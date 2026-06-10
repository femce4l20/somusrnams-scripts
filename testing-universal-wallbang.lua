local CONFIG = {
	MAX_PHASE_COUNT = 128,
	RAY_DISTANCE = 5000,
	STAND_CHECK_DIST = 4,
	IGNORE_TERRAIN = false,

	-- Only affect anchored/static world parts.
	STATIC_ONLY = true,

	-- Never touch parts with any transparency above this threshold.
	MAX_ALLOWED_TRANSPARENCY = 0,

	-- Small offset between successive penetrations to reduce repeated hits
	-- on the same surface from floating-point precision jitter.
	RAY_ADVANCE_EPSILON = 0.01,

	ANTI_FLOOR = {
		ENABLED = false,

		-- A part is treated as "floor-like" when one axis is much thinner
		-- than the other two, and that thin axis is close to world-up/down.
		MAX_THIN_TO_WIDE_RATIO = 0.30,
		MIN_WIDE_AXIS = 2.0,
		MIN_MIDDLE_AXIS = 1.0,
		MIN_THIN_AXIS = 0.20,
		MIN_UP_ALIGNMENT = 0.75,
	},

	PHYSICS = {
		-- How long a part must stay out of the active target set before it
		-- becomes eligible to be restored. This smooths out flicker.
		RESTORE_DELAY = 0.08,
	},

	VISUALIZATION = {
		ENABLED = true,
		SHOW_HUD = false,
		SHOW_RAY = false,
		SHOW_HIT_MARKERS = true,
		SHOW_HIGHLIGHTS = false,

		RAY_COLOR = Color3.fromRGB(0, 255, 170),
		HIT_MARKER_COLOR = Color3.fromRGB(255, 170, 0),
		HIGHLIGHT_FILL_COLOR = Color3.fromRGB(255, 255, 0),
		HIGHLIGHT_OUTLINE_COLOR = Color3.fromRGB(255, 255, 255),

		RAY_THICKNESS = 0.08,
		HIT_MARKER_SIZE = 0.22,

		-- Moves the hit marker lower/up/down in world space.
		HIT_MARKER_OFFSET = Vector3.new(0, -2.5, 0),

		-- In first person, aim from the center of the screen instead of the
		-- mouse position. This offset is applied in screen-space pixels.
		-- Positive X = right, positive Y = down.
		FIRST_PERSON_SCREEN_OFFSET = Vector2.new(0, 0),

		HIGHLIGHT_FILL_TRANSPARENCY = 0.75,
		HIGHLIGHT_OUTLINE_TRANSPARENCY = 0.1,
	},
}

--  SERVICES / REFERENCES

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--  STATE

local disabledParts: { [BasePart]: boolean } = {}
local restoreQueue: { [BasePart]: number } = {}

type HitInfo = {
	Part: BasePart,
	Position: Vector3,
	StartPosition: Vector3,
}

local currentTargets: { [BasePart]: boolean } = {}

local AIM_UPDATE_INTERVAL = 1 / 60
local aimUpdateAccumulator = 0

local lastHudText = ""
local lastDebugSignature: string? = nil

local standingPartCache: BasePart? = nil
local standingPartCacheTime = 0
local STANDING_PART_CACHE_INTERVAL = 0.05

-- Reused raycast parameters and buffers to reduce per-frame allocations.
local mainRayParams = RaycastParams.new()
mainRayParams.FilterType = Enum.RaycastFilterType.Exclude
mainRayParams.IgnoreWater = true

local standRayParams = RaycastParams.new()
standRayParams.FilterType = Enum.RaycastFilterType.Exclude
standRayParams.IgnoreWater = true

local excludedInstances: { Instance } = table.create(16)
local standExcludedInstances: { Instance } = table.create(4)

--  UI

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RaycastPhaseUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Name = "StatusLabel"
label.Size = UDim2.new(0, 420, 0, 44)
label.Position = UDim2.new(0.5, -210, 0, 16)
label.BackgroundTransparency = 0.35
label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.GothamBold
label.TextSize = 15
label.TextXAlignment = Enum.TextXAlignment.Center
label.Text = ""
label.Visible = CONFIG.VISUALIZATION.ENABLED and CONFIG.VISUALIZATION.SHOW_HUD
label.Parent = screenGui

--  DEBUG VISUALS

local debugFolder: Folder? = nil
local rayParts: { Part } = {}
local hitMarkers: { Part } = {}
local debugHighlights: { [BasePart]: Highlight } = {}

local function ensureDebugFolder()
	if not CONFIG.VISUALIZATION.ENABLED then
		return
	end

	if debugFolder and debugFolder.Parent then
		return
	end

	debugFolder = Instance.new("Folder")
	debugFolder.Name = "RaycastPhaseDebug"
	debugFolder.Parent = workspace
end

ensureDebugFolder()

local function setDebugPartVisible(part: Part, visible: boolean)
	part.Transparency = visible and 0.15 or 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
end

local function getRayPart(index: number): Part
	ensureDebugFolder()

	local part = rayParts[index]
	if not part then
		part = Instance.new("Part")
		part.Name = "RaySegment_" .. index
		part.Anchored = true
		part.Locked = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Material = Enum.Material.Neon
		part.Color = CONFIG.VISUALIZATION.RAY_COLOR
		part.Size = Vector3.new(CONFIG.VISUALIZATION.RAY_THICKNESS, CONFIG.VISUALIZATION.RAY_THICKNESS, 1)
		part.Parent = debugFolder
		rayParts[index] = part
	end
	return part
end

local function getHitMarker(index: number): Part
	ensureDebugFolder()

	local part = hitMarkers[index]
	if not part then
		part = Instance.new("Part")
		part.Name = "HitMarker_" .. index
		part.Anchored = true
		part.Locked = true
		part.Shape = Enum.PartType.Ball
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Material = Enum.Material.Neon
		part.Color = CONFIG.VISUALIZATION.HIT_MARKER_COLOR
		part.Size = Vector3.new(
			CONFIG.VISUALIZATION.HIT_MARKER_SIZE,
			CONFIG.VISUALIZATION.HIT_MARKER_SIZE,
			CONFIG.VISUALIZATION.HIT_MARKER_SIZE
		)
		part.Parent = debugFolder
		hitMarkers[index] = part
	end
	return part
end

local function getOrCreateHighlight(part: BasePart): Highlight
	ensureDebugFolder()

	local existing = debugHighlights[part]
	if existing then
		return existing
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "PhaseHighlight"
	highlight.Adornee = part
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = CONFIG.VISUALIZATION.HIGHLIGHT_FILL_COLOR
	highlight.OutlineColor = CONFIG.VISUALIZATION.HIGHLIGHT_OUTLINE_COLOR
	highlight.FillTransparency = CONFIG.VISUALIZATION.HIGHLIGHT_FILL_TRANSPARENCY
	highlight.OutlineTransparency = CONFIG.VISUALIZATION.HIGHLIGHT_OUTLINE_TRANSPARENCY
	highlight.Enabled = true
	highlight.Parent = debugFolder

	debugHighlights[part] = highlight
	return highlight
end

local function clearUnusedDebugParts(usedRayCount: number, usedMarkerCount: number, usedHighlights: { [BasePart]: boolean })
	for i = usedRayCount + 1, #rayParts do
		setDebugPartVisible(rayParts[i], false)
	end

	for i = usedMarkerCount + 1, #hitMarkers do
		setDebugPartVisible(hitMarkers[i], false)
	end

	for part, highlight in pairs(debugHighlights) do
		if not usedHighlights[part] then
			if highlight then
				highlight:Destroy()
			end
			debugHighlights[part] = nil
		end
	end
end

local function vector3Signature(v: Vector3): string
	local sx = math.floor(v.X * 1000 + 0.5)
	local sy = math.floor(v.Y * 1000 + 0.5)
	local sz = math.floor(v.Z * 1000 + 0.5)
	return sx .. "," .. sy .. "," .. sz
end

local function buildDebugSignature(hits: { HitInfo }): string
	if #hits == 0 then
		return "0"
	end

	local chunks = table.create(#hits * 3 + 1)
	chunks[1] = tostring(#hits)

	for i, hit in ipairs(hits) do
		chunks[#chunks + 1] = tostring(hit.Part)
		chunks[#chunks + 1] = vector3Signature(hit.StartPosition)
		chunks[#chunks + 1] = vector3Signature(hit.Position)
	end

	return table.concat(chunks, "|")
end

local function updateDebugVisuals(hits: { HitInfo }, signature: string)
	if not CONFIG.VISUALIZATION.ENABLED then
		return
	end

	ensureDebugFolder()
	if not debugFolder then
		return
	end

	if lastDebugSignature == signature then
		return
	end
	lastDebugSignature = signature

	local usedHighlights: { [BasePart]: boolean } = {}
	local rayIndex = 0
	local markerIndex = 0

	if CONFIG.VISUALIZATION.SHOW_RAY then
		for _, hit in ipairs(hits) do
			rayIndex += 1
			local segment = getRayPart(rayIndex)

			local startPos = hit.StartPosition
			local endPos = hit.Position
			local length = (endPos - startPos).Magnitude

			if length < 0.001 then
				setDebugPartVisible(segment, false)
			else
				local midpoint = (startPos + endPos) * 0.5
				segment.Size = Vector3.new(CONFIG.VISUALIZATION.RAY_THICKNESS, CONFIG.VISUALIZATION.RAY_THICKNESS, length)
				segment.CFrame = CFrame.lookAt(midpoint, endPos)
				setDebugPartVisible(segment, true)
			end
		end
	end

	if CONFIG.VISUALIZATION.SHOW_HIT_MARKERS then
		for _, hit in ipairs(hits) do
			markerIndex += 1
			local marker = getHitMarker(markerIndex)
			marker.CFrame = CFrame.new(hit.Position + CONFIG.VISUALIZATION.HIT_MARKER_OFFSET)
			setDebugPartVisible(marker, true)
		end
	end

	if CONFIG.VISUALIZATION.SHOW_HIGHLIGHTS then
		for _, hit in ipairs(hits) do
			usedHighlights[hit.Part] = true
			getOrCreateHighlight(hit.Part).Enabled = true
		end
	end

	clearUnusedDebugParts(rayIndex, markerIndex, usedHighlights)
end

local function pruneDestroyedDebugHighlights()
	for part, highlight in pairs(debugHighlights) do
		if not part or not part.Parent or not highlight or not highlight.Parent then
			if highlight then
				highlight:Destroy()
			end
			debugHighlights[part] = nil
		end
	end
end

local function resetDebugVisualCache()
	lastDebugSignature = nil
	lastHudText = ""
end

--  HELPERS

local function getStandingPart(): BasePart?
	local char = player.Character
	if not char then
		return nil
	end

	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end

	standExcludedInstances[1] = char
	standRayParams.FilterDescendantsInstances = standExcludedInstances

	local result = workspace:Raycast(root.Position, Vector3.new(0, -CONFIG.STAND_CHECK_DIST, 0), standRayParams)
	if result and result.Instance and result.Instance:IsA("BasePart") then
		return result.Instance
	end

	return nil
end

local function getCachedStandingPart(now: number, forceRefresh: boolean?): BasePart?
	if forceRefresh or (now - standingPartCacheTime) >= STANDING_PART_CACHE_INTERVAL then
		standingPartCacheTime = now
		standingPartCache = getStandingPart()
	end

	return standingPartCache
end

local function invalidateCachedStandingPart()
	standingPartCache = nil
	standingPartCacheTime = 0
end

local function syncStandingCacheFromPhysics(now: number)
	standingPartCacheTime = now
	standingPartCache = getStandingPart()
end

local function isInTool(inst: Instance): boolean
	return inst:FindFirstAncestorOfClass("Tool") ~= nil
end

local function isInAccessory(inst: Instance): boolean
	return inst:FindFirstAncestorOfClass("Accessory") ~= nil
end

local function isInCharacterModel(inst: Instance): boolean
	local model = inst:FindFirstAncestorOfClass("Model")
	return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function getIgnoreRoot(inst: Instance): Instance
	local tool = inst:FindFirstAncestorOfClass("Tool")
	if tool then
		return tool
	end

	local accessory = inst:FindFirstAncestorOfClass("Accessory")
	if accessory then
		return accessory
	end

	local model = inst:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		return model
	end

	return inst
end

local function isTransparentPart(part: BasePart): boolean
	return part.Transparency > CONFIG.MAX_ALLOWED_TRANSPARENCY
end

local function isLikelyFloor(part: BasePart): boolean
	if not CONFIG.ANTI_FLOOR.ENABLED then
		return false
	end

	local size = part.Size

	local axes = {
		{ size = size.X, vec = part.CFrame.RightVector },
		{ size = size.Y, vec = part.CFrame.UpVector },
		{ size = size.Z, vec = part.CFrame.LookVector },
	}

	table.sort(axes, function(a, b)
		return a.size < b.size
	end)

	local thin = axes[1].size
	local mid = axes[2].size
	local wide = axes[3].size

	if thin < CONFIG.ANTI_FLOOR.MIN_THIN_AXIS then
		return false
	end

	if mid < CONFIG.ANTI_FLOOR.MIN_MIDDLE_AXIS then
		return false
	end

	if wide < CONFIG.ANTI_FLOOR.MIN_WIDE_AXIS then
		return false
	end

	if (thin / wide) > CONFIG.ANTI_FLOOR.MAX_THIN_TO_WIDE_RATIO then
		return false
	end

	local thinAxisVector = axes[1].vec
	local upAlignment = math.abs(thinAxisVector:Dot(Vector3.yAxis))

	return upAlignment >= CONFIG.ANTI_FLOOR.MIN_UP_ALIGNMENT
end

local function isStaticWorldPart(part: BasePart): boolean
	if CONFIG.STATIC_ONLY and not part.Anchored then
		return false
	end

	return true
end

local function shouldIgnoreHit(inst: Instance): boolean
	if CONFIG.IGNORE_TERRAIN and inst == workspace.Terrain then
		return true
	end

	if not inst:IsA("BasePart") then
		return true
	end

	local part = inst :: BasePart

	if isTransparentPart(part) then
		return true
	end

	if not isStaticWorldPart(part) then
		return true
	end

	if isInTool(inst) or isInAccessory(inst) or isInCharacterModel(inst) then
		return true
	end

	if isLikelyFloor(part) then
		return true
	end

	return false
end

local function disablePart(part: BasePart)
	if disabledParts[part] then
		return
	end

	disabledParts[part] = true
	part.CanCollide = false
	part.CanQuery = false
end

local function tryEnablePart(part: BasePart, standingOn: BasePart?)
	if standingOn == part then
		return false
	end

	if not disabledParts[part] then
		return false
	end

	part.CanCollide = true
	part.CanQuery = true
	disabledParts[part] = nil
	restoreQueue[part] = nil
	return true
end

local function purgeDestroyedPhysicsEntries()
	for part in pairs(disabledParts) do
		if not part or not part.Parent then
			disabledParts[part] = nil
			restoreQueue[part] = nil
			currentTargets[part] = nil
		end
	end

	for part in pairs(restoreQueue) do
		if not part or not part.Parent then
			disabledParts[part] = nil
			restoreQueue[part] = nil
			currentTargets[part] = nil
		end
	end
end

local function castPenetratingRay(origin: Vector3, direction: Vector3): { HitInfo }
	local hits: { HitInfo } = {}

	local char = player.Character
	table.clear(excludedInstances)
	if char then
		excludedInstances[1] = char
	end
	mainRayParams.FilterDescendantsInstances = excludedInstances

	local remaining = CONFIG.RAY_DISTANCE
	local rayOrigin = origin
	local rayDir = direction.Unit

	for _ = 1, CONFIG.MAX_PHASE_COUNT do
		if remaining <= 0 then
			break
		end

		local startPos = rayOrigin
		local result = workspace:Raycast(rayOrigin, rayDir * remaining, mainRayParams)
		if not result then
			break
		end

		local inst = result.Instance
		local travelled = result.Distance
		rayOrigin = result.Position + rayDir * CONFIG.RAY_ADVANCE_EPSILON
		remaining -= travelled

		if shouldIgnoreHit(inst) then
			excludedInstances[#excludedInstances + 1] = getIgnoreRoot(inst)
			continue
		end

		local part = inst :: BasePart
		hits[#hits + 1] = {
			Part = part,
			Position = result.Position,
			StartPosition = startPos,
		}

		excludedInstances[#excludedInstances + 1] = part
	end

	return hits
end

local function buildTargetNameText(targets: { HitInfo }): string
	if #targets == 0 then
		return ""
	elseif #targets == 1 then
		return "⬡ Phasing: " .. targets[1].Part.Name
	else
		local names = table.create(#targets)
		for i, hit in ipairs(targets) do
			names[i] = hit.Part.Name
		end
		return "⬡ Phasing (" .. #targets .. "): " .. table.concat(names, " → ")
	end
end

local function updateTargetCache(newTargets: { HitInfo })
	table.clear(currentTargets)
	for _, hit in ipairs(newTargets) do
		currentTargets[hit.Part] = true
	end
end

local function syncPhysicsPreSimulation()
	local now = os.clock()
	purgeDestroyedPhysicsEntries()
	pruneDestroyedDebugHighlights()
	syncStandingCacheFromPhysics(now)

	-- Refresh current targets immediately before physics.
	for part in pairs(currentTargets) do
		if part and part.Parent then
			disablePart(part)
		else
			disabledParts[part] = nil
			restoreQueue[part] = nil
			currentTargets[part] = nil
		end
	end

	-- Queue stale disabled parts for restoration.
	for part in pairs(disabledParts) do
		if not currentTargets[part] and part.Parent then
			if not restoreQueue[part] then
				restoreQueue[part] = now + CONFIG.PHYSICS.RESTORE_DELAY
			end
		end
	end

	-- Cancel restore timers for parts that became targets again.
	for part in pairs(restoreQueue) do
		if currentTargets[part] then
			restoreQueue[part] = nil
		end
	end
end

local function syncPhysicsHeartbeat()
	local now = os.clock()
	purgeDestroyedPhysicsEntries()
	pruneDestroyedDebugHighlights()

	local standingOn = getCachedStandingPart(now, false)

	-- Try restoring anything whose delay has elapsed.
	for part, restoreAt in pairs(restoreQueue) do
		if now >= restoreAt then
			if part and part.Parent then
				if tryEnablePart(part, standingOn) then
					restoreQueue[part] = nil
				else
					-- Still standing on it; keep retrying.
					restoreQueue[part] = now + CONFIG.PHYSICS.RESTORE_DELAY
				end
			else
				disabledParts[part] = nil
				restoreQueue[part] = nil
				currentTargets[part] = nil
			end
		end
	end
end

local function updateAimRayAndUi(dt: number?)
	dt = dt or AIM_UPDATE_INTERVAL
	aimUpdateAccumulator += dt

	if aimUpdateAccumulator < AIM_UPDATE_INTERVAL then
		return
	end
	aimUpdateAccumulator -= AIM_UPDATE_INTERVAL

	camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local viewportPos: Vector2

	if UserInputService.MouseEnabled then
		local inset = GuiService:GetGuiInset()
		local mousePos = UserInputService:GetMouseLocation()
		viewportPos = mousePos - Vector2.new(inset.X, inset.Y)
	else
		local vp = camera.ViewportSize
		viewportPos = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
	end

	local function isFirstPerson()
		if player.CameraMode == Enum.CameraMode.LockFirstPerson then
			return true
		end

		local camPos = camera.CFrame.Position
		local focusPos = camera.Focus.Position
		return (camPos - focusPos).Magnitude < 1.5
	end

	if isFirstPerson() then
		local vp = camera.ViewportSize
		viewportPos = Vector2.new(vp.X * 0.5, vp.Y * 0.5) + CONFIG.VISUALIZATION.FIRST_PERSON_SCREEN_OFFSET
	end

	local unitRay = camera:ViewportPointToRay(viewportPos.X, viewportPos.Y, 0)
	local origin = unitRay.Origin
	local direction = unitRay.Direction

	local newTargets = castPenetratingRay(origin, direction)
	updateTargetCache(newTargets)

	if CONFIG.VISUALIZATION.ENABLED and CONFIG.VISUALIZATION.SHOW_HUD then
		local newHudText = buildTargetNameText(newTargets)
		label.Visible = true
		if newHudText ~= lastHudText then
			label.Text = newHudText
			lastHudText = newHudText
		end
	else
		label.Visible = false
		lastHudText = ""
	end

	if CONFIG.VISUALIZATION.ENABLED then
		updateDebugVisuals(newTargets, buildDebugSignature(newTargets))
	end
end

--  MAIN LOOP

local BIND_NAME = "RaycastPhaseScript"

RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 1, updateAimRayAndUi)
RunService.PreSimulation:Connect(syncPhysicsPreSimulation)
RunService.Heartbeat:Connect(syncPhysicsHeartbeat)

--  CLEANUP ON RESPAWN

local function cleanup()
	for part in pairs(disabledParts) do
		if part and part.Parent then
			part.CanCollide = true
			part.CanQuery = true
		end
	end

	table.clear(disabledParts)
	table.clear(restoreQueue)
	table.clear(currentTargets)
	invalidateCachedStandingPart()
	aimUpdateAccumulator = 0
	lastHudText = ""
	resetDebugVisualCache()

	if CONFIG.VISUALIZATION.ENABLED and debugFolder then
		for _, part in ipairs(rayParts) do
			if part then
				part:Destroy()
			end
		end

		for _, part in ipairs(hitMarkers) do
			if part then
				part:Destroy()
			end
		end

		for _, highlight in pairs(debugHighlights) do
			if highlight then
				highlight:Destroy()
			end
		end

		debugFolder:Destroy()
		debugFolder = nil
		rayParts = {}
		hitMarkers = {}
		debugHighlights = {}
	end
end

player.CharacterRemoving:Connect(cleanup)
