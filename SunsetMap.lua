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

if _G.StopSunsetMap then
    pcall(_G.StopSunsetMap)
end

_G.StopSunsetMap = function()
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

local sky = Instance.new("Sky")
sky.SkyboxBk = "rbxassetid://169210090"
sky.SkyboxDn = "rbxassetid://169210108"
sky.SkyboxFt = "rbxassetid://169210121"
sky.SkyboxLf = "rbxassetid://169210133"
sky.SkyboxRt = "rbxassetid://169210143"
sky.SkyboxUp = "rbxassetid://169210149"
sky.CelestialBodiesShown = false
sky.Parent = Lighting

Lighting.Technology = Enum.Technology.Future
Lighting.ClockTime = 6.14
Lighting.GeographicLatitude = -155
Lighting.Brightness = 2.5
Lighting.ExposureCompensation = 0.2
Lighting.Ambient = Color3.fromRGB(120, 80, 95)
Lighting.OutdoorAmbient = Color3.fromRGB(160, 110, 120)
Lighting.ColorShift_Top = Color3.fromRGB(255, 160, 150)
Lighting.ColorShift_Bottom = Color3.fromRGB(110, 60, 90)
Lighting.FogColor = Color3.fromRGB(255, 150, 140)
Lighting.FogStart = 0
Lighting.FogEnd = 1000000

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Color = Color3.fromRGB(255, 170, 150)
atmosphere.Decay = Color3.fromRGB(120, 70, 100)
atmosphere.Glare = 1.3
atmosphere.Haze = 2
atmosphere.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.6
bloom.Size = 45
bloom.Parent = Lighting

local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.18
sunRays.Spread = 0.9
sunRays.Parent = Lighting

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.05
colorCorrection.Contrast = 0.15
colorCorrection.Saturation = 0.15
colorCorrection.TintColor = Color3.fromRGB(255, 200, 190)
colorCorrection.Parent = Lighting

setOcean({
    Color = Color3.fromRGB(70, 85, 95),
    Material = Enum.Material.SmoothPlastic,
    Transparency = 0,
})

createLoopedSound(audioFolder, "Ambience", 2523360050, 0.3, 2, 100000)
local music = createMusicSound(audioFolder, "Music", 89272750877034)
startRandomizedMusic(music, 0.45, 2)
