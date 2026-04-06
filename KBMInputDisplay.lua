if _G.StopKBMInputDisplay then
	pcall(_G.StopKBMInputDisplay)
	_G.StopKBMInputDisplay = nil
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

for _, name in ipairs({ "InputVisualizer" }) do
	local old = playerGui:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "InputVisualizer"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.BorderSizePixel = 0
root.Parent = gui

local DEFAULT_SCALE = 0.65
local SIMPLE_SCALE = 0.9
local currentScale = DEFAULT_SCALE

local function S(v)
	return math.floor(v * currentScale + 0.5)
end

local simpleStyleEnabled = false
local leftHanded = false
local isOpen = true
local cornersEnabled = true
local suppressNextLeftMouseVisual = false

local controlSelectEnabled = false
local selectedControlIndex = 1
local controlButtonOrder = {
	"SwapButton",
	"LayoutButton",
	"InvertButton",
	"CornersButton",
	"SimpleStyleButton",
}

local SELECTED_CONTROL_SCALE = 1.2
local DIMMED_UNSELECTED_TRANSPARENCY_ADD = 0.18
local SELECTED_STROKE_THICKNESS = 2
local SELECTED_STROKE_COLOR = Color3.fromRGB(255, 255, 255)

local uiLeft = 0
local uiBottom = 0
local connections = {}
local currentCameraViewportConn
local stopped = false

local function trackConnection(connection)
	connections[#connections + 1] = connection
	return connection
end

local function disconnectConnection(connection)
	if connection then
		pcall(function()
			connection:Disconnect()
		end)
	end
end

local function disconnectAllConnections()
	disconnectConnection(currentCameraViewportConn)
	currentCameraViewportConn = nil
	for i = #connections, 1, -1 do
		disconnectConnection(connections[i])
		connections[i] = nil
	end
end

local TRANSPARENCY = {
	idle = 0.35,
	pressed = 0.15,
	contrastIdle = 0,
	contrastPressed = 0,
}

local KEYBOARD = {
	bottomMargin = 5,
	collapsedLeft = 11,
	collapsedBottom = 11,
	rowGap = 5,
	fullKeyGap = 6,
	simpleKeyGap = 5,
	keySize = 44,
	sidePadding = 8,
	topPadding = 8,
	bottomPadding = 8,
	revealBleed = 10,
	corner = 8,
	textSize = 16,
	toggleImage = "rbxassetid://102567068329894",
	controlGap = 6,
	controlRowGap = 8,
}

local MOUSE = {
	width = 132,
	height = 198,
	gapFromKeyboard = 10,
	bottomGap = 0,
	simpleBottomOffset = 0,
	assets = {
		bottom = "rbxassetid://76563324380675",
		left = "rbxassetid://136424168694433",
		right = "rbxassetid://140592291990835",
		middle = "rbxassetid://129489611077671",
	},
}

local SIMPLE_MOUSE_SCALE = 0.7

local SIDE = {
	buttonSize = 31.5,
	buttonGap = 6,
	iconInset = 4,
	assets = {
		swap = "rbxassetid://136330436723114",
		layout = "rbxassetid://137731564645457",
		invert = "rbxassetid://97149755226399",
		cornersOn = "rbxassetid://122630615991387",
		cornersOff = "rbxassetid://140578753916877",
		simpleStyleOn = "rbxassetid://123387487598299",
		simpleStyleOff = "rbxassetid://98168143393303",
	},
	fallbackText = {
		LayoutButton = "S",
		InvertButton = "I",
		CornersButton = "C",
		SimpleStyleButton = "SS",
	},
}

local STYLE_REGULAR = 1
local STYLE_CONTRAST = 2
local STYLE_REGULAR_INVERTED = 3
local STYLE_CONTRAST_INVERTED = 4
local STYLE_BLUE = 5
local STYLE_RED = 6
local STYLE_GREEN = 7

local STYLES = {
	{
		idleBg = Color3.fromRGB(255, 255, 255),
		idleText = Color3.fromRGB(0, 0, 0),
		pressedBg = Color3.fromRGB(0, 0, 0),
		pressedText = Color3.fromRGB(255, 255, 255),
		sideButtonBg = Color3.fromRGB(0, 0, 0),
		sideButtonIcon = Color3.fromRGB(255, 255, 255),
		toggleBgClosed = Color3.fromRGB(0, 0, 0),
		toggleBgOpen = Color3.fromRGB(0, 0, 0),
		mouseIdle = Color3.fromRGB(255, 255, 255),
		mousePressed = Color3.fromRGB(0, 0, 0),
		idleTransparency = TRANSPARENCY.idle,
		pressedTransparency = TRANSPARENCY.pressed,
		font = Enum.Font.GothamBold,
		gradient = nil,
		pressedGradient = nil,
	},
	{
		idleBg = Color3.fromRGB(255, 255, 255),
		idleText = Color3.fromRGB(0, 0, 0),
		pressedBg = Color3.fromRGB(0, 0, 0),
		pressedText = Color3.fromRGB(0, 255, 255),
		sideButtonBg = Color3.fromRGB(0, 0, 0),
		sideButtonIcon = Color3.fromRGB(255, 255, 255),
		toggleBgClosed = Color3.fromRGB(0, 0, 0),
		toggleBgOpen = Color3.fromRGB(0, 0, 0),
		mouseIdle = Color3.fromRGB(255, 255, 255),
		mousePressed = Color3.fromRGB(0, 0, 0),
		idleTransparency = TRANSPARENCY.contrastIdle,
		pressedTransparency = TRANSPARENCY.contrastPressed,
		font = Enum.Font.GothamBlack,
		gradient = nil,
		pressedGradient = nil,
	},
	{
		idleBg = Color3.fromRGB(0, 0, 0),
		idleText = Color3.fromRGB(255, 255, 255),
		pressedBg = Color3.fromRGB(255, 255, 255),
		pressedText = Color3.fromRGB(0, 0, 0),
		sideButtonBg = Color3.fromRGB(0, 0, 0),
		sideButtonIcon = Color3.fromRGB(255, 255, 255),
		toggleBgClosed = Color3.fromRGB(0, 0, 0),
		toggleBgOpen = Color3.fromRGB(0, 0, 0),
		mouseIdle = Color3.fromRGB(0, 0, 0),
		mousePressed = Color3.fromRGB(255, 255, 255),
		idleTransparency = TRANSPARENCY.idle,
		pressedTransparency = TRANSPARENCY.pressed,
		font = Enum.Font.GothamBold,
		gradient = nil,
		pressedGradient = nil,
	},
	{
		idleBg = Color3.fromRGB(0, 0, 0),
		idleText = Color3.fromRGB(255, 255, 255),
		pressedBg = Color3.fromRGB(255, 255, 255),
		pressedText = Color3.fromRGB(0, 0, 0),
		sideButtonBg = Color3.fromRGB(0, 0, 0),
		sideButtonIcon = Color3.fromRGB(255, 255, 255),
		toggleBgClosed = Color3.fromRGB(0, 0, 0),
		toggleBgOpen = Color3.fromRGB(0, 0, 0),
		mouseIdle = Color3.fromRGB(0, 0, 0),
		mousePressed = Color3.fromRGB(255, 255, 255),
		idleTransparency = TRANSPARENCY.contrastIdle,
		pressedTransparency = TRANSPARENCY.contrastPressed,
		font = Enum.Font.GothamBlack,
		gradient = nil,
		pressedGradient = nil,
	},
	{
		idleBg = Color3.fromRGB(170, 210, 255),
		idleText = Color3.fromRGB(0, 5, 15),
		pressedBg = Color3.fromRGB(35, 85, 170),
		pressedText = Color3.fromRGB(255, 255, 255),
		sideButtonBg = Color3.fromRGB(35, 85, 170),
		sideButtonIcon = Color3.fromRGB(255, 255, 255),
		toggleBgClosed = Color3.fromRGB(35, 85, 170),
		toggleBgOpen = Color3.fromRGB(35, 85, 170),
		mouseIdle = Color3.fromRGB(170, 210, 255),
		mousePressed = Color3.fromRGB(35, 85, 170),
		idleTransparency = 0,
		pressedTransparency = TRANSPARENCY.pressed,
		font = Enum.Font.Cartoon,
		gradient = {
			rotation = 45,
			sequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(195, 232, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 78, 170)),
			}),
		},
		pressedGradient = {
			rotation = 45,
			sequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(145, 205, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 48, 125)),
			}),
		},
	},
	{
		idleBg = Color3.fromRGB(255, 185, 185),
		idleText = Color3.fromRGB(55, 10, 10),
		pressedBg = Color3.fromRGB(170, 30, 30),
		pressedText = Color3.fromRGB(255, 255, 255),
		sideButtonBg = Color3.fromRGB(170, 30, 30),
		sideButtonIcon = Color3.fromRGB(255, 255, 255),
		toggleBgClosed = Color3.fromRGB(170, 30, 30),
		toggleBgOpen = Color3.fromRGB(170, 30, 30),
		mouseIdle = Color3.fromRGB(255, 185, 185),
		mousePressed = Color3.fromRGB(170, 30, 30),
		idleTransparency = 0,
		pressedTransparency = TRANSPARENCY.pressed,
		font = Enum.Font.ArimoBold,
		gradient = {
			rotation = 45,
			sequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 135, 190)),
			}),
		},
		pressedGradient = {
			rotation = 45,
			sequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 35, 35)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 95, 160)),
			}),
		},
	},
	{
		idleBg = Color3.fromRGB(185, 255, 190),
		idleText = Color3.fromRGB(15, 50, 20),
		pressedBg = Color3.fromRGB(35, 145, 60),
		pressedText = Color3.fromRGB(255, 255, 255),
		sideButtonBg = Color3.fromRGB(35, 145, 60),
		sideButtonIcon = Color3.fromRGB(255, 255, 255),
		toggleBgClosed = Color3.fromRGB(35, 145, 60),
		toggleBgOpen = Color3.fromRGB(35, 145, 60),
		mouseIdle = Color3.fromRGB(185, 255, 190),
		mousePressed = Color3.fromRGB(35, 145, 60),
		idleTransparency = 0,
		pressedTransparency = TRANSPARENCY.pressed,
		font = Enum.Font.Merriweather,
		gradient = {
			rotation = 45,
			sequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 110, 45)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(165, 255, 175)),
			}),
		},
		pressedGradient = {
			rotation = 45,
			sequence = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 90, 38)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 220, 135)),
			}),
		},
	},
}

local NORMAL_STYLE_CYCLE = {
	STYLE_REGULAR,
	STYLE_CONTRAST,
	STYLE_BLUE,
	STYLE_RED,
	STYLE_GREEN,
}

local currentStyleIndex = STYLE_REGULAR
local currentStyle = STYLES[currentStyleIndex]

local TOGGLE_ASPECT_X = 28
local TOGGLE_ASPECT_Y = 13

local fullRows = {
	{
		{ label = "Esc", code = Enum.KeyCode.Escape, width = 1.2 },
		{ label = "1", code = Enum.KeyCode.One },
		{ label = "2", code = Enum.KeyCode.Two },
		{ label = "3", code = Enum.KeyCode.Three },
		{ label = "4", code = Enum.KeyCode.Four },
		{ label = "5", code = Enum.KeyCode.Five },
		{ label = "6", code = Enum.KeyCode.Six },
		{ label = "7", code = Enum.KeyCode.Seven },
		{ label = "8", code = Enum.KeyCode.Eight },
		{ label = "9", code = Enum.KeyCode.Nine },
		{ label = "0", code = Enum.KeyCode.Zero },
	},
	{
		{ label = "Tab", code = Enum.KeyCode.Tab, width = 1.5 },
		{ label = "Q", code = Enum.KeyCode.Q },
		{ label = "W", code = Enum.KeyCode.W },
		{ label = "E", code = Enum.KeyCode.E },
		{ label = "R", code = Enum.KeyCode.R },
		{ label = "T", code = Enum.KeyCode.T },
		{ label = "Y", code = Enum.KeyCode.Y },
		{ label = "U", code = Enum.KeyCode.U },
		{ label = "I", code = Enum.KeyCode.I },
		{ label = "O", code = Enum.KeyCode.O },
		{ label = "P", code = Enum.KeyCode.P },
	},
	{
		{ label = "Caps", code = Enum.KeyCode.CapsLock, width = 1.8 },
		{ label = "A", code = Enum.KeyCode.A },
		{ label = "S", code = Enum.KeyCode.S },
		{ label = "D", code = Enum.KeyCode.D },
		{ label = "F", code = Enum.KeyCode.F },
		{ label = "G", code = Enum.KeyCode.G },
		{ label = "H", code = Enum.KeyCode.H },
		{ label = "J", code = Enum.KeyCode.J },
		{ label = "K", code = Enum.KeyCode.K },
		{ label = "L", code = Enum.KeyCode.L },
		{ label = ";", code = Enum.KeyCode.Semicolon },
	},
	{
		{ label = "Shift", code = Enum.KeyCode.LeftShift, width = 2.2 },
		{ label = "Z", code = Enum.KeyCode.Z },
		{ label = "X", code = Enum.KeyCode.X },
		{ label = "C", code = Enum.KeyCode.C },
		{ label = "V", code = Enum.KeyCode.V },
		{ label = "B", code = Enum.KeyCode.B },
		{ label = "N", code = Enum.KeyCode.N },
		{ label = "M", code = Enum.KeyCode.M },
		{ label = "Back", code = Enum.KeyCode.Backspace, width = 1.8 },
	},
	{
		{ label = "Ctrl", code = Enum.KeyCode.LeftControl, width = 1.5 },
		{ label = "Alt", code = Enum.KeyCode.LeftAlt, width = 1.5 },
		{ label = "Space", code = Enum.KeyCode.Space, width = 5 },
		{ label = "Enter", code = Enum.KeyCode.Return, width = 2 },
	},
}

local squareKeyMap = {}
for _, key in ipairs({
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five,
	Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine, Enum.KeyCode.Zero,
	Enum.KeyCode.A, Enum.KeyCode.B, Enum.KeyCode.C, Enum.KeyCode.D, Enum.KeyCode.E, Enum.KeyCode.F,
	Enum.KeyCode.G, Enum.KeyCode.H, Enum.KeyCode.I, Enum.KeyCode.J, Enum.KeyCode.K, Enum.KeyCode.L,
	Enum.KeyCode.M, Enum.KeyCode.N, Enum.KeyCode.O, Enum.KeyCode.P, Enum.KeyCode.Q, Enum.KeyCode.R,
	Enum.KeyCode.S, Enum.KeyCode.T, Enum.KeyCode.U, Enum.KeyCode.V, Enum.KeyCode.W, Enum.KeyCode.X,
	Enum.KeyCode.Y, Enum.KeyCode.Z, Enum.KeyCode.Semicolon
}) do
	squareKeyMap[key] = true
end

local keyRefs = {}
local sideButtonRefs = {}

local keyboardContentWidth = 0
local keyboardHeight = 0
local keyboardMainWidth = 0
local keyboardMainHeight = 0
local controlsHeight = 0
local controlsWidth = 0
local sideColumnWidth = 0
local sideColumnHeight = 0
local totalWidth = 0
local totalHeight = 0
local simpleLayoutOffsetX = 0
local simpleControlsExcessWidth = 0

local mouseState = {
	[Enum.UserInputType.MouseButton1] = false,
	[Enum.UserInputType.MouseButton2] = false,
	[Enum.UserInputType.MouseButton3] = false,
}

local function scaled(v)
	return S(v)
end

local function getKeySize()
	return scaled(KEYBOARD.keySize)
end

local function getFullKeyGap()
	return scaled(KEYBOARD.fullKeyGap)
end

local function getSimpleKeyGap()
	return scaled(KEYBOARD.simpleKeyGap)
end

local function getRowGap()
	return scaled(KEYBOARD.rowGap)
end

local function getSidePadding()
	return scaled(KEYBOARD.sidePadding)
end

local function getTopPadding()
	return scaled(KEYBOARD.topPadding)
end

local function getBottomPadding()
	return scaled(KEYBOARD.bottomPadding)
end

local function getRevealBleed()
	return scaled(KEYBOARD.revealBleed)
end

local function getCornerRadius()
	return cornersEnabled and scaled(KEYBOARD.corner) or 0
end

local function getTextSize()
	return scaled(KEYBOARD.textSize)
end

local function getControlGap()
	return scaled(KEYBOARD.controlGap)
end

local function getControlRowGap()
	return scaled(KEYBOARD.controlRowGap)
end

local function getToggleSize()
	local h = getKeySize()
	local w = math.floor(h * (TOGGLE_ASPECT_X / TOGGLE_ASPECT_Y) + 0.5)
	return w, h
end

local function getMouseLayoutValues()
	local mouseScale = simpleStyleEnabled and SIMPLE_MOUSE_SCALE or 1
	local mouseWidth = math.floor(scaled(MOUSE.width) * mouseScale + 0.5)
	local mouseHeight = math.floor(scaled(MOUSE.height) * mouseScale + 0.5)
	local gapFromKeyboard = simpleStyleEnabled and math.floor(scaled(MOUSE.gapFromKeyboard) * 0.55 + 0.5) or scaled(MOUSE.gapFromKeyboard)
	return mouseWidth, mouseHeight, gapFromKeyboard
end

local cluster = Instance.new("Frame")
cluster.AnchorPoint = Vector2.new(0, 1)
cluster.BackgroundTransparency = 1
cluster.BorderSizePixel = 0
cluster.Parent = root

local main = Instance.new("Frame")
main.AnchorPoint = Vector2.new(0, 1)
main.BackgroundTransparency = 1
main.BorderSizePixel = 0
main.Parent = cluster

local keyboardMask = Instance.new("Frame")
keyboardMask.BackgroundTransparency = 1
keyboardMask.BorderSizePixel = 0
keyboardMask.ClipsDescendants = true
keyboardMask.Parent = main

local keyboardFrame = Instance.new("Frame")
keyboardFrame.BackgroundTransparency = 1
keyboardFrame.BorderSizePixel = 0
keyboardFrame.Parent = keyboardMask

local controlsFrame = Instance.new("Frame")
controlsFrame.BackgroundTransparency = 1
controlsFrame.BorderSizePixel = 0
controlsFrame.Parent = keyboardFrame

local sideColumn = Instance.new("Frame")
sideColumn.AnchorPoint = Vector2.new(0, 1)
sideColumn.BackgroundTransparency = 1
sideColumn.BorderSizePixel = 0
sideColumn.Parent = cluster

local mouseMask = Instance.new("Frame")
mouseMask.AnchorPoint = Vector2.new(0, 1)
mouseMask.BackgroundTransparency = 1
mouseMask.BorderSizePixel = 0
mouseMask.ClipsDescendants = true
mouseMask.Parent = sideColumn

local mouseColumn = Instance.new("Frame")
mouseColumn.BackgroundTransparency = 1
mouseColumn.BorderSizePixel = 0
mouseColumn.Parent = mouseMask

local mouseFrame = Instance.new("Frame")
mouseFrame.AnchorPoint = Vector2.new(0.5, 1)
mouseFrame.BackgroundTransparency = 1
mouseFrame.BorderSizePixel = 0
mouseFrame.Parent = mouseColumn

local toggleButton = Instance.new("ImageButton")
toggleButton.BorderSizePixel = 0
toggleButton.AutoButtonColor = false
toggleButton.Image = ""
toggleButton.ZIndex = 50
toggleButton.Active = true
toggleButton.Parent = controlsFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.Parent = toggleButton

local toggleIcon = Instance.new("ImageLabel")
toggleIcon.AnchorPoint = Vector2.new(0.5, 0.5)
toggleIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
toggleIcon.BackgroundTransparency = 1
toggleIcon.Image = KEYBOARD.toggleImage
toggleIcon.ScaleType = Enum.ScaleType.Fit
toggleIcon.ZIndex = 51
toggleIcon.Parent = toggleButton

local function createGradientHost(parent)
	local gradient = Instance.new("UIGradient")
	gradient.Parent = parent
	return gradient
end

local function createKey(parent, width, height, label)
	local key = Instance.new("Frame")
	key.Size = UDim2.new(0, width, 0, height)
	key.BorderSizePixel = 0
	key.ClipsDescendants = true
	key.Parent = parent

	local frameCorner = Instance.new("UICorner")
	frameCorner.Parent = key

	local gradient = createGradientHost(key)

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = label
	text.ZIndex = 2
	text.Parent = key

	return {
		frame = key,
		text = text,
		gradient = gradient,
		frameCorner = frameCorner,
		pressed = false,
	}
end

local function createMousePart(name, image, zIndex)
	local part = Instance.new("ImageLabel")
	part.Name = name
	part.BackgroundTransparency = 1
	part.BorderSizePixel = 0
	part.Size = UDim2.new(1, 0, 1, 0)
	part.Position = UDim2.new(0, 0, 0, 0)
	part.Image = image
	part.ScaleType = Enum.ScaleType.Fit
	part.ZIndex = zIndex
	part.Parent = mouseFrame

	local gradient = createGradientHost(part)

	return {
		image = part,
		gradient = gradient,
	}
end

local function createSideImageButton(name, assetId)
	local button = Instance.new("ImageButton")
	button.Name = name
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Image = ""
	button.Parent = controlsFrame

	local corner = Instance.new("UICorner")
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Enabled = false
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = SELECTED_STROKE_THICKNESS
	stroke.Color = SELECTED_STROKE_COLOR
	stroke.Transparency = 0
	stroke.Parent = button

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.BackgroundTransparency = 1
	icon.Image = assetId
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = button

	local fallback = Instance.new("TextLabel")
	fallback.Name = "Fallback"
	fallback.AnchorPoint = Vector2.new(0.5, 0.5)
	fallback.Position = UDim2.new(0.5, 0, 0.5, 0)
	fallback.BackgroundTransparency = 1
	fallback.Text = SIDE.fallbackText[name] or ""
	fallback.TextScaled = true
	fallback.Visible = assetId == nil or assetId == ""
	fallback.Parent = button

	trackConnection(button.MouseButton1Down:Connect(function()
		suppressNextLeftMouseVisual = true
	end))

	sideButtonRefs[name] = {
		button = button,
		icon = icon,
		fallback = fallback,
		corner = corner,
		stroke = stroke,
		pressed = false,
	}

	return button
end

local mouseParts = {
	BottomBody = createMousePart("BottomBody", MOUSE.assets.bottom, 1),
	LeftButton = createMousePart("LeftButton", MOUSE.assets.left, 2),
	RightButton = createMousePart("RightButton", MOUSE.assets.right, 3),
	MiddleButton = createMousePart("MiddleButton", MOUSE.assets.middle, 4),
}

local mouseRefs = {
	[Enum.UserInputType.MouseButton1] = mouseParts.LeftButton,
	[Enum.UserInputType.MouseButton2] = mouseParts.RightButton,
	[Enum.UserInputType.MouseButton3] = mouseParts.MiddleButton,
}

local swapButton = createSideImageButton("SwapButton", SIDE.assets.swap)
local layoutButton = createSideImageButton("LayoutButton", SIDE.assets.layout)
local invertButton = createSideImageButton("InvertButton", SIDE.assets.invert)
local cornersButton = createSideImageButton("CornersButton", SIDE.assets.cornersOn)
local simpleStyleButton = createSideImageButton("SimpleStyleButton", SIDE.assets.simpleStyleOff)

-- keep the rest of your current KBM script exactly the same up to the bottom --

function KBMInputDisplay()
	if stopped then
		return
	end

	stopped = true
	isOpen = false
	controlSelectEnabled = false
	suppressNextLeftMouseVisual = false

	disconnectAllConnections()
	disconnectConnection(currentCameraViewportConn)
	currentCameraViewportConn = nil

	pcall(function()
		gui:Destroy()
	end)

	local leftover = playerGui:FindFirstChild("InputVisualizer")
	if leftover then
		pcall(function()
			leftover:Destroy()
		end)
	end

	table.clear(keyRefs)
	table.clear(sideButtonRefs)
	table.clear(mouseState)
	table.clear(connections)

	_G.StopKBMInputDisplay = nil
	_G.KBMInputDisplay = nil
end

_G.StopKBMInputDisplay = KBMInputDisplay
_G.KBMInputDisplay = KBMInputDisplay
return KBMInputDisplay
