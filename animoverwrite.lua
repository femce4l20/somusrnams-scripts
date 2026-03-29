local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

--[[
	Custom keybind section.

	Edit these entries to change the key, mode, and animation id.

	Mode options:
	- "hold"   = plays while the key is held, then returns to idle on release
	- "press"  = plays once, then returns to idle when the animation ends
	- "toggle" = press once to start, press again to stop and return to idle

	For the Splits keybind (C), startTime and endTime define the ping‑pong range.
]]
local keybindActions = {
	{
		name = "Wave",
		keyCode = Enum.KeyCode.Q,
		mode = "hold",
		animationId = "86074172929360",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	{
		name = "DropKick",
		keyCode = Enum.KeyCode.E,
		mode = "press",
		animationId = "133566007754001",
		looped = false,
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
	name = "SitPretty1",
	keyCode = Enum.KeyCode.Y,
	mode = "toggle",
	animationId = "85961795938515",
	looped = true,
	priority = Enum.AnimationPriority.Action,
},
{
	name = "SitPretty2",
	keyCode = Enum.KeyCode.U,
	mode = "toggle",
	animationId = "113986788014462",
	looped = true,
	priority = Enum.AnimationPriority.Action,
},
{
	name = "CuteDanceIdk",
	keyCode = Enum.KeyCode.F,
	mode = "toggle",
	animationId = "131673340109237",
	looped = true,
	priority = Enum.AnimationPriority.Action,
},
{
	name = "JiggleDance",
	keyCode = Enum.KeyCode.G,
	mode = "toggle",
	animationId = "125763702777221",
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
	name = "FeelinMyself",
	keyCode = Enum.KeyCode.K,
	mode = "toggle",
	animationId = "101385394794634",
	looped = true,
	priority = Enum.AnimationPriority.Action,
},
{
	name = "SitOnIt",
	keyCode = Enum.KeyCode.Z,
	mode = "toggle",
	animationId = "120446020975705",
	looped = true,
	priority = Enum.AnimationPriority.Action,
},
{
	name = "SitOnIt2",
	keyCode = Enum.KeyCode.X,
	mode = "toggle",
	animationId = "103890015669349",
	looped = true,
	priority = Enum.AnimationPriority.Action,
},
{
	name = "Splits",
	keyCode = Enum.KeyCode.C,
	mode = "toggle",
	animationId = "118947009579831",
	looped = true,
	priority = Enum.AnimationPriority.Action,
	startTime = 3.19,   -- ping‑pong start
	endTime = 5.47,     -- ping‑pong end
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
	name = "Anim_B",
	keyCode = Enum.KeyCode.B,
	mode = "toggle",
	animationId = "120446020725705",
	looped = true,
	priority = Enum.AnimationPriority.Action,
},
{
	name = "Anim_N",
	keyCode = Enum.KeyCode.N,
	mode = "toggle",
	animationId = "109716540429732",
	looped = true,
	priority = Enum.AnimationPriority.Action,
},
{
	name = "Anim_M",
	keyCode = Enum.KeyCode.M,
	mode = "toggle",
	animationId = "140655897836448",
	looped = true,
	priority = Enum.AnimationPriority.Action,
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

local animNames = {
	idle = {
		{ id = "http://www.roblox.com/asset/?id=78809479095741", weight = 1 },
		{ id = "http://www.roblox.com/asset/?id=104342455423558", weight = 1 },
		{ id = "http://www.roblox.com/asset/?id=89179616136359", weight = 1 },
		{ id = "http://www.roblox.com/asset/?id=79493772354232", weight = 1 },
		{ id = "http://www.roblox.com/asset/?id=80997638859162", weight = 1 },
		{ id = "http://www.roblox.com/asset/?id=114843552733773", weight = 1 },
		{ id = "http://www.roblox.com/asset/?id=139856242706116", weight = 1 },
		{ id = "http://www.roblox.com/asset/?id=132482243634511", weight = 1 },
		{ id = "http://www.roblox.com/asset/?id=80997638859162", weight = 1 },
		{ id = "http://www.roblox.com/asset/?id=134741630981082", weight = 1 },
	},
	walk = {
		{ id = "http://www.roblox.com/asset/?id=81902773529444", weight = 10 },
	},
	run = {
		{ id = "http://www.roblox.com/asset/?id=85475131476587", weight = 10 },
	},
	swim = {
		{ id = "http://www.roblox.com/asset/?id=16738339158", weight = 10 },
	},
	swimidle = {
		{ id = "http://www.roblox.com/asset/?id=16738339817", weight = 10 },
	},
	jump = {
		{ id = "http://www.roblox.com/asset/?id=16738336650", weight = 10 },
	},
	fall = {
		{ id = "http://www.roblox.com/asset/?id=16738333171", weight = 10 },
	},
	climb = {
		{ id = "http://www.roblox.com/asset/?id=16738332169", weight = 10 },
	},
	sit = {
		{ id = "http://www.roblox.com/asset/?id=2506281703", weight = 10 },
	},
	toolnone = {
		{ id = "http://www.roblox.com/asset/?id=507768375", weight = 10 },
	},
	toolslash = {
		{ id = "http://www.roblox.com/asset/?id=522635514", weight = 10 },
	},
	toollunge = {
		{ id = "http://www.roblox.com/asset/?id=522638767", weight = 10 },
	},
	wave = {
		{ id = "http://www.roblox.com/asset/?id=507770239", weight = 10 },
	},
	point = {
		{ id = "http://www.roblox.com/asset/?id=507770453", weight = 10 },
	},
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
	laugh = {
		{ id = "http://www.roblox.com/asset/?id=507770818", weight = 10 },
	},
	cheer = {
		{ id = "http://www.roblox.com/asset/?id=507770677", weight = 10 },
	},
}

local emoteNames = {
	wave = false,
	point = false,
	dance = true,
	dance2 = true,
	dance3 = true,
	laugh = false,
	cheer = false,
}

local EMOTE_TRANSITION_TIME = 0.1
local HumanoidHipHeight = 2

local activeCleanup = nil

local function startForCharacter(Character)
	if activeCleanup then
		activeCleanup()
		activeCleanup = nil
	end

	local Humanoid = Character:WaitForChild("Humanoid")
	local Animator = Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	Animator.Parent = Humanoid

	-- Disable the default Roblox Animate script so this one fully controls animations
	local defaultAnimate = Character:FindFirstChild("Animate")
	if defaultAnimate then
		defaultAnimate:Destroy()
	end

	-- Stop any currently playing tracks from the previous animation system
	for _, track in ipairs(Animator:GetPlayingAnimationTracks()) do
		pcall(function()
			track:Stop(0)
			track:Destroy()
		end)
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

	-- Build custom keybind table with optional startTime/endTime for ping‑pong
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
			}
			if binding.startTime then newBinding.startTime = binding.startTime end
			if binding.endTime then newBinding.endTime = binding.endTime end
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
			pcall(function()
				c:Disconnect()
			end)
		end
		table.clear(connections)
	end

	local function stopTrack(track, fadeTime)
		if track then
			pcall(function()
				track:Stop(fadeTime or 0)
				track:Destroy()
			end)
		end
	end

	local function stopMainAnimationTracks(fadeTime)
		if currentAnimKeyframeHandler then
			pcall(function()
				currentAnimKeyframeHandler:Disconnect()
			end)
			currentAnimKeyframeHandler = nil
		end

		if runAnimKeyframeHandler then
			pcall(function()
				runAnimKeyframeHandler:Disconnect()
			end)
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
		if count <= 1 then
			return 1
		end

		local chosen = exceptIndex or 0
		while chosen == exceptIndex do
			chosen = math.random(1, count)
		end
		return chosen
	end

	local function configureAnimationSet(name, fileList)
		if animTable[name] ~= nil then
			for _, connection in ipairs(animTable[name].connections or {}) do
				pcall(function()
					connection:Disconnect()
				end)
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
					if weightObject ~= nil then
						newWeight = weightObject.Value
					end

					animTable[name].count += 1
					local idx = animTable[name].count
					animTable[name][idx] = {
						anim = childPart,
						weight = newWeight,
					}
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
					pcall(function()
						Animator:LoadAnimation(animType[idx].anim)
					end)
					PreloadedAnims[animationId] = true
				end
			end
		end
	end

	local function findExistingAnimationInSet(set, anim)
		if set == nil or anim == nil then
			return 0
		end

		for idx = 1, set.count do
			if set[idx].anim.AnimationId == anim.AnimationId then
				return idx
			end
		end

		return 0
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
		local speedScaled = speed * 1.25
		local heightScale = getHeightScale()
		return speedScaled / heightScale
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
		if not idleSet or idleSet.count <= 0 then
			return
		end

		index = math.clamp(index or 1, 1, idleSet.count)
		currentIdleIndex = index

		-- Stop any non-idle main animation and switch to the selected idle
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
		if currentCustomAction == nil then
			return
		end

		local action = currentCustomAction
		currentCustomAction = nil

		action.isActive = false
		action.ignoreStop = true

		-- Clean up ping‑pong heartbeat if present
		if action.pingPongConnection then
			action.pingPongConnection:Disconnect()
			action.pingPongConnection = nil
		end

		if action.track then
			local track = action.track
			action.track = nil
			action.animation = nil

			pcall(function()
				track:Stop(fadeTime or 0)
			end)
			pcall(function()
				track:Destroy()
			end)
		end

		action.ignoreStop = false

		if goIdle and Character.Parent ~= nil and Humanoid.Parent ~= nil then
			setIdleState(true, fadeTime or 0.15)
		end
	end

	local function playCustomAction(action, transitionTime)
		if action == nil or Humanoid.Parent == nil then
			return
		end

		if currentCustomAction and currentCustomAction ~= action then
			stopCurrentCustomAction(transitionTime or 0, false)
		end

		if currentCustomAction == action and action.track then
			pcall(function()
				action.track:Stop(0)
				action.track:Destroy()
			end)
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

		-- Special ping‑pong handling for Splits (if startTime & endTime are provided)
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
					-- If the track stops for any reason, clean up
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
			-- Normal playback mode
			track.Looped = (action.mode ~= "press") and (action.looped == true or action.looped == nil or action.mode == "hold" or action.mode == "toggle") or false
			track:Play(transitionTime or 0.1)
		end

		local stoppedConnection
		stoppedConnection = track.Stopped:Connect(function()
			if currentCustomAction ~= action then
				return
			end
			if action.ignoreStop then
				return
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
		if currentCustomAction and animName ~= "idle" then
			return
		end

		if animName == "idle" then
			setIdleState(true, transitionTime)
			return
		end

		local idx = rollAnimation(animName)
		local anim = animTable[animName][idx].anim

		if anim ~= currentAnimInstance then
			-- Leaving idle? stop it cleanly and pick a new next idle for later.
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
				pcall(function()
					currentAnimKeyframeHandler:Disconnect()
				end)
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
							if currentAnimTrack and currentAnimTrack.Looped then
								return
							end
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
					pcall(function()
						runAnimKeyframeHandler:Disconnect()
					end)
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
		if currentCustomAction then
			return
		end

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
			pcall(function()
				currentAnimKeyframeHandler:Disconnect()
			end)
			currentAnimKeyframeHandler = nil
		end

		if runAnimKeyframeHandler ~= nil then
			pcall(function()
				runAnimKeyframeHandler:Disconnect()
			end)
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
		if currentCustomAction then
			return
		end

		local heightScale = getHeightScale()

		-- Adjust the walking speed if a ControllerManager is being used.
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
					if moveMag < 0.1 then
						relSpeed = 0
						moveMag = 0
					elseif moveMag > 1.0 then
						moveMag = 1.0
					end
					speed = relSpeed * moveMag
				end
			end
		end

		local movedDuringEmote = currentlyPlayingEmote and Humanoid.MoveDirection == Vector3.new(0, 0, 0)
		local speedThreshold = movedDuringEmote and (Humanoid.WalkSpeed / heightScale) or 0.75

		if speed > speedThreshold * heightScale then
			if isIdle then
				setIdleState(false, 0.1)
			end

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
	end

	local function onJumping()
		if currentCustomAction then
			return
		end
		if isIdle then
			setIdleState(false, 0.1)
		end
		playAnimation("jump", 0.1, Humanoid)
		jumpAnimTime = jumpAnimDuration
		pose = "Jumping"
	end

	local function onClimbing(speed)
		if currentCustomAction then
			return
		end
		if isIdle then
			setIdleState(false, 0.1)
		end
		speed /= getHeightScale()
		local scale = 5.0
		playAnimation("climb", 0.1, Humanoid)
		setAnimationSpeed(speed / scale)
		pose = "Climbing"
	end

	local function onGettingUp()
		pose = "GettingUp"
	end

	local function onFreeFall()
		if currentCustomAction then
			return
		end
		if isIdle then
			setIdleState(false, 0.1)
		end
		if jumpAnimTime <= 0 then
			playAnimation("fall", fallTransitionTime, Humanoid)
		end
		pose = "FreeFall"
	end

	local function onFallingDown()
		pose = "FallingDown"
	end

	local function onSeated()
		if currentCustomAction then
			return
		end
		if isIdle then
			setIdleState(false, 0.1)
		end
		pose = "Seated"
	end

	local function onPlatformStanding()
		pose = "PlatformStanding"
	end

	local function onSwimming(speed)
		if currentCustomAction then
			return
		end
		if isIdle then
			setIdleState(false, 0.1)
		end
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
		if currentCustomAction then
			return
		end

		if toolAnim == "None" then
			playAnimation("toolnone", toolTransitionTime, Humanoid)
			if currentAnimTrack then
				currentAnimTrack.Priority = Enum.AnimationPriority.Idle
			end
			return
		end

		if toolAnim == "Slash" then
			playAnimation("toolslash", 0, Humanoid)
			if currentAnimTrack then
				currentAnimTrack.Priority = Enum.AnimationPriority.Action
			end
			return
		end

		if toolAnim == "Lunge" then
			playAnimation("toollunge", 0, Humanoid)
			if currentAnimTrack then
				currentAnimTrack.Priority = Enum.AnimationPriority.Action
			end
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

	local function toolKeyFrameReachedFunc(frameName)
		if frameName == "End" then
			playToolAnimation(toolAnimName, 0.0, Humanoid)
		end
	end

	function playToolAnimation(animName, transitionTime, humanoid, priority)
		if currentCustomAction then
			return
		end

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
		if currentCustomAction then
			return
		end

		local deltaTime = currentTime - lastTick
		lastTick = currentTime

		if jumpAnimTime > 0 then
			jumpAnimTime -= deltaTime
		end

		if pose == "FreeFall" and jumpAnimTime <= 0 then
			playAnimation("fall", fallTransitionTime, Humanoid)
		elseif pose == "Seated" then
			playAnimation("sit", 0.5, Humanoid)
			return
		elseif pose == "Running" then
			playAnimation("walk", 0.2, Humanoid)
		elseif pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "Seated" or pose == "PlatformStanding" then
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
			if binding.keyCode == keyCode then
				return binding
			end
		end
		return nil
	end

	local function handleCustomBindPressed(inputObject, gameProcessed)
		if gameProcessed then
			return
		end

		local binding = getBindingForKeyCode(inputObject.KeyCode)
		if not binding then
			return
		end

		if binding.mode == "hold" then
			playCustomAction(binding, 0.05)
		elseif binding.mode == "press" then
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
		if gameProcessed then
			return
		end

		local binding = getBindingForKeyCode(inputObject.KeyCode)
		if not binding then
			return
		end

		if binding.mode == "hold" and currentCustomAction == binding then
			stopCurrentCustomAction(0.1, true)
		end
	end

	-- Setup animation sets
	for name, fileList in pairs(animNames) do
		configureAnimationSet(name, fileList)
	end

	-- Event connections
	connect(Humanoid.Died, onDied)
	connect(Humanoid.Running, onRunning)
	connect(Humanoid.Jumping, onJumping)
	connect(Humanoid.Climbing, onClimbing)
	connect(Humanoid.GettingUp, onGettingUp)
	connect(Humanoid.FreeFalling, onFreeFall)
	connect(Humanoid.FallingDown, onFallingDown)
	connect(Humanoid.Seated, onSeated)
	connect(Humanoid.PlatformStanding, onPlatformStanding)
	connect(Humanoid.Swimming, onSwimming)

	connect(UserInputService.InputBegan, handleCustomBindPressed)
	connect(UserInputService.InputEnded, handleCustomBindReleased)

	connect(player.Chatted, function(msg)
		if currentCustomAction then
			return
		end

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
			if currentCustomAction then
				return false
			end

			if pose ~= "Standing" then
				return
			end

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

	local heartbeatConnection
	heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		if Character.Parent == nil or Humanoid.Parent == nil then
			if heartbeatConnection then
				heartbeatConnection:Disconnect()
			end
			cleanupConnections()
			return
		end

		stepAnimate(dt)
	end)

	table.insert(connections, heartbeatConnection)

	activeCleanup = function()
		cleanupConnections()

		if currentCustomAction then
			if currentCustomAction.pingPongConnection then
				currentCustomAction.pingPongConnection:Disconnect()
			end
			currentCustomAction.isActive = false
			currentCustomAction.ignoreStop = true
			currentCustomAction = nil
		end

		if currentAnimKeyframeHandler then
			pcall(function()
				currentAnimKeyframeHandler:Disconnect()
			end)
		end
		if runAnimKeyframeHandler then
			pcall(function()
				runAnimKeyframeHandler:Disconnect()
			end)
		end
		if currentToolAnimKeyframeHandler then
			pcall(function()
				currentToolAnimKeyframeHandler:Disconnect()
			end)
		end

		if currentAnimTrack then
			pcall(function()
				currentAnimTrack:Stop(0)
				currentAnimTrack:Destroy()
			end)
		end
		if runAnimTrack then
			pcall(function()
				runAnimTrack:Stop(0)
				runAnimTrack:Destroy()
			end)
		end
		if toolAnimTrack then
			pcall(function()
				toolAnimTrack:Stop(0)
				toolAnimTrack:Destroy()
			end)
		end
		if idleTrack then
			pcall(function()
				idleTrack:Stop(0)
				idleTrack:Destroy()
			end)
		end
	end
end

if player.Character then
	startForCharacter(player.Character)
end

player.CharacterAdded:Connect(function(character)
	startForCharacter(character)
end)
