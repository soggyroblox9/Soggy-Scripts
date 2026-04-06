local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local toysFolder = workspace:WaitForChild(player.Name .. "SpawnedInToys")
local destroyToyRemote = ReplicatedStorage:WaitForChild("MenuToys"):WaitForChild("DestroyToy")

local tweenTime = 0.4
local rainbowSpeed = 2

local emitterName = "SecretPalletParticleEmitter"
local attachmentName = "SecretPalletParticleAttachment"
local targetPalletName = "PalletLightBrown"

local mode = 1
local rainbowT = 0
local stopped = false

local connections = {}
local palletConnections = {}
local watchedPallets = {}

local paletteModes = {
	{color = Color3.fromRGB(234, 215, 198), material = Enum.Material.WoodPlanks},
	{color = Color3.fromRGB(149, 121, 119), material = Enum.Material.WoodPlanks},
	{color = Color3.fromRGB(187, 179, 178), material = Enum.Material.WoodPlanks},
	{color = Color3.fromRGB(141, 135, 134), material = Enum.Material.WoodPlanks},
	{color = Color3.fromRGB(185, 196, 177), material = Enum.Material.WoodPlanks},
	{color = Color3.fromRGB(175, 148, 131), material = Enum.Material.WoodPlanks},
	{color = Color3.fromRGB(226, 220, 188), material = Enum.Material.WoodPlanks},
	{color = Color3.fromRGB(37, 52, 68), material = Enum.Material.WoodPlanks},
	{color = Color3.fromRGB(230, 230, 230), material = Enum.Material.WoodPlanks},
	{color = Color3.fromRGB(77, 207, 255), material = Enum.Material.Glass, particle = Color3.fromRGB(104, 247, 255)},
	{color = Color3.fromRGB(110, 58, 155), material = Enum.Material.Glass, particle = Color3.fromRGB(85, 57, 145)},
	{color = Color3.fromRGB(0, 180, 39), material = Enum.Material.Glass, particle = Color3.fromRGB(0, 171, 0)},
	{color = Color3.fromRGB(0, 11, 173), material = Enum.Material.Glass, particle = Color3.fromRGB(0, 47, 164)},
	{color = Color3.fromRGB(199, 174, 81), material = Enum.Material.Glass, particle = Color3.fromRGB(190, 143, 81)},
	{color = Color3.fromRGB(127, 0, 4), material = Enum.Material.Glass, particle = Color3.fromRGB(117, 1, 31)},
	{rainbow = true}
}

local rainbowColors = {
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(255, 127, 0),
	Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(0, 255, 0),
	Color3.fromRGB(0, 255, 255),
	Color3.fromRGB(0, 0, 255),
	Color3.fromRGB(127, 0, 255),
	Color3.fromRGB(255, 0, 127)
}

local function track(connection)
	connections[#connections + 1] = connection
	return connection
end

local function trackPalletConnection(pallet, connection)
	local bucket = palletConnections[pallet]
	if not bucket then
		bucket = {}
		palletConnections[pallet] = bucket
	end
	bucket[#bucket + 1] = connection
	return connection
end

local function disconnectList(list)
	for i = 1, #list do
		local connection = list[i]
		if connection then
			pcall(function()
				connection:Disconnect()
			end)
		end
	end
	table.clear(list)
end

local function disconnectPalletConnections(pallet)
	local bucket = palletConnections[pallet]
	if bucket then
		disconnectList(bucket)
		palletConnections[pallet] = nil
	end
end

local function disconnectAll()
	disconnectList(connections)

	for pallet, bucket in pairs(palletConnections) do
		disconnectList(bucket)
		palletConnections[pallet] = nil
		watchedPallets[pallet] = nil
	end
end

local previousStop = rawget(_G, "StopPalletCycler")
if typeof(previousStop) == "function" then
	pcall(previousStop)
end

local function lerpColor(a, b, t)
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

local function isTargetPallet(obj)
	return obj:IsA("Model") and obj.Name == targetPalletName
end

local function getPalletParts(pallet)
	local parts = {}
	for _, obj in ipairs(pallet:GetDescendants()) do
		if obj:IsA("BasePart") then
			parts[#parts + 1] = obj
		end
	end
	return parts
end

local function clearEffects(pallet)
	for _, obj in ipairs(pallet:GetDescendants()) do
		if obj:IsA("ParticleEmitter") and obj.Name == emitterName then
			obj:Destroy()
		elseif obj:IsA("Attachment") and obj.Name == attachmentName then
			obj:Destroy()
		end
	end
end

local function applyPart(part, color, material, instant)
	part.Material = material
	if instant then
		part.Color = color
	else
		TweenService:Create(part, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Color = color
		}):Play()
	end
end

local function randomTopSurfacePosition(part)
	local size = part.Size
	return Vector3.new(
		(math.random() - 0.5) * size.X,
		size.Y / 2,
		(math.random() - 0.5) * size.Z
	)
end

local function addEmitters(pallet, particleColor)
	clearEffects(pallet)

	local parts = getPalletParts(pallet)
	if #parts == 0 then
		return
	end

	for _ = 1, math.min(3, #parts) do
		local startPart = parts[math.random(1, #parts)]

		local attachment = Instance.new("Attachment")
		attachment.Name = attachmentName
		attachment.Position = randomTopSurfacePosition(startPart)
		attachment.Parent = startPart

		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = emitterName
		emitter.Enabled = false
		emitter.Texture = "rbxassetid://124330687039957"
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(1.6, 2)
		emitter.Speed = NumberRange.new(0.12, 0.28)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-8, 8)
		emitter.SpreadAngle = Vector2.new(20, 20)
		emitter.Acceleration = Vector3.new(0, 0.35, 0)
		emitter.LockedToPart = true
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Shape = Enum.ParticleEmitterShape.Box
		emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		emitter.ShapePartial = 1
		emitter.Color = ColorSequence.new(particleColor)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.5, 0.25),
			NumberSequenceKeypoint.new(1, 0.35)
		})
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45),
			NumberSequenceKeypoint.new(0.2, 0.2),
			NumberSequenceKeypoint.new(0.8, 0.45),
			NumberSequenceKeypoint.new(1, 1)
		})
		emitter.Parent = attachment

		task.spawn(function()
			while not stopped and pallet.Parent and attachment.Parent and emitter.Parent do
				local current = paletteModes[mode]
				if not current or not current.particle then
					task.wait(0.2)
				else
					local currentParts = getPalletParts(pallet)
					if #currentParts == 0 then
						break
					end

					local nextPart = currentParts[math.random(1, #currentParts)]
					attachment.Parent = nextPart
					attachment.Position = randomTopSurfacePosition(nextPart)
					emitter.Color = ColorSequence.new(current.particle)
					emitter:Emit(1)

					task.wait(math.random(2, 3))
				end
			end
		end)
	end
end

local function updatePallet(pallet, instant)
	local current = paletteModes[mode]
	if not current then
		return
	end

	clearEffects(pallet)

	if current.rainbow then
		for _, part in ipairs(getPalletParts(pallet)) do
			part.Material = Enum.Material.Neon
		end
		return
	end

	for _, part in ipairs(getPalletParts(pallet)) do
		applyPart(part, current.color, current.material, instant)
	end

	if current.particle then
		addEmitters(pallet, current.particle)
	end
end

local function updateAllPallets(instant)
	for _, obj in ipairs(toysFolder:GetChildren()) do
		if isTargetPallet(obj) then
			updatePallet(obj, instant)
		end
	end
end

local function watchPallet(pallet)
	if stopped or watchedPallets[pallet] or not isTargetPallet(pallet) then
		return
	end

	watchedPallets[pallet] = true
	updatePallet(pallet, true)

	trackPalletConnection(pallet, pallet.DescendantAdded:Connect(function(child)
		if stopped then
			return
		end
		if child:IsA("BasePart") then
			updatePallet(pallet, true)
		end
	end))

	trackPalletConnection(pallet, pallet.AncestryChanged:Connect(function(_, parent)
		if not parent then
			disconnectPalletConnections(pallet)
			watchedPallets[pallet] = nil
		end
	end))
end

local function destroyAllSpawnedToys()
	for _, toy in ipairs(toysFolder:GetChildren()) do
		if toy:IsA("Model") then
			destroyToyRemote:FireServer(toy)
		end
	end
end

local function stopPalletCycler()
	if stopped then
		return
	end

	stopped = true
	mode = 1
	updateAllPallets(true)
	disconnectAll()

	if rawget(_G, "StopPalletCycler") == stopPalletCycler then
		_G.StopPalletCycler = nil
	end
end

_G.StopPalletCycler = stopPalletCycler

for _, obj in ipairs(toysFolder:GetChildren()) do
	if isTargetPallet(obj) then
		watchPallet(obj)
	end
end

track(toysFolder.ChildAdded:Connect(function(obj)
	if stopped then
		return
	end
	if isTargetPallet(obj) then
		watchPallet(obj)
		updatePallet(obj, false)
	end
end))

track(RunService.RenderStepped:Connect(function(dt)
	if stopped then
		return
	end

	local current = paletteModes[mode]
	if not current or not current.rainbow then
		return
	end

	rainbowT += dt / rainbowSpeed * #rainbowColors

	local i1 = math.floor(rainbowT) % #rainbowColors + 1
	local i2 = i1 % #rainbowColors + 1
	local alpha = rainbowT - math.floor(rainbowT)
	local color = lerpColor(rainbowColors[i1], rainbowColors[i2], alpha)

	for _, obj in ipairs(toysFolder:GetChildren()) do
		if isTargetPallet(obj) then
			for _, part in ipairs(getPalletParts(obj)) do
				part.Color = color
				part.Material = Enum.Material.Neon
			end
		end
	end
end))

track(UserInputService.InputBegan:Connect(function(input, processed)
	if stopped or processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Y then
		destroyAllSpawnedToys()
		return
	end

	if input.KeyCode ~= Enum.KeyCode.P then
		return
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
		mode = 1
	else
		mode = mode % #paletteModes + 1
	end

	updateAllPallets(false)
end))

return stopPalletCycler
