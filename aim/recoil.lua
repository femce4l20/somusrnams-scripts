local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local recoilKeywords = {
	"recoil",
	"camshake",
	"camerashake",
	"shake",
	"kick",
	"kickback",
	"viewbob",
	"sway"
}

local function matches(name)
	name = string.lower(name)

	for _, v in ipairs(recoilKeywords) do
		if string.find(name, v) then
			return true
		end
	end

	return false
end

-- disable recoil value objects if found
local function disableRecoilObjects(container)
	for _, obj in ipairs(container:GetDescendants()) do
		if matches(obj.Name) then
			pcall(function()
				if obj:IsA("NumberValue") or obj:IsA("IntValue") then
					obj.Value = 0
				elseif obj:IsA("Vector3Value") then
					obj.Value = Vector3.zero
				elseif obj:IsA("CFrameValue") then
					obj.Value = CFrame.new()
				end
			end)
		end
	end
end

disableRecoilObjects(player)

player.DescendantAdded:Connect(function(obj)
	task.defer(function()
		if matches(obj.Name) then
			pcall(function()
				if obj:IsA("NumberValue") or obj:IsA("IntValue") then
					obj.Value = 0
				elseif obj:IsA("Vector3Value") then
					obj.Value = Vector3.zero
				elseif obj:IsA("CFrameValue") then
					obj.Value = CFrame.new()
				end
			end)
		end
	end)
end)

-- camera recoil smoother
local lastLook = camera.CFrame.LookVector
local recoilStrength = 0.15 -- lower = less recoil correction

RunService.RenderStepped:Connect(function()
	camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local cf = camera.CFrame

	-- smoothly counter sudden recoil movement
	local currentLook = cf.LookVector
	local blendedLook = lastLook:Lerp(currentLook, recoilStrength)

	camera.CFrame = CFrame.new(cf.Position, cf.Position + blendedLook)

	lastLook = blendedLook

	-- prevent extreme FOV kick
	if camera.FieldOfView > 70 then
		camera.FieldOfView = camera.FieldOfView - ((camera.FieldOfView - 70) * 0.25)
	end
end)
