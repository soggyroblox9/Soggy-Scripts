local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

for _, name in ipairs({ "KeyboardVisualizer", "MouseVisualizer", "InputVisualizer" }) do
	local old = playerGui:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "InputVisualizer"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.BorderSizePixel = 0
root.Parent = gui

local DEFAULT_UI_SCALE = 0.65
local SIMPLE_UI_SCALE = 0.9
local currentUiScale = DEFAULT_UI_SCALE

local function S(v)
	return math.floor(v * currentUiScale + 0.5)
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
	assets = {
		bottom = "rbxassetid://76563324380675",
		left = "rbxassetid://136424168694433",
		right = "rbxassetid://140592291990835",
		middle = "rbxassetid://129489611077671",
	},
}

local SIDE = {
	buttonSize = 42,
	buttonWidth = 42,
	buttonGap = 6,
	iconInset = 4,
	assets = {
		swap = "rbxassetid://136330436723114",
		drag = "rbxassetid://98735676558040",
		lockLocked = "rbxassetid://122498571171192",
		lockUnlocked = "rbxassetid://78649068959806",
		layout = "rbxassetid://137731564645457",
		cornersOff = "rbxassetid://122630615991387",
		cornersOn = "rbxassetid://140578753916877",
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
		name = "DefaultMode",
		idleBg = Color3.fromRGB(255, 255, 255),
		idleText = Color3.fromRGB(0, 0, 0),
		pressedBg = Color3.fromRGB(0, 0, 0),
		pressedText = Color3.fromRGB(255, 255, 255),
		sideButtonBg = Color3.fromRGB(0, 0, 0),
		sideButtonIcon = Color3.fromRGB(255, 255, 255),
		toggleBgClosed = Color3.fromRGB(0, 0, 0),
		toggleBgOpen = Color3.fromRGB(255, 255, 255),
		mouseIdle = Color3.fromRGB(255, 255, 255),
		mousePressed = Color3.fromRGB(0, 0, 0),
		idleTransparency = TRANSPARENCY.idle,
		pressedTransparency = TRANSPARENCY.pressed,
		font = Enum.Font.GothamBold,
		gradient = nil,
		pressedGradient = nil,
	},
	{
		name = "HighContrastMode",
		idleBg = Color3.fromRGB(255, 255, 255),
		idleText = Color3.fromRGB(0, 0, 0),
		pressedBg = Color3.fromRGB(0, 0, 0),
		pressedText = Color3.fromRGB(0, 255, 255),
		sideButtonBg = Color3.fromRGB(0, 0, 0),
		sideButtonIcon = Color3.fromRGB(255, 255, 255),
		toggleBgClosed = Color3.fromRGB(0, 0, 0),
		toggleBgOpen = Color3.fromRGB(255, 255, 255),
		mouseIdle = Color3.fromRGB(255, 255, 255),
		mousePressed = Color3.fromRGB(0, 0, 0),
		idleTransparency = TRANSPARENCY.contrastIdle,
		pressedTransparency = TRANSPARENCY.contrastPressed,
		font = Enum.Font.GothamBlack,
		gradient = nil,
		pressedGradient = nil,
	},
	{
		name = "BlueMode",
		idleBg = Color3.fromRGB(170, 210, 255),
		idleText = Color3.fromRGB(10, 25, 45),
		pressedBg = Color3.fromRGB(35, 85, 170),
		pressedText = Color3.fromRGB(255, 255, 255),
		sideButtonBg = Color3.fromRGB(35, 85, 170),
		sideButtonIcon = Color3.fromRGB(255, 255, 255),
		toggleBgClosed = Color3.fromRGB(35, 85, 170),
		toggleBgOpen = Color3.fromRGB(170, 210, 255),
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
		name = "RedMode",
		idleBg = Color3.fromRGB(255, 185, 185),
		idleText = Color3.fromRGB(55, 10, 10),
		pressedBg = Color3.fromRGB(170, 30, 30),
		pressedText = Color3.fromRGB(255, 255, 255),
		sideButtonBg = Color3.fromRGB(170, 30, 30),
		sideButtonIcon = Color3.fromRGB(255, 255, 255),
		toggleBgClosed = Color3.fromRGB(170, 30, 30),
		toggleBgOpen = Color3.fromRGB(255, 185, 185),
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
		name = "GreenMode",
		idleBg = Color3.fromRGB(185, 255, 190),
		idleText = Color3.fromRGB(15, 50, 20),
		pressedBg = Color3.fromRGB(35, 145, 60),
		pressedText = Color3.fromRGB(255, 255, 255),
		sideButtonBg = Color3.fromRGB(35, 145, 60),
		sideButtonIcon = Color3.fromRGB(255, 255, 255),
		toggleBgClosed = Color3.fromRGB(35, 145, 60),
		toggleBgOpen = Color3.fromRGB(185, 255, 190),
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

local simpleStyleEnabled = false
local isOpen = false
local isAnimating = false
local dragging = false
local positionLocked = false
local cornersEnabled = true
local leftHanded = false
local suppressNextLeftMouseVisual = false
local uiLeft = KEYBOARD.defaultLeft
local uiBottom = KEYBOARD.defaultBottom
local dragStartMouse = Vector2.zero
local dragStartPos = Vector2.zero
local activeTweens = {}

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

local keyRefs = {}
local sideButtonRefs = {}
local mouseState = {
	[Enum.UserInputType.MouseButton1] = false,
	[Enum.UserInputType.MouseButton2] = false,
	[Enum.UserInputType.MouseButton3] = false,
}

local enterKeyFrame
local ctrlKeyFrame
local spaceKeyFrame

local function getCornerRadius()
	return cornersEnabled and S(KEYBOARD.corner) or 0
end

local function scaled(v)
	return S(v)
end

local cluster = Instance.new("Frame")
cluster.Name = "Cluster"
cluster.AnchorPoint = Vector2.new(0, 1)
cluster.BackgroundTransparency = 1
cluster.BorderSizePixel = 0
cluster.Parent = root

local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0, 1)
main.BackgroundTransparency = 1
main.BorderSizePixel = 0
main.ClipsDescendants = false
main.Parent = cluster

local keyboardMask = Instance.new("Frame")
keyboardMask.Name = "KeyboardMask"
keyboardMask.BackgroundTransparency = 1
keyboardMask.BorderSizePixel = 0
keyboardMask.ClipsDescendants = true
keyboardMask.Visible = false
keyboardMask.Parent = main

local keyboardFrame = Instance.new("Frame")
keyboardFrame.Name = "KeyboardFrame"
keyboardFrame.BackgroundTransparency = 1
keyboardFrame.BorderSizePixel = 0
keyboardFrame.Parent = keyboardMask

local controlsFrame = Instance.new("Frame")
controlsFrame.Name = "ControlsFrame"
controlsFrame.BackgroundTransparency = 1
controlsFrame.BorderSizePixel = 0
controlsFrame.Parent = keyboardFrame

local sideColumn = Instance.new("Frame")
sideColumn.Name = "SideColumn"
sideColumn.AnchorPoint = Vector2.new(0, 1)
sideColumn.BackgroundTransparency = 1
sideColumn.BorderSizePixel = 0
sideColumn.Parent = cluster

local mouseMask = Instance.new("Frame")
mouseMask.Name = "MouseMask"
mouseMask.AnchorPoint = Vector2.new(0, 1)
mouseMask.BackgroundTransparency = 1
mouseMask.BorderSizePixel = 0
mouseMask.ClipsDescendants = true
mouseMask.Visible = false
mouseMask.Parent = sideColumn

local mouseColumn = Instance.new("Frame")
mouseColumn.Name = "MouseColumn"
mouseColumn.BackgroundTransparency = 1
mouseColumn.BorderSizePixel = 0
mouseColumn.Parent = mouseMask

local mouseFrame = Instance.new("Frame")
mouseFrame.Name = "MouseFrame"
mouseFrame.AnchorPoint = Vector2.new(0.5, 1)
mouseFrame.BackgroundTransparency = 1
mouseFrame.BorderSizePixel = 0
mouseFrame.Parent = mouseColumn

local toggleButton = Instance.new("ImageButton")
toggleButton.Name = "ToggleButton"
toggleButton.BorderSizePixel = 0
toggleButton.AutoButtonColor = false
toggleButton.Image = ""
toggleButton.ZIndex = 50
toggleButton.Parent = root

local toggleCorner = Instance.new("UICorner")
toggleCorner.Parent = toggleButton

local toggleIcon = Instance.new("ImageLabel")
toggleIcon.Name = "Icon"
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
	frameCorner.CornerRadius = UDim.new(0, getCornerRadius())
	frameCorner.Parent = key

	local gradient = createGradientHost(key)

	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = label
	text.TextSize = scaled(KEYBOARD.textSize)
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
	part.ScaleType = Enum.ScaleType.Stretch
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

	button.MouseButton1Down:Connect(function()
		suppressNextLeftMouseVisual = true
	end)

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
local dragButton = createSideImageButton("DragButton", SIDE.assets.drag)
local lockButton = createSideImageButton("LockButton", SIDE.assets.lockUnlocked)
local layoutButton = createSideImageButton("LayoutButton", SIDE.assets.layout)
local cornersButton = createSideImageButton("CornersButton", SIDE.assets.cornersOn)
local simpleStyleButton = createSideImageButton("SimpleStyleButton", SIDE.assets.simplestyle)

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

local function getKeyWidth(keyData)
	if squareKeyMap[keyData.code] and not keyData.width then
		return scaled(KEYBOARD.keySize)
	end
	return math.floor(scaled(KEYBOARD.keySize) * (keyData.width or 1) + 0.5)
end

local function clearKeys()
	for _, ref in pairs(keyRefs) do
		ref.frame:Destroy()
	end
	table.clear(keyRefs)
	enterKeyFrame = nil
	ctrlKeyFrame = nil
	spaceKeyFrame = nil
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
	ref.text.TextSize = scaled(KEYBOARD.textSize)
	applyGradient(ref.gradient, pressed and currentStyle.pressedGradient or currentStyle.gradient)
end

local function applyMousePartVisual(partRef, pressed)
	partRef.image.ImageColor3 = pressed and currentStyle.mousePressed or currentStyle.mouseIdle
	partRef.image.ImageTransparency = pressed and currentStyle.pressedTransparency or currentStyle.idleTransparency
	applyGradient(partRef.gradient, pressed and currentStyle.pressedGradient or currentStyle.gradient)
end

local function refreshLockIcon()
	sideButtonRefs.LockButton.icon.Image = positionLocked and SIDE.assets.lockLocked or SIDE.assets.lockUnlocked
	sideButtonRefs.LockButton.fallback.Text = positionLocked and "L" or "U"
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
		ref.fallback.TextColor3 = currentStyle.sideButtonIcon
		ref.fallback.Font = currentStyle.font
		ref.fallback.Size = UDim2.new(1, -4, 1, -4)
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
	refreshLockIcon()
	refreshCornersIcon()

	toggleButton.BackgroundColor3 = currentStyle.sideButtonBg
	toggleButton.BackgroundTransparency = currentStyle.idleTransparency
	toggleIcon.ImageColor3 = currentStyle.sideButtonIcon

	refreshCornerMode()
end

local function addKey(keyData, x, y)
	local width = getKeyWidth(keyData)
	local ref = createKey(keyboardFrame, width, scaled(KEYBOARD.keySize), keyData.label)
	ref.frame.Position = UDim2.new(0, x, 0, y)
	keyRefs[keyData.code] = ref

	if keyData.code == Enum.KeyCode.Return then
		enterKeyFrame = ref.frame
	elseif keyData.code == Enum.KeyCode.LeftControl then
		ctrlKeyFrame = ref.frame
	elseif keyData.code == Enum.KeyCode.Space then
		spaceKeyFrame = ref.frame
	end
end

local function layoutControls()
	local buttons = {
		swapButton,
		dragButton,
		lockButton,
		layoutButton,
		cornersButton,
		simpleStyleButton,
	}

	local toggleWidth = math.floor(scaled(KEYBOARD.keySize) * (TOGGLE_ASPECT_X / TOGGLE_ASPECT_Y) + 0.5)
	local toggleHeight = scaled(KEYBOARD.keySize)
	local gap = scaled(KEYBOARD.controlGap)
	local buttonWidth = scaled(SIDE.buttonWidth)
	local buttonHeight = scaled(SIDE.buttonSize)
	local buttonY = math.max(0, math.floor((toggleHeight - buttonHeight) / 2))

	controlsHeight = toggleHeight
	toggleButton.Parent = controlsFrame
	toggleButton.AnchorPoint = Vector2.new(0, 0)
	toggleButton.Size = UDim2.new(0, toggleWidth, 0, toggleHeight)
	toggleIcon.Size = UDim2.new(0.88, 0, 0.88, 0)

	local x = 0
	if leftHanded then
		for _, button in ipairs(buttons) do
			button.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
			button.Position = UDim2.new(0, x, 0, buttonY)
			x += buttonWidth + gap
		end
		toggleButton.Position = UDim2.new(0, x, 0, 0)
		x += toggleWidth
	else
		toggleButton.Position = UDim2.new(0, 0, 0, 0)
		x = toggleWidth + gap
		for _, button in ipairs(buttons) do
			button.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
			button.Position = UDim2.new(0, x, 0, buttonY)
			x += buttonWidth + gap
		end
		x -= gap
	end

	controlsWidth = x
	controlsFrame.Size = UDim2.new(0, controlsWidth, 0, controlsHeight)
end

local function placeControls()
	if leftHanded then
		controlsFrame.Position = UDim2.new(0, math.max(0, keyboardContentWidth - controlsWidth), 0, 0)
	else
		controlsFrame.Position = UDim2.new(0, 0, 0, 0)
	end
end

local function buildFullLayout()
	clearKeys()
	layoutControls()

	local rowWidths = {}
	local maxRowWidth = 0

	for i, row in ipairs(fullRows) do
		local width = 0
		for j, keyData in ipairs(row) do
			width += getKeyWidth(keyData)
			if j < #row then
				width += scaled(KEYBOARD.keyGap)
			end
		end
		rowWidths[i] = width
		maxRowWidth = math.max(maxRowWidth, width)
	end

	local topOffset = controlsHeight + scaled(KEYBOARD.controlRowGap)

	keyboardContentWidth = math.max(maxRowWidth, controlsWidth)
	keyboardHeight = topOffset + (#fullRows * scaled(KEYBOARD.keySize)) + ((#fullRows - 1) * scaled(KEYBOARD.rowGap))
	keyboardMainWidth = keyboardContentWidth + scaled(KEYBOARD.sidePadding) * 2
	keyboardMainHeight = keyboardHeight + scaled(KEYBOARD.topPadding) + scaled(KEYBOARD.bottomPadding)
	placeControls()

	for rowIndex, row in ipairs(fullRows) do
		local y = topOffset + (rowIndex - 1) * (scaled(KEYBOARD.keySize) + scaled(KEYBOARD.rowGap))
		local rowWidth = rowWidths[rowIndex]
		local startX = leftHanded and (keyboardContentWidth - rowWidth) or 0
		local x = startX

		for _, keyData in ipairs(row) do
			addKey(keyData, x, y)
			x += getKeyWidth(keyData) + scaled(KEYBOARD.keyGap)
		end
	end
end

local function buildSimpleLayout()
	clearKeys()
	layoutControls()

	local unitX = scaled(KEYBOARD.keySize) + scaled(KEYBOARD.keyGap)
	local unitY = scaled(KEYBOARD.keySize) + scaled(KEYBOARD.rowGap)
	local topOffset = controlsHeight + scaled(KEYBOARD.controlRowGap)

	local placements = {
		{ label = "Tab", code = Enum.KeyCode.Tab, x = 0.0, y = 0.0, width = 1.5 },
		{ label = "E", code = Enum.KeyCode.E, x = 1.45, y = 0.0 },
		{ label = "I", code = Enum.KeyCode.I, x = 2.45, y = 0.0 },
		{ label = "O", code = Enum.KeyCode.O, x = 3.45, y = 0.0 },

		{ label = "Shift", code = Enum.KeyCode.LeftShift, x = 0.0, y = 1.0, width = 1.8 },
		{ label = "W", code = Enum.KeyCode.W, x = 1.73, y = 1.0 },
		{ label = "A", code = Enum.KeyCode.A, x = 2.73, y = 1.0 },
		{ label = "S", code = Enum.KeyCode.S, x = 3.73, y = 1.0 },
		{ label = "D", code = Enum.KeyCode.D, x = 4.73, y = 1.0 },

		{ label = "Ctrl", code = Enum.KeyCode.LeftControl, x = 0.0, y = 2.0, width = 1.6 },
		{ label = "Space", code = Enum.KeyCode.Space, x = 1.55, y = 2.0, width = 4.2 },

		{ label = "0", code = Enum.KeyCode.Zero, x = 4.45, y = 0.0 },
		{ label = "1", code = Enum.KeyCode.One, x = 5.45, y = 0.0 },
		{ label = "2", code = Enum.KeyCode.Two, x = 6.45, y = 0.0 },
		{ label = "3", code = Enum.KeyCode.Three, x = 7.45, y = 0.0 },

		{ label = "4", code = Enum.KeyCode.Four, x = 5.45, y = 1.0 },
		{ label = "5", code = Enum.KeyCode.Five, x = 6.45, y = 1.0 },
		{ label = "6", code = Enum.KeyCode.Six, x = 7.45, y = 1.0 },

		{ label = "7", code = Enum.KeyCode.Seven, x = 5.45, y = 2.0 },
		{ label = "8", code = Enum.KeyCode.Eight, x = 6.45, y = 2.0 },
		{ label = "9", code = Enum.KeyCode.Nine, x = 7.45, y = 2.0 },
	}

	local maxRight = controlsWidth
	local maxBottom = controlsHeight
	local placementRight = 0

	for _, keyData in ipairs(placements) do
		local width = getKeyWidth(keyData)
		local x = math.floor(keyData.x * unitX + 0.5)
		local y = topOffset + math.floor(keyData.y * unitY + 0.5)
		placementRight = math.max(placementRight, x + width)
		maxRight = math.max(maxRight, x + width)
		maxBottom = math.max(maxBottom, y + scaled(KEYBOARD.keySize))
	end

	keyboardContentWidth = maxRight
	keyboardHeight = maxBottom
	keyboardMainWidth = keyboardContentWidth + scaled(KEYBOARD.sidePadding) * 2
	keyboardMainHeight = keyboardHeight + scaled(KEYBOARD.topPadding) + scaled(KEYBOARD.bottomPadding)
	placeControls()

	local simpleContentRight = placementRight
	local simpleRightOffset = leftHanded and math.max(0, keyboardContentWidth - simpleContentRight) or 0

	for _, keyData in ipairs(placements) do
		local x = math.floor(keyData.x * unitX + 0.5) + simpleRightOffset
		local y = topOffset + math.floor(keyData.y * unitY + 0.5)
		addKey(keyData, x, y)
	end
end

local function rebuildKeyboardLayout()
	currentUiScale = simpleStyleEnabled and SIMPLE_UI_SCALE or DEFAULT_UI_SCALE

	if simpleStyleEnabled then
		buildSimpleLayout()
	else
		buildFullLayout()
	end

	main.Size = UDim2.new(0, keyboardMainWidth, 0, keyboardMainHeight)
	keyboardMask.Position = UDim2.new(0, scaled(KEYBOARD.sidePadding) - scaled(KEYBOARD.revealBleed), 0, scaled(KEYBOARD.topPadding) - scaled(KEYBOARD.revealBleed))
	keyboardMask.Size = UDim2.new(0, 0, 0, keyboardHeight + scaled(KEYBOARD.revealBleed) * 2)
	keyboardFrame.Position = UDim2.new(0, scaled(KEYBOARD.revealBleed), 0, scaled(KEYBOARD.revealBleed))
	keyboardFrame.Size = UDim2.new(0, keyboardContentWidth, 0, keyboardHeight)
end

local function refreshMeasurements()
	sideColumnWidth = scaled(MOUSE.width)
	sideColumnHeight = math.max(keyboardMainHeight, scaled(MOUSE.height) + scaled(MOUSE.bottomGap))

	totalWidth = keyboardMainWidth + scaled(MOUSE.gapFromKeyboard) + sideColumnWidth
	totalHeight = math.max(keyboardMainHeight, sideColumnHeight)

	cluster.Size = UDim2.new(0, totalWidth, 0, totalHeight)
	sideColumn.Size = UDim2.new(0, sideColumnWidth, 0, sideColumnHeight)

	mouseMask.Position = UDim2.new(0, 0, 1, 0)
	mouseMask.Size = UDim2.new(0, isOpen and sideColumnWidth or 0, 0, sideColumnHeight)
	mouseColumn.Size = UDim2.new(0, sideColumnWidth, 0, sideColumnHeight)
	mouseColumn.Position = UDim2.new(0, 0, 0, 0)

	mouseFrame.Size = UDim2.new(0, scaled(MOUSE.width), 0, scaled(MOUSE.height))
	mouseFrame.Position = UDim2.new(0.5, 0, 1, -scaled(MOUSE.bottomGap))
end

local function layoutCluster()
	if leftHanded then
		sideColumn.Position = UDim2.new(0, 0, 1, 0)
		main.Position = UDim2.new(0, sideColumnWidth + scaled(MOUSE.gapFromKeyboard), 1, 0)
	else
		main.Position = UDim2.new(0, 0, 1, 0)
		sideColumn.Position = UDim2.new(0, keyboardMainWidth + scaled(MOUSE.gapFromKeyboard), 1, 0)
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
	uiLeft, uiBottom = clampPosition(uiLeft, uiBottom)
	cluster.Position = UDim2.new(0, uiLeft, 1, -uiBottom)
end

local function stopTweens()
	for _, tween in ipairs(activeTweens) do
		tween:Cancel()
	end
	table.clear(activeTweens)
end

local function setToggleVisual(open)
	toggleButton.BackgroundColor3 = currentStyle.sideButtonBg
	toggleButton.BackgroundTransparency = currentStyle.idleTransparency
	toggleIcon.Visible = true
end

local function placeToggleCollapsed()
	local toggleWidth = math.floor(scaled(KEYBOARD.keySize) * (TOGGLE_ASPECT_X / TOGGLE_ASPECT_Y) + 0.5)
	local toggleHeight = scaled(KEYBOARD.keySize)
	toggleButton.Parent = root
	toggleButton.AnchorPoint = Vector2.new(0, 1)
	toggleButton.Position = UDim2.new(0, KEYBOARD.collapsedLeft, 1, -KEYBOARD.collapsedBottom)
	toggleButton.Size = UDim2.new(0, toggleWidth, 0, toggleHeight)
	setToggleVisual(false)
end

local function refreshLayout()
	rebuildKeyboardLayout()
	refreshMeasurements()
	layoutCluster()
	updatePositions()

	if isOpen then
		local keyboardTargetWidth = keyboardContentWidth + scaled(KEYBOARD.revealBleed) * 2
		keyboardMask.Visible = true
		keyboardMask.Size = UDim2.new(0, keyboardTargetWidth, 0, keyboardHeight + scaled(KEYBOARD.revealBleed) * 2)
		mouseMask.Visible = true
		mouseMask.Size = UDim2.new(0, sideColumnWidth, 0, sideColumnHeight)
	else
		keyboardMask.Visible = false
		keyboardMask.Size = UDim2.new(0, 0, 0, keyboardHeight + scaled(KEYBOARD.revealBleed) * 2)
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

	local keyboardTargetWidth = keyboardContentWidth + scaled(KEYBOARD.revealBleed) * 2
	local mouseTargetWidth = sideColumnWidth

	if not animated then
		keyboardMask.Size = UDim2.new(0, keyboardTargetWidth, 0, keyboardHeight + scaled(KEYBOARD.revealBleed) * 2)
		mouseMask.Size = UDim2.new(0, mouseTargetWidth, 0, sideColumnHeight)
		applyStyle()
		return
	end

	isAnimating = true
	keyboardMask.Size = UDim2.new(0, 0, 0, keyboardHeight + scaled(KEYBOARD.revealBleed) * 2)
	mouseMask.Size = UDim2.new(0, 0, 0, sideColumnHeight)

	local keyboardTween = TweenService:Create(
		keyboardMask,
		TweenInfo.new(0.85, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, keyboardTargetWidth, 0, keyboardHeight + scaled(KEYBOARD.revealBleed) * 2) }
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
	dragging = false
	keyboardMask.Visible = false
	mouseMask.Visible = false
	keyboardMask.Size = UDim2.new(0, 0, 0, keyboardHeight + scaled(KEYBOARD.revealBleed) * 2)
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

toggleButton.MouseButton1Down:Connect(function()
	suppressNextLeftMouseVisual = true
end)

toggleButton.Activated:Connect(function()
	if isOpen then
		closeUI()
	else
		openUI(true)
	end
end)

swapButton.MouseButton1Down:Connect(function()
	setSideButtonPressed("SwapButton", true)
end)

swapButton.MouseButton1Up:Connect(function()
	setSideButtonPressed("SwapButton", false)
end)

swapButton.Activated:Connect(function()
	leftHanded = not leftHanded
	refreshLayout()
end)

lockButton.MouseButton1Down:Connect(function()
	setSideButtonPressed("LockButton", true)
end)

lockButton.MouseButton1Up:Connect(function()
	setSideButtonPressed("LockButton", false)
end)

lockButton.Activated:Connect(function()
	positionLocked = not positionLocked
	dragging = false
	refreshLockIcon()
	refreshSideButtons()
end)

layoutButton.MouseButton1Down:Connect(function()
	setSideButtonPressed("LayoutButton", true)
end)

layoutButton.MouseButton1Up:Connect(function()
	setSideButtonPressed("LayoutButton", false)
end)

layoutButton.Activated:Connect(function()
	currentStyleIndex += 1
	if currentStyleIndex > #STYLES then
		currentStyleIndex = 1
	end
	currentStyle = STYLES[currentStyleIndex]
	applyStyle()
end)

cornersButton.MouseButton1Down:Connect(function()
	setSideButtonPressed("CornersButton", true)
end)

cornersButton.MouseButton1Up:Connect(function()
	setSideButtonPressed("CornersButton", false)
end)

cornersButton.Activated:Connect(function()
	cornersEnabled = not cornersEnabled
	refreshCornerMode()
	applyStyle()
end)

simpleStyleButton.MouseButton1Down:Connect(function()
	setSideButtonPressed("SimpleStyleButton", true)
end)

simpleStyleButton.MouseButton1Up:Connect(function()
	setSideButtonPressed("SimpleStyleButton", false)
end)

simpleStyleButton.Activated:Connect(function()
	simpleStyleEnabled = not simpleStyleEnabled
	refreshLayout()
end)

dragButton.MouseButton1Down:Connect(function()
	setSideButtonPressed("DragButton", true)
	if not isOpen or positionLocked then
		return
	end
	dragging = true
	dragStartMouse = UserInputService:GetMouseLocation()
	dragStartPos = Vector2.new(uiLeft, uiBottom)
end)

dragButton.MouseButton1Up:Connect(function()
	setSideButtonPressed("DragButton", false)
	dragging = false
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local mousePos = UserInputService:GetMouseLocation()
		local delta = mousePos - dragStartMouse
		uiLeft = dragStartPos.X + delta.X
		uiBottom = dragStartPos.Y - delta.Y
		updatePositions()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
		for name in pairs(sideButtonRefs) do
			setSideButtonPressed(name, false)
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

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
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		setKeyState(input.KeyCode, false)
		return
	end

	if mouseRefs[input.UserInputType] then
		setMouseState(input.UserInputType, false)
	end
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	task.defer(updatePositions)
end)

local camera = workspace.CurrentCamera
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePositions)
end

refreshLayout()

task.delay(1, function()
	if gui.Parent and not isOpen then
		openUI(true)
	end
end)
