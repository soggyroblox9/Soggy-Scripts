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

local queueOnTeleport = syn and syn.queue_on_teleport
	or queue_on_teleport
	or (fluxus and fluxus.queue_on_teleport)

local setFpsCap = setfpscap or (syn and syn.set_fps_cap)

local function safeSetFpsCap(cap)
	if not setFpsCap then
		return false
	end
	return pcall(function()
		setFpsCap(cap)
	end)
end

local MENU_URL = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/SoggyScriptHub.lua"

local DEFAULT_SETTINGS = {
	ReexecuteOnTeleport = false,
	AutoRunActiveScripts = true,
	UncapFPS = false,
	FOV = 70
}

_G.LoadstringSelectorSettings = _G.LoadstringSelectorSettings or {}

for key, value in pairs(DEFAULT_SETTINGS) do
	if _G.LoadstringSelectorSettings[key] == nil then
		_G.LoadstringSelectorSettings[key] = value
	end
end

local settings = _G.LoadstringSelectorSettings
_G.LoadstringSelectorSettings = settings

local function clamp(v, min, max)
	return math.max(min, math.min(max, v))
end

local function applyFOV(value)
	settings.FOV = clamp(math.floor(value + 0.5), 1, 120)
	camera.FieldOfView = settings.FOV
end

local function applyFPSSetting()
	if settings.UncapFPS then
		safeSetFpsCap(0)
	else
		safeSetFpsCap(60)
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
		end,
	},
	{
		Name = "Dex Explorer(DONT CLICK)",
		CanStop = false,
		Url = "https://raw.githubusercontent.com/peyton2465/Dex/master/out.lua",
		Action = function(self)
			loadstring(game:HttpGet(self.Url))()
		end,
	}
}

local scriptLookup = {}
for _, scriptInfo in ipairs(scripts) do
	scriptLookup[scriptInfo.Name] = scriptInfo
end

local activeScripts = {}
local rowRefs = {}
local currentTab = "Scripts"

local function tween(obj, props, t)
	TweenService:Create(
		obj,
		TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props
	):Play()
end

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

local function buildTeleportReexecCode()
	local activeNames = {}

	if settings.AutoRunActiveScripts then
		for _, scriptInfo in ipairs(scripts) do
			if activeScripts[scriptInfo.Name] then
				table.insert(activeNames, scriptInfo.Name)
			end
		end
	end

	local payload = {
		settings = settings,
		activeScripts = activeNames
	}

	local payloadJson = HttpService:JSONEncode(payload)

	return ([[
task.spawn(function()
	local HttpService = game:GetService("HttpService")

	local payload = %q
	local ok, data = pcall(function()
		return HttpService:JSONDecode(payload)
	end)
	if not ok or type(data) ~= "table" then
		return
	end

	local loadedSettings = data.settings or {}
	local loadedActiveScripts = data.activeScripts or {}

	local defaults = {
		ReexecuteOnTeleport = false,
		AutoRunActiveScripts = true,
		UncapFPS = false,
		FOV = 70
	}

	_G.LoadstringSelectorSettings = _G.LoadstringSelectorSettings or {}

	for key, value in pairs(defaults) do
		if loadedSettings[key] == nil then
			loadedSettings[key] = value
		end
	end

	_G.LoadstringSelectorSettings = loadedSettings

	local setFpsCap = setfpscap or (syn and syn.set_fps_cap)
	if loadedSettings.UncapFPS and setFpsCap then
		pcall(function()
			setFpsCap(0)
		end)
	end

	if loadedSettings.FOV then
		local cam = workspace.CurrentCamera
		if cam then
			cam.FieldOfView = loadedSettings.FOV
		end
	end

	task.wait(1)

	loadstring(game:HttpGet(%q))()

	_G.LoadstringSelectorPendingScripts = loadedActiveScripts
end)
]]):format(payloadJson, MENU_URL)
end

local function clearQueuedTeleport()
	if not queueOnTeleport then
		return
	end

	pcall(function()
		queueOnTeleport("")
	end)
end

local function queueTeleportReexecIfEnabled()
	if not queueOnTeleport then
		return
	end

	if not settings.ReexecuteOnTeleport then
		clearQueuedTeleport()
		return
	end

	local code = buildTeleportReexecCode()
	pcall(function()
		queueOnTeleport(code)
	end)
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

local function restorePendingScripts()
	local pending = _G.LoadstringSelectorPendingScripts
	if type(pending) ~= "table" then
		return
	end

	_G.LoadstringSelectorPendingScripts = nil

	task.defer(function()
		for _, scriptName in ipairs(pending) do
			local scriptInfo = scriptLookup[scriptName]
			if scriptInfo then
				activateScript(scriptInfo)

				if scriptInfo.Name == "BinisJ"
					or scriptInfo.Name == "Infinite Yield"
					or scriptInfo.Name == "Dex Explorer"
				then
					local ref = rowRefs[scriptInfo.Name]
					if ref and ref.Button then
						local row = ref.Button.Parent
						activeScripts[scriptInfo.Name] = nil
						rowRefs[scriptInfo.Name] = nil
						if row then
							row:Destroy()
						end
					end
				end
			end
		end

		if settings.ReexecuteOnTeleport then
			queueTeleportReexecIfEnabled()
		end
	end)
end

local function rejoinServer()
	queueTeleportReexecIfEnabled()
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
		queueTeleportReexecIfEnabled()
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
scriptsTabButton.Size = UDim2.new(1/3, -4, 1, 0)
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

local infoTabButton = Instance.new("TextButton")
infoTabButton.Size = UDim2.new(1/3, -4, 1, 0)
infoTabButton.Position = UDim2.new(1/3, 2, 0, 0)
infoTabButton.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
infoTabButton.BorderSizePixel = 0
infoTabButton.AutoButtonColor = false
infoTabButton.Text = "Info / Utility"
infoTabButton.TextColor3 = Color3.fromRGB(205, 205, 205)
infoTabButton.Font = Enum.Font.GothamBold
infoTabButton.TextSize = 13
infoTabButton.Parent = tabBar

local infoTabCorner = Instance.new("UICorner")
infoTabCorner.CornerRadius = UDim.new(0, 10)
infoTabCorner.Parent = infoTabButton

local settingsTabButton = Instance.new("TextButton")
settingsTabButton.Size = UDim2.new(1/3, -4, 1, 0)
settingsTabButton.Position = UDim2.new(2/3, 4, 0, 0)
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

local infoPage = Instance.new("Frame")
infoPage.Name = "InfoPage"
infoPage.Size = UDim2.new(1, 0, 1, 0)
infoPage.BackgroundTransparency = 1
infoPage.Visible = false
infoPage.Parent = contentHolder

local settingsPage = Instance.new("Frame")
settingsPage.Name = "SettingsPage"
settingsPage.Size = UDim2.new(1, 0, 1, 0)
settingsPage.BackgroundTransparency = 1
settingsPage.Visible = false
settingsPage.Parent = contentHolder

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

		if scriptInfo.Name == "BinisJ"
			or scriptInfo.Name == "Infinite Yield"
			or scriptInfo.Name == "Dex Explorer" then

			activeScripts[scriptInfo.Name] = nil
			rowRefs[scriptInfo.Name] = nil
			row:Destroy()
		end
	end)
end

local infoScroller = Instance.new("ScrollingFrame")
infoScroller.Size = UDim2.new(1, -12, 1, -12)
infoScroller.Position = UDim2.new(0, 6, 0, 6)
infoScroller.BackgroundTransparency = 1
infoScroller.BorderSizePixel = 0
infoScroller.ScrollBarThickness = 3
infoScroller.ScrollBarImageColor3 = Color3.fromRGB(75, 75, 75)
infoScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
infoScroller.Parent = infoPage

local infoLayout = Instance.new("UIListLayout")
infoLayout.Padding = UDim.new(0, 10)
infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
infoLayout.Parent = infoScroller

infoLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	infoScroller.CanvasSize = UDim2.new(0, 0, 0, infoLayout.AbsoluteContentSize.Y + 8)
end)

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

local function createToggleRow(parent, titleText, descText, order, initialValue, onChanged)
	local box = createSection(parent, 90, order)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -88, 0, 20)
	titleLabel.Position = UDim2.new(0, 10, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = titleText
	titleLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = box

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -110, 0, 42)
	descLabel.Position = UDim2.new(0, 10, 0, 36)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = descText
	descLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.Parent = box

	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(0, 58, 0, 28)
	toggle.Position = UDim2.new(1, -68, 0, 15)
	toggle.BackgroundColor3 = initialValue and Color3.fromRGB(70, 130, 70) or Color3.fromRGB(45, 45, 45)
	toggle.BorderSizePixel = 0
	toggle.Text = ""
	toggle.AutoButtonColor = false
	toggle.Parent = box

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(1, 0)
	toggleCorner.Parent = toggle

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 22, 0, 22)
	knob.Position = initialValue and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = toggle

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local state = initialValue

	local function refresh()
		tween(toggle, {
			BackgroundColor3 = state and Color3.fromRGB(70, 130, 70) or Color3.fromRGB(45, 45, 45)
		})
		tween(knob, {
			Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
		})
	end

	toggle.MouseButton1Click:Connect(function()
		state = not state
		refresh()
		if onChanged then
			onChanged(state)
		end
	end)

	return {
		Box = box,
		Set = function(v)
			state = v
			refresh()
		end,
		Get = function()
			return state
		end
	}
end

local function createSliderRow(parent, titleText, descText, order, minValue, maxValue, initialValue, onChanged)
	local box = createSection(parent, 120, order)

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

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -20, 0, 18)
	descLabel.Position = UDim2.new(0, 10, 0, 34)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = descText
	descLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = box

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0, 52, 0, 18)
	valueLabel.Position = UDim2.new(1, -62, 0, 10)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(initialValue)
	valueLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 13
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = box

	local sliderBack = Instance.new("Frame")
	sliderBack.Size = UDim2.new(1, -20, 0, 8)
	sliderBack.Position = UDim2.new(0, 10, 0, 72)
	sliderBack.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	sliderBack.BorderSizePixel = 0
	sliderBack.Parent = box

	local sliderBackCorner = Instance.new("UICorner")
	sliderBackCorner.CornerRadius = UDim.new(1, 0)
	sliderBackCorner.Parent = sliderBack

	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new(0, 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderBack

	local sliderFillCorner = Instance.new("UICorner")
	sliderFillCorner.CornerRadius = UDim.new(1, 0)
	sliderFillCorner.Parent = sliderFill

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = sliderBack

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local draggingSlider = false
	local currentValue = initialValue

	local function valueToAlpha(v)
		return (v - minValue) / (maxValue - minValue)
	end

	local function setValue(v)
		currentValue = clamp(v, minValue, maxValue)
		local alpha = valueToAlpha(currentValue)
		sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = tostring(math.floor(currentValue + 0.5))
		if onChanged then
			onChanged(currentValue)
		end
	end

	local function updateFromX(x)
		local pos = sliderBack.AbsolutePosition.X
		local size = sliderBack.AbsoluteSize.X
		local alpha = clamp((x - pos) / size, 0, 1)
		local value = minValue + (maxValue - minValue) * alpha
		setValue(value)
	end

	sliderBack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSlider = true
			updateFromX(input.Position.X)
		end
	end)

	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSlider = true
			updateFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSlider = false
		end
	end)

	setValue(initialValue)

	return {
		Box = box,
		Set = setValue,
		Get = function()
			return currentValue
		end
	}
end

createKeybindBox(
	infoScroller,
	"Speedometer/FOV Keybinds",
	"• F = Increase Fov\n• T = Reset FOV",
	1,
	80,
	38
)

createKeybindBox(
	infoScroller,
	"Map Cycler Keybinds",
	"• M = Toggle Music\n• V = Toggle Sounds\n• Shift + N = Cycle Skyboxes/Maps",
	2
)

createKeybindBox(
	infoScroller,
	"Pallet Cycler Keybinds",
	"• P = Cycle Pallet Mode\n• Y = Despawn Toys\n• Shift + P = Reset Pallet Mode",
	3
)

createKeybindBox(
	infoScroller,
	"Freecam Keybinds",
	"• C = Toggle Freecam\n• Shift = Down In Freecam\n• Space = Up In Freecam\n• Middle Mouse = Reset Freecam Speed\n• Scroll Wheel = Increase/Decrease Freecam\n  Speed",
	4,
	134,
	90
)

createKeybindBox(
	infoScroller,
	"KBM Input Display Keybinds",
	"• B = Toggles UI\n• G = Cycles Control Buttons\n• Enter = Use Selected Control Button\n• Backspace = Deselects Control Button\n• Shift + B = Reset UI",
	5,
	124,
	78
)

local utilitySection = createSection(infoScroller, 200, 6)

local utilityTitle = Instance.new("TextLabel")
utilityTitle.Size = UDim2.new(1, -20, 0, 20)
utilityTitle.Position = UDim2.new(0, 10, 0, 10)
utilityTitle.BackgroundTransparency = 1
utilityTitle.Text = "Server / Script Utility"
utilityTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
utilityTitle.Font = Enum.Font.GothamBold
utilityTitle.TextSize = 14
utilityTitle.TextXAlignment = Enum.TextXAlignment.Left
utilityTitle.Parent = utilitySection

local sidePadding = 10
local rowHeight = 40
local startY = 38
local gap = 10

local rejoinButton = Instance.new("TextButton")
rejoinButton.Size = UDim2.new(1, -20, 0, rowHeight)
rejoinButton.Position = UDim2.new(0, sidePadding, 0, startY)
rejoinButton.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
rejoinButton.BorderSizePixel = 0
rejoinButton.AutoButtonColor = false
rejoinButton.Text = "Rejoin"
rejoinButton.TextColor3 = Color3.fromRGB(245, 245, 245)
rejoinButton.Font = Enum.Font.GothamBold
rejoinButton.TextSize = 14
rejoinButton.Parent = utilitySection

local rejoinCorner = Instance.new("UICorner")
rejoinCorner.CornerRadius = UDim.new(0, 10)
rejoinCorner.Parent = rejoinButton

local hopButton = Instance.new("TextButton")
hopButton.Size = UDim2.new(1, -20, 0, rowHeight)
hopButton.Position = UDim2.new(0, sidePadding, 0, startY + rowHeight + gap)
hopButton.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
hopButton.BorderSizePixel = 0
hopButton.AutoButtonColor = false
hopButton.Text = "Server Hop"
hopButton.TextColor3 = Color3.fromRGB(245, 245, 245)
hopButton.Font = Enum.Font.GothamBold
hopButton.TextSize = 14
hopButton.Parent = utilitySection

local hopCorner = Instance.new("UICorner")
hopCorner.CornerRadius = UDim.new(0, 10)
hopCorner.Parent = hopButton

local unloadButton = Instance.new("TextButton")
unloadButton.Size = UDim2.new(1, -20, 0, rowHeight)
unloadButton.Position = UDim2.new(0, sidePadding, 0, startY + (rowHeight + gap) * 2)
unloadButton.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
unloadButton.BorderSizePixel = 0
unloadButton.AutoButtonColor = false
unloadButton.Text = "Unload Active Scripts"
unloadButton.TextColor3 = Color3.fromRGB(245, 245, 245)
unloadButton.Font = Enum.Font.GothamBold
unloadButton.TextSize = 14
unloadButton.Parent = utilitySection

local unloadCorner = Instance.new("UICorner")
unloadCorner.CornerRadius = UDim.new(0, 10)
unloadCorner.Parent = unloadButton

local function styleUtilityButton(button)
	button.MouseEnter:Connect(function()
		tween(button, {BackgroundColor3 = Color3.fromRGB(35, 35, 35)})
	end)

	button.MouseLeave:Connect(function()
		tween(button, {BackgroundColor3 = Color3.fromRGB(28, 28, 28)})
	end)

	button.MouseButton1Down:Connect(function()
		tween(button, {BackgroundColor3 = Color3.fromRGB(42, 42, 42)}, 0.06)
	end)

	button.MouseButton1Up:Connect(function()
		tween(button, {BackgroundColor3 = Color3.fromRGB(28, 28, 28)}, 0.08)
	end)
end

styleUtilityButton(rejoinButton)
styleUtilityButton(hopButton)
styleUtilityButton(unloadButton)

rejoinButton.MouseButton1Click:Connect(function()
	rejoinServer()
end)

hopButton.MouseButton1Click:Connect(function()
	serverHop()
end)

unloadButton.MouseButton1Click:Connect(function()
	unloadActiveScripts()
end)

createToggleRow(
	settingsScroller,
	"Re-execute On Teleport",
	"Queues the menu to run again when rejoining or server hopping.",
	1,
	settings.ReexecuteOnTeleport,
	function(state)
		settings.ReexecuteOnTeleport = state
		if state then
			queueTeleportReexecIfEnabled()
		else
			clearQueuedTeleport()
		end
	end
)

createToggleRow(
	settingsScroller,
	"Auto-run Active Scripts",
	"Re-runs currently active scripts after teleport when re-execute is enabled.",
	2,
	settings.AutoRunActiveScripts,
	function(state)
		settings.AutoRunActiveScripts = state
		if settings.ReexecuteOnTeleport then
			queueTeleportReexecIfEnabled()
		end
	end
)

createToggleRow(
	settingsScroller,
	"Uncap FPS",
	"Uses setfpscap(0) when supported by your executor.",
	3,
	settings.UncapFPS,
	function(state)
		settings.UncapFPS = state
		applyFPSSetting()
		if settings.ReexecuteOnTeleport then
			queueTeleportReexecIfEnabled()
		end
	end
)

createSliderRow(
	settingsScroller,
	"Field Of View",
	"Smooth drag slider for live camera FOV.",
	4,
	1,
	120,
	settings.FOV,
	function(value)
		applyFOV(value)
		if settings.ReexecuteOnTeleport then
			queueTeleportReexecIfEnabled()
		end
	end
)

local settingsNote = createSection(settingsScroller, 82, 5)

local settingsNoteTitle = Instance.new("TextLabel")
settingsNoteTitle.Size = UDim2.new(1, -20, 0, 20)
settingsNoteTitle.Position = UDim2.new(0, 10, 0, 10)
settingsNoteTitle.BackgroundTransparency = 1
settingsNoteTitle.Text = "Notes"
settingsNoteTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
settingsNoteTitle.Font = Enum.Font.GothamBold
settingsNoteTitle.TextSize = 14
settingsNoteTitle.TextXAlignment = Enum.TextXAlignment.Left
settingsNoteTitle.Parent = settingsNote

local settingsNoteText = Instance.new("TextLabel")
settingsNoteText.Size = UDim2.new(1, -20, 0, 42)
settingsNoteText.Position = UDim2.new(0, 10, 0, 34)
settingsNoteText.BackgroundTransparency = 1
settingsNoteText.Text = "Re-execute and FPS uncapping depend on executor support. FOV updates live and is also applied after teleports."
settingsNoteText.TextColor3 = Color3.fromRGB(170, 170, 170)
settingsNoteText.Font = Enum.Font.Gotham
settingsNoteText.TextSize = 12
settingsNoteText.TextWrapped = true
settingsNoteText.TextXAlignment = Enum.TextXAlignment.Left
settingsNoteText.TextYAlignment = Enum.TextYAlignment.Top
settingsNoteText.Parent = settingsNote

local function refreshTabs()
	local scriptsSelected = currentTab == "Scripts"
	local infoSelected = currentTab == "Info"
	local settingsSelected = currentTab == "Settings"

	scriptsPage.Visible = scriptsSelected
	infoPage.Visible = infoSelected
	settingsPage.Visible = settingsSelected

	scriptsTabButton.BackgroundColor3 = scriptsSelected and Color3.fromRGB(32, 32, 32) or Color3.fromRGB(24, 24, 24)
	scriptsTabButton.TextColor3 = scriptsSelected and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(205, 205, 205)

	infoTabButton.BackgroundColor3 = infoSelected and Color3.fromRGB(32, 32, 32) or Color3.fromRGB(24, 24, 24)
	infoTabButton.TextColor3 = infoSelected and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(205, 205, 205)

	settingsTabButton.BackgroundColor3 = settingsSelected and Color3.fromRGB(32, 32, 32) or Color3.fromRGB(24, 24, 24)
	settingsTabButton.TextColor3 = settingsSelected and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(205, 205, 205)
end

scriptsTabButton.MouseButton1Click:Connect(function()
	currentTab = "Scripts"
	refreshTabs()
end)

infoTabButton.MouseButton1Click:Connect(function()
	currentTab = "Info"
	refreshTabs()
end)

settingsTabButton.MouseButton1Click:Connect(function()
	currentTab = "Settings"
	refreshTabs()
end)

local menuOpen = true
setMenuOpen(gui, true)
refreshTabs()
applyFOV(settings.FOV)
applyFPSSetting()
restorePendingScripts()

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

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
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
