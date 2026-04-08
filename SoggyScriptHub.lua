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
local saveSettings = true
local targetFOV = math.floor(((camera and camera.FieldOfView) or 70) + 0.5)
local commandText = ""

local fpsCapOptions = {60, 120, 144, 180, 200, 240, 0}
local fpsCapLabels = {"60", "120", "144", "180", "200", "240", "240+"}
local fpsCapIndex = 1

local defaultFOV = math.floor(((camera and camera.FieldOfView) or 70) + 0.5)
local defaultFpsCapIndex = 1
local SETTINGS_FILE_NAME = "SoggyScriptHub_Settings.json"

local MENU_LOADSTRING_URL = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/SoggyScriptHub.lua"

local activeScripts = {}
local rowRefs = {}
local currentTab = "Scripts"

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

local function getReadFileFunction()
	return readfile
		or (syn and syn.readfile)
end

local function getWriteFileFunction()
	return writefile
		or (syn and syn.writefile)
end

local function getIsFileFunction()
	return isfile
		or (syn and syn.isfile)
end

local function getDeleteFileFunction()
	return delfile
		or (syn and syn.delfile)
end

local function saveSettingsToFile(fovValue, fpsIndexValue)
	local readFile = getReadFileFunction()
	local writeFile = getWriteFileFunction()
	local isFile = getIsFileFunction()

	if not writeFile or not isFile then
		return
	end

	local payload = {
		FOV = math.clamp(math.floor((fovValue or defaultFOV) + 0.5), 1, 120),
		FpsCapIndex = math.clamp(math.floor(fpsIndexValue or defaultFpsCapIndex), 1, #fpsCapOptions)
	}

	pcall(function()
		writeFile(SETTINGS_FILE_NAME, HttpService:JSONEncode(payload))
	end)
end

local function clearSavedSettingsFile()
	local deleteFile = getDeleteFileFunction()
	local isFile = getIsFileFunction()

	if deleteFile and isFile then
		local ok, exists = pcall(function()
			return isFile(SETTINGS_FILE_NAME)
		end)
		if ok and exists then
			pcall(function()
				deleteFile(SETTINGS_FILE_NAME)
			end)
		end
	end
end

local function loadSavedSettingsFromFile()
	local readFile = getReadFileFunction()
	local isFile = getIsFileFunction()

	if not readFile or not isFile then
		return
	end

	local ok, exists = pcall(function()
		return isFile(SETTINGS_FILE_NAME)
	end)
	if not ok or not exists then
		return
	end

	local okRead, contents = pcall(function()
		return readFile(SETTINGS_FILE_NAME)
	end)
	if not okRead or type(contents) ~= "string" or contents == "" then
		return
	end

	local okDecode, data = pcall(function()
		return HttpService:JSONDecode(contents)
	end)
	if not okDecode or type(data) ~= "table" then
		return
	end

	if type(data.FOV) == "number" then
		targetFOV = math.clamp(math.floor(data.FOV + 0.5), 1, 120)
	end

	if type(data.FpsCapIndex) == "number" then
		fpsCapIndex = math.clamp(math.floor(data.FpsCapIndex), 1, #fpsCapOptions)
	end
end

local function persistCurrentSettings()
	if saveSettings then
		saveSettingsToFile(targetFOV, fpsCapIndex)
	else
		clearSavedSettingsFile()
		saveSettingsToFile(defaultFOV, defaultFpsCapIndex)
	end
end

do
	local queued = getgenv and getgenv().__SoggyHubQueuedSettings
	if type(queued) == "table" then
		saveSettings = queued.SaveSettings ~= false

		if type(queued.FOV) == "number" then
			targetFOV = math.clamp(math.floor(queued.FOV + 0.5), 1, 120)
		end

		if type(queued.FpsCapIndex) == "number" then
			fpsCapIndex = math.clamp(math.floor(queued.FpsCapIndex), 1, #fpsCapOptions)
		end

		getgenv().__SoggyHubQueuedSettings = nil
	elseif saveSettings then
		loadSavedSettingsFromFile()
	end
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
	persistCurrentSettings()

	if reExecuteOnTeleport then
		local queuedFOV = saveSettings and targetFOV or defaultFOV
		local queuedFpsCapIndex = saveSettings and fpsCapIndex or defaultFpsCapIndex

		local source = string.format([[
getgenv().__SoggyHubQueuedSettings = {
	SaveSettings = %s,
	FOV = %d,
	FpsCapIndex = %d
}
loadstring(game:HttpGet("%s"))()
		]], tostring(saveSettings), queuedFOV, queuedFpsCapIndex, MENU_LOADSTRING_URL)

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

	local cap = fpsCapOptions[fpsCapIndex] or 60
	pcall(function()
		setCap(cap)
	end)
end

local function tween(obj, props, t)
	TweenService:Create(
		obj,
		TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props
	):Play()
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

local function setMenuOpen(guiObject, state)
	guiObject.Enabled = state
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

local function refreshAllRows()
	for scriptName in pairs(rowRefs) do
		refreshRow(scriptName)
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

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 14)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(42, 42, 42)
frameStroke.Thickness = 1.2
frameStroke.Transparency = 0.15
frameStroke.Parent = frame

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
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
closeButton.BorderSizePixel = 0
closeButton.AutoButtonColor = false
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
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

local scriptsTabCorner = Instance.new("UICorner")
scriptsTabCorner.CornerRadius = UDim.new(0, 10)
scriptsTabCorner.Parent = scriptsTabButton

local settingsTabButton = Instance.new("TextButton")
settingsTabButton.Size = UDim2.new(1/3, -7, 1, 0)
settingsTabButton.Position = UDim2.new(1/3, 3, 0, 0)
settingsTabButton.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
settingsTabButton.BorderSizePixel = 0
settingsTabButton.AutoButtonColor = false
settingsTabButton.Text = "Settings"
settingsTabButton.TextColor3 = Color3.fromRGB(205, 205, 205)
settingsTabButton.Font = Enum.Font.GothamBold
settingsTabButton.TextSize = 13
settingsTabButton.Parent = tabBar

local settingsTabCorner = Instance.new("UICorner")
settingsTabCorner.CornerRadius = UDim.new(0, 10)
settingsTabCorner.Parent = settingsTabButton

local keybindsTabButton = Instance.new("TextButton")
keybindsTabButton.Size = UDim2.new(1/3, -7, 1, 0)
keybindsTabButton.Position = UDim2.new(2/3, 6, 0, 0)
keybindsTabButton.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
keybindsTabButton.BorderSizePixel = 0
keybindsTabButton.AutoButtonColor = false
keybindsTabButton.Text = "Keys/Cmd"
keybindsTabButton.TextColor3 = Color3.fromRGB(205, 205, 205)
keybindsTabButton.Font = Enum.Font.GothamBold
keybindsTabButton.TextSize = 13
keybindsTabButton.Parent = tabBar

local keybindsTabCorner = Instance.new("UICorner")
keybindsTabCorner.CornerRadius = UDim.new(0, 10)
keybindsTabCorner.Parent = keybindsTabButton

local contentHolder = Instance.new("Frame")
contentHolder.Size = UDim2.new(1, -24, 1, -140)
contentHolder.Position = UDim2.new(0, 12, 0, 136)
contentHolder.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
contentHolder.BorderSizePixel = 0
contentHolder.Parent = frame

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

local unloadTopCorner = Instance.new("UICorner")
unloadTopCorner.CornerRadius = UDim.new(0, 10)
unloadTopCorner.Parent = unloadButtonTop

styleButton(unloadButtonTop)
unloadButtonTop.MouseButton1Click:Connect(function()
	unloadActiveScripts()
end)

local separatorHolder = Instance.new("Frame")
separatorHolder.Size = UDim2.new(1, -2, 0, 14)
separatorHolder.BackgroundTransparency = 1
separatorHolder.LayoutOrder = 1
separatorHolder.Parent = scroller

local separatorLine = Instance.new("Frame")
separatorLine.AnchorPoint = Vector2.new(0.5, 0.5)
separatorLine.Position = UDim2.new(0.5, 0, 0.5, 0)
separatorLine.Size = UDim2.new(1, -18, 0, 1)
separatorLine.BackgroundColor3 = Color3.fromRGB(58, 58, 58)
separatorLine.BorderSizePixel = 0
separatorLine.Parent = separatorHolder

for i, scriptInfo in ipairs(scripts) do
	local row = Instance.new("Frame")
	row.Name = scriptInfo.Name
	row.Size = UDim2.new(1, -2, 0, 48)
	row.BackgroundTransparency = 1
	row.LayoutOrder = i + 1
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
	"• C = Toggle Freecam\n• Shift = Down In Freecam\n• Space = Up In Freecam\n• Middle Mouse = Reset Freecam Speed\n• Scroll Wheel = Increase/Decrease Freecam Speed",
	4,
	124,
	78
)

createKeybindBox(
	keybindsScroller,
	"KBM Input Display Keybinds",
	"• B = Toggles UI\n• G = Cycles Control Buttons\n• Enter = Use Selected Control Button\n• Backspace = Deselects Control Button\n• Shift + B = Reset UI",
	5,
	124,
	78
)

local keybindsSeparatorHolder = Instance.new("Frame")
keybindsSeparatorHolder.Size = UDim2.new(1, -2, 0, 14)
keybindsSeparatorHolder.BackgroundTransparency = 1
keybindsSeparatorHolder.LayoutOrder = 6
keybindsSeparatorHolder.Parent = keybindsScroller

local keybindsSeparatorLine = Instance.new("Frame")
keybindsSeparatorLine.AnchorPoint = Vector2.new(0.5, 0.5)
keybindsSeparatorLine.Position = UDim2.new(0.5, 0, 0.5, 0)
keybindsSeparatorLine.Size = UDim2.new(1, -18, 0, 1)
keybindsSeparatorLine.BackgroundColor3 = Color3.fromRGB(58, 58, 58)
keybindsSeparatorLine.BorderSizePixel = 0
keybindsSeparatorLine.Parent = keybindsSeparatorHolder

createKeybindBox(
	keybindsScroller,
	"Commands - All Commands Start With ;",
	"•  goto /  tp [player]\n•  esp /  locate [player/@all]\n•  unesp /  unlocate [player/@all]\n•  fly [speed]\n•  unfly\n•  view /  lookat [player]\n•  unview /  unlookat\n•  run /  load [script]\n•  unrun /  unload [script/@all]\n•  reload /  rerun [script/@all]\n•  rj /  rejoin\n•  serverhop\n•  respawn /  reset\n•  noclip /  unnoclip",
	7,
	250,
	200
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
settingsLayout.Padding = UDim.new(0, 8)
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Parent = settingsScroller

settingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	settingsScroller.CanvasSize = UDim2.new(0, 0, 0, settingsLayout.AbsoluteContentSize.Y + 8)
end)

local teleportSection = createSection(settingsScroller, 62, 1)

local rejoinButton = Instance.new("TextButton")
rejoinButton.Size = UDim2.new(0.5, -16, 0, 34)
rejoinButton.Position = UDim2.new(0, 10, 0, 14)
rejoinButton.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
rejoinButton.BorderSizePixel = 0
rejoinButton.AutoButtonColor = false
rejoinButton.Text = "Rejoin"
rejoinButton.TextColor3 = Color3.fromRGB(245, 245, 245)
rejoinButton.Font = Enum.Font.GothamBold
rejoinButton.TextSize = 14
rejoinButton.Parent = teleportSection

local rejoinCorner = Instance.new("UICorner")
rejoinCorner.CornerRadius = UDim.new(0, 10)
rejoinCorner.Parent = rejoinButton

local hopButton = Instance.new("TextButton")
hopButton.Size = UDim2.new(0.5, -16, 0, 34)
hopButton.Position = UDim2.new(0.5, 6, 0, 14)
hopButton.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
hopButton.BorderSizePixel = 0
hopButton.AutoButtonColor = false
hopButton.Text = "Server Hop"
hopButton.TextColor3 = Color3.fromRGB(245, 245, 245)
hopButton.Font = Enum.Font.GothamBold
hopButton.TextSize = 14
hopButton.Parent = teleportSection

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

local reexecuteSection = createSection(settingsScroller, 58, 2)

local reexecuteTitle = Instance.new("TextLabel")
reexecuteTitle.Size = UDim2.new(1, -90, 0, 20)
reexecuteTitle.Position = UDim2.new(0, 12, 0, 19)
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

local reexecuteToggleCorner = Instance.new("UICorner")
reexecuteToggleCorner.CornerRadius = UDim.new(1, 0)
reexecuteToggleCorner.Parent = reexecuteToggle

local reexecuteKnob = Instance.new("Frame")
reexecuteKnob.Size = UDim2.new(0, 24, 0, 24)
reexecuteKnob.Position = UDim2.new(0, 3, 0, 3)
reexecuteKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
reexecuteKnob.BorderSizePixel = 0
reexecuteKnob.Parent = reexecuteToggle

local reexecuteKnobCorner = Instance.new("UICorner")
reexecuteKnobCorner.CornerRadius = UDim.new(1, 0)
reexecuteKnobCorner.Parent = reexecuteKnob

local saveSettingsSection = createSection(settingsScroller, 58, 3)

local saveSettingsTitle = Instance.new("TextLabel")
saveSettingsTitle.Size = UDim2.new(1, -90, 0, 20)
saveSettingsTitle.Position = UDim2.new(0, 12, 0, 19)
saveSettingsTitle.BackgroundTransparency = 1
saveSettingsTitle.Text = "Save Settings"
saveSettingsTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
saveSettingsTitle.Font = Enum.Font.GothamBold
saveSettingsTitle.TextSize = 14
saveSettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
saveSettingsTitle.Parent = saveSettingsSection

local saveSettingsToggle = Instance.new("TextButton")
saveSettingsToggle.Size = UDim2.new(0, 58, 0, 30)
saveSettingsToggle.Position = UDim2.new(1, -70, 0.5, -15)
saveSettingsToggle.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
saveSettingsToggle.BorderSizePixel = 0
saveSettingsToggle.AutoButtonColor = false
saveSettingsToggle.Text = ""
saveSettingsToggle.Parent = saveSettingsSection

local saveSettingsToggleCorner = Instance.new("UICorner")
saveSettingsToggleCorner.CornerRadius = UDim.new(1, 0)
saveSettingsToggleCorner.Parent = saveSettingsToggle

local saveSettingsKnob = Instance.new("Frame")
saveSettingsKnob.Size = UDim2.new(0, 24, 0, 24)
saveSettingsKnob.Position = UDim2.new(0, 3, 0, 3)
saveSettingsKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
saveSettingsKnob.BorderSizePixel = 0
saveSettingsKnob.Parent = saveSettingsToggle

local saveSettingsKnobCorner = Instance.new("UICorner")
saveSettingsKnobCorner.CornerRadius = UDim.new(1, 0)
saveSettingsKnobCorner.Parent = saveSettingsKnob

local fpsSection = createSection(settingsScroller, 74, 4)

local fpsTitle = Instance.new("TextLabel")
fpsTitle.Size = UDim2.new(1, -20, 0, 20)
fpsTitle.Position = UDim2.new(0, 12, 0, 10)
fpsTitle.BackgroundTransparency = 1
fpsTitle.Text = "FPS Cap"
fpsTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
fpsTitle.Font = Enum.Font.GothamBold
fpsTitle.TextSize = 14
fpsTitle.TextXAlignment = Enum.TextXAlignment.Left
fpsTitle.Parent = fpsSection

local fpsValueLabel = Instance.new("TextLabel")
fpsValueLabel.Size = UDim2.new(0, 70, 0, 20)
fpsValueLabel.Position = UDim2.new(1, -82, 0, 10)
fpsValueLabel.BackgroundTransparency = 1
fpsValueLabel.Text = fpsCapLabels[fpsCapIndex]
fpsValueLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
fpsValueLabel.Font = Enum.Font.GothamBold
fpsValueLabel.TextSize = 13
fpsValueLabel.TextXAlignment = Enum.TextXAlignment.Right
fpsValueLabel.Parent = fpsSection

local fpsTrack = Instance.new("Frame")
fpsTrack.Size = UDim2.new(1, -24, 0, 8)
fpsTrack.Position = UDim2.new(0, 12, 0, 46)
fpsTrack.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
fpsTrack.BorderSizePixel = 0
fpsTrack.Parent = fpsSection

local fpsTrackCorner = Instance.new("UICorner")
fpsTrackCorner.CornerRadius = UDim.new(1, 0)
fpsTrackCorner.Parent = fpsTrack

local fpsFill = Instance.new("Frame")
fpsFill.Size = UDim2.new(0, 0, 1, 0)
fpsFill.BackgroundColor3 = Color3.fromRGB(60, 125, 255)
fpsFill.BorderSizePixel = 0
fpsFill.Parent = fpsTrack

local fpsFillCorner = Instance.new("UICorner")
fpsFillCorner.CornerRadius = UDim.new(1, 0)
fpsFillCorner.Parent = fpsFill

local fpsKnob = Instance.new("Frame")
fpsKnob.Size = UDim2.new(0, 16, 0, 16)
fpsKnob.AnchorPoint = Vector2.new(0.5, 0.5)
fpsKnob.Position = UDim2.new(0, 0, 0.5, 0)
fpsKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
fpsKnob.BorderSizePixel = 0
fpsKnob.Parent = fpsTrack

local fpsKnobCorner = Instance.new("UICorner")
fpsKnobCorner.CornerRadius = UDim.new(1, 0)
fpsKnobCorner.Parent = fpsKnob

local fpsKnobHitbox = Instance.new("TextButton")
fpsKnobHitbox.Size = UDim2.new(0, 30, 0, 30)
fpsKnobHitbox.AnchorPoint = Vector2.new(0.5, 0.5)
fpsKnobHitbox.Position = fpsKnob.Position
fpsKnobHitbox.BackgroundTransparency = 1
fpsKnobHitbox.BorderSizePixel = 0
fpsKnobHitbox.Text = ""
fpsKnobHitbox.AutoButtonColor = false
fpsKnobHitbox.Parent = fpsTrack

local fovSection = createSection(settingsScroller, 74, 5)

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
fovTrack.Position = UDim2.new(0, 12, 0, 46)
fovTrack.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
fovTrack.BorderSizePixel = 0
fovTrack.Parent = fovSection

local fovTrackCorner = Instance.new("UICorner")
fovTrackCorner.CornerRadius = UDim.new(1, 0)
fovTrackCorner.Parent = fovTrack

local fovFill = Instance.new("Frame")
fovFill.Size = UDim2.new(0, 0, 1, 0)
fovFill.BackgroundColor3 = Color3.fromRGB(60, 125, 255)
fovFill.BorderSizePixel = 0
fovFill.Parent = fovTrack

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

local fovKnobCorner = Instance.new("UICorner")
fovKnobCorner.CornerRadius = UDim.new(1, 0)
fovKnobCorner.Parent = fovKnob

local fovKnobHitbox = Instance.new("TextButton")
fovKnobHitbox.Size = UDim2.new(0, 30, 0, 30)
fovKnobHitbox.AnchorPoint = Vector2.new(0.5, 0.5)
fovKnobHitbox.Position = fovKnob.Position
fovKnobHitbox.BackgroundTransparency = 1
fovKnobHitbox.BorderSizePixel = 0
fovKnobHitbox.Text = ""
fovKnobHitbox.AutoButtonColor = false
fovKnobHitbox.Parent = fovTrack

local commandSection = createSection(settingsScroller, 68, 6)

local commandTitle = Instance.new("TextLabel")
commandTitle.Size = UDim2.new(1, -20, 0, 20)
commandTitle.Position = UDim2.new(0, 12, 0, 8)
commandTitle.BackgroundTransparency = 1
commandTitle.Text = "Command Bar"
commandTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
commandTitle.Font = Enum.Font.GothamBold
commandTitle.TextSize = 14
commandTitle.TextXAlignment = Enum.TextXAlignment.Left
commandTitle.Parent = commandSection

local commandBox = Instance.new("TextBox")
commandBox.Size = UDim2.new(1, -24, 0, 32)
commandBox.Position = UDim2.new(0, 12, 0, 28)
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

local commandCorner = Instance.new("UICorner")
commandCorner.CornerRadius = UDim.new(0, 10)
commandCorner.Parent = commandBox

local function refreshReexecuteToggle()
	if reExecuteOnTeleport then
		reexecuteToggle.BackgroundColor3 = Color3.fromRGB(60, 125, 255)
		reexecuteKnob.Position = UDim2.new(0, 31, 0, 3)
	else
		reexecuteToggle.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
		reexecuteKnob.Position = UDim2.new(0, 3, 0, 3)
	end
end

local function refreshSaveSettingsToggle()
	if saveSettings then
		saveSettingsToggle.BackgroundColor3 = Color3.fromRGB(60, 125, 255)
		saveSettingsKnob.Position = UDim2.new(0, 31, 0, 3)
	else
		saveSettingsToggle.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
		saveSettingsKnob.Position = UDim2.new(0, 3, 0, 3)
	end
end

local function setFpsSliderVisual()
	local count = #fpsCapOptions
	local alpha = 0
	if count > 1 then
		alpha = (fpsCapIndex - 1) / (count - 1)
	end
	fpsFill.Size = UDim2.new(alpha, 0, 1, 0)
	fpsKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
	fpsKnobHitbox.Position = fpsKnob.Position
	fpsValueLabel.Text = fpsCapLabels[fpsCapIndex]
end

local function setFovSliderVisual()
	local minValue, maxValue = 1, 120
	local alpha = math.clamp((targetFOV - minValue) / (maxValue - minValue), 0, 1)
	fovFill.Size = UDim2.new(alpha, 0, 1, 0)
	fovKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
	fovKnobHitbox.Position = fovKnob.Position
	fovValueLabel.Text = tostring(math.floor(targetFOV + 0.5))
end

reexecuteToggle.MouseButton1Click:Connect(function()
	reExecuteOnTeleport = not reExecuteOnTeleport
	refreshReexecuteToggle()
end)

saveSettingsToggle.MouseButton1Click:Connect(function()
	saveSettings = not saveSettings
	refreshSaveSettingsToggle()
	persistCurrentSettings()
end)

local commandStatusResetToken = 0

local function setCommandStatus(message)
	commandStatusResetToken += 1
	local myToken = commandStatusResetToken
	commandTitle.Text = message and ("Command Bar - " .. tostring(message)) or "Command Bar"
	task.delay(2.5, function()
		if commandStatusResetToken == myToken and commandTitle then
			commandTitle.Text = "Command Bar"
		end
	end)
end

local draggingSlider = nil
local draggingWindow = false
local dragStart
local startPos

local function updateSliderFromInput(input)
	if not draggingSlider then
		return
	end

	local track = draggingSlider.Track
	local setter = draggingSlider.Setter
	local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
	setter(alpha)
end

local function beginSliderDrag(track, setter, input)
	draggingSlider = {
		Track = track,
		Setter = setter
	}
	updateSliderFromInput(input)
end

fpsTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		beginSliderDrag(fpsTrack, function(alpha)
			local count = #fpsCapOptions
			local index = math.clamp(math.floor(alpha * (count - 1) + 0.5) + 1, 1, count)
			fpsCapIndex = index
			setFpsSliderVisual()
			applyFpsCap()
			if saveSettings then
				saveSettingsToFile(targetFOV, fpsCapIndex)
			end
			if saveSettings then
				saveSettingsToFile(targetFOV, fpsCapIndex)
			end
		end, input)
	end
end)

fpsKnobHitbox.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		beginSliderDrag(fpsTrack, function(alpha)
			local count = #fpsCapOptions
			local index = math.clamp(math.floor(alpha * (count - 1) + 0.5) + 1, 1, count)
			fpsCapIndex = index
			setFpsSliderVisual()
			applyFpsCap()
		end, input)
	end
end)

fovTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		beginSliderDrag(fovTrack, function(alpha)
			local value = 1 + ((120 - 1) * alpha)
			targetFOV = math.clamp(math.floor(value + 0.5), 1, 120)
			camera.FieldOfView = targetFOV
			setFovSliderVisual()
			if saveSettings then
				saveSettingsToFile(targetFOV, fpsCapIndex)
			end
			if saveSettings then
				saveSettingsToFile(targetFOV, fpsCapIndex)
			end
		end, input)
	end
end)

fovKnobHitbox.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		beginSliderDrag(fovTrack, function(alpha)
			local value = 1 + ((120 - 1) * alpha)
			targetFOV = math.clamp(math.floor(value + 0.5), 1, 120)
			camera.FieldOfView = targetFOV
			setFovSliderVisual()
		end, input)
	end
end)

local espObjects = {}
local trackedEspPlayers = {}
local allEspEnabled = false
local allEspPlayerAddedConnection
local allEspCharacterConnections = {}

local flyState = {
	Enabled = false,
	Speed = 20,
	BodyVelocity = nil,
	BodyGyro = nil,
	RenderConnection = nil,
	CharacterConnection = nil
}

local viewState = {
	Target = nil
}

local noclipState = {
	Enabled = false,
	Connection = nil
}

local function normalizeString(value)
	return string.lower(tostring(value or ""))
end

local function splitWords(textValue)
	local words = {}
	for word in string.gmatch(tostring(textValue or ""), "%S+") do
		table.insert(words, word)
	end
	return words
end

local function getCharacterParts(targetPlayer)
	if not targetPlayer then
		return nil, nil, nil
	end
	local character = targetPlayer.Character
	if not character then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

local function getUniquePlayerMatch(query)
	local search = normalizeString(query)
	if search == "" then
		return nil, "missing name"
	end

	local exactMatches = {}
	local prefixMatches = {}

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		local username = normalizeString(otherPlayer.Name)
		local displayName = normalizeString(otherPlayer.DisplayName)

		if username == search or displayName == search then
			table.insert(exactMatches, otherPlayer)
		elseif string.sub(username, 1, #search) == search or string.sub(displayName, 1, #search) == search then
			table.insert(prefixMatches, otherPlayer)
		end
	end

	if #exactMatches == 1 then
		return exactMatches[1]
	end

	if #exactMatches > 1 then
		return nil, "name mismatch"
	end

	if #prefixMatches == 1 then
		return prefixMatches[1]
	end

	if #prefixMatches > 1 then
		return nil, "name mismatch"
	end

	return nil, "player not found"
end

local function clearEspForPlayer(targetPlayer)
	if not targetPlayer then
		return
	end

	trackedEspPlayers[targetPlayer.UserId] = nil

	local existing = espObjects[targetPlayer.UserId]
	if existing then
		if existing.Connection then
			existing.Connection:Disconnect()
		end
		if existing.Highlight then
			existing.Highlight:Destroy()
		end
		if existing.Billboard then
			existing.Billboard:Destroy()
		end
		espObjects[targetPlayer.UserId] = nil
	end
end

local function buildEspForCharacter(targetPlayer, character)
	if not targetPlayer or not character then
		return
	end

	clearEspForPlayer(targetPlayer)
	trackedEspPlayers[targetPlayer.UserId] = true

	local adornPart = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	if not adornPart then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "SoggyCommandESP"
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.Parent = gui

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SoggyCommandESPLabel"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 220, 0, 46)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.Adornee = adornPart
	billboard.Parent = gui

	local displayLabel = Instance.new("TextLabel")
	displayLabel.Size = UDim2.new(1, 0, 0, 22)
	displayLabel.Position = UDim2.new(0, 0, 0, 0)
	displayLabel.BackgroundTransparency = 1
	displayLabel.Text = targetPlayer.DisplayName
	displayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	displayLabel.TextStrokeTransparency = 0.5
	displayLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	displayLabel.Font = Enum.Font.GothamBold
	displayLabel.TextSize = 14
	displayLabel.Parent = billboard

	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Size = UDim2.new(1, 0, 0, 18)
	usernameLabel.Position = UDim2.new(0, 0, 0, 20)
	usernameLabel.BackgroundTransparency = 1
	usernameLabel.Text = "@" .. targetPlayer.Name
	usernameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	usernameLabel.TextStrokeTransparency = 0.5
	usernameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	usernameLabel.Font = Enum.Font.Gotham
	usernameLabel.TextSize = 11
	usernameLabel.Parent = billboard

	local connection = targetPlayer.CharacterAdded:Connect(function(newCharacter)
		task.wait(0.15)
		if trackedEspPlayers[targetPlayer.UserId] then
			buildEspForCharacter(targetPlayer, newCharacter)
		end
	end)

	espObjects[targetPlayer.UserId] = {
		Highlight = highlight,
		Billboard = billboard,
		Connection = connection
	}
end

local function applyEspToPlayer(targetPlayer)
	if not targetPlayer then
		return false, "player not found"
	end

	local character = targetPlayer.Character
	if not character then
		return false, "character not found"
	end

	buildEspForCharacter(targetPlayer, character)
	return true
end

local function applyEspToAllPlayers()
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			applyEspToPlayer(otherPlayer)
		end
	end
end

local function clearAllEsp()
	allEspEnabled = false

	if allEspPlayerAddedConnection then
		allEspPlayerAddedConnection:Disconnect()
		allEspPlayerAddedConnection = nil
	end

	for userId, connection in pairs(allEspCharacterConnections) do
		if connection then
			connection:Disconnect()
		end
		allEspCharacterConnections[userId] = nil
	end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		clearEspForPlayer(otherPlayer)
	end
end

local function enableEspForAllFuturePlayers()
	if allEspPlayerAddedConnection then
		allEspPlayerAddedConnection:Disconnect()
	end

	allEspPlayerAddedConnection = Players.PlayerAdded:Connect(function(otherPlayer)
		allEspCharacterConnections[otherPlayer.UserId] = otherPlayer.CharacterAdded:Connect(function()
			if allEspEnabled and otherPlayer ~= player then
				task.wait(0.15)
				applyEspToPlayer(otherPlayer)
			end
		end)

		if allEspEnabled and otherPlayer ~= player and otherPlayer.Character then
			task.defer(function()
				applyEspToPlayer(otherPlayer)
			end)
		end
	end)

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if allEspCharacterConnections[otherPlayer.UserId] then
			allEspCharacterConnections[otherPlayer.UserId]:Disconnect()
		end
		allEspCharacterConnections[otherPlayer.UserId] = otherPlayer.CharacterAdded:Connect(function()
			if allEspEnabled and otherPlayer ~= player then
				task.wait(0.15)
				applyEspToPlayer(otherPlayer)
			end
		end)
	end
end

local function stopFly()
	if flyState.RenderConnection then
		flyState.RenderConnection:Disconnect()
		flyState.RenderConnection = nil
	end

	if flyState.CharacterConnection then
		flyState.CharacterConnection:Disconnect()
		flyState.CharacterConnection = nil
	end

	if flyState.BodyVelocity then
		flyState.BodyVelocity:Destroy()
		flyState.BodyVelocity = nil
	end

	if flyState.BodyGyro then
		flyState.BodyGyro:Destroy()
		flyState.BodyGyro = nil
	end

	local _, humanoid, root = getCharacterParts(player)
	if humanoid then
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
	end

	flyState.Enabled = false
end

local function startFly(speed)
	stopFly()

	local character, humanoid, root = getCharacterParts(player)
	if not character or not humanoid or not root then
		return false, "character not ready"
	end

	flyState.Enabled = true
	flyState.Speed = tonumber(speed) or 20

	humanoid.PlatformStand = true

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = root

	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bodyGyro.P = 1e5
	bodyGyro.CFrame = camera.CFrame
	bodyGyro.Parent = root

	flyState.BodyVelocity = bodyVelocity
	flyState.BodyGyro = bodyGyro

	flyState.CharacterConnection = player.CharacterAdded:Connect(function()
		stopFly()
	end)

	flyState.RenderConnection = RunService.RenderStepped:Connect(function()
		if not flyState.Enabled then
			return
		end

		local _, currentHumanoid, currentRoot = getCharacterParts(player)
		if not currentHumanoid or not currentRoot or not flyState.BodyVelocity or not flyState.BodyGyro then
			return
		end

		local moveVector = Vector3.zero
		local camFrame = camera.CFrame
		local forward = camFrame.LookVector
		local right = camFrame.RightVector

		local flatForward = Vector3.new(forward.X, 0, forward.Z)
		local flatRight = Vector3.new(right.X, 0, right.Z)

		if flatForward.Magnitude > 0 then
			flatForward = flatForward.Unit
		end
		if flatRight.Magnitude > 0 then
			flatRight = flatRight.Unit
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveVector += flatForward
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveVector -= flatForward
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveVector += flatRight
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveVector -= flatRight
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			moveVector += Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
			moveVector -= Vector3.new(0, 1, 0)
		end

		if moveVector.Magnitude > 0 then
			moveVector = moveVector.Unit * flyState.Speed
		end

		flyState.BodyVelocity.Velocity = moveVector
		flyState.BodyGyro.CFrame = camera.CFrame
	end)

	return true
end


local function resetView()
	viewState.Target = nil
	local character, humanoid = getCharacterParts(player)
	if humanoid then
		camera.CameraSubject = humanoid
	end
	camera.CameraType = Enum.CameraType.Custom
end

local function setViewTarget(targetPlayer)
	if not targetPlayer then
		return false, "player not found"
	end

	local _, humanoid = getCharacterParts(targetPlayer)
	if not humanoid then
		return false, "character not ready"
	end

	viewState.Target = targetPlayer
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid
	return true
end

local function stopNoclip()
	noclipState.Enabled = false
	if noclipState.Connection then
		noclipState.Connection:Disconnect()
		noclipState.Connection = nil
	end
end

local function startNoclip()
	stopNoclip()
	noclipState.Enabled = true
	noclipState.Connection = RunService.Stepped:Connect(function()
		if not noclipState.Enabled then
			return
		end
		local character = player.Character
		if not character then
			return
		end
		for _, obj in ipairs(character:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.CanCollide = false
			end
		end
	end)
end

local function reloadScript(scriptInfo)
	if not scriptInfo then
		return false, "script not found"
	end
	if not scriptInfo.CanStop then
		return false, "script can't reload"
	end
	if activeScripts[scriptInfo.Name] then
		deactivateScript(scriptInfo)
		task.wait()
	end
	activateScript(scriptInfo)
	return true, "reload " .. scriptInfo.Name
end

local scriptLookup = {
	speedometer = "Speedometer/FOV",
	speed = "Speedometer/FOV",
	mapcycler = "Skybox/Map Cycler(WIP)",
	map = "Skybox/Map Cycler(WIP)",
	palletcycler = "Pallet Cycler",
	pallet = "Pallet Cycler",
	freecam = "Freecam",
	free = "Freecam",
	cam = "Freecam",
	kbm = "KBMInputDisplay",
	keyboard = "KBMInputDisplay",
	key = "KBMInputDisplay",
	infyield = "Infinite Yield",
	iy = "Infinite Yield",
	inf = "Infinite Yield",
	infiniteyield = "Infinite Yield",
	dex = "Dex Explorer(DONT CLICK)",
	dexexplorer = "Dex Explorer(DONT CLICK)",
	dexex = "Dex Explorer(DONT CLICK)"
}

local function findScriptInfoByName(name)
	local search = normalizeString(name)
	if search == "" then
		return nil, "missing script"
	end

	if scriptLookup[search] then
		for _, scriptInfo in ipairs(scripts) do
			if scriptInfo.Name == scriptLookup[search] then
				return scriptInfo
			end
		end
	end

	local matches = {}
	for alias, mappedName in pairs(scriptLookup) do
		if string.sub(alias, 1, #search) == search then
			matches[mappedName] = true
		end
	end

	local matchList = {}
	for mappedName in pairs(matches) do
		table.insert(matchList, mappedName)
	end

	if #matchList == 1 then
		for _, scriptInfo in ipairs(scripts) do
			if scriptInfo.Name == matchList[1] then
				return scriptInfo
			end
		end
	elseif #matchList > 1 then
		return nil, "script mismatch"
	end

	return nil, "script not found"
end

local function runCommand(rawText)
	local trimmed = tostring(rawText or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then
		return false, "empty command"
	end

	if string.sub(trimmed, 1, 1) ~= ";" then
		return false, "missing ;"
	end

	trimmed = string.sub(trimmed, 2)
	trimmed = tostring(trimmed or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then
		return false, "empty command"
	end

	local words = splitWords(trimmed)
	local action = normalizeString(words[1] or "")
	local argument = ""
	if #words >= 2 then
		argument = table.concat(words, " ", 2)
	end

	if action == "goto" or action == "tp" then
		local targetPlayer, err = getUniquePlayerMatch(argument)
		if not targetPlayer then
			return false, err
		end

		local _, _, localRoot = getCharacterParts(player)
		local _, _, targetRoot = getCharacterParts(targetPlayer)
		if not localRoot or not targetRoot then
			return false, "character not ready"
		end

		localRoot.CFrame = targetRoot.CFrame + Vector3.new(3, 2, 0)
		return true, "goto " .. targetPlayer.Name
	end

	if action == "esp" or action == "locate" then
		if normalizeString(argument) == "@all" then
			allEspEnabled = true
			applyEspToAllPlayers()
			enableEspForAllFuturePlayers()
			return true, "esp all"
		end

		local targetPlayer, err = getUniquePlayerMatch(argument)
		if not targetPlayer then
			return false, err
		end

		local ok, espErr = applyEspToPlayer(targetPlayer)
		if not ok then
			return false, espErr
		end

		return true, "esp " .. targetPlayer.Name
	end

	if action == "unesp" or action == "unlocate" then
		if normalizeString(argument) == "@all" then
			clearAllEsp()
			return true, "unesp all"
		end

		local targetPlayer, err = getUniquePlayerMatch(argument)
		if not targetPlayer then
			return false, err
		end

		clearEspForPlayer(targetPlayer)
		return true, "unesp " .. targetPlayer.Name
	end

	if action == "view" or action == "lookat" then
		local targetPlayer, err = getUniquePlayerMatch(argument)
		if not targetPlayer then
			return false, err
		end

		local ok, viewErr = setViewTarget(targetPlayer)
		if not ok then
			return false, viewErr
		end

		return true, "view " .. targetPlayer.Name
	end

	if action == "unview" or action == "unlookat" then
		resetView()
		return true, "unview"
	end

	if action == "fly" then
		local speed = tonumber(argument) or 20
		local ok, err = startFly(speed)
		if not ok then
			return false, err
		end
		return true, "fly " .. tostring(speed)
	end

	if action == "unfly" then
		stopFly()
		return true, "unfly"
	end

	if action == "respawn" or action == "reset" then
		local character = player.Character
		if not character then
			return false, "character not ready"
		end
		character:BreakJoints()
		return true, "respawn"
	end

	if action == "noclip" then
		startNoclip()
		return true, "noclip"
	end

	if action == "unnoclip" then
		stopNoclip()
		return true, "unnoclip"
	end

	if action == "rj" or action == "rejoin" then
		rejoinServer()
		return true, "rejoin"
	end

	if action == "serverhop" then
		serverHop()
		return true, "serverhop"
	end

	if action == "run" or action == "load" then
		local scriptInfo, err = findScriptInfoByName(argument)
		if not scriptInfo then
			return false, err
		end

		activateScript(scriptInfo)
		return true, "run " .. scriptInfo.Name
	end

	if action == "unrun" or action == "unload" then
		if normalizeString(argument) == "@all" then
			unloadActiveScripts()
			return true, "unload all"
		end

		local scriptInfo, err = findScriptInfoByName(argument)
		if not scriptInfo then
			return false, err
		end

		if not scriptInfo.CanStop then
			return false, "script can't unload"
		end

		if not activeScripts[scriptInfo.Name] then
			return false, "script not active"
		end

		deactivateScript(scriptInfo)
		return true, "unload " .. scriptInfo.Name
	end

	if action == "reload" or action == "rerun" then
		if normalizeString(argument) == "@all" then
			local didReload = false
			for _, scriptInfo in ipairs(scripts) do
				if activeScripts[scriptInfo.Name] and scriptInfo.CanStop then
					didReload = true
					deactivateScript(scriptInfo)
					task.wait()
					activateScript(scriptInfo)
				end
			end
			if not didReload then
				return false, "no active scripts"
			end
			return true, "reload all"
		end

		local scriptInfo, err = findScriptInfoByName(argument)
		if not scriptInfo then
			return false, err
		end

		return reloadScript(scriptInfo)
	end

	return false, "unknown command"
end

local function submitCommand()
	commandText = commandBox.Text or ""
	local ok, message = runCommand(commandText)
	setCommandStatus(message)
	if ok then
		commandBox.Text = ""
		commandText = ""
	end
end

commandBox.FocusLost:Connect(function(enterPressed)
	commandText = commandBox.Text
	if enterPressed then
		submitCommand()
	end
end)

local function refreshTabs()
	local isScripts = currentTab == "Scripts"
	local isSettings = currentTab == "Settings"
	local isKeybinds = currentTab == "Keybinds"

	scriptsPage.Visible = isScripts
	settingsPage.Visible = isSettings
	keybindsPage.Visible = isKeybinds

	scriptsTabButton.BackgroundColor3 = isScripts and Color3.fromRGB(32, 32, 32) or Color3.fromRGB(24, 24, 24)
	scriptsTabButton.TextColor3 = isScripts and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(205, 205, 205)

	settingsTabButton.BackgroundColor3 = isSettings and Color3.fromRGB(32, 32, 32) or Color3.fromRGB(24, 24, 24)
	settingsTabButton.TextColor3 = isSettings and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(205, 205, 205)

	keybindsTabButton.BackgroundColor3 = isKeybinds and Color3.fromRGB(32, 32, 32) or Color3.fromRGB(24, 24, 24)
	keybindsTabButton.TextColor3 = isKeybinds and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(205, 205, 205)
end

scriptsTabButton.MouseButton1Click:Connect(function()
	currentTab = "Scripts"
	refreshTabs()
end)

settingsTabButton.MouseButton1Click:Connect(function()
	currentTab = "Settings"
	refreshTabs()
end)

keybindsTabButton.MouseButton1Click:Connect(function()
	currentTab = "Keybinds"
	refreshTabs()
end)

local menuOpen = true
setMenuOpen(gui, true)
refreshTabs()
refreshReexecuteToggle()
refreshSaveSettingsToggle()
setFpsSliderVisual()
setFovSliderVisual()
if camera then
	camera.FieldOfView = targetFOV
end
applyFpsCap()
refreshAllRows()
persistCurrentSettings()

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
	if commandBox:IsFocused() then
		return
	end

	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Tab then
		menuOpen = not menuOpen
		setMenuOpen(gui, menuOpen)
		if menuOpen then
			unlockMouseUntil = tick() + 1
		end
	elseif input.KeyCode == Enum.KeyCode.Semicolon then
		menuOpen = true
		setMenuOpen(gui, true)
		unlockMouseUntil = tick() + 1
		currentTab = "Settings"
		refreshTabs()
		commandBox:CaptureFocus()
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
		draggingWindow = false
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
	end
end)

Players.PlayerRemoving:Connect(function(otherPlayer)
	clearEspForPlayer(otherPlayer)

	if viewState.Target == otherPlayer then
		resetView()
	end

	if allEspCharacterConnections[otherPlayer.UserId] then
		allEspCharacterConnections[otherPlayer.UserId]:Disconnect()
		allEspCharacterConnections[otherPlayer.UserId] = nil
	end
end)
