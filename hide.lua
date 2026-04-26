local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Create platform
local platform = Instance.new("Part")
platform.Size = Vector3.new(1000, 10, 1000)
platform.Anchored = true
platform.Name = "LocalPlatform"
platform.Material = Enum.Material.Concrete
platform.Color = Color3.fromRGB(100, 100, 100)

-- Position it far away
local FAR_POSITION = Vector3.new(3000, 500, 3000)
platform.Position = FAR_POSITION
platform.Parent = workspace

-- Spawn position
local SPAWN_CFRAME = CFrame.new(FAR_POSITION + Vector3.new(0, 20, 0))

-- Teleport function
local function teleportCharacter(char)
	local hrp = char:WaitForChild("HumanoidRootPart")
	hrp.CFrame = SPAWN_CFRAME
end

-- Initial spawn
if player.Character then
	teleportCharacter(player.Character)
end

-- Respawn handling
local charConn
charConn = player.CharacterAdded:Connect(function(char)
	teleportCharacter(char)
	setupAntiTeleport(char)
end)

-- Anti-force-teleport
local antiTpConn
local lastSafeTime = 0
local TELEPORT_THRESHOLD = 200 -- studs away from platform before considered "forced"
local COOLDOWN = 1 -- seconds between corrections

function setupAntiTeleport(char)
	if antiTpConn then
		antiTpConn:Disconnect()
	end

	local hrp = char:WaitForChild("HumanoidRootPart")

	antiTpConn = RunService.Heartbeat:Connect(function()
		if not platform or not hrp then return end

		local distance = (hrp.Position - FAR_POSITION).Magnitude

		-- If too far away, assume forced teleport
		if distance > TELEPORT_THRESHOLD then
			if tick() - lastSafeTime > COOLDOWN then
				lastSafeTime = tick()
				hrp.CFrame = SPAWN_CFRAME
			end
		end
	end)
end

-- Run for current character
if player.Character then
	setupAntiTeleport(player.Character)
end

-- Create button
local function createButton()
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")

	local button = Instance.new("Part")
	button.Size = Vector3.new(2, .5, 1)
	button.Anchored = true
	button.Color = Color3.fromRGB(255, 0, 0)
	button.Name = "DeletePlatformButton"

	button.CFrame = hrp.CFrame * CFrame.new(0, -15, -5)
	button.Parent = workspace

	local click = Instance.new("ClickDetector")
	click.Parent = button

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = button

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = "DELETE PLATFORM"
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Parent = billboard

	-- Cleanup
	local function cleanup()
		if platform then
			platform:Destroy()
			platform = nil
		end

		if button then
			button:Destroy()
			button = nil
		end

		if charConn then
			charConn:Disconnect()
			charConn = nil
		end

		if antiTpConn then
			antiTpConn:Disconnect()
			antiTpConn = nil
		end
	end

	click.MouseClick:Connect(cleanup)
end

createButton()
