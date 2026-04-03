local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local START_FOV = 90
local RESET_FOV = 70
local MAX_FOV = 120

local MAX_SPEED = 450
local MIN_ANGLE = -120
local MAX_ANGLE = 120

local SPEEDOMETER_IMAGE = "rbxassetid://84228149572004"
local FOV_IMAGE = "rbxassetid://111279510104567"

local LEFT_X = 5
local RIGHT_MARGIN = 5

local LEFT_SPEED_Y_OFFSET = -210
local LEFT_FOV_GAP = 4

local RIGHT_SPEED_Y_OFFSET = -285
local RIGHT_FOV_GAP = 6

local BASE_SPEED_SIZE = 160
local BASE_FOV_WIDTH = 140
local BASE_FOV_HEIGHT = 42

local NEEDLE_WIDTH = 3
local NEEDLE_HEIGHT = 53
local DOT_SIZE = 8

local LEFT_SCALE = 1
local RIGHT_SCALE = 1.35

local SPEED_TEXT_SIZE_LEFT = 18
local SPEED_TEXT_SIZE_RIGHT = 24

local FOV_TEXT_SIZE_LEFT = 27
local FOV_TEXT_SIZE_RIGHT = 36

local SIDE_TWEEN_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local FOV_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local smoothSpeed = 0
local frameCount = 0
local uiOnRight = false

camera.FieldOfView = START_FOV

local oldGui = playerGui:FindFirstChild("SpeedometerFOVGui")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SpeedometerFOVGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function make(className, props, parent)
	local obj = Instance.new(className)
	for k, v in pairs(props) do
		obj[k] = v
	end
	obj.Parent = parent
	return obj
end

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
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0
}, speedContainer)

local pivot = make("Frame", {
	Size = UDim2.new(0, 0, 0, 0),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1,
	BorderSizePixel = 0
}, speedOverlay)

local needle = make("Frame", {
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
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
	ZIndex = 3
}, speedOverlay)

make("UICorner", {
	CornerRadius = UDim.new(1, 0)
}, centerDot)

local speedLabel = make("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = false,
	TextSize = SPEED_TEXT_SIZE_LEFT,
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
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Font = Enum.Font.Michroma,
	Text = "",
	TextScaled = false,
	TextSize = FOV_TEXT_SIZE_LEFT,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	TextStrokeTransparency = 0.75,
	TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
}, fovContainer)

local function getMetrics(onRight)
	local scale = onRight and RIGHT_SCALE or LEFT_SCALE

	return {
		speedSize = math.floor(BASE_SPEED_SIZE * scale + 0.5),
		fovWidth = math.floor(BASE_FOV_WIDTH * scale + 0.5),
		fovHeight = math.floor(BASE_FOV_HEIGHT * scale + 0.5),
		needleWidth = math.max(3, math.floor(NEEDLE_WIDTH * scale + 0.5)),
		needleHeight = math.floor(NEEDLE_HEIGHT * scale + 0.5),
		dotSize = math.floor(DOT_SIZE * scale + 0.5),
		speedLabelWidth = math.floor(80 * scale + 0.5),
		speedLabelHeight = math.floor(24 * scale + 0.5),
		fovTextInset = math.floor(9 * scale + 0.5),
		fovTextPad = math.floor(18 * scale + 0.5),
		speedYOffset = onRight and RIGHT_SPEED_Y_OFFSET or LEFT_SPEED_Y_OFFSET,
		fovGap = onRight and RIGHT_FOV_GAP or LEFT_FOV_GAP,
		speedTextSize = onRight and SPEED_TEXT_SIZE_RIGHT or SPEED_TEXT_SIZE_LEFT,
		fovTextSize = onRight and FOV_TEXT_SIZE_RIGHT or FOV_TEXT_SIZE_LEFT
	}
end

local function applyElementSizing(onRight)
	local m = getMetrics(onRight)

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

local function getLayout(onRight)
	local m = getMetrics(onRight)

	local speedPos
	if onRight then
		speedPos = UDim2.new(1, -(m.speedSize + RIGHT_MARGIN), 1, m.speedYOffset)
	else
		speedPos = UDim2.new(0, LEFT_X, 1, m.speedYOffset)
	end

	local fovXOffset
	if onRight then
		fovXOffset = -(RIGHT_MARGIN + math.floor((m.speedSize + m.fovWidth) / 2 + 0.5))
	else
		fovXOffset = LEFT_X + math.floor((m.speedSize - m.fovWidth) / 2 + 0.5)
	end

	local fovPos = UDim2.new(
		speedPos.X.Scale,
		fovXOffset,
		1,
		m.speedYOffset + m.speedSize + m.fovGap
	)

	return speedPos, fovPos
end

local function updateFOVLabel()
	fovLabel.Text = "FOV: " .. math.floor(camera.FieldOfView)
end

local function setUISide(onRight, instant)
	uiOnRight = onRight
	applyElementSizing(onRight)

	local speedPos, fovPos = getLayout(onRight)

	if instant then
		speedContainer.Position = speedPos
		fovContainer.Position = fovPos
		return
	end

	TweenService:Create(speedContainer, SIDE_TWEEN_INFO, {
		Position = speedPos
	}):Play()

	TweenService:Create(fovContainer, SIDE_TWEEN_INFO, {
		Position = fovPos
	}):Play()
end

local function setCharacter(char)
	character = char
	root = char:WaitForChild("HumanoidRootPart")
	smoothSpeed = 0
	camera.FieldOfView = START_FOV
	updateFOVLabel()
end

applyElementSizing(false)
updateFOVLabel()
setUISide(false, true)

RunService.RenderStepped:Connect(function()
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
end)

camera:GetPropertyChangedSignal("FieldOfView"):Connect(updateFOVLabel)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
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
	elseif input.KeyCode == Enum.KeyCode.X and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		setUISide(not uiOnRight, false)
	end
end)

player.CharacterAdded:Connect(setCharacter)
