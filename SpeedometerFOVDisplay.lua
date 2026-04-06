local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local RESET_FOV = 70
local MAX_FOV = 120

local MAX_SPEED = 450
local MIN_ANGLE = -120
local MAX_ANGLE = 120

local SPEEDOMETER_IMAGE = "rbxassetid://84228149572004"
local FOV_IMAGE = "rbxassetid://111279510104567"

local RIGHT_MARGIN = 5
local SPEED_Y_OFFSET = -235
local FOV_GAP = 5

local BASE_SPEED_SIZE = 160
local BASE_FOV_WIDTH = 140
local BASE_FOV_HEIGHT = 42

local NEEDLE_WIDTH = 3
local NEEDLE_HEIGHT = 53
local DOT_SIZE = 8

local UI_SCALE = 1.1

local SPEED_TEXT_SIZE = 21
local FOV_TEXT_SIZE = 32

local FOV_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

local smoothSpeed = 0
local frameCount = 0
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

local function make(className, props, parent)
	local obj = Instance.new(className)
	for key, value in pairs(props) do
		obj[key] = value
	end
	obj.Parent = parent
	return obj
end

local previousStop = rawget(_G, "StopSpeedometerFOV")
if typeof(previousStop) == "function" then
	pcall(previousStop)
end

local oldGui = playerGui:FindFirstChild("SpeedometerFOVGui")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SpeedometerFOVGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local speedContainer = make("Frame", {
	Name = "SpeedContainer",
	BackgroundTransparency = 1,
	BorderSizePixel = 0
}, gui)

make("ImageLabel", {
	Name = "SpeedBackground",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Image = SPEEDOMETER_IMAGE,
	ScaleType = Enum.ScaleType.Stretch
}, speedContainer)

local speedOverlay = make("Frame", {
	Name = "SpeedOverlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0
}, speedContainer)

local pivot = make("Frame", {
	Name = "Pivot",
	Size = UDim2.new(0, 0, 0, 0),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1,
	BorderSizePixel = 0
}, speedOverlay)

local needle = make("Frame", {
	Name = "Needle",
	AnchorPoint = Vector2.new(0.5, 1),
	BackgroundColor3 = Color3.fromRGB(255, 0, 0),
	BackgroundTransparency = 0.3,
	BorderSizePixel = 0,
	ZIndex = 2
}, pivot)

make("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
}, needle)

local centerDot = make("Frame", {
	Name = "CenterDot",
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
	ZIndex = 3
}, speedOverlay)

make("UICorner", {
	CornerRadius = UDim.new(1, 0)
}, centerDot)

local speedLabel = make("TextLabel", {
	Name = "SpeedLabel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = false,
	TextSize = SPEED_TEXT_SIZE,
	Font = Enum.Font.Michroma,
	Text = "0 SPS",
	TextStrokeTransparency = 0.75,
	TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
	ZIndex = 4
}, speedOverlay)

local fovContainer = make("Frame", {
	Name = "FOVContainer",
	BackgroundTransparency = 1,
	BorderSizePixel = 0
}, gui)

make("ImageLabel", {
	Name = "FOVBackground",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Image = FOV_IMAGE,
	ScaleType = Enum.ScaleType.Stretch
}, fovContainer)

local fovLabel = make("TextLabel", {
	Name = "FOVLabel",
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Font = Enum.Font.Michroma,
	Text = "",
	TextScaled = false,
	TextSize = FOV_TEXT_SIZE,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	TextStrokeTransparency = 0.75,
	TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
}, fovContainer)

local function getMetrics()
	return {
		speedSize = math.floor(BASE_SPEED_SIZE * UI_SCALE + 0.5),
		fovWidth = math.floor(BASE_FOV_WIDTH * UI_SCALE + 0.5),
		fovHeight = math.floor(BASE_FOV_HEIGHT * UI_SCALE + 0.5),
		needleWidth = math.max(3, math.floor(NEEDLE_WIDTH * UI_SCALE + 0.5)),
		needleHeight = math.floor(NEEDLE_HEIGHT * UI_SCALE + 0.5),
		dotSize = math.floor(DOT_SIZE * UI_SCALE + 0.5),
		speedLabelWidth = math.floor(80 * UI_SCALE + 0.5),
		speedLabelHeight = math.floor(24 * UI_SCALE + 0.5),
		fovTextInset = math.floor(9 * UI_SCALE + 0.5),
		fovTextPad = math.floor(18 * UI_SCALE + 0.5),
		speedTextSize = SPEED_TEXT_SIZE,
		fovTextSize = FOV_TEXT_SIZE
	}
end

local function applyElementSizing()
	local m = getMetrics()

	speedContainer.Size = UDim2.new(0, m.speedSize, 0, m.speedSize)
	fovContainer.Size = UDim2.new(0, m.fovWidth, 0, m.fovHeight)

	needle.Size = UDim2.new(0, m.needleWidth, 0, m.needleHeight)

	centerDot.Size = UDim2.new(0, m.dotSize, 0, m.dotSize)
	centerDot.Position = UDim2.new(0.5, -m.dotSize / 2, 0.5, -m.dotSize / 2)

	speedLabel.Size = UDim2.new(0, m.speedLabelWidth, 0, m.speedLabelHeight)
	speedLabel.Position = UDim2.new(0.5, 0, 0.78, 0)
	speedLabel.TextSize = m.speedTextSize

	fovLabel.Size = UDim2.new(1, -m.fovTextPad, 1, 0)
	fovLabel.Position = UDim2.new(0, m.fovTextInset, 0, 0)
	fovLabel.TextSize = m.fovTextSize
end

local function applyLayout()
	local m = getMetrics()

	local speedPos = UDim2.new(1, -(m.speedSize + RIGHT_MARGIN), 1, SPEED_Y_OFFSET)
	local fovPos = UDim2.new(
		1,
		-(RIGHT_MARGIN + math.floor((m.speedSize + m.fovWidth) / 2 + 0.5)),
		1,
		SPEED_Y_OFFSET + m.speedSize + FOV_GAP
	)

	speedContainer.Position = speedPos
	fovContainer.Position = fovPos
end

local function updateFOVLabel()
	if stopped then
		return
	end
	fovLabel.Text = "FOV: " .. math.floor(camera.FieldOfView)
end

local function setCharacter(char)
	if stopped then
		return
	end

	character = char
	root = char:WaitForChild("HumanoidRootPart")
	smoothSpeed = 0
	updateFOVLabel()
end

local function stopSpeedometerFOV()
	if stopped then
		return
	end

	stopped = true
	disconnectAll()

	pcall(function()
		camera.FieldOfView = RESET_FOV
	end)

	pcall(function()
		gui:Destroy()
	end)

	if rawget(_G, "StopSpeedometerFOV") == stopSpeedometerFOV then
		_G.StopSpeedometerFOV = nil
	end
	if rawget(_G, "StopSpeedometerFOVDisplay") == stopSpeedometerFOV then
		_G.StopSpeedometerFOVDisplay = nil
	end
	if rawget(_G, "StopSpeedometer") == stopSpeedometerFOV then
		_G.StopSpeedometer = nil
	end
end

_G.StopSpeedometerFOV = stopSpeedometerFOV
_G.StopSpeedometerFOVDisplay = stopSpeedometerFOV
_G.StopSpeedometer = stopSpeedometerFOV

applyElementSizing()
applyLayout()
updateFOVLabel()

track(RunService.RenderStepped:Connect(function()
	if stopped then
		return
	end

	if not root or not root.Parent then
		local currentCharacter = player.Character
		root = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart") or nil
		updateFOVLabel()
		return
	end

	frameCount += 1
	if frameCount < 3 then
		updateFOVLabel()
		return
	end
	frameCount = 0

	local rawSpeed = root.AssemblyLinearVelocity.Magnitude
	smoothSpeed += (rawSpeed - smoothSpeed) * 0.1

	local normalized = math.clamp(smoothSpeed / MAX_SPEED, 0, 1)
	pivot.Rotation = MIN_ANGLE + (MAX_ANGLE - MIN_ANGLE) * normalized
	speedLabel.Text = math.floor(smoothSpeed) .. " SPS"
	updateFOVLabel()
end))

track(camera:GetPropertyChangedSignal("FieldOfView"):Connect(updateFOVLabel))

track(UserInputService.InputBegan:Connect(function(input, processed)
	if stopped or processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.F then
		TweenService:Create(camera, FOV_TWEEN_INFO, {
			FieldOfView = math.min(camera.FieldOfView + 10, MAX_FOV)
		}):Play()
	elseif input.KeyCode == Enum.KeyCode.T then
		TweenService:Create(camera, FOV_TWEEN_INFO, {
			FieldOfView = RESET_FOV
		}):Play()
	end
end))

track(player.CharacterAdded:Connect(setCharacter))

return stopSpeedometerFOV
