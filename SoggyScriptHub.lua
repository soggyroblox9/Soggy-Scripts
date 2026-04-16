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

local SETTINGS_FILE_NAME = "SoggyScriptHub_Settings.json"
local MENU_LOADSTRING_URL = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/SoggyScriptHub.lua"

local state = {
	reExecuteOnTeleport = true,
	saveSettings = true,
	targetFOV = math.floor(((camera and camera.FieldOfView) or 70) + 0.5),
	commandText = "",
	fpsCapOptions = {60, 120, 144, 180, 200, 240, 0},
	fpsCapLabels = {"60", "120", "144", "180", "200", "240", "240+"},
	fpsCapIndex = 1,
	defaultFOV = math.floor(((camera and camera.FieldOfView) or 70) + 0.5),
	defaultFpsCapIndex = 1,
	defaultMinZoomDistance = player.CameraMinZoomDistance,
	defaultMaxZoomDistance = player.CameraMaxZoomDistance,
	thirdPersonEnabled = false,
	currentTab = "Main/Scripts",
	menuOpen = true,
	unlockMouseUntil = 0,
	activeScripts = {},
	rowRefs = {},
	commandStatusResetToken = 0,
	draggingSlider = nil,
	draggingWindow = false,
	dragStart = nil,
	startPos = nil,
	defaultGravity = workspace.Gravity
}

local refs = {
	gui = nil,
	frame = nil,
	topBar = nil,
	closeButton = nil,
	commandBox = nil,
	commandTitle = nil,
	pages = {},
	tabButtons = {},
	sliders = {},
	player = {},
	settings = {}
}

local scripts = {
	{
		Name = "Speedometer",
		CanStop = true,
		Url = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/SpeedometerDisplay.lua",
		Action = function(self)
			loadstring(game:HttpGet(self.Url))()
		end,
		Stop = function()
			if _G.StopSpeedometer then
				_G.StopSpeedometer()
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
		Name = "Dex Explorer",
		CanStop = false,
		Url = "https://raw.githubusercontent.com/peyton2465/Dex/master/out.lua",
		Action = function(self)
			loadstring(game:HttpGet(self.Url))()
		end
	}
}

local espObjects = {}
local trackedEspPlayers = {}
local allEspEnabled = false
local allEspPlayerAddedConnection = nil
local allEspCharacterConnections = {}

local viewState = {
	Target = nil
}

local noclipState = {
	Enabled = false,
	Connection = nil
}

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
	return readfile or (syn and syn.readfile)
end

local function getWriteFileFunction()
	return writefile or (syn and syn.writefile)
end

local function getIsFileFunction()
	return isfile or (syn and syn.isfile)
end

local function getDeleteFileFunction()
	return delfile or (syn and syn.delfile)
end

local function queueTeleportSource(source)
	local queueFn = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
	if not queueFn then
		return
	end
	pcall(function()
		queueFn(source)
	end)
end

local function saveSettingsToFile()
	local writeFile = getWriteFileFunction()
	local isFile = getIsFileFunction()
	if not writeFile or not isFile then
		return
	end

	local payload = {
		FOV = math.clamp(math.floor((state.targetFOV or state.defaultFOV) + 0.5), 1, 120),
		FpsCapIndex = math.clamp(math.floor(state.fpsCapIndex or state.defaultFpsCapIndex), 1, #state.fpsCapOptions),
		ThirdPerson = state.thirdPersonEnabled == true
	}

	pcall(function()
		writeFile(SETTINGS_FILE_NAME, HttpService:JSONEncode(payload))
	end)
end

local function clearSavedSettingsFile()
	local deleteFile = getDeleteFileFunction()
	local isFile = getIsFileFunction()
	if not deleteFile or not isFile then
		return
	end
	local ok, exists = pcall(function()
		return isFile(SETTINGS_FILE_NAME)
	end)
	if ok and exists then
		pcall(function()
			deleteFile(SETTINGS_FILE_NAME)
		end)
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
		state.targetFOV = math.clamp(math.floor(data.FOV + 0.5), 1, 120)
	end
	if type(data.FpsCapIndex) == "number" then
		state.fpsCapIndex = math.clamp(math.floor(data.FpsCapIndex), 1, #state.fpsCapOptions)
	end
	if type(data.ThirdPerson) == "boolean" then
		state.thirdPersonEnabled = data.ThirdPerson
	end
end

local function persistCurrentSettings()
	if state.saveSettings then
		saveSettingsToFile()
	else
		clearSavedSettingsFile()
	end
end

do
	local queued = getgenv and getgenv().__SoggyHubQueuedSettings
	if type(queued) == "table" then
		state.saveSettings = queued.SaveSettings ~= false
		if type(queued.FOV) == "number" then
			state.targetFOV = math.clamp(math.floor(queued.FOV + 0.5), 1, 120)
		end
		if type(queued.FpsCapIndex) == "number" then
			state.fpsCapIndex = math.clamp(math.floor(queued.FpsCapIndex), 1, #state.fpsCapOptions)
		end
		if type(queued.ThirdPerson) == "boolean" then
			state.thirdPersonEnabled = queued.ThirdPerson
		end
		getgenv().__SoggyHubQueuedSettings = nil
		if state.saveSettings then
			loadSavedSettingsFromFile()
		end
	elseif state.saveSettings then
		loadSavedSettingsFromFile()
	end
end

local function queueReexecute()
	persistCurrentSettings()

	if state.reExecuteOnTeleport then
		local queuedFOV = state.saveSettings and state.targetFOV or state.defaultFOV
		local queuedFpsCapIndex = state.saveSettings and state.fpsCapIndex or state.defaultFpsCapIndex
		local queuedThirdPerson = state.saveSettings and state.thirdPersonEnabled or false

		local source = string.format([[
getgenv().__SoggyHubQueuedSettings = {
	SaveSettings = %s,
	FOV = %d,
	FpsCapIndex = %d,
	ThirdPerson = %s
}
loadstring(game:HttpGet("%s"))()
		]], tostring(state.saveSettings), queuedFOV, queuedFpsCapIndex, tostring(queuedThirdPerson), MENU_LOADSTRING_URL)

		queueTeleportSource(source)
	else
		queueTeleportSource("")
	end
end

local function getSetFpsCapFunction()
	return setfpscap or set_fps_cap or (syn and syn.setfpscap)
end

local function applyFpsCap()
	local setCap = getSetFpsCapFunction()
	if not setCap then
		return
	end
	local cap = state.fpsCapOptions[state.fpsCapIndex] or 60
	pcall(function()
		setCap(cap)
	end)
end

local function tween(obj, props, t)
	if not obj then
		return
	end
	TweenService:Create(
		obj,
		TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props
	):Play()
end

local function styleButton(button, normalColor, hoverColor, pressColor)
	normalColor = normalColor or Color3.fromRGB(30, 35, 44)
	hoverColor = hoverColor or Color3.fromRGB(39, 46, 57)
	pressColor = pressColor or Color3.fromRGB(48, 56, 68)

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

local function getLocalHumanoid()
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

local function getUniquePlayerMatch(query)
	local search = normalizeString(query)
	if search == "" then
		return nil, "missing name"
	end

	local exactMatches, prefixMatches = {}, {}
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
	if not targetPlayer or not character or not refs.gui then
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
	highlight.Parent = refs.gui

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SoggyCommandESPLabel"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 220, 0, 46)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.Adornee = adornPart
	billboard.Parent = refs.gui

	local displayLabel = Instance.new("TextLabel")
	displayLabel.Size = UDim2.new(1, 0, 0, 22)
	displayLabel.BackgroundTransparency = 1
	displayLabel.Text = targetPlayer.DisplayName
	displayLabel.TextColor3 = Color3.fromRGB(248, 250, 255)
	displayLabel.TextStrokeTransparency = 0.5
	displayLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	displayLabel.Font = Enum.Font.GothamSemibold
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
	usernameLabel.Font = Enum.Font.GothamSemibold
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

local function resetView()
	viewState.Target = nil
	local _, humanoid = getCharacterParts(player)
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

local function refreshNoclipToggles()
	local enabled = noclipState.Enabled
	if refs.player.noclipTrack then
		refs.player.noclipTrack.BackgroundColor3 = enabled and Color3.fromRGB(98, 122, 168) or Color3.fromRGB(72, 80, 94)
	end
	if refs.player.noclipKnob then
		refs.player.noclipKnob.Position = enabled and UDim2.new(0, 31, 0, 3) or UDim2.new(0, 3, 0, 3)
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

local function setNoclipEnabled(enabled)
	if enabled then
		startNoclip()
	else
		stopNoclip()
	end
	refreshNoclipToggles()
end

local function applyThirdPersonState()
	if state.thirdPersonEnabled then
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = 6
		player.CameraMaxZoomDistance = 100
	else
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = state.defaultMinZoomDistance
		player.CameraMaxZoomDistance = state.defaultMaxZoomDistance
	end
end

local function refreshThirdPersonToggles()
	local enabled = state.thirdPersonEnabled
	local color = enabled and Color3.fromRGB(98, 122, 168) or Color3.fromRGB(72, 80, 94)
	local pos = enabled and UDim2.new(0, 31, 0, 3) or UDim2.new(0, 3, 0, 3)

	if refs.player.thirdTrack then
		refs.player.thirdTrack.BackgroundColor3 = color
	end
	if refs.player.thirdKnob then
		refs.player.thirdKnob.Position = pos
	end
end

local function setThirdPersonEnabled(enabled)
	state.thirdPersonEnabled = enabled == true
	applyThirdPersonState()
	refreshThirdPersonToggles()
	if state.saveSettings then
		saveSettingsToFile()
	end
end

local function refreshSettingsToggles()
	local function apply(track, knob, enabled)
		if track then
			track.BackgroundColor3 = enabled and Color3.fromRGB(98, 122, 168) or Color3.fromRGB(72, 80, 94)
		end
		if knob then
			knob.Position = enabled and UDim2.new(0, 31, 0, 3) or UDim2.new(0, 3, 0, 3)
		end
	end
	apply(refs.settings.reexecTrack, refs.settings.reexecKnob, state.reExecuteOnTeleport)
	apply(refs.settings.saveTrack, refs.settings.saveKnob, state.saveSettings)
end

local function setCommandStatus(message)
	state.commandStatusResetToken += 1
	local token = state.commandStatusResetToken
	if refs.commandTitle then
		refs.commandTitle.Text = message and ("Command Bar - " .. tostring(message)) or "Command Bar"
	end
	task.delay(2.5, function()
		if state.commandStatusResetToken == token and refs.commandTitle then
			refs.commandTitle.Text = "Command Bar"
		end
	end)
end

local function setMenuOpen(guiObject, enabled)
	state.menuOpen = enabled == true
	if refs.frame then
		refs.frame.Visible = state.menuOpen
	end
	if guiObject then
		guiObject.Enabled = true
	end
	if state.menuOpen then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end
	camera.CameraType = Enum.CameraType.Custom
end

local function refreshRow(scriptName)
	local ref = state.rowRefs[scriptName]
	if not ref then
		return
	end
	local isActive = state.activeScripts[scriptName] == true
	if ref.ToggleTrack then
		ref.ToggleTrack.BackgroundColor3 = isActive and Color3.fromRGB(98, 122, 168) or Color3.fromRGB(72, 80, 94)
	end
	if ref.ToggleKnob then
		ref.ToggleKnob.Position = isActive and UDim2.new(0, 31, 0, 3) or UDim2.new(0, 3, 0, 3)
	end
	if ref.ActionButton then
		ref.ActionButton.ImageTransparency = isActive and 0 or 0.2
		ref.ActionButton.ImageColor3 = isActive and Color3.fromRGB(241, 244, 248) or Color3.fromRGB(205, 212, 224)
	end
end

local function refreshAllRows()
	for scriptName in pairs(state.rowRefs) do
		refreshRow(scriptName)
	end
end

local function activateScript(scriptInfo)
	if state.activeScripts[scriptInfo.Name] then
		refreshRow(scriptInfo.Name)
		return true
	end

	local ok, err = pcall(function()
		if scriptInfo.Action then
			scriptInfo.Action(scriptInfo)
		end
	end)

	if ok then
		state.activeScripts[scriptInfo.Name] = true
		refreshRow(scriptInfo.Name)
		return true
	end
	warn("Failed to run " .. scriptInfo.Name .. ": " .. tostring(err))
	return false, tostring(err)
end

local function deactivateScript(scriptInfo)
	if not scriptInfo.CanStop then
		return false, "script can't stop"
	end
	local ok, err = pcall(function()
		if scriptInfo.Stop then
			scriptInfo.Stop()
		end
	end)
	if not ok then
		warn("Failed to stop " .. scriptInfo.Name .. ": " .. tostring(err))
		return false, tostring(err)
	end
	state.activeScripts[scriptInfo.Name] = nil
	refreshRow(scriptInfo.Name)
	return true
end

local function setScriptToggle(scriptInfo, enabled)
	if enabled then
		return activateScript(scriptInfo)
	end
	if not scriptInfo.CanStop then
		refreshRow(scriptInfo.Name)
		return false, "script can't stop"
	end
	if not state.activeScripts[scriptInfo.Name] then
		refreshRow(scriptInfo.Name)
		return true
	end
	return deactivateScript(scriptInfo)
end

local function toggleScript(scriptInfo)
	return setScriptToggle(scriptInfo, not state.activeScripts[scriptInfo.Name])
end
local function rejoinServer()
	queueReexecute()
	TeleportService:Teleport(placeId, player)
end

local function serverHop()
	local cursor = ""
	local foundServer = nil

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


local setSliderVisual, refreshJumpSlider, refreshGravitySlider


refreshJumpSlider = function()
	local humanoid = getLocalHumanoid()
	local value = humanoid and (humanoid.UseJumpPower and humanoid.JumpPower or 24) or 24
	setSliderVisual("player_jump", math.clamp((value - 0) / 300, 0, 1), math.floor(value + 0.5))
end


local function setJumpPower(value)
	value = tonumber(value)
	if not value then
		return false
	end
	local humanoid = getLocalHumanoid()
	if not humanoid then
		return false
	end
	humanoid.UseJumpPower = true
	humanoid.JumpPower = math.clamp(value, 0, 300)
	refreshJumpSlider()
	return true
end

local function setGravity(value)
	value = tonumber(value)
	if not value then
		return false
	end
	workspace.Gravity = math.clamp(value, 0, 500)
	refreshGravitySlider()
	return true
end

local function syncPlayerStatBoxes()
	refreshJumpSlider()
	refreshGravitySlider()
end

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = parent
	return corner
end

local function createLabel(parent, text, size, pos, font, textSize, color, alignX)
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = pos
	label.BackgroundTransparency = 1
	label.Text = text or ""
	label.TextColor3 = color or Color3.fromRGB(241, 244, 248)
	label.Font = font or Enum.Font.GothamSemibold
	label.TextSize = textSize or 14
	label.TextXAlignment = alignX or Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function createButton(parent, text, size, pos)
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = pos
	button.BackgroundColor3 = Color3.fromRGB(30, 35, 44)
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = text or ""
	button.TextColor3 = Color3.fromRGB(241, 244, 248)
	button.Font = Enum.Font.GothamSemibold
	button.TextSize = 14
	button.Parent = parent
	createCorner(button, 10)
	return button
end

local function createToggle(parent, pos)
	local track = Instance.new("TextButton")
	track.Size = UDim2.new(0, 58, 0, 30)
	track.Position = pos
	track.BackgroundColor3 = Color3.fromRGB(72, 80, 94)
	track.BorderSizePixel = 0
	track.AutoButtonColor = false
	track.Text = ""
	track.Parent = parent
	createCorner(track, 999)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 24, 0, 24)
	knob.Position = UDim2.new(0, 3, 0, 3)
	knob.BackgroundColor3 = Color3.fromRGB(248, 250, 255)
	knob.BorderSizePixel = 0
	knob.Parent = track
	createCorner(knob, 999)

	return track, knob
end

local function createTextBox(parent, placeholder, size, pos, initial)
	local box = Instance.new("TextBox")
	box.Size = size
	box.Position = pos
	box.BackgroundColor3 = Color3.fromRGB(30, 35, 44)
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Text = initial or ""
	box.PlaceholderText = placeholder or ""
	box.TextColor3 = Color3.fromRGB(241, 244, 248)
	box.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	box.Font = Enum.Font.GothamSemibold
	box.TextSize = 14
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Parent = parent
	createCorner(box, 10)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.Parent = box
	return box
end

local function createSection(parent, height, order)
	local section = Instance.new("Frame")
	section.Size = UDim2.new(1, -2, 0, height)
	section.BackgroundColor3 = Color3.fromRGB(22, 26, 33)
	section.BorderSizePixel = 0
	section.LayoutOrder = order
	section.Parent = parent
	createCorner(section, 12)
	return section
end

local function createScrolledPage(parent)
	local page = Instance.new("Frame")
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = parent

	local scroller = Instance.new("ScrollingFrame")
	scroller.Size = UDim2.new(1, -12, 1, -12)
	scroller.Position = UDim2.new(0, 6, 0, 6)
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.ScrollBarThickness = 3
	scroller.ScrollBarImageColor3 = Color3.fromRGB(92, 102, 120)
	scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroller.Parent = page

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroller

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroller.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
	end)

	return page, scroller, layout
end

local function createSliderSection(parent, order, titleText, sliderKey)
	local section = createSection(parent, 74, order)
	createLabel(section, titleText, UDim2.new(1, -20, 0, 20), UDim2.new(0, 12, 0, 10), Enum.Font.GothamSemibold, 14)

	local valueLabel = createLabel(section, "", UDim2.new(0, 48, 0, 20), UDim2.new(1, -52, 0, 10), Enum.Font.GothamSemibold, 13, Color3.fromRGB(190, 190, 190), Enum.TextXAlignment.Right)

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -24, 0, 8)
	track.Position = UDim2.new(0, 12, 0, 46)
	track.BackgroundColor3 = Color3.fromRGB(39, 45, 55)
	track.BorderSizePixel = 0
	track.Parent = section
	createCorner(track, 999)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(98, 122, 168)
	fill.BorderSizePixel = 0
	fill.Parent = track
	createCorner(fill, 999)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(248, 250, 255)
	knob.BorderSizePixel = 0
	knob.Parent = track
	createCorner(knob, 999)

	local hitbox = Instance.new("TextButton")
	hitbox.Size = UDim2.new(0, 30, 0, 30)
	hitbox.AnchorPoint = Vector2.new(0.5, 0.5)
	hitbox.Position = knob.Position
	hitbox.BackgroundTransparency = 1
	hitbox.BorderSizePixel = 0
	hitbox.Text = ""
	hitbox.AutoButtonColor = false
	hitbox.Parent = track

	refs.sliders[sliderKey] = {
		valueLabel = valueLabel,
		track = track,
		fill = fill,
		knob = knob,
		hitbox = hitbox
	}
	return section
end

local function createResettableSliderSection(parent, order, titleText, sliderKey, resetCallback)
	local section = createSliderSection(parent, order, titleText, sliderKey)
	local valueLabel = refs.sliders[sliderKey].valueLabel
	valueLabel.Position = UDim2.new(1, -72, 0, 10)
	valueLabel.Size = UDim2.new(0, 54, 0, 20)

	local resetButton = Instance.new("ImageButton")
	resetButton.Size = UDim2.new(0, 16, 0, 16)
	resetButton.Position = UDim2.new(1, -60, 0, 12)
	resetButton.BackgroundTransparency = 1
	resetButton.BorderSizePixel = 0
	resetButton.AutoButtonColor = false
	resetButton.Image = "rbxassetid://107192048421590"
	resetButton.ImageColor3 = Color3.fromRGB(200, 200, 200)
	resetButton.ImageTransparency = 0.2
	resetButton.Parent = section

	resetButton.MouseEnter:Connect(function()
		tween(resetButton, {ImageTransparency = 0})
	end)

	resetButton.MouseLeave:Connect(function()
		tween(resetButton, {ImageTransparency = 0.2})
	end)

	resetButton.MouseButton1Click:Connect(function()
		if resetCallback then
			resetCallback()
		end
	end)

	return section, resetButton
end

setSliderVisual = function(sliderKey, alpha, text)
	local slider = refs.sliders[sliderKey]
	if not slider then
		return
	end
	alpha = math.clamp(alpha, 0, 1)
	slider.fill.Size = UDim2.new(alpha, 0, 1, 0)
	slider.knob.Position = UDim2.new(alpha, 0, 0.5, 0)
	slider.hitbox.Position = slider.knob.Position
	slider.valueLabel.Text = tostring(text)
end

refreshGravitySlider = function()
	local gravity = workspace.Gravity or 196.2
	local alpha = math.clamp((gravity - 0) / 500, 0, 1)
	setSliderVisual("player_gravity", alpha, math.floor(gravity + 0.5))
end

local function refreshFpsSliders()
	local count = #state.fpsCapOptions
	local alpha = 0
	if count > 1 then
		alpha = (state.fpsCapIndex - 1) / (count - 1)
	end
	local text = state.fpsCapLabels[state.fpsCapIndex]
	setSliderVisual("settings_fps", alpha, text)
end

local function refreshFovSliders()
	local alpha = math.clamp((state.targetFOV - 1) / 119, 0, 1)
	setSliderVisual("player_fov", alpha, math.floor(state.targetFOV + 0.5))
end

local function beginSliderDrag(sliderKey, setter, input)
	local slider = refs.sliders[sliderKey]
	if not slider then
		return
	end
	state.draggingSlider = {
		track = slider.track,
		setter = setter
	}
	local alpha = math.clamp((input.Position.X - slider.track.AbsolutePosition.X) / slider.track.AbsoluteSize.X, 0, 1)
	setter(alpha)
end

local function buildMainShell()
	local oldGui = playerGui:FindFirstChild("LoadstringSelectorGui")
	if oldGui then
		oldGui:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "LoadstringSelectorGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui
	refs.gui = gui

	local frame = Instance.new("Frame")
	frame.Name = "Main"
	frame.Size = UDim2.new(0, 480, 0, 530)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(19, 22, 28)
	frame.BorderSizePixel = 0
	frame.Parent = gui
	createCorner(frame, 14)

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Color3.fromRGB(48, 56, 68)
	frameStroke.Thickness = 1.2
	frameStroke.Transparency = 0.15
	frameStroke.Parent = frame

	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 42)
	topBar.BackgroundColor3 = Color3.fromRGB(26, 30, 38)
	topBar.BorderSizePixel = 0
	topBar.Parent = frame
	createCorner(topBar, 14)

	local topBarFix = Instance.new("Frame")
	topBarFix.Size = UDim2.new(1, 0, 0, 16)
	topBarFix.Position = UDim2.new(0, 0, 1, -16)
	topBarFix.BackgroundColor3 = Color3.fromRGB(26, 30, 38)
	topBarFix.BorderSizePixel = 0
	topBarFix.Parent = topBar

	local logo = Instance.new("ImageLabel")
	logo.Size = UDim2.new(0, 34, 0, 34)
	logo.Position = UDim2.new(0, 6, 0.5, -18)
	logo.BackgroundTransparency = 1
	logo.Image = "rbxassetid://96561699768956"
	logo.Parent = topBar

	createLabel(topBar, "Soggy-Script HUB", UDim2.new(1, -84, 1, 0), UDim2.new(0, 42, 0, 0), Enum.Font.GothamBlack, 17)

	local closeButton = Instance.new("ImageButton")
	closeButton.Size = UDim2.new(0, 22, 0, 22)
	closeButton.Position = UDim2.new(1, -33, 0.5, -11)
	closeButton.BackgroundTransparency = 1
	closeButton.BorderSizePixel = 0
	closeButton.AutoButtonColor = false
	closeButton.Image = "rbxassetid://138598738825070"
	closeButton.ImageColor3 = Color3.fromRGB(241, 244, 248)
	closeButton.ImageTransparency = 0.15
	closeButton.Parent = topBar
	refs.closeButton = closeButton
	refs.topBar = topBar
	refs.frame = frame

	local navSidebar = Instance.new("Frame")
	navSidebar.Name = "NavSidebar"
	navSidebar.Size = UDim2.new(0, 148, 1, -58)
	navSidebar.Position = UDim2.new(0, 10, 0, 48)
	navSidebar.BackgroundColor3 = Color3.fromRGB(14, 17, 23)
	navSidebar.BorderSizePixel = 0
	navSidebar.Parent = frame
	createCorner(navSidebar, 12)

	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, -20, 0, 278)
	tabBar.Position = UDim2.new(0, 10, 0, 12)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = navSidebar

	local function addTab(name, y)
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 34)
		button.Position = UDim2.new(0, 0, 0, y)
		button.BackgroundColor3 = Color3.fromRGB(26, 30, 38)
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = name
		button.TextColor3 = Color3.fromRGB(205, 212, 224)
		button.Font = Enum.Font.GothamSemibold
		button.TextSize = 13
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.Parent = tabBar
		createCorner(button, 10)

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 12)
		padding.Parent = button

		refs.tabButtons[name] = button
		return button
	end

	addTab("Main/Scripts", 0)
	addTab("Player Settings", 40)
	addTab("Script Settings", 80)
	addTab("Map Settings", 120)
	addTab("Pallet Settings", 160)
	addTab("Custom Keybinds", 200)
	addTab("Info & More", 240)

	local profileDivider = Instance.new("Frame")
	profileDivider.Size = UDim2.new(1, -20, 0, 1)
	profileDivider.Position = UDim2.new(0, 10, 1, -74)
	profileDivider.BackgroundColor3 = Color3.fromRGB(58, 64, 76)
	profileDivider.BorderSizePixel = 0
	profileDivider.Parent = navSidebar

	local profileCard = Instance.new("Frame")
	profileCard.Size = UDim2.new(1, -20, 0, 52)
	profileCard.Position = UDim2.new(0, 10, 1, -62)
	profileCard.BackgroundColor3 = Color3.fromRGB(22, 26, 33)
	profileCard.BorderSizePixel = 0
	profileCard.Parent = navSidebar
	createCorner(profileCard, 12)

	local profileAvatar = Instance.new("ImageLabel")
	profileAvatar.Size = UDim2.new(0, 36, 0, 36)
	profileAvatar.Position = UDim2.new(0, 8, 0.5, -18)
	profileAvatar.BackgroundColor3 = Color3.fromRGB(30, 35, 44)
	profileAvatar.BorderSizePixel = 0
	profileAvatar.Parent = profileCard
	createCorner(profileAvatar, 999)

	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Color = Color3.fromRGB(70, 78, 92)
	avatarStroke.Thickness = 1
	avatarStroke.Transparency = 0.15
	avatarStroke.Parent = profileAvatar

	createLabel(profileCard, player.DisplayName, UDim2.new(1, -56, 0, 20), UDim2.new(0, 52, 0, 8))
	local uname = createLabel(profileCard, "@" .. player.Name, UDim2.new(1, -56, 0, 16), UDim2.new(0, 52, 0, 26), Enum.Font.GothamSemibold, 11, Color3.fromRGB(170, 178, 192))
	uname.TextTruncate = Enum.TextTruncate.AtEnd

	do
		local ok, thumbnail = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if ok and type(thumbnail) == "string" and thumbnail ~= "" then
			profileAvatar.Image = thumbnail
		end
	end

	local contentHolder = Instance.new("Frame")
	contentHolder.Size = UDim2.new(1, -180, 1, -60)
	contentHolder.Position = UDim2.new(0, 162, 0, 48)
	contentHolder.BackgroundColor3 = Color3.fromRGB(16, 19, 25)
	contentHolder.BorderSizePixel = 0
	contentHolder.Parent = frame
	createCorner(contentHolder, 12)

	local pageNames = {"Main/Scripts", "Player Settings", "Script Settings", "Map Settings", "Pallet Settings", "Custom Keybinds", "Info & More"}
	for _, pageName in ipairs(pageNames) do
		local page, scroller = createScrolledPage(contentHolder)
		page.Name = pageName:gsub("%s", "") .. "Page"
		page.Visible = (pageName == "Main/Scripts")
		refs.pages[pageName] = {page = page, scroller = scroller}
	end
end

local function buildScriptsPage()
	local scroller = refs.pages["Main/Scripts"].scroller
	local layout = scroller:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout.Padding = UDim.new(0, 10)
	end

	for i, scriptInfo in ipairs(scripts) do
		if i == 4 then
			local separatorHolder = Instance.new("Frame")
			separatorHolder.Size = UDim2.new(1, -2, 0, 14)
			separatorHolder.BackgroundTransparency = 1
			separatorHolder.LayoutOrder = i
			separatorHolder.Parent = scroller

			local separatorLine = Instance.new("Frame")
			separatorLine.AnchorPoint = Vector2.new(0.5, 0.5)
			separatorLine.Position = UDim2.new(0.5, 0, 0.5, 0)
			separatorLine.Size = UDim2.new(1, -18, 0, 1)
			separatorLine.BackgroundColor3 = Color3.fromRGB(70, 78, 92)
			separatorLine.BorderSizePixel = 0
			separatorLine.Parent = separatorHolder
		end

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -2, 0, 54)
		row.BackgroundTransparency = 1
		row.LayoutOrder = i + (i >= 4 and 1 or 0)
		row.Parent = scroller

		local button = Instance.new("Frame")
		button.Size = UDim2.new(1, 0, 1, 0)
		button.BackgroundColor3 = Color3.fromRGB(30, 35, 44)
		button.BorderSizePixel = 0
		button.Parent = row
		createCorner(button, 10)

		createLabel(button, scriptInfo.Name, UDim2.new(1, -96, 0, 20), UDim2.new(0, 12, 0, 17))

		local function onTogglePressed()
			local ok, err = toggleScript(scriptInfo)
			if not ok and err then
				warn(scriptInfo.Name .. ": " .. tostring(err))
			end
		end

		if scriptInfo.CanStop then
			local track, knob = createToggle(button, UDim2.new(1, -70, 0.5, -15))
			track.MouseButton1Click:Connect(onTogglePressed)
			state.rowRefs[scriptInfo.Name] = {
				ToggleTrack = track,
				ToggleKnob = knob
			}
		else
			local actionButton = Instance.new("ImageButton")
			actionButton.Size = UDim2.new(0, 28, 0, 28)
			actionButton.AnchorPoint = Vector2.new(1, 0.5)
			actionButton.Position = UDim2.new(1, -14, 0.5, 0)
			actionButton.BackgroundTransparency = 1
			actionButton.BorderSizePixel = 0
			actionButton.AutoButtonColor = false
			actionButton.Image = "rbxassetid://96561699768956"
			actionButton.ImageTransparency = 0.2
			actionButton.ImageColor3 = Color3.fromRGB(205, 212, 224)
			actionButton.Parent = button
			actionButton.MouseButton1Click:Connect(onTogglePressed)

			local clickOverlay = Instance.new("TextButton")
			clickOverlay.Size = UDim2.new(1, 0, 1, 0)
			clickOverlay.BackgroundTransparency = 1
			clickOverlay.BorderSizePixel = 0
			clickOverlay.Text = ""
			clickOverlay.AutoButtonColor = false
			clickOverlay.Parent = button
			clickOverlay.MouseButton1Click:Connect(onTogglePressed)

			state.rowRefs[scriptInfo.Name] = {
				ActionButton = actionButton
			}
		end

		refreshRow(scriptInfo.Name)
	end

	local separatorHolder = Instance.new("Frame")
	separatorHolder.Size = UDim2.new(1, -2, 0, 14)
	separatorHolder.BackgroundTransparency = 1
	separatorHolder.LayoutOrder = 99
	separatorHolder.Parent = scroller

	local separatorLine = Instance.new("Frame")
	separatorLine.AnchorPoint = Vector2.new(0.5, 0.5)
	separatorLine.Position = UDim2.new(0.5, 0, 0.5, 0)
	separatorLine.Size = UDim2.new(1, -18, 0, 1)
	separatorLine.BackgroundColor3 = Color3.fromRGB(70, 78, 92)
	separatorLine.BorderSizePixel = 0
	separatorLine.Parent = separatorHolder

	local commandSection = createSection(scroller, 68, 100)
	refs.commandTitle = createLabel(commandSection, "Command Bar", UDim2.new(1, -20, 0, 20), UDim2.new(0, 12, 0, 8))
	refs.commandBox = createTextBox(commandSection, "Type command here", UDim2.new(1, -24, 0, 32), UDim2.new(0, 12, 0, 28), state.commandText)
end

local function buildPlayerPage()
	local scroller = refs.pages["Player Settings"].scroller
	local layout = scroller:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout.Padding = UDim.new(0, 8)
	end

	createResettableSliderSection(scroller, 1, "JumpPower", "player_jump", function()
		setJumpPower(24)
	end)

	createResettableSliderSection(scroller, 2, "Gravity", "player_gravity", function()
		setGravity(state.defaultGravity or 196.2)
	end)

	local noclipSection = createSection(scroller, 58, 3)
	createLabel(noclipSection, "Noclip", UDim2.new(1, -90, 0, 20), UDim2.new(0, 12, 0, 19))
	local noclipTrack, noclipKnob = createToggle(noclipSection, UDim2.new(1, -70, 0.5, -15))
	noclipTrack.MouseButton1Click:Connect(function()
		setNoclipEnabled(not noclipState.Enabled)
	end)
	refs.player.noclipTrack = noclipTrack
	refs.player.noclipKnob = noclipKnob

	local separatorHolder = Instance.new("Frame")
	separatorHolder.Size = UDim2.new(1, -2, 0, 14)
	separatorHolder.BackgroundTransparency = 1
	separatorHolder.LayoutOrder = 4
	separatorHolder.Parent = scroller

	local separatorLine = Instance.new("Frame")
	separatorLine.AnchorPoint = Vector2.new(0.5, 0.5)
	separatorLine.Position = UDim2.new(0.5, 0, 0.5, 0)
	separatorLine.Size = UDim2.new(1, -18, 0, 1)
	separatorLine.BackgroundColor3 = Color3.fromRGB(70, 78, 92)
	separatorLine.BorderSizePixel = 0
	separatorLine.Parent = separatorHolder

	local camSection = createSection(scroller, 58, 5)
	createLabel(camSection, "Camera Mode", UDim2.new(1, -90, 0, 20), UDim2.new(0, 12, 0, 19))
	local thirdTrack, thirdKnob = createToggle(camSection, UDim2.new(1, -70, 0.5, -15))
	thirdTrack.MouseButton1Click:Connect(function()
		setThirdPersonEnabled(not state.thirdPersonEnabled)
	end)
	refs.player.thirdTrack = thirdTrack
	refs.player.thirdKnob = thirdKnob

	createResettableSliderSection(scroller, 6, "FOV", "player_fov", function()
		state.targetFOV = 70
		if camera then
			camera.FieldOfView = state.targetFOV
		end
		refreshFovSliders()
		if state.saveSettings then
			saveSettingsToFile()
		end
	end)

	local respawnSection = createSection(scroller, 62, 7)
	local respawnButton = createButton(respawnSection, "Respawn", UDim2.new(1, -20, 0, 34), UDim2.new(0, 10, 0, 14))
	respawnButton.MouseButton1Click:Connect(function()
		local character = player.Character
		if character then
			character:BreakJoints()
		end
	end)
	styleButton(respawnButton)
end

local function createKeybindBox(parent, titleText, text, order, boxHeight, textBackHeight)
	local box = createSection(parent, boxHeight, order)
	createLabel(box, titleText, UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 10), Enum.Font.GothamBold, 14)

	local textBack = Instance.new("Frame")
	textBack.Size = UDim2.new(1, -20, 0, textBackHeight)
	textBack.Position = UDim2.new(0, 10, 0, 34)
	textBack.BackgroundColor3 = Color3.fromRGB(30, 35, 44)
	textBack.BorderSizePixel = 0
	textBack.Parent = box
	createCorner(textBack, 10)

	local textLabel = createLabel(textBack, text, UDim2.new(1, -12, 1, -12), UDim2.new(0, 6, 0, 6), Enum.Font.GothamSemibold, 13, Color3.fromRGB(176, 184, 198))
	textLabel.TextWrapped = true
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	return box
end

local function buildPlaceholderPage(pageName, titleText)
	local scroller = refs.pages[pageName].scroller
	local card = createSection(scroller, 88, 1)
	local title = createLabel(card, titleText, UDim2.new(1, -20, 0, 22), UDim2.new(0, 12, 0, 12), Enum.Font.GothamBold, 15)
	title.TextWrapped = true
	local body = createLabel(card, "Coming soon", UDim2.new(1, -20, 0, 18), UDim2.new(0, 12, 0, 46), Enum.Font.GothamSemibold, 13, Color3.fromRGB(176, 184, 198))
	body.TextWrapped = true
end

local function buildInfoPage()
	local scroller = refs.pages["Info & More"].scroller
	local layout = scroller:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout.Padding = UDim.new(0, 10)
	end

	createKeybindBox(
		scroller,
		"Freecam Keybinds",
		"• C = Toggle Freecam\n• Shift = Down In Freecam\n• Space = Up In Freecam\n• Middle Mouse = Reset Freecam Speed\n• Scroll Wheel = Change Freecam Speed",
		1,
		136,
		90
	)

	createKeybindBox(
		scroller,
		"KBM Input Display Keybinds",
		"• B = Toggles UI\n• G = Cycles Control Buttons\n• Enter = Use Selected Control Button\n• Backspace = Deselects Control Button\n• Shift + B = Reset UI",
		2,
		136,
		90
	)

	local separatorHolder = Instance.new("Frame")
	separatorHolder.Size = UDim2.new(1, -2, 0, 14)
	separatorHolder.BackgroundTransparency = 1
	separatorHolder.LayoutOrder = 3
	separatorHolder.Parent = scroller

	local separatorLine = Instance.new("Frame")
	separatorLine.AnchorPoint = Vector2.new(0.5, 0.5)
	separatorLine.Position = UDim2.new(0.5, 0, 0.5, 0)
	separatorLine.Size = UDim2.new(1, -18, 0, 1)
	separatorLine.BackgroundColor3 = Color3.fromRGB(70, 78, 92)
	separatorLine.BorderSizePixel = 0
	separatorLine.Parent = separatorHolder

	createKeybindBox(
		scroller,
		"Commands - All Commands Start With ;",
		"• goto / tp [player]\n• esp [player/@all]\n• unesp [player/@all]\n• view / lookat [player]\n• unview / unlookat\n• noclip\n• unnoclip\n• rj / rejoin\n• serverhop\n• respawn / reset",
		4,
		290,
		240
	)
end

local function buildSettingsPage()
	local scroller = refs.pages["Script Settings"].scroller

	local tpSection = createSection(scroller, 62, 1)
	local rejoinButton = createButton(tpSection, "Rejoin", UDim2.new(0.5, -16, 0, 34), UDim2.new(0, 10, 0, 14))
	local hopButton = createButton(tpSection, "Server Hop", UDim2.new(0.5, -16, 0, 34), UDim2.new(0.5, 6, 0, 14))
	styleButton(rejoinButton)
	styleButton(hopButton)
	rejoinButton.MouseButton1Click:Connect(rejoinServer)
	hopButton.MouseButton1Click:Connect(serverHop)

	local reexecSection = createSection(scroller, 58, 2)
	createLabel(reexecSection, "Re-Execute On Teleport", UDim2.new(1, -90, 0, 20), UDim2.new(0, 12, 0, 19))
	local reexecTrack, reexecKnob = createToggle(reexecSection, UDim2.new(1, -70, 0.5, -15))
	reexecTrack.MouseButton1Click:Connect(function()
		state.reExecuteOnTeleport = not state.reExecuteOnTeleport
		refreshSettingsToggles()
	end)
	refs.settings.reexecTrack = reexecTrack
	refs.settings.reexecKnob = reexecKnob

	local saveSection = createSection(scroller, 58, 3)
	createLabel(saveSection, "Save Settings", UDim2.new(1, -90, 0, 20), UDim2.new(0, 12, 0, 19))
	local saveTrack, saveKnob = createToggle(saveSection, UDim2.new(1, -70, 0.5, -15))
	saveTrack.MouseButton1Click:Connect(function()
		state.saveSettings = not state.saveSettings
		refreshSettingsToggles()
		persistCurrentSettings()
	end)
	refs.settings.saveTrack = saveTrack
	refs.settings.saveKnob = saveKnob

	createSliderSection(scroller, 4, "FPS Cap", "settings_fps")
	if refs.sliders["settings_fps"] then
		refs.sliders["settings_fps"].valueLabel.Position = UDim2.new(1, -72, 0, 10)
		refs.sliders["settings_fps"].valueLabel.Size = UDim2.new(0, 54, 0, 20)
	end
end

local function refreshTabs()
	for pageName, pack in pairs(refs.pages) do
		pack.page.Visible = (pageName == state.currentTab)
	end
	for tabName, button in pairs(refs.tabButtons) do
		local active = (tabName == state.currentTab)
		button.BackgroundColor3 = active and Color3.fromRGB(36, 42, 52) or Color3.fromRGB(26, 30, 38)
		button.TextColor3 = active and Color3.fromRGB(241, 244, 248) or Color3.fromRGB(205, 212, 224)
	end
end

local function scrollToCommandBar()
	task.wait()
	local section = refs.commandBox and refs.commandBox.Parent
	local scroller = refs.pages["Main/Scripts"] and refs.pages["Main/Scripts"].scroller
	if not section or not scroller then
		return
	end
	local y = section.AbsolutePosition.Y - scroller.AbsolutePosition.Y + scroller.CanvasPosition.Y - 8
	if y < 0 then
		y = 0
	end
	scroller.CanvasPosition = Vector2.new(0, y)
end

local function runCommand(rawText)
	local trimmed = tostring(rawText or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then
		return false, "empty command"
	end
	if string.sub(trimmed, 1, 1) ~= ";" then
		return false, "missing ;"
	end

	trimmed = string.sub(trimmed, 2):gsub("^%s+", ""):gsub("%s+$", "")
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

	if action == "esp" then
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

	if action == "unesp" then
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

	if action == "respawn" or action == "reset" then
		local character = player.Character
		if not character then
			return false, "character not ready"
		end
		character:BreakJoints()
		return true, "respawn"
	end

	if action == "noclip" then
		setNoclipEnabled(true)
		return true, "noclip"
	end

	if action == "unnoclip" then
		setNoclipEnabled(false)
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

	return false, "unknown command"
end

local function submitCommand()
	state.commandText = refs.commandBox and refs.commandBox.Text or ""
	local ok, message = runCommand(state.commandText)
	setCommandStatus(message)
	if ok and refs.commandBox then
		refs.commandBox.Text = ""
		state.commandText = ""
	end
end

local function bindSlider(sliderKey, setter)
	local slider = refs.sliders[sliderKey]
	if not slider then
		return
	end
	slider.track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			beginSliderDrag(sliderKey, setter, input)
		end
	end)
	slider.hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			beginSliderDrag(sliderKey, setter, input)
		end
	end)
end

local function safeBuild(name, callback)
	local ok, err = pcall(callback)
	if not ok then
		warn("Soggy Script Hub build error [" .. tostring(name) .. "]: " .. tostring(err))
	end
end

buildMainShell()
safeBuild("Main", buildScriptsPage)
safeBuild("Player Settings", buildPlayerPage)
safeBuild("Script Settings", buildSettingsPage)
safeBuild("Map Settings", function() buildPlaceholderPage("Map Settings", "Map Settings") end)
safeBuild("Pallet Settings", function() buildPlaceholderPage("Pallet Settings", "Pallet Settings") end)
safeBuild("Custom Keybinds", function() buildPlaceholderPage("Custom Keybinds", "Custom Keybinds") end)
safeBuild("Info", buildInfoPage)

for tabName, button in pairs(refs.tabButtons) do
	button.MouseButton1Click:Connect(function()
		state.currentTab = tabName
		refreshTabs()
	end)
end

bindSlider("settings_fps", function(alpha)
	local count = #state.fpsCapOptions
	state.fpsCapIndex = math.clamp(math.floor(alpha * (count - 1) + 0.5) + 1, 1, count)
	refreshFpsSliders()
	applyFpsCap()
	if state.saveSettings then
		saveSettingsToFile()
	end
end)

bindSlider("player_fov", function(alpha)
	state.targetFOV = math.clamp(math.floor((1 + 119 * alpha) + 0.5), 1, 120)
	if camera then
		camera.FieldOfView = state.targetFOV
	end
	refreshFovSliders()
	if state.saveSettings then
		saveSettingsToFile()
	end
end)


bindSlider("player_jump", function(alpha)
	setJumpPower(math.floor((300 * alpha) + 0.5))
end)

bindSlider("player_gravity", function(alpha)
	workspace.Gravity = math.clamp(math.floor((500 * alpha) + 0.5), 0, 500)
	refreshGravitySlider()
end)

if refs.commandBox then
	refs.commandBox.FocusLost:Connect(function(enterPressed)
		state.commandText = refs.commandBox.Text
		if enterPressed then
			submitCommand()
		end
	end)
end

setMenuOpen(refs.gui, true)
refreshTabs()
refreshSettingsToggles()
refreshThirdPersonToggles()
refreshNoclipToggles()
refreshFpsSliders()
refreshFovSliders()
refreshGravitySlider()
if camera then
	camera.FieldOfView = state.targetFOV
end
applyThirdPersonState()
applyFpsCap()
syncPlayerStatBoxes()
refreshAllRows()
persistCurrentSettings()

state.unlockMouseUntil = tick() + 3

refs.closeButton.MouseEnter:Connect(function()
	tween(refs.closeButton, {ImageTransparency = 0})
end)

refs.closeButton.MouseLeave:Connect(function()
	tween(refs.closeButton, {ImageTransparency = 0.15})
end)

refs.closeButton.MouseButton1Click:Connect(function()
	state.menuOpen = false
	if refs.commandBox and refs.commandBox:IsFocused() then
		refs.commandBox:ReleaseFocus(false)
	end
	setMenuOpen(refs.gui, false)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Tab then
		state.menuOpen = not state.menuOpen
		setMenuOpen(refs.gui, state.menuOpen)
		if state.menuOpen then
			state.unlockMouseUntil = tick() + 1
		end
		return
	elseif input.KeyCode == Enum.KeyCode.Semicolon then
		state.menuOpen = true
		setMenuOpen(refs.gui, true)
		state.unlockMouseUntil = tick() + 1
		state.currentTab = "Main/Scripts"
		refreshTabs()
		scrollToCommandBar()
		if refs.commandBox then
			refs.commandBox:CaptureFocus()
		end
		return
	end

	if refs.commandBox and refs.commandBox:IsFocused() then
		return
	end
	if gameProcessed then
		return
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if state.draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
		local alpha = math.clamp((input.Position.X - state.draggingSlider.track.AbsolutePosition.X) / state.draggingSlider.track.AbsoluteSize.X, 0, 1)
		state.draggingSlider.setter(alpha)
	end

	if state.draggingWindow and input.UserInputType == Enum.UserInputType.MouseMovement and state.dragStart and state.startPos then
		local delta = input.Position - state.dragStart
		refs.frame.Position = UDim2.new(
			state.startPos.X.Scale,
			state.startPos.X.Offset + delta.X,
			state.startPos.Y.Scale,
			state.startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		state.draggingSlider = nil
		state.draggingWindow = false
	end
end)

RunService.RenderStepped:Connect(function()
	if state.menuOpen or tick() < state.unlockMouseUntil then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end
end)

refs.topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		state.draggingWindow = true
		state.dragStart = input.Position
		state.startPos = refs.frame.Position
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

player.CharacterAdded:Connect(function()
	task.wait(0.2)
	applyThirdPersonState()
	refreshNoclipToggles()
	syncPlayerStatBoxes()
	if camera then
		camera.FieldOfView = state.targetFOV
	end
end)
