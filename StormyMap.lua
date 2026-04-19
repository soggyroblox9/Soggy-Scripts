local function _SoggyMapCommonCleanup(removeSnowGui)
    local Lighting = game:GetService("Lighting")
    local SoundService = game:GetService("SoundService")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")

    local player = Players.LocalPlayer
    local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    local clouds = terrain and terrain:FindFirstChild("Clouds")

    for _, name in ipairs({
        "SoggyMapAudio", "SoggyMapVisuals", "SoggyMapStarGui", "SpaceNebulaStars", "SnowGui"
    }) do
        if name ~= "SnowGui" or removeSnowGui then
            local obj = SoundService:FindFirstChild(name)
                or Lighting:FindFirstChild(name)
                or workspace:FindFirstChild(name)
                or (playerGui and playerGui:FindFirstChild(name))
            if obj then
                obj:Destroy()
            end
        end
    end

    for _, name in ipairs({
        "SoggyAmbience", "SoggyMusic", "SoggyMapOneShot",
        "CloudyAmbientSound", "CloudyMusic",
        "StormMusicLoop", "StormThunderSound", "StormRainLoop", "StormWindLoop",
        "SunriseMusic", "SunriseOceanWaves",
        "SpaceNebulaAudio", "SunsetAmbienceSounds",
        "ChristmasWind"
    }) do
        local obj = SoundService:FindFirstChild(name) or workspace:FindFirstChild(name)
        if obj then
            obj:Destroy()
        end
    end

    RunService:UnbindFromRenderStep("SoggyMapStarBind")
    RunService:UnbindFromRenderStep("SpaceNebulaStarFollow")

    if clouds then
        clouds.Cover = 0
        clouds.Density = 0
    end
end


local function _SoggyResetLightingToPlayableDefault()
    local Lighting = game:GetService("Lighting")
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
end

if _G.StopStormyMap then
    pcall(_G.StopStormyMap)
end

_G.StopStormyMap = function()
    _SoggyMapCommonCleanup(false)
    _SoggyResetLightingToPlayableDefault()
end

_SoggyMapCommonCleanup(false)
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local MAP_AUDIO_FOLDER = "SoggyMapAudio"
local MAP_VISUAL_FOLDER = "SoggyMapVisuals"
local MAP_STAR_GUI = "SoggyMapStarGui"
local MAP_STAR_BIND = "SoggyMapStarBind"

local terrain = workspace:FindFirstChildOfClass("Terrain")
local clouds = terrain and terrain:FindFirstChild("Clouds")
local player = Players.LocalPlayer
local playerGui = player and player:FindFirstChildOfClass("PlayerGui")

local function getOceanRoot()
    local map = workspace:FindFirstChild("Map")
    local alwaysHere = map and map:FindFirstChild("AlwaysHereTweenedObjects")
    local ocean = alwaysHere and alwaysHere:FindFirstChild("Ocean")
    local object = ocean and ocean:FindFirstChild("Object")
    local objectModel = object and object:FindFirstChild("ObjectModel")
    return objectModel or object
end

local oceanRoot = getOceanRoot()

local function tweenNumber(instance, property, value, duration)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        {[property] = value}
    )
    tween:Play()
    return tween
end

local function fadeSound(sound, targetVolume, duration)
    return tweenNumber(sound, "Volume", targetVolume, duration)
end

local function clearLighting()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky")
            or obj:IsA("Atmosphere")
            or obj:IsA("BloomEffect")
            or obj:IsA("SunRaysEffect")
            or obj:IsA("ColorCorrectionEffect")
            or obj:IsA("BlurEffect")
            or obj:IsA("DepthOfFieldEffect") then
            obj:Destroy()
        end
    end
end

local function clearAudio()
    local folder = SoundService:FindFirstChild(MAP_AUDIO_FOLDER)
    if folder then
        folder:Destroy()
    end
end

local function clearVisuals()
    local folder = workspace:FindFirstChild(MAP_VISUAL_FOLDER)
    if folder then
        folder:Destroy()
    end

    if playerGui then
        local starGui = playerGui:FindFirstChild(MAP_STAR_GUI)
        if starGui then
            starGui:Destroy()
        end
    end

    RunService:UnbindFromRenderStep(MAP_STAR_BIND)
end

local function resetClouds()
    if clouds then
        clouds.Density = 0
        clouds.Cover = 0
    end
end

local function setOcean(props)
    if not oceanRoot then
        return
    end

    for _, part in ipairs(oceanRoot:GetDescendants()) do
        if part:IsA("BasePart") and part.Name == "Ocean" then
            if props.Color then
                part.Color = props.Color
            end
            if props.Material then
                part.Material = props.Material
            end
            if props.Transparency ~= nil then
                part.Transparency = props.Transparency
            end
        end
    end
end

local function createAudioFolder()
    local folder = Instance.new("Folder")
    folder.Name = MAP_AUDIO_FOLDER
    folder.Parent = SoundService
    return folder
end

local function createVisualFolder()
    local folder = Instance.new("Folder")
    folder.Name = MAP_VISUAL_FOLDER
    folder.Parent = workspace
    return folder
end

local function createLoopedSound(parent, name, soundId, targetVolume, fadeTime, rollOffMaxDistance)
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = "rbxassetid://" .. tostring(soundId)
    sound.Volume = 0
    sound.Looped = true
    sound.RollOffMaxDistance = rollOffMaxDistance or 100000
    sound.RollOffMode = Enum.RollOffMode.Inverse
    sound.Parent = parent
    sound:Play()
    fadeSound(sound, targetVolume, fadeTime)
    return sound
end

local function createMusicSound(parent, name, soundId)
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = "rbxassetid://" .. tostring(soundId)
    sound.Volume = 0
    sound.Looped = false
    sound.RollOffMaxDistance = 100000
    sound.RollOffMode = Enum.RollOffMode.Inverse
    sound.Parent = parent
    return sound
end

local function startRandomizedMusic(sound, targetVolume, fadeTime)
    local function play()
        if not sound.Parent then
            return
        end

        if sound.TimeLength > 1 then
            sound.TimePosition = math.random() * (sound.TimeLength - 1)
        else
            sound.TimePosition = 0
        end

        sound.Volume = 0
        sound:Play()
        fadeSound(sound, targetVolume, fadeTime)
    end

    sound.Loaded:Connect(play)
    sound.Ended:Connect(play)

    task.delay(2, function()
        if sound.Parent and not sound.IsPlaying then
            play()
        end
    end)

    return sound
end

clearAudio()
clearVisuals()
clearLighting()
resetClouds()

local audioFolder = createAudioFolder()
local visualFolder = createVisualFolder()
local camera = workspace.CurrentCamera

local sky = Instance.new("Sky")
sky.SkyboxBk = "rbxassetid://149679669"
sky.SkyboxDn = "rbxassetid://149681979"
sky.SkyboxFt = "rbxassetid://149679690"
sky.SkyboxLf = "rbxassetid://149679709"
sky.SkyboxRt = "rbxassetid://149679722"
sky.SkyboxUp = "rbxassetid://149680199"
sky.CelestialBodiesShown = false
sky.Parent = Lighting

local atmosphere = Instance.new("Atmosphere")
atmosphere.Color = Color3.fromRGB(112, 122, 136)
atmosphere.Decay = Color3.fromRGB(64, 70, 78)
atmosphere.Density = 0.34
atmosphere.Offset = 0
atmosphere.Glare = 0
atmosphere.Haze = 1.7
atmosphere.Parent = Lighting

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.65
colorCorrection.Contrast = 1.4
colorCorrection.Saturation = -0.12
colorCorrection.TintColor = Color3.fromRGB(205, 215, 230)
colorCorrection.Parent = Lighting

Lighting.Technology = Enum.Technology.Future
Lighting.Ambient = Color3.fromRGB(52, 58, 68)
Lighting.OutdoorAmbient = Color3.fromRGB(70, 76, 88)
Lighting.Brightness = 0.42
Lighting.ColorShift_Top = Color3.fromRGB(18, 20, 24)
Lighting.ColorShift_Bottom = Color3.fromRGB(10, 12, 16)
Lighting.EnvironmentDiffuseScale = 0.25
Lighting.EnvironmentSpecularScale = 0.1
Lighting.ShadowSoftness = 0.9
Lighting.ClockTime = 13
Lighting.ExposureCompensation = -0.3
Lighting.FogColor = Color3.fromRGB(88, 98, 112)
Lighting.FogStart = 800
Lighting.FogEnd = 2000

setOcean({
    Color = Color3.fromRGB(56, 66, 78),
    Transparency = 0,
})

local thunder = Instance.new("Sound")
thunder.Name = "Thunder"
thunder.SoundId = "rbxassetid://139319051979882"
thunder.Volume = 0.65
thunder.Looped = false
thunder.RollOffMaxDistance = 500
thunder.RollOffMode = Enum.RollOffMode.Inverse
thunder.Parent = audioFolder

createLoopedSound(audioFolder, "Rain", 5911952995, 0.28, 2, 100000)
createLoopedSound(audioFolder, "Wind", 93035214379043, 0.22, 2, 100000)
createLoopedSound(audioFolder, "Music", 88733565266906, 0.18, 2, 100000)

local shaking = false
local shakeConnection
local thunderBusy = false

local function cleanupShake()
    if shakeConnection then
        shakeConnection:Disconnect()
        shakeConnection = nil
    end
    shaking = false
end

local function doScreenShake()
    if shaking then
        return
    end

    shaking = true
    local duration = 0.35
    local elapsed = 0

    shakeConnection = RunService.RenderStepped:Connect(function(dt)
        if not camera or not camera.Parent then
            cleanupShake()
            return
        end

        elapsed += dt
        local alpha = math.clamp(elapsed / duration, 0, 1)
        local strength = (1 - alpha) * 0.35

        camera.CFrame = camera.CFrame * CFrame.new(
            (math.random() - 0.5) * strength,
            (math.random() - 0.5) * strength,
            (math.random() - 0.5) * strength * 0.15
        )

        if alpha >= 1 then
            cleanupShake()
        end
    end)
end

local function doLightningFlash()
    local baseBrightness = Lighting.Brightness
    Lighting.Brightness = baseBrightness + 3.2
    task.wait(0.045)
    Lighting.Brightness = baseBrightness + 1.2
    task.wait(0.035)
    Lighting.Brightness = baseBrightness + 2.4
    task.wait(0.05)
    Lighting.Brightness = baseBrightness
end

local function playThunder()
    if thunderBusy then
        return
    end

    thunderBusy = true
    thunder.PlaybackSpeed = math.random(92, 108) / 100
    thunder.TimePosition = 0
    thunder:Play()
    doScreenShake()
    doLightningFlash()
    thunderBusy = false
end

task.spawn(function()
    while audioFolder.Parent and visualFolder.Parent do
        task.wait(math.random(9, 16))
        playThunder()
    end
end)
