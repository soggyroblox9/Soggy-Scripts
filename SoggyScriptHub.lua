local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local placeId = game.PlaceId
local jobId = game.JobId

local reExecuteOnTeleport = true
local fpsUncapEnabled = false
local targetFOV = math.floor(((camera and camera.FieldOfView) or 70) + 0.5)
local menuOpacity = 100
local commandText = ""

local MENU_LOADSTRING_URL = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/SoggyScriptHub.lua"

local activeScripts = {}
local rowRefs = {}
local currentTab = "Scripts"
local opacityTargets = {}

local function requestUrl(url)
	local req = syn and syn.request
		or http_request
		or request
		or (http and http.request)
		or (fluxus and fluxus.request)

	if not req then
		return nil, "No supported request function found"
	end

	local ok, res = pcall(function()
		return req({
			Url = url,
			Method = "GET"
		})
	end)

	if not ok or not res then
		return nil, "Request failed"
	end

	if res.StatusCode ~= 200 or not res.Body then
		return nil, "Bad response"
	end

	return res.Body
end

local function queueTeleportSource(source)
	local queueFn =
		queue_on_teleport
		or queueonteleport
		or (syn and syn.queue_on_teleport)

	if not queueFn then
		return
	end

	pcall(function()
		queueFn(source)
	end)
end

local function queueReexecute()
	if reExecuteOnTeleport then
		local source = string.format('loadstring(game:HttpGet("%s"))()', MENU_LOADSTRING_URL)
		queueTeleportSource(source)
	else
		queueTeleportSource("")
	end
end

local function getSetFpsCapFunction()
	return setfpscap
		or set_fps_cap
		or (syn and syn.setfpscap)
end

local function applyFpsCap()
	local setCap = getSetFpsCapFunction()
	if not setCap then
		return
	end

	pcall(function()
		if fpsUncapEnabled then
			setCap(999)
		else
			setCap(60)
		end
	end)
end

local function tween(obj, props, t)
	TweenService:Create(
		obj,
		TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props
	):Play()
end

local function addOpacityTarget(obj, prop, base)
	table.insert(opacityTargets, {
		obj = obj,
		prop = prop or "BackgroundTransparency",
		base = base or 0
	})
end

local function applyMenuOpacity()
	local extra = 1 - (menuOpacity / 100)

	for _, entry in ipairs(opacityTargets) do
		local obj = entry.obj
		if obj and obj.Parent then
			local value = math.clamp(entry.base + extra, 0, 1)
			pcall(function()
				obj[entry.prop] = value
			end)
		end
	end
end

local scripts = {
	{
		Name = "Speedometer/FOV",
		CanStop = true,
		Url = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/SpeedometerFOVDisplay.lua",
		Action = function(self)
			loadstring(game:HttpGet(self.Url))()
		end,
		Stop = function()
			if _G.StopSpeedometerFOV then
				_G.StopSpeedometerFOV()
			end
		end
	},
	{
		Name = "Skybox/Map Cycler(WIP)",
		CanStop = true,
		Stop = function()
			if _G.StopMapCycler then
				_G.StopMapCycler()
			end
		end,
		Action = function()
			print("Run Skybox/Map Cycler")
		end
	},
	{
		Name = "Pallet Cycler",
		CanStop = true,
		Url = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/PalletCycler.lua",
		Action = function(self)
			loadstring(game:HttpGet(self.Url))()
		end,
		Stop = function()
			if _G.StopPalletCycler then
				_G.StopPalletCycler()
			end
		end
	},
	{
		Name = "Freecam",
		CanStop = true,
		Url = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/FreeCam.lua",
		Action = function(self)
			loadstring(game:HttpGet(self.Url))()
		end,
		Stop = function()
			if _G.StopFreeCam then
				_G.StopFreeCam()
			end
		end
	},
	{
		Name = "KBMInputDisplay",
		CanStop = true,
		Url = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/KBMInputDisplay.lua",
		Action = function(self)
			loadstring(game:HttpGet(self.Url))()
		end,
		Stop = function()
			if _G.StopKBMInputDisplay then
				_G.StopKBMInputDisplay()
			end
		end
	},
	{
		Name = "Infinite Yield",
		CanStop = false,
		Url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
		Action = function(self)
			loadstring(game:HttpGet(self.Url))()
		end
	},
	{
		Name = "Dex Explorer(DONT CLICK)",
		CanStop = false,
		Url = "https://raw.githubusercontent.com/peyton2465/Dex/master/out.lua",
		Action = function(self)
			loadstring(game:HttpGet(self.Url))()
		end
	}
}

local function setMenuOpen(gui, state)
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

local function refreshRow(scriptName)
	local ref = rowRefs[scriptName]
	if not ref then
		return
	end

	local isActive = activeScripts[scriptName] == true
	ref.Button.BackgroundColor3 = isActive and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(28, 28, 28)

	if ref.Kill then
		ref.Kill.Visible = isActive
	end
end

local function activateScript(scriptInfo)
	local ok, err = pcall(function()
		if scriptInfo.Action then
			scriptInfo.Action(scriptInfo)
		end
	end)

	if ok then
		activeScripts[scriptInfo.Name] = true
		refreshRow(scriptInfo.Name)
	else
		warn("Failed to run " .. scriptInfo.Name .. ": " .. tostring(err))
	end
end

local function deactivateScript(scriptInfo)
	if not scriptInfo.CanStop then
		return
	end

	local ok, err = pcall(function()
		if scriptInfo.Stop then
			scriptInfo.Stop()
		end
	end)

	if not ok then
		warn("Failed to stop " .. scriptInfo.Name .. ": " .. tostring(err))
	end

	activeScripts[scriptInfo.Name] = nil
	refreshRow(scriptInfo.Name)
end

local function unloadActiveScripts()
	for _, scriptInfo in ipairs(scripts) do
		if activeScripts[scriptInfo.Name] and scriptInfo.CanStop then
			deactivateScript(scriptInfo)
		end
	end
end

local function rejoinServer()
	queueReexecute()
	TeleportService:Teleport(placeId, player)
end

local function serverHop()
	local cursor = ""
	local foundServer

	for _ = 1, 8 do
		local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
		if cursor ~= "" then
			url = url .. "&cursor=" .. cursor
		end

		local body, err = requestUrl(url)
		if not body then
			warn("Server hop failed: " .. tostring(err))
			break
		end

		local ok, data = pcall(function()
			return HttpService:JSONDecode(body)
		end)

		if not ok or not data or not data.data then
			warn("Server hop failed: invalid server list")
			break
		end

		local shuffled = {}
		for i, server in ipairs(data.data) do
			shuffled[i] = server
		end

		for i = #shuffled, 2, -1 do
			local j = math.random(i)
			shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
		end

		for _, server in ipairs(shuffled) do
			if server.id ~= jobId and server.playing < server.maxPlayers then
				foundServer = server.id
				break
			end
		end

		if foundServer then
			break
		end

		cursor = data.nextPageCursor or ""
		if cursor == "" then
			break
		end
	end

	if foundServer then
		queueReexecute()
		TeleportService:TeleportToPlaceInstance(placeId, foundServer, player)
	else
		warn("No different server found")
	end
end

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
frame.Name = "Main"
frame.Size = UDim2.new(0, 320, 0, 530)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
frame.BorderSizePixel = 0
frame.Parent = gui
addOpacityTarget(frame)

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 14)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(42, 42, 42)
frameStroke.Thickness = 1.2
frameStroke.Transparency = 0.15
frameStroke.Parent = frame
addOpacityTarget(frameStroke, "Transparency", 0.15)

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 42)
topBar.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
topBar.BorderSizePixel = 0
topBar.Parent = frame
addOpacityTarget(topBar)

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 14)
topBarCorner.Parent = topBar

local topBarFix = Instance.new("Frame")
topBarFix.Size = UDim2.new(1, 0, 0, 16)
topBarFix.Position = UDim2.new(0, 0, 1, -16)
topBarFix.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
topBarFix.BorderSizePixel = 0
topBarFix.Parent = topBar
addOpacityTarget(topBarFix)

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
closeButton.BorderSizePixel = 0
closeButton.AutoButtonColor = false
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.Parent = topBar
addOpacityTarget(closeButton)

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local hintBack = Instance.new("Frame")
hintBack.Size = UDim2.new(1, -24, 0, 32)
hintBack.Position = UDim2.new(0, 12, 0, 54)
hintBack.BackgroundColor3 = Color3.fromRGB(21, 21, 21)
hintBack.BorderSizePixel = 0
hintBack.Parent = frame
addOpacityTarget(hintBack)

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

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -24, 0, 34)
tabBar.Position = UDim2.new(0, 12, 0, 94)
tabBar.BackgroundTransparency = 1
tabBar.Parent = frame

local scriptsTabButton = Instance.new("TextButton")
scriptsTabButton.Size = UDim2.new(1/3, -7, 1, 0)
scriptsTabButton.Position = UDim2.new(0, 0, 0, 0)
scriptsTabButton.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
scriptsTabButton.BorderSizePixel = 0
scriptsTabButton.AutoButtonColor = false
scriptsTabButton.Text = "Scripts"
scriptsTabButton.TextColor3 = Color3.fromRGB(245, 245, 245)
scriptsTabButton.Font = Enum.Font.GothamBold
scriptsTabButton.TextSize = 13
scriptsTabButton.Parent = tabBar
addOpacityTarget(scriptsTabButton)

local scriptsTabCorner = Instance.new("UICorner")
scriptsTabCorner.CornerRadius = UDim.new(0, 10)
scriptsTabCorner.Parent = scriptsTabButton

local keybindsTabButton = Instance.new("TextButton")
keybindsTabButton.Size = UDim2.new(1/3, -7, 1, 0)
keybindsTabButton.Position = UDim2.new(1/3, 3, 0, 0)
keybindsTabButton.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
keybindsTabButton.BorderSizePixel = 0
keybindsTabButton.AutoButtonColor = false
keybindsTabButton.Text = "Keybinds"
keybindsTabButton.TextColor3 = Color3.fromRGB(205, 205, 205)
keybindsTabButton.Font = Enum.Font.GothamBold
keybindsTabButton.TextSize = 13
keybindsTabButton.Parent = tabBar
addOpacityTarget(keybindsTabButton)

local keybindsTabCorner = Instance.new("UICorner")
keybindsTabCorner.CornerRadius = UDim.new(0, 10)
keybindsTabCorner.Parent = keybindsTabButton

local settingsTabButton = Instance.new("TextButton")
settingsTabButton.Size = UDim2.new(1/3, -7, 1, 0)
settingsTabButton.Position = UDim2.new(2/3, 6, 0, 0)
settingsTabButton.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
settingsTabButton.BorderSizePixel = 0
settingsTabButton.AutoButtonColor = false
settingsTabButton.Text = "Settings"
settingsTabButton.TextColor3 = Color3.fromRGB(205, 205, 205)
settingsTabButton.Font = Enum.Font.GothamBold
settingsTabButton.TextSize = 13
settingsTabButton.Parent = tabBar
addOpacityTarget(settingsTabButton)

local settingsTabCorner = Instance.new("UICorner")
settingsTabCorner.CornerRadius = UDim.new(0, 10)
settingsTabCorner.Parent = settingsTabButton

local contentHolder = Instance.new("Frame")
contentHolder.Size = UDim2.new(1, -24, 1, -140)
contentHolder.Position = UDim2.new(0, 12, 0, 136)
contentHolder.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
contentHolder.BorderSizePixel = 0
contentHolder.Parent = frame
addOpacityTarget(contentHolder)

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 12)
contentCorner.Parent = contentHolder

local scriptsPage = Instance.new("Frame")
scriptsPage.Name = "ScriptsPage"
scriptsPage.Size = UDim2.new(1, 0, 1, 0)
scriptsPage.BackgroundTransparency = 1
scriptsPage.Parent = contentHolder

local keybindsPage = Instance.new("Frame")
keybindsPage.Name = "KeybindsPage"
keybindsPage.Size = UDim2.new(1, 0, 1, 0)
keybindsPage.BackgroundTransparency = 1
keybindsPage.Visible = false
keybindsPage.Parent = contentHolder

local settingsPage = Instance.new("Frame")
settingsPage.Name = "SettingsPage"
settingsPage.Size = UDim2.new(1, 0, 1, 0)
settingsPage.BackgroundTransparency = 1
settingsPage.Visible = false
settingsPage.Parent = contentHolder

local function createSection(parent, height, order)
	local section = Instance.new("Frame")
	section.Size = UDim2.new(1, -2, 0, height)
	section.BackgroundColor3 = Color3.fromRGB(21, 21, 21)
	section.BorderSizePixel = 0
	section.LayoutOrder = order
	section.Parent = parent
	addOpacityTarget(section)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = section

	return section
end

local function createKeybindBox(parent, titleText, text, order, boxHeight, textBackHeight)
	local box = createSection(parent, boxHeight or 95, order)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 20)
	titleLabel.Position = UDim2.new(0, 10, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = titleText
	titleLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = box

	local textBack = Instance.new("Frame")
	textBack.Size = UDim2.new(1, -20, 0, textBackHeight or 53)
	textBack.Position = UDim2.new(0, 10, 0, 34)
	textBack.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	textBack.BorderSizePixel = 0
	textBack.Parent = box
	addOpacityTarget(textBack)

	local textBackCorner = Instance.new("UICorner")
	textBackCorner.CornerRadius = UDim.new(0, 10)
	textBackCorner.Parent = textBack

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -12, 1, -12)
	textLabel.Position = UDim2.new(0, 6, 0, 6)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text or ""
	textLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextSize = 13
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.Parent = textBack

	return box
end

local function styleButton(button, normalColor, hoverColor, pressColor)
	normalColor = normalColor or Color3.fromRGB(28, 28, 28)
	hoverColor = hoverColor or Color3.fromRGB(35, 35, 35)
	pressColor = pressColor or Color3.fromRGB(42, 42, 42)

	button.MouseEnter:Connect(function()
		tween(button, {BackgroundColor3 = hoverColor})
	end)

	button.MouseLeave:Connect(function()
		tween(button, {BackgroundColor3 = normalColor})
	end)

	button.MouseButton1Down:Connect(function()
		tween(button, {BackgroundColor3 = pressColor}, 0.06)
	end)

	button.MouseButton1Up:Connect(function()
		tween(button, {BackgroundColor3 = normalColor}, 0.08)
	end)
end

local scroller = Instance.new("ScrollingFrame")
scroller.Size = UDim2.new(1, -12, 1, -12)
scroller.Position = UDim2.new(0, 6, 0, 6)
scroller.BackgroundTransparency = 1
scroller.BorderSizePixel = 0
scroller.ScrollBarThickness = 3
scroller.ScrollBarImageColor3 = Color3.fromRGB(75, 75, 75)
scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
scroller.Parent = scriptsPage

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroller

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroller.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 2)
end)

local unloadButtonTop = Instance.new("TextButton")
unloadButtonTop.Size = UDim2.new(1, -2, 0, 42)
unloadButtonTop.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
unloadButtonTop.BorderSizePixel = 0
unloadButtonTop.AutoButtonColor = false
unloadButtonTop.Text = "Unload Active Scripts"
unloadButtonTop.TextColor3 = Color3.fromRGB(245, 245, 245)
unloadButtonTop.Font = Enum.Font.GothamBold
unloadButtonTop.TextSize = 14
unloadButtonTop.LayoutOrder = 0
unloadButtonTop.Parent = scroller
addOpacityTarget(unloadButtonTop)

local unloadTopCorner = Instance.new("UICorner")
unloadTopCorner.CornerRadius = UDim.new(0, 10)
unloadTopCorner.Parent = unloadButtonTop

styleButton(unloadButtonTop)
unloadButtonTop.MouseButton1Click:Connect(function()
	unloadActiveScripts()
end)

for i, scriptInfo in ipairs(scripts) do
	local row = Instance.new("Frame")
	row.Name = scriptInfo.Name
	row.Size = UDim2.new(1, -2, 0, 48)
	row.BackgroundTransparency = 1
	row.LayoutOrder = i
	row.Parent = scroller

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = scriptInfo.Name
	button.TextColor3 = Color3.fromRGB(245, 245, 245)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.Parent = row
	addOpacityTarget(button)

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 10)
	buttonCorner.Parent = button

	local killButton
	if scriptInfo.CanStop then
		killButton = Instance.new("TextButton")
		killButton.Size = UDim2.new(0, 26, 0, 26)
		killButton.AnchorPoint = Vector2.new(1, 0.5)
		killButton.Position = UDim2.new(1, -10, 0.5, 0)
		killButton.BackgroundColor3 = Color3.fromRGB(52, 52, 52)
		killButton.BorderSizePixel = 0
		killButton.AutoButtonColor = false
		killButton.Text = "X"
		killButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		killButton.Font = Enum.Font.GothamBold
		killButton.TextSize = 13
		killButton.Visible = false
		killButton.Parent = row
		addOpacityTarget(killButton)

		local killCorner = Instance.new("UICorner")
		killCorner.CornerRadius = UDim.new(0, 8)
		killCorner.Parent = killButton

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

	rowRefs[scriptInfo.Name] = {
		Button = button,
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
			tween(button, {BackgroundColor3 = Color3.fromRGB(28, 28, 28)}, 0.08)
		end
	end)

	button.MouseButton1Click:Connect(function()
		activateScript(scriptInfo)

		if scriptInfo.Name == "Infinite Yield" or scriptInfo.Name == "Dex Explorer(DONT CLICK)" then
			activeScripts[scriptInfo.Name] = nil
			rowRefs[scriptInfo.Name] = nil
			row:Destroy()
		end
	end)
end

local keybindsScroller = Instance.new("ScrollingFrame")
keybindsScroller.Size = UDim2.new(1, -12, 1, -12)
keybindsScroller.Position = UDim2.new(0, 6, 0, 6)
keybindsScroller.BackgroundTransparency = 1
keybindsScroller.BorderSizePixel = 0
keybindsScroller.ScrollBarThickness = 3
keybindsScroller.ScrollBarImageColor3 = Color3.fromRGB(75, 75, 75)
keybindsScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
keybindsScroller.Parent = keybindsPage

local keybindsLayout = Instance.new("UIListLayout")
keybindsLayout.Padding = UDim.new(0, 10)
keybindsLayout.SortOrder = Enum.SortOrder.LayoutOrder
keybindsLayout.Parent = keybindsScroller

keybindsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	keybindsScroller.CanvasSize = UDim2.new(0, 0, 0, keybindsLayout.AbsoluteContentSize.Y + 8)
end)

createKeybindBox(
	keybindsScroller,
	"Speedometer/FOV Keybinds",
	"• F = Increase Fov\n• T = Reset FOV",
	1,
	80,
	38
)

createKeybindBox(
	keybindsScroller,
	"Map Cycler Keybinds",
	"• M = Toggle Music\n• V = Toggle Sounds\n• Shift + N = Cycle Skyboxes/Maps",
	2
)

createKeybindBox(
	keybindsScroller,
	"Pallet Cycler Keybinds",
	"• P = Cycle Pallet Mode\n• Y = Despawn Toys\n• Shift + P = Reset Pallet Mode",
	3
)

createKeybindBox(
	keybindsScroller,
	"Freecam Keybinds",
	"• C = Toggle Freecam\n• Shift = Down In Freecam\n• Space = Up In Freecam\n• Middle Mouse = Reset Freecam Speed\n• Scroll Wheel = Increase/Decrease Freecam\n  Speed",
	4,
	134,
	90
)

createKeybindBox(
	keybindsScroller,
	"KBM Input Display Keybinds",
	"• B = Toggles UI\n• G = Cycles Control Buttons\n• Enter = Use Selected Control Button\n• Backspace = Deselects Control Button\n• Shift + B = Reset UI",
	5,
	124,
	78
)

local settingsScroller = Instance.new("ScrollingFrame")
settingsScroller.Size = UDim2.new(1, -12, 1, -12)
settingsScroller.Position = UDim2.new(0, 6, 0, 6)
settingsScroller.BackgroundTransparency = 1
settingsScroller.BorderSizePixel = 0
settingsScroller.ScrollBarThickness = 3
settingsScroller.ScrollBarImageColor3 = Color3.fromRGB(75, 75, 75)
settingsScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
settingsScroller.Parent = settingsPage

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.Padding = UDim.new(0, 10)
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Parent = settingsScroller

settingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	settingsScroller.CanvasSize = UDim2.new(0, 0, 0, settingsLayout.AbsoluteContentSize.Y + 8)
end)

local teleportSection = createSection(settingsScroller, 74, 1)

local rejoinButton = Instance.new("TextButton")
rejoinButton.Size = UDim2.new(0.5, -6, 0, 40)
rejoinButton.Position = UDim2.new(0, 10, 0, 17)
rejoinButton.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
rejoinButton.BorderSizePixel = 0
rejoinButton.AutoButtonColor = false
rejoinButton.Text = "Rejoin"
rejoinButton.TextColor3 = Color3.fromRGB(245, 245, 245)
rejoinButton.Font = Enum.Font.GothamBold
rejoinButton.TextSize = 14
rejoinButton.Parent = teleportSection
addOpacityTarget(rejoinButton)

local rejoinCorner = Instance.new("UICorner")
rejoinCorner.CornerRadius = UDim.new(0, 10)
rejoinCorner.Parent = rejoinButton

local hopButton = Instance.new("TextButton")
hopButton.Size = UDim2.new(0.5, -6, 0, 40)
hopButton.Position = UDim2.new(0.5, 0, 0, 17)
hopButton.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
hopButton.BorderSizePixel = 0
hopButton.AutoButtonColor = false
hopButton.Text = "Server Hop"
hopButton.TextColor3 = Color3.fromRGB(245, 245, 245)
hopButton.Font = Enum.Font.GothamBold
hopButton.TextSize = 14
hopButton.Parent = teleportSection
addOpacityTarget(hopButton)

local hopCorner = Instance.new("UICorner")
hopCorner.CornerRadius = UDim.new(0, 10)
hopCorner.Parent = hopButton

styleButton(rejoinButton)
styleButton(hopButton)

rejoinButton.MouseButton1Click:Connect(function()
	rejoinServer()
end)

hopButton.MouseButton1Click:Connect(function()
	serverHop()
end)

local reexecuteSection = createSection(settingsScroller, 72, 2)

local reexecuteTitle = Instance.new("TextLabel")
reexecuteTitle.Size = UDim2.new(1, -90, 0, 20)
reexecuteTitle.Position = UDim2.new(0, 12, 0, 25)
reexecuteTitle.BackgroundTransparency = 1
reexecuteTitle.Text = "Re-Execute On Teleport"
reexecuteTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
reexecuteTitle.Font = Enum.Font.GothamBold
reexecuteTitle.TextSize = 14
reexecuteTitle.TextXAlignment = Enum.TextXAlignment.Left
reexecuteTitle.Parent = reexecuteSection

local reexecuteToggle = Instance.new("TextButton")
reexecuteToggle.Size = UDim2.new(0, 58, 0, 30)
reexecuteToggle.Position = UDim2.new(1, -70, 0.5, -15)
reexecuteToggle.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
reexecuteToggle.BorderSizePixel = 0
reexecuteToggle.AutoButtonColor = false
reexecuteToggle.Text = ""
reexecuteToggle.Parent = reexecuteSection
addOpacityTarget(reexecuteToggle)

local reexecuteToggleCorner = Instance.new("UICorner")
reexecuteToggleCorner.CornerRadius = UDim.new(1, 0)
reexecuteToggleCorner.Parent = reexecuteToggle

local reexecuteKnob = Instance.new("Frame")
reexecuteKnob.Size = UDim2.new(0, 24, 0, 24)
reexecuteKnob.Position = UDim2.new(0, 3, 0, 3)
reexecuteKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
reexecuteKnob.BorderSizePixel = 0
reexecuteKnob.Parent = reexecuteToggle
addOpacityTarget(reexecuteKnob)

local reexecuteKnobCorner = Instance.new("UICorner")
reexecuteKnobCorner.CornerRadius = UDim.new(1, 0)
reexecuteKnobCorner.Parent = reexecuteKnob

local fpsSection = createSection(settingsScroller, 72, 3)

local fpsTitle = Instance.new("TextLabel")
fpsTitle.Size = UDim2.new(1, -90, 0, 20)
fpsTitle.Position = UDim2.new(0, 12, 0, 25)
fpsTitle.BackgroundTransparency = 1
fpsTitle.Text = "FPS Uncap"
fpsTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
fpsTitle.Font = Enum.Font.GothamBold
fpsTitle.TextSize = 14
fpsTitle.TextXAlignment = Enum.TextXAlignment.Left
fpsTitle.Parent = fpsSection

local fpsToggle = Instance.new("TextButton")
fpsToggle.Size = UDim2.new(0, 58, 0, 30)
fpsToggle.Position = UDim2.new(1, -70, 0.5, -15)
fpsToggle.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
fpsToggle.BorderSizePixel = 0
fpsToggle.AutoButtonColor = false
fpsToggle.Text = ""
fpsToggle.Parent = fpsSection
addOpacityTarget(fpsToggle)

local fpsToggleCorner = Instance.new("UICorner")
fpsToggleCorner.CornerRadius = UDim.new(1, 0)
fpsToggleCorner.Parent = fpsToggle

local fpsKnob = Instance.new("Frame")
fpsKnob.Size = UDim2.new(0, 24, 0, 24)
fpsKnob.Position = UDim2.new(0, 3, 0, 3)
fpsKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
fpsKnob.BorderSizePixel = 0
fpsKnob.Parent = fpsToggle
addOpacityTarget(fpsKnob)

local fpsKnobCorner = Instance.new("UICorner")
fpsKnobCorner.CornerRadius = UDim.new(1, 0)
fpsKnobCorner.Parent = fpsKnob

local fovSection = createSection(settingsScroller, 92, 4)

local fovTitle = Instance.new("TextLabel")
fovTitle.Size = UDim2.new(1, -20, 0, 20)
fovTitle.Position = UDim2.new(0, 12, 0, 10)
fovTitle.BackgroundTransparency = 1
fovTitle.Text = "FOV"
fovTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
fovTitle.Font = Enum.Font.GothamBold
fovTitle.TextSize = 14
fovTitle.TextXAlignment = Enum.TextXAlignment.Left
fovTitle.Parent = fovSection

local fovValueLabel = Instance.new("TextLabel")
fovValueLabel.Size = UDim2.new(0, 60, 0, 20)
fovValueLabel.Position = UDim2.new(1, -72, 0, 10)
fovValueLabel.BackgroundTransparency = 1
fovValueLabel.Text = tostring(targetFOV)
fovValueLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
fovValueLabel.Font = Enum.Font.GothamBold
fovValueLabel.TextSize = 13
fovValueLabel.TextXAlignment = Enum.TextXAlignment.Right
fovValueLabel.Parent = fovSection

local fovTrack = Instance.new("Frame")
fovTrack.Size = UDim2.new(1, -24, 0, 8)
fovTrack.Position = UDim2.new(0, 12, 0, 54)
fovTrack.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
fovTrack.BorderSizePixel = 0
fovTrack.Parent = fovSection
addOpacityTarget(fovTrack)

local fovTrackCorner = Instance.new("UICorner")
fovTrackCorner.CornerRadius = UDim.new(1, 0)
fovTrackCorner.Parent = fovTrack

local fovFill = Instance.new("Frame")
fovFill.Size = UDim2.new(0, 0, 1, 0)
fovFill.BackgroundColor3 = Color3.fromRGB(60, 125, 255)
fovFill.BorderSizePixel = 0
fovFill.Parent = fovTrack
addOpacityTarget(fovFill)

local fovFillCorner = Instance.new("UICorner")
fovFillCorner.CornerRadius = UDim.new(1, 0)
fovFillCorner.Parent = fovFill

local fovKnob = Instance.new("Frame")
fovKnob.Size = UDim2.new(0, 16, 0, 16)
fovKnob.AnchorPoint = Vector2.new(0.5, 0.5)
fovKnob.Position = UDim2.new(0, 0, 0.5, 0)
fovKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
fovKnob.BorderSizePixel = 0
fovKnob.Parent = fovTrack
addOpacityTarget(fovKnob)

local fovKnobCorner = Instance.new("UICorner")
fovKnobCorner.CornerRadius = UDim.new(1, 0)
fovKnobCorner.Parent = fovKnob

local opacitySection = createSection(settingsScroller, 92, 5)

local opacityTitle = Instance.new("TextLabel")
opacityTitle.Size = UDim2.new(1, -20, 0, 20)
opacityTitle.Position = UDim2.new(0, 12, 0, 10)
opacityTitle.BackgroundTransparency = 1
opacityTitle.Text = "Opacity"
opacityTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
opacityTitle.Font = Enum.Font.GothamBold
opacityTitle.TextSize = 14
opacityTitle.TextXAlignment = Enum.TextXAlignment.Left
opacityTitle.Parent = opacitySection

local opacityValueLabel = Instance.new("TextLabel")
opacityValueLabel.Size = UDim2.new(0, 60, 0, 20)
opacityValueLabel.Position = UDim2.new(1, -72, 0, 10)
opacityValueLabel.BackgroundTransparency = 1
opacityValueLabel.Text = tostring(menuOpacity) .. "%"
opacityValueLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
opacityValueLabel.Font = Enum.Font.GothamBold
opacityValueLabel.TextSize = 13
opacityValueLabel.TextXAlignment = Enum.TextXAlignment.Right
opacityValueLabel.Parent = opacitySection

local opacityTrack = Instance.new("Frame")
opacityTrack.Size = UDim2.new(1, -24, 0, 8)
opacityTrack.Position = UDim2.new(0, 12, 0, 54)
opacityTrack.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
opacityTrack.BorderSizePixel = 0
opacityTrack.Parent = opacitySection
addOpacityTarget(opacityTrack)

local opacityTrackCorner = Instance.new("UICorner")
opacityTrackCorner.CornerRadius = UDim.new(1, 0)
opacityTrackCorner.Parent = opacityTrack

local opacityFill = Instance.new("Frame")
opacityFill.Size = UDim2.new(0, 0, 1, 0)
opacityFill.BackgroundColor3 = Color3.fromRGB(60, 125, 255)
opacityFill.BorderSizePixel = 0
opacityFill.Parent = opacityTrack
addOpacityTarget(opacityFill)

local opacityFillCorner = Instance.new("UICorner")
opacityFillCorner.CornerRadius = UDim.new(1, 0)
opacityFillCorner.Parent = opacityFill

local opacityKnob = Instance.new("Frame")
opacityKnob.Size = UDim2.new(0, 16, 0, 16)
opacityKnob.AnchorPoint = Vector2.new(0.5, 0.5)
opacityKnob.Position = UDim2.new(0, 0, 0.5, 0)
opacityKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
opacityKnob.BorderSizePixel = 0
opacityKnob.Parent = opacityTrack
addOpacityTarget(opacityKnob)

local opacityKnobCorner = Instance.new("UICorner")
opacityKnobCorner.CornerRadius = UDim.new(1, 0)
opacityKnobCorner.Parent = opacityKnob

local commandSection = createSection(settingsScroller, 84, 6)

local commandTitle = Instance.new("TextLabel")
commandTitle.Size = UDim2.new(1, -20, 0, 20)
commandTitle.Position = UDim2.new(0, 12, 0, 10)
commandTitle.BackgroundTransparency = 1
commandTitle.Text = "Command Bar"
commandTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
commandTitle.Font = Enum.Font.GothamBold
commandTitle.TextSize = 14
commandTitle.TextXAlignment = Enum.TextXAlignment.Left
commandTitle.Parent = commandSection

local commandBox = Instance.new("TextBox")
commandBox.Size = UDim2.new(1, -24, 0, 38)
commandBox.Position = UDim2.new(0, 12, 0, 34)
commandBox.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
commandBox.BorderSizePixel = 0
commandBox.ClearTextOnFocus = false
commandBox.Text = commandText
commandBox.PlaceholderText = "Type command here"
commandBox.TextColor3 = Color3.fromRGB(245, 245, 245)
commandBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
commandBox.Font = Enum.Font.Gotham
commandBox.TextSize = 14
commandBox.TextXAlignment = Enum.TextXAlignment.Left
commandBox.Parent = commandSection
addOpacityTarget(commandBox)

local commandCorner = Instance.new("UICorner")
commandCorner.CornerRadius = UDim.new(0, 10)
commandCorner.Parent = commandBox

local function refreshReexecuteToggle()
	if reExecuteOnTeleport then
		reexecuteToggle.BackgroundColor3 = Color3.fromRGB(60, 125, 255)
		tween(reexecuteKnob, {Position = UDim2.new(0, 31, 0, 3)}, 0.12)
	else
		reexecuteToggle.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
		tween(reexecuteKnob, {Position = UDim2.new(0, 3, 0, 3)}, 0.12)
	end
end

local function refreshFpsToggle()
	if fpsUncapEnabled then
		fpsToggle.BackgroundColor3 = Color3.fromRGB(60, 125, 255)
		tween(fpsKnob, {Position = UDim2.new(0, 31, 0, 3)}, 0.12)
	else
		fpsToggle.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
		tween(fpsKnob, {Position = UDim2.new(0, 3, 0, 3)}, 0.12)
	end
end

local function setFovSliderVisual()
	local minValue, maxValue = 60, 120
	local alpha = math.clamp((targetFOV - minValue) / (maxValue - minValue), 0, 1)
	fovFill.Size = UDim2.new(alpha, 0, 1, 0)
	fovKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
	fovValueLabel.Text = tostring(math.floor(targetFOV + 0.5))
end

local function setOpacitySliderVisual()
	local minValue, maxValue = 20, 100
	local alpha = math.clamp((menuOpacity - minValue) / (maxValue - minValue), 0, 1)
	opacityFill.Size = UDim2.new(alpha, 0, 1, 0)
	opacityKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
	opacityValueLabel.Text = tostring(math.floor(menuOpacity + 0.5)) .. "%"
end

reexecuteToggle.MouseButton1Click:Connect(function()
	reExecuteOnTeleport = not reExecuteOnTeleport
	refreshReexecuteToggle()
end)

fpsToggle.MouseButton1Click:Connect(function()
	fpsUncapEnabled = not fpsUncapEnabled
	refreshFpsToggle()
	applyFpsCap()
end)

commandBox.FocusLost:Connect(function()
	commandText = commandBox.Text
end)

local draggingSlider = nil
local draggingWindow = false
local dragStart
local startPos

local function updateSliderFromInput(input)
	if not draggingSlider then
		return
	end

	local track = draggingSlider.Track
	local minValue = draggingSlider.Min
	local maxValue = draggingSlider.Max
	local setter = draggingSlider.Setter

	local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
	local value = minValue + ((maxValue - minValue) * alpha)

	if draggingSlider.Step then
		value = math.floor(value / draggingSlider.Step + 0.5) * draggingSlider.Step
	end

	setter(value)
end

local function beginSliderDrag(track, minValue, maxValue, setter, step, input)
	draggingSlider = {
		Track = track,
		Min = minValue,
		Max = maxValue,
		Setter = setter,
		Step = step
	}
	updateSliderFromInput(input)
end

fovTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		beginSliderDrag(fovTrack, 60, 120, function(value)
			targetFOV = math.clamp(math.floor(value + 0.5), 60, 120)
			camera.FieldOfView = targetFOV
			setFovSliderVisual()
		end, 1, input)
	end
end)

opacityTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		beginSliderDrag(opacityTrack, 20, 100, function(value)
			menuOpacity = math.clamp(math.floor(value + 0.5), 20, 100)
			setOpacitySliderVisual()
			applyMenuOpacity()
		end, 1, input)
	end
end)

local function refreshTabs()
	local isScripts = currentTab == "Scripts"
	local isKeybinds = currentTab == "Keybinds"
	local isSettings = currentTab == "Settings"

	scriptsPage.Visible = isScripts
	keybindsPage.Visible = isKeybinds
	settingsPage.Visible = isSettings

	scriptsTabButton.BackgroundColor3 = isScripts and Color3.fromRGB(32, 32, 32) or Color3.fromRGB(24, 24, 24)
	scriptsTabButton.TextColor3 = isScripts and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(205, 205, 205)

	keybindsTabButton.BackgroundColor3 = isKeybinds and Color3.fromRGB(32, 32, 32) or Color3.fromRGB(24, 24, 24)
	keybindsTabButton.TextColor3 = isKeybinds and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(205, 205, 205)

	settingsTabButton.BackgroundColor3 = isSettings and Color3.fromRGB(32, 32, 32) or Color3.fromRGB(24, 24, 24)
	settingsTabButton.TextColor3 = isSettings and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(205, 205, 205)
end

scriptsTabButton.MouseButton1Click:Connect(function()
	currentTab = "Scripts"
	refreshTabs()
end)

keybindsTabButton.MouseButton1Click:Connect(function()
	currentTab = "Keybinds"
	refreshTabs()
end)

settingsTabButton.MouseButton1Click:Connect(function()
	currentTab = "Settings"
	refreshTabs()
end)

local menuOpen = true
setMenuOpen(gui, true)
refreshTabs()
refreshReexecuteToggle()
refreshFpsToggle()
setFovSliderVisual()
setOpacitySliderVisual()
applyMenuOpacity()

local unlockMouseUntil = tick() + 3

closeButton.MouseEnter:Connect(function()
	tween(closeButton, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)})
end)

closeButton.MouseLeave:Connect(function()
	tween(closeButton, {BackgroundColor3 = Color3.fromRGB(42, 42, 42)})
end)

closeButton.MouseButton1Click:Connect(function()
	menuOpen = false
	setMenuOpen(gui, false)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.K and (
		UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or
		UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	) then
		menuOpen = not menuOpen
		setMenuOpen(gui, menuOpen)
		if menuOpen then
			unlockMouseUntil = tick() + 1
		end
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
		updateSliderFromInput(input)
	end

	if draggingWindow and input.UserInputType == Enum.UserInputType.MouseMovement then
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
		draggingSlider = nil
	end
end)

RunService.RenderStepped:Connect(function()
	if gui.Enabled or tick() < unlockMouseUntil then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end)

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingWindow = true
		dragStart = input.Position
		startPos = frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				draggingWindow = false
			end
		end)
	end
end)
