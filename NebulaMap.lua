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

if _G.StopNebulaMap then
    pcall(_G.StopNebulaMap)
end

_G.StopNebulaMap = function()
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

local STAR_TEXTURES = {
    {Id = "rbxassetid://7216848699", Name = "SixPointStar", Weight = 30},
    {Id = "rbxassetid://7216853637", Name = "GlowStar", Weight = 25},
    {Id = "rbxassetid://7216849075", Name = "SoftStar", Weight = 25},
    {Id = "rbxassetid://7216848960", Name = "SharpStar", Weight = 20},
}

local STAR_COUNT = 30
local BRIGHT_STAR_CHANCE = 0.22
local STAR_GLOW_PULSE_TIME = 0.22
local STAR_GLOW_SCALE = 1.35
local MUSIC_ID = 140533822783920
local MUSIC_VOLUME = 0.42
local MUSIC_LOOP_TIME = 36
local MUSIC_CROSSFADE_TIME = 2.2

local function chooseWeightedStar()
    local totalWeight = 0
    for _, star in ipairs(STAR_TEXTURES) do
        totalWeight += star.Weight
    end

    local roll = math.random(1, totalWeight)
    local running = 0

    for _, star in ipairs(STAR_TEXTURES) do
        running += star.Weight
        if roll <= running then
            return star
        end
    end

    return STAR_TEXTURES[1]
end

local function getStarSize(starName, brightStar)
    if starName == "SixPointStar" then
        return brightStar and math.random(16, 24) or math.random(27, 38)
    elseif starName == "GlowStar" then
        return brightStar and math.random(15, 23) or math.random(22, 34)
    elseif starName == "SoftStar" then
        return brightStar and math.random(14, 21) or math.random(21, 33)
    elseif starName == "SharpStar" then
        return brightStar and math.random(13, 20) or math.random(20, 32)
    end

    return brightStar and math.random(14, 22) or math.random(20, 32)
end

local function getStarColor(brightStar)
    if brightStar then
        local colors = {
            Color3.fromRGB(255, 245, 255),
            Color3.fromRGB(220, 235, 255),
            Color3.fromRGB(255, 220, 255),
        }
        return colors[math.random(1, #colors)]
    end

    local colors = {
        Color3.fromRGB(170, 220, 255),
        Color3.fromRGB(235, 170, 255),
        Color3.fromRGB(255, 210, 250),
        Color3.fromRGB(190, 215, 255),
    }
    return colors[math.random(1, #colors)]
end

local function randomizeStar(data)
    data.screenX = math.random(2, 98) / 100
    data.screenY = math.random(2, 98) / 100
    data.phaseX = math.random() * math.pi * 2
    data.phaseY = math.random() * math.pi * 2
    data.idleX = math.random(-100, 100) / 10000
    data.idleY = math.random(-100, 100) / 10000
end

local sky = Instance.new("Sky")
sky.SkyboxBk = "rbxassetid://129876530632297"
sky.SkyboxDn = "rbxassetid://108406529909981"
sky.SkyboxFt = "rbxassetid://104400530594543"
sky.SkyboxLf = "rbxassetid://73372229972523"
sky.SkyboxRt = "rbxassetid://87408857415924"
sky.SkyboxUp = "rbxassetid://137817405681365"
sky.CelestialBodiesShown = false
sky.Parent = Lighting

Lighting.Ambient = Color3.fromRGB(58, 28, 108)
Lighting.OutdoorAmbient = Color3.fromRGB(118, 66, 168)
Lighting.Brightness = 1.55
Lighting.ColorShift_Top = Color3.fromRGB(210, 110, 255)
Lighting.ColorShift_Bottom = Color3.fromRGB(32, 12, 72)
Lighting.EnvironmentDiffuseScale = 0.42
Lighting.EnvironmentSpecularScale = 0.38
Lighting.ShadowSoftness = 0.9
Lighting.ClockTime = 14
Lighting.ExposureCompensation = 0.22
Lighting.FogColor = Color3.fromRGB(18, 0, 34)
Lighting.FogStart = 3500
Lighting.FogEnd = 18000

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 2.15
bloom.Size = 48
bloom.Threshold = 0.78
bloom.Parent = Lighting

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.03
colorCorrection.Contrast = 0.26
colorCorrection.Saturation = 0.28
colorCorrection.TintColor = Color3.fromRGB(255, 185, 255)
colorCorrection.Parent = Lighting

local blur = Instance.new("BlurEffect")
blur.Size = 1
blur.Parent = Lighting

setOcean({
    Transparency = 1,
})

local musicA = createMusicSound(audioFolder, "MusicA", MUSIC_ID)
local musicB = createMusicSound(audioFolder, "MusicB", MUSIC_ID)

musicA:Play()
fadeSound(musicA, MUSIC_VOLUME, MUSIC_CROSSFADE_TIME)

task.spawn(function()
    local active = musicA
    local inactive = musicB

    while audioFolder.Parent do
        if not active.IsPlaying then
            active.TimePosition = 0
            active.Volume = 0
            active:Play()
            fadeSound(active, MUSIC_VOLUME, MUSIC_CROSSFADE_TIME)
        end

        if active.TimePosition >= MUSIC_LOOP_TIME - MUSIC_CROSSFADE_TIME then
            inactive:Stop()
            inactive.TimePosition = 0
            inactive.Volume = 0
            inactive:Play()

            fadeSound(active, 0, MUSIC_CROSSFADE_TIME)
            fadeSound(inactive, MUSIC_VOLUME, MUSIC_CROSSFADE_TIME)

            task.wait(MUSIC_CROSSFADE_TIME)

            if active.Parent then
                active:Stop()
            end

            active, inactive = inactive, active
        else
            task.wait(0.1)
        end
    end
end)

if playerGui then
    local starGui = Instance.new("ScreenGui")
    starGui.Name = MAP_STAR_GUI
    starGui.IgnoreGuiInset = true
    starGui.ResetOnSpawn = false
    starGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    starGui.Parent = playerGui

    local starData = {}

    for _ = 1, STAR_COUNT do
        local brightStar = math.random() < BRIGHT_STAR_CHANCE
        local chosenStar = chooseWeightedStar()
        local size = getStarSize(chosenStar.Name, brightStar)
        local transparency = brightStar and math.random(5, 12) / 100 or math.random(18, 28) / 100
        local color = getStarColor(brightStar)
        local rotation = math.random(0, 360)

        local image = Instance.new("ImageLabel")
        image.Name = chosenStar.Name
        image.BackgroundTransparency = 1
        image.Image = chosenStar.Id
        image.ImageColor3 = color
        image.ImageTransparency = 1
        image.Size = UDim2.fromOffset(size, size)
        image.AnchorPoint = Vector2.new(0.5, 0.5)
        image.ZIndex = 10
        image.Rotation = rotation
        image.Parent = starGui

        local glow = Instance.new("ImageLabel")
        glow.Name = "Glow"
        glow.BackgroundTransparency = 1
        glow.Image = chosenStar.Id
        glow.ImageColor3 = color:Lerp(Color3.new(1, 1, 1), 0.35)
        glow.ImageTransparency = 1
        glow.Size = UDim2.fromOffset(math.floor(size * 1.35), math.floor(size * 1.35))
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.ZIndex = 9
        glow.Rotation = rotation
        glow.Parent = starGui

        local data = {
            image = image,
            glow = glow,
            baseSize = size,
            baseTransparency = transparency,
            glowBaseTransparency = math.clamp(transparency + (brightStar and 0.32 or 0.4), 0, 1),
            parallax = brightStar and math.random(10, 15) / 10 or math.random(6, 10) / 10,
            swayAmount = brightStar and math.random(8, 12) / 1000 or math.random(4, 8) / 1000,
            driftSpeedX = math.random(7, 12) / 100,
            driftSpeedY = math.random(5, 10) / 100,
            screenX = 0.5,
            screenY = 0.5,
            phaseX = 0,
            phaseY = 0,
            idleX = 0,
            idleY = 0,
        }

        randomizeStar(data)
        image.Position = UDim2.fromScale(data.screenX, data.screenY)
        glow.Position = image.Position
        starData[#starData + 1] = data
    end

    local lastCameraCFrame = workspace.CurrentCamera and workspace.CurrentCamera.CFrame
    local smoothYaw = 0
    local smoothPitch = 0

    RunService:BindToRenderStep(MAP_STAR_BIND, Enum.RenderPriority.Camera.Value + 1, function(dt)
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local viewport = camera.ViewportSize
        local currentCFrame = camera.CFrame
        local t = tick()
        local yawDelta = 0
        local pitchDelta = 0

        if lastCameraCFrame then
            local currentLook = currentCFrame.LookVector
            local lastLook = lastCameraCFrame.LookVector
            local delta = currentLook - lastLook
            yawDelta = delta.X
            pitchDelta = delta.Y
        end

        lastCameraCFrame = currentCFrame

        local smoothing = math.clamp(dt * 5, 0, 1)
        smoothYaw += (yawDelta - smoothYaw) * smoothing
        smoothPitch += (pitchDelta - smoothPitch) * smoothing

        for _, data in ipairs(starData) do
            local idleOffsetX = math.sin(t * data.driftSpeedX + data.phaseX) * data.swayAmount + data.idleX
            local idleOffsetY = math.cos(t * data.driftSpeedY + data.phaseY) * data.swayAmount + data.idleY
            local moveOffsetX = -smoothYaw * 90 * data.parallax * data.swayAmount
            local moveOffsetY = smoothPitch * 90 * data.parallax * data.swayAmount
            local px = math.clamp((data.screenX + idleOffsetX + moveOffsetX) * viewport.X, 0, viewport.X)
            local py = math.clamp((data.screenY + idleOffsetY + moveOffsetY) * viewport.Y, 0, viewport.Y)
            local pos = UDim2.fromOffset(px, py)
            data.image.Position = pos
            data.glow.Position = pos
        end
    end)

    for _, data in ipairs(starData) do
        task.spawn(function()
            while data.image.Parent and data.glow.Parent and visualFolder.Parent do
                randomizeStar(data)

                local fadeInTime = math.random(35, 60) / 100
                local visibleTime = math.random(120, 220) / 100
                local fadeOutTime = math.random(50, 80) / 100
                local hiddenTime = math.random(35, 100) / 100

                local start = tick()
                while data.image.Parent and data.glow.Parent and tick() - start < fadeInTime do
                    local alpha = (tick() - start) / fadeInTime
                    data.image.ImageTransparency = 1 - (1 - data.baseTransparency) * alpha
                    data.glow.ImageTransparency = 1 - (1 - data.glowBaseTransparency) * alpha
                    RunService.RenderStepped:Wait()
                end

                if not data.image.Parent or not data.glow.Parent then
                    break
                end

                data.image.ImageTransparency = data.baseTransparency
                data.glow.ImageTransparency = data.glowBaseTransparency
                data.image.Size = UDim2.fromOffset(data.baseSize, data.baseSize)
                data.glow.Size = UDim2.fromOffset(math.floor(data.baseSize * 1.35), math.floor(data.baseSize * 1.35))

                task.wait(visibleTime)

                if not data.image.Parent or not data.glow.Parent then
                    break
                end

                local pulseImageSize = math.floor(data.baseSize * STAR_GLOW_SCALE)
                local pulseGlowSize = math.floor(data.baseSize * 1.35 * STAR_GLOW_SCALE)

                TweenService:Create(
                    data.image,
                    TweenInfo.new(STAR_GLOW_PULSE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                    {
                        ImageTransparency = math.max(0, data.baseTransparency - 0.18),
                        Size = UDim2.fromOffset(pulseImageSize, pulseImageSize),
                    }
                ):Play()

                TweenService:Create(
                    data.glow,
                    TweenInfo.new(STAR_GLOW_PULSE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                    {
                        ImageTransparency = math.max(0, data.glowBaseTransparency - 0.28),
                        Size = UDim2.fromOffset(pulseGlowSize, pulseGlowSize),
                    }
                ):Play()

                task.wait(STAR_GLOW_PULSE_TIME)

                start = tick()
                while data.image.Parent and data.glow.Parent and tick() - start < fadeOutTime do
                    local alpha = (tick() - start) / fadeOutTime
                    data.image.ImageTransparency = data.baseTransparency + (1 - data.baseTransparency) * alpha
                    data.glow.ImageTransparency = data.glowBaseTransparency + (1 - data.glowBaseTransparency) * alpha
                    RunService.RenderStepped:Wait()
                end

                if not data.image.Parent or not data.glow.Parent then
                    break
                end

                data.image.ImageTransparency = 1
                data.glow.ImageTransparency = 1
                data.image.Size = UDim2.fromOffset(data.baseSize, data.baseSize)
                data.glow.Size = UDim2.fromOffset(math.floor(data.baseSize * 1.35), math.floor(data.baseSize * 1.35))

                task.wait(hiddenTime)
            end
        end)
    end
end
