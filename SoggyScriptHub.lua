local Players        = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService     = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService    = game:GetService("HttpService")
local SoundService   = game:GetService("SoundService")
local Lighting       = game:GetService("Lighting")
local GuiService     = game:GetService("GuiService")

local SETTINGS_FILE      = "SoggyScriptHub_Settings.json"
local MENU_LOADSTRING_URL = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/SoggyScriptHub.lua"

local TWEEN_SHORT = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_FAST  = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED   = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera
local placeId   = game.PlaceId
local jobId     = game.JobId

local fnSetFpsCap  = setfpscap  or set_fps_cap  or (syn and syn.setfpscap)
local fnReadFile   = readfile   or (syn and syn.readfile)
local fnWriteFile  = writefile  or (syn and syn.writefile)
local fnIsFile     = isfile     or (syn and syn.isfile)
local fnDelFile    = delfile    or (syn and syn.delfile)
local fnQueueTp    = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
local fnRequest    = syn and syn.request or http_request or request or (http and http.request) or (fluxus and fluxus.request)

local SCRIPTS = {
	{
		Name = "Speedometer", CanStop = true,
		Url  = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/SpeedometerDisplay.lua",
		Action = function(self) loadstring(game:HttpGet(self.Url))() end,
		Stop   = function() if _G.StopSpeedometer then _G.StopSpeedometer() end end,
	},
	{
		Name = "KBMInputDisplay", CanStop = true,
		Url  = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/KBMInputDisplay.lua",
		Action = function(self) loadstring(game:HttpGet(self.Url))() end,
		Stop   = function() if _G.StopKBMInputDisplay then _G.StopKBMInputDisplay() end end,
	},
	{
		Name = "Infinite Yield", CanStop = false,
		Url  = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
		Action = function(self) loadstring(game:HttpGet(self.Url))() end,
	},
	{
		Name = "Dex++ Explorer", CanStop = false,
		Url  = "https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua",
		Action = function(self) loadstring(game:HttpGet(self.Url))() end,
	},
}

local MAP_PRESET_ORDER = { "BlueNight","RedNight","Sunrise","Sunset","Cloudy","Stormy","Nebula" }

local MAP_PRESET = {
	BlueNight = {
		DisplayName = "Blue Night",
		Image  = "rbxassetid://109672038801876",
		Url    = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/BlueNightMap.lua",
		StopFn = "StopBlueNightMap",
	},
	RedNight = {
		DisplayName = "Red Night",
		Image  = "rbxassetid://114519832278035",
		Url    = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/RedNightMap.lua",
		StopFn = "StopRedNightMap",
	},
	Sunrise = {
		DisplayName = "Sunrise",
		Image  = "rbxassetid://124757791368556",
		Url    = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/SunriseMap.lua",
		StopFn = "StopSunriseMap",
	},
	Sunset = {
		DisplayName = "Sunset",
		Image  = "rbxassetid://70657743268267",
		Url    = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/SunsetMap.lua",
		StopFn = "StopSunsetMap",
	},
	Cloudy = {
		DisplayName = "Cloudy",
		Image  = "rbxassetid://95169366883606",
		Url    = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/CloudyMap.lua",
		StopFn = "StopCloudyMap",
	},
	Stormy = {
		DisplayName = "Stormy(WIP)",
		Image  = "rbxassetid://71636238856733",
		Url    = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/StormyMap.lua",
		StopFn = "StopStormyMap",
	},
	Nebula = {
		DisplayName = "Nebula",
		Image  = "rbxassetid://136867789406475",
		Url    = "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/NebulaMap.lua",
		StopFn = "StopNebulaMap",
	},
}

local MANAGED_AUDIO_NAMES = {
	"SoggyAmbience","SoggyMusic","SoggyMapOneShot",
	"CloudyAmbientSound","CloudyMusic",
	"StormThunderSound","StormRainLoop","StormWindLoop","StormMusicLoop",
	"SunriseMusic","SunriseOceanWaves","SoggyMapAudio",
}
local MANAGED_FOLDER_NAMES = {
	"SpaceNebulaAudio","SunsetAmbienceSounds","SoggyMapVisuals",
}

local FPS_CAP_OPTIONS = {60, 120, 144, 180, 200, 240, 0}
local FPS_CAP_LABELS  = {"60","120","144","180","200","240","240+"}

local state = {
	reExecuteOnTeleport    = true,
	saveSettings           = true,
	targetFOV              = math.floor(((camera and camera.FieldOfView) or 70) + 0.5),
	fpsCapIndex            = 1,
	thirdPersonEnabled     = false,

	defaultFOV             = math.floor(((camera and camera.FieldOfView) or 70) + 0.5),
	defaultGravity         = workspace.Gravity,
	defaultClockTime       = game:GetService("Lighting").ClockTime,
	todLocked              = false,
	defaultMinZoom         = player.CameraMinZoomDistance,
	defaultMaxZoom         = player.CameraMaxZoomDistance,

	currentTab             = "Main/Displays",
	menuOpen               = true,
	unlockMouseUntil       = 0,
	commandText            = "",
	commandStatusToken     = 0,

	draggingSlider         = nil,
	draggingWindow         = false,
	dragStart              = nil,
	startPos               = nil,

	activeScripts          = {},
	rowRefs                = {},

	currentMapPreset       = nil,
	activeFTAPMap          = nil,     
	resetMapAmbienceActive = true,
	mapEffectsMuted        = false,
	ftapDefaultAmbienceEnabled = false,
}

local refs = {
	gui         = nil,
	frame       = nil,
	topBar      = nil,
	closeButton = nil,
	commandBox  = nil,
	commandTitle = nil,
	pages       = {},  
	tabButtons  = {},  
	sliders     = {},  
	player      = {},  
	settings    = {},  
	map         = {},  
}

local noclip = { enabled = false, connection = nil }
local view   = { target = nil }
local esp    = {
	objects             = {},  
	tracked             = {},  
	allEnabled          = false,
	playerAddedConn     = nil,
	charConns           = {},  
}

local ftapState = {
	scriptsLoaded    = false,
	propsLoaded      = false,
	ambienceClone    = nil,
	ambienceConns    = {},
}

local mapSnapshot = {
	taken = false,
	lightingProps    = {},
	lightingChildren = {},
	clouds           = nil,
	oceanStates      = {},
}

local PALLET_TARGET_NAME  = "PalletLightBrown"
local PALLET_PRESET_FILE  = "pallet_presets.json"
local PALLET_APPLY_RATE   = 1 / 30
local PALLET_DEFAULT_PRESETS = {
	{ name="Black Pallet", r=27, g=42, b=53, material="WoodPlanks" },
	{ name="White Pallet", r=231, g=231, b=236, material="WoodPlanks" },
	{ name="DiamondPallet", r=77, g=207, b=255, material="Glass", special="DiamondPallet" },
}
local PALLET_RESTORE_ICON = "rbxassetid://116604835627941"
local PALLET_DIAMOND_EMITTER = "SoggyDiamondPalletEmitter"

local palletMaterialOptions = {
	{ Name="Plastic",        Material=Enum.Material.Plastic        },
	{ Name="SmoothPlastic",  Material=Enum.Material.SmoothPlastic  },
	{ Name="Neon",           Material=Enum.Material.Neon           },
	{ Name="Wood",           Material=Enum.Material.Wood           },
	{ Name="WoodPlanks",     Material=Enum.Material.WoodPlanks     },
	{ Name="Marble",         Material=Enum.Material.Marble         },
	{ Name="Slate",          Material=Enum.Material.Slate          },
	{ Name="Concrete",       Material=Enum.Material.Concrete       },
	{ Name="Granite",        Material=Enum.Material.Granite        },
	{ Name="Brick",          Material=Enum.Material.Brick          },
	{ Name="Pebble",         Material=Enum.Material.Pebble         },
	{ Name="Cobblestone",    Material=Enum.Material.Cobblestone    },
	{ Name="Rock",           Material=Enum.Material.Rock           },
	{ Name="Sandstone",      Material=Enum.Material.Sandstone      },
	{ Name="Basalt",         Material=Enum.Material.Basalt         },
	{ Name="CrackedLava",    Material=Enum.Material.CrackedLava    },
	{ Name="Limestone",      Material=Enum.Material.Limestone      },
	{ Name="Ground",         Material=Enum.Material.Ground         },
	{ Name="Sand",           Material=Enum.Material.Sand           },
	{ Name="Grass",          Material=Enum.Material.Grass          },
	{ Name="LeafyGrass",     Material=Enum.Material.LeafyGrass     },
	{ Name="Mud",            Material=Enum.Material.Mud            },
	{ Name="Snow",           Material=Enum.Material.Snow           },
	{ Name="Ice",            Material=Enum.Material.Ice            },
	{ Name="Glacier",        Material=Enum.Material.Glacier        },
	{ Name="Salt",           Material=Enum.Material.Salt           },
	{ Name="Asphalt",        Material=Enum.Material.Asphalt        },
	{ Name="Pavement",       Material=Enum.Material.Pavement       },
	{ Name="Fabric",         Material=Enum.Material.Fabric         },
	{ Name="Foil",           Material=Enum.Material.Foil           },
	{ Name="Metal",          Material=Enum.Material.Metal          },
	{ Name="CorrodedMetal",  Material=Enum.Material.CorrodedMetal  },
	{ Name="DiamondPlate",   Material=Enum.Material.DiamondPlate   },
	{ Name="Glass",          Material=Enum.Material.Glass          },
	{ Name="ForceField",     Material=Enum.Material.ForceField     },
}

local palletMatByName = {}
local palletMatByEnum = {}
for _, opt in ipairs(palletMaterialOptions) do
	palletMatByName[opt.Name]     = opt.Material
	palletMatByEnum[opt.Material] = opt.Name
end

local palletState = {
	defaultColor    = Color3.fromRGB(234,215,198),
	defaultMaterial = Enum.Material.WoodPlanks,
	appliedColor    = Color3.fromRGB(234,215,198),
	selectedMaterial = Enum.Material.WoodPlanks,
	previewColor    = Color3.fromRGB(234,215,198),
	pickerHue       = 0,
	pickerSat       = 0,
	brightness      = 1,
	draggingPicker      = false,
	draggingBrightness  = false,
	lastMatApply    = 0,
	matQueued       = false,
	feedbackToken   = 0,
	dropdownOpen    = false,
	diamondActive    = false,
	presetData = { version=1, selectedIndex=0, presets={} },
}

local palletRefs = {
	pickerFrame  = nil,
	cursor       = nil,
	brightnessBar = nil,
	handle        = nil,
	preview       = nil,
	rBox=nil, gBox=nil, bBox=nil,
	dropBtn      = nil,
	dropFrame    = nil,
	dropScroll   = nil,
	dropLayout   = nil,
	saveBtn      = nil,
}

local palletToysFolder = nil
local destroyToyRemote = nil
local palletPaintConnections = {}

local function initPalletRemotes()
	local ok1, folder = pcall(function()
		return workspace:WaitForChild(player.Name.."SpawnedInToys", 5)
	end)
	local ok2, remote = pcall(function()
		return ReplicatedStorage:WaitForChild("MenuToys",5):WaitForChild("DestroyToy",5)
	end)
	palletToysFolder = ok1 and folder or nil
	destroyToyRemote = ok2 and remote or nil
end

local FTAP_DEFAULT_MAP_SOURCE = [==[local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local map = workspace:WaitForChild("Map")
local mapProps = map:WaitForChild("MapProps")

local BUFFER_TIME = 0.2

local state = {
	applied = false,
	lighting = nil,
	sky = nil,
	clouds = nil,
	parts = {},
	objects = {},
}

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local function closeColor(a, b, tol)
	local function ch(c) return math.floor(c * 255 + 0.5) end
	return math.abs(ch(a.R)-ch(b.R)) <= tol
		and math.abs(ch(a.G)-ch(b.G)) <= tol
		and math.abs(ch(a.B)-ch(b.B)) <= tol
end

local function snapshotBasePart(part)
	return { Transparency=part.Transparency, CanCollide=part.CanCollide, CanQuery=part.CanQuery, CanTouch=part.CanTouch }
end

local function savePartState(part)
	if not state.parts[part] then
		state.parts[part] = { Material=part.Material, Color=part.Color }
	end
end

local function saveObjectState(obj)
	if state.objects[obj] then return state.objects[obj] end
	local record = { Parent=obj.Parent, BaseParts={} }
	if obj:IsA("BasePart") then record.BaseParts[obj] = snapshotBasePart(obj) end
	for _, v in ipairs(obj:GetDescendants()) do
		if v:IsA("BasePart") then record.BaseParts[v] = snapshotBasePart(v) end
	end
	state.objects[obj] = record
	return record
end

local function setObjectVisible(obj)
	local record = saveObjectState(obj)
	obj.Parent = mapProps
	for part, _ in pairs(record.BaseParts) do
		if part and part.Parent then
			part.Transparency = 0; part.CanCollide = true; part.CanQuery = true; part.CanTouch = true
		end
	end
end

local swaps = {
	{ fromMat=Enum.Material.Slate,  fromColor=rgb(116,114,117), toMat=Enum.Material.Slate,  toColor=rgb(163,161,165), tolerance=2 },
	{ fromMat=Enum.Material.Grass,  fromColor=rgb(100,135,82),  toMat=Enum.Material.Grass,  toColor=rgb(124,156,107), tolerance=2 },
	{ fromMat=Enum.Material.Grass,  fromColor=rgb(43,80,36),    toMat=Enum.Material.Grass,  toColor=rgb(61,100,54),   tolerance=2 },
	{ fromMat=Enum.Material.Mud,    fromColor=rgb(65,52,43),    toMat=Enum.Material.Grass,  toColor=rgb(84,63,84),    tolerance=2 },
	{ fromMat=Enum.Material.Mud,    fromColor=rgb(175,147,131), toMat=Enum.Material.Slate,  toColor=rgb(175,147,131), tolerance=2 },
	{ fromMat=Enum.Material.Foil,   fromColor=rgb(2,65,98),     toMat=Enum.Material.Foil,   toColor=rgb(8,137,207),   tolerance=0 },
}

local function applyLighting()
	if not state.lighting then
		state.lighting = {
			Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime,
			FogStart=Lighting.FogStart, FogEnd=Lighting.FogEnd, FogColor=Lighting.FogColor,
		}
	end
	Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogStart=0; Lighting.FogEnd=100000
	Lighting.FogColor=Color3.fromRGB(191,191,191)
end

local function applySky()
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not state.sky then
		state.sky = {
			Existed=sky~=nil, Instance=sky,
			Properties=sky and {
				SkyboxBk=sky.SkyboxBk, SkyboxDn=sky.SkyboxDn, SkyboxFt=sky.SkyboxFt,
				SkyboxLf=sky.SkyboxLf, SkyboxRt=sky.SkyboxRt, SkyboxUp=sky.SkyboxUp,
			} or nil,
		}
	end
	if not sky then sky = Instance.new("Sky"); sky.Parent = Lighting end
	sky.SkyboxBk="rbxassetid://8995816670"; sky.SkyboxDn="rbxassetid://8995686153"
	sky.SkyboxFt="rbxassetid://8995816670"; sky.SkyboxLf="rbxassetid://8995816670"
	sky.SkyboxRt="rbxassetid://8995816670"; sky.SkyboxUp="rbxassetid://8995814929"
end

local function applyClouds()
	if not Terrain then return end
	local clouds = Terrain:FindFirstChild("Clouds")
	if not state.clouds then
		state.clouds = {
			Existed=clouds~=nil, Instance=clouds,
			Properties=clouds and { Density=clouds.Density, Cover=clouds.Cover } or nil,
		}
	end
	if not clouds then clouds = Instance.new("Clouds"); clouds.Parent = Terrain end
	clouds.Density=0.571; clouds.Cover=0.571
end

local function applyMapChanges()
	for _, obj in ipairs(map:GetDescendants()) do
		if obj:IsA("BasePart") then
			for _, rule in ipairs(swaps) do
				if obj.Material==rule.fromMat and closeColor(obj.Color,rule.fromColor,rule.tolerance or 0) then
					savePartState(obj); obj.Material=rule.toMat; obj.Color=rule.toColor; break
				end
			end
		end
	end
	for _, obj in ipairs(map:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name=="Snow" then
			savePartState(obj); obj.Material=Enum.Material.Sand; obj.Color=Color3.fromRGB(248,248,248)
		end
	end
	local hiddenFolder = workspace:FindFirstChild("HiddenMapProps")
	if hiddenFolder then
		for _, obj in ipairs(hiddenFolder:GetChildren()) do
			if obj.Name=="TallTree" or obj.Name=="PineTree2" then setObjectVisible(obj) end
		end
	end
end

local function revertLighting()
	if not state.lighting then return end
	Lighting.Brightness=state.lighting.Brightness; Lighting.ClockTime=state.lighting.ClockTime
	Lighting.FogStart=state.lighting.FogStart; Lighting.FogEnd=state.lighting.FogEnd
	Lighting.FogColor=state.lighting.FogColor
end

local function revertSky()
	if not state.sky then return end
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not state.sky.Existed then if sky then sky:Destroy() end; return end
	if sky and state.sky.Properties then
		local p = state.sky.Properties
		sky.SkyboxBk=p.SkyboxBk; sky.SkyboxDn=p.SkyboxDn; sky.SkyboxFt=p.SkyboxFt
		sky.SkyboxLf=p.SkyboxLf; sky.SkyboxRt=p.SkyboxRt; sky.SkyboxUp=p.SkyboxUp
	end
end

local function revertClouds()
	if not state.clouds or not Terrain then return end
	local clouds = Terrain:FindFirstChild("Clouds")
	if not state.clouds.Existed then if clouds then clouds:Destroy() end; return end
	if clouds and state.clouds.Properties then
		clouds.Density=state.clouds.Properties.Density; clouds.Cover=state.clouds.Properties.Cover
	end
end

local function revertMapChanges()
	for part, props in pairs(state.parts) do
		if part and part.Parent then part.Material=props.Material; part.Color=props.Color end
	end
	for obj, record in pairs(state.objects) do
		if obj then obj.Parent=record.Parent end
		for part, props in pairs(record.BaseParts) do
			if part and part.Parent then
				part.Transparency=props.Transparency; part.CanCollide=props.CanCollide
				part.CanQuery=props.CanQuery; part.CanTouch=props.CanTouch
			end
		end
	end
	table.clear(state.parts); table.clear(state.objects)
end

local function revertSelf()
	if not state.applied then return end
	revertMapChanges(); revertLighting(); revertSky(); revertClouds()
	state.applied=false; state.lighting=nil; state.sky=nil; state.clouds=nil
end

local function revertOtherMaps()
	if type(_G.RevertFoggyMap)=="function" then _G.RevertFoggyMap() end
	if type(_G.RevertXmasMap)=="function"  then _G.RevertXmasMap()  end
end

local function applySelf()
	revertSelf(); revertOtherMaps(); task.wait(BUFFER_TIME)
	applyLighting(); applySky(); applyClouds(); applyMapChanges()
	state.applied=true
end

_G.RevertDefaultMap = revertSelf
_G.ApplyDefaultMap  = applySelf
]==]

local FTAP_FOGGY_MAP_SOURCE = [==[local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local map = workspace:WaitForChild("Map")

local BUFFER_TIME = 0.2

local state = {
	applied = false,
	lighting = nil, sky = nil, clouds = nil,
	parts = {}, objects = {}, hiddenFolderCreated = false,
}

local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end

local function closeColor(a, b, tol)
	local function ch(c) return math.floor(c*255+0.5) end
	return math.abs(ch(a.R)-ch(b.R))<=tol and math.abs(ch(a.G)-ch(b.G))<=tol and math.abs(ch(a.B)-ch(b.B))<=tol
end

local function snapshotBasePart(part)
	return { Transparency=part.Transparency, CanCollide=part.CanCollide, CanQuery=part.CanQuery, CanTouch=part.CanTouch }
end

local function savePartState(part)
	if not state.parts[part] then state.parts[part]={Material=part.Material,Color=part.Color} end
end

local function saveObjectState(obj)
	if state.objects[obj] then return state.objects[obj] end
	local record={Parent=obj.Parent,BaseParts={}}
	if obj:IsA("BasePart") then record.BaseParts[obj]=snapshotBasePart(obj) end
	for _,v in ipairs(obj:GetDescendants()) do
		if v:IsA("BasePart") then record.BaseParts[v]=snapshotBasePart(v) end
	end
	state.objects[obj]=record; return record
end

local function hideObject(obj, hiddenFolder)
	local record=saveObjectState(obj)
	obj.Parent=hiddenFolder
	for part,_ in pairs(record.BaseParts) do
		if part and part.Parent then
			part.Transparency=1; part.CanCollide=false; part.CanQuery=false; part.CanTouch=false
		end
	end
end

local swaps = {
	{ fromMat=Enum.Material.Slate, fromColor=rgb(163,161,165), toMat=Enum.Material.Slate, toColor=rgb(116,114,117), tolerance=2 },
	{ fromMat=Enum.Material.Grass, fromColor=rgb(124,156,107), toMat=Enum.Material.Grass, toColor=rgb(100,135,82),  tolerance=2 },
	{ fromMat=Enum.Material.Grass, fromColor=rgb(61,100,54),   toMat=Enum.Material.Grass, toColor=rgb(43,80,36),    tolerance=2 },
	{ fromMat=Enum.Material.Grass, fromColor=rgb(84,63,84),    toMat=Enum.Material.Mud,   toColor=rgb(65,52,43),    tolerance=2 },
	{ fromMat=Enum.Material.Slate, fromColor=rgb(175,147,131), toMat=Enum.Material.Mud,   toColor=rgb(175,147,131), tolerance=2 },
	{ fromMat=Enum.Material.Foil,  fromColor=rgb(8,137,207),   toMat=Enum.Material.Foil,  toColor=rgb(2,65,98),     tolerance=0 },
	{ fromMat=Enum.Material.Sand,  fromColor=rgb(248,248,248), toMat=Enum.Material.Slate,  toColor=rgb(116,114,117), tolerance=0 },
}

local function applyLighting()
	if not state.lighting then
		state.lighting={
			Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime,
			FogStart=Lighting.FogStart, FogEnd=Lighting.FogEnd, FogColor=Lighting.FogColor,
		}
	end
	Lighting.Brightness=1.5; Lighting.ClockTime=16.5; Lighting.FogStart=200
	Lighting.FogEnd=5000; Lighting.FogColor=Color3.fromRGB(255,255,255)
end

local function applySky()
	local sky=Lighting:FindFirstChildOfClass("Sky")
	if not state.sky then
		state.sky={
			Existed=sky~=nil,
			Properties=sky and {
				SkyboxBk=sky.SkyboxBk, SkyboxDn=sky.SkyboxDn, SkyboxFt=sky.SkyboxFt,
				SkyboxLf=sky.SkyboxLf, SkyboxRt=sky.SkyboxRt, SkyboxUp=sky.SkyboxUp,
			} or nil,
		}
	end
	if not sky then sky=Instance.new("Sky"); sky.Parent=Lighting end
	local id="rbxassetid://10491933248"
	sky.SkyboxBk=id; sky.SkyboxDn=id; sky.SkyboxFt=id
	sky.SkyboxLf=id; sky.SkyboxRt=id; sky.SkyboxUp=id
end

local function applyClouds()
	if not Terrain then return end
	local clouds=Terrain:FindFirstChild("Clouds")
	if not state.clouds then
		state.clouds={
			Existed=clouds~=nil,
			Properties=clouds and { Density=clouds.Density, Cover=clouds.Cover } or nil,
		}
	end
	if not clouds then clouds=Instance.new("Clouds"); clouds.Parent=Terrain end
	clouds.Density=0.801; clouds.Cover=0.801
end

local function applyMapChanges()
	local hiddenFolder=workspace:FindFirstChild("HiddenMapProps")
	if not hiddenFolder then
		hiddenFolder=Instance.new("Folder")
		hiddenFolder.Name="HiddenMapProps"
		hiddenFolder.Parent=workspace
		state.hiddenFolderCreated=true
	else
		state.hiddenFolderCreated=false
	end
	for _,obj in ipairs(map:GetDescendants()) do
		if obj:IsA("BasePart") then
			for _,rule in ipairs(swaps) do
				if obj.Material==rule.fromMat and closeColor(obj.Color,rule.fromColor,rule.tolerance or 0) then
					savePartState(obj); obj.Material=rule.toMat; obj.Color=rule.toColor; break
				end
			end
		end
	end
	for _,obj in ipairs(map:GetDescendants()) do
		if obj.Name=="TallTree" or obj.Name=="PineTree2" then hideObject(obj,hiddenFolder) end
	end
end

local function revertLighting()
	if not state.lighting then return end
	Lighting.Brightness=state.lighting.Brightness; Lighting.ClockTime=state.lighting.ClockTime
	Lighting.FogStart=state.lighting.FogStart; Lighting.FogEnd=state.lighting.FogEnd
	Lighting.FogColor=state.lighting.FogColor
end

local function revertSky()
	if not state.sky then return end
	local sky=Lighting:FindFirstChildOfClass("Sky")
	if not state.sky.Existed then if sky then sky:Destroy() end; return end
	if sky and state.sky.Properties then
		local p=state.sky.Properties
		sky.SkyboxBk=p.SkyboxBk; sky.SkyboxDn=p.SkyboxDn; sky.SkyboxFt=p.SkyboxFt
		sky.SkyboxLf=p.SkyboxLf; sky.SkyboxRt=p.SkyboxRt; sky.SkyboxUp=p.SkyboxUp
	end
end

local function revertClouds()
	if not state.clouds or not Terrain then return end
	local clouds=Terrain:FindFirstChild("Clouds")
	if not state.clouds.Existed then if clouds then clouds:Destroy() end; return end
	if clouds and state.clouds.Properties then
		clouds.Density=state.clouds.Properties.Density; clouds.Cover=state.clouds.Properties.Cover
	end
end

local function revertMapChanges()
	for part,props in pairs(state.parts) do
		if part and part.Parent then part.Material=props.Material; part.Color=props.Color end
	end
	for obj,record in pairs(state.objects) do
		if obj then obj.Parent=record.Parent end
		for part,props in pairs(record.BaseParts) do
			if part and part.Parent then
				part.Transparency=props.Transparency; part.CanCollide=props.CanCollide
				part.CanQuery=props.CanQuery; part.CanTouch=props.CanTouch
			end
		end
	end
	table.clear(state.parts); table.clear(state.objects)
	if state.hiddenFolderCreated then
		local f=workspace:FindFirstChild("HiddenMapProps")
		if f and #f:GetChildren()==0 then f:Destroy() end
		state.hiddenFolderCreated=false
	end
end

local function revertSelf()
	if not state.applied then return end
	revertMapChanges(); revertLighting(); revertSky(); revertClouds()
	state.applied=false; state.lighting=nil; state.sky=nil; state.clouds=nil
end

local function revertOtherMaps()
	if type(_G.RevertDefaultMap)=="function" then _G.RevertDefaultMap() end
	if type(_G.RevertXmasMap)=="function"    then _G.RevertXmasMap()    end
end

local function applySelf()
	revertSelf(); revertOtherMaps(); task.wait(BUFFER_TIME)
	applyLighting(); applySky(); applyClouds(); applyMapChanges()
	state.applied=true
end

_G.RevertFoggyMap = revertSelf
_G.ApplyFoggyMap  = applySelf
]==]

local FTAP_XMAS_MAP_SOURCE = [==[local map = workspace:WaitForChild("Map")
local BUFFER_TIME = 0.2

local state = { applied=false, parts={}, objects={} }

local hiddenFolder = workspace:FindFirstChild("HiddenMapProps")
if not hiddenFolder then
	hiddenFolder = Instance.new("Folder")
	hiddenFolder.Name = "HiddenMapProps"
	hiddenFolder.Parent = workspace
end

local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end

local function closeColor(a, b, tol)
	local function ch(c) return math.floor(c*255+0.5) end
	return math.abs(ch(a.R)-ch(b.R))<=tol and math.abs(ch(a.G)-ch(b.G))<=tol and math.abs(ch(a.B)-ch(b.B))<=tol
end

local function savePartState(part)
	if not state.parts[part] then state.parts[part]={Material=part.Material,Color=part.Color} end
end

local function saveObjectState(obj)
	if state.objects[obj] then return end
	local record={Parent=obj.Parent,BaseParts={}}
	if obj:IsA("BasePart") then
		record.Self={Transparency=obj.Transparency,CanCollide=obj.CanCollide,CanQuery=obj.CanQuery,CanTouch=obj.CanTouch}
	end
	for _,v in ipairs(obj:GetDescendants()) do
		if v:IsA("BasePart") then
			record.BaseParts[v]={Transparency=v.Transparency,CanCollide=v.CanCollide,CanQuery=v.CanQuery,CanTouch=v.CanTouch}
		end
	end
	state.objects[obj]=record
end

local swaps = {
	{ fromMat=Enum.Material.Slate, fromColor=rgb(163,161,165), toMat=Enum.Material.Foil,  toColor=rgb(77,96,103),   tolerance=2 },
	{ fromMat=Enum.Material.Grass, fromColor=rgb(124,156,107), toMat=Enum.Material.Snow,  toColor=rgb(255,255,255), tolerance=2 },
	{ fromMat=Enum.Material.Grass, fromColor=rgb(61,100,54),   toMat=Enum.Material.Snow,  toColor=rgb(188,233,255), tolerance=2 },
	{ fromMat=Enum.Material.Grass, fromColor=rgb(84,63,84),    toMat=Enum.Material.Snow,  toColor=rgb(59,65,68),    tolerance=2 },
	{ fromMat=Enum.Material.Slate, fromColor=rgb(175,147,131), toMat=Enum.Material.Foil,  toColor=rgb(119,144,156), tolerance=2 },
	{ fromMat=Enum.Material.Sand,  fromColor=rgb(240,230,198), toMat=Enum.Material.Snow,  toColor=rgb(255,255,255), tolerance=2 },
	{ fromMat=Enum.Material.Sand,  fromColor=rgb(248,248,248), toMat=Enum.Material.Snow,  toColor=rgb(255,255,255), tolerance=2 },
}

local function hideObject(obj)
	if not obj then return end
	saveObjectState(obj)
	obj.Parent=hiddenFolder
	if obj:IsA("BasePart") then
		obj.Transparency=1; obj.CanCollide=false; obj.CanQuery=false; obj.CanTouch=false
	end
	for _,v in ipairs(obj:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Transparency=1; v.CanCollide=false; v.CanQuery=false; v.CanTouch=false
		end
	end
end

local function applyMapChanges()
	for _,obj in ipairs(map:GetDescendants()) do
		if obj:IsA("BasePart") then
			for _,rule in ipairs(swaps) do
				if obj.Material==rule.fromMat and closeColor(obj.Color,rule.fromColor,rule.tolerance or 0) then
					savePartState(obj); obj.Material=rule.toMat; obj.Color=rule.toColor; break
				end
			end
		end
		if obj.Name=="TallTree" or obj.Name=="PineTree2" then hideObject(obj) end
	end
end

local function revertSelf()
	if not state.applied then return end
	for part,props in pairs(state.parts) do
		if part and part.Parent then part.Material=props.Material; part.Color=props.Color end
	end
	for obj,props in pairs(state.objects) do
		if obj then
			if props.Parent then obj.Parent=props.Parent end
			if props.Self and obj:IsA("BasePart") then
				obj.Transparency=props.Self.Transparency; obj.CanCollide=props.Self.CanCollide
				obj.CanQuery=props.Self.CanQuery; obj.CanTouch=props.Self.CanTouch
			end
			for basePart,baseProps in pairs(props.BaseParts) do
				if basePart and basePart.Parent then
					basePart.Transparency=baseProps.Transparency; basePart.CanCollide=baseProps.CanCollide
					basePart.CanQuery=baseProps.CanQuery; basePart.CanTouch=baseProps.CanTouch
				end
			end
		end
	end
	table.clear(state.parts); table.clear(state.objects)
	state.applied=false
end

local function revertOtherMaps()
	if type(_G.RevertDefaultMap)=="function" then _G.RevertDefaultMap() end
	if type(_G.RevertFoggyMap)=="function"   then _G.RevertFoggyMap()   end
end

local function applySelf()
	revertSelf(); revertOtherMaps(); task.wait(BUFFER_TIME)
	applyMapChanges(); state.applied=true
end

_G.RevertXmasMap = revertSelf
_G.ApplyXmasMap  = applySelf
]==]

local CHRISTMAS_MAP_PROPS_SOURCE = [==[local HttpService = game:GetService("HttpService")

local targetPositions = {
	SmallSnowPineTree1=Vector3.new(-189.341705,211.743896,562.024109),
	SmallSnowPineTree2=Vector3.new(-228.392105,200.31778,518.811401),
	SmallSnowPineTree3=Vector3.new(324.52475,23.5731735,-332.382751),
	SmallSnowPineTree4=Vector3.new(236.920868,69.7438736,-310.254791),
	SmallSnowPineTree5=Vector3.new(-451.079132,25.7438774,-404.25473),
	SmallSnowPineTree6=Vector3.new(-454.210175,13.4027491,-332.784058),
	SmallSnowPineTree7=Vector3.new(-605.760925,15.3184671,-284.45929),
	MediumDarkPineTree1=Vector3.new(618.064331,150.695084,-264.380493),
	MediumDarkPineTree2=Vector3.new(314.687073,79.1661682,-466.588043),
	MediumDarkPineTree3=Vector3.new(-552.092773,79.1670303,-333.950256),
	MediumDarkPineTree4=Vector3.new(-603.014099,51.4600525,203.807846),
	MediumDarkPineTree5=Vector3.new(48.2129211,386.014099,376.256622),
	LargeLushPineTree1=Vector3.new(-691.473572,133.440689,-67.1524963),
	LargeLushPineTree2=Vector3.new(-320.309448,167.634598,-438.702087),
	LargeLushPineTree3=Vector3.new(-475.745178,288.871704,398.591156),
	MassiveOrnamentPineTree=Vector3.new(320.440002,369.436188,137.680023),
}

local function getClosestTarget(position, targets)
	local closestName, closestDist = nil, math.huge
	for name, targetPos in pairs(targets) do
		local dist = (position - targetPos).Magnitude
		if dist < closestDist then closestDist=dist; closestName=name end
	end
	return closestName
end

local function deserializeMap(jsonString)
	local data = HttpService:JSONDecode(jsonString)
	local oldMap = workspace:FindFirstChild("ChristmasMapProps")
	if oldMap then oldMap:Destroy() end

	local mapRoot = Instance.new("Folder")
	mapRoot.Name = "ChristmasMapProps"
	mapRoot.Parent = workspace

	local mapParts, partToIndex = {}, {}

	for _, p in ipairs(data) do
		local newPart
		if p.ClassName=="MeshPart" then
			newPart = Instance.new("MeshPart")
			pcall(function() newPart.MeshId=p.MeshId end)
			pcall(function() newPart.TextureID=p.TextureID end)
		else
			newPart = Instance.new(p.ClassName)
		end
		if p.ClassName=="Part" and p.Shape then newPart.Shape=Enum.PartType[p.Shape] end
		newPart.Name        = p.Name
		newPart.CFrame      = CFrame.new(unpack(p.CFrame))
		newPart.Size        = Vector3.new(unpack(p.Size))
		newPart.Color       = Color3.new(unpack(p.Color))
		newPart.Material    = Enum.Material[p.Material]
		newPart.Transparency = 1
		newPart:SetAttribute("SoggyOriginalTransparency", p.Transparency)
		newPart.Anchored    = p.Anchored
		newPart.CanCollide  = false
		newPart.CanTouch    = false
		newPart.CanQuery    = true
		newPart.Parent      = mapRoot
		if newPart:IsA("BasePart") then
			table.insert(mapParts, newPart)
			partToIndex[newPart] = #mapParts
		end
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = {mapRoot}
	overlapParams.MaxParts = 0

	local adjacency = table.create(#mapParts)
	for i=1,#mapParts do adjacency[i]={} end
	local PAD = Vector3.new(0.05,0.05,0.05)
	for i, part in ipairs(mapParts) do
		for _, other in ipairs(workspace:GetPartBoundsInBox(part.CFrame, part.Size+PAD, overlapParams)) do
			if other~=part then
				local j=partToIndex[other]
				if j and j>i then adjacency[i][j]=true; adjacency[j][i]=true end
			end
		end
	end

	local visited = table.create(#mapParts, false)
	local groups  = {}
	for startIndex=1,#mapParts do
		if not visited[startIndex] then
			local queue, head, group = {startIndex}, 1, {}
			visited[startIndex]=true
			while head<=#queue do
				local cur=queue[head]; head+=1
				table.insert(group, cur)
				for nb in pairs(adjacency[cur]) do
					if not visited[nb] then visited[nb]=true; table.insert(queue,nb) end
				end
			end
			table.insert(groups, group)
		end
	end

	local remaining = {}
	for name, pos in pairs(targetPositions) do remaining[name]=pos end

	for _, group in ipairs(groups) do
		local groupModel = Instance.new("Model")
		groupModel.Name  = "TempGroup"
		groupModel.Parent = mapRoot
		for _, idx in ipairs(group) do mapParts[idx].Parent=groupModel end
		local match = getClosestTarget(groupModel:GetPivot().Position, remaining)
		groupModel.Name = match or "UnmatchedGroup"
		if match then remaining[match]=nil end
	end

	for _, part in ipairs(mapParts) do
		part.CanCollide=false; part.CanTouch=false; part.CanQuery=false
	end
end

local ok, contents = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/soggyroblox9/Soggy-Scripts/refs/heads/main/ChristmasTrees.json")
if ok and type(contents)=="string" and contents~="" then
	deserializeMap(contents)
else
	warn("SoggyHub: Failed to fetch ChristmasTrees.json")
end

local function setVisible(visible)
	local mapRoot = workspace:FindFirstChild("ChristmasMapProps")
	if not mapRoot then return end
	for _, obj in ipairs(mapRoot:GetDescendants()) do
		if obj:IsA("BasePart") then
			local orig = obj:GetAttribute("SoggyOriginalTransparency")
			if typeof(orig)~="number" then orig=0 end
			obj.Transparency = visible and orig or 1
			obj.CanCollide=false; obj.CanTouch=false; obj.CanQuery=false
		end
	end
end

setVisible(false)
_G.SetChristmasMapPropsVisible = setVisible
_G.ShowChristmasMapProps = function() setVisible(true)  end
_G.HideChristmasMapProps = function() setVisible(false) end
]==]

local function saveSettings()
	if not (fnWriteFile and fnIsFile) then return end
	pcall(fnWriteFile, SETTINGS_FILE, HttpService:JSONEncode({
		FOV         = math.clamp(math.floor(state.targetFOV + 0.5), 1, 120),
		FpsCapIndex = math.clamp(math.floor(state.fpsCapIndex), 1, #FPS_CAP_OPTIONS),
		ThirdPerson = state.thirdPersonEnabled,
	}))
end

local function clearSavedSettings()
	if not (fnDelFile and fnIsFile) then return end
	local ok, exists = pcall(fnIsFile, SETTINGS_FILE)
	if ok and exists then pcall(fnDelFile, SETTINGS_FILE) end
end

local function loadSavedSettings()
	if not (fnReadFile and fnIsFile) then return end
	local ok, exists = pcall(fnIsFile, SETTINGS_FILE)
	if not ok or not exists then return end
	local okR, contents = pcall(fnReadFile, SETTINGS_FILE)
	if not okR or type(contents)~="string" or contents=="" then return end
	local okD, data = pcall(HttpService.JSONDecode, HttpService, contents)
	if not okD or type(data)~="table" then return end
	if type(data.FOV)=="number" then
		state.targetFOV = math.clamp(math.floor(data.FOV+0.5), 1, 120)
	end
	if type(data.FpsCapIndex)=="number" then
		state.fpsCapIndex = math.clamp(math.floor(data.FpsCapIndex), 1, #FPS_CAP_OPTIONS)
	end
	if type(data.ThirdPerson)=="boolean" then
		state.thirdPersonEnabled = data.ThirdPerson
	end
end

local function persistSettings()
	if state.saveSettings then saveSettings() else clearSavedSettings() end
end

do
	local queued = getgenv and getgenv().__SoggyHubQueuedSettings
	if type(queued)=="table" then
		state.saveSettings = queued.SaveSettings ~= false
		if type(queued.FOV)=="number"         then state.targetFOV        = math.clamp(math.floor(queued.FOV+0.5), 1, 120) end
		if type(queued.FpsCapIndex)=="number" then state.fpsCapIndex      = math.clamp(math.floor(queued.FpsCapIndex), 1, #FPS_CAP_OPTIONS) end
		if type(queued.ThirdPerson)=="boolean"then state.thirdPersonEnabled = queued.ThirdPerson end
		getgenv().__SoggyHubQueuedSettings = nil
	end
	if state.saveSettings then loadSavedSettings() end
end

local function tween(obj, props, info)
	if obj then TweenService:Create(obj, info or TWEEN_SHORT, props):Play() end
end

local function spinButton(btn)
	local STEPS = 12
	local STEP_TIME = 0.4 / STEPS
	task.spawn(function()
		for i = 1, STEPS do
			btn.Rotation = (i / STEPS) * 360
			task.wait(STEP_TIME)
		end
		btn.Rotation = 0
	end)
end

local function safeRun(name, fn)
	local ok, err = pcall(fn)
	if not ok then warn("SoggyHub ["..tostring(name).."]: "..tostring(err)) end
end

local function safePcall(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then warn("SoggyHub error: "..tostring(err)) end
end

local function httpGet(url)
	local ok, body = pcall(game.HttpGet, game, url)
	return ok and body or nil
end

local function requestUrl(url)
	if not fnRequest then return nil, "no request fn" end
	local ok, res = pcall(fnRequest, { Url=url, Method="GET" })
	if not ok or not res then return nil, "request failed" end
	if res.StatusCode~=200 or not res.Body then return nil, "bad response" end
	return res.Body
end

local function queueTeleportSource(source)
	if fnQueueTp then pcall(fnQueueTp, source) end
end

local function normalizeStr(s) return string.lower(tostring(s or "")) end

local function splitWords(s)
	local t = {}
	for w in string.gmatch(tostring(s or ""), "%S+") do t[#t+1] = w end
	return t
end

local function getCharParts(p)
	local char = p and p.Character
	if not char then return nil, nil, nil end
	return char, char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart")
end

local function localHumanoid()
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function findPlayerMatch(query)
	local search = normalizeStr(query)
	if search=="" then return nil, "missing name" end
	local exact, prefix = {}, {}
	for _, p in ipairs(Players:GetPlayers()) do
		local u = normalizeStr(p.Name)
		local d = normalizeStr(p.DisplayName)
		if u==search or d==search then
			exact[#exact+1] = p
		elseif u:sub(1,#search)==search or d:sub(1,#search)==search then
			prefix[#prefix+1] = p
		end
	end
	if #exact==1  then return exact[1]  end
	if #exact>1   then return nil, "ambiguous name" end
	if #prefix==1 then return prefix[1] end
	if #prefix>1  then return nil, "ambiguous name" end
	return nil, "player not found"
end

local function buildQueueSource()
	return string.format([[
getgenv().__SoggyHubQueuedSettings={SaveSettings=%s,FOV=%d,FpsCapIndex=%d,ThirdPerson=%s}
loadstring(game:HttpGet("%s"))()
	]],
		tostring(state.saveSettings),
		state.saveSettings and state.targetFOV    or state.defaultFOV,
		state.saveSettings and state.fpsCapIndex  or 1,
		tostring(state.saveSettings and state.thirdPersonEnabled or false),
		MENU_LOADSTRING_URL
	)
end

local function rejoinServer()
	persistSettings()
	if state.reExecuteOnTeleport then queueTeleportSource(buildQueueSource()) else queueTeleportSource("") end
	TeleportService:Teleport(placeId, player)
end

local function serverHop()
	local cursor = ""
	local foundServer = nil
	for _=1,8 do
		local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
		if cursor~="" then url = url.."&cursor="..cursor end
		local body, err = requestUrl(url)
		if not body then warn("Server hop: "..tostring(err)); break end
		local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
		if not ok or not data or not data.data then warn("Server hop: bad data"); break end
		local servers = data.data
		for i=#servers,2,-1 do
			local j=math.random(i); servers[i],servers[j]=servers[j],servers[i]
		end
		for _, srv in ipairs(servers) do
			if srv.id~=jobId and srv.playing<srv.maxPlayers then foundServer=srv.id; break end
		end
		if foundServer then break end
		cursor = data.nextPageCursor or ""
		if cursor=="" then break end
	end
	if foundServer then
		persistSettings()
		if state.reExecuteOnTeleport then queueTeleportSource(buildQueueSource()) else queueTeleportSource("") end
		TeleportService:TeleportToPlaceInstance(placeId, foundServer, player)
	else
		warn("No different server found")
	end
end

local function applyFpsCap()
	if not fnSetFpsCap then return end
	pcall(fnSetFpsCap, FPS_CAP_OPTIONS[state.fpsCapIndex] or 60)
end

local function clearEspPlayer(p)
	if not p then return end
	esp.tracked[p.UserId] = nil
	local e = esp.objects[p.UserId]
	if not e then return end
	if e.Connection then e.Connection:Disconnect() end
	if e.Highlight   then e.Highlight:Destroy() end
	if e.Billboard   then e.Billboard:Destroy() end
	esp.objects[p.UserId] = nil
end

local function buildEsp(p, character)
	if not p or not character or not refs.gui then return end
	clearEspPlayer(p)
	esp.tracked[p.UserId] = true

	local adornPart = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	if not adornPart then return end

	local hl = Instance.new("Highlight")
	hl.Name              = "SoggyESP"
	hl.Adornee           = character
	hl.DepthMode         = Enum.HighlightDepthMode.AlwaysOnTop
	hl.FillTransparency  = 0.5
	hl.OutlineTransparency = 0
	hl.Parent            = refs.gui

	local bb = Instance.new("BillboardGui")
	bb.Name         = "SoggyESPLabel"
	bb.AlwaysOnTop  = true
	bb.Size         = UDim2.new(0,220,0,46)
	bb.StudsOffset  = Vector3.new(0,3.2,0)
	bb.Adornee      = adornPart
	bb.Parent       = refs.gui

	local function mkLabel(text, y, size, color)
		local l = Instance.new("TextLabel")
		l.Size               = UDim2.new(1,0,0,size)
		l.Position           = UDim2.new(0,0,0,y)
		l.BackgroundTransparency = 1
		l.Text               = text
		l.TextColor3         = color or Color3.fromRGB(248,250,255)
		l.TextStrokeTransparency = 0.5
		l.TextStrokeColor3   = Color3.fromRGB(0,0,0)
		l.Font               = Enum.Font.GothamSemibold
		l.TextSize           = size==22 and 14 or 11
		l.Parent             = bb
	end
	mkLabel(p.DisplayName, 0,  22)
	mkLabel("@"..p.Name,  20, 18, Color3.fromRGB(220,220,220))

	local conn = p.CharacterAdded:Connect(function(newChar)
		task.wait(0.15)
		if esp.tracked[p.UserId] then buildEsp(p, newChar) end
	end)
	esp.objects[p.UserId] = { Highlight=hl, Billboard=bb, Connection=conn }
end

local function espPlayer(p)
	if not p then return false,"player not found" end
	local char = p.Character
	if not char then return false,"character not found" end
	buildEsp(p, char); return true
end

local function espAll()
	for _, p in ipairs(Players:GetPlayers()) do
		if p~=player then espPlayer(p) end
	end
end

local function clearAllEsp()
	esp.allEnabled = false
	if esp.playerAddedConn then esp.playerAddedConn:Disconnect(); esp.playerAddedConn=nil end
	for uid, conn in pairs(esp.charConns) do
		if conn then conn:Disconnect() end
		esp.charConns[uid] = nil
	end
	for _, p in ipairs(Players:GetPlayers()) do clearEspPlayer(p) end
end

local function enableEspAllFuture()
	if esp.playerAddedConn then esp.playerAddedConn:Disconnect() end
	esp.playerAddedConn = Players.PlayerAdded:Connect(function(p)
		esp.charConns[p.UserId] = p.CharacterAdded:Connect(function()
			if esp.allEnabled and p~=player then task.wait(0.15); espPlayer(p) end
		end)
		if esp.allEnabled and p~=player and p.Character then task.defer(espPlayer, p) end
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		if esp.charConns[p.UserId] then esp.charConns[p.UserId]:Disconnect() end
		esp.charConns[p.UserId] = p.CharacterAdded:Connect(function()
			if esp.allEnabled and p~=player then task.wait(0.15); espPlayer(p) end
		end)
	end
end

local function resetView()
	view.target = nil
	local _, hum = getCharParts(player)
	if hum then camera.CameraSubject = hum end
	camera.CameraType = Enum.CameraType.Custom
end

local function setView(p)
	if not p then return false,"player not found" end
	local _, hum = getCharParts(p)
	if not hum then return false,"character not ready" end
	view.target           = p
	camera.CameraType     = Enum.CameraType.Custom
	camera.CameraSubject  = hum
	return true
end

local function stopNoclip()
	noclip.enabled = false
	if noclip.connection then noclip.connection:Disconnect(); noclip.connection=nil end
end

local function startNoclip()
	stopNoclip()
	noclip.enabled = true
	noclip.connection = RunService.Stepped:Connect(function()
		if not noclip.enabled then return end
		local char = player.Character
		if not char then return end
		for _, obj in ipairs(char:GetDescendants()) do
			if obj:IsA("BasePart") then obj.CanCollide=false end
		end
	end)
end

local function applyThirdPerson()
	player.CameraMode = Enum.CameraMode.Classic
	if state.thirdPersonEnabled then
		player.CameraMinZoomDistance = 6
		player.CameraMaxZoomDistance = 100
	else
		player.CameraMinZoomDistance = state.defaultMinZoom
		player.CameraMaxZoomDistance = state.defaultMaxZoom
	end
end

local function cloneIfOk(obj)
	local ok, c = pcall(function() return obj:Clone() end)
	return ok and c or nil
end

local function snapshotMap()
	if mapSnapshot.taken then return end
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	local clouds  = terrain and terrain:FindFirstChild("Clouds")
	local map     = workspace:FindFirstChild("Map")

	for _, obj in ipairs(Lighting:GetChildren()) do
		if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect")
		or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect")
		or obj:IsA("BlurEffect") or obj:IsA("DepthOfFieldEffect") then
			local c = cloneIfOk(obj)
			if c then mapSnapshot.lightingChildren[#mapSnapshot.lightingChildren+1] = c end
		end
	end

	for _, prop in ipairs({
		"Technology","Ambient","OutdoorAmbient","Brightness","ColorShift_Top",
		"ColorShift_Bottom","EnvironmentDiffuseScale","EnvironmentSpecularScale",
		"ShadowSoftness","ClockTime","GeographicLatitude","ExposureCompensation",
		"FogColor","FogStart","FogEnd",
	}) do
		mapSnapshot.lightingProps[prop] = Lighting[prop]
	end

	if clouds then
		mapSnapshot.clouds = { Density=clouds.Density, Cover=clouds.Cover, Color=clouds.Color }
	end

	if map then
		for _, obj in ipairs(map:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Name=="Ocean" then
				mapSnapshot.oceanStates[obj] = {
					Color=obj.Color, Material=obj.Material, Transparency=obj.Transparency
				}
			end
		end
	end

	mapSnapshot.taken = true
end

local function clearManagedLighting()
	for _, obj in ipairs(Lighting:GetChildren()) do
		if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("BloomEffect")
		or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect")
		or obj:IsA("BlurEffect") or obj:IsA("DepthOfFieldEffect") then
			obj:Destroy()
		end
	end
end

local function clearManagedAudio()
	for _, name in ipairs(MANAGED_AUDIO_NAMES) do
		repeat local o=SoundService:FindFirstChild(name); if o then o:Destroy() end until not o
	end
	for _, name in ipairs(MANAGED_FOLDER_NAMES) do
		repeat local o=SoundService:FindFirstChild(name); if o then o:Destroy() end until not o
	end
end

local function clearMutedEffects()
	local a = SoundService:FindFirstChild("SoggyMapAudio")
	if a then a:Destroy() end
	local sg = playerGui:FindFirstChild("SoggyMapStarGui")
	if sg then sg:Destroy() end
end

local function restoreMap()
	if not mapSnapshot.taken then return end

	local preset = state.currentMapPreset
	if preset then
		local fn = MAP_PRESET[preset] and MAP_PRESET[preset].StopFn
		if fn and type(_G[fn])=="function" then pcall(_G[fn]) end
	end

	clearManagedLighting()
	clearManagedAudio()
	pcall(RunService.UnbindFromRenderStep, RunService, "SpaceNebulaStarFollow")
	pcall(RunService.UnbindFromRenderStep, RunService, "SoggyMapStarBind")

	for _, name in ipairs({"SpaceNebulaStars","SoggyMapStarGui"}) do
		local g = playerGui:FindFirstChild(name); if g then g:Destroy() end
	end
	local vf = workspace:FindFirstChild("SoggyMapVisuals"); if vf then vf:Destroy() end

	for prop, val in pairs(mapSnapshot.lightingProps) do
		pcall(function() Lighting[prop] = val end)
	end
	for _, clone in ipairs(mapSnapshot.lightingChildren) do
		local r = cloneIfOk(clone)
		if r then r.Parent = Lighting end
	end

	local terrain = workspace:FindFirstChildOfClass("Terrain")
	local clouds  = terrain and terrain:FindFirstChild("Clouds")
	if clouds and mapSnapshot.clouds then
		clouds.Density = mapSnapshot.clouds.Density
		clouds.Cover   = mapSnapshot.clouds.Cover
		clouds.Color   = mapSnapshot.clouds.Color
	end

	for obj, saved in pairs(mapSnapshot.oceanStates) do
		if obj and obj.Parent then
			obj.Color        = saved.Color
			obj.Material     = saved.Material
			obj.Transparency = saved.Transparency
		end
	end
end

local function revertAllFTAP()
	if type(_G.RevertDefaultMap)=="function" then pcall(_G.RevertDefaultMap) end
	if type(_G.RevertFoggyMap)  =="function" then pcall(_G.RevertFoggyMap)  end
	if type(_G.RevertXmasMap)   =="function" then pcall(_G.RevertXmasMap)   end
end

local function loadFTAPScripts()
	if ftapState.scriptsLoaded then return true end
	for _, src in ipairs({FTAP_DEFAULT_MAP_SOURCE, FTAP_FOGGY_MAP_SOURCE, FTAP_XMAS_MAP_SOURCE}) do
		local chunk, err = loadstring(src)
		if not chunk then warn("FTAP compile: "..tostring(err)); return false end
		local ok, rErr = pcall(chunk)
		if not ok then warn("FTAP runtime: "..tostring(rErr)); return false end
	end
	ftapState.scriptsLoaded = true
	return true
end

local function loadChristmasProps()
	if ftapState.propsLoaded then return true end
	local chunk, err = loadstring(CHRISTMAS_MAP_PROPS_SOURCE)
	if not chunk then warn("Xmas props compile: "..tostring(err)); return false end
	local ok, rErr = pcall(chunk)
	if not ok then warn("Xmas props runtime: "..tostring(rErr)); return false end
	ftapState.propsLoaded = true
	return true
end

local function setXmasPropsVisible(visible)
	if not loadChristmasProps() then return end
	if type(_G.SetChristmasMapPropsVisible)=="function" then
		pcall(_G.SetChristmasMapPropsVisible, visible==true)
	end
end

local function getMapNoisesFolder()
	local map = workspace:FindFirstChild("Map")
	return map and map:FindFirstChild("MapNoises")
end

local function applyAmbienceFilter()
	local folder = getMapNoisesFolder()
	if state.ftapDefaultAmbienceEnabled then
		if not folder and ftapState.ambienceClone then
			local map = workspace:FindFirstChild("Map")
			if map then
				local r = cloneIfOk(ftapState.ambienceClone)
				if r then r.Parent=map end
			end
		end
	else
		if folder then
			if not ftapState.ambienceClone then
				ftapState.ambienceClone = cloneIfOk(folder)
			end
			folder:Destroy()
		end
	end
end

local function bindAmbienceFiltering()
	local map = workspace:FindFirstChild("Map")
	if map then
		ftapState.ambienceConns[#ftapState.ambienceConns+1] = map.ChildAdded:Connect(function(child)
			if child and child.Name=="MapNoises" then
				if state.ftapDefaultAmbienceEnabled then
					if not ftapState.ambienceClone then
						ftapState.ambienceClone = cloneIfOk(child)
					end
				else
					task.defer(applyAmbienceFilter)
				end
			end
		end)
	end
	applyAmbienceFilter()
end

local refreshToggle, refreshNoclip, refreshThirdPerson, refreshSettingsToggles
local refreshFtapToggles, refreshMapPresetButtons, refreshMapResetButton
local refreshFpsSlider, refreshFovSlider, refreshJumpSlider, refreshGravitySlider, refreshTodSlider
local setSliderVisual

local function setResetMapAmbienceActive(enabled)
	state.resetMapAmbienceActive = enabled==true
	if refreshMapResetButton then refreshMapResetButton() end
end

local function setMapEffectsMuted(enabled)
	state.mapEffectsMuted = enabled==true
	if state.mapEffectsMuted then clearMutedEffects() end
end

local function setFTAPMap(selection)
	local valid = {Default=true,Foggy=true,Christmas=true}
	if selection~=nil and not valid[selection] then return end

	if not loadFTAPScripts() then
		if refreshFtapToggles then refreshFtapToggles() end; return
	end

	if state.mapEffectsMuted then setMapEffectsMuted(false) end
	snapshotMap()
	restoreMap()
	state.currentMapPreset = nil
	setResetMapAmbienceActive(true)
	revertAllFTAP()
	setXmasPropsVisible(false)
	state.activeFTAPMap = nil
	if refreshMapPresetButtons then refreshMapPresetButtons() end
	task.defer(applyAmbienceFilter)

	if selection=="Default" and type(_G.ApplyDefaultMap)=="function" then
		pcall(_G.ApplyDefaultMap)
		state.activeFTAPMap = "Default"
	elseif selection=="Foggy" and type(_G.ApplyFoggyMap)=="function" then
		pcall(_G.ApplyFoggyMap)
		state.activeFTAPMap = "Foggy"
	elseif selection=="Christmas" and type(_G.ApplyXmasMap)=="function" then
		pcall(_G.ApplyXmasMap)
		setXmasPropsVisible(true)
		state.activeFTAPMap = "Christmas"
	end

	state.todLocked = (state.activeFTAPMap == nil)
	if refreshFtapToggles then refreshFtapToggles() end
	if refreshMapPresetButtons then refreshMapPresetButtons() end
end

local function toggleFTAPMap(selection)
	if state.activeFTAPMap==selection then
		revertAllFTAP()
		setXmasPropsVisible(false)
		state.activeFTAPMap = nil
		state.todLocked = true
		if refreshFtapToggles then refreshFtapToggles() end
	else
		setFTAPMap(selection)
	end
end

local function toggleResetMapAmbience()
	if state.resetMapAmbienceActive then
		revertAllFTAP()
		state.activeFTAPMap = nil
		if refreshFtapToggles then refreshFtapToggles() end
		setResetMapAmbienceActive(false)
	else
		if state.mapEffectsMuted then setMapEffectsMuted(false) end
		snapshotMap()
		restoreMap()
		state.currentMapPreset = nil
		setResetMapAmbienceActive(true)
		if refreshMapPresetButtons then refreshMapPresetButtons() end
		if refreshFtapToggles then refreshFtapToggles() end
		task.defer(applyAmbienceFilter)
	end
end

local function setMapPreset(name)
	local info = MAP_PRESET[name]
	if not info then return end

	snapshotMap()
	_G.SoggyMapPresetToken = tostring(os.clock())..name

	if state.mapEffectsMuted then setMapEffectsMuted(false) end
	revertAllFTAP()
	state.activeFTAPMap = nil
	if refreshFtapToggles then refreshFtapToggles() end
	setResetMapAmbienceActive(false)
	restoreMap()
	state.currentMapPreset = name
	state.todLocked = true
	if refreshMapPresetButtons then refreshMapPresetButtons() end

	local ok, err = pcall(function()
		local body = httpGet(info.Url)
		if body then loadstring(body)() end
	end)
	if not ok then
		warn("Map preset ["..name.."] failed: "..tostring(err))
		state.currentMapPreset = nil
		restoreMap()
		if refreshMapPresetButtons then refreshMapPresetButtons() end
	end

	task.defer(applyAmbienceFilter)
end

local function setCommandStatus(msg)
	state.commandStatusToken += 1
	local token = state.commandStatusToken
	if refs.commandTitle then
		refs.commandTitle.Text = msg and ("Command Bar - "..msg) or "Command Bar"
	end
	task.delay(2.5, function()
		if state.commandStatusToken==token and refs.commandTitle then
			refs.commandTitle.Text = "Command Bar"
		end
	end)
end

local COMMANDS = {
	goto = function(arg)
		local p, err = findPlayerMatch(arg)
		if not p then return false, err end
		local _,_,lr = getCharParts(player)
		local _,_,tr = getCharParts(p)
		if not lr or not tr then return false,"character not ready" end
		lr.CFrame = tr.CFrame + Vector3.new(3,2,0)
		return true, "goto "..p.Name
	end,
	tp = function(arg, ...) return COMMANDS.goto(arg, ...) end,

	esp = function(arg)
		if normalizeStr(arg)=="@all" then
			esp.allEnabled=true; espAll(); enableEspAllFuture()
			return true,"esp all"
		end
		local p, err = findPlayerMatch(arg)
		if not p then return false, err end
		local ok, e = espPlayer(p)
		if not ok then return false, e end
		return true, "esp "..p.Name
	end,

	unesp = function(arg)
		if normalizeStr(arg)=="@all" then clearAllEsp(); return true,"unesp all" end
		local p, err = findPlayerMatch(arg)
		if not p then return false, err end
		clearEspPlayer(p); return true,"unesp "..p.Name
	end,

	view = function(arg)
		local p, err = findPlayerMatch(arg)
		if not p then return false, err end
		local ok, e = setView(p)
		if not ok then return false, e end
		return true,"view "..p.Name
	end,
	lookat = function(arg, ...) return COMMANDS.view(arg, ...) end,

	unview    = function() resetView(); return true,"unview" end,
	unlookat  = function() resetView(); return true,"unview" end,

	respawn = function()
		local char = player.Character
		if not char then return false,"character not ready" end
		char:BreakJoints(); return true,"respawn"
	end,
	reset = function(...) return COMMANDS.respawn(...) end,

	noclip    = function() startNoclip();    if refreshNoclip then refreshNoclip() end; return true,"noclip"    end,
	unnoclip  = function() stopNoclip();     if refreshNoclip then refreshNoclip() end; return true,"unnoclip"  end,

	rj        = function() task.defer(rejoinServer); return true,"rejoin"     end,
	rejoin    = function() task.defer(rejoinServer); return true,"rejoin"     end,
	serverhop = function() task.defer(serverHop);   return true,"serverhop"  end,
}

local function runCommand(raw)
	local trimmed = tostring(raw or ""):match("^%s*(.-)%s*$")
	if trimmed=="" or trimmed:sub(1,1)~=";" then return false,"missing ;" end
	local body = trimmed:sub(2):match("^%s*(.-)%s*$")
	if body=="" then return false,"empty command" end

	local words = splitWords(body)
	local action = normalizeStr(words[1])
	local arg    = #words>=2 and table.concat(words," ",2) or ""

	local fn = COMMANDS[action]
	if not fn then return false,"unknown command" end
	return fn(arg)
end

local function palletGetParts(model)
	local parts = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then parts[#parts+1] = d end
	end
	return parts
end

local function palletIsTarget(obj)
	return obj and obj:IsA("Model") and obj.Name == PALLET_TARGET_NAME
end

local function palletRemoveDiamondEmitterFromPart(part)
	if not part then return end
	local existing = part:FindFirstChild(PALLET_DIAMOND_EMITTER)
	if existing then existing:Destroy() end
end

local function palletRemoveDiamondEmitter(model)
	if not model then return end
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("ParticleEmitter") and obj.Name == PALLET_DIAMOND_EMITTER then
			obj:Destroy()
		end
	end
end

local function palletApplyDiamondEmitter(soundPart)
	if not soundPart or not soundPart:IsA("BasePart") then return end
	if soundPart:FindFirstChild(PALLET_DIAMOND_EMITTER) then return end

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = PALLET_DIAMOND_EMITTER
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.000000, Color3.fromRGB(105, 248, 255)),
		ColorSequenceKeypoint.new(0.515571, Color3.fromRGB(138, 253, 255)),
		ColorSequenceKeypoint.new(1.000000, Color3.fromRGB(168, 255, 250)),
	})
	emitter.LightEmission = 1
	emitter.LightInfluence = 1
	emitter.Orientation = Enum.ParticleOrientation.FacingCamera
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0.000000, 0.000000, 0.000000),
		NumberSequenceKeypoint.new(0.098381, 0.750000, 0.000000),
		NumberSequenceKeypoint.new(0.298879, 0.000000, 0.000000),
		NumberSequenceKeypoint.new(0.503113, 0.812500, 0.000000),
		NumberSequenceKeypoint.new(0.702366, 0.000000, 0.000000),
		NumberSequenceKeypoint.new(0.900374, 0.750000, 0.000000),
		NumberSequenceKeypoint.new(1.000000, 0.000000, 0.000000),
	})
	emitter.Squash = NumberSequence.new(0)
	emitter.Texture = "rbxassetid://5946093983"
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.000000, 1.000000, 0.000000),
		NumberSequenceKeypoint.new(0.117647, 0.076503, 0.000000),
		NumberSequenceKeypoint.new(0.206723, 0.344262, 0.000000),
		NumberSequenceKeypoint.new(0.255462, 0.316940, 0.000000),
		NumberSequenceKeypoint.new(0.295798, 0.191257, 0.000000),
		NumberSequenceKeypoint.new(0.321008, 0.300546, 0.000000),
		NumberSequenceKeypoint.new(0.394958, 0.426230, 0.000000),
		NumberSequenceKeypoint.new(0.490756, 0.306011, 0.000000),
		NumberSequenceKeypoint.new(0.566387, 0.568306, 0.000000),
		NumberSequenceKeypoint.new(0.625210, 0.464481, 0.000000),
		NumberSequenceKeypoint.new(0.652101, 0.322404, 0.000000),
		NumberSequenceKeypoint.new(0.729412, 0.655738, 0.000000),
		NumberSequenceKeypoint.new(0.779832, 0.639344, 0.000000),
		NumberSequenceKeypoint.new(0.838655, 0.699454, 0.000000),
		NumberSequenceKeypoint.new(0.941176, 0.513661, 0.000000),
		NumberSequenceKeypoint.new(0.959664, 0.945355, 0.000000),
		NumberSequenceKeypoint.new(1.000000, 0.000000, 0.000000),
	})
	emitter.ZOffset = 0
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Enabled = true
	emitter.Lifetime = NumberRange.new(2.5)
	emitter.Rate = 3
	emitter.Speed = NumberRange.new(1)
	emitter.Rotation = NumberRange.new(-543)
	emitter.RotSpeed = NumberRange.new(-20)
	emitter.SpreadAngle = Vector2.new(360, 360)
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Acceleration = Vector3.new(0, 0, 0)
	emitter.Drag = 0
	emitter.LockedToPart = true
	emitter.TimeScale = 1
	emitter.VelocityInheritance = 0
	emitter.WindAffectsDrag = false
	emitter.Parent = soundPart
end

local function palletPaintPart(part, color, material)
	if part and part:IsA("BasePart") then
		part.Color = color
		part.Material = material
		if part.Name == "SoundPart" then
			if palletState.diamondActive then
				palletApplyDiamondEmitter(part)
			else
				palletRemoveDiamondEmitterFromPart(part)
			end
		end
	end
end

local function palletApplyToModel(model, color, material)
	if not model or not model.Parent then return end
	if not palletState.diamondActive then palletRemoveDiamondEmitter(model) end
	for _, part in ipairs(palletGetParts(model)) do
		palletPaintPart(part, color, material)
	end
end

local function palletTrackModel(model)
	if not palletIsTarget(model) or palletPaintConnections[model] then return end
	local conns = {}
	palletPaintConnections[model] = conns

	conns[#conns+1] = model.DescendantAdded:Connect(function(obj)
		if obj:IsA("BasePart") then
			palletPaintPart(obj, palletState.appliedColor, palletState.selectedMaterial)
			task.defer(function()
				if obj.Parent then palletPaintPart(obj, palletState.appliedColor, palletState.selectedMaterial) end
			end)
		end
	end)

	conns[#conns+1] = model.AncestryChanged:Connect(function(_, parent)
		if parent then return end
		local list = palletPaintConnections[model]
		if list then
			for _, conn in ipairs(list) do
				if conn then conn:Disconnect() end
			end
			palletPaintConnections[model] = nil
		end
	end)
end

local function palletForcePaintModel(model, color, material)
	palletTrackModel(model)
	palletApplyToModel(model, color, material)
	for _, delayTime in ipairs({0.05, 0.15, 0.35, 0.75, 1.5}) do
		task.delay(delayTime, function()
			if model and model.Parent then
				palletApplyToModel(model, palletState.appliedColor, palletState.selectedMaterial)
			end
		end)
	end
end

local function palletApplyAll(color, material)
	if not palletToysFolder then return end
	for _, obj in ipairs(palletToysFolder:GetChildren()) do
		if palletIsTarget(obj) then palletForcePaintModel(obj, color, material) end
	end
end

local function palletApplyMaterialAll(material)
	if not palletToysFolder then return end
	for _, obj in ipairs(palletToysFolder:GetChildren()) do
		if palletIsTarget(obj) then
			palletTrackModel(obj)
			for _, p in ipairs(palletGetParts(obj)) do p.Material = material end
		end
	end
end

local function palletQueueMaterial()
	if palletState.matQueued then return end
	palletState.matQueued = true
	task.defer(function()
		local dt = tick() - palletState.lastMatApply
		if dt < PALLET_APPLY_RATE then task.wait(PALLET_APPLY_RATE - dt) end
		palletState.lastMatApply = tick()
		palletState.matQueued = false
		palletApplyMaterialAll(palletState.selectedMaterial)
	end)
end

local function palletDestroyAll()
	if not palletToysFolder or not destroyToyRemote then return end
	for _, toy in ipairs(palletToysFolder:GetChildren()) do
		if toy:IsA("Model") then destroyToyRemote:FireServer(toy) end
	end
end

local function palletRGB(color)
	return {
		r = math.floor(color.R*255+0.5),
		g = math.floor(color.G*255+0.5),
		b = math.floor(color.B*255+0.5),
	}
end

local function palletFindPreset(color, material)
	local rgb = palletRGB(color)
	local matName = palletMatByEnum[material]
	for i, p in ipairs(palletState.presetData.presets) do
		if p.r==rgb.r and p.g==rgb.g and p.b==rgb.b and p.material==matName then
			return i
		end
	end
	return nil
end

local refreshPalletPresetList

local function palletCopyPreset(p)
	return {
		name = p.name,
		r = math.clamp(tonumber(p.r) or 0, 0, 255),
		g = math.clamp(tonumber(p.g) or 0, 0, 255),
		b = math.clamp(tonumber(p.b) or 0, 0, 255),
		material = tostring(p.material or "WoodPlanks"),
		special = p.special,
		cyclePosition = tonumber(p.cyclePosition) or 0,
	}
end

local function palletPresetKey(p)
	return tostring(p.name or "").."|"..tostring(p.r).."|"..tostring(p.g).."|"..tostring(p.b).."|"..tostring(p.material).."|"..tostring(p.special or "")
end

local function palletAddMissingDefaultPresets()
	local existing = {}
	for _, p in ipairs(palletState.presetData.presets) do
		existing[palletPresetKey(p)] = true
		if p.name then existing[tostring(p.name)] = true end
	end
	local added = 0
	for _, p in ipairs(PALLET_DEFAULT_PRESETS) do
		local cp = palletCopyPreset(p)
		if palletMatByName[cp.material] and not existing[palletPresetKey(cp)] and not existing[tostring(cp.name or "")] then
			cp.cyclePosition = #palletState.presetData.presets + 1
			palletState.presetData.presets[#palletState.presetData.presets+1] = cp
			existing[palletPresetKey(cp)] = true
			if cp.name then existing[tostring(cp.name)] = true end
			added += 1
		end
	end
	return added
end

local function palletSaveFile()
	if not fnWriteFile then return end
	local d = palletState.presetData
	for i, p in ipairs(d.presets) do p.cyclePosition = i end
	local lines = {'{',
		'  "version": '..d.version..',',
		'  "selectedIndex": '..d.selectedIndex..',',
		'  "presets": [',
	}
	for i, p in ipairs(d.presets) do
		local comma = i < #d.presets and "," or ""
		local fields = {
			'"r":'..p.r,
			'"g":'..p.g,
			'"b":'..p.b,
			'"material":"'..tostring(p.material)..'"',
			'"cyclePosition":'..p.cyclePosition,
		}
		if p.name then table.insert(fields, 1, '"name":"'..tostring(p.name):gsub('"','\\"')..'"') end
		if p.special then fields[#fields+1] = '"special":"'..tostring(p.special):gsub('"','\\"')..'"' end
		lines[#lines+1] = '    {'..table.concat(fields, ',')..'}'..comma
	end
	lines[#lines+1] = '  ]'; lines[#lines+1] = '}'
	pcall(fnWriteFile, PALLET_PRESET_FILE, table.concat(lines,"\n"))
end

local function palletLoadFile()
	if not (fnIsFile and fnReadFile) then
		palletAddMissingDefaultPresets()
		return
	end
	local ok, exists = pcall(fnIsFile, PALLET_PRESET_FILE)
	if not ok or not exists then
		palletAddMissingDefaultPresets()
		palletSaveFile()
		return
	end
	local okR, raw = pcall(fnReadFile, PALLET_PRESET_FILE)
	if not okR or type(raw)~="string" or raw=="" then
		palletAddMissingDefaultPresets()
		palletSaveFile()
		return
	end
	local okD, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
	if not okD or type(decoded)~="table" then
		palletAddMissingDefaultPresets()
		palletSaveFile()
		return
	end

	decoded.version = 1
	decoded.selectedIndex = tonumber(decoded.selectedIndex) or 0
	decoded.presets = type(decoded.presets)=="table" and decoded.presets or {}

	local cleaned = {}
	for _, p in ipairs(decoded.presets) do
		if type(p)=="table" and palletMatByName[tostring(p.material or "")] then
			cleaned[#cleaned+1] = {
				name = type(p.name)=="string" and p.name ~= "" and p.name or nil,
				r = math.clamp(tonumber(p.r) or 0, 0, 255),
				g = math.clamp(tonumber(p.g) or 0, 0, 255),
				b = math.clamp(tonumber(p.b) or 0, 0, 255),
				material = tostring(p.material),
				special = type(p.special)=="string" and p.special ~= "" and p.special or nil,
				cyclePosition = #cleaned+1,
			}
		end
	end
	decoded.presets = cleaned
	decoded.selectedIndex = #cleaned==0 and 0 or math.clamp(decoded.selectedIndex, 0, #cleaned)
	palletState.presetData = decoded
end

local function palletRestoreDefaultPresets()
	local added = palletAddMissingDefaultPresets()
	palletSaveFile()
	if refreshPalletPresetList then refreshPalletPresetList() end
	return added
end

local function palletUpdateSaveBtn()
	if not palletRefs.saveBtn then return end
	palletRefs.saveBtn.Text = palletFindPreset(palletState.appliedColor, palletState.selectedMaterial)
		and "Unsave Preset" or "Save Preset"
end

local function palletUpdateRGB()
	local r = math.floor(palletState.previewColor.R*255+0.5)
	local g = math.floor(palletState.previewColor.G*255+0.5)
	local b = math.floor(palletState.previewColor.B*255+0.5)
	if palletRefs.rBox and not palletRefs.rBox:IsFocused() then palletRefs.rBox.Text=tostring(r) end
	if palletRefs.gBox and not palletRefs.gBox:IsFocused() then palletRefs.gBox.Text=tostring(g) end
	if palletRefs.bBox and not palletRefs.bBox:IsFocused() then palletRefs.bBox.Text=tostring(b) end
end

local function palletUpdatePreview()
	palletState.previewColor = Color3.fromHSV(
		palletState.pickerHue, palletState.pickerSat, palletState.brightness)
	if palletRefs.preview then palletRefs.preview.BackgroundColor3 = palletState.previewColor end
	palletUpdateRGB()
end

local function palletSyncUIToColor(color)
	local h,s,v = color:ToHSV()
	palletState.pickerHue = h
	palletState.pickerSat = s
	palletState.brightness = v
	
	if palletRefs.cursor then palletRefs.cursor.Position = UDim2.new(h,0,s,0) end
	if palletRefs.handle  then palletRefs.handle.Position = UDim2.new(v,0,0.5,0) end
	palletUpdatePreview()
end

local function palletSyncUI()
	palletSyncUIToColor(palletState.appliedColor)
	if palletRefs.dropBtn then
		palletRefs.dropBtn.Text = (palletMatByEnum[palletState.selectedMaterial] or "WoodPlanks").."  ▼"
	end
	palletUpdateSaveBtn()
end

local function palletFeedback(btn, defaultText, text)
	if not btn then return end
	palletState.feedbackToken += 1
	local token = palletState.feedbackToken
	btn.Text = text
	task.delay(0.8, function()
		if token==palletState.feedbackToken and btn and btn.Parent then
			btn.Text = defaultText
		end
	end)
end

local function palletApplyPresetByIndex(index)
	local p = palletState.presetData.presets[index]; if not p then return end
	local mat = palletMatByName[p.material]; if not mat then return end
	palletState.appliedColor = Color3.fromRGB(p.r, p.g, p.b)
	palletState.selectedMaterial = mat
	palletState.diamondActive = p.special == "DiamondPallet"
	palletState.presetData.selectedIndex = index
	palletSyncUI()
	palletApplyAll(palletState.appliedColor, palletState.selectedMaterial)
	palletSaveFile()
	if refreshPalletPresetList then refreshPalletPresetList() end
end

local function palletCyclePreset()
	local count = #palletState.presetData.presets
	if count==0 then return false end
	local next = palletState.presetData.selectedIndex + 1
	if next > count then next = 1 end
	palletApplyPresetByIndex(next)
	return true
end

local function palletSavePreset()
	if palletFindPreset(palletState.appliedColor, palletState.selectedMaterial) then
		return false, "Already Saved"
	end
	local rgb = palletRGB(palletState.appliedColor)
	local matName = palletMatByEnum[palletState.selectedMaterial]
	if not matName then return false, "No Material" end
	palletState.presetData.presets[#palletState.presetData.presets+1] = {
		r=rgb.r, g=rgb.g, b=rgb.b,
		material=matName,
		cyclePosition=#palletState.presetData.presets+1,
	}
	palletState.presetData.selectedIndex = #palletState.presetData.presets
	palletSaveFile()
	palletUpdateSaveBtn()
	if refreshPalletPresetList then refreshPalletPresetList() end
	return true, "Saved"
end

local function palletUnsavePreset()
	local idx = palletFindPreset(palletState.appliedColor, palletState.selectedMaterial)
	if not idx then palletUpdateSaveBtn(); return false, "Not Saved" end
	table.remove(palletState.presetData.presets, idx)
	local count = #palletState.presetData.presets
	if count==0 then
		palletState.presetData.selectedIndex = 0
	elseif palletState.presetData.selectedIndex > count then
		palletState.presetData.selectedIndex = count
	elseif palletState.presetData.selectedIndex >= idx then
		palletState.presetData.selectedIndex = math.max(0, palletState.presetData.selectedIndex-1)
	end
	palletSaveFile()
	palletUpdateSaveBtn()
	if refreshPalletPresetList then refreshPalletPresetList() end
	return true, "Removed"
end

local function palletApplyColor()
	palletState.diamondActive = false
	palletState.appliedColor = palletState.previewColor
	palletApplyAll(palletState.appliedColor, palletState.selectedMaterial)
	local match = palletFindPreset(palletState.appliedColor, palletState.selectedMaterial)
	palletState.presetData.selectedIndex = match or 0
	palletSaveFile()
	palletUpdateSaveBtn()
	if refreshPalletPresetList then refreshPalletPresetList() end
end

local function palletReset()
	palletState.diamondActive = false
	palletState.appliedColor = palletState.defaultColor
	palletState.selectedMaterial = palletState.defaultMaterial
	palletState.presetData.selectedIndex = 0
	palletSyncUI()
	palletApplyAll(palletState.appliedColor, palletState.selectedMaterial)
	palletSaveFile()
	if refreshPalletPresetList then refreshPalletPresetList() end
end

local function palletSetColorFromRGB()
	if not palletRefs.rBox then return end
	local r = tonumber(palletRefs.rBox.Text)
	local g = tonumber(palletRefs.gBox.Text)
	local b = tonumber(palletRefs.bBox.Text)
	if not (r and g and b) then palletUpdateRGB(); return end
	r = math.clamp(math.floor(r+0.5),0,255)
	g = math.clamp(math.floor(g+0.5),0,255)
	b = math.clamp(math.floor(b+0.5),0,255)
	local h2,s2,v2 = Color3.fromRGB(r,g,b):ToHSV()
	palletState.pickerHue = h2
	palletState.pickerSat = s2
	palletState.brightness = v2
	if palletRefs.cursor then palletRefs.cursor.Position = UDim2.new(h2,0,s2,0) end
	if palletRefs.handle  then palletRefs.handle.Position  = UDim2.new(v2,0,0.5,0) end
	palletUpdatePreview()
end

local function palletMousePosition()
	local pos = UserInputService:GetMouseLocation()
	if refs.gui and refs.gui.IgnoreGuiInset then
		local inset = GuiService:GetGuiInset()
		pos = pos - inset
	end
	return pos
end

local function palletUpdatePickerPos(mousePos)
	local f = palletRefs.pickerFrame; if not f then return end
	local ap, as = f.AbsolutePosition, f.AbsoluteSize
	if as.X <= 0 or as.Y <= 0 then return end
	local x = math.clamp((mousePos.X - ap.X) / as.X, 0, 1)
	local y = math.clamp((mousePos.Y - ap.Y) / as.Y, 0, 1)
	palletState.pickerHue = x
	palletState.pickerSat = y
	if palletRefs.cursor then palletRefs.cursor.Position = UDim2.new(x, 0, y, 0) end
	palletUpdatePreview()
end

local function palletUpdateBrightness(mousePos)
	local f = palletRefs.brightnessBar; if not f then return end
	local ap, as = f.AbsolutePosition, f.AbsoluteSize
	if as.X <= 0 then return end
	local x = math.clamp((mousePos.X - ap.X) / as.X, 0, 1)
	palletState.brightness = x
	if palletRefs.handle then palletRefs.handle.Position = UDim2.new(x, 0, 0.5, 0) end
	palletUpdatePreview()
end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = parent
	return c
end

local function label(parent, text, size, pos, font, textSize, color, alignX)
	local l = Instance.new("TextLabel")
	l.Size               = size
	l.Position           = pos
	l.BackgroundTransparency = 1
	l.Text               = text or ""
	l.TextColor3         = color or Color3.fromRGB(241,244,248)
	l.Font               = font  or Enum.Font.GothamSemibold
	l.TextSize           = textSize or 14
	l.TextXAlignment     = alignX or Enum.TextXAlignment.Left
	l.Parent             = parent
	return l
end

local function button(parent, text, size, pos)
	local b = Instance.new("TextButton")
	b.Size              = size
	b.Position          = pos
	b.BackgroundColor3  = Color3.fromRGB(30,35,44)
	b.BorderSizePixel   = 0
	b.AutoButtonColor   = false
	b.Text              = text or ""
	b.TextColor3        = Color3.fromRGB(241,244,248)
	b.Font              = Enum.Font.GothamSemibold
	b.TextSize          = 14
	b.Parent            = parent
	corner(b, 10)
	return b
end

local function styleButton(b, nc, hc, pc)
	nc = nc or Color3.fromRGB(30,35,44)
	hc = hc or Color3.fromRGB(39,46,57)
	pc = pc or Color3.fromRGB(48,56,68)
	b.MouseEnter:Connect(function()    tween(b,{BackgroundColor3=hc}) end)
	b.MouseLeave:Connect(function()    tween(b,{BackgroundColor3=nc}) end)
	b.MouseButton1Down:Connect(function() tween(b,{BackgroundColor3=pc},TWEEN_FAST) end)
	b.MouseButton1Up:Connect(function()   tween(b,{BackgroundColor3=nc},TWEEN_MED)  end)
end

local function textBox(parent, placeholder, size, pos, initial)
	local box = Instance.new("TextBox")
	box.Size                = size
	box.Position            = pos
	box.BackgroundColor3    = Color3.fromRGB(30,35,44)
	box.BorderSizePixel     = 0
	box.ClearTextOnFocus    = false
	box.Text                = initial or ""
	box.PlaceholderText     = placeholder or ""
	box.TextColor3          = Color3.fromRGB(241,244,248)
	box.PlaceholderColor3   = Color3.fromRGB(150,150,150)
	box.Font                = Enum.Font.GothamSemibold
	box.TextSize            = 14
	box.TextXAlignment      = Enum.TextXAlignment.Left
	box.Parent              = parent
	corner(box, 10)
	local pad = Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(0,10); pad.Parent=box
	return box
end

local function section(parent, height, order)
	local f = Instance.new("Frame")
	f.Size             = UDim2.new(1,-2,0,height)
	f.BackgroundColor3 = Color3.fromRGB(22,26,33)
	f.BorderSizePixel  = 0
	f.LayoutOrder      = order
	f.Parent           = parent
	corner(f, 12)
	return f
end

local function toggle(parent, pos)
	local track = Instance.new("TextButton")
	track.Size             = UDim2.new(0,58,0,30)
	track.Position         = pos
	track.BackgroundColor3 = Color3.fromRGB(72,80,94)
	track.BorderSizePixel  = 0
	track.AutoButtonColor  = false
	track.Text             = ""
	track.Parent           = parent
	corner(track, 999)

	local knob = Instance.new("Frame")
	knob.Size             = UDim2.new(0,24,0,24)
	knob.Position         = UDim2.new(0,3,0,3)
	knob.BackgroundColor3 = Color3.fromRGB(248,250,255)
	knob.BorderSizePixel  = 0
	knob.Parent           = track
	corner(knob, 999)

	return track, knob
end

local function separator(parent, order)
	local holder = Instance.new("Frame")
	holder.Size                = UDim2.new(1,-2,0,14)
	holder.BackgroundTransparency = 1
	holder.LayoutOrder         = order
	holder.Parent              = parent

	local line = Instance.new("Frame")
	line.AnchorPoint       = Vector2.new(0.5,0.5)
	line.Position          = UDim2.new(0.5,0,0.5,0)
	line.Size              = UDim2.new(1,-18,0,1)
	line.BackgroundColor3  = Color3.fromRGB(70,78,92)
	line.BorderSizePixel   = 0
	line.Parent            = holder
end

local function scrolledPage(parent)
	local page = Instance.new("Frame")
	page.Size                = UDim2.new(1,0,1,0)
	page.BackgroundTransparency = 1
	page.Visible             = false
	page.Parent              = parent

	local scroller = Instance.new("ScrollingFrame")
	scroller.Size              = UDim2.new(1,-12,1,-12)
	scroller.Position          = UDim2.new(0,6,0,6)
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel   = 0
	scroller.ScrollBarThickness = 3
	scroller.ScrollBarImageColor3 = Color3.fromRGB(92,102,120)
	scroller.CanvasSize        = UDim2.new(0,0,0,0)
	scroller.Parent            = page

	local layout = Instance.new("UIListLayout")
	layout.Padding    = UDim.new(0,8)
	layout.SortOrder  = Enum.SortOrder.LayoutOrder
	layout.Parent     = scroller

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroller.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+8)
	end)

	return page, scroller
end

setSliderVisual = function(key, alpha, text)
	local s = refs.sliders[key]; if not s then return end
	alpha = math.clamp(alpha, 0, 1)
	s.fill.Size      = UDim2.new(alpha, 0, 1, 0)
	s.knob.Position  = UDim2.new(alpha, 0, 0.5, 0)
	s.hitbox.Position = s.knob.Position
	s.valueLabel.Text = tostring(text)
end

local function makeSliderSection(parent, order, titleText, key)
	local s = section(parent, 74, order)
	label(s, titleText, UDim2.new(1,-20,0,20), UDim2.new(0,12,0,10))
	local vl = label(s, "", UDim2.new(0,48,0,20), UDim2.new(1,-52,0,10),
		Enum.Font.GothamSemibold, 13, Color3.fromRGB(190,190,190), Enum.TextXAlignment.Right)

	local track = Instance.new("Frame")
	track.Size            = UDim2.new(1,-24,0,8)
	track.Position        = UDim2.new(0,12,0,46)
	track.BackgroundColor3 = Color3.fromRGB(39,45,55)
	track.BorderSizePixel = 0
	track.Parent          = s
	corner(track, 999)

	local fill = Instance.new("Frame")
	fill.Size             = UDim2.new(0,0,1,0)
	fill.BackgroundColor3 = Color3.fromRGB(98,122,168)
	fill.BorderSizePixel  = 0
	fill.Parent           = track
	corner(fill, 999)

	local knob = Instance.new("Frame")
	knob.Size             = UDim2.new(0,16,0,16)
	knob.AnchorPoint      = Vector2.new(0.5,0.5)
	knob.Position         = UDim2.new(0,0,0.5,0)
	knob.BackgroundColor3 = Color3.fromRGB(248,250,255)
	knob.BorderSizePixel  = 0
	knob.Parent           = track
	corner(knob, 999)

	local hitbox = Instance.new("TextButton")
	hitbox.Size              = UDim2.new(0,30,0,30)
	hitbox.AnchorPoint       = Vector2.new(0.5,0.5)
	hitbox.Position          = knob.Position
	hitbox.BackgroundTransparency = 1
	hitbox.BorderSizePixel   = 0
	hitbox.Text              = ""
	hitbox.AutoButtonColor   = false
	hitbox.Parent            = track

	refs.sliders[key] = { valueLabel=vl, track=track, fill=fill, knob=knob, hitbox=hitbox }
	return s
end

local function makeResettableSliderSection(parent, order, titleText, key, onReset)
	local s = makeSliderSection(parent, order, titleText, key)
	local vl = refs.sliders[key].valueLabel
	vl.Position = UDim2.new(1,-90,0,10)
	vl.Size     = UDim2.new(0,60,0,20)

	local rb = Instance.new("ImageButton")
	rb.Size                = UDim2.new(0,16,0,16)
	rb.Position            = UDim2.new(1,-26,0,12)
	rb.BackgroundTransparency = 1
	rb.BorderSizePixel     = 0
	rb.AutoButtonColor     = false
	rb.Image               = "rbxassetid://107192048421590"
	rb.ImageColor3         = Color3.fromRGB(200,200,200)
	rb.ImageTransparency   = 0.2
	rb.Parent              = s
	rb.MouseEnter:Connect(function()  tween(rb,{ImageTransparency=0})   end)
	rb.MouseLeave:Connect(function()  tween(rb,{ImageTransparency=0.2}) end)
	rb.MouseButton1Click:Connect(function() spinButton(rb); if onReset then onReset() end end)
	return s
end

local function bindSlider(key, setter)
	local s = refs.sliders[key]; if not s then return end
	local function begin(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 then
			state.draggingSlider = { track=s.track, setter=setter }
			local alpha = math.clamp((input.Position.X - s.track.AbsolutePosition.X) / s.track.AbsoluteSize.X, 0, 1)
			setter(alpha)
		end
	end
	s.track.InputBegan:Connect(begin)
	s.hitbox.InputBegan:Connect(begin)
end

refreshJumpSlider = function()
	local hum = localHumanoid()
	local v = hum and (hum.UseJumpPower and hum.JumpPower or 24) or 24
	setSliderVisual("player_jump", math.clamp(v/300,0,1), math.floor(v+0.5))
end

refreshGravitySlider = function()
	local g = workspace.Gravity or 196.2
	setSliderVisual("player_gravity", math.clamp(g/500,0,1), math.floor(g+0.5))
end

refreshFpsSlider = function()
	local count = #FPS_CAP_OPTIONS
	local alpha = count>1 and (state.fpsCapIndex-1)/(count-1) or 0
	setSliderVisual("settings_fps", alpha, FPS_CAP_LABELS[state.fpsCapIndex])
end

local function clockTimeToLabel(t)
	local totalMins = math.floor(t * 60 + 0.5)  
	totalMins = math.clamp(totalMins, 0, 23*60+59)
	local hour24 = math.floor(totalMins / 60) % 24
	local mins   = totalMins % 60
	local ampm   = hour24 >= 12 and "PM" or "AM"
	local hour12 = hour24 % 12
	if hour12 == 0 then hour12 = 12 end
	return string.format("%d:%02d %s", hour12, mins, ampm)
end

local TOD_MAX = 23 + 59/60  

refreshTodSlider = function()
	local t = math.clamp(game:GetService("Lighting").ClockTime, 0, TOD_MAX)
	local alpha = math.clamp(t / TOD_MAX, 0, 1)
	setSliderVisual("map_tod", alpha, clockTimeToLabel(t))
end

refreshFovSlider = function()
	setSliderVisual("player_fov", math.clamp((state.targetFOV-1)/119,0,1), math.floor(state.targetFOV+0.5))
end

refreshToggle = function(track, knob, enabled)
	if track then track.BackgroundColor3 = enabled and Color3.fromRGB(98,122,168) or Color3.fromRGB(72,80,94) end
	if knob  then knob.Position          = enabled and UDim2.new(0,31,0,3)      or UDim2.new(0,3,0,3)        end
end

refreshNoclip = function()
	refreshToggle(refs.player.noclipTrack, refs.player.noclipKnob, noclip.enabled)
end

refreshThirdPerson = function()
	refreshToggle(refs.player.thirdTrack, refs.player.thirdKnob, state.thirdPersonEnabled)
end

refreshSettingsToggles = function()
	refreshToggle(refs.settings.reexecTrack, refs.settings.reexecKnob, state.reExecuteOnTeleport)
	refreshToggle(refs.settings.saveTrack,   refs.settings.saveKnob,   state.saveSettings)
end

refreshFtapToggles = function()
	refreshToggle(refs.map.ftapDefaultMapTrack,   refs.map.ftapDefaultMapKnob,   state.activeFTAPMap=="Default")
	refreshToggle(refs.map.ftapFoggyMapTrack,     refs.map.ftapFoggyMapKnob,     state.activeFTAPMap=="Foggy")
	refreshToggle(refs.map.ftapChristmasMapTrack, refs.map.ftapChristmasMapKnob, state.activeFTAPMap=="Christmas")
	refreshToggle(refs.map.effectsTrack, refs.map.effectsKnob, state.mapEffectsMuted)
	refreshToggle(refs.map.ftapDefaultAmbienceTrack, refs.map.ftapDefaultAmbienceKnob, state.ftapDefaultAmbienceEnabled)
end

refreshMapPresetButtons = function()
	for name, card in pairs(refs.map.presetButtons or {}) do
		local active = state.currentMapPreset==name
		card.BackgroundColor3 = active and Color3.fromRGB(52,62,78) or Color3.fromRGB(24,28,36)
		local stroke = card:FindFirstChild("PreviewStroke")
		local title  = card:FindFirstChild("PreviewTitle")
		if stroke then
			stroke.Color        = active and Color3.fromRGB(98,122,168) or Color3.fromRGB(58,66,80)
			stroke.Transparency = active and 0 or 0.18
		end
		if title then
			title.TextColor3 = active and Color3.fromRGB(241,244,248) or Color3.fromRGB(220,226,235)
		end
	end
	if refreshMapResetButton then refreshMapResetButton() end
end

refreshMapResetButton = function()
	local b = refs.map.resetAmbienceButton; if not b then return end
	b.ImageColor3        = Color3.fromRGB(241,244,248)
	b.ImageTransparency  = 0.15
	b.BackgroundTransparency = 1
	b.BorderSizePixel    = 0
	b.AutoButtonColor    = false
end

local function refreshScriptRow(name)
	local r = state.rowRefs[name]; if not r then return end
	local active = state.activeScripts[name]==true
	if r.ToggleTrack then r.ToggleTrack.BackgroundColor3 = active and Color3.fromRGB(98,122,168) or Color3.fromRGB(72,80,94) end
	if r.ToggleKnob  then r.ToggleKnob.Position          = active and UDim2.new(0,31,0,3)       or UDim2.new(0,3,0,3)       end
	if r.ActionButton then
		r.ActionButton.ImageTransparency = active and 0 or 0.2
		r.ActionButton.ImageColor3 = active and Color3.fromRGB(241,244,248) or Color3.fromRGB(205,212,224)
	end
end

local function refreshAllRows()
	for name in pairs(state.rowRefs) do refreshScriptRow(name) end
end

local function activateScript(info)
	if state.activeScripts[info.Name] then refreshScriptRow(info.Name); return true end
	local ok, err = pcall(function() if info.Action then info.Action(info) end end)
	if ok then
		state.activeScripts[info.Name] = true
		refreshScriptRow(info.Name)
		return true
	end
	warn("Failed to run "..info.Name..": "..tostring(err))
	return false, tostring(err)
end

local function deactivateScript(info)
	if not info.CanStop then return false,"can't stop" end
	local ok, err = pcall(function() if info.Stop then info.Stop() end end)
	if not ok then warn("Failed to stop "..info.Name..": "..tostring(err)); return false, tostring(err) end
	state.activeScripts[info.Name] = nil
	refreshScriptRow(info.Name)
	return true
end

local function toggleScript(info)
	if state.activeScripts[info.Name] then
		return deactivateScript(info)
	end
	return activateScript(info)
end

local function setMenuOpen(enabled)
	state.menuOpen = enabled==true
	if refs.frame then refs.frame.Visible = state.menuOpen end
	if refs.gui   then refs.gui.Enabled   = true end
	if state.menuOpen then
		state.unlockMouseUntil = tick() + 0.25
		UserInputService.MouseBehavior   = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
	camera.CameraType = Enum.CameraType.Custom
end

local PAGE_NAMES = {
	"Main/Displays","Player Settings","Script Settings",
	"Esp Settings","Map Settings","Pallet Settings",
	"Custom Keybinds","Info & More",
}

local function getHubParent()
	local okHui, hui = pcall(function()
		return gethui and gethui()
	end)
	if okHui and hui then return hui end

	local okCore, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if okCore and core then return core end

	return playerGui
end

local function buildShell()
	local hubParent = getHubParent()
	for _, parent in ipairs({ playerGui, hubParent }) do
		local old = parent and parent:FindFirstChild("LoadstringSelectorGui")
		if old then old:Destroy() end
	end

	local gui = Instance.new("ScreenGui")
	gui.Name            = "LoadstringSelectorGui"
	gui.ResetOnSpawn    = false
	gui.IgnoreGuiInset  = true
	gui.DisplayOrder    = 2147483647
	gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
	pcall(function() gui.OnTopOfCoreBlur = true end)
	gui.Parent          = hubParent
	refs.gui = gui

	local frame = Instance.new("Frame")
	frame.Name             = "Main"
	frame.Size             = UDim2.new(0,480,0,530)
	frame.AnchorPoint      = Vector2.new(0.5,0.5)
	frame.Position         = UDim2.new(0.5,0,0.5,0)
	frame.BackgroundColor3 = Color3.fromRGB(19,22,28)
	frame.BorderSizePixel  = 0
	frame.Parent           = gui
	corner(frame, 14)
	local fs = Instance.new("UIStroke")
	fs.Color=Color3.fromRGB(48,56,68); fs.Thickness=1.2; fs.Transparency=0.15; fs.Parent=frame
	refs.frame = frame

	local topBar = Instance.new("Frame")
	topBar.Name             = "TopBar"
	topBar.Size             = UDim2.new(1,0,0,42)
	topBar.BackgroundColor3 = Color3.fromRGB(26,30,38)
	topBar.BorderSizePixel  = 0
	topBar.Parent           = frame
	corner(topBar, 14)
	local fix = Instance.new("Frame")
	fix.Size=UDim2.new(1,0,0,16); fix.Position=UDim2.new(0,0,1,-16)
	fix.BackgroundColor3=Color3.fromRGB(26,30,38); fix.BorderSizePixel=0; fix.Parent=topBar

	local logo = Instance.new("ImageLabel")
	logo.Size=UDim2.new(0,34,0,34); logo.Position=UDim2.new(0,6,0.5,-18)
	logo.BackgroundTransparency=1; logo.Image="rbxassetid://96561699768956"; logo.Parent=topBar

	label(topBar,"Soggy-Script HUB",UDim2.new(1,-84,1,0),UDim2.new(0,42,0,0),Enum.Font.GothamBlack,17)

	local closeBtn = Instance.new("ImageButton")
	closeBtn.Size=UDim2.new(0,22,0,22); closeBtn.Position=UDim2.new(1,-33,0.5,-11)
	closeBtn.BackgroundTransparency=1; closeBtn.BorderSizePixel=0
	closeBtn.AutoButtonColor=false; closeBtn.Image="rbxassetid://138598738825070"
	closeBtn.ImageColor3=Color3.fromRGB(241,244,248); closeBtn.ImageTransparency=0.15
	closeBtn.Parent=topBar
	refs.closeButton = closeBtn
	refs.topBar      = topBar

	local sidebar = Instance.new("Frame")
	sidebar.Name=  "NavSidebar"
	sidebar.Size=  UDim2.new(0,148,1,-58)
	sidebar.Position=UDim2.new(0,10,0,48)
	sidebar.BackgroundColor3=Color3.fromRGB(14,17,23)
	sidebar.BorderSizePixel=0; sidebar.Parent=frame
	corner(sidebar, 12)

	local tabHolder = Instance.new("Frame")
	tabHolder.Size=UDim2.new(1,-20,0,0); tabHolder.Position=UDim2.new(0,10,0,12)
	tabHolder.BackgroundTransparency=1; tabHolder.AutomaticSize=Enum.AutomaticSize.Y
	tabHolder.Parent=sidebar
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.Padding=UDim.new(0,4); tabLayout.SortOrder=Enum.SortOrder.LayoutOrder; tabLayout.Parent=tabHolder

	for i, name in ipairs(PAGE_NAMES) do
		local btn = Instance.new("TextButton")
		btn.Size=UDim2.new(1,0,0,34); btn.LayoutOrder=i
		btn.BackgroundColor3=Color3.fromRGB(26,30,38); btn.BorderSizePixel=0
		btn.AutoButtonColor=false; btn.Text=name
		btn.TextColor3=Color3.fromRGB(205,212,224)
		btn.Font=Enum.Font.GothamSemibold; btn.TextSize=13
		btn.TextXAlignment=Enum.TextXAlignment.Left; btn.Parent=tabHolder
		corner(btn, 10)
		local pad=Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(0,12); pad.Parent=btn
		refs.tabButtons[name] = btn
	end

	local divider=Instance.new("Frame")
	divider.Size=UDim2.new(1,-20,0,1); divider.Position=UDim2.new(0,10,1,-92)
	divider.BackgroundColor3=Color3.fromRGB(58,64,76); divider.BorderSizePixel=0; divider.Parent=sidebar

	local card=Instance.new("Frame")
	card.Size=UDim2.new(1,-20,0,80); card.Position=UDim2.new(0,10,1,-88)
	card.BackgroundColor3=Color3.fromRGB(22,26,33); card.BorderSizePixel=0; card.Parent=sidebar
	corner(card,12)

	
	local dnLabel = label(card, player.DisplayName, UDim2.new(1,-16,0,18), UDim2.new(0,8,0,6),
		Enum.Font.GothamSemibold, 13, Color3.fromRGB(241,244,248))
	dnLabel.TextTruncate = Enum.TextTruncate.AtEnd

	local unLabel = label(card, "@"..player.Name, UDim2.new(1,-16,0,14), UDim2.new(0,8,0,22),
		Enum.Font.GothamSemibold, 11, Color3.fromRGB(170,178,192))
	unLabel.TextTruncate = Enum.TextTruncate.AtEnd

	
	local innerDiv = Instance.new("Frame")
	innerDiv.Size=UDim2.new(1,-16,0,1); innerDiv.Position=UDim2.new(0,8,0,40)
	innerDiv.BackgroundColor3=Color3.fromRGB(45,50,62); innerDiv.BorderSizePixel=0; innerDiv.Parent=card

	
	local avatar=Instance.new("ImageLabel")
	avatar.Size=UDim2.new(0,28,0,28); avatar.Position=UDim2.new(0,8,0,46)
	avatar.BackgroundColor3=Color3.fromRGB(30,35,44); avatar.BorderSizePixel=0; avatar.Parent=card
	corner(avatar, 999)
	local as=Instance.new("UIStroke"); as.Color=Color3.fromRGB(70,78,92); as.Thickness=1; as.Transparency=0.15; as.Parent=avatar

	
	local sessionLabel = label(card, "0:00:00", UDim2.new(1,-46,0,14), UDim2.new(0,42,0,50),
		Enum.Font.GothamSemibold, 11, Color3.fromRGB(140,150,168))
	sessionLabel.TextXAlignment = Enum.TextXAlignment.Left

	
	local sessionStart = tick()
	RunService.Heartbeat:Connect(function()
		local elapsed = math.floor(tick() - sessionStart)
		local h = math.floor(elapsed / 3600)
		local m = math.floor((elapsed % 3600) / 60)
		local s2 = elapsed % 60
		sessionLabel.Text = string.format("%d:%02d:%02d", h, m, s2)
	end)

	do
		local ok, thumb = pcall(Players.GetUserThumbnailAsync, Players, player.UserId,
			Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		if ok and type(thumb)=="string" and thumb~="" then avatar.Image=thumb end
	end

	local content = Instance.new("Frame")
	content.Size=UDim2.new(1,-180,1,-60); content.Position=UDim2.new(0,162,0,48)
	content.BackgroundColor3=Color3.fromRGB(16,19,25); content.BorderSizePixel=0; content.Parent=frame
	corner(content, 12)

	for _, name in ipairs(PAGE_NAMES) do
		local pg, sc = scrolledPage(content)
		pg.Name    = name:gsub("%s","").."Page"
		pg.Visible = (name=="Main/Displays")
		refs.pages[name] = { page=pg, scroller=sc }
	end
end

local function buildScriptsPage()
	local scroller = refs.pages["Main/Displays"].scroller
	local layout = scroller:FindFirstChildOfClass("UIListLayout")
	if layout then layout.Padding=UDim.new(0,10) end

	local separatorAdded = false
	for i, info in ipairs(SCRIPTS) do
		if not info.CanStop and i>1 and not separatorAdded then
			separator(scroller, i-1)
			separatorAdded = true
		end

		local row = Instance.new("Frame")
		row.Size=UDim2.new(1,-2,0,54); row.BackgroundTransparency=1
		row.LayoutOrder=i+(not info.CanStop and 1 or 0); row.Parent=scroller

		local card = Instance.new("Frame")
		card.Size=UDim2.new(1,0,1,0); card.BackgroundColor3=Color3.fromRGB(30,35,44)
		card.BorderSizePixel=0; card.Parent=row
		corner(card, 10)

		label(card, info.Name, UDim2.new(1,-96,0,20), UDim2.new(0,12,0,17))

		local function onToggle() toggleScript(info) end

		if info.CanStop then
			local tr, kn = toggle(card, UDim2.new(1,-70,0.5,-15))
			tr.MouseButton1Click:Connect(onToggle)
			state.rowRefs[info.Name] = { ToggleTrack=tr, ToggleKnob=kn }
		else
			local ab = Instance.new("ImageButton")
			ab.Size=UDim2.new(0,28,0,28); ab.AnchorPoint=Vector2.new(1,0.5)
			ab.Position=UDim2.new(1,-14,0.5,0); ab.BackgroundTransparency=1
			ab.BorderSizePixel=0; ab.AutoButtonColor=false
			ab.Image="rbxassetid://108915532102226"; ab.ImageTransparency=0.2
			ab.ImageColor3=Color3.fromRGB(205,212,224); ab.Parent=card
			ab.MouseButton1Click:Connect(function() spinButton(ab); onToggle() end)

			local ov=Instance.new("TextButton")
			ov.Size=UDim2.new(1,0,1,0); ov.BackgroundTransparency=1
			ov.BorderSizePixel=0; ov.Text=""; ov.AutoButtonColor=false; ov.Parent=card
			ov.MouseButton1Click:Connect(onToggle)

			state.rowRefs[info.Name] = { ActionButton=ab }
		end
		refreshScriptRow(info.Name)
	end

	separator(scroller, 99)

	local cmdSection = section(scroller, 68, 100)
	refs.commandTitle = label(cmdSection, "Command Bar", UDim2.new(1,-20,0,20), UDim2.new(0,12,0,8))
	refs.commandBox   = textBox(cmdSection, "Type command here", UDim2.new(1,-24,0,32), UDim2.new(0,12,0,28), state.commandText)
end

local function buildPlayerPage()
	local scroller = refs.pages["Player Settings"].scroller

	makeResettableSliderSection(scroller, 1, "JumpPower", "player_jump", function()
		local hum = localHumanoid()
		if hum then hum.UseJumpPower=true; hum.JumpPower=24 end
		refreshJumpSlider()
	end)

	makeResettableSliderSection(scroller, 2, "Gravity", "player_gravity", function()
		workspace.Gravity = state.defaultGravity or 196.2
		refreshGravitySlider()
	end)

	local nc = section(scroller, 58, 3)
	label(nc, "Noclip", UDim2.new(1,-90,0,20), UDim2.new(0,12,0,19))
	local nct, nck = toggle(nc, UDim2.new(1,-70,0.5,-15))
	nct.MouseButton1Click:Connect(function()
		if noclip.enabled then stopNoclip() else startNoclip() end
		refreshNoclip()
	end)
	refs.player.noclipTrack = nct
	refs.player.noclipKnob  = nck

	separator(scroller, 4)

	local cam = section(scroller, 58, 5)
	label(cam, "Camera Mode", UDim2.new(1,-90,0,20), UDim2.new(0,12,0,19))
	local camt, camk = toggle(cam, UDim2.new(1,-70,0.5,-15))
	camt.MouseButton1Click:Connect(function()
		state.thirdPersonEnabled = not state.thirdPersonEnabled
		applyThirdPerson()
		refreshThirdPerson()
		if state.saveSettings then saveSettings() end
	end)
	refs.player.thirdTrack = camt
	refs.player.thirdKnob  = camk

	makeResettableSliderSection(scroller, 6, "FOV", "player_fov", function()
		state.targetFOV = 70
		if camera then camera.FieldOfView=state.targetFOV end
		refreshFovSlider()
		if state.saveSettings then saveSettings() end
	end)

	local resp = section(scroller, 62, 7)
	local rb = button(resp, "Respawn", UDim2.new(1,-20,0,34), UDim2.new(0,10,0,14))
	styleButton(rb)
	rb.MouseButton1Click:Connect(function()
		local char = player.Character; if char then char:BreakJoints() end
	end)
end

local function buildSettingsPage()
	local scroller = refs.pages["Script Settings"].scroller

	local tpSec = section(scroller, 62, 1)
	local rjBtn = button(tpSec, "Rejoin",     UDim2.new(0.5,-16,0,34), UDim2.new(0,10,0,14))
	local shBtn = button(tpSec, "Server Hop", UDim2.new(0.5,-16,0,34), UDim2.new(0.5,6,0,14))
	styleButton(rjBtn); styleButton(shBtn)
	rjBtn.MouseButton1Click:Connect(rejoinServer)
	shBtn.MouseButton1Click:Connect(serverHop)

	local rex = section(scroller, 58, 2)
	label(rex, "Re-Execute On Teleport", UDim2.new(1,-90,0,20), UDim2.new(0,12,0,19))
	local ret, rek = toggle(rex, UDim2.new(1,-70,0.5,-15))
	ret.MouseButton1Click:Connect(function()
		state.reExecuteOnTeleport = not state.reExecuteOnTeleport
		refreshSettingsToggles()
	end)
	refs.settings.reexecTrack = ret
	refs.settings.reexecKnob  = rek

	local sv = section(scroller, 58, 3)
	label(sv, "Save Settings", UDim2.new(1,-90,0,20), UDim2.new(0,12,0,19))
	local svt, svk = toggle(sv, UDim2.new(1,-70,0.5,-15))
	svt.MouseButton1Click:Connect(function()
		state.saveSettings = not state.saveSettings
		refreshSettingsToggles()
		persistSettings()
	end)
	refs.settings.saveTrack = svt
	refs.settings.saveKnob  = svk

	makeSliderSection(scroller, 4, "FPS Cap", "settings_fps")
	local vl = refs.sliders["settings_fps"] and refs.sliders["settings_fps"].valueLabel
	if vl then vl.Position=UDim2.new(1,-72,0,10); vl.Size=UDim2.new(0,54,0,20) end
end

local function buildMapPage()
	local scroller = refs.pages["Map Settings"].scroller
	refs.map.presetButtons = {}

	local presetSec = section(scroller, 602, 1)
	label(presetSec,"Map Presets (4 more presets soon)",UDim2.new(1,-52,0,20),UDim2.new(0,12,0,12),Enum.Font.GothamBold,15)

	local rab = Instance.new("ImageButton")
	rab.Name="ResetAmbienceButton"; rab.Size=UDim2.new(0,18,0,18); rab.Position=UDim2.new(1,-30,0,13)
	rab.BackgroundTransparency=1; rab.BorderSizePixel=0; rab.AutoButtonColor=false
	rab.Image="rbxassetid://107192048421590"; rab.ImageColor3=Color3.fromRGB(241,244,248)
	rab.ImageTransparency=0.15; rab.Parent=presetSec
	rab.MouseButton1Click:Connect(function() spinButton(rab); toggleResetMapAmbience() end)
	refs.map.resetAmbienceButton = rab

	local CW, CH, IH, SX, GX, SY, GY = 124, 96, 52, 12, 10, 42, 10
	for idx, name in ipairs(MAP_PRESET_ORDER) do
		local info   = MAP_PRESET[name]
		local col    = (idx-1)%2
		local row    = math.floor((idx-1)/2)

		local card = Instance.new("TextButton")
		card.Name=name.."Card"; card.Text=""; card.AutoButtonColor=false
		card.Size=UDim2.new(0,CW,0,CH)
		card.Position=UDim2.new(0,SX+(CW+GX)*col,0,SY+(CH+GY)*row)
		card.BackgroundColor3=Color3.fromRGB(24,28,36); card.BorderSizePixel=0; card.Parent=presetSec
		corner(card, 10)

		local imgHolder = Instance.new("Frame")
		imgHolder.BackgroundColor3=Color3.fromRGB(18,22,28); imgHolder.Transparency=1
		imgHolder.BorderSizePixel=0; imgHolder.Size=UDim2.new(1,-14.4,0,62.4)
		imgHolder.Position=UDim2.new(0,6,0,6); imgHolder.Parent=card
		corner(imgHolder, 10)

		local img = Instance.new("ImageLabel")
		img.Size=UDim2.new(1,0,1,0); img.BackgroundTransparency=1
		img.Image=info.Image; img.ScaleType=Enum.ScaleType.Fit; img.Parent=imgHolder
		corner(img, 8)

		local t = Instance.new("TextLabel")
		t.Name="PreviewTitle"; t.BackgroundTransparency=1
		t.Size=UDim2.new(1,-12,0,30); t.Position=UDim2.new(0,8,0,IH+16)
		t.Font=Enum.Font.GothamBold; t.Text=info.DisplayName; t.TextSize=15
		t.TextXAlignment=Enum.TextXAlignment.Left; t.TextColor3=Color3.fromRGB(220,226,235)
		t.Parent=card

		card.MouseButton1Click:Connect(function() setMapPreset(name) end)
		refs.map.presetButtons[name] = card
	end

	local tSec = section(scroller, 90, 2)
	label(tSec,"Disable Map Visuals/Sounds",UDim2.new(1,-90,0,20),UDim2.new(0,12,0,14))
	local et, ek = toggle(tSec, UDim2.new(1,-70,0,12))
	et.MouseButton1Click:Connect(function() setMapEffectsMuted(not state.mapEffectsMuted); refreshFtapToggles() end)
	refs.map.effectsTrack = et; refs.map.effectsKnob = ek

	label(tSec,"FTAP Default Ambience",UDim2.new(1,-90,0,20),UDim2.new(0,12,0,52))
	local at, ak = toggle(tSec, UDim2.new(1,-70,0,50))
	at.MouseButton1Click:Connect(function()
		state.ftapDefaultAmbienceEnabled = not state.ftapDefaultAmbienceEnabled
		applyAmbienceFilter()
		refreshFtapToggles()
	end)
	refs.map.ftapDefaultAmbienceTrack = at; refs.map.ftapDefaultAmbienceKnob = ak

	separator(scroller, 3)

	
	local todSec = makeResettableSliderSection(scroller, 4, "Time Of Day", "map_tod", function()
		game:GetService("Lighting").ClockTime = state.defaultClockTime
		refreshTodSlider()
	end)

	
	game:GetService("Lighting"):GetPropertyChangedSignal("ClockTime"):Connect(function()
		if not state.draggingSlider or state.draggingSlider.track ~= (refs.sliders["map_tod"] and refs.sliders["map_tod"].track) then
			refreshTodSlider()
		end
	end)

	separator(scroller, 5)

	local ftapSec = section(scroller, 148, 6)
	label(ftapSec,"Non-Custom Maps",UDim2.new(1,-20,0,20),UDim2.new(0,12,0,12),Enum.Font.GothamBold,15)

	local function ftapRow(title, yOff, selection)
		label(ftapSec,title,UDim2.new(1,-90,0,20),UDim2.new(0,12,0,yOff))
		local t2, k2 = toggle(ftapSec, UDim2.new(1,-70,0,yOff-2))
		t2.MouseButton1Click:Connect(function() toggleFTAPMap(selection) end)
		return t2, k2
	end

	refs.map.ftapDefaultMapTrack,   refs.map.ftapDefaultMapKnob   = ftapRow("FTAP Default Map",   46, "Default")
	refs.map.ftapFoggyMapTrack,     refs.map.ftapFoggyMapKnob     = ftapRow("FTAP Foggy Map",     80, "Foggy")
	refs.map.ftapChristmasMapTrack, refs.map.ftapChristmasMapKnob = ftapRow("FTAP Christmas Map", 114,"Christmas")

	loadChristmasProps()
	setXmasPropsVisible(state.activeFTAPMap=="Christmas")
	refreshMapPresetButtons()
	refreshMapResetButton()
	refreshFtapToggles()
end

local function buildInfoPage()
	local scroller = refs.pages["Info & More"].scroller
	local layout = scroller:FindFirstChildOfClass("UIListLayout")
	if layout then layout.Padding=UDim.new(0,10) end

	local function keybindBox(titleText, text, order, totalHeight, bodyHeight)
		local box = section(scroller, totalHeight, order)
		label(box, titleText, UDim2.new(1,-20,0,20), UDim2.new(0,10,0,10), Enum.Font.GothamBold, 14)
		local back = Instance.new("Frame")
		back.Size=UDim2.new(1,-20,0,bodyHeight); back.Position=UDim2.new(0,10,0,34)
		back.BackgroundColor3=Color3.fromRGB(30,35,44); back.BorderSizePixel=0; back.Parent=box
		corner(back, 10)
		local lbl = label(back,text,UDim2.new(1,-12,1,-12),UDim2.new(0,6,0,6),
			Enum.Font.GothamSemibold,13,Color3.fromRGB(176,184,198))
		lbl.TextWrapped=true; lbl.TextYAlignment=Enum.TextYAlignment.Top
	end

	keybindBox("KBM Input Display Keybinds",
		"• B = Toggles UI\n• G = Cycles Control Buttons\n• Enter = Use Selected\n• Backspace = Deselects\n• Shift + B = Reset UI",
		1, 136, 90)

	separator(scroller, 2)

	keybindBox("Commands — prefix with ;",
		"• goto / tp [player]\n• esp [player/@all]\n• unesp [player/@all]\n• view / lookat [player]\n• unview / unlookat\n• noclip  •  unnoclip\n• rj / rejoin  •  serverhop\n• respawn / reset",
		3, 250, 200)
end

local function buildPlaceholderPage(name, title)
	local scroller = refs.pages[name].scroller
	local card = section(scroller, 88, 1)
	local t = label(card, title, UDim2.new(1,-20,0,22), UDim2.new(0,12,0,12), Enum.Font.GothamBold, 15)
	t.TextWrapped=true
	local b = label(card, "Coming soon", UDim2.new(1,-20,0,18), UDim2.new(0,12,0,46),
		Enum.Font.GothamSemibold,13,Color3.fromRGB(176,184,198))
	b.TextWrapped=true
end

local function refreshTabs()
	for name, pack in pairs(refs.pages) do
		pack.page.Visible = (name==state.currentTab)
	end
	for name, btn in pairs(refs.tabButtons) do
		local active = name==state.currentTab
		btn.BackgroundColor3 = active and Color3.fromRGB(36,42,52) or Color3.fromRGB(26,30,38)
		btn.TextColor3       = active and Color3.fromRGB(241,244,248) or Color3.fromRGB(205,212,224)
	end
end

buildShell()
safeRun("Main/Displays",    buildScriptsPage)
safeRun("Player Settings", buildPlayerPage)
safeRun("Script Settings", buildSettingsPage)
safeRun("Esp Settings",    function() buildPlaceholderPage("Esp Settings",    "Esp Settings")    end)
safeRun("Map Settings",    buildMapPage)
safeRun("Pallet Settings", function()
	local scroller = refs.pages["Pallet Settings"].scroller
	palletRefs.scroller = scroller
	local layout = scroller:FindFirstChildOfClass("UIListLayout")
	if layout then layout.Padding = UDim.new(0,8) end

	
	local pickerCard = section(scroller, 206, 1)

	
	local PW, PH = 154, 154
	local pickerFrame = Instance.new("Frame")
	pickerFrame.Size = UDim2.new(0,PW,0,PH)
	pickerFrame.Position = UDim2.new(0,10,0,10)
	pickerFrame.BackgroundColor3 = Color3.fromRGB(18,20,24)
	pickerFrame.BorderSizePixel = 0
	pickerFrame.ClipsDescendants = true
	pickerFrame.Parent = pickerCard
	corner(pickerFrame, 6)
	palletRefs.pickerFrame = pickerFrame

	local hueLayer = Instance.new("Frame")
	hueLayer.Size = UDim2.new(1,0,1,0)
	hueLayer.BackgroundColor3 = Color3.new(1,1,1)
	hueLayer.BorderSizePixel = 0
	hueLayer.Parent = pickerFrame
	local hueGrad = Instance.new("UIGradient")
	hueGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0)),
	})
	hueGrad.Parent = hueLayer

	local whiteLayer = Instance.new("Frame")
	whiteLayer.Size = UDim2.new(1,0,1,0)
	whiteLayer.BackgroundColor3 = Color3.new(1,1,1)
	whiteLayer.BorderSizePixel = 0
	whiteLayer.Parent = pickerFrame
	local whiteGrad = Instance.new("UIGradient")
	whiteGrad.Rotation = 90
	whiteGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	whiteGrad.Parent = whiteLayer

	local cursor = Instance.new("Frame")
	cursor.Size = UDim2.new(0,10,0,10)
	cursor.AnchorPoint = Vector2.new(0.5,0.5)
	cursor.BackgroundColor3 = Color3.fromRGB(255,255,255)
	cursor.BorderSizePixel = 0
	cursor.ZIndex = 2
	cursor.Parent = pickerFrame
	corner(cursor, 999)
	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(0,0,0); cStroke.Thickness=1; cStroke.Parent=cursor
	palletRefs.cursor = cursor

	
	local RX = PW + 18
	local CARD_W = 286
	local RIGHT_W = CARD_W - RX - 10

	
	local preview = Instance.new("Frame")
	preview.Size = UDim2.new(0,RIGHT_W,0,40)
	preview.Position = UDim2.new(0,RX,0,10)
	preview.BackgroundColor3 = palletState.previewColor
	preview.BorderSizePixel = 0
	preview.Parent = pickerCard
	corner(preview, 6)
	local pStroke = Instance.new("UIStroke")
	pStroke.Color=Color3.fromRGB(60,65,78); pStroke.Transparency=0.1; pStroke.Thickness=1; pStroke.Parent=preview
	palletRefs.preview = preview

	
		local RGB_BOX_W = math.floor((RIGHT_W - 8) / 3)
	local function mkRGBBox(placeholder, xOffset)
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(0, RGB_BOX_W, 0, 26)
		box.Position = UDim2.new(0, RX + xOffset*(RGB_BOX_W+4), 0, 58)
		box.BackgroundColor3 = Color3.fromRGB(30,35,44)
		box.BorderSizePixel = 0
		box.ClearTextOnFocus = false
		box.Text = ""
		box.PlaceholderText = placeholder
		box.TextColor3 = Color3.fromRGB(241,244,248)
		box.PlaceholderColor3 = Color3.fromRGB(130,138,155)
		box.Font = Enum.Font.GothamSemibold
		box.TextSize = 12
		box.Parent = pickerCard
		corner(box, 6)
		local s2 = Instance.new("UIStroke")
		s2.Color=Color3.fromRGB(60,65,78); s2.Transparency=0.1; s2.Thickness=1; s2.Parent=box
		return box
	end
	palletRefs.rBox = mkRGBBox("R",0)
	palletRefs.gBox = mkRGBBox("G",1)
	palletRefs.bBox = mkRGBBox("B",2)

	
	local dropBtn = Instance.new("TextButton")
	dropBtn.Size = UDim2.new(0,RIGHT_W,0,28)
	dropBtn.Position = UDim2.new(0,RX,0,92)
	dropBtn.BackgroundColor3 = Color3.fromRGB(30,35,44)
	dropBtn.BorderSizePixel = 0
	dropBtn.AutoButtonColor = false
	dropBtn.Text = (palletMatByEnum[palletState.selectedMaterial] or "WoodPlanks").."  ▼"
	dropBtn.TextColor3 = Color3.fromRGB(241,244,248)
	dropBtn.Font = Enum.Font.GothamSemibold
	dropBtn.TextSize = 12
	dropBtn.TextXAlignment = Enum.TextXAlignment.Left
	dropBtn.Parent = pickerCard
	corner(dropBtn, 6)
	local dbPad = Instance.new("UIPadding"); dbPad.PaddingLeft=UDim.new(0,8); dbPad.Parent=dropBtn
	local dbStroke = Instance.new("UIStroke")
	dbStroke.Color=Color3.fromRGB(60,65,78); dbStroke.Transparency=0.1; dbStroke.Thickness=1; dbStroke.Parent=dropBtn
	dropBtn.MouseEnter:Connect(function() tween(dropBtn,{BackgroundColor3=Color3.fromRGB(39,46,57)}) end)
	dropBtn.MouseLeave:Connect(function() tween(dropBtn,{BackgroundColor3=Color3.fromRGB(30,35,44)}) end)
	palletRefs.dropBtn = dropBtn

	
	local dropFrame = Instance.new("Frame")
	dropFrame.Size = UDim2.new(0,RIGHT_W,0,280)
	dropFrame.Position = UDim2.new(0,RX,0,120)
	dropFrame.BackgroundColor3 = Color3.fromRGB(24,28,36)
	dropFrame.BorderSizePixel = 0
	dropFrame.Visible = false
	dropFrame.ZIndex = 20
	dropFrame.Parent = pickerCard
	corner(dropFrame, 6)
	local dfStroke = Instance.new("UIStroke")
	dfStroke.Color=Color3.fromRGB(60,65,78); dfStroke.Transparency=0.05; dfStroke.Thickness=1; dfStroke.Parent=dropFrame
	palletRefs.dropFrame = dropFrame

	local dropScroll = Instance.new("ScrollingFrame")
	dropScroll.Size = UDim2.new(1,-6,1,-6)
	dropScroll.Position = UDim2.new(0,3,0,3)
	dropScroll.BackgroundTransparency = 1
	dropScroll.BorderSizePixel = 0
	dropScroll.ScrollBarThickness = 3
	dropScroll.ScrollBarImageColor3 = Color3.fromRGB(92,102,120)
	dropScroll.CanvasSize = UDim2.new(0,0,0,0)
	dropScroll.ZIndex = 21
	dropScroll.Parent = dropFrame
	palletRefs.dropScroll = dropScroll

	local dropLayout = Instance.new("UIListLayout")
	dropLayout.Padding = UDim.new(0,2)
	dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
	dropLayout.Parent = dropScroll
	palletRefs.dropLayout = dropLayout

	dropLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		dropScroll.CanvasSize = UDim2.new(0,0,0,dropLayout.AbsoluteContentSize.Y+4)
	end)

	for _, opt in ipairs(palletMaterialOptions) do
		local ob = Instance.new("TextButton")
		ob.Size = UDim2.new(1,-4,0,24)
		ob.BackgroundColor3 = Color3.fromRGB(30,35,44)
		ob.BorderSizePixel = 0
		ob.AutoButtonColor = false
		ob.Text = opt.Name
		ob.TextColor3 = Color3.fromRGB(241,244,248)
		ob.Font = Enum.Font.GothamSemibold
		ob.TextSize = 12
		ob.ZIndex = 22
		ob.Parent = dropScroll
		corner(ob, 6)
		ob.MouseEnter:Connect(function() tween(ob,{BackgroundColor3=Color3.fromRGB(42,48,60)}) end)
		ob.MouseLeave:Connect(function() tween(ob,{BackgroundColor3=Color3.fromRGB(30,35,44)}) end)
		ob.MouseButton1Click:Connect(function()
			palletState.diamondActive = false
			palletState.selectedMaterial = opt.Material
			dropBtn.Text = opt.Name.."  ▼"
			palletApplyAll(palletState.appliedColor, palletState.selectedMaterial)
			palletUpdateSaveBtn()
			palletState.dropdownOpen = false
			dropFrame.Visible = false
		end)
	end

	
	local brightnessBar = Instance.new("Frame")
	brightnessBar.Size = UDim2.new(0,PW,0,28)
	brightnessBar.Position = UDim2.new(0,10,0,PH+18)
	brightnessBar.BackgroundColor3 = Color3.fromRGB(255,255,255)
	brightnessBar.BorderSizePixel = 0
	brightnessBar.ClipsDescendants = true
	brightnessBar.Parent = pickerCard
	corner(brightnessBar, 6)

	local bsGrad = Instance.new("UIGradient")
	bsGrad.Rotation = 0
	bsGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
	})
	bsGrad.Transparency = NumberSequence.new(0)
	bsGrad.Parent = brightnessBar
	palletRefs.brightnessBar = brightnessBar

	local handle = Instance.new("Frame")
	handle.Size = UDim2.new(0,14,0,28)
	handle.AnchorPoint = Vector2.new(0.5,0.5)
	handle.Position = UDim2.new(1,0,0.5,0)
	handle.BackgroundColor3 = Color3.fromRGB(255,255,255)
	handle.BorderSizePixel = 0
	handle.ZIndex = brightnessBar.ZIndex + 2
	handle.Parent = brightnessBar
	corner(handle, 999)
	local hStroke = Instance.new("UIStroke")
	hStroke.Color=Color3.fromRGB(0,0,0); hStroke.Thickness=1.5; hStroke.Parent=handle
	palletRefs.handle = handle

	
	local btnCard = section(scroller, 82, 2)
	local function mkBtn(txt, x, y, w, h)
		local b = button(btnCard, txt, UDim2.new(0,w,0,h), UDim2.new(0,x,0,y))
		local existingCorner = b:FindFirstChildOfClass("UICorner")
		if existingCorner then existingCorner.CornerRadius = UDim.new(0,6) end
		styleButton(b)
		return b
	end
	local BTN_CARD_W = 286
	local BTN_MARGIN = 10
	local BTN_GAP = 8
	local BW = math.floor((BTN_CARD_W - (BTN_MARGIN * 2) - BTN_GAP) / 2)
	local BH = 26
	local BX2 = BTN_MARGIN + BW + BTN_GAP
	local applyBtn  = mkBtn("Apply Color",   BTN_MARGIN, 10, BW, BH)
	local resetBtn  = mkBtn("Reset Color",   BX2,        10, BW, BH)
	local cycleBtn  = mkBtn("Cycle Presets", BTN_MARGIN, 44, BW, BH)
	local saveBtn   = mkBtn("Save Preset",   BX2,        44, BW, BH)
	palletRefs.saveBtn = saveBtn

	applyBtn.MouseButton1Click:Connect(function()
		palletApplyColor()
		palletFeedback(applyBtn,"Apply Color","Applied!")
	end)
	resetBtn.MouseButton1Click:Connect(function()
		palletReset()
		palletFeedback(resetBtn,"Reset Color","Reset!")
	end)
	cycleBtn.MouseButton1Click:Connect(function()
		if palletCyclePreset() then
			palletFeedback(cycleBtn,"Cycle Presets","Cycled!")
		else
			palletFeedback(cycleBtn,"Cycle Presets","No Presets")
		end
	end)
	saveBtn.MouseButton1Click:Connect(function()
		if palletFindPreset(palletState.appliedColor, palletState.selectedMaterial) then
			local ok,msg = palletUnsavePreset()
			palletFeedback(saveBtn,"Unsave Preset",msg or (ok and "Removed" or "Failed"))
		else
			local ok,msg = palletSavePreset()
			palletFeedback(saveBtn,"Save Preset",msg or (ok and "Saved" or "Failed"))
		end
	end)
	dropBtn.MouseButton1Click:Connect(function()
		palletState.dropdownOpen = not palletState.dropdownOpen
		dropFrame.Visible = palletState.dropdownOpen
	end)

	
	local presetsCard = section(scroller, 130, 3)
	label(presetsCard,"Saved Presets",UDim2.new(1,-52,0,18),UDim2.new(0,10,0,8),Enum.Font.GothamBold,13)

	local restoreDefaultsBtn = Instance.new("ImageButton")
	restoreDefaultsBtn.Size = UDim2.new(0,21,0,21)
	restoreDefaultsBtn.Position = UDim2.new(1,-189,0,7)
	restoreDefaultsBtn.BackgroundTransparency = 1
	restoreDefaultsBtn.BorderSizePixel = 0
	restoreDefaultsBtn.AutoButtonColor = false
	restoreDefaultsBtn.Image = PALLET_RESTORE_ICON
	restoreDefaultsBtn.ImageColor3 = Color3.fromRGB(241,244,248)
	restoreDefaultsBtn.ImageTransparency = 0.1
	restoreDefaultsBtn.Parent = presetsCard
	restoreDefaultsBtn.MouseEnter:Connect(function() tween(restoreDefaultsBtn,{BackgroundColor3=Color3.fromRGB(39,46,57), ImageTransparency=0}) end)
	restoreDefaultsBtn.MouseLeave:Connect(function() tween(restoreDefaultsBtn,{BackgroundColor3=Color3.fromRGB(30,35,44), ImageTransparency=0.1}) end)
	restoreDefaultsBtn.MouseButton1Click:Connect(function()
		local added = palletRestoreDefaultPresets()
		if added == 0 then
			tween(restoreDefaultsBtn,{ImageColor3=Color3.fromRGB(150,190,255)},TWEEN_FAST)
		else
			tween(restoreDefaultsBtn,{ImageColor3=Color3.fromRGB(120,220,160)},TWEEN_FAST)
		end
		task.delay(0.45,function()
			if restoreDefaultsBtn and restoreDefaultsBtn.Parent then
				tween(restoreDefaultsBtn,{ImageColor3=Color3.fromRGB(241,244,248)},TWEEN_FAST)
			end
		end)
	end)

	local presetScroll = Instance.new("ScrollingFrame")
	presetScroll.Size = UDim2.new(1,-16,0,96)
	presetScroll.Position = UDim2.new(0,8,0,28)
	presetScroll.BackgroundColor3 = Color3.fromRGB(16,19,25)
	presetScroll.BorderSizePixel = 0
	presetScroll.ScrollBarThickness = 3
	presetScroll.ScrollBarImageColor3 = Color3.fromRGB(92,102,120)
	presetScroll.CanvasSize = UDim2.new(0,0,0,0)
	presetScroll.Parent = presetsCard
	corner(presetScroll, 8)

	local presetLayout = Instance.new("UIListLayout")
	presetLayout.Padding = UDim.new(0,4)
	presetLayout.SortOrder = Enum.SortOrder.LayoutOrder
	presetLayout.Parent = presetScroll
	presetLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		presetScroll.CanvasSize = UDim2.new(0,0,0,presetLayout.AbsoluteContentSize.Y+4)
	end)

	refreshPalletPresetList = function()
		for _, ch in ipairs(presetScroll:GetChildren()) do
			if ch:IsA("Frame") then ch:Destroy() end
		end
		local presets = palletState.presetData.presets
		if #presets == 0 then
			local empty = Instance.new("Frame")
			empty.Size = UDim2.new(1,0,0,24); empty.BackgroundTransparency=1; empty.Parent=presetScroll
			local el = label(empty,"No saved presets",UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),
				Enum.Font.GothamSemibold,12,Color3.fromRGB(120,128,145))
			el.TextXAlignment = Enum.TextXAlignment.Center
			return
		end
		for i, p in ipairs(presets) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1,0,0,26)
			row.BackgroundColor3 = Color3.fromRGB(22,26,33)
			row.BorderSizePixel = 0
			row.LayoutOrder = i
			row.Parent = presetScroll
			corner(row, 6)

			local isSelected = (i == palletState.presetData.selectedIndex)
			local displayName = p.name or (p.material.." | "..p.r..", "..p.g..", "..p.b)
			local nameLabel = label(row,
				displayName,
				UDim2.new(1,-34,1,0), UDim2.new(0,8,0,0),
				Enum.Font.GothamSemibold, 11,
				isSelected and Color3.fromRGB(241,244,248) or Color3.fromRGB(170,178,195))

			local unsaveRowBtn = Instance.new("ImageButton")
			unsaveRowBtn.Size = UDim2.new(0,16,0,16)
			unsaveRowBtn.Position = UDim2.new(1,-22,0.5,-8)
			unsaveRowBtn.BackgroundTransparency = 1
			unsaveRowBtn.BorderSizePixel = 0
			unsaveRowBtn.AutoButtonColor = false
			unsaveRowBtn.Image = "rbxassetid://138598738825070"
			unsaveRowBtn.ImageColor3 = Color3.fromRGB(220,80,80)
			unsaveRowBtn.ImageTransparency = 0.2
			unsaveRowBtn.Parent = row
			unsaveRowBtn.MouseEnter:Connect(function() tween(unsaveRowBtn,{ImageTransparency=0}) end)
			unsaveRowBtn.MouseLeave:Connect(function() tween(unsaveRowBtn,{ImageTransparency=0.2}) end)
			unsaveRowBtn.MouseButton1Click:Connect(function()
				local targetColor = Color3.fromRGB(p.r, p.g, p.b)
				local targetMat = palletMatByName[p.material]
				if targetMat then
					local idx = palletFindPreset(targetColor, targetMat)
					if idx then
						table.remove(palletState.presetData.presets, idx)
						local count = #palletState.presetData.presets
						if count == 0 then
							palletState.presetData.selectedIndex = 0
						elseif palletState.presetData.selectedIndex > count then
							palletState.presetData.selectedIndex = count
						elseif palletState.presetData.selectedIndex >= idx then
							palletState.presetData.selectedIndex = math.max(0, palletState.presetData.selectedIndex - 1)
						end
						palletSaveFile()
						palletUpdateSaveBtn()
						refreshPalletPresetList()
					end
				end
			end)
		end
	end

	
	palletRefs.rBox.FocusLost:Connect(palletSetColorFromRGB)
	palletRefs.gBox.FocusLost:Connect(palletSetColorFromRGB)
	palletRefs.bBox.FocusLost:Connect(palletSetColorFromRGB)

	pickerFrame.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 then
			palletState.draggingPicker = true
			palletUpdatePickerPos(palletMousePosition())
		end
	end)
	brightnessBar.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 then
			palletState.draggingBrightness = true
			palletUpdateBrightness(palletMousePosition())
		end
	end)

	
	UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if palletState.dropdownOpen and inp.UserInputType==Enum.UserInputType.MouseButton1 then
			local mp = palletMousePosition()
			local function inside(f2)
				if not f2 or not f2.Visible then return false end
				local ap2,as2 = f2.AbsolutePosition, f2.AbsoluteSize
				return mp.X>=ap2.X and mp.X<=ap2.X+as2.X and mp.Y>=ap2.Y and mp.Y<=ap2.Y+as2.Y
			end
			if not inside(dropBtn) and not inside(dropFrame) then
				palletState.dropdownOpen = false
				dropFrame.Visible = false
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 then
			palletState.draggingPicker = false
			palletState.draggingBrightness = false
		end
	end)

	UserInputService.InputChanged:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseMovement then
			local mp = palletMousePosition()
			if palletState.draggingPicker     then palletUpdatePickerPos(mp)  end
			if palletState.draggingBrightness then palletUpdateBrightness(mp) end
		end
	end)

	
	task.spawn(function()
		initPalletRemotes()
		if palletToysFolder then
			for _, child in ipairs(palletToysFolder:GetChildren()) do
				if palletIsTarget(child) then
					palletTrackModel(child)
				end
			end
			palletToysFolder.ChildAdded:Connect(function(child)
				if palletIsTarget(child) then
					palletForcePaintModel(child, palletState.appliedColor, palletState.selectedMaterial)
				end
			end)
		end
	end)

	
	palletLoadFile()
	palletSyncUI()
	palletUpdatePreview()
	refreshPalletPresetList()
end)
safeRun("Custom Keybinds", function() buildPlaceholderPage("Custom Keybinds", "Custom Keybinds") end)
safeRun("Info & More",     buildInfoPage)

bindSlider("settings_fps", function(alpha)
	local count = #FPS_CAP_OPTIONS
	state.fpsCapIndex = math.clamp(math.floor(alpha*(count-1)+0.5)+1, 1, count)
	refreshFpsSlider(); applyFpsCap()
	if state.saveSettings then saveSettings() end
end)

bindSlider("player_fov", function(alpha)
	state.targetFOV = math.clamp(math.floor(1+119*alpha+0.5), 1, 120)
	if camera then camera.FieldOfView=state.targetFOV end
	refreshFovSlider()
	if state.saveSettings then saveSettings() end
end)

bindSlider("player_jump", function(alpha)
	local hum = localHumanoid()
	if hum then hum.UseJumpPower=true; hum.JumpPower=math.floor(300*alpha+0.5) end
	refreshJumpSlider()
end)

bindSlider("player_gravity", function(alpha)
	workspace.Gravity = math.clamp(math.floor(500*alpha+0.5), 0, 500)
	refreshGravitySlider()
end)

bindSlider("map_tod", function(alpha)
	if state.todLocked then
		refreshTodSlider()
		return
	end
	
	local TOD_MAX_L = 23 + 59/60
	local rawTime = alpha * TOD_MAX_L
	local snapped = math.floor(rawTime * 60 + 0.5) / 60  
	snapped = math.clamp(snapped, 0, TOD_MAX_L)
	game:GetService("Lighting").ClockTime = snapped
	refreshTodSlider()
end)

if refs.commandBox then
	refs.commandBox.FocusLost:Connect(function(enter)
		state.commandText = refs.commandBox.Text
		if enter then
			local ok, msg = runCommand(state.commandText)
			setCommandStatus(msg)
			if ok then refs.commandBox.Text=""; state.commandText="" end
		end
	end)
end

refreshTabs()
refreshSettingsToggles()
refreshThirdPerson()
refreshNoclip()
refreshFtapToggles()
refreshMapPresetButtons()
refreshMapResetButton()
refreshFpsSlider()
refreshFovSlider()
refreshGravitySlider()
refreshJumpSlider()
refreshTodSlider()
refreshAllRows()

if camera then camera.FieldOfView=state.targetFOV end
applyThirdPerson()
applyFpsCap()
persistSettings()

bindAmbienceFiltering()
state.ftapDefaultAmbienceEnabled = false
state.todLocked = false
setResetMapAmbienceActive(true)
setFTAPMap("Default")

state.unlockMouseUntil = tick() + 3

refs.closeButton.MouseEnter:Connect(function()  tween(refs.closeButton,{ImageTransparency=0})    end)
refs.closeButton.MouseLeave:Connect(function()  tween(refs.closeButton,{ImageTransparency=0.15}) end)
refs.closeButton.MouseButton1Click:Connect(function()
	if refs.commandBox and refs.commandBox:IsFocused() then refs.commandBox:ReleaseFocus(false) end
	setMenuOpen(false)
end)

for name, btn in pairs(refs.tabButtons) do
	btn.MouseButton1Click:Connect(function()
		state.currentTab = name
		refreshTabs()
	end)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode==Enum.KeyCode.Tab then
		setMenuOpen(not state.menuOpen)
		if state.menuOpen then state.unlockMouseUntil=tick()+1 end
		return
	end

	if input.KeyCode==Enum.KeyCode.Semicolon then
		setMenuOpen(true)
		state.unlockMouseUntil=tick()+1
		state.currentTab="Main/Displays"
		refreshTabs()
		task.wait()
		local cmdSec = refs.commandBox and refs.commandBox.Parent
		local sc = refs.pages["Main/Displays"] and refs.pages["Main/Displays"].scroller
		if cmdSec and sc then
			local y = cmdSec.AbsolutePosition.Y - sc.AbsolutePosition.Y + sc.CanvasPosition.Y - 8
			sc.CanvasPosition = Vector2.new(0, math.max(0,y))
		end
		if refs.commandBox then refs.commandBox:CaptureFocus() end
		return
	end

	if refs.commandBox and refs.commandBox:IsFocused() then return end
	if gp then return end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseMovement then
		if state.draggingSlider then
			local ds = state.draggingSlider
			local alpha = math.clamp((input.Position.X - ds.track.AbsolutePosition.X) / ds.track.AbsoluteSize.X, 0, 1)
			ds.setter(alpha)
		end
		if state.draggingWindow and state.dragStart and state.startPos then
			local d = input.Position - state.dragStart
			refs.frame.Position = UDim2.new(
				state.startPos.X.Scale, state.startPos.X.Offset+d.X,
				state.startPos.Y.Scale, state.startPos.Y.Offset+d.Y
			)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 then
		state.draggingSlider = nil
		state.draggingWindow = false
	end
end)

refs.topBar.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 then
		state.draggingWindow = true
		state.dragStart      = input.Position
		state.startPos       = refs.frame.Position
	end
end)

RunService.RenderStepped:Connect(function()
	local shouldUnlock = state.menuOpen
		or state.draggingWindow
		or state.draggingSlider ~= nil
		or (refs.commandBox and refs.commandBox:IsFocused())
		or tick() < state.unlockMouseUntil

	if shouldUnlock then
		UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end)

Players.PlayerRemoving:Connect(function(p)
	clearEspPlayer(p)
	if view.target==p then resetView() end
	if esp.charConns[p.UserId] then
		esp.charConns[p.UserId]:Disconnect()
		esp.charConns[p.UserId]=nil
	end
end)

player.CharacterAdded:Connect(function()
	task.wait(0.2)
	applyThirdPerson()
	refreshNoclip()
	refreshJumpSlider()
	refreshGravitySlider()
	if camera then camera.FieldOfView=state.targetFOV end
end)
