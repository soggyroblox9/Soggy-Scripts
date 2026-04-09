local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "SpeedometerGui"

local BACKGROUND_IMAGE = "rbxassetid://98216964162336"
local BORDER_IMAGE = "rbxassetid://106775962283164"

local DIAL_MAX_SPS = 450
local MIN_ANGLE = -120
local MAX_ANGLE = 120

local RIGHT_MARGIN = 0
local BOTTOM_OFFSET = -175
local SPEED_SIZE = 176

local NEEDLE_WIDTH = 4
local NEEDLE_HEIGHT = 58
local NEEDLE_COLOR = Color3.fromRGB(255, 15, 15)

local CENTER_DOT_SIZE = 10

local SPEED_TEXT_SIZE = 21
local SPEED_TEXT_WIDTH = 96
local SPEED_TEXT_HEIGHT = 26

local UNIT_TEXT_SIZE = 14
local UNIT_TEXT_WIDTH = 70
local UNIT_TEXT_HEIGHT = 16

local TICK_COLOR = Color3.fromRGB(50, 240, 50)
local TICK_LABEL_COLOR = Color3.fromRGB(255, 255, 255)

local MAJOR_TICK_LENGTH = 16
local MAJOR_TICK_THICKNESS = 4
local MINOR_TICK_LENGTH = 8
local MINOR_TICK_THICKNESS = 2
local TICK_RADIUS = 60
local LABEL_RADIUS = 48.5

local SMOOTHING = 0.1
local SHAKE_START_SPEED = 380
local SHAKE_AMOUNT = 2

local UNIT_MODES = { "SPS", "KMH", "MPH" }

local UNIT_DATA = {
	SPS = { ticks = { 0, 50, 100, 150, 200, 250, 300, 350, 400, 450 } },
	KMH = { ticks = { 0, 15, 30, 45, 60, 75, 90, 105, 120, 135 } },
	MPH = { ticks = { 0, 10, 20, 30, 40, 50, 60, 70, 80, 90 } },
}

local currentUnitIndex = 1
local stopped = false
local connections = {}

local character = player.Character or player.CharacterAdded:Wait()
local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
local smoothSpeed = 0
local gui

local function track(connection)
	connections[#connections + 1] = connection
	return connection
end

local function disconnectAll()
	for i = 1, #connections do
		local connection = connections[i]
		if connection then
			connection:Disconnect()
		end
	end
	table.clear(connections)
end

local function create(className, properties, parent)
	local object = Instance.new(className)
	for key, value in pairs(properties) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function addCorner(instance, scale)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(scale, 0)
	corner.Parent = instance
	return corner
end

local function clearChildren(instance)
	for _, child in ipairs(instance:GetChildren()) do
		child:Destroy()
	end
end

local function getUnitName()
	return UNIT_MODES[currentUnitIndex]
end

local function getDisplayValue(speedSPS)
	local unitName = getUnitName()

	if unitName == "KMH" then
		return speedSPS * 0.3
	elseif unitName == "MPH" then
		return speedSPS * 0.186411
	end

	return speedSPS
end

local function getNeedleAlpha(speedSPS)
	return math.clamp(speedSPS / DIAL_MAX_SPS, 0, 1)
end

local previousStop = rawget(_G, "StopSpeedometer")
if typeof(previousStop) == "function" then
	pcall(previousStop)
end

local oldGui = playerGui:FindFirstChild(GUI_NAME)
if oldGui then
	oldGui:Destroy()
end

gui = create("ScreenGui", {
	Name = GUI_NAME,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
}, playerGui)

local container = create("Frame", {
	Name = "Container",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(0, SPEED_SIZE, 0, SPEED_SIZE),
	Position = UDim2.new(1, -(SPEED_SIZE + RIGHT_MARGIN), 1, BOTTOM_OFFSET),
}, gui)

create("ImageLabel", {
	Name = "Background",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	Image = BACKGROUND_IMAGE,
	ScaleType = Enum.ScaleType.Stretch,
	ZIndex = 1,
}, container)

local dialLayer = create("Frame", {
	Name = "DialLayer",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 2,
}, container)

local tickFolder = create("Folder", {
	Name = "Ticks",
}, dialLayer)

local labelFolder = create("Folder", {
	Name = "Labels",
}, dialLayer)

local pivot = create("Frame", {
	Name = "Pivot",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 0, 0, 0),
	Position = UDim2.fromScale(0.5, 0.5),
	Rotation = MIN_ANGLE,
	ZIndex = 3,
}, dialLayer)

local needle = create("Frame", {
	Name = "Needle",
	AnchorPoint = Vector2.new(0.5, 1),
	BackgroundColor3 = NEEDLE_COLOR,
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
	Size = UDim2.new(0, NEEDLE_WIDTH, 0, NEEDLE_HEIGHT),
	ZIndex = 4,
}, pivot)
addCorner(needle, 1)

local centerDot = create("Frame", {
	Name = "CenterDot",
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
	Size = UDim2.new(0, CENTER_DOT_SIZE, 0, CENTER_DOT_SIZE),
	Position = UDim2.new(0.5, -CENTER_DOT_SIZE / 2, 0.5, -CENTER_DOT_SIZE / 2),
	ZIndex = 5,
}, dialLayer)
addCorner(centerDot, 1)

local speedLabel = create("TextLabel", {
	Name = "SpeedLabel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 0, 0.71, 0),
	Size = UDim2.new(0, SPEED_TEXT_WIDTH, 0, SPEED_TEXT_HEIGHT),
	Text = "0",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = SPEED_TEXT_SIZE,
	Font = Enum.Font.Michroma,
	TextScaled = false,
	TextStrokeTransparency = 0.75,
	TextStrokeColor3 = Color3.fromRGB(255, 255, 255),
	ZIndex = 6,
}, dialLayer)

local unitLabel = create("TextLabel", {
	Name = "UnitLabel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Position = UDim2.new(0.5, 0, 0.80, 0),
	Size = UDim2.new(0, UNIT_TEXT_WIDTH, 0, UNIT_TEXT_HEIGHT),
	Text = "SPS",
	TextColor3 = TICK_LABEL_COLOR,
	TextSize = UNIT_TEXT_SIZE,
	Font = Enum.Font.Michroma,
	TextScaled = false,
	TextStrokeTransparency = 0.8,
	TextStrokeColor3 = TICK_LABEL_COLOR,
	ZIndex = 6,
}, dialLayer)

create("ImageLabel", {
	Name = "Border",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	Image = BORDER_IMAGE,
	ScaleType = Enum.ScaleType.Stretch,
	ZIndex = 10,
}, container)

local function createTick(angle, radius, length, thickness, zIndex)
	local holder = create("Frame", {
		Name = "TickHolder",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 0, 0, 0),
		Rotation = angle,
		ZIndex = zIndex,
	}, tickFolder)

	local tick = create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = TICK_COLOR,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, -radius),
		Size = UDim2.new(0, thickness, 0, length),
		ZIndex = zIndex + 1,
	}, holder)

	addCorner(tick, 1)
end

local function polarToScale(angleDegrees, radiusPixels)
	local radians = math.rad(angleDegrees - 90)
	local radiusScale = radiusPixels / SPEED_SIZE
	return 0.5 + math.cos(radians) * radiusScale, 0.5 + math.sin(radians) * radiusScale
end

local function createTickLabel(angle, value)
	local x, y = polarToScale(angle, LABEL_RADIUS)

	create("TextLabel", {
		Name = "TickLabel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(x, y),
		Size = UDim2.new(0, 34, 0, 14),
		Text = tostring(value),
		TextColor3 = TICK_LABEL_COLOR,
		TextSize = 8,
		Font = Enum.Font.Michroma,
		TextScaled = false,
		TextStrokeTransparency = 0.8,
		TextStrokeColor3 = TICK_LABEL_COLOR,
		ZIndex = 6,
	}, labelFolder)
end

local function rebuildDial()
	clearChildren(tickFolder)
	clearChildren(labelFolder)

	local tickValues = UNIT_DATA[getUnitName()].ticks
	local majorCount = #tickValues
	local majorStepAngle = (MAX_ANGLE - MIN_ANGLE) / (majorCount - 1)

	for i = 1, majorCount do
		local angle = MIN_ANGLE + (i - 1) * majorStepAngle

		createTick(angle, TICK_RADIUS, MAJOR_TICK_LENGTH, MAJOR_TICK_THICKNESS, 3)
		createTickLabel(angle, tickValues[i])

		if i < majorCount then
			createTick(
				angle + majorStepAngle / 2,
				TICK_RADIUS + 1,
				MINOR_TICK_LENGTH,
				MINOR_TICK_THICKNESS,
				2
			)
		end
	end
end

local function refreshDisplay(displayValue)
	displayValue = displayValue or getDisplayValue(smoothSpeed)
	speedLabel.Text = tostring(math.floor(displayValue + 0.5))
	unitLabel.Text = getUnitName()
end

local function setCharacter(newCharacter)
	if stopped then
		return
	end

	character = newCharacter
	root = newCharacter:FindFirstChild("HumanoidRootPart") or newCharacter:WaitForChild("HumanoidRootPart")
	smoothSpeed = 0
	pivot.Rotation = MIN_ANGLE
	refreshDisplay(0)
end

local function stopSpeedometer()
	if stopped then
		return
	end

	stopped = true
	disconnectAll()

	if gui then
		gui:Destroy()
		gui = nil
	end

	character = nil
	root = nil

	if rawget(_G, "StopSpeedometer") == stopSpeedometer then
		_G.StopSpeedometer = nil
	end
end

_G.StopSpeedometer = stopSpeedometer

rebuildDial()
refreshDisplay(0)

track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if stopped or gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.U then
		currentUnitIndex += 1
		if currentUnitIndex > #UNIT_MODES then
			currentUnitIndex = 1
		end

		rebuildDial()
		refreshDisplay()
	end
end))

track(RunService.RenderStepped:Connect(function()
	if stopped then
		return
	end

	if not root or not root.Parent then
		local currentCharacter = player.Character
		root = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart") or nil
		return
	end

	local rawSpeed = root.AssemblyLinearVelocity.Magnitude
	smoothSpeed += (rawSpeed - smoothSpeed) * SMOOTHING

	local displayValue = getDisplayValue(smoothSpeed)
	local rotation = MIN_ANGLE + (MAX_ANGLE - MIN_ANGLE) * getNeedleAlpha(smoothSpeed)

	if smoothSpeed > SHAKE_START_SPEED then
		rotation += math.random(-SHAKE_AMOUNT, SHAKE_AMOUNT)
	end

	pivot.Rotation = rotation
	refreshDisplay(displayValue)
end))

track(player.CharacterAdded:Connect(setCharacter))

return stopSpeedometer
