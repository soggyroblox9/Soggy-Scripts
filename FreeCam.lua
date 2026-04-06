local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local terrain = workspace:FindFirstChildOfClass("Terrain") or workspace

local TOGGLE_KEY = "c"
local MOVE_BLOCK_ACTION = "FreecamFreezeMovement"
local CLICK_BLOCK_ACTION = "FreecamBlockClick"

local DEFAULT_SPEED = 100
local MIN_SPEED = 10
local MAX_SPEED = 999
local SPEED_STEP = 25
local ROTATION_SMOOTHING = 8
local MOVEMENT_ACCELERATION = 10
local MOVEMENT_FRICTION = 8
local RETURN_TIME = 0.35

local BOX_POS_NORMAL = UDim2.new(0.5, 670, 1, -8)
local BOX_POS_SPEEDOMETER = UDim2.new(0.5, 500, 1, -8)

local freecamEnabled = false
local flySpeed = DEFAULT_SPEED
local currentPitch = 0
local currentYaw = 0
local targetPitch = 0
local targetYaw = 0
local currentPos = Vector3.zero
local currentVelocity = Vector3.zero
local savedCameraType
local savedCameraSubject
local returnRotation = CFrame.new()
local returnOffset = Vector3.zero
local stopped = false

local connections = {}

local function track(connection)
	connections[#connections + 1] = connection
	return connection
end

local function disconnectAll()
	for i = 1, #connections do
		local connection = connections[i]
		if connection then
			pcall(function()
				connection:Disconnect()
			end)
		end
	end
	table.clear(connections)
end

local previousStop = rawget(_G, "StopFreeCam")
if typeof(previousStop) == "function" then
	pcall(previousStop)
end

local userGameSettings = UserSettings():GetService("UserGameSettings")
local sensitivity = userGameSettings.MouseSensitivity / 10

local oldGui = playerGui:FindFirstChild("FreecamSpeedGui")
if oldGui then
	oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FreecamSpeedGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local box = Instance.new("ImageLabel")
box.Name = "Box"
box.AnchorPoint = Vector2.new(0.5, 1)
box.Position = BOX_POS_NORMAL
box.Size = UDim2.new(0, 180, 0, 40)
box.BackgroundTransparency = 1
box.Image = "rbxassetid://111279510104567"
box.Parent = screenGui

local speedText = Instance.new("TextLabel")
speedText.Name = "SpeedText"
speedText.AnchorPoint = Vector2.new(0.5, 0.5)
speedText.Position = UDim2.new(0.5, 0, 0.5, -1)
speedText.Size = UDim2.new(1, -28, 1, -20)
speedText.BackgroundTransparency = 1
speedText.TextColor3 = Color3.fromRGB(255, 255, 255)
speedText.TextSize = 18
speedText.Font = Enum.Font.Michroma
speedText.TextXAlignment = Enum.TextXAlignment.Center
speedText.TextYAlignment = Enum.TextYAlignment.Center
speedText.TextStrokeTransparency = 0.75
speedText.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
speedText.Parent = box

local function isSpeedometerActive()
	if rawget(_G, "StopSpeedometerFOVDisplay") or rawget(_G, "StopSpeedometer") or rawget(_G, "StopSpeedometerFOV") then
		return true
	end

	local guiNames = {
		"SpeedometerFOVDisplay",
		"SpeedometerFOVGui",
		"SpeedometerGui",
		"SpeedometerDisplay",
		"Speedometer",
		"FOVSpeedometerGui",
	}

	for _, name in ipairs(guiNames) do
		if playerGui:FindFirstChild(name) then
			return true
		end
	end

	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			local hasSPS = false
			local hasFOV = false

			for _, obj in ipairs(gui:GetDescendants()) do
				if obj:IsA("TextLabel") or obj:IsA("TextButton") then
					local text = tostring(obj.Text)
					if text:find("SPS") then
						hasSPS = true
					end
					if text:find("FOV") then
						hasFOV = true
					end
				end

				if hasSPS and hasFOV then
					return true
				end
			end
		end
	end

	return false
end

local function updateBoxPosition()
	box.Position = isSpeedometerActive() and BOX_POS_SPEEDOMETER or BOX_POS_NORMAL
end

local function updateSpeedDisplay()
	if stopped then
		return
	end

	updateBoxPosition()

	speedText.Text = freecamEnabled
		and ("Flyspeed = " .. math.floor(flySpeed + 0.5))
		or "Enable Freecam = C"
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function sinkInput()
	return Enum.ContextActionResult.Sink
end

local function restoreCharacterTransparency()
	local character = player.Character
	if not character then
		return
	end

	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.LocalTransparencyModifier = 0
		end
	end
end

local function setFreecamControls(enabled)
	if enabled then
		ContextActionService:UnbindAction(MOVE_BLOCK_ACTION)
		ContextActionService:UnbindAction(CLICK_BLOCK_ACTION)
		if savedCameraSubject then
			camera.CameraSubject = savedCameraSubject
		end
		return
	end

	ContextActionService:BindActionAtPriority(
		MOVE_BLOCK_ACTION,
		sinkInput,
		false,
		2001,
		Enum.KeyCode.W,
		Enum.KeyCode.A,
		Enum.KeyCode.S,
		Enum.KeyCode.D,
		Enum.KeyCode.Space,
		Enum.KeyCode.LeftShift
	)

	ContextActionService:BindActionAtPriority(
		CLICK_BLOCK_ACTION,
		sinkInput,
		false,
		2001,
		Enum.UserInputType.MouseButton1,
		Enum.UserInputType.MouseButton2
	)
end

local function updateCharacterTransparency()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local fade = 1 - math.clamp(((camera.CFrame.Position - (root.CFrame * CFrame.new(0, 2, 0)).Position).Magnitude - 2) / 10, 0, 1)

	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.LocalTransparencyModifier = fade
		end
	end
end

local function enable()
	if stopped then
		return
	end

	freecamEnabled = true

	local camCFrame = camera.CFrame
	local rx, ry = camCFrame:ToEulerAnglesYXZ()

	returnRotation = camCFrame - camCFrame.Position
	returnOffset = camCFrame.Position - camera.Focus.Position
	currentPos = camCFrame.Position
	currentVelocity = Vector3.zero
	targetPitch, currentPitch = math.deg(rx), math.deg(rx)
	targetYaw, currentYaw = math.deg(ry), math.deg(ry)

	savedCameraType = camera.CameraType
	savedCameraSubject = camera.CameraSubject

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CameraSubject = terrain
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	setFreecamControls(false)
	updateSpeedDisplay()
end

local function disable(skipTween)
	freecamEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if root then
		if skipTween then
			local targetCFrame = CFrame.new(root.Position + Vector3.new(0, 2, 0) + returnOffset) * returnRotation
			camera.CFrame = targetCFrame
		else
			local startTime = tick()
			local startCFrame = camera.CFrame
			local targetCFrame = CFrame.new(root.Position + Vector3.new(0, 2, 0) + returnOffset) * returnRotation

			while tick() - startTime < RETURN_TIME do
				if stopped or freecamEnabled then
					return
				end

				local alpha = math.clamp((tick() - startTime) / RETURN_TIME, 0, 1)
				camera.CFrame = startCFrame:Lerp(targetCFrame, alpha)
				updateCharacterTransparency()
				task.wait()
			end

			camera.CFrame = targetCFrame
		end
	end

	camera.CameraType = savedCameraType or Enum.CameraType.Custom
	camera.CameraSubject = savedCameraSubject
	setFreecamControls(true)
	restoreCharacterTransparency()
	updateSpeedDisplay()
end

local function teleportDisable()
	freecamEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if root then
		local rotation =
			CFrame.Angles(0, math.rad(currentYaw), 0) *
			CFrame.Angles(math.rad(currentPitch), 0, 0)

		root.CFrame = CFrame.new(currentPos) * CFrame.Angles(0, math.rad(currentYaw), 0)
		camera.CFrame = CFrame.new(currentPos) * rotation
	end

	camera.CameraType = savedCameraType or Enum.CameraType.Custom
	camera.CameraSubject = savedCameraSubject
	setFreecamControls(true)
	restoreCharacterTransparency()
	updateSpeedDisplay()
end

local function stopFreeCam()
	if stopped then
		return
	end

	stopped = true

	if freecamEnabled then
		disable(true)
	else
		setFreecamControls(true)
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		camera.CameraType = savedCameraType or Enum.CameraType.Custom
		if savedCameraSubject then
			camera.CameraSubject = savedCameraSubject
		end
		restoreCharacterTransparency()
	end

	disconnectAll()

	pcall(function()
		screenGui:Destroy()
	end)

	if rawget(_G, "StopFreeCam") == stopFreeCam then
		_G.StopFreeCam = nil
	end
end

_G.StopFreeCam = stopFreeCam

track(userGameSettings:GetPropertyChangedSignal("MouseSensitivity"):Connect(function()
	if stopped then
		return
	end
	sensitivity = userGameSettings.MouseSensitivity / 10
end))

track(mouse.KeyDown:Connect(function(key)
	if stopped or key:lower() ~= TOGGLE_KEY or UserInputService:GetFocusedTextBox() then
		return
	end

	local ctrlHeld =
		UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or
		UserInputService:IsKeyDown(Enum.KeyCode.RightControl)

	if ctrlHeld then
		if freecamEnabled then
			teleportDisable()
		end
		return
	end

	if freecamEnabled then
		disable()
	else
		enable()
	end
end))

track(UserInputService.InputBegan:Connect(function(input)
	if stopped then
		return
	end

	if freecamEnabled and input.UserInputType == Enum.UserInputType.MouseButton3 then
		flySpeed = DEFAULT_SPEED
		updateSpeedDisplay()
	end
end))

track(UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if stopped then
		return
	end

	if freecamEnabled and not gameProcessed and input.UserInputType == Enum.UserInputType.MouseWheel then
		flySpeed = math.clamp(flySpeed + input.Position.Z * SPEED_STEP, MIN_SPEED, MAX_SPEED)
		updateSpeedDisplay()
	end
end))

track(player.CharacterAdded:Connect(function()
	if stopped then
		return
	end

	restoreCharacterTransparency()

	if freecamEnabled then
		setFreecamControls(false)
	end
end))

track(playerGui.ChildAdded:Connect(function()
	if stopped then
		return
	end
	task.defer(updateBoxPosition)
end))

track(playerGui.ChildRemoved:Connect(function()
	if stopped then
		return
	end
	task.defer(updateBoxPosition)
end))

track(RunService.RenderStepped:Connect(function(dt)
	if stopped then
		return
	end

	updateBoxPosition()

	if not freecamEnabled then
		return
	end

	if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end

	if camera.CameraSubject ~= terrain then
		camera.CameraSubject = terrain
	end

	updateCharacterTransparency()

	local delta = UserInputService:GetMouseDelta()
	targetPitch -= delta.Y * sensitivity * camera.FieldOfView
	targetYaw -= delta.X * sensitivity * camera.FieldOfView

	local rotationAlpha = math.clamp(ROTATION_SMOOTHING * dt, 0, 1)
	currentPitch = lerp(currentPitch, targetPitch, rotationAlpha)
	currentYaw = lerp(currentYaw, targetYaw, rotationAlpha)

	local rotation = CFrame.Angles(0, math.rad(currentYaw), 0) * CFrame.Angles(math.rad(currentPitch), 0, 0)

	local moveInput = Vector3.zero
	if not UserInputService:GetFocusedTextBox() then
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveInput += Vector3.new(0, 0, -2) end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveInput += Vector3.new(0, 0, 2) end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveInput += Vector3.new(-2, 0, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveInput += Vector3.new(2, 0, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveInput += Vector3.new(0, 2, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveInput += Vector3.new(0, -2, 0) end
	end

	local targetVelocity = moveInput.Magnitude > 0 and (rotation * moveInput.Unit) * flySpeed or Vector3.zero
	local velocityLerp = math.clamp((moveInput.Magnitude > 0 and MOVEMENT_ACCELERATION or MOVEMENT_FRICTION) * dt, 0, 10)

	currentVelocity = currentVelocity:Lerp(targetVelocity, velocityLerp)
	currentPos += currentVelocity * dt
	camera.CFrame = CFrame.new(currentPos) * rotation
end))

updateSpeedDisplay()
updateBoxPosition()
