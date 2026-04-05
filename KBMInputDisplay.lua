local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

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
local isAnimating = false
local cornersEnabled = true
local suppressNextLeftMouseVisual = false

local uiLeft = 5
local uiBottom = 5
local activeTweens = {}
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

local function stopTweens()
	for i = #activeTweens, 1, -1 do
		local tween = activeTweens[i]
		pcall(function()
			tween:Cancel()
		end)
		activeTweens[i] = nil
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
	defaultLeft = 5,
	defaultBottom = 5,
	collapsedLeft = 11,
	collapsedBottom = 11,
	rowGap = 5,
	keyGap = 5,
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
	buttonSize = 40,
	buttonGap = 6,
	iconInset = 4,
	assets = {
		swap = "rbxassetid://136330436723114",
		layout = "rbxassetid://137731564645457",
		cornersOn = "rbxassetid://140578753916877",
		cornersOff = "rbxassetid://122630615991387",
		simplestyle = "rbxassetid://80108775249851",
	},
	fallbackText = {
		LayoutButton = "S",
		CornersButton = "C",
		SimpleStyleButton = "SS",
	},
}

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
		idleBg = Color3.fromRGB(170, 210, 255),
		idleText = Color3.fromRGB(10, 25, 45),
		pressedBg = Color3.fromRGB(35, 85, 170),
		pressedText = Color3.fromRGB(255, 255, 255),
		sideButtonBg = Color3.fromRGB(35, 85, 170),
		sideButtonIcon = Color3.fromRGB(255, 255, 255),
		toggleBgClosed = Color3.fromRGB(35, 85, 170),
		toggleBgOpen = Color3.fromRGB(35, 85, 170),
		mouseIdle = Color3.fromRGB(170, 210, 255),
		mousePressed = Color3.fromRGB(35, 85, 170),
		idleTransparency = TRANSPARENCY.idle,
		pressedTransparency = TRANSPARENCY.pressed,
		font = Enum.Font.Arcade,
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
		idleTransparency = TRANSPARENCY.idle,
		pressedTransparency = TRANSPARENCY.pressed,
		font = Enum.Font.Bangers,
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
		idleTransparency = TRANSPARENCY.idle,
		pressedTransparency = TRANSPARENCY.pressed,
		font = Enum.Font.FredokaOne,
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

local currentStyleIndex = 1
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

local function getKeyGap()
	return scaled(KEYBOARD.keyGap)
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
local cornersButton = createSideImageButton("CornersButton", SIDE.assets.cornersOn)
local simpleStyleButton = createSideImageButton("SimpleStyleButton", SIDE.assets.simplestyle)

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

	for name, ref in pairs(sideButtonRefs) do
		ref.button.Size = UDim2.new(0, buttonSize, 0, buttonSize)
		ref.button.BackgroundColor3 = ref.pressed and currentStyle.pressedBg or currentStyle.sideButtonBg
		ref.button.BackgroundTransparency = ref.pressed and currentStyle.pressedTransparency or currentStyle.idleTransparency
		ref.icon.ImageColor3 = currentStyle.sideButtonIcon
		ref.icon.ImageTransparency = 0
		ref.icon.Size = UDim2.new(1, -inset * 2, 1, -inset * 2)
		ref.fallback.Size = UDim2.new(1, -4, 1, -4)
		ref.fallback.TextColor3 = currentStyle.sideButtonIcon
		ref.fallback.Font = currentStyle.font

		if name == "SimpleStyleButton" then
			ref.fallback.Text = simpleStyleEnabled and "ON" or "SS"
		elseif name == "LayoutButton" then
			ref.fallback.Text = "S"
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

	toggleButton.BackgroundColor3 = currentStyle.sideButtonBg
	toggleButton.BackgroundTransparency = currentStyle.idleTransparency
	toggleIcon.ImageColor3 = currentStyle.sideButtonIcon
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
	local buttonGap = scaled(SIDE.buttonGap)
	local controlGap = getControlGap()
	local toggleWidth, toggleHeight = getToggleSize()
	local buttons = {
		swapButton,
		layoutButton,
		cornersButton,
		simpleStyleButton,
	}

	controlsHeight = math.max(toggleHeight, buttonSize)
	local yOffset = controlsHeight - buttonSize

	if leftHanded then
		local totalButtonsWidth = (#buttons * buttonSize) + ((#buttons - 1) * controlGap)
		controlsWidth = totalButtonsWidth + controlGap + toggleWidth

		local x = 0
		for _, button in ipairs(buttons) do
			button.Position = UDim2.new(0, x, 0, yOffset)
			x += buttonSize + controlGap
		end

		toggleButton.Parent = controlsFrame
		toggleButton.AnchorPoint = Vector2.new(0, 0)
		toggleButton.Position = UDim2.new(0, x, 0, 0)
	else
		controlsWidth = toggleWidth + controlGap + (#buttons * buttonSize) + ((#buttons - 1) * controlGap)

		toggleButton.Parent = controlsFrame
		toggleButton.AnchorPoint = Vector2.new(0, 0)
		toggleButton.Position = UDim2.new(0, 0, 0, 0)

		local x = toggleWidth + controlGap
		for _, button in ipairs(buttons) do
			button.Position = UDim2.new(0, x, 0, yOffset)
			x += buttonSize + controlGap
		end
	end

	toggleButton.Size = UDim2.new(0, toggleWidth, 0, toggleHeight)
	controlsFrame.Position = UDim2.new(0, 0, 0, 0)
	controlsFrame.Size = UDim2.new(0, controlsWidth, 0, controlsHeight)

	for _, ref in pairs(sideButtonRefs) do
		ref.button.Size = UDim2.new(0, buttonSize, 0, buttonSize)
	end
end

local function buildFullLayout()
	clearKeys()
	layoutControls()

	local rowWidths = {}
	local maxRowWidth = 0
	local keyGap = getKeyGap()
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

	local unitX = getKeySize() + getKeyGap()
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

local function getViewportSize()
	return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
end

local function clampPosition(left, bottom)
	local viewport = getViewportSize()

	local minLeft = KEYBOARD.defaultLeft
	local maxLeft = viewport.X - KEYBOARD.defaultLeft - totalWidth
	local minBottom = KEYBOARD.defaultBottom
	local maxBottom = viewport.Y - KEYBOARD.defaultBottom - totalHeight

	if maxLeft < minLeft then
		maxLeft = minLeft
	end
	if maxBottom < minBottom then
		maxBottom = minBottom
	end

	return math.clamp(left, minLeft, maxLeft), math.clamp(bottom, minBottom, maxBottom)
end

local function updatePositions()
	if stopped then
		return
	end
	uiLeft, uiBottom = clampPosition(uiLeft, uiBottom)
	cluster.Position = UDim2.new(0, uiLeft, 1, -uiBottom)
end


local function setToggleVisual()
	toggleButton.BackgroundColor3 = currentStyle.sideButtonBg
	toggleButton.BackgroundTransparency = currentStyle.idleTransparency
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
		keyboardMask.Visible = false
		keyboardMask.Size = UDim2.new(0, 0, 0, keyboardHeight + getRevealBleed() * 2)
		mouseMask.Visible = false
		mouseMask.Size = UDim2.new(0, 0, 0, sideColumnHeight)
		placeToggleCollapsed()
	end

	applyStyle()
end

local function openUI(animated)
	if isOpen or isAnimating then
		return
	end

	stopTweens()
	isOpen = true
	keyboardMask.Visible = true
	mouseMask.Visible = true
	refreshLayout()

	local revealBleed = getRevealBleed()
	local keyboardTargetWidth = keyboardContentWidth + revealBleed * 2
	local mouseTargetWidth = sideColumnWidth

	if not animated then
		keyboardMask.Size = UDim2.new(0, keyboardTargetWidth, 0, keyboardHeight + revealBleed * 2)
		mouseMask.Size = UDim2.new(0, mouseTargetWidth, 0, sideColumnHeight)
		applyStyle()
		return
	end

	isAnimating = true
	keyboardMask.Size = UDim2.new(0, 0, 0, keyboardHeight + revealBleed * 2)
	mouseMask.Size = UDim2.new(0, 0, 0, sideColumnHeight)

	local keyboardTween = TweenService:Create(
		keyboardMask,
		TweenInfo.new(0.85, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, keyboardTargetWidth, 0, keyboardHeight + revealBleed * 2) }
	)

	local mouseTween = TweenService:Create(
		mouseMask,
		TweenInfo.new(0.85, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, mouseTargetWidth, 0, sideColumnHeight) }
	)

	activeTweens = { keyboardTween, mouseTween }
	keyboardTween:Play()
	mouseTween:Play()
	keyboardTween.Completed:Wait()

	table.clear(activeTweens)
	isAnimating = false
	applyStyle()
end

local function closeUI()
	stopTweens()
	isOpen = false
	isAnimating = false
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
		openUI(true)
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
	leftHanded = not leftHanded
	refreshLayout()
end))

trackConnection(layoutButton.MouseButton1Down:Connect(function()
	setSideButtonPressed("LayoutButton", true)
end))

trackConnection(layoutButton.MouseButton1Up:Connect(function()
	setSideButtonPressed("LayoutButton", false)
end))

trackConnection(layoutButton.Activated:Connect(function()
	currentStyleIndex += 1
	if currentStyleIndex > #STYLES then
		currentStyleIndex = 1
	end
	currentStyle = STYLES[currentStyleIndex]
	applyStyle()
end))

trackConnection(cornersButton.MouseButton1Down:Connect(function()
	setSideButtonPressed("CornersButton", true)
end))

trackConnection(cornersButton.MouseButton1Up:Connect(function()
	setSideButtonPressed("CornersButton", false)
end))

trackConnection(cornersButton.Activated:Connect(function()
	cornersEnabled = not cornersEnabled
	refreshCornerMode()
	applyStyle()
end))

trackConnection(simpleStyleButton.MouseButton1Down:Connect(function()
	setSideButtonPressed("SimpleStyleButton", true)
end))

trackConnection(simpleStyleButton.MouseButton1Up:Connect(function()
	setSideButtonPressed("SimpleStyleButton", false)
end))

trackConnection(simpleStyleButton.Activated:Connect(function()
	simpleStyleEnabled = not simpleStyleEnabled
	refreshLayout()
end))

trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		setKeyState(input.KeyCode, true)
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
	disconnectAllConnections()
	stopTweens()
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
	table.clear(activeTweens)
	table.clear(connections)
	_G.KBMInputDisplay = nil
end

_G.KBMInputDisplay = KBMInputDisplay
return KBMInputDisplay
