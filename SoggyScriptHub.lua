local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local scripts = {
	{
		Name = "Speedometer/FOV",
		Url = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/main/SpeedometerFOVDisplay.lua",
		Stop = function()
			if _G.StopSpeedometerFOV then
				_G.StopSpeedometerFOV()
			end
		end
	},
	{
		Name = "Skybox/Map Cycler",
		Url = "https://example.com/test2.lua",
		Stop = function()
			if _G.StopMapCycler then
				_G.StopMapCycler()
			end
		end
	},
	{
		Name = "Pallet Cycler",
		Url = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/PalletCycler.lua",
		Stop = function()
			if _G.StopPalletCycler then
				_G.StopPalletCycler()
			end
		end
	},
	{
		Name = "Extra QOL",
		Url = "https://example.com/test4.lua",
		Stop = function()
			if _G.StopExtraQOL then
				_G.StopExtraQOL()
			end
		end
	},
	{
		Name = "Minecraft FTAP",
		Url = "https://example.com/test5.lua",
		Stop = function()
			if _G.StopMinecraftFTAP then
				_G.StopMinecraftFTAP()
			end
		end
	},
	{
		Name = "BinisJ",
		Url = "https://example.com/test6.lua",
		Stop = function()
			if _G.StopBinisJ then
				_G.StopBinisJ()
			end
		end
	},
	{
		Name = "Infinite Yield",
		Url = "https://example.com/test7.lua",
		Stop = function()
			if _G.StopInfiniteYield then
				_G.StopInfiniteYield()
			end
		end
	},
	{
		Name = "Dex Explorer",
		Url = "https://example.com/test8.lua",
		Stop = function()
			if _G.StopDexExplorer then
				_G.StopDexExplorer()
			end
		end
	}
}

local activeScripts = {}
local rowRefs = {}

local oldGui = playerGui:FindFirstChild("LoadstringSelectorGui")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "LoadstringSelectorGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 290, 0, 525)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
frame.BorderSizePixel = 0
frame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 14)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(42, 42, 42)
frameStroke.Thickness = 1.2
frameStroke.Transparency = 0.15
frameStroke.Parent = frame

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 42)
topBar.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
topBar.BorderSizePixel = 0
topBar.Parent = frame

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 14)
topBarCorner.Parent = topBar

local topBarFix = Instance.new("Frame")
topBarFix.Size = UDim2.new(1, 0, 0, 16)
topBarFix.Position = UDim2.new(0, 0, 1, -16)
topBarFix.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
topBarFix.BorderSizePixel = 0
topBarFix.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -52, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Script Selector"
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 28, 0, 28)
closeButton.Position = UDim2.new(1, -35, 0, 7)
closeButton.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.BorderSizePixel = 0
closeButton.AutoButtonColor = false
closeButton.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local hintBack = Instance.new("Frame")
hintBack.Size = UDim2.new(1, -24, 0, 32)
hintBack.Position = UDim2.new(0, 12, 0, 54)
hintBack.BackgroundColor3 = Color3.fromRGB(21, 21, 21)
hintBack.BorderSizePixel = 0
hintBack.Parent = frame

local hintCorner = Instance.new("UICorner")
hintCorner.CornerRadius = UDim.new(0, 10)
hintCorner.Parent = hintBack

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -12, 1, 0)
hint.Position = UDim2.new(0, 12, 0, 0)
hint.BackgroundTransparency = 1
hint.Text = "Shift K to close & open menu"
hint.TextColor3 = Color3.fromRGB(175, 175, 175)
hint.Font = Enum.Font.Gotham
hint.TextSize = 13
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Parent = hintBack

local listBack = Instance.new("Frame")
listBack.Size = UDim2.new(1, -24, 1, -102)
listBack.Position = UDim2.new(0, 12, 0, 96)
listBack.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
listBack.BorderSizePixel = 0
listBack.Parent = frame

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 12)
listCorner.Parent = listBack

local scroller = Instance.new("ScrollingFrame")
scroller.Size = UDim2.new(1, -12, 1, -12)
scroller.Position = UDim2.new(0, 6, 0, 6)
scroller.BackgroundTransparency = 1
scroller.BorderSizePixel = 0
scroller.ScrollBarThickness = 3
scroller.ScrollBarImageColor3 = Color3.fromRGB(75, 75, 75)
scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
scroller.Parent = listBack

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.Parent = scroller

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroller.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 2)
end)

local function tween(obj, props, t)
	TweenService:Create(obj, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function refreshRow(name)
	local ref = rowRefs[name]
	if not ref then
		return
	end

	local isActive = activeScripts[name] == true
	ref.Kill.Visible = isActive

	if isActive then
		ref.Main.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	else
		ref.Main.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	end
end

local function activateScript(scriptInfo)
	local success, err = pcall(function()
		loadstring(game:HttpGet(scriptInfo.Url))()
	end)

	if success then
		activeScripts[scriptInfo.Name] = true
		refreshRow(scriptInfo.Name)
	else
		warn("Failed:", scriptInfo.Name, err)
	end
end

local function deactivateScript(scriptInfo)
	local success, err = pcall(function()
		if scriptInfo.Stop then
			scriptInfo.Stop()
		end
	end)

	if not success then
		warn("Stop failed:", scriptInfo.Name, err)
	end

	activeScripts[scriptInfo.Name] = nil
	refreshRow(scriptInfo.Name)
end

for i, scriptInfo in ipairs(scripts) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -2, 0, 48)
	row.BackgroundTransparency = 1
	row.LayoutOrder = i
	row.Parent = scroller

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	button.Text = scriptInfo.Name
	button.TextColor3 = Color3.fromRGB(245, 245, 245)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Parent = row

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 10)
	buttonCorner.Parent = button

	local killButton = Instance.new("TextButton")
	killButton.Size = UDim2.new(0, 26, 0, 26)
	killButton.AnchorPoint = Vector2.new(1, 0.5)
	killButton.Position = UDim2.new(1, -10, 0.5, 0)
	killButton.BackgroundColor3 = Color3.fromRGB(52, 52, 52)
	killButton.Text = "X"
	killButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	killButton.Font = Enum.Font.GothamBold
	killButton.TextSize = 13
	killButton.BorderSizePixel = 0
	killButton.AutoButtonColor = false
	killButton.Visible = false
	killButton.Parent = row

	local killCorner = Instance.new("UICorner")
	killCorner.CornerRadius = UDim.new(0, 8)
	killCorner.Parent = killButton

	rowRefs[scriptInfo.Name] = {
		Main = button,
		Kill = killButton
	}

	button.MouseEnter:Connect(function()
		if not activeScripts[scriptInfo.Name] then
			tween(button, {BackgroundColor3 = Color3.fromRGB(35, 35, 35)})
		end
	end)

	button.MouseLeave:Connect(function()
		if not activeScripts[scriptInfo.Name] then
			tween(button, {BackgroundColor3 = Color3.fromRGB(28, 28, 28)})
		end
	end)

	button.MouseButton1Down:Connect(function()
		tween(button, {BackgroundColor3 = Color3.fromRGB(42, 42, 42)}, 0.06)
	end)

	button.MouseButton1Up:Connect(function()
		if activeScripts[scriptInfo.Name] then
			tween(button, {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}, 0.08)
		else
			tween(button, {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}, 0.08)
		end
	end)

	button.MouseButton1Click:Connect(function()
		activateScript(scriptInfo)
	end)

	killButton.MouseEnter:Connect(function()
		tween(killButton, {BackgroundColor3 = Color3.fromRGB(68, 68, 68)})
	end)

	killButton.MouseLeave:Connect(function()
		tween(killButton, {BackgroundColor3 = Color3.fromRGB(52, 52, 52)})
	end)

	killButton.MouseButton1Click:Connect(function()
		deactivateScript(scriptInfo)
	end)
end

local function setMenu(state)
	gui.Enabled = state
	if state then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end
	camera.CameraType = Enum.CameraType.Custom
end

local open = true
setMenu(true)

closeButton.MouseEnter:Connect(function()
	tween(closeButton, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)})
end)

closeButton.MouseLeave:Connect(function()
	tween(closeButton, {BackgroundColor3 = Color3.fromRGB(42, 42, 42)})
end)

closeButton.MouseButton1Click:Connect(function()
	open = false
	setMenu(false)
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end

	if input.KeyCode == Enum.KeyCode.K and (
		UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or
		UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	) then
		open = not open
		setMenu(open)
	end
end)

RunService.RenderStepped:Connect(function()
	if gui.Enabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end)

local dragging = false
local dragStart
local startPos

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)
