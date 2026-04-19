local christmasVisualsConnections = {}

local function _SoggyDisconnectChristmasVisuals()
    for i = #christmasVisualsConnections, 1, -1 do
        local connection = christmasVisualsConnections[i]
        if connection and connection.Disconnect then
            pcall(function()
                connection:Disconnect()
            end)
        end
        christmasVisualsConnections[i] = nil
    end
end

local function _SoggyStopChristmasVisualsImpl()
    local Lighting = game:GetService("Lighting")
    local SoundService = game:GetService("SoundService")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    _SoggyDisconnectChristmasVisuals()

    local player = Players.LocalPlayer
    local playerGui = player and player:FindFirstChildOfClass("PlayerGui")

    local terrain = workspace:FindFirstChildOfClass("Terrain")
    local clouds = terrain and terrain:FindFirstChild("Clouds")
    if clouds then
        clouds.Cover = 0
        clouds.Density = 0
    end

    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere")
            or v:IsA("BloomEffect")
            or v:IsA("SunRaysEffect")
            or v:IsA("BlurEffect")
            or v:IsA("ColorCorrectionEffect")
            or v:IsA("Sky") then
            v:Destroy()
        end
    end

    Lighting.ClockTime = 14
    Lighting.Brightness = 2
    Lighting.ExposureCompensation = 0
    Lighting.ShadowSoftness = 0.2
    Lighting.Ambient = Color3.fromRGB(140, 140, 140)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.FogStart = 0
    Lighting.FogEnd = 100000
    Lighting.FogColor = Color3.fromRGB(192, 192, 192)
    Lighting.GlobalShadows = true

    local wind = SoundService:FindFirstChild("ChristmasWind")
    if wind then
        wind:Destroy()
    end

    if playerGui then
        local snowGui = playerGui:FindFirstChild("SnowGui")
        if snowGui then
            snowGui:Destroy()
        end
    end

    RunService:UnbindFromRenderStep("ChristmasSnowUpdate")
end

if _G.StopChristmasVisuals then
    pcall(_G.StopChristmasVisuals)
end

_G.StopChristmasVisuals = _SoggyStopChristmasVisualsImpl

_SoggyStopChristmasVisualsImpl()
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")



-- LIGHTING

for _, v in ipairs(Lighting:GetChildren()) do
	if v:IsA("Atmosphere")
		or v:IsA("BloomEffect")
		or v:IsA("SunRaysEffect")
		or v:IsA("BlurEffect")
		or v:IsA("ColorCorrectionEffect")
		or v:IsA("Sky") then
		v:Destroy()
	end
end

Lighting.ClockTime = 18.7
Lighting.Brightness = 1.8
Lighting.ExposureCompensation = -0.15
Lighting.ShadowSoftness = 0.2
Lighting.Ambient = Color3.fromRGB(45, 55, 80)
Lighting.OutdoorAmbient = Color3.fromRGB(110, 145, 180)

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.33
atmosphere.Color = Color3.fromRGB(130, 165, 195)
atmosphere.Decay = Color3.fromRGB(25, 30, 45)
atmosphere.Glare = 0
atmosphere.Haze = 1.6
atmosphere.Parent = Lighting

local color = Instance.new("ColorCorrectionEffect")
color.Brightness = -0.06
color.Contrast = 0.05
color.Saturation = -0.18
color.TintColor = Color3.fromRGB(170, 190, 255)
color.Parent = Lighting

local sky = Instance.new("Sky")
sky.SkyboxBk = "rbxassetid://225469345"
sky.SkyboxDn = "rbxassetid://225469349"
sky.SkyboxFt = "rbxassetid://225469359"
sky.SkyboxLf = "rbxassetid://225469364"
sky.SkyboxRt = "rbxassetid://225469372"
sky.SkyboxUp = "rbxassetid://225469380"
sky.CelestialBodiesShown = false
sky.Parent = Lighting

local terrain = workspace:FindFirstChildOfClass("Terrain")
if terrain then
	local clouds = terrain:FindFirstChild("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.66
	clouds.Density = 1
	clouds.Color = Color3.fromRGB(120, 130, 155)
	clouds.Parent = terrain
end



-- SNOW GUI

local oldSnowGui = PlayerGui:FindFirstChild("SnowGui")
if oldSnowGui then
	oldSnowGui:Destroy()
end

local snowGui = Instance.new("ScreenGui")
snowGui.Name = "SnowGui"
snowGui.IgnoreGuiInset = true
snowGui.ResetOnSpawn = false
snowGui.Parent = PlayerGui

local snowContainer = Instance.new("Frame")
snowContainer.Size = UDim2.fromScale(1, 1)
snowContainer.BackgroundTransparency = 1
snowContainer.Parent = snowGui

local SNOW_IMAGE = "rbxassetid://111395970734311"
local SNOW_GRID = 4
local SNOW_TOTAL = 16
local SNOW_FRAME_SIZE = 255
local SNOW_STEP = 255

local SNOW_COUNT = 15
local SNOW_MIN_SIZE = 15
local SNOW_MAX_SIZE = 35
local SNOW_MIN_SPEED = 35
local SNOW_MAX_SPEED = 75
local SNOW_MIN_DRIFT = 12
local SNOW_MAX_DRIFT = 40
local SNOW_MIN_FPS = 8
local SNOW_MAX_FPS = 12

local flakes = {}

local function setSnowFrame(img, frame)
	frame = (frame - 1) % SNOW_TOTAL
	local col = frame % SNOW_GRID
	local row = frame // SNOW_GRID

	img.ImageRectSize = Vector2.new(SNOW_FRAME_SIZE, SNOW_FRAME_SIZE)
	img.ImageRectOffset = Vector2.new(col * SNOW_STEP, row * SNOW_STEP)
end

local function rand(a, b)
	return a + math.random() * (b - a)
end

local function getViewport()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1920, 1080)
end

local function respawnFlake(flake, first)
	local vp = getViewport()

	flake.x = rand(0, vp.X)
	flake.y = first and rand(-vp.Y, 0) or rand(-60, -10)

	flake.size = rand(SNOW_MIN_SIZE, SNOW_MAX_SIZE)
	flake.speed = rand(SNOW_MIN_SPEED, SNOW_MAX_SPEED)
	flake.drift = rand(SNOW_MIN_DRIFT, SNOW_MAX_DRIFT)

	local t = (flake.size - SNOW_MIN_SIZE) / (SNOW_MAX_SIZE - SNOW_MIN_SIZE)
	flake.animSpeed = SNOW_MAX_FPS - t * (SNOW_MAX_FPS - SNOW_MIN_FPS)
	flake.animTimer = 0
	flake.frame = math.random(1, SNOW_TOTAL)

	flake.swayOffset = rand(0, math.pi * 2)
	flake.swaySpeed = rand(1, 2)
	flake.swayAmount = rand(3, 8)
	flake.life = 0

	flake.image.Size = UDim2.fromOffset(flake.size, flake.size)
	flake.image.ImageTransparency = rand(0.3, 0.6)

	setSnowFrame(flake.image, flake.frame)
end

for i = 1, SNOW_COUNT do
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	img.Image = SNOW_IMAGE
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Parent = snowContainer

	local flake = { image = img }
	respawnFlake(flake, true)
	table.insert(flakes, flake)
end



-- SOUNDS

local WIND_NAME = "ChristmasWind"
local WIND_SOUND_ID = "rbxassetid://138320690485163"
local WIND_VOLUME = 0.10
local WIND_ROLLOFF_MODE = Enum.RollOffMode.InverseTapered

local FOOTSTEPS = {
	{ id = "rbxassetid://135918121539048", vol = 2 },
	{ id = "rbxassetid://128551000876862", vol = 0.4 },
	{ id = "rbxassetid://108480745011651", vol = 2.5 },
}

local STEP_MIN = 0.7
local STEP_MAX = 0.9
local BASE_VOLUME = 0.35
local MAX_DIST = 7

local function createWind()
	local oldWind = SoundService:FindFirstChild(WIND_NAME)
	if oldWind then
		oldWind:Destroy()
	end

	local wind = Instance.new("Sound")
	wind.Name = WIND_NAME
	wind.SoundId = WIND_SOUND_ID
	wind.Looped = true
	wind.Volume = WIND_VOLUME
	wind.RollOffMode = WIND_ROLLOFF_MODE
	wind.Parent = SoundService
	wind:Play()
end

local function playFootstep(root, data)
	local sound = Instance.new("Sound")
	sound.SoundId = data.id
	sound.Volume = BASE_VOLUME * data.vol * (math.random(90, 110) / 100)
	sound.PlaybackSpeed = math.random(92, 108) / 100
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.MaxDistance = MAX_DIST
	sound.Parent = root
	sound:Play()

	task.delay(0.35, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

local function isOnMap(root)
	local map = workspace:FindFirstChild("Map")
	if not map then
		return false
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = { root.Parent }

	local result = workspace:Raycast(root.Position, Vector3.new(0, -6, 0), params)

	return result
		and result.Instance
		and result.Instance:IsDescendantOf(map)
end

local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")

	local lastIndex = 0
	local nextStepTime = 0

	table.insert(christmasVisualsConnections, RunService.Heartbeat:Connect(function()
		if not character.Parent then
			return
		end

		local state = humanoid:GetState()
		local grounded =
			state ~= Enum.HumanoidStateType.Freefall
			and state ~= Enum.HumanoidStateType.Jumping
			and state ~= Enum.HumanoidStateType.FallingDown
			and state ~= Enum.HumanoidStateType.Flying
			and state ~= Enum.HumanoidStateType.Swimming

		if not grounded or not isOnMap(root) then
			return
		end

		local velocity = Vector3.new(
			root.AssemblyLinearVelocity.X,
			0,
			root.AssemblyLinearVelocity.Z
		).Magnitude

		if humanoid.MoveDirection.Magnitude < 0.05 or velocity < 1 then
			return
		end

		local now = tick()
		if now < nextStepTime then
			return
		end

		local speedScale = math.clamp(velocity / 16, 0.35, 1.25)
		local interval = (math.random(STEP_MIN * 100, STEP_MAX * 100) / 100) / speedScale
		nextStepTime = now + interval

		local index = math.random(1, #FOOTSTEPS)
		if index == lastIndex then
			index = (index % #FOOTSTEPS) + 1
		end
		lastIndex = index

		playFootstep(root, FOOTSTEPS[index])
	end))
end

createWind()

if LocalPlayer.Character then
	setupCharacter(LocalPlayer.Character)
end

table.insert(christmasVisualsConnections, LocalPlayer.CharacterAdded:Connect(setupCharacter))



-- SNOW UPDATE LOOP

RunService:BindToRenderStep("ChristmasSnowUpdate", Enum.RenderPriority.Last.Value, function(dt)
	local vp = getViewport()

	for _, flake in ipairs(flakes) do
		flake.life += dt
		flake.y += flake.speed * dt
		flake.x += flake.drift * dt

		local sway = math.sin(flake.life * flake.swaySpeed + flake.swayOffset) * flake.swayAmount

		flake.animTimer += dt
		if flake.animTimer >= 1 / flake.animSpeed then
			flake.animTimer = 0
			flake.frame += 1
			setSnowFrame(flake.image, flake.frame)
		end

		if flake.y > vp.Y + 20 then
			respawnFlake(flake, false)
		else
			flake.image.Position = UDim2.fromOffset(flake.x + sway, flake.y)
		end
	end
end)
