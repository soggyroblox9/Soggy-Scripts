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
local currentPitch, currentYaw = 0, 0
local targetPitch, targetYaw = 0, 0
local currentPos = Vector3.zero
local currentVelocity = Vector3.zero
local savedCameraType, savedCameraSubject
local returnRotation = CFrame.new()
local returnOffset = Vector3.zero
local stopped = false

local checkingEnabled = true
local lastTransparencyUpdate = 0
local TRANSPARENCY_UPDATE_INTERVAL = 1

local connections = {}

local function track(c)
	connections[#connections+1] = c
	return c
end

local function disconnectAll()
	for _,c in ipairs(connections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(connections)
end

local previousStop = rawget(_G, "StopFreeCam")
if typeof(previousStop) == "function" then
	pcall(previousStop)
end

local sensitivity = UserSettings():GetService("UserGameSettings").MouseSensitivity / 10

local oldGui = playerGui:FindFirstChild("FreecamSpeedGui")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FreecamSpeedGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local box = Instance.new("ImageLabel")
box.AnchorPoint = Vector2.new(0.5,1)
box.Position = BOX_POS_NORMAL
box.Size = UDim2.new(0,180,0,40)
box.BackgroundTransparency = 1
box.Image = "rbxassetid://111279510104567"
box.Parent = screenGui

local speedText = Instance.new("TextLabel")
speedText.AnchorPoint = Vector2.new(0.5,0.5)
speedText.Position = UDim2.new(0.5,0,0.5,-1)
speedText.Size = UDim2.new(1,-28,1,-20)
speedText.BackgroundTransparency = 1
speedText.TextColor3 = Color3.fromRGB(255,255,255)
speedText.TextSize = 18
speedText.Font = Enum.Font.Michroma
speedText.TextStrokeTransparency = 0.75
speedText.TextStrokeColor3 = Color3.new(1,1,1)
speedText.Parent = box

local function isSpeedometerActive()
	if rawget(_G,"StopSpeedometerFOVDisplay") or rawget(_G,"StopSpeedometer") or rawget(_G,"StopSpeedometerFOV") then
		return true
	end

	local names = {
		"SpeedometerFOVDisplay","SpeedometerFOVGui","SpeedometerGui",
		"SpeedometerDisplay","Speedometer","FOVSpeedometerGui"
	}

	for _,n in ipairs(names) do
		if playerGui:FindFirstChild(n) then return true end
	end

	for _,gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			local sps,fov=false,false
			for _,obj in ipairs(gui:GetDescendants()) do
				if obj:IsA("TextLabel") or obj:IsA("TextButton") then
					local t = obj.Text
					if t:find("SPS") then sps=true end
					if t:find("FOV") then fov=true end
				end
				if sps and fov then return true end
			end
		end
	end
	return false
end

local function updateBoxPosition()
	box.Position = isSpeedometerActive() and BOX_POS_SPEEDOMETER or BOX_POS_NORMAL
end

local function updateSpeedDisplay()
	if stopped then return end
	speedText.Text = freecamEnabled
		and ("Flyspeed = "..math.floor(flySpeed+0.5))
		or "Enable Freecam = C"
end

local function restoreCharacterTransparency()
	local char = player.Character
	if not char then return end
	for _,p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			p.LocalTransparencyModifier = 0
		end
	end
end

local function updateCharacterTransparency()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local fade = 1 - math.clamp(((camera.CFrame.Position - (root.Position+Vector3.new(0,2,0))).Magnitude-2)/10,0,1)

	for _,p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			p.LocalTransparencyModifier = fade
		end
	end
end

local function enable()
	freecamEnabled = true

	local cf = camera.CFrame
	local rx,ry = cf:ToEulerAnglesYXZ()

	returnRotation = cf - cf.Position
	returnOffset = cf.Position - camera.Focus.Position
	currentPos = cf.Position
	currentVelocity = Vector3.zero

	targetPitch,currentPitch = math.deg(rx),math.deg(rx)
	targetYaw,currentYaw = math.deg(ry),math.deg(ry)

	savedCameraType = camera.CameraType
	savedCameraSubject = camera.CameraSubject

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CameraSubject = terrain
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	updateSpeedDisplay()
end

local function disable()
	freecamEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	camera.CameraType = savedCameraType or Enum.CameraType.Custom
	camera.CameraSubject = savedCameraSubject
	restoreCharacterTransparency()
	updateSpeedDisplay()
end

local function stopFreeCam()
	if stopped then return end
	stopped = true

	disable()
	disconnectAll()
	screenGui:Destroy()

	if rawget(_G,"StopFreeCam")==stopFreeCam then
		_G.StopFreeCam=nil
	end
end

_G.StopFreeCam = stopFreeCam

track(mouse.KeyDown:Connect(function(key)
	if stopped or UserInputService:GetFocusedTextBox() then return end
	key = key:lower()

	if key=="l" then
		checkingEnabled = not checkingEnabled
		return
	end

	if key~=TOGGLE_KEY then return end

	if freecamEnabled then disable() else enable() end
end))

track(UserInputService.InputChanged:Connect(function(input,gp)
	if stopped then return end
	if freecamEnabled and not gp and input.UserInputType==Enum.UserInputType.MouseWheel then
		flySpeed = math.clamp(flySpeed + input.Position.Z*SPEED_STEP,MIN_SPEED,MAX_SPEED)
		updateSpeedDisplay()
	end
end))

task.spawn(function()
	while not stopped do
		if checkingEnabled then
			updateBoxPosition()
		end
		task.wait(1)
	end
end)

track(RunService.RenderStepped:Connect(function(dt)
	if stopped or not freecamEnabled then return end

	if UserInputService.MouseBehavior~=Enum.MouseBehavior.LockCenter then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end

	if camera.CameraSubject~=terrain then
		camera.CameraSubject = terrain
	end

	if tick()-lastTransparencyUpdate>=TRANSPARENCY_UPDATE_INTERVAL then
		lastTransparencyUpdate = tick()
		updateCharacterTransparency()
	end

	local delta = UserInputService:GetMouseDelta()
	targetPitch -= delta.Y*sensitivity*camera.FieldOfView
	targetYaw -= delta.X*sensitivity*camera.FieldOfView

	currentPitch += (targetPitch-currentPitch)*math.clamp(ROTATION_SMOOTHING*dt,0,1)
	currentYaw += (targetYaw-currentYaw)*math.clamp(ROTATION_SMOOTHING*dt,0,1)

	local rot = CFrame.Angles(0,math.rad(currentYaw),0)*CFrame.Angles(math.rad(currentPitch),0,0)

	local move = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then move+=Vector3.new(0,0,-2) end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then move+=Vector3.new(0,0,2) end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then move+=Vector3.new(-2,0,0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then move+=Vector3.new(2,0,0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move+=Vector3.new(0,2,0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move+=Vector3.new(0,-2,0) end

	local targetVel = move.Magnitude>0 and (rot*move.Unit)*flySpeed or Vector3.zero
	currentVelocity = currentVelocity:Lerp(targetVel,math.clamp((move.Magnitude>0 and MOVEMENT_ACCELERATION or MOVEMENT_FRICTION)*dt,0,10))

	currentPos += currentVelocity*dt
	camera.CFrame = CFrame.new(currentPos)*rot
end))

updateSpeedDisplay()
updateBoxPosition()

return stopFreeCam
