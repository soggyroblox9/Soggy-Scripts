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

local function clearKeys()
	for _, ref in pairs(keyRefs) do
		ref.frame:Destroy()
	end
	table.clear(keyRefs)
end

local function getKeyWidth(keyData)
	local keySize = getKeySize()
	if squareKeyMap[keyData.code] and not keyData.width then
		return keySize
	end
	return math.floor(keySize * (keyData.width or 1) + 0.5)
end

local function applyGradient(gradientObject, data)
	if not data then
		gradientObject.Enabled = false
		return
	end
	gradientObject.Enabled = true
	gradientObject.Rotation = data.rotation or 0
	gradientObject.Color = data.sequence
end

local function getChromeStyleIndex(styleIndex)
	if styleIndex == STYLE_REGULAR_INVERTED then
		return STYLE_REGULAR
	elseif styleIndex == STYLE_CONTRAST_INVERTED then
		return STYLE_CONTRAST
	end
	return styleIndex
end

local function getChromeStyle()
	return STYLES[getChromeStyleIndex(currentStyleIndex)]
end

local function applyKeyVisual(ref)
	local pressed = ref.pressed
	ref.frame.BackgroundColor3 = pressed and currentStyle.pressedBg or currentStyle.idleBg
	ref.frame.BackgroundTransparency = pressed and currentStyle.pressedTransparency or currentStyle.idleTransparency
	ref.text.TextColor3 = pressed and currentStyle.pressedText or currentStyle.idleText
	ref.text.Font = currentStyle.font
	ref.text.TextSize = getTextSize()
	ref.frameCorner.CornerRadius = UDim.new(0, getCornerRadius())
	applyGradient(ref.gradient, pressed and currentStyle.pressedGradient or currentStyle.gradient)
end

local function applyMousePartVisual(partRef, pressed)
	partRef.image.ImageColor3 = pressed and currentStyle.mousePressed or currentStyle.mouseIdle
	partRef.image.ImageTransparency = pressed and currentStyle.pressedTransparency or currentStyle.idleTransparency
	applyGradient(partRef.gradient, pressed and currentStyle.pressedGradient or currentStyle.gradient)
end

local function refreshCornersIcon()
	sideButtonRefs.CornersButton.icon.Image = cornersEnabled and SIDE.assets.cornersOn or SIDE.assets.cornersOff
end

local function refreshCornerMode()
	local radius = getCornerRadius()
	for _, ref in pairs(keyRefs) do
		ref.frameCorner.CornerRadius = UDim.new(0, radius)
	end
	for _, ref in pairs(sideButtonRefs) do
		ref.corner.CornerRadius = UDim.new(0, radius)
	end
	toggleCorner.CornerRadius = UDim.new(0, radius)
end

local function refreshSideButtons()
	local buttonSize = scaled(SIDE.buttonSize)
	local inset = scaled(SIDE.iconInset)
	local chromeStyle = getChromeStyle()

	for index, name in ipairs(controlButtonOrder) do
		local ref = sideButtonRefs[name]
		if ref then
			local isSelected = controlSelectEnabled and isOpen and index == selectedControlIndex
			local size = isSelected and math.floor(buttonSize * SELECTED_CONTROL_SCALE + 0.5) or buttonSize
			ref.button.Size = UDim2.new(0, size, 0, size)
			ref.button.BackgroundColor3 = ref.pressed and chromeStyle.pressedBg or chromeStyle.sideButtonBg
			ref.button.BackgroundTransparency = (ref.pressed and chromeStyle.pressedTransparency or chromeStyle.idleTransparency) + ((not isSelected and controlSelectEnabled and isOpen) and DIMMED_UNSELECTED_TRANSPARENCY_ADD or 0)
			if ref.button.BackgroundTransparency > 1 then
				ref.button.BackgroundTransparency = 1
			end
			ref.icon.ImageColor3 = chromeStyle.sideButtonIcon
			ref.icon.ImageTransparency = (not isSelected and controlSelectEnabled and isOpen) and 0.2 or 0
			ref.icon.Size = UDim2.new(1, -inset * 2, 1, -inset * 2)
			ref.fallback.Size = UDim2.new(1, -4, 1, -4)
			ref.fallback.TextColor3 = chromeStyle.sideButtonIcon
			ref.fallback.TextTransparency = (not isSelected and controlSelectEnabled and isOpen) and 0.2 or 0
			ref.fallback.Font = chromeStyle.font
			ref.stroke.Enabled = isSelected
			ref.stroke.Color = SELECTED_STROKE_COLOR
			ref.stroke.Thickness = SELECTED_STROKE_THICKNESS

			if name == "SimpleStyleButton" then
				ref.icon.Image = simpleStyleEnabled and SIDE.assets.simpleStyleOn or SIDE.assets.simpleStyleOff
			elseif name == "CornersButton" then
				ref.icon.Image = cornersEnabled and SIDE.assets.cornersOn or SIDE.assets.cornersOff
			elseif name == "InvertButton" then
				ref.icon.Image = SIDE.assets.invert
			end
		end
	end

	for name, ref in pairs(sideButtonRefs) do
		ref.fallback.TextColor3 = chromeStyle.sideButtonIcon
		ref.fallback.Font = chromeStyle.font

		if name == "SimpleStyleButton" then
			ref.fallback.Text = simpleStyleEnabled and "ON" or "SS"
		elseif name == "LayoutButton" then
			ref.fallback.Text = "S"
		elseif name == "InvertButton" then
			ref.fallback.Text = "I"
		elseif name == "CornersButton" then
			ref.fallback.Text = cornersEnabled and "C" or "SQ"
		end
	end
end

local function applyStyle()
	for _, ref in pairs(keyRefs) do
		applyKeyVisual(ref)
	end

	applyMousePartVisual(mouseParts.BottomBody, false)
	applyMousePartVisual(mouseParts.LeftButton, mouseState[Enum.UserInputType.MouseButton1])
	applyMousePartVisual(mouseParts.RightButton, mouseState[Enum.UserInputType.MouseButton2])
	applyMousePartVisual(mouseParts.MiddleButton, mouseState[Enum.UserInputType.MouseButton3])

	refreshSideButtons()
	refreshCornersIcon()

	local chromeStyle = getChromeStyle()
	toggleButton.BackgroundColor3 = chromeStyle.sideButtonBg
	toggleButton.BackgroundTransparency = chromeStyle.idleTransparency
	toggleIcon.ImageColor3 = chromeStyle.sideButtonIcon
	toggleIcon.Size = UDim2.new(0.88, 0, 0.88, 0)

	refreshCornerMode()
end

local function addKey(keyData, x, y)
	local width = getKeyWidth(keyData)
	local ref = createKey(keyboardFrame, width, getKeySize(), keyData.label)
	ref.frame.Position = UDim2.new(0, x, 0, y)
	keyRefs[keyData.code] = ref
end

local function layoutControls()
	local buttonSize = scaled(SIDE.buttonSize)
	local controlGap = getControlGap()
	local toggleWidth, toggleHeight = getToggleSize()
	local buttons = {
		swapButton,
		layoutButton,
		invertButton,
		cornersButton,
		simpleStyleButton,
	}

	local function getVisualButtonSize(button)
		for index, name in ipairs(controlButtonOrder) do
			local ref = sideButtonRefs[name]
			if ref and ref.button == button then
				local isSelected = controlSelectEnabled and isOpen and index == selectedControlIndex
				return isSelected and math.floor(buttonSize * SELECTED_CONTROL_SCALE + 0.5) or buttonSize
			end
		end
		return buttonSize
	end

	local maxButtonSize = buttonSize
		if controlSelectEnabled and isOpen then
			maxButtonSize = math.floor(buttonSize * SELECTED_CONTROL_SCALE + 0.5)
		end
	controlsHeight = math.max(toggleHeight, maxButtonSize)

	local totalButtonsWidth = 0
	for i, button in ipairs(buttons) do
		totalButtonsWidth += getVisualButtonSize(button)
		if i < #buttons then
			totalButtonsWidth += controlGap
		end
	end

	if leftHanded then
		controlsWidth = totalButtonsWidth + controlGap + toggleWidth

		local x = 0
		for _, button in ipairs(buttons) do
			local size = getVisualButtonSize(button)
			button.Position = UDim2.new(0, x, 0, controlsHeight - size)
			x += size + controlGap
		end

		toggleButton.Parent = controlsFrame
		toggleButton.AnchorPoint = Vector2.new(0, 0)
		toggleButton.Position = UDim2.new(0, x, 0, 0)
	else
		controlsWidth = toggleWidth + controlGap + totalButtonsWidth

		toggleButton.Parent = controlsFrame
		toggleButton.AnchorPoint = Vector2.new(0, 0)
		toggleButton.Position = UDim2.new(0, 0, 0, 0)

		local x = toggleWidth + controlGap
		for _, button in ipairs(buttons) do
			local size = getVisualButtonSize(button)
			button.Position = UDim2.new(0, x, 0, controlsHeight - size)
			x += size + controlGap
		end
	end

	toggleButton.Size = UDim2.new(0, toggleWidth, 0, toggleHeight)
	controlsFrame.Position = UDim2.new(0, 0, 0, 0)
	controlsFrame.Size = UDim2.new(0, controlsWidth, 0, controlsHeight)
end

local function buildFullLayout()
	clearKeys()
	layoutControls()

	local rowWidths = {}
	local maxRowWidth = 0
	local keyGap = getFullKeyGap()
	local rowGap = getRowGap()
	local keySize = getKeySize()
	local topOffset = controlsHeight + getControlRowGap()

	for i, row in ipairs(fullRows) do
		local width = 0
		for j, keyData in ipairs(row) do
			width += getKeyWidth(keyData)
			if j < #row then
				width += keyGap
			end
		end
		rowWidths[i] = width
		maxRowWidth = math.max(maxRowWidth, width)
	end

	keyboardContentWidth = math.max(maxRowWidth, controlsWidth)
	keyboardHeight = topOffset + (#fullRows * keySize) + ((#fullRows - 1) * rowGap)
	keyboardMainWidth = keyboardContentWidth + getSidePadding() * 2
	keyboardMainHeight = keyboardHeight + getTopPadding() + getBottomPadding()

	for rowIndex, row in ipairs(fullRows) do
		local y = topOffset + (rowIndex - 1) * (keySize + rowGap)
		local rowWidth = rowWidths[rowIndex]
		local startX = leftHanded and (keyboardContentWidth - rowWidth) or 0
		local x = startX

		for _, keyData in ipairs(row) do
			addKey(keyData, x, y)
			x += getKeyWidth(keyData) + keyGap
		end
	end
end

local function buildSimpleLayout()
	clearKeys()
	layoutControls()

	local unitX = getKeySize() + getSimpleKeyGap()
	local unitY = getKeySize() + getRowGap()
	local topOffset = controlsHeight + getControlRowGap()

	local placements = {
		{ label = "Tab", code = Enum.KeyCode.Tab, x = 0.0, y = 0.0, width = 1.8 },
		{ label = "E", code = Enum.KeyCode.E, x = 1.7, y = 0.0 },
		{ label = "R", code = Enum.KeyCode.R, x = 2.7, y = 0.0 },
		{ label = "I", code = Enum.KeyCode.I, x = 3.7, y = 0.0 },
		{ label = "O", code = Enum.KeyCode.O, x = 4.7, y = 0.0 },

		{ label = "Shift", code = Enum.KeyCode.LeftShift, x = 0.0, y = 1.0, width = 1.8 },
		{ label = "W", code = Enum.KeyCode.W, x = 1.7, y = 1.0 },
		{ label = "A", code = Enum.KeyCode.A, x = 2.7, y = 1.0 },
		{ label = "S", code = Enum.KeyCode.S, x = 3.7, y = 1.0 },
		{ label = "D", code = Enum.KeyCode.D, x = 4.7, y = 1.0 },

		{ label = "Ctrl", code = Enum.KeyCode.LeftControl, x = 0.0, y = 2.0, width = 1.8 },
		{ label = "Space", code = Enum.KeyCode.Space, x = 1.7, y = 2.0, width = 4.37 },
	}

	local maxRight = 0
	local maxBottom = controlsHeight

	for _, keyData in ipairs(placements) do
		local width = getKeyWidth(keyData)
		local rawX = math.floor(keyData.x * unitX + 0.5)
		local y = topOffset + math.floor(keyData.y * unitY + 0.5)
		maxRight = math.max(maxRight, rawX + width)
		maxBottom = math.max(maxBottom, y + getKeySize())
	end

	keyboardContentWidth = math.max(maxRight, controlsWidth)
	simpleControlsExcessWidth = keyboardContentWidth - maxRight
	keyboardHeight = maxBottom
	keyboardMainWidth = keyboardContentWidth + getSidePadding() * 2
	keyboardMainHeight = keyboardHeight + getTopPadding() + getBottomPadding()

	simpleLayoutOffsetX = leftHanded and simpleControlsExcessWidth or 0

	for _, keyData in ipairs(placements) do
		local rawX = math.floor(keyData.x * unitX + 0.5)
		local x = simpleLayoutOffsetX + rawX
		local y = topOffset + math.floor(keyData.y * unitY + 0.5)
		addKey(keyData, x, y)
	end
end

local function rebuildKeyboardLayout()
	currentScale = simpleStyleEnabled and SIMPLE_SCALE or DEFAULT_SCALE

	if simpleStyleEnabled then
		buildSimpleLayout()
	else
		buildFullLayout()
	end

	main.Size = UDim2.new(0, keyboardMainWidth, 0, keyboardMainHeight)

	local revealBleed = getRevealBleed()
	local sidePadding = getSidePadding()
	local topPadding = getTopPadding()

	keyboardMask.Position = UDim2.new(0, sidePadding - revealBleed, 0, topPadding - revealBleed)
	keyboardMask.Size = UDim2.new(0, 0, 0, keyboardHeight + revealBleed * 2)

	keyboardFrame.Position = UDim2.new(0, revealBleed, 0, revealBleed)
	keyboardFrame.Size = UDim2.new(0, keyboardContentWidth, 0, keyboardHeight)
	controlsFrame.Position = UDim2.new(0, simpleStyleEnabled and 0 or (leftHanded and (keyboardContentWidth - controlsWidth) or 0), 0, 0)
end

local function refreshMeasurements()
	local mouseWidth, mouseHeight, gapFromKeyboard = getMouseLayoutValues()

	sideColumnWidth = mouseWidth
	sideColumnHeight = math.max(keyboardMainHeight, mouseHeight + scaled(MOUSE.bottomGap))

	totalWidth = keyboardMainWidth + gapFromKeyboard + sideColumnWidth
	totalHeight = math.max(keyboardMainHeight, sideColumnHeight)

	cluster.Size = UDim2.new(0, totalWidth, 0, totalHeight)
	sideColumn.Size = UDim2.new(0, sideColumnWidth, 0, sideColumnHeight)

	mouseMask.Position = UDim2.new(0, 0, 1, 0)
	mouseMask.Size = UDim2.new(0, isOpen and sideColumnWidth or 0, 0, sideColumnHeight)

	mouseColumn.Size = UDim2.new(0, sideColumnWidth, 0, sideColumnHeight)
	mouseColumn.Position = UDim2.new(0, 0, 0, 0)

	mouseFrame.Size = UDim2.new(0, mouseWidth, 0, mouseHeight)
	local bottomOffset = simpleStyleEnabled and scaled(MOUSE.simpleBottomOffset or 0) or 0
	mouseFrame.Position = UDim2.new(0.5, 0, 1, -(scaled(MOUSE.bottomGap) + bottomOffset))
end

local function layoutCluster()
	local _, _, gapFromKeyboard = getMouseLayoutValues()

	if simpleStyleEnabled then
		local simpleAnchorWidth = keyboardMainWidth - simpleControlsExcessWidth

		if leftHanded then
			sideColumn.Position = UDim2.new(0, 0, 1, 0)
			main.Position = UDim2.new(0, math.max(0, sideColumnWidth + gapFromKeyboard - simpleControlsExcessWidth), 1, 0)
		else
			main.Position = UDim2.new(0, 0, 1, 0)
			sideColumn.Position = UDim2.new(0, simpleAnchorWidth + gapFromKeyboard, 1, 0)
		end
		return
	end

	if leftHanded then
		sideColumn.Position = UDim2.new(0, 0, 1, 0)
		main.Position = UDim2.new(0, sideColumnWidth + gapFromKeyboard, 1, 0)
	else
		main.Position = UDim2.new(0, 0, 1, 0)
		sideColumn.Position = UDim2.new(0, keyboardMainWidth + gapFromKeyboard, 1, 0)
	end
end

local function updatePositions()
	if stopped then
		return
	end
	cluster.Position = UDim2.new(0, uiLeft, 1, -uiBottom)
end

local function setToggleVisual()
	local chromeStyle = getChromeStyle()
	toggleButton.BackgroundColor3 = chromeStyle.sideButtonBg
	toggleButton.BackgroundTransparency = chromeStyle.idleTransparency
	toggleIcon.ImageColor3 = chromeStyle.sideButtonIcon
end

local function placeToggleCollapsed()
	local toggleWidth, toggleHeight = getToggleSize()
	toggleButton.Parent = root
	toggleButton.AnchorPoint = Vector2.new(0, 1)
	toggleButton.Position = UDim2.new(0, KEYBOARD.collapsedLeft, 1, -KEYBOARD.collapsedBottom)
	toggleButton.Size = UDim2.new(0, toggleWidth, 0, toggleHeight)
	setToggleVisual()
end

local function refreshLayout()
	rebuildKeyboardLayout()
	refreshMeasurements()
	layoutCluster()
	updatePositions()

	if isOpen then
		local revealBleed = getRevealBleed()
		local keyboardTargetWidth = keyboardContentWidth + revealBleed * 2
		keyboardMask.Visible = true
		keyboardMask.Size = UDim2.new(0, keyboardTargetWidth, 0, keyboardHeight + revealBleed * 2)
		mouseMask.Visible = true
		mouseMask.Size = UDim2.new(0, sideColumnWidth, 0, sideColumnHeight)
		toggleButton.Parent = controlsFrame
		toggleButton.AnchorPoint = Vector2.new(0, 0)
	else
		controlSelectEnabled = false
		keyboardMask.Visible = false
		keyboardMask.Size = UDim2.new(0, 0, 0, keyboardHeight + getRevealBleed() * 2)
		mouseMask.Visible = false
		mouseMask.Size = UDim2.new(0, 0, 0, sideColumnHeight)
		placeToggleCollapsed()
	end

	applyStyle()
	updateControlSelectionVisual()
end

local function openUI()
	if isOpen then
		return
	end

	isOpen = true
	keyboardMask.Visible = true
	mouseMask.Visible = true
	refreshLayout()
	applyStyle()
end

local function closeUI()
	isOpen = false
	setControlSelectionEnabled(false)
	keyboardMask.Visible = false
	mouseMask.Visible = false
	keyboardMask.Size = UDim2.new(0, 0, 0, keyboardHeight + getRevealBleed() * 2)
	mouseMask.Size = UDim2.new(0, 0, 0, sideColumnHeight)
	placeToggleCollapsed()
	applyStyle()
end

local function setKeyState(keyCode, pressed)
	local ref = keyRefs[keyCode]
	if not ref then
		return
	end
	ref.pressed = pressed
	applyKeyVisual(ref)
end

local function setMouseState(inputType, pressed)
	mouseState[inputType] = pressed
	local ref = mouseRefs[inputType]
	if ref then
		applyMousePartVisual(ref, pressed)
	end
end

local function setSideButtonPressed(name, pressed)
	local ref = sideButtonRefs[name]
	if not ref then
		return
	end
	ref.pressed = pressed
	refreshSideButtons()
end

local function clearControlSelectionVisual()
	for _, name in ipairs(controlButtonOrder) do
		setSideButtonPressed(name, false)
	end
end

local function updateControlSelectionVisual()
	clearControlSelectionVisual()
	if controlSelectEnabled and isOpen then
		setSideButtonPressed(controlButtonOrder[selectedControlIndex], true)
	end
	layoutControls()
	refreshSideButtons()
end

local function setControlSelectionEnabled(enabled)
	controlSelectEnabled = enabled and isOpen or false
	updateControlSelectionVisual()
end

local function selectNextControl(step)
	if not (controlSelectEnabled and isOpen) then
		return
	end
	selectedControlIndex += step
	if selectedControlIndex < 1 then
		selectedControlIndex = #controlButtonOrder
	elseif selectedControlIndex > #controlButtonOrder then
		selectedControlIndex = 1
	end
	updateControlSelectionVisual()
end

local function cycleMainStyle()
	local baseStyle = currentStyleIndex
	if baseStyle == STYLE_REGULAR_INVERTED then
		baseStyle = STYLE_REGULAR
	elseif baseStyle == STYLE_CONTRAST_INVERTED then
		baseStyle = STYLE_CONTRAST
	end

	local currentPos = 1
	for i, styleIndex in ipairs(NORMAL_STYLE_CYCLE) do
		if styleIndex == baseStyle then
			currentPos = i
			break
		end
	end

	currentPos += 1
	if currentPos > #NORMAL_STYLE_CYCLE then
		currentPos = 1
	end

	currentStyleIndex = NORMAL_STYLE_CYCLE[currentPos]
	currentStyle = STYLES[currentStyleIndex]
	applyStyle()
end

local function toggleInvertStyle()
	if currentStyleIndex == STYLE_REGULAR then
		currentStyleIndex = STYLE_REGULAR_INVERTED
	elseif currentStyleIndex == STYLE_REGULAR_INVERTED then
		currentStyleIndex = STYLE_REGULAR
	elseif currentStyleIndex == STYLE_CONTRAST then
		currentStyleIndex = STYLE_CONTRAST_INVERTED
	elseif currentStyleIndex == STYLE_CONTRAST_INVERTED then
		currentStyleIndex = STYLE_CONTRAST
	else
		return
	end

	currentStyle = STYLES[currentStyleIndex]
	applyStyle()
end

local function activateSwapButton()
	leftHanded = not leftHanded
	refreshLayout()
	updateControlSelectionVisual()
end

local function activateLayoutButton()
	cycleMainStyle()
	updateControlSelectionVisual()
end

local function activateInvertButton()
	toggleInvertStyle()
	updateControlSelectionVisual()
end

local function activateCornersButton()
	cornersEnabled = not cornersEnabled
	refreshCornerMode()
	applyStyle()
	updateControlSelectionVisual()
end

local function activateSimpleStyleButton()
	simpleStyleEnabled = not simpleStyleEnabled
	refreshLayout()
	updateControlSelectionVisual()
end

local function activateSelectedControl()
	if not (controlSelectEnabled and isOpen) then
		return
	end

	local name = controlButtonOrder[selectedControlIndex]
	if name == "SwapButton" then
		activateSwapButton()
	elseif name == "InvertButton" then
		activateInvertButton()
	elseif name == "LayoutButton" then
		activateLayoutButton()
	elseif name == "SimpleStyleButton" then
		activateSimpleStyleButton()
	elseif name == "CornersButton" then
		activateCornersButton()
	end
end

trackConnection(toggleButton.MouseButton1Down:Connect(function()
	suppressNextLeftMouseVisual = true
end))

local lastTogglePress = 0
local function handleTogglePress()
	local now = os.clock()
	if now - lastTogglePress < 0.12 then
		return
	end
	lastTogglePress = now
	if isOpen then
		closeUI()
	else
		openUI()
	end
end

trackConnection(toggleButton.Activated:Connect(handleTogglePress))
trackConnection(toggleButton.MouseButton1Click:Connect(handleTogglePress))

trackConnection(swapButton.MouseButton1Down:Connect(function()
	setSideButtonPressed("SwapButton", true)
end))

trackConnection(swapButton.MouseButton1Up:Connect(function()
	setSideButtonPressed("SwapButton", false)
end))

trackConnection(swapButton.Activated:Connect(function()
	activateSwapButton()
end))

trackConnection(layoutButton.MouseButton1Down:Connect(function()
	setSideButtonPressed("LayoutButton", true)
end))

trackConnection(layoutButton.MouseButton1Up:Connect(function()
	setSideButtonPressed("LayoutButton", false)
end))

trackConnection(layoutButton.Activated:Connect(function()
	activateLayoutButton()
end))

trackConnection(invertButton.MouseButton1Down:Connect(function()
	setSideButtonPressed("InvertButton", true)
end))

trackConnection(invertButton.MouseButton1Up:Connect(function()
	setSideButtonPressed("InvertButton", false)
end))

trackConnection(invertButton.Activated:Connect(function()
	activateInvertButton()
end))

trackConnection(cornersButton.MouseButton1Down:Connect(function()
	setSideButtonPressed("CornersButton", true)
end))

trackConnection(cornersButton.MouseButton1Up:Connect(function()
	setSideButtonPressed("CornersButton", false)
end))

trackConnection(cornersButton.Activated:Connect(function()
	activateCornersButton()
end))

trackConnection(simpleStyleButton.MouseButton1Down:Connect(function()
	setSideButtonPressed("SimpleStyleButton", true)
end))

trackConnection(simpleStyleButton.MouseButton1Up:Connect(function()
	setSideButtonPressed("SimpleStyleButton", false)
end))

trackConnection(simpleStyleButton.Activated:Connect(function()
	activateSimpleStyleButton()
end))

trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		setKeyState(input.KeyCode, true)

		if not gameProcessed then
			if input.KeyCode == Enum.KeyCode.B then
				handleTogglePress()
				return
			end

			if input.KeyCode == Enum.KeyCode.G and isOpen then
				if not controlSelectEnabled then
					setControlSelectionEnabled(true)
				else
					selectNextControl(1)
				end
				return
			end

			if input.KeyCode == Enum.KeyCode.Backspace then
				setControlSelectionEnabled(false)
				return
			end

			if controlSelectEnabled and isOpen and input.KeyCode == Enum.KeyCode.Return then
				activateSelectedControl()
				return
			end
		end

		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 and suppressNextLeftMouseVisual then
		suppressNextLeftMouseVisual = false
		return
	end

	if mouseRefs[input.UserInputType] then
		setMouseState(input.UserInputType, true)
	end
end))

trackConnection(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		setKeyState(input.KeyCode, false)
		return
	end

	if mouseRefs[input.UserInputType] then
		setMouseState(input.UserInputType, false)
	end
end))

trackConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	disconnectConnection(currentCameraViewportConn)
	currentCameraViewportConn = nil
	local camera = workspace.CurrentCamera
	if camera then
		currentCameraViewportConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePositions)
	end
	task.defer(updatePositions)
end))

local camera = workspace.CurrentCamera
if camera then
	currentCameraViewportConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePositions)
end

refreshLayout()
applyStyle()

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
