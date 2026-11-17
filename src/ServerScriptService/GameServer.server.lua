--[[
	👹 MOG MONSTERS 👹
	==================
	Put this as a *Script* in ServerScriptService.

	This script builds the whole map and runs the game:
	  * TRAIN your MOG: stand at the MOG STATION next to your base and
	    press E - your HAMMER hits the stone by itself. Upgrade hammer
	    power and swing speed, buy AURAS to multiply your MOG.
	  * The MOG ROAD has 8 huge walled ZONES. Every gate needs more MOG.
	  * Press E on a wild monster for a MOG BATTLE (mini game). Win and
	    carry it home - other players can hit you with their hammer and
	    take it! (You can NOT steal from bases, only on the road.)
	  * Monsters walk around in your enclosure and make money.
	    Upgrade the enclosure to keep more monsters.
	  * Levels: Normal, Silver, Golden, Diamond, Rainbow, Cosmic, RAINBOW COSMIC.
	  * GIGAMOG: 1 in 1,000,000,000!
	  * Leaderboard, fusion, rebirth, Lucky Rush, daily rewards, shop.

	REALISTIC MONSTERS (optional):
	  In ServerStorage there is a Folder "MonsterModels". Put a 3D Model
	  inside and name it like a monster (for example "Werewolf").
	  The game will use your model instead of the built-in one.
	  Scripts inside the model are removed automatically.

	>>> ONLY CHANGE THINGS IN THE "CONFIG" SECTION BELOW <<<
]]

----------------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------------
local CONFIG = {
	START_CASH = 0,
	START_MOG = 10,
	START_SLOTS = 6,          -- monsters your enclosure holds at the start
	MAX_SLOTS = 20,           -- biggest enclosure you can buy with cash
	SLOT_BASE_COST = 400,     -- price of slot 7 (then x2.2 every slot)
	WANDER_SPEED = 4,         -- how fast wild monsters walk around
	PEN_SPEED = 2.5,          -- how fast monsters walk in your enclosure
	BATTLE_MIN_TIME = 2,
	BATTLE_MAX_TIME = 25,
	LOOSE_TIME = 15,          -- seconds a dropped monster stays on the ground
	RESPAWN_TIME = 3,
	THROW_POWER = 75,
	SELL_PERCENT = 0.5,
	REBIRTH_BASE_COST = 1000000,
	REBIRTH_COST_MULT = 5,
	RUSH_EVERY = 600,         -- LUCKY RUSH every 10 minutes
	RUSH_TIME = 60,
	FIRST_RUSH = 300,

	-- Paste your IDs here after you create them on create.roblox.com
	-- (0 = not set up yet, the button just says "coming soon")
	DOUBLE_MONEY_PASS_ID = 0, -- 2x money
	DOUBLE_MOG_PASS_ID = 0,   -- 2x MOG from training
	VIP_PASS_ID = 0,          -- VIP tag, +20% money, 2x daily reward
	EXTRA_SLOTS_PASS_ID = 0,  -- +5 monsters in your enclosure
	SERVER_LUCK_PRODUCT_ID = 0, -- 2x luck for EVERYONE for 15 minutes
	CASH_PACK_PRODUCT_ID = 0,   -- 10 minutes of income (min 5K)
}

-- Mog = MOG you need (also the MOG to enter that zone), Income = money per second
local RARITIES = {
	{ Name = "Common",    Mog = 10,        Income = 2,       Color = Color3.fromRGB(220, 220, 220) },
	{ Name = "Uncommon",  Mog = 40,        Income = 6,       Color = Color3.fromRGB(110, 235, 110) },
	{ Name = "Rare",      Mog = 200,       Income = 25,      Color = Color3.fromRGB(90, 170, 255) },
	{ Name = "Epic",      Mog = 1500,      Income = 100,     Color = Color3.fromRGB(200, 110, 255) },
	{ Name = "Legendary", Mog = 12000,     Income = 600,     Color = Color3.fromRGB(255, 205, 50) },
	{ Name = "Mythic",    Mog = 100000,    Income = 4000,    Color = Color3.fromRGB(255, 80, 140) },
	{ Name = "Secret",    Mog = 2000000,   Income = 50000,   Color = Color3.fromRGB(60, 60, 60) },
	{ Name = "GODLY",     Mog = 100000000, Income = 1000000, Color = Color3.fromRGB(255, 255, 255) },
}

-- One ZONE per rarity along the Mog Road.
-- Every = seconds between new monsters, Max = most monsters at once.
local ZONES = {
	{ Every = 3,   Max = 16 },
	{ Every = 5,   Max = 13 },
	{ Every = 8,   Max = 10 },
	{ Every = 15,  Max = 8 },
	{ Every = 30,  Max = 6 },
	{ Every = 60,  Max = 4 },
	{ Every = 180, Max = 3 },
	{ Every = nil, Max = 1 }, -- GODLY zone: only a GIGAMOG (1 in a billion per spawn)
}
local GIGAMOG_CHANCE = 1 / 1000000000

-- The monsters (inspired by old myths and legends from all over the world).
-- Plan = body type: humanoid, quadruped, ghost, serpent, dragon, bird
-- Style = extra details for that body type.
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local MONSTERS = {
	{ Id = "Zombie",     Name = "Zombie",         Rarity = 1, Plan = "humanoid",  Style = "zombie",     Skin = rgb(150, 185, 120), Shirt = rgb(120, 100, 80), Pants = rgb(70, 80, 110), Hair = rgb(60, 50, 40), Shoes = rgb(60, 50, 45) },
	{ Id = "Redcap",     Name = "Redcap",         Rarity = 1, Plan = "humanoid",  Style = "redcap",     Height = 0.75, Skin = rgb(215, 175, 145), Shirt = rgb(95, 125, 65), Pants = rgb(100, 75, 55), Hair = rgb(200, 200, 200), Shoes = rgb(70, 50, 35), Accent = rgb(220, 30, 30) },
	{ Id = "Leprechaun", Name = "Leprechaun",     Rarity = 2, Plan = "humanoid",  Style = "leprechaun", Height = 0.7, Skin = rgb(245, 205, 175), Shirt = rgb(40, 160, 70), Pants = rgb(35, 125, 55), Hair = rgb(235, 120, 40), Shoes = rgb(40, 30, 25), Accent = rgb(255, 210, 60) },
	{ Id = "Cadejo",     Name = "El Cadejo",      Rarity = 2, Plan = "quadruped", Style = "dog",        Color = rgb(40, 40, 48), Accent = rgb(255, 40, 40), Material = Enum.Material.Fabric },
	{ Id = "Werewolf",   Name = "Werewolf",       Rarity = 3, Plan = "humanoid",  Style = "werewolf",   Height = 1.15, Skin = rgb(85, 90, 115), Shirt = rgb(85, 90, 115), Pants = rgb(70, 65, 90), Hair = rgb(70, 75, 100), Accent = rgb(255, 220, 80), Material = Enum.Material.Fabric },
	{ Id = "Kelpie",     Name = "Kelpie",         Rarity = 3, Plan = "quadruped", Style = "horse",      Color = rgb(30, 55, 50), Accent = rgb(60, 150, 120) },
	{ Id = "Vampire",    Name = "Vampire",        Rarity = 4, Plan = "humanoid",  Style = "vampire",    Skin = rgb(240, 235, 240), Shirt = rgb(130, 20, 70), Pants = rgb(30, 25, 40), Hair = rgb(25, 20, 30), Shoes = rgb(20, 20, 25), Accent = rgb(255, 30, 60) },
	{ Id = "Ghost",      Name = "Ghost",          Rarity = 4, Plan = "ghost",                               Color = rgb(225, 235, 250), Accent = rgb(120, 200, 255) },
	{ Id = "Troll",      Name = "Troll",          Rarity = 5, Plan = "humanoid",  Style = "troll",      Height = 1.35, Skin = rgb(110, 135, 80), Shirt = rgb(110, 135, 80), Pants = rgb(120, 85, 55), Hair = rgb(80, 65, 45) },
	{ Id = "Kitsune",    Name = "Kitsune",        Rarity = 5, Plan = "quadruped", Style = "fox",        Color = rgb(235, 50, 100), Accent = rgb(255, 245, 250) },
	{ Id = "Bigfoot",    Name = "Bigfoot",        Rarity = 6, Plan = "humanoid",  Style = "bigfoot",    Height = 1.45, Skin = rgb(105, 70, 45), Shirt = rgb(105, 70, 45), Pants = rgb(105, 70, 45), Hair = rgb(95, 62, 40), Accent = rgb(150, 110, 85), Material = Enum.Material.Fabric },
	{ Id = "Mothman",    Name = "Mothman",        Rarity = 6, Plan = "humanoid",  Style = "mothman",    Height = 1.25, Skin = rgb(70, 55, 50), Shirt = rgb(70, 55, 50), Pants = rgb(55, 45, 40), Hair = rgb(70, 55, 50), Accent = rgb(255, 30, 30) },
	{ Id = "Grootslang", Name = "Grootslang",     Rarity = 7, Plan = "serpent",                             Color = rgb(120, 115, 105), Accent = rgb(240, 235, 215) },
	{ Id = "Dragon",     Name = "Ancient Dragon", Rarity = 7, Plan = "dragon",                              Color = rgb(70, 72, 80), Accent = rgb(220, 140, 50) },
	{ Id = "Gigamog",    Name = "GIGAMOG",        Rarity = 8, Plan = "dragon",                              Color = rgb(255, 205, 60), Accent = rgb(255, 255, 255), Scale = 1.2, Crown = true },
	-- Only from Rebirth 10:
	{ Id = "Phoenixmog", Name = "Phoenixmog",     Rarity = 6, Plan = "bird",                                Color = rgb(255, 130, 50), Accent = rgb(255, 225, 70), Exclusive = true },
}

-- Levels. Chance is per monster. Mult boosts money AND the MOG you need.
local VARIANTS = {
	{ Name = "Normal",         Chance = nil,         Mult = 1 },
	{ Name = "Silver",         Chance = 1 / 10,      Mult = 1.5, Color = Color3.fromRGB(215, 220, 230), Material = Enum.Material.Metal },
	{ Name = "Golden",         Chance = 1 / 40,      Mult = 2,   Color = Color3.fromRGB(255, 205, 50),  Material = Enum.Material.Foil },
	{ Name = "Diamond",        Chance = 1 / 250,     Mult = 4,   Color = Color3.fromRGB(180, 245, 255), Material = Enum.Material.Glass },
	{ Name = "Rainbow",        Chance = 1 / 1500,    Mult = 8 },
	{ Name = "Cosmic",         Chance = 1 / 15000,   Mult = 20,  Color = Color3.fromRGB(80, 30, 160),   Material = Enum.Material.Neon },
	{ Name = "Rainbow Cosmic", Chance = 1 / 1000000, Mult = 100, Material = Enum.Material.Neon },
}

-- HAMMER: MOG per hit for each level (and the price to get it)
local HAMMERS = {
	{ Power = 1,     Cost = 0 },
	{ Power = 2,     Cost = 50 },
	{ Power = 4,     Cost = 160 },
	{ Power = 8,     Cost = 500 },
	{ Power = 15,    Cost = 1600 },
	{ Power = 30,    Cost = 5200 },
	{ Power = 60,    Cost = 17000 },
	{ Power = 120,   Cost = 54000 },
	{ Power = 250,   Cost = 170000 },
	{ Power = 500,   Cost = 550000 },
	{ Power = 1000,  Cost = 1800000 },
	{ Power = 2500,  Cost = 5600000 },
	{ Power = 6000,  Cost = 18000000 },
	{ Power = 15000, Cost = 58000000 },
	{ Power = 40000, Cost = 185000000 },
}
-- SWING SPEED: seconds between hammer hits for each level
local SWINGS = {
	{ Time = 1.0,  Cost = 0 },
	{ Time = 0.8,  Cost = 100 },
	{ Time = 0.65, Cost = 400 },
	{ Time = 0.5,  Cost = 1600 },
	{ Time = 0.4,  Cost = 6400 },
	{ Time = 0.3,  Cost = 25000 },
	{ Time = 0.22, Cost = 100000 },
	{ Time = 0.15, Cost = 400000 },
}
-- AURAS multiply the MOG you get from training
local AURAS = {
	{ Name = "Spark Aura",   Tier = "Common",    Mult = 1.25, Cost = 1000,       Color = Color3.fromRGB(255, 255, 160) },
	{ Name = "Flame Aura",   Tier = "Rare",      Mult = 1.5,  Cost = 10000,      Color = Color3.fromRGB(255, 120, 40) },
	{ Name = "Frost Aura",   Tier = "Rare",      Mult = 2,    Cost = 75000,      Color = Color3.fromRGB(130, 220, 255) },
	{ Name = "Thunder Aura", Tier = "Epic",      Mult = 3,    Cost = 500000,     Color = Color3.fromRGB(255, 240, 60) },
	{ Name = "Toxic Aura",   Tier = "Epic",      Mult = 4,    Cost = 1500000,    Color = Color3.fromRGB(120, 255, 80) },
	{ Name = "Shadow Aura",  Tier = "Legendary", Mult = 5,    Cost = 4000000,    Color = Color3.fromRGB(140, 60, 220) },
	{ Name = "Blood Aura",   Tier = "Mythic",     Mult = 6.5,  Cost = 12000000,   Color = Color3.fromRGB(230, 30, 60) },
	{ Name = "Cosmic Aura",  Tier = "Secret",    Mult = 8,    Cost = 30000000,   Color = Color3.fromRGB(90, 40, 255) },
	{ Name = "Rainbow Aura", Tier = "Divine",    Mult = 12,   Cost = 250000000,  Color = Color3.fromRGB(255, 120, 220), Rainbow = true },
}

-- Money Boost upgrade levels
local BOOST_MULTS = { 1, 1.5, 2, 3, 5, 8, 12, 20, 35, 60 }
local BOOST_BASE_COST = 200

----------------------------------------------------------------------
-- SERVICES, REMOTES, HELPERS
----------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

Players.RespawnTime = CONFIG.RESPAWN_TIME

-- Bright, happy lighting
Lighting.ClockTime = 13
Lighting.Brightness = 3
Lighting.Ambient = Color3.fromRGB(150, 150, 160)
Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 190)
local function addLightingEffect(className, props)
	local e = Lighting:FindFirstChildOfClass(className)
	if not e then
		e = Instance.new(className)
		e.Parent = Lighting
	end
	for k, v in pairs(props) do
		e[k] = v
	end
end
addLightingEffect("Atmosphere", { Density = 0.2, Haze = 0.3, Color = Color3.fromRGB(220, 235, 255), Decay = Color3.fromRGB(180, 200, 255), Glare = 0.2 })
addLightingEffect("BloomEffect", { Intensity = 0.4, Size = 20, Threshold = 1.8 })
addLightingEffect("ColorCorrectionEffect", { Saturation = 0.3, Contrast = 0.08, Brightness = 0.03 })
addLightingEffect("SunRaysEffect", { Intensity = 0.04, Spread = 0.6 })
addLightingEffect("DepthOfFieldEffect", { FarIntensity = 0.12, FocusDistance = 80, InFocusRadius = 120, NearIntensity = 0 })
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.25
Lighting.EnvironmentDiffuseScale = 1
Lighting.EnvironmentSpecularScale = 1
pcall(function()
	if not Lighting:FindFirstChildOfClass("Sky") then
		local sky = Instance.new("Sky")
		sky.SunAngularSize = 14
		sky.Parent = Lighting
	end
end)

for key, value in pairs({
	DoubleMoneyPassId = CONFIG.DOUBLE_MONEY_PASS_ID,
	DoubleMogPassId = CONFIG.DOUBLE_MOG_PASS_ID,
	VipPassId = CONFIG.VIP_PASS_ID,
	ExtraSlotsPassId = CONFIG.EXTRA_SLOTS_PASS_ID,
	ServerLuckProductId = CONFIG.SERVER_LUCK_PRODUCT_ID,
	CashPackProductId = CONFIG.CASH_PACK_PRODUCT_ID,
}) do
	ReplicatedStorage:SetAttribute(key, value)
end

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local function remote(className, name)
	local r = Instance.new(className)
	r.Name = name
	r.Parent = remotes
	return r
end
local notifyRemote = remote("RemoteEvent", "Notify")
local announceRemote = remote("RemoteEvent", "Announce")
local panelRemote = remote("RemoteEvent", "OpenPanel")
local throwRemote = remote("RemoteEvent", "Throw")
local effectRemote = remote("RemoteEvent", "Effect")
local battleRemote = remote("RemoteEvent", "Battle")
local requestRemote = remote("RemoteFunction", "Request")
remotes.Parent = ReplicatedStorage

local function notify(player, text)
	notifyRemote:FireClient(player, text)
end
local function announce(text)
	announceRemote:FireAllClients(text)
end
local function effect(position, color, text)
	effectRemote:FireAllClients(position, color, text)
end

local function fmt(n)
	n = math.floor(n)
	if n >= 1e15 then
		return string.format("%.1fQ", n / 1e15)
	elseif n >= 1e12 then
		return string.format("%.1fT", n / 1e12)
	elseif n >= 1e9 then
		return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(n)
end

local MONSTER_BY_ID = {}
for _, def in ipairs(MONSTERS) do
	MONSTER_BY_ID[def.Id] = def
end
local AURA_BY_NAME = {}
for _, a in ipairs(AURAS) do
	AURA_BY_NAME[a.Name] = a
end

local function variantChance(v)
	local c = VARIANTS[v].Chance
	if c then
		return c
	end
	local rest = 1
	for i = 2, #VARIANTS do
		rest = rest - VARIANTS[i].Chance
	end
	return rest
end

-- "1 in X" for a monster + level
local function oddsOf(id, variant)
	local def = MONSTER_BY_ID[id]
	if def.Exclusive then
		return 0
	end
	local chance = variantChance(variant or 1)
	if def.Rarity == #RARITIES then
		chance = chance * GIGAMOG_CHANCE
	end
	return math.floor(1 / chance + 0.5)
end

local function displayName(id, variant)
	local def = MONSTER_BY_ID[id]
	if variant and variant > 1 then
		return VARIANTS[variant].Name .. " " .. def.Name
	end
	return def.Name
end

local function monsterIncome(id, variant)
	return RARITIES[MONSTER_BY_ID[id].Rarity].Income * VARIANTS[variant].Mult
end
local function monsterMog(id, variant)
	return math.floor(RARITIES[MONSTER_BY_ID[id].Rarity].Mog * VARIANTS[variant].Mult)
end
local function monsterValue(id, variant)
	return monsterIncome(id, variant) * 30
end

----------------------------------------------------------------------
-- MAP
----------------------------------------------------------------------
local oldBaseplate = workspace:FindFirstChild("Baseplate")
if oldBaseplate then
	oldBaseplate:Destroy()
end

local map = Instance.new("Folder")
map.Name = "Map"
map.Parent = workspace
local monsterFolder = Instance.new("Folder")
monsterFolder.Name = "Monsters"
monsterFolder.Parent = workspace

local function block(size, cframe, color, material, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent or map
	return p
end

local function surfaceText(part, text, face)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	gui.Parent = part
	return label
end

local function billboard(part, width, height, offset, lines)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, width, 0, height)
	bb.StudsOffset = offset
	bb.MaxDistance = 300
	bb.Parent = part
	local labels = {}
	for i = 1, lines do
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, 0, 1 / lines, 0)
		l.Position = UDim2.new(0, 0, (i - 1) / lines, 0)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = Color3.new(1, 1, 1)
		l.TextStrokeTransparency = 0
		l.Text = ""
		l.Parent = bb
		labels[i] = l
	end
	return bb, labels
end

local function sign(position, title, color)
	local p = block(Vector3.new(1, 1, 1), CFrame.new(position), color)
	p.Transparency = 1
	p.CanCollide = false
	local _, labels = billboard(p, 320, 80, Vector3.new(), 2)
	labels[1].Text = title
	labels[1].TextColor3 = color
	return labels[2]
end

-- Sizes
local ROAD_X0 = 30
local ZONE_LEN = 140
local ROAD_W = 110
local ROAD_END = ROAD_X0 + ZONE_LEN * #ZONES
local MAP_X1, MAP_X2, MAP_Z = -500, ROAD_END + 40, 200
local WALL_H = 26
local WALL_COLOR = Color3.fromRGB(245, 235, 215)
local GRASS = Color3.fromRGB(120, 215, 95)

-- Ground, hub and walls around the whole map
block(Vector3.new(MAP_X2 - MAP_X1, 2, MAP_Z * 2), CFrame.new((MAP_X1 + MAP_X2) / 2, -1.5, 0), GRASS, Enum.Material.Grass) -- backup floor
-- real terrain grass (looks much better) + soft clouds
pcall(function()
	local terrain = workspace.Terrain
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(115, 205, 85))
	terrain:FillBlock(CFrame.new((MAP_X1 + MAP_X2) / 2, -2, 0), Vector3.new(MAP_X2 - MAP_X1, 4, MAP_Z * 2), Enum.Material.Grass)
	local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.55
	clouds.Density = 0.6
	clouds.Color = Color3.fromRGB(255, 255, 255)
	clouds.Parent = terrain
end)
block(Vector3.new(500, 0.2, 100), CFrame.new(-250, 0.1, 0), Color3.fromRGB(250, 238, 215), Enum.Material.Pavement)
block(Vector3.new(ROAD_X0 + 2, 0.3, ROAD_W), CFrame.new(ROAD_X0 / 2, 0.15, 0), Color3.fromRGB(250, 238, 215), Enum.Material.Pavement)
local function wall(x1, z1, x2, z2, h)
	local a, b = Vector3.new(x1, 0, z1), Vector3.new(x2, 0, z2)
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	return block(Vector3.new(4, h, len + 4), CFrame.lookAt(mid, b) * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, math.rad(-90), 0), WALL_COLOR, Enum.Material.SmoothPlastic)
end
-- outer walls
wall(MAP_X1, -MAP_Z, MAP_X1, MAP_Z, WALL_H + 4)
wall(MAP_X2, -MAP_Z, MAP_X2, MAP_Z, WALL_H + 4)
wall(MAP_X1, -MAP_Z, MAP_X2, -MAP_Z, WALL_H + 4)
wall(MAP_X1, MAP_Z, MAP_X2, MAP_Z, WALL_H + 4)
-- walls along the Mog Road + walls closing off the grass next to it
for _, z in ipairs({ -ROAD_W / 2 - 2, ROAD_W / 2 + 2 }) do
	wall(ROAD_X0, z, ROAD_END, z, WALL_H)
	wall(ROAD_X0, z, ROAD_X0, z > 0 and MAP_Z or -MAP_Z, WALL_H)
end
local endWall = wall(ROAD_END + 2, -ROAD_W / 2, ROAD_END + 2, ROAD_W / 2, WALL_H)
surfaceText(endWall, "MORE ZONES COMING SOON...", Enum.NormalId.Left)
surfaceText(endWall, "MORE ZONES COMING SOON...", Enum.NormalId.Right)

-- MOG ROAD zones
local zoneInfo = {}
for k = 1, #ZONES do
	local rarity = RARITIES[k]
	local x0 = ROAD_X0 + (k - 1) * ZONE_LEN
	local floorColor = rarity.Color:Lerp(Color3.new(1, 1, 1), 0.45)
	if k == 7 then
		floorColor = Color3.fromRGB(120, 120, 135)
	end
	local floorPart = block(Vector3.new(ZONE_LEN, 0.4, ROAD_W), CFrame.new(x0 + ZONE_LEN / 2, 0.2, 0), floorColor, Enum.Material.SmoothPlastic)
	floorPart.Name = "Zone" .. k
	-- gate: a sign beam over the road and a glowing barrier
	local top = block(Vector3.new(3, 5, ROAD_W), CFrame.new(x0, WALL_H - 2.5, 0), WALL_COLOR, Enum.Material.SmoothPlastic)
	local gateText = "ZONE " .. k .. ": " .. rarity.Name:upper() .. (k > 1 and ("  |  NEED " .. fmt(rarity.Mog) .. " MOG") or "")
	surfaceText(top, gateText, Enum.NormalId.Left).TextColor3 = rarity.Color:Lerp(Color3.new(0, 0, 0), 0.25)
	surfaceText(top, gateText, Enum.NormalId.Right).TextColor3 = rarity.Color:Lerp(Color3.new(0, 0, 0), 0.25)
	if k > 1 then
		local barrier = block(Vector3.new(0.4, WALL_H - 5, ROAD_W), CFrame.new(x0, (WALL_H - 5) / 2, 0), rarity.Color, Enum.Material.ForceField)
		barrier.CanCollide = false
		barrier.CanQuery = false
		barrier.Transparency = 0.3
	end
	zoneInfo[k] = { X0 = x0, X1 = x0 + ZONE_LEN, Need = k == 1 and 0 or rarity.Mog }
end
local rushLabel = sign(Vector3.new(ROAD_X0 - 10, WALL_H + 10, 0), "MOG ROAD", Color3.fromRGB(255, 90, 90))

local function zoneAtX(x)
	if x < ROAD_X0 then
		return 0
	end
	return math.clamp(math.floor((x - ROAD_X0) / ZONE_LEN) + 1, 1, #ZONES)
end

-- FUSION MACHINE (in the hub)
local fusionPos = Vector3.new(-250, 0, 0)
local fusionBase = block(Vector3.new(2, 16, 16), CFrame.new(fusionPos + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(230, 220, 255), Enum.Material.SmoothPlastic)
fusionBase.Shape = Enum.PartType.Cylinder
local fusionCore = block(Vector3.new(6, 6, 6), CFrame.new(fusionPos + Vector3.new(0, 7, 0)), Color3.fromRGB(210, 110, 255), Enum.Material.ForceField)
fusionCore.Shape = Enum.PartType.Ball
fusionCore.CanCollide = false
local fusionPrompt = Instance.new("ProximityPrompt")
fusionPrompt.ActionText = "Fuse Monsters"
fusionPrompt.ObjectText = "Fusion Machine"
fusionPrompt.MaxActivationDistance = 16
fusionPrompt.RequiresLineOfSight = false
fusionPrompt.Parent = fusionCore
sign(fusionPos + Vector3.new(0, 14, 0), "FUSION MACHINE", Color3.fromRGB(210, 110, 255)).Text = "2 same monsters = next level!"

-- LEADERBOARD (end of the hub)
local boardPart = block(Vector3.new(2, 26, 34), CFrame.new(MAP_X1 + 14, 15, 0), Color3.fromRGB(40, 45, 70), Enum.Material.SmoothPlastic)
local boardGui = Instance.new("SurfaceGui")
boardGui.Face = Enum.NormalId.Right
boardGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
boardGui.PixelsPerStud = 20
boardGui.Parent = boardPart
local boardTitle = Instance.new("TextLabel")
boardTitle.Size = UDim2.new(1, 0, 0.12, 0)
boardTitle.BackgroundTransparency = 1
boardTitle.Font = Enum.Font.FredokaOne
boardTitle.TextScaled = true
boardTitle.TextColor3 = Color3.fromRGB(255, 210, 60)
boardTitle.Text = "TOP MOG"
boardTitle.Parent = boardGui
local boardRows = {}
for i = 1, 10 do
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(0.92, 0, 0.08, 0)
	row.Position = UDim2.new(0.04, 0, 0.13 + (i - 1) * 0.087, 0)
	row.BackgroundTransparency = 1
	row.Font = Enum.Font.FredokaOne
	row.TextScaled = true
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.TextColor3 = i == 1 and Color3.fromRGB(255, 215, 60) or i == 2 and Color3.fromRGB(220, 220, 230) or i == 3 and Color3.fromRGB(230, 150, 90) or Color3.new(1, 1, 1)
	row.Text = ""
	row.Parent = boardGui
	boardRows[i] = row
end

-- BASES (big fenced enclosures in two rows next to the hub)
local PLOT_W, PLOT_D = 96, 80
local PEN = { X1 = -42, X2 = 42, Z1 = -34, Z2 = 34 } -- where your monsters walk (local)
local PLOT_COLORS = {
	Color3.fromRGB(255, 130, 130), Color3.fromRGB(130, 190, 255), Color3.fromRGB(150, 235, 150), Color3.fromRGB(255, 215, 120),
	Color3.fromRGB(215, 150, 255), Color3.fromRGB(130, 235, 235), Color3.fromRGB(255, 170, 215), Color3.fromRGB(230, 230, 230),
}

local plots = {}
local playerPlot = {}

local function buildPlot(index)
	local north = index <= 4
	local col = (index - 1) % 4
	local center = Vector3.new(-400 + col * 110, 0, north and 90 or -90)
	local cf = CFrame.lookAt(center, center + Vector3.new(0, 0, north and -1 or 1)) -- -Z points at the hub
	local color = PLOT_COLORS[index]
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. index
	folder.Parent = map

	block(Vector3.new(PLOT_W, 1, PLOT_D), cf * CFrame.new(0, 0.5, 0), Color3.fromRGB(140, 225, 110), Enum.Material.Grass, folder)

	-- white fence with a gate at the front
	local white = Color3.fromRGB(255, 255, 255)
	local fenceH = 5
	local function fenceLine(x1, z1, x2, z2)
		local a, b = Vector3.new(x1, 0, z1), Vector3.new(x2, 0, z2)
		local len = (b - a).Magnitude
		local mid = (a + b) / 2
		local dirCF = cf * CFrame.lookAt(mid, b)
		for _, h in ipairs({ 2, 4 }) do
			block(Vector3.new(0.4, 0.5, len), dirCF * CFrame.new(0, h, 0), white, Enum.Material.SmoothPlastic, folder)
		end
		local posts = math.max(1, math.floor(len / 5))
		for i = 0, posts do
			local p = a:Lerp(b, i / posts)
			block(Vector3.new(0.8, fenceH, 0.8), cf * CFrame.new(p.X, fenceH / 2 + 0.5, p.Z), color, Enum.Material.SmoothPlastic, folder)
		end
		local inv = block(Vector3.new(0.5, 12, len), dirCF * CFrame.new(0, 6.5, 0), white, nil, folder)
		inv.Transparency = 1
	end
	local hw, hd, door = PLOT_W / 2, PLOT_D / 2, 8
	fenceLine(-hw, hd, hw, hd)
	fenceLine(-hw, -hd, -hw, hd)
	fenceLine(hw, -hd, hw, hd)
	fenceLine(-hw, -hd, -door, -hd)
	fenceLine(door, -hd, hw, -hd)

	-- cosy pen stuff: a pond and a feeding trough
	local pond = block(Vector3.new(1, 14, 14), cf * CFrame.new(28, 1.05, 22) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(90, 190, 255), Enum.Material.Glass, folder)
	pond.Shape = Enum.PartType.Cylinder
	pond.Transparency = 0.2
	pond.CanCollide = false
	local trough = block(Vector3.new(9, 1.6, 3), cf * CFrame.new(-30, 1.8, 28), Color3.fromRGB(200, 150, 100), Enum.Material.WoodPlanks, folder)
	local hay = block(Vector3.new(8.4, 0.3, 2.4), trough.CFrame * CFrame.new(0, 0.7, 0), Color3.fromRGB(240, 210, 110), Enum.Material.Grass, folder)
	hay.CanCollide = false

	-- MOG TRAINING STATION (outside, next to the gate)
	local stationCF = cf * CFrame.new(24, 0, -hd - 10)
	block(Vector3.new(12, 0.4, 12), stationCF * CFrame.new(0, 0.3, 0), color:Lerp(Color3.new(1, 1, 1), 0.4), Enum.Material.SmoothPlastic, folder)
	local stone = block(Vector3.new(5, 4.5, 5), stationCF * CFrame.new(0, 2.6, 0), Color3.fromRGB(190, 190, 200), Enum.Material.Rock, folder)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = stone
	stone.Name = "MogStone"
	local trainPrompt = Instance.new("ProximityPrompt")
	trainPrompt.Name = "Train"
	trainPrompt.ActionText = "Train MOG"
	trainPrompt.ObjectText = "Mog Stone"
	trainPrompt.MaxActivationDistance = 12
	trainPrompt.RequiresLineOfSight = false
	trainPrompt.Parent = stone
	local _, stoneLabels = billboard(stone, 220, 50, Vector3.new(0, 5, 0), 2)
	stoneLabels[1].Text = "MOG TRAINING"
	stoneLabels[1].TextColor3 = Color3.fromRGB(255, 120, 200)
	stoneLabels[2].Text = "Press E to train"

	local signPart = block(Vector3.new(1, 1, 1), cf * CFrame.new(0, 12, -hd), color, nil, folder)
	signPart.Transparency = 1
	signPart.CanCollide = false
	local _, labels = billboard(signPart, 300, 90, Vector3.new(), 3)
	labels[1].TextColor3 = color
	labels[1].Text = "Empty Base"

	local plot = {
		Index = index, CF = cf, Owner = nil, Slots = {}, Stone = stone, TrainPrompt = trainPrompt,
		NameLabel = labels[1], IncomeLabel = labels[2], StatusLabel = labels[3],
	}
	plot.PenRegion = { CF = cf, X1 = PEN.X1, X2 = PEN.X2, Z1 = PEN.Z1, Z2 = PEN.Z2, GroundY = 1, Speed = CONFIG.PEN_SPEED }
	plots[index] = plot
	return plot
end

for i = 1, 8 do
	buildPlot(i)
end

local function plotAt(position)
	for _, plot in ipairs(plots) do
		local p = plot.CF:PointToObjectSpace(position)
		if math.abs(p.X) <= PLOT_W / 2 and math.abs(p.Z) <= PLOT_D / 2 and p.Y > -5 and p.Y < 40 then
			return plot
		end
	end
	return nil
end

local zoneRegions = {}
for k = 1, #ZONES do
	local z = zoneInfo[k]
	zoneRegions[k] = {
		CF = CFrame.new(z.X0 + ZONE_LEN / 2, 0, 0),
		X1 = -ZONE_LEN / 2 + 10, X2 = ZONE_LEN / 2 - 10, Z1 = -ROAD_W / 2 + 10, Z2 = ROAD_W / 2 - 10,
		GroundY = 0.4, Speed = CONFIG.WANDER_SPEED,
	}
end

-- a few lamps along the hub
for x = -470, -30, 55 do
	for _, z in ipairs({ -47, 47 }) do
		block(Vector3.new(0.8, 12, 0.8), CFrame.new(x, 6, z), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
		local bulb = block(Vector3.new(2.4, 2.4, 2.4), CFrame.new(x, 12.6, z), Color3.fromRGB(255, 235, 170), Enum.Material.Neon)
		bulb.Shape = Enum.PartType.Ball
		bulb.CanCollide = false
	end
end

----------------------------------------------------------------------
-- PLAYER DATA
----------------------------------------------------------------------
local store, boardStore
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("MogMonsters_v2")
	end)
	if ok then
		store = result
	else
		warn("Saving is off: " .. tostring(result))
	end
	local ok2, result2 = pcall(function()
		return DataStoreService:GetOrderedDataStore("MogLeaderboard_v1")
	end)
	if ok2 then
		boardStore = result2
	end
end
local sessions = {}

local function newData()
	return {
		Cash = CONFIG.START_CASH, Mog = CONFIG.START_MOG, Hammer = 1, Swing = 1, Auras = {}, Aura = "",
		Boost = 0, Slots = CONFIG.START_SLOTS, Rebirths = 0, Monsters = {}, Discovered = {}, LastDaily = 0, Streak = 0,
	}
end

local function loadData(player)
	if not store then
		local data = newData()
		data.NoSave = true
		return data
	end
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return store:GetAsync("player_" .. player.UserId)
		end)
		if ok then
			local data = newData()
			if type(result) == "table" then
				for k, v in pairs(result) do
					data[k] = v
				end
			end
			return data
		end
		warn("Load failed (attempt " .. attempt .. "): " .. tostring(result))
		task.wait(1)
	end
	local data = newData()
	data.NoSave = true
	return data
end

local function saveData(player)
	local data = sessions[player]
	local plot = playerPlot[player]
	if not data or data.NoSave or not store then
		return
	end
	local monsters = {}
	if plot then
		for slot, m in pairs(plot.Slots) do
			if m.Owner == player then
				table.insert(monsters, { Id = m.Id, V = m.Variant, S = slot })
			end
		end
	end
	local toSave = {}
	for k, v in pairs(data) do
		toSave[k] = v
	end
	toSave.Monsters = monsters
	toSave.NoSave = nil
	local ok, err = pcall(function()
		store:SetAsync("player_" .. player.UserId, toSave)
	end)
	if not ok then
		warn("Save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

local function playerMog(player)
	local data = sessions[player]
	return data and math.floor(data.Mog) or 0
end

local function updateStats(player)
	local data = sessions[player]
	local stats = player:FindFirstChild("leaderstats")
	if data and stats then
		stats.MOG.Value = math.floor(data.Mog)
		stats.Cash.Value = math.floor(data.Cash)
		stats.Rebirths.Value = data.Rebirths
	end
	if data then
		player:SetAttribute("Mog", math.floor(data.Mog))
	end
end

local function slotLimit(player)
	local data = sessions[player]
	local n = data and data.Slots or CONFIG.START_SLOTS
	if player:GetAttribute("ExtraSlots") then
		n = n + 5
	end
	return n
end

local function moneyMultiplier(player)
	local data = sessions[player]
	local m = (1 + (data and data.Rebirths or 0)) * BOOST_MULTS[(data and data.Boost or 0) + 1]
	if player:GetAttribute("DoubleMoney") then
		m = m * 2
	end
	if player:GetAttribute("VIP") then
		m = m * 1.2
	end
	return m
end

local function auraMult(data)
	local a = AURA_BY_NAME[data.Aura or ""]
	return a and a.Mult or 1
end

local function mogPerHit(player)
	local data = sessions[player]
	if not data then
		return 0
	end
	local m = HAMMERS[data.Hammer].Power * auraMult(data) * (1 + data.Rebirths)
	if player:GetAttribute("DoubleMog") then
		m = m * 2
	end
	return m
end

local function rebirthCost(data)
	return CONFIG.REBIRTH_BASE_COST * CONFIG.REBIRTH_COST_MULT ^ data.Rebirths
end
local function slotCost(data)
	return math.floor(CONFIG.SLOT_BASE_COST * 2.2 ^ (data.Slots - CONFIG.START_SLOTS))
end
local function boostCost(data)
	return BOOST_BASE_COST * 4 ^ data.Boost
end

----------------------------------------------------------------------
-- LUCK & ROLLS
----------------------------------------------------------------------
local luckUntil = 0
local rushUntil = 0
local function luck()
	local l = 1
	if os.clock() < luckUntil then
		l = l * 2
	end
	if os.clock() < rushUntil then
		l = l * 3
	end
	return l
end

local function rollVariant(extraLuck)
	local l = luck() * (extraLuck or 1)
	local r = math.random()
	local acc = 0
	for i = #VARIANTS, 2, -1 do
		acc = acc + VARIANTS[i].Chance * l
		if r < acc then
			return i
		end
	end
	return 1
end

local function randomSpecies(rarity)
	local options = {}
	for _, def in ipairs(MONSTERS) do
		if def.Rarity == rarity and not def.Exclusive then
			table.insert(options, def.Id)
		end
	end
	return options[math.random(1, #options)]
end

----------------------------------------------------------------------
-- MONSTER LOOKS (bodies made of smooth ovals, sticks and balls)
----------------------------------------------------------------------
local modelFolder = ServerStorage:FindFirstChild("MonsterModels")
if not modelFolder then
	modelFolder = Instance.new("Folder")
	modelFolder.Name = "MonsterModels"
	modelFolder.Parent = ServerStorage
end

local function buildBody(def, variant)
	local rarity = RARITIES[def.Rarity]
	local v = VARIANTS[variant]
	local s = (2.8 + def.Rarity * 0.55) * (def.Scale or 1)
	local plan = def.Plan
	local white, black = Color3.new(1, 1, 1), Color3.fromRGB(25, 25, 30)
	local DEG = math.rad

	-- the colors of this monster. A Silver/Golden/... level paints the whole body.
	local base = def.Color or def.Skin or rgb(200, 200, 200)
	local palette = {
		skin = def.Skin or base, shirt = def.Shirt or base, pants = def.Pants or base,
		hair = def.Hair or base, shoes = def.Shoes or (def.Skin or base), body = base,
		accent = def.Accent or base:Lerp(black, 0.3),
	}
	local mat = v.Material or def.Material or Enum.Material.SmoothPlastic
	if v.Color then
		for k, c in pairs(palette) do
			palette[k] = k == "accent" and v.Color:Lerp(Color3.new(1, 1, 1), 0.35) or v.Color:Lerp(c, 0.12)
		end
	end

	local root = Instance.new("Part")
	root.Name = "Monster"
	root.Anchored = true
	root.CanCollide = false
	root.CustomPhysicalProperties = PhysicalProperties.new(1, 1, 0, 1, 1)
	root.CFrame = CFrame.new()
	local rootMesh = Instance.new("SpecialMesh")
	rootMesh.MeshType = Enum.MeshType.Sphere
	rootMesh.Parent = root

	-- kind: "egg" (smooth oval), "ball", "cyl" (round stick along Y), "block"
	local function add(size, offset, color, kind, material, transparency)
		local p = Instance.new("Part")
		p.Name = "Deco"
		if palette[color] then
			p.Color = palette[color]
			p.Material = (color == "accent" and not v.Color) and (material or Enum.Material.SmoothPlastic) or mat
			p:SetAttribute("Skin", true)
		else
			p.Color = color
			p.Material = material or Enum.Material.SmoothPlastic
		end
		p.Transparency = transparency or 0
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.Anchored = false
		if kind == "cyl" then
			p.Shape = Enum.PartType.Cylinder
			p.Size = Vector3.new(size.Y, size.X, size.Z)
			p.CFrame = offset * CFrame.Angles(0, 0, DEG(90))
		else
			p.Size = size
			p.CFrame = offset
			if kind == "egg" then
				local m = Instance.new("SpecialMesh")
				m.MeshType = Enum.MeshType.Sphere
				m.Parent = p
			elseif kind == "ball" then
				p.Shape = Enum.PartType.Ball
			end
		end
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = p
		w.Parent = p
		p.Parent = root
		return p
	end
	local function V(x, y, z)
		return Vector3.new(x, y, z)
	end
	local function at(x, y, z)
		return CFrame.new(x, y, z)
	end
	-- makes a body part move: the client swings it around "pivot" (walking legs,
	-- swinging arms, flapping wings, wagging tails)
	local function limb(p, kind, phase, pivot, amp)
		local wc = p:FindFirstChildOfClass("WeldConstraint")
		if wc then
			wc:Destroy()
		end
		local w = Instance.new("Weld")
		w.Name = "LimbWeld"
		w.Part0 = root
		w.Part1 = p
		w.C0 = p.CFrame -- the root sits at (0,0,0) while we build, so this is the offset
		w.Parent = p
		p:SetAttribute("Limb", kind)
		p:SetAttribute("Phase", phase)
		p:SetAttribute("Pivot", pivot)
		p:SetAttribute("Amp", amp)
		return p
	end
	local function eyes(x, y, z, size, glow, pupil)
		for _, sx in ipairs({ -1, 1 }) do
			if glow then
				add(V(size, size, size), at(sx * x, y, z), glow, "ball", Enum.Material.Neon)
			else
				add(V(size, size * 0.85, size * 0.6), at(sx * x, y, z), white, "egg")
				add(V(size * 0.5, size * 0.5, size * 0.3), at(sx * x, y, z - size * 0.25), pupil or rgb(60, 40, 30), "egg")
				add(V(size * 0.22, size * 0.22, size * 0.1), at(sx * x, y, z - size * 0.33), black, "egg")
			end
		end
	end

	local foot, hover = s * 0.5, 0

	if plan == "humanoid" then
		local st = def.Style
		local u = s * 0.42 * (def.Height or 1)
		local furry = st == "bigfoot" or st == "werewolf"
		local barefoot = furry or st == "troll" or st == "mothman"
		-- torso (root)
		root.Size = V(1.15 * u, 1.45 * u, 0.75 * u)
		root.Color = palette.shirt
		root.Material = mat
		root:SetAttribute("Skin", true)
		if st == "troll" then
			add(V(1.4 * u, 1.15 * u, 1.05 * u), at(0, -0.35 * u, -0.2 * u), "skin", "egg") -- big belly
		end
		if st == "werewolf" or st == "bigfoot" or st == "troll" then
			add(V(1.35 * u, 0.7 * u, 0.85 * u), at(0, 0.55 * u, 0.05 * u), "skin", "egg") -- big shoulders
		end
		add(V(1.05 * u, 0.6 * u, 0.72 * u), at(0, -0.8 * u, 0), "pants", "egg") -- hips
		-- legs
		for _, sx in ipairs({ -1, 1 }) do
			local ph, hip = sx < 0 and 0 or 1, V(sx * 0.28 * u, -0.85 * u, 0)
			limb(add(V(0.44 * u, 1.0 * u, 0.44 * u), at(sx * 0.28 * u, -1.35 * u, 0), "pants", "cyl"), "walk", ph, hip, 0.55)
			limb(add(V(0.48 * u, 0.4 * u, 0.48 * u), at(sx * 0.28 * u, -1.8 * u, 0), "pants", "egg"), "walk", ph, hip, 0.55) -- knee
			limb(add(V(0.38 * u, 0.9 * u, 0.38 * u), at(sx * 0.28 * u, -2.2 * u, 0), barefoot and "skin" or "pants", "cyl"), "walk", ph, hip, 0.55)
			limb(add(V(0.44 * u, 0.28 * u, 0.8 * u), at(sx * 0.28 * u, -2.7 * u, -0.17 * u), barefoot and "skin" or "shoes", "egg"), "walk", ph, hip, 0.55)
		end
		foot = 2.82 * u
		-- arms
		local armLen = (st == "bigfoot" or st == "troll") and 1.15 or 1
		for _, sx in ipairs({ -1, 1 }) do
			add(V(0.46 * u, 0.46 * u, 0.46 * u), at(sx * 0.68 * u, 0.55 * u, 0), "shirt", "ball")
			local ph, shoulder = sx < 0 and 1 or 0, V(sx * 0.7 * u, 0.5 * u, 0)
			if st == "zombie" then
				limb(add(V(0.34 * u, 0.85 * u, 0.34 * u), at(sx * 0.66 * u, 0.5 * u, -0.45 * u) * CFrame.Angles(DEG(-90), 0, 0), "shirt", "cyl"), "walk", ph, shoulder, 0.15)
				limb(add(V(0.3 * u, 0.8 * u, 0.3 * u), at(sx * 0.66 * u, 0.5 * u, -1.22 * u) * CFrame.Angles(DEG(-90), 0, 0), "skin", "cyl"), "walk", ph, shoulder, 0.15)
				limb(add(V(0.32 * u, 0.3 * u, 0.42 * u), at(sx * 0.66 * u, 0.48 * u, -1.72 * u), "skin", "egg"), "walk", ph, shoulder, 0.15)
			else
				limb(add(V(0.34 * u, 0.85 * u * armLen, 0.34 * u), at(sx * 0.76 * u, 0.05 * u, 0) * CFrame.Angles(0, 0, sx * DEG(8)), "shirt", "cyl"), "walk", ph, shoulder, 0.45)
				limb(add(V(0.3 * u, 0.8 * u * armLen, 0.3 * u), at(sx * 0.82 * u, -0.75 * u * armLen, 0), (st == "vampire") and "shirt" or "skin", "cyl"), "walk", ph, shoulder, 0.45)
				local hand = limb(add(V(0.32 * u, 0.4 * u, 0.3 * u), at(sx * 0.84 * u, -1.2 * u * armLen, 0), "skin", "egg"), "walk", ph, shoulder, 0.45)
				if st == "werewolf" or st == "troll" or st == "bigfoot" then
					for i = -1, 1 do
						limb(add(V(0.06 * u, 0.22 * u, 0.06 * u), at(sx * 0.84 * u + i * 0.08 * u, -1.45 * u * armLen, -0.08 * u) * CFrame.Angles(DEG(-20), 0, 0), st == "werewolf" and white or "accent", "cyl"), "walk", ph, shoulder, 0.45)
					end
				end
				hand.Name = "Hand"
			end
		end
		-- neck + head
		local hz = st == "troll" and -0.3 * u or (st == "zombie" and -0.12 * u or 0)
		local hy = st == "troll" and 1.25 * u or 1.38 * u
		add(V(0.38 * u, 0.4 * u, 0.38 * u), at(0, 0.85 * u, hz * 0.5), "skin", "cyl")
		add(V(0.74 * u, 0.86 * u, 0.8 * u), at(0, hy, hz), "skin", "egg")
		local fz = hz - 0.38 * u -- front of the face
		if st == "werewolf" then
			add(V(0.42 * u, 0.38 * u, 0.62 * u), at(0, hy - 0.12 * u, fz - 0.15 * u), "skin", "egg") -- snout
			add(V(0.16 * u, 0.12 * u, 0.12 * u), at(0, hy - 0.02 * u, fz - 0.45 * u), black, "egg") -- nose
			for _, sx in ipairs({ -1, 1 }) do
				add(V(0.2 * u, 0.42 * u, 0.12 * u), at(sx * 0.24 * u, hy + 0.5 * u, hz) * CFrame.Angles(0, 0, -sx * DEG(15)), "hair", "egg") -- ears
				add(V(0.05 * u, 0.14 * u, 0.05 * u), at(sx * 0.1 * u, hy - 0.3 * u, fz - 0.3 * u), white, "cyl") -- fangs
			end
			eyes(0.17 * u, hy + 0.12 * u, fz + 0.02 * u, 0.13 * u, palette.accent)
		elseif st == "mothman" then
			eyes(0.2 * u, hy + 0.08 * u, fz + 0.04 * u, 0.32 * u, def.Accent)
			for _, sx in ipairs({ -1, 1 }) do
				add(V(0.04 * u, 0.6 * u, 0.04 * u), at(sx * 0.15 * u, hy + 0.6 * u, hz - 0.1 * u) * CFrame.Angles(DEG(-20), 0, -sx * DEG(25)), "hair", "cyl") -- antennae
				local wing = add(V(0.08 * u, 2.4 * u, 1.7 * u), at(sx * 1.05 * u, 0.5 * u, 0.5 * u) * CFrame.Angles(0, sx * DEG(-20), -sx * DEG(30)), "hair", "egg")
				wing.Name = "Wing"
				limb(wing, "flap", sx < 0 and 0 or 1, V(sx * 0.4 * u, 0.5 * u, 0.4 * u), 0.35)
				limb(add(V(0.1 * u, 0.5 * u, 0.5 * u), at(sx * 1.35 * u, 0.9 * u, 0.62 * u), "accent", "egg", Enum.Material.Neon), "flap", sx < 0 and 0 or 1, V(sx * 0.4 * u, 0.5 * u, 0.4 * u), 0.35)
			end
		else
			local pupil = (st == "vampire") and def.Accent or (st == "zombie" and rgb(200, 200, 120) or nil)
			eyes(0.16 * u, hy + 0.08 * u, fz + 0.03 * u, 0.2 * u, nil, pupil)
			local noseSize = st == "troll" and 0.34 or (st == "redcap" and 0.2 or 0.14)
			add(V(noseSize * u, noseSize * 1.2 * u, noseSize * u), at(0, hy - 0.05 * u, fz - 0.03 * u), "skin", "egg") -- nose
			add(V(0.28 * u, 0.06 * u, 0.06 * u), at(0, hy - 0.26 * u, fz + 0.04 * u), rgb(90, 30, 40), "egg") -- mouth
			if st == "bigfoot" then
				add(V(0.5 * u, 0.4 * u, 0.3 * u), at(0, hy - 0.15 * u, fz + 0.04 * u), "accent", "egg") -- ape face
				add(V(0.6 * u, 0.12 * u, 0.2 * u), at(0, hy + 0.2 * u, fz + 0.02 * u), "hair", "egg") -- brow
			end
			if st == "vampire" or st == "troll" then
				for _, sx in ipairs({ -1, 1 }) do
					local tooth = add(V(0.05 * u, 0.12 * u, 0.05 * u), at(sx * 0.07 * u, hy - 0.32 * u, fz + 0.02 * u), white, "cyl")
					if st == "troll" then
						tooth.Size = Vector3.new(0.2 * u, 0.08 * u, 0.08 * u)
					end
				end
			end
		end
		-- hair / hats / clothes
		if st ~= "mothman" and st ~= "troll" then
			add(V(0.8 * u, 0.5 * u, 0.84 * u), at(0, hy + 0.27 * u, hz + 0.05 * u), "hair", "egg")
		end
		if st == "redcap" then
			add(V(0.82 * u, 0.25 * u, 0.86 * u), at(0, hy + 0.38 * u, hz + 0.04 * u), "accent", "egg")
			add(V(0.55 * u, 0.9 * u, 0.55 * u), at(0, hy + 0.75 * u, hz + 0.18 * u) * CFrame.Angles(DEG(25), 0, 0), "accent", "egg")
			add(V(0.55 * u, 0.55 * u, 0.3 * u), at(0, hy - 0.4 * u, fz + 0.05 * u), "hair", "egg") -- beard
		elseif st == "leprechaun" then
			add(V(0.18 * u, 1.15 * u, 1.15 * u), at(0, hy + 0.42 * u, hz) * CFrame.Angles(0, 0, DEG(90)), "shirt", "cyl")
			add(V(0.7 * u, 0.65 * u, 0.7 * u), at(0, hy + 0.78 * u, hz), "shirt", "cyl")
			add(V(0.72 * u, 0.14 * u, 0.72 * u), at(0, hy + 0.55 * u, hz), black, "cyl")
			add(V(0.2 * u, 0.14 * u, 0.06 * u), at(0, hy + 0.55 * u, hz - 0.36 * u), "accent", "block", Enum.Material.Neon)
			add(V(0.65 * u, 0.6 * u, 0.35 * u), at(0, hy - 0.42 * u, fz + 0.06 * u), "hair", "egg") -- beard
			add(V(1.2 * u, 0.15 * u, 0.8 * u), at(0, -0.5 * u, 0), black, "egg") -- belt
			add(V(0.25 * u, 0.2 * u, 0.06 * u), at(0, -0.5 * u, -0.4 * u), "accent", "block", Enum.Material.Neon)
		elseif st == "vampire" then
			add(V(1.6 * u, 2.7 * u, 0.14 * u), at(0, -0.6 * u, 0.42 * u), rgb(25, 10, 15), "egg") -- cape
			add(V(1.5 * u, 2.5 * u, 0.1 * u), at(0, -0.6 * u, 0.36 * u), "accent", "egg") -- red inside
			for _, sx in ipairs({ -1, 1 }) do
				add(V(0.5 * u, 0.7 * u, 0.08 * u), at(sx * 0.38 * u, 1.0 * u, 0.15 * u) * CFrame.Angles(0, 0, -sx * DEG(20)), rgb(25, 10, 15), "block") -- collar
			end
		elseif st == "zombie" then
			add(V(0.5 * u, 0.4 * u, 0.1 * u), at(0.2 * u, -0.2 * u, -0.36 * u), "skin", "egg") -- hole in the shirt
		elseif st == "troll" then
			add(V(1.3 * u, 0.5 * u, 0.9 * u), at(0, -0.9 * u, 0), "pants", "egg") -- loincloth
			add(V(0.35 * u, 0.3 * u, 0.35 * u), at(0, hy + 0.4 * u, hz + 0.05 * u), "hair", "egg") -- tuft
		end

	elseif plan == "quadruped" then
		local st = def.Style
		local u = s * 0.5
		local horse, fox = st == "horse", st == "fox"
		local bodyLen = horse and 2.4 or (fox and 1.6 or 1.7)
		local legLen = horse and 1.1 or 0.6
		root.Size = V((horse and 1.1 or 0.85) * u, (horse and 1.1 or 0.8) * u, bodyLen * u)
		root.Color = palette.body
		root.Material = mat
		root:SetAttribute("Skin", true)
		local legX = horse and 0.36 * u or 0.3 * u
		local legZ = bodyLen * 0.34 * u
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local ph, hip = (sx * sz > 0) and 0 or 1, V(sx * legX, -0.2 * u, sz * legZ)
				add(V(0.48 * u, 0.7 * u, 0.55 * u), at(sx * legX, -0.3 * u, sz * legZ), "body", "egg") -- thigh
				limb(add(V(0.24 * u, legLen * u, 0.24 * u), at(sx * legX, -0.4 * u - legLen * 0.5 * u, sz * legZ), "body", "cyl"), "walk", ph, hip, 0.45)
				limb(add(V(0.2 * u, legLen * u, 0.2 * u), at(sx * legX, -0.4 * u - legLen * 1.4 * u, sz * legZ), "body", "cyl"), "walk", ph, hip, 0.45)
				limb(add(V(0.3 * u, 0.2 * u, horse and 0.32 * u or 0.4 * u), at(sx * legX, -0.4 * u - legLen * 1.9 * u, sz * legZ - 0.05 * u), horse and black or "body", "egg"), "walk", ph, hip, 0.45)
			end
		end
		foot = 0.4 * u + legLen * 1.9 * u + 0.1 * u
		-- neck + head
		local hy, hz
		if horse then
			add(V(0.6 * u, 1.5 * u, 0.75 * u), at(0, 0.85 * u, -1.15 * u) * CFrame.Angles(DEG(-30), 0, 0), "body", "egg")
			hy, hz = 1.5 * u, -1.65 * u
			add(V(0.55 * u, 0.6 * u, 1.1 * u), at(0, hy, hz) * CFrame.Angles(DEG(20), 0, 0), "body", "egg")
			add(V(0.45 * u, 0.42 * u, 0.4 * u), at(0, hy - 0.25 * u, hz - 0.5 * u), "body", "egg") -- muzzle
			for _, sx in ipairs({ -1, 1 }) do
				add(V(0.06 * u, 0.06 * u, 0.04 * u), at(sx * 0.1 * u, hy - 0.22 * u, hz - 0.7 * u), black, "egg") -- nostrils
				add(V(0.12 * u, 0.3 * u, 0.08 * u), at(sx * 0.15 * u, hy + 0.42 * u, hz + 0.3 * u), "body", "egg") -- ears
			end
			eyes(0.24 * u, hy + 0.12 * u, hz - 0.2 * u, 0.14 * u, nil, black)
			add(V(0.18 * u, 1.6 * u, 0.5 * u), at(0, 1.15 * u, -1.0 * u) * CFrame.Angles(DEG(-30), 0, 0), "accent", "egg") -- mane
			limb(add(V(0.32 * u, 1.4 * u, 0.32 * u), at(0, -0.35 * u, bodyLen * 0.55 * u) * CFrame.Angles(DEG(25), 0, 0), "accent", "egg"), "tail", 0, V(0, 0.2 * u, bodyLen * 0.48 * u), 0.3) -- tail
		else
			add(V(0.5 * u, 0.7 * u, 0.55 * u), at(0, 0.35 * u, -0.75 * u * bodyLen / 1.7) * CFrame.Angles(DEG(-30), 0, 0), "body", "egg")
			hy, hz = 0.72 * u, -1.05 * u * bodyLen / 1.7
			add(V(0.62 * u, 0.58 * u, 0.62 * u), at(0, hy, hz), "body", "egg")
			add(V(0.32 * u, 0.28 * u, (fox and 0.6 or 0.48) * u), at(0, hy - 0.08 * u, hz - 0.42 * u), fox and "accent" or "body", "egg") -- snout
			add(V(0.12 * u, 0.1 * u, 0.1 * u), at(0, hy - 0.02 * u, hz - (fox and 0.72 or 0.66) * u), black, "egg") -- nose
			for _, sx in ipairs({ -1, 1 }) do
				add(V(0.18 * u, (fox and 0.5 or 0.36) * u, 0.1 * u), at(sx * 0.2 * u, hy + 0.38 * u, hz + 0.05 * u) * CFrame.Angles(0, 0, -sx * DEG(12)), "body", "egg") -- ears
			end
			eyes(0.15 * u, hy + 0.1 * u, hz - 0.27 * u, 0.13 * u, st == "dog" and def.Accent or nil, fox and rgb(255, 200, 40) or nil)
			if fox then
				for i = 1, 9 do
					local a = DEG(-60 + (i - 1) * 15)
					local tail = add(V(0.32 * u, 1.5 * u, 0.32 * u), at(0, 0, bodyLen * 0.5 * u) * CFrame.Angles(0, 0, a) * CFrame.Angles(DEG(45), 0, 0) * at(0, 0.75 * u, 0), "body", "egg")
					tail.Name = "Tail"
					local tip = add(V(0.26 * u, 0.4 * u, 0.26 * u), tail.CFrame * at(0, 0.6 * u, 0), "accent", "egg", Enum.Material.Neon)
					limb(tail, "tail", i / 9, V(0, 0, bodyLen * 0.5 * u), 0.25)
					limb(tip, "tail", i / 9, V(0, 0, bodyLen * 0.5 * u), 0.25)
				end
			else
				limb(add(V(0.16 * u, 0.9 * u, 0.16 * u), at(0, 0.25 * u, bodyLen * 0.55 * u) * CFrame.Angles(DEG(45), 0, 0), "body", "egg"), "tail", 0, V(0, 0, bodyLen * 0.48 * u), 0.5) -- tail
			end
		end

	elseif plan == "ghost" then
		root.Size = V(s * 0.9, s * 1.1, s * 0.8)
		root.Color = palette.body
		root.Material = mat
		root.Transparency = 0.25
		root:SetAttribute("Skin", true)
		for i = 1, 4 do
			local w = s * (0.85 - i * 0.12)
			local tail = add(V(w, s * 0.5, w * 0.9), at(math.sin(i) * s * 0.08, -s * (0.35 + i * 0.28), s * i * 0.1), "body", "egg")
			tail.Transparency = 0.25 + i * 0.15
		end
		for _, sx in ipairs({ -1, 1 }) do
			add(V(s * 0.22, s * 0.28, s * 0.1), at(sx * s * 0.18, s * 0.15, -s * 0.36), black, "egg")
			add(V(s * 0.08, s * 0.08, s * 0.05), at(sx * s * 0.18, s * 0.15, -s * 0.41), def.Accent, "ball", Enum.Material.Neon)
			local arm = add(V(s * 0.18, s * 0.7, s * 0.18), at(sx * s * 0.5, -s * 0.05, -s * 0.15) * CFrame.Angles(DEG(-50), 0, sx * DEG(20)), "body", "egg")
			arm.Transparency = 0.35
		end
		add(V(s * 0.2, s * 0.3, s * 0.08), at(0, -s * 0.15, -s * 0.38), black, "egg") -- "oooh" mouth
		foot = s * 0.55
		hover = 2.5

	elseif plan == "serpent" then
		-- Grootslang: giant snake body with an elephant head
		root.Size = V(s * 0.95, s * 0.85, s * 1.0)
		root.Color = palette.body
		root.Material = mat
		root:SetAttribute("Skin", true)
		for _, sx in ipairs({ -1, 1 }) do
			add(V(s * 0.08, s * 0.85, s * 0.7), at(sx * s * 0.52, s * 0.05, s * 0.05) * CFrame.Angles(0, sx * DEG(25), 0), "body", "egg") -- big ears
			add(V(s * 0.08, s * 0.55, s * 0.08), at(sx * s * 0.2, -s * 0.32, -s * 0.48) * CFrame.Angles(DEG(-60), 0, 0), "accent", "cyl") -- tusks
		end
		eyes(s * 0.22, s * 0.15, -s * 0.42, s * 0.12, nil, black)
		for i = 1, 4 do
			add(V(s * (0.28 - i * 0.03), s * 0.32, s * (0.28 - i * 0.03)), at(0, -s * (0.05 + i * 0.22), -s * (0.5 + i * 0.05)) * CFrame.Angles(DEG(i * 8), 0, 0), "body", "egg") -- trunk
		end
		for i = 1, 8 do
			local seg = s * (0.85 - i * 0.07)
			add(V(seg, seg * 0.8, seg * 1.3), at(math.sin(i * 0.8) * s * 0.4, -s * 0.15, s * (0.4 + i * 0.62)), i % 2 == 0 and "accent" or "body", "egg")
		end
		foot = s * 0.45

	elseif plan == "dragon" then
		local u = s * 0.55
		root.Size = V(1.1 * u, 1.0 * u, 2.0 * u)
		root.Color = palette.body
		root.Material = mat
		root:SetAttribute("Skin", true)
		add(V(0.9 * u, 0.6 * u, 1.6 * u), at(0, -0.25 * u, 0), "accent", "egg") -- belly
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local ph, hip = (sx * sz > 0) and 0 or 1, V(sx * 0.48 * u, -0.45 * u, sz * 0.6 * u)
				add(V(0.5 * u, 0.75 * u, 0.6 * u), at(sx * 0.45 * u, -0.35 * u, sz * 0.6 * u), "body", "egg")
				limb(add(V(0.3 * u, 0.7 * u, 0.3 * u), at(sx * 0.5 * u, -0.9 * u, sz * 0.6 * u), "body", "cyl"), "walk", ph, hip, 0.4)
				limb(add(V(0.4 * u, 0.2 * u, 0.5 * u), at(sx * 0.5 * u, -1.25 * u, sz * 0.6 * u - 0.1 * u), "body", "egg"), "walk", ph, hip, 0.4)
				for i = -1, 1 do
					limb(add(V(0.05 * u, 0.05 * u, 0.2 * u), at(sx * 0.5 * u + i * 0.12 * u, -1.3 * u, sz * 0.6 * u - 0.35 * u), white, "egg"), "walk", ph, hip, 0.4) -- claws
				end
			end
			-- wings: arm bone + big membrane
			local wingRoot = V(sx * 0.45 * u, 0.4 * u, 0.1 * u)
			limb(add(V(0.12 * u, 1.8 * u, 0.12 * u), at(sx * 1.0 * u, 0.9 * u, 0.1 * u) * CFrame.Angles(DEG(-15), 0, -sx * DEG(55)), "body", "cyl"), "flap", sx < 0 and 0 or 1, wingRoot, 0.3)
			local wing = add(V(0.06 * u, 2.4 * u, 2.2 * u), at(sx * 1.35 * u, 0.85 * u, 0.55 * u) * CFrame.Angles(DEG(-10), 0, -sx * DEG(55)), "accent", "egg", nil, 0.1)
			wing.Name = "Wing"
			limb(wing, "flap", sx < 0 and 0 or 1, wingRoot, 0.3)
		end
		-- neck and head
		for i = 1, 3 do
			add(V((0.6 - i * 0.05) * u, (0.6 - i * 0.05) * u, 0.6 * u), at(0, (0.35 + i * 0.32) * u, -(0.9 + i * 0.3) * u), "body", "egg")
		end
		local hy, hz = 1.55 * u, -2.05 * u
		add(V(0.65 * u, 0.55 * u, 0.85 * u), at(0, hy, hz), "body", "egg")
		add(V(0.45 * u, 0.25 * u, 0.6 * u), at(0, hy - 0.22 * u, hz - 0.45 * u), "body", "egg") -- jaw
		add(V(0.5 * u, 0.3 * u, 0.65 * u), at(0, hy - 0.02 * u, hz - 0.5 * u), "body", "egg") -- snout
		eyes(0.22 * u, hy + 0.12 * u, hz - 0.3 * u, 0.13 * u, rgb(255, 210, 50))
		for _, sx in ipairs({ -1, 1 }) do
			add(V(0.1 * u, 0.7 * u, 0.1 * u), at(sx * 0.22 * u, hy + 0.45 * u, hz + 0.35 * u) * CFrame.Angles(DEG(55), 0, -sx * DEG(20)), "accent", "cyl")
			add(V(0.04 * u, 0.12 * u, 0.04 * u), at(sx * 0.12 * u, hy - 0.2 * u, hz - 0.7 * u), white, "cyl") -- teeth
		end
		for i = 0, 5 do
			add(V(0.08 * u, 0.35 * u, 0.25 * u), at(0, 0.5 * u - i * 0.05 * u, -0.6 * u + i * 0.45 * u), "accent", "egg") -- back spikes
		end
		for i = 1, 6 do
			local w = (0.55 - i * 0.07) * u
			add(V(w, w, 0.7 * u), at(math.sin(i * 0.7) * 0.3 * u, -0.1 * u - i * 0.06 * u, (0.9 + i * 0.55) * u), "body", "egg") -- tail
		end
		if def.Crown then
			add(V(0.6 * u, 0.2 * u, 0.6 * u), at(0, hy + 0.38 * u, hz + 0.05 * u), rgb(255, 225, 80), "cyl", Enum.Material.Neon)
			for i = 1, 5 do
				local a = DEG(i * 72)
				add(V(0.08 * u, 0.3 * u, 0.08 * u), at(math.cos(a) * 0.25 * u, hy + 0.55 * u, hz + 0.05 * u + math.sin(a) * 0.25 * u), rgb(255, 225, 80), "cyl", Enum.Material.Neon)
			end
		end
		foot = 1.35 * u

	else -- bird
		root.Size = V(s * 0.8, s * 0.85, s * 1.0)
		root.Color = palette.body
		root.Material = mat
		root:SetAttribute("Skin", true)
		add(V(s * 0.5, s * 0.5, s * 0.5), at(0, s * 0.42, -s * 0.38), "body", "ball")
		add(V(s * 0.12, s * 0.12, s * 0.34), at(0, s * 0.37, -s * 0.72), rgb(255, 175, 40), "egg")
		eyes(s * 0.14, s * 0.5, -s * 0.56, s * 0.13)
		add(V(s * 0.08, s * 0.4, s * 0.3), at(0, s * 0.75, -s * 0.3), "accent", "egg", Enum.Material.Neon)
		for _, sx in ipairs({ -1, 1 }) do
			limb(add(V(s * 0.12, s * 0.8, s * 1.1), at(sx * s * 0.55, s * 0.2, s * 0.05) * CFrame.Angles(0, 0, sx * 0.6), "accent", "egg"), "flap", sx < 0 and 0 or 1, V(sx * s * 0.35, s * 0.25, 0), 0.4)
			local ph, hip = sx < 0 and 0 or 1, V(sx * s * 0.15, -s * 0.38, 0)
			limb(add(V(s * 0.07, s * 0.42, s * 0.07), at(sx * s * 0.15, -s * 0.58, 0), rgb(255, 175, 40), "cyl"), "walk", ph, hip, 0.6)
			limb(add(V(s * 0.18, s * 0.05, s * 0.22), at(sx * s * 0.15, -s * 0.78, -s * 0.06), rgb(255, 175, 40), "egg"), "walk", ph, hip, 0.6)
		end
		for i = -1, 1 do
			add(V(s * 0.18, s * 0.08, s * 0.9), at(i * s * 0.15, s * 0.1, s * 0.75) * CFrame.Angles(0.35, i * 0.3, 0), "accent", "egg", Enum.Material.Neon)
		end
		foot = s * 0.8
	end

	if def.Rarity >= 5 or variant >= 5 then
		local light = Instance.new("PointLight")
		light.Color = rarity.Color
		light.Range = 10 + def.Rarity * 2
		light.Brightness = 2
		light.Parent = root
	end
	if variant >= 6 or def.Rarity >= 7 then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.new(1, 1, 1)
		sparkles.Parent = root
	end
	if def.Rarity >= 4 or variant >= 3 then
		local aura = Instance.new("ParticleEmitter")
		aura.Color = ColorSequence.new(v.Color or rarity.Color)
		aura.LightEmission = 1
		aura.Rate = 4 + def.Rarity * 3
		aura.Lifetime = NumberRange.new(0.8, 1.4)
		aura.Speed = NumberRange.new(1, 2)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Size = NumberSequence.new(0.6, 0)
		aura.Parent = root
	end
	return root, s, foot, hover
end

-- Uses your own 3D model from ServerStorage.MonsterModels if there is one
local function useCustomModel(def, root, s)
	local template = modelFolder:FindFirstChild(def.Id)
	if not template or not template:IsA("Model") then
		return nil
	end
	local model = template:Clone()
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BaseScript") or d:IsA("ModuleScript") then
			d:Destroy()
		end
	end
	local _, size = model:GetBoundingBox()
	local biggest = math.max(size.X, size.Y, size.Z)
	if biggest > 0 then
		model:ScaleTo(model:GetScale() * (s * 1.8) / biggest)
	end
	local boxCF, boxSize = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() + (root.Position - boxCF.Position))
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = d
			w.Parent = d
		end
	end
	for _, d in ipairs(root:GetChildren()) do
		if d:IsA("BasePart") or d:IsA("SpecialMesh") then
			d:Destroy()
		end
	end
	model.Parent = root
	root.Transparency = 1
	root:SetAttribute("Skin", nil)
	return boxSize.Y / 2
end

----------------------------------------------------------------------
-- MONSTER OBJECTS
----------------------------------------------------------------------
local monstersByPart = {}
local carriers = {}
local wild = {}     -- [m] = true for monsters walking in a zone
local battles = {}  -- [player] = m
local trainers = {} -- [player] = { Plot, Next }
local zoneCount = {}
for k = 1, #ZONES do
	zoneCount[k] = 0
end

local applyMovement
local onMonsterPrompt

local function setState(m, state)
	m.State = state
	m.Part:SetAttribute("State", state)
end

local function updateLabel(m)
	local info = m.InfoLabel
	if m.State == "Lane" then
		info.Text = "NEED " .. fmt(m.MogReq) .. " MOG  |  $" .. fmt(m.Income) .. "/s"
	elseif m.State == "Battle" then
		info.Text = "MOG BATTLE!"
	elseif m.State == "Placed" or m.State == "Flying" then
		info.Text = "$" .. fmt(m.Income) .. "/s"
	elseif m.State == "Loose" then
		info.Text = "DROPPED! Grab it!"
	else
		info.Text = "HIT THEM TO TAKE IT!"
	end
end

local function createMonster(id, variant)
	local def = MONSTER_BY_ID[id]
	local rarity = RARITIES[def.Rarity]
	local v = VARIANTS[variant]
	local body, s, foot, hover = buildBody(def, variant)
	local customFoot = useCustomModel(def, body, s)
	if customFoot then
		foot, hover = customFoot, 0
	end

	local _, labels = billboard(body, 250, 84, Vector3.new(0, s * 0.6 + 2.8, 0), 3)
	labels[1].Text = displayName(id, variant)
	labels[1].TextColor3 = variant > 1 and (v.Color or Color3.fromRGB(255, 120, 255)) or rarity.Color
	local odds = oddsOf(id, variant)
	labels[2].Text = rarity.Name .. ((odds > 1) and ("  |  1 in " .. fmt(odds)) or "")
	labels[2].TextColor3 = rarity.Color
	if def.Rarity >= 7 then
		labels[2].TextStrokeColor3 = Color3.new(1, 1, 1)
	end
	labels[3].Name = "MogLabel"
	labels[1].Parent.MaxDistance = 120

	local m = {
		Part = body, Id = id, Def = def, Variant = variant, State = "New", Size = s,
		Foot = foot, Hover = hover, Walked = 0, Pause = 0,
		Income = monsterIncome(id, variant), MogReq = monsterMog(id, variant), Value = monsterValue(id, variant),
		InfoLabel = labels[3],
	}

	local prompts = {
		{ Name = "Mog", Action = "MOG BATTLE!", Hold = 0.2 },
		{ Name = "Sell", Action = "Sell $" .. fmt(m.Value * CONFIG.SELL_PERCENT), Hold = 1, Key = Enum.KeyCode.R },
		{ Name = "Grab", Action = "Pick up", Hold = 0.3 },
	}
	for _, info in ipairs(prompts) do
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = info.Name
		prompt.ActionText = info.Action
		prompt.ObjectText = displayName(id, variant)
		prompt.HoldDuration = info.Hold
		prompt.MaxActivationDistance = math.max(12, s * 1.5)
		prompt.RequiresLineOfSight = false
		if info.Key then
			prompt.KeyboardKeyCode = info.Key
		end
		prompt.Parent = body
		prompt.Triggered:Connect(function(player)
			onMonsterPrompt(m, info.Name, player)
		end)
	end

	body:SetAttribute("MonsterId", id)
	body:SetAttribute("Variant", v.Name)
	body:SetAttribute("MogReq", m.MogReq)
	body:SetAttribute("OwnerId", 0)
	body:SetAttribute("Slot", 0)
	body:SetAttribute("State", "New")
	CollectionService:AddTag(body, "Monster")
	monstersByPart[body] = m
	body.Parent = monsterFolder
	return m
end

local function monsterAlive(m)
	return monstersByPart[m.Part] == m
end

local function leaveWild(m)
	if wild[m] then
		wild[m] = nil
		zoneCount[m.Zone] = math.max(0, zoneCount[m.Zone] - 1)
	end
end

local function destroyMonster(m)
	monstersByPart[m.Part] = nil
	leaveWild(m)
	if m.BattleBy then
		battles[m.BattleBy] = nil
		m.BattleBy = nil
	end
	if m.Plot and m.Plot.Slots[m.Slot] == m then
		m.Plot.Slots[m.Slot] = nil
	end
	m.Part:Destroy()
end

local function regionPoint(region, m)
	local x = region.X1 + math.random() * (region.X2 - region.X1)
	local z = region.Z1 + math.random() * (region.Z2 - region.Z1)
	local p = region.CF * Vector3.new(x, 0, z)
	return Vector3.new(p.X, region.GroundY + m.Foot + m.Hover, p.Z)
end

local function freeSlot(plot, player)
	for i = 1, slotLimit(player) do
		if not plot.Slots[i] then
			return i
		end
	end
	return nil
end

local function countMonsters(plot)
	local n = 0
	for _ in pairs(plot.Slots) do
		n = n + 1
	end
	return n
end

local function place(m, plot, slot, owner, position)
	plot.Slots[slot] = m
	m.Plot, m.Slot, m.Owner = plot, slot, owner
	m.Region = plot.PenRegion
	local part = m.Part
	part.Anchored = true
	part.CanCollide = false
	local pos = position or regionPoint(m.Region, m)
	part.CFrame = CFrame.new(pos) * plot.CF.Rotation
	m.Target = regionPoint(m.Region, m)
	m.Pause = math.random() * 2
	part:SetAttribute("OwnerId", owner.UserId)
	part:SetAttribute("Slot", slot)
	setState(m, "Placed")
	updateLabel(m)
end

local function flyToSlot(m, plot, slot, owner)
	plot.Slots[slot] = m
	m.Plot, m.Slot, m.Owner = plot, slot, owner
	m.Region = plot.PenRegion
	local part = m.Part
	part.Anchored = true
	part.CanCollide = false
	part:SetAttribute("OwnerId", owner.UserId)
	part:SetAttribute("Slot", slot)
	setState(m, "Flying")
	updateLabel(m)
	local target = regionPoint(m.Region, m)
	local tween = TweenService:Create(part, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(target) * plot.CF.Rotation })
	tween.Completed:Connect(function()
		if monsterAlive(m) and m.State == "Flying" and plot.Slots[slot] == m and owner.Parent then
			place(m, plot, slot, owner, target)
		end
	end)
	tween:Play()
end

local function attachToCarrier(m, player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local part = m.Part
	part.CanCollide = false
	part.Massless = true
	part.CFrame = root.CFrame * CFrame.new(0, 3 + m.Foot, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	part.Anchored = false
	m.Carrier = player
	carriers[player] = m
	player:SetAttribute("Carrying", true)
	part:SetAttribute("OwnerId", 0)
	setState(m, "Carried")
	updateLabel(m)
	applyMovement(player)
	return true
end

local function detach(m)
	local part = m.Part
	local weld = part:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	part.Anchored = true
	part.Massless = false
	local carrier = m.Carrier
	m.Carrier = nil
	if carrier then
		carriers[carrier] = nil
		carrier:SetAttribute("Carrying", false)
		applyMovement(carrier)
	end
end

-- a monster nobody got home goes back to its zone
local function returnToWild(m)
	if not monsterAlive(m) then
		return
	end
	detach(m)
	if not m.Zone or zoneCount[m.Zone] >= ZONES[m.Zone].Max then
		destroyMonster(m)
		return
	end
	m.Plot, m.Slot, m.Owner = nil, nil, nil
	m.Region = zoneRegions[m.Zone]
	local pos = regionPoint(m.Region, m)
	m.Part.CFrame = CFrame.new(pos)
	m.Target = regionPoint(m.Region, m)
	m.Part:SetAttribute("OwnerId", 0)
	m.Part:SetAttribute("Slot", 0)
	setState(m, "Lane")
	updateLabel(m)
	wild[m] = true
	zoneCount[m.Zone] = zoneCount[m.Zone] + 1
	effect(pos, RARITIES[m.Def.Rarity].Color, "Escaped!")
end

local function discover(player, m)
	local data = sessions[player]
	if data and not data.Discovered[m.Id] then
		data.Discovered[m.Id] = true
		notify(player, "NEW MONSTER DISCOVERED: " .. m.Def.Name .. "!")
	end
end

local function deliver(m, player, plot, slot)
	detach(m)
	local pos = regionPoint(plot.PenRegion, m)
	place(m, plot, slot, player, pos)
	discover(player, m)
	local name = displayName(m.Id, m.Variant)
	effect(pos, RARITIES[m.Def.Rarity].Color, "MOGGED!")
	notify(player, name .. " is yours!")
	if m.Def.Rarity >= 5 or m.Variant >= 4 then
		announce(player.Name .. " brought home a " .. RARITIES[m.Def.Rarity].Name .. " " .. name .. "!")
	end
end

local function groundBelow(position)
	local params = RaycastParams.new()
	local ignore = { monsterFolder }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	params.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -100, 0), params)
	if result then
		return result.Position
	end
	return Vector3.new(position.X, 0, position.Z)
end

local function makeLoose(m, position)
	detach(m)
	local part = m.Part
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = CFrame.new(groundBelow(position) + Vector3.new(0, m.Foot + m.Hover, 0))
	part:SetAttribute("OwnerId", 0)
	setState(m, "Loose")
	updateLabel(m)
	local token = {}
	m.LooseToken = token
	task.delay(CONFIG.LOOSE_TIME, function()
		if monsterAlive(m) and m.State == "Loose" and m.LooseToken == token then
			returnToWild(m)
		end
	end)
end

-- give a player a brand new monster (daily, rebirth reward)
local function giveMonster(player, id, variant)
	local plot = playerPlot[player]
	if not plot then
		return false
	end
	local slot = freeSlot(plot, player)
	if not slot then
		return false
	end
	local m = createMonster(id, variant)
	m.Part.CFrame = CFrame.new(plot.CF.Position + Vector3.new(0, 50, 0))
	flyToSlot(m, plot, slot, player)
	discover(player, m)
	return true
end

----------------------------------------------------------------------
-- MOVEMENT & AURAS
----------------------------------------------------------------------
local function isAlive(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

applyMovement = function(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local data = sessions[player]
	if not hum or not data then
		return
	end
	local speed = 18
	if data.Rebirths >= 3 then
		speed = speed + math.min(10, 4 + (data.Rebirths - 3) * 2)
	end
	if carriers[player] then
		speed = speed - 3
	end
	if battles[player] then
		speed = 0
	end
	hum.WalkSpeed = speed
end

local function applyAura(player)
	local data = sessions[player]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not data or not root then
		return
	end
	local old = root:FindFirstChild("AuraFX")
	if old then
		old:Destroy()
	end
	local oldLight = root:FindFirstChild("AuraLight")
	if oldLight then
		oldLight:Destroy()
	end
	local a = AURA_BY_NAME[data.Aura or ""]
	player:SetAttribute("Aura", a and a.Name or "")
	if not a then
		return
	end
	local fx = Instance.new("ParticleEmitter")
	fx.Name = "AuraFX"
	fx.Color = a.Rainbow and ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 240, 60)),
		ColorSequenceKeypoint.new(0.66, Color3.fromRGB(60, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 60, 255)),
	}) or ColorSequence.new(a.Color)
	fx.LightEmission = 1
	fx.Rate = 30
	fx.Lifetime = NumberRange.new(0.6, 1.1)
	fx.Speed = NumberRange.new(2, 4)
	fx.SpreadAngle = Vector2.new(180, 180)
	fx.Size = NumberSequence.new(0.8, 0)
	fx.Parent = root
	local light = Instance.new("PointLight")
	light.Name = "AuraLight"
	light.Color = a.Color
	light.Range = 12
	light.Parent = root
end

----------------------------------------------------------------------
-- ZONE SPAWNING
----------------------------------------------------------------------
local function spawnZoneMonster(k, id)
	id = id or randomSpecies(k)
	local variant = rollVariant()
	local m = createMonster(id, variant)
	m.Zone = k
	m.Region = zoneRegions[k]
	local start = regionPoint(m.Region, m)
	m.Part.CFrame = CFrame.new(start)
	m.Target = regionPoint(m.Region, m)
	setState(m, "Lane")
	updateLabel(m)
	wild[m] = true
	zoneCount[k] = zoneCount[k] + 1
	effect(start, RARITIES[k].Color, nil)
	if k >= 6 or variant >= 5 or (k >= 5 and variant >= 3) then
		announce("A " .. RARITIES[k].Name:upper() .. " " .. displayName(id, variant) .. " appeared in ZONE " .. k .. "!")
	end
end

----------------------------------------------------------------------
-- MOG BATTLE (mini game)
----------------------------------------------------------------------
local function endBattle(m, player)
	battles[player] = nil
	if m.BattleBy == player then
		m.BattleBy = nil
	end
	if monsterAlive(m) and m.State == "Battle" then
		setState(m, "Lane")
		updateLabel(m)
		m.Pause = 1
	end
	applyMovement(player)
end

local function startBattle(m, player)
	local mog = playerMog(player)
	local ratio = math.clamp(m.MogReq / math.max(mog, 1), 0, 1) -- 1 = just strong enough (hard)
	local r = m.Def.Rarity
	m.BattleBy = player
	m.BattleStart = os.clock()
	battles[player] = m
	setState(m, "Battle")
	updateLabel(m)
	applyMovement(player)
	local data = sessions[player]
	local clickMult = 1 + ((data and data.Hammer or 1) - 1) * 0.08
	battleRemote:FireClient(player, m.Part, {
		Name = displayName(m.Id, m.Variant),
		Color = RARITIES[r].Color,
		ClickPower = 0.07 * clickMult,
		ClickMult = math.floor(clickMult * 10 + 0.5) / 10,
		Rarity = r,
		Type = math.random() < 0.5 and "Clash" or "Timing",
		Pull = 0.05 + 0.15 * ratio + r * 0.015,
		ZoneWidth = math.clamp(0.3 - 0.12 * ratio - r * 0.015, 0.07, 0.3),
		Speed = 0.7 + r * 0.12 + ratio * 0.3,
		Time = 12,
	})
end

local function battleResult(player, part, won)
	local m = typeof(part) == "Instance" and monstersByPart[part] or nil
	if not m or m.BattleBy ~= player then
		return false, "No battle"
	end
	local elapsed = os.clock() - (m.BattleStart or 0)
	endBattle(m, player)
	local name = displayName(m.Id, m.Variant)
	if won ~= true or elapsed < CONFIG.BATTLE_MIN_TIME then
		effect(m.Part.Position, Color3.fromRGB(255, 80, 80), "Too strong!")
		return true, name .. " won this time! Try again."
	end
	if carriers[player] or not isAlive(player) then
		return false, "You can't carry it right now"
	end
	leaveWild(m)
	if not attachToCarrier(m, player) then
		returnToWild(m)
		return false, "Something went wrong"
	end
	effect(m.Part.Position, RARITIES[m.Def.Rarity].Color, "YOU WON!")
	if m.Def.Rarity >= 5 or m.Variant >= 4 then
		announce(player.Name .. " beat a " .. RARITIES[m.Def.Rarity].Name .. " " .. name .. "! Hit them to take it!")
	end
	return true, "You won! CARRY " .. name .. " HOME before someone hits you!"
end

----------------------------------------------------------------------
-- MONSTER PROMPTS (Mog / Sell / Grab) - no stealing from bases!
----------------------------------------------------------------------
onMonsterPrompt = function(m, action, player)
	local data = sessions[player]
	local plot = playerPlot[player]
	if not data or not plot or not monsterAlive(m) or not isAlive(player) then
		return
	end
	local name = displayName(m.Id, m.Variant)

	if action == "Mog" then
		if m.State ~= "Lane" or m.BattleBy or battles[player] or carriers[player] then
			return
		end
		local mog = playerMog(player)
		if mog < m.MogReq then
			notify(player, "Your MOG is too low! You have " .. fmt(mog) .. ", need " .. fmt(m.MogReq) .. ". Train at your MOG STONE!")
			return
		end
		if not freeSlot(plot, player) then
			notify(player, "Your enclosure is full! Sell a monster or upgrade it (UPGRADES).")
			return
		end
		trainers[player] = nil
		startBattle(m, player)

	elseif action == "Sell" then
		if m.State ~= "Placed" or m.Owner ~= player then
			return
		end
		local amount = math.floor(m.Value * CONFIG.SELL_PERCENT)
		data.Cash = data.Cash + amount
		updateStats(player)
		effect(m.Part.Position, Color3.fromRGB(110, 255, 110), "+$" .. fmt(amount))
		destroyMonster(m)
		notify(player, "Sold " .. name .. " for $" .. fmt(amount))

	elseif action == "Grab" then
		if m.State ~= "Loose" or carriers[player] or battles[player] then
			return
		end
		if not freeSlot(plot, player) then
			notify(player, "Your enclosure is full! Make room first.")
			return
		end
		attachToCarrier(m, player)
		notify(player, "You picked up " .. name .. "! Get it home!")
	end
end

----------------------------------------------------------------------
-- THROWING
----------------------------------------------------------------------
local lastThrow = {}

local function landed(m, thrower)
	if not monsterAlive(m) or m.State ~= "Thrown" then
		return
	end
	local pos = m.Part.Position
	local plot = plotAt(pos)
	if plot and plot.Owner == thrower and thrower.Parent then
		local slot = freeSlot(plot, thrower)
		if slot then
			deliver(m, thrower, plot, slot)
			return
		end
	end
	makeLoose(m, pos)
end

throwRemote.OnServerEvent:Connect(function(player, direction)
	local m = carriers[player]
	if not m or typeof(direction) ~= "Vector3" then
		return
	end
	if lastThrow[player] and os.clock() - lastThrow[player] < 1 then
		return
	end
	lastThrow[player] = os.clock()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 0.1 or flat.Magnitude ~= flat.Magnitude then
		flat = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	end
	flat = flat.Unit

	detach(m)
	setState(m, "Thrown")
	updateLabel(m)
	local part = m.Part
	part.CFrame = CFrame.new(root.Position + Vector3.new(0, 4, 0) + flat * 3)
	part.CanCollide = true
	part.Anchored = false
	part:SetNetworkOwner(nil)
	local speed = CONFIG.THROW_POWER
	part.AssemblyLinearVelocity = flat * speed + Vector3.new(0, speed * 0.9, 0)

	task.spawn(function()
		local start = os.clock()
		while monsterAlive(m) and m.State == "Thrown" do
			task.wait(0.1)
			local t = os.clock() - start
			if part.Position.Y < -30 then
				returnToWild(m)
				return
			end
			if (t > 0.5 and part.AssemblyLinearVelocity.Magnitude < 4) or t > 5 then
				landed(m, player)
				return
			end
		end
	end)
end)

----------------------------------------------------------------------
-- HAMMER (train MOG + hit players who carry a monster)
----------------------------------------------------------------------
local lastHit = {}
local hammers = {} -- [player] = { Tool, BaseGrip }

local function knockback(root, velocity)
	local att = Instance.new("Attachment")
	att.Parent = root
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.MaxForce = 1e6
	lv.VectorVelocity = velocity
	lv.Parent = root
	Debris:AddItem(lv, 0.15)
	Debris:AddItem(att, 0.15)
end

local function swingHammer(player)
	local h = hammers[player]
	if not h or not h.Tool.Parent then
		return
	end
	h.Tool.Grip = (h.BaseGrip or CFrame.new()) * CFrame.Angles(math.rad(-75), 0, 0)
	task.delay(0.1, function()
		if h.Tool.Parent then
			h.Tool.Grip = h.BaseGrip or CFrame.new()
		end
	end)
end

local function hammerHit(player)
	if lastHit[player] and os.clock() - lastHit[player] < 0.6 then
		return
	end
	lastHit[player] = os.clock()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not isAlive(player) or battles[player] then
		return
	end
	swingHammer(player)
	for _, other in ipairs(Players:GetPlayers()) do
		local oroot = other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		local carrying = oroot and carriers[other]
		if carrying and isAlive(other) then
			local offset = oroot.Position - root.Position
			if offset.Magnitude < 10 and offset.Magnitude > 0 and root.CFrame.LookVector:Dot(offset.Unit) > 0.2 then
				local flat = Vector3.new(offset.X, 0, offset.Z)
				knockback(oroot, (flat.Magnitude > 0.1 and flat.Unit or root.CFrame.LookVector) * 55 + Vector3.new(0, 30, 0))
				effect(oroot.Position, Color3.fromRGB(255, 220, 60), "BONK!")
				makeLoose(carrying, oroot.Position)
				notify(player, "BONK! " .. other.Name .. " DROPPED it! Pick it up!")
				notify(other, "You got hit by a hammer and dropped the monster!")
			end
		end
	end
end

local function giveHammer(player)
	local data = sessions[player]
	local tool = Instance.new("Tool")
	tool.Name = "Hammer"
	tool.CanBeDropped = false
	tool.GripForward = Vector3.new(-1, 0, 0)
	tool.GripRight = Vector3.new(0, 1, 0)
	tool.GripUp = Vector3.new(0, 0, 1)
	tool.GripPos = Vector3.new(0, 0, -1.2)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.4, 3.4)
	handle.Color = Color3.fromRGB(150, 100, 60)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = tool
	local level = data and data.Hammer or 1
	local headColor = Color3.fromHSV(((level - 1) * 0.07) % 1, 0.6, 1)
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.1 + level * 0.05, 1.1 + level * 0.05, 1.8 + level * 0.06)
	head.Color = headColor
	head.Material = level >= 8 and Enum.Material.Neon or Enum.Material.Metal
	head.CanCollide = false
	head.Massless = true
	head.CFrame = handle.CFrame * CFrame.new(0, 0, 1.6) * CFrame.Angles(0, math.rad(90), 0)
	local w = Instance.new("WeldConstraint")
	w.Part0 = handle
	w.Part1 = head
	w.Parent = head
	head.Parent = tool
	tool.Activated:Connect(function()
		hammerHit(player)
	end)
	tool.Parent = player:WaitForChild("Backpack")
	hammers[player] = { Tool = tool, BaseGrip = tool.Grip }
end

-- MOG training at your stone
local function stopTraining(player, why)
	if trainers[player] then
		trainers[player] = nil
		player:SetAttribute("Training", false)
		if why then
			notify(player, why)
		end
	end
end

for _, plot in ipairs(plots) do
	plot.TrainPrompt.Triggered:Connect(function(player)
		local data = sessions[player]
		if not data or not isAlive(player) or battles[player] then
			return
		end
		if trainers[player] then
			stopTraining(player, "Training stopped.")
			return
		end
		if carriers[player] then
			notify(player, "Bring your monster home first!")
			return
		end
		trainers[player] = { Plot = plot, Next = os.clock() + 0.3 }
		player:SetAttribute("Training", true)
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		local h = hammers[player]
		if hum and h and h.Tool.Parent ~= player.Character then
			hum:EquipTool(h.Tool)
		end
		notify(player, "Training MOG! Press E again or walk away to stop.")
	end)
end

----------------------------------------------------------------------
-- STATION PROMPTS
----------------------------------------------------------------------
fusionPrompt.Triggered:Connect(function(player)
	panelRemote:FireClient(player, "Fusion")
end)

local function near(player, position, distance)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and (root.Position - position).Magnitude <= distance
end

----------------------------------------------------------------------
-- REQUESTS FROM THE CLIENT (menus + mini game result)
----------------------------------------------------------------------
local function myMonstersList(player)
	local plot = playerPlot[player]
	local list = {}
	if plot then
		for slot, m in pairs(plot.Slots) do
			if m.Owner == player and m.State == "Placed" then
				table.insert(list, {
					Slot = slot, Id = m.Id, Variant = m.Variant, Name = displayName(m.Id, m.Variant),
					Rarity = m.Def.Rarity, Income = m.Income, Value = m.Value,
				})
			end
		end
	end
	table.sort(list, function(a, b)
		return a.Income > b.Income
	end)
	return list
end

local function dailyStatus(data)
	local since = os.time() - (data.LastDaily or 0)
	return since >= 20 * 3600, math.max(0, 20 * 3600 - since)
end

local function getInfo(player)
	local data = sessions[player]
	local index = {}
	for _, def in ipairs(MONSTERS) do
		table.insert(index, {
			Id = def.Id, Name = def.Name, Rarity = def.Rarity, Found = data.Discovered[def.Id] == true,
			Odds = oddsOf(def.Id, 1), Zone = def.Rarity, Exclusive = def.Exclusive == true,
		})
	end
	local variants = {}
	for i, v in ipairs(VARIANTS) do
		variants[i] = { Name = v.Name, Mult = v.Mult, Odds = math.floor(1 / variantChance(i) + 0.5) }
	end
	local auras = {}
	for i, a in ipairs(AURAS) do
		auras[i] = { Name = a.Name, Tier = a.Tier, Mult = a.Mult, Cost = a.Cost, Color = a.Color, Owned = data.Auras[a.Name] == true }
	end
	local nextHammer = HAMMERS[data.Hammer + 1]
	local nextSwing = SWINGS[data.Swing + 1]
	local ready, wait = dailyStatus(data)
	return {
		Cash = data.Cash, Mog = playerMog(player), MogPerHit = mogPerHit(player),
		Rebirths = data.Rebirths, RebirthCost = rebirthCost(data),
		Hammer = data.Hammer, HammerPower = HAMMERS[data.Hammer].Power, MaxHammer = #HAMMERS,
		NextHammerPower = nextHammer and nextHammer.Power, NextHammerCost = nextHammer and nextHammer.Cost,
		Swing = data.Swing, SwingTime = SWINGS[data.Swing].Time, MaxSwing = #SWINGS,
		NextSwingTime = nextSwing and nextSwing.Time, NextSwingCost = nextSwing and nextSwing.Cost,
		Slots = slotLimit(player), BaseSlots = data.Slots, MaxSlots = CONFIG.MAX_SLOTS, SlotCost = slotCost(data),
		Boost = BOOST_MULTS[data.Boost + 1], NextBoost = BOOST_MULTS[data.Boost + 2],
		BoostCost = BOOST_MULTS[data.Boost + 2] and boostCost(data) or nil,
		Aura = data.Aura, Auras = auras,
		DailyReady = ready, DailyWait = wait, Streak = data.Streak,
		Index = index, Variants = variants, Monsters = myMonstersList(player),
	}
end

local function doFuse(player, slotA, slotB)
	local data = sessions[player]
	local plot = playerPlot[player]
	if type(slotA) ~= "number" or type(slotB) ~= "number" or slotA == slotB then
		return false, "Pick two different monsters"
	end
	if not near(player, fusionPos, 30) then
		return false, "Go to the Fusion Machine!"
	end
	local a, b = plot.Slots[slotA], plot.Slots[slotB]
	if not a or not b or a.Owner ~= player or b.Owner ~= player or a.State ~= "Placed" or b.State ~= "Placed" then
		return false, "Those monsters are not in your enclosure"
	end
	if a.Id ~= b.Id or a.Variant ~= b.Variant then
		return false, "You need 2 of the SAME monster with the SAME level!"
	end
	if a.Variant >= #VARIANTS then
		return false, "Rainbow Cosmic is already the highest level!"
	end
	local cost = math.floor(a.Value * 0.5)
	if data.Cash < cost then
		return false, "Fusion costs $" .. fmt(cost)
	end
	data.Cash = data.Cash - cost
	local id, variant = a.Id, a.Variant + 1
	destroyMonster(a)
	destroyMonster(b)
	local result = createMonster(id, variant)
	result.Part.CFrame = fusionCore.CFrame
	flyToSlot(result, plot, slotA, player)
	updateStats(player)
	local name = displayName(id, variant)
	effect(fusionCore.Position, VARIANTS[variant].Color or Color3.fromRGB(255, 120, 255), name .. "!")
	if variant >= 5 then
		announce(player.Name .. " fused a " .. name .. "!")
	end
	return true, "You made " .. name .. "!"
end

local function doRebirth(player)
	local data = sessions[player]
	local plot = playerPlot[player]
	local cost = rebirthCost(data)
	if data.Cash < cost then
		return false, "You need $" .. fmt(cost)
	end
	for _, m in pairs(plot.Slots) do
		if m.Owner == player then
			destroyMonster(m)
		end
	end
	data.Rebirths = data.Rebirths + 1
	data.Cash = CONFIG.START_CASH
	data.Mog = CONFIG.START_MOG
	data.Hammer = 1
	data.Swing = 1
	data.Boost = 0
	data.Slots = CONFIG.START_SLOTS
	applyMovement(player)
	updateStats(player)
	announce(player.Name .. " reached REBIRTH " .. data.Rebirths .. "!")
	if data.Rebirths == 10 then
		giveMonster(player, "Phoenixmog", 3)
		announce(player.Name .. " unlocked the exclusive GOLDEN PHOENIXMOG!")
	end
	saveData(player)
	return true, "REBIRTH " .. data.Rebirths .. "! You now get x" .. (1 + data.Rebirths) .. " MOG and money!"
end

local function buyThing(data, cost)
	if data.Cash < cost then
		return false
	end
	data.Cash = data.Cash - cost
	return true
end

requestRemote.OnServerInvoke = function(player, action, a, b)
	local data = sessions[player]
	local plot = playerPlot[player]
	if not data or not plot then
		return false, "Loading..."
	end

	if action == "GetInfo" then
		return true, getInfo(player)
	elseif action == "BattleResult" then
		return battleResult(player, a, b)
	elseif action == "Fuse" then
		return doFuse(player, a, b)
	elseif action == "Rebirth" then
		return doRebirth(player)

	elseif action == "BuyHammer" then
		local nextH = HAMMERS[data.Hammer + 1]
		if not nextH then
			return false, "Your hammer is max level!"
		end
		if not buyThing(data, nextH.Cost) then
			return false, "You need $" .. fmt(nextH.Cost)
		end
		data.Hammer = data.Hammer + 1
		updateStats(player)
		local h = hammers[player]
		if h and h.Tool.Parent then
			local wasEquipped = h.Tool.Parent == player.Character
			h.Tool:Destroy()
			giveHammer(player)
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if wasEquipped and hum then
				hum:EquipTool(hammers[player].Tool)
			end
		end
		return true, "Hammer level " .. data.Hammer .. "! +" .. fmt(nextH.Power) .. " MOG per hit"

	elseif action == "BuySwing" then
		local nextS = SWINGS[data.Swing + 1]
		if not nextS then
			return false, "Swing speed is max level!"
		end
		if not buyThing(data, nextS.Cost) then
			return false, "You need $" .. fmt(nextS.Cost)
		end
		data.Swing = data.Swing + 1
		updateStats(player)
		return true, "Faster swing! One hit every " .. nextS.Time .. " seconds"

	elseif action == "UnequipAura" then
		data.Aura = ""
		applyAura(player)
		return true, "Aura removed."

	elseif action == "BuyAura" or action == "EquipAura" then
		local aura = AURA_BY_NAME[a]
		if not aura then
			return false, "Unknown aura"
		end
		if not data.Auras[aura.Name] then
			if action == "EquipAura" then
				return false, "You don't own that aura"
			end
			if not buyThing(data, aura.Cost) then
				return false, "You need $" .. fmt(aura.Cost)
			end
			data.Auras[aura.Name] = true
		end
		data.Aura = aura.Name
		updateStats(player)
		applyAura(player)
		return true, aura.Name .. " equipped! x" .. aura.Mult .. " MOG"

	elseif action == "BuyBoost" then
		if not BOOST_MULTS[data.Boost + 2] then
			return false, "Money Boost is max level!"
		end
		local cost = boostCost(data)
		if not buyThing(data, cost) then
			return false, "You need $" .. fmt(cost)
		end
		data.Boost = data.Boost + 1
		updateStats(player)
		return true, "Money Boost is now x" .. BOOST_MULTS[data.Boost + 1] .. "!"

	elseif action == "BuySlot" then
		if data.Slots >= CONFIG.MAX_SLOTS then
			return false, "Your enclosure is max size!"
		end
		local cost = slotCost(data)
		if not buyThing(data, cost) then
			return false, "You need $" .. fmt(cost)
		end
		data.Slots = data.Slots + 1
		updateStats(player)
		return true, "Bigger enclosure! You can keep " .. slotLimit(player) .. " monsters."

	elseif action == "ClaimDaily" then
		if not dailyStatus(data) then
			return false, "Come back later!"
		end
		if os.time() - (data.LastDaily or 0) > 48 * 3600 then
			data.Streak = 0
		end
		data.Streak = data.Streak + 1
		data.LastDaily = os.time()
		local day = ((data.Streak - 1) % 7) + 1
		local reward = math.floor((300 + (player:GetAttribute("Income") or 0) * 120) * day)
		if player:GetAttribute("VIP") then
			reward = reward * 2
		end
		data.Cash = data.Cash + reward
		updateStats(player)
		local msg = "Day " .. day .. " reward: $" .. fmt(reward) .. "!"
		if day == 7 then
			local id = randomSpecies(math.random() < 0.8 and 4 or 5)
			if giveMonster(player, id, rollVariant(5)) then
				msg = msg .. " + a free " .. MONSTER_BY_ID[id].Name .. "!"
			end
		end
		return true, msg
	end
	return false, "Unknown action"
end

----------------------------------------------------------------------
-- GAME PASSES & PRODUCTS
----------------------------------------------------------------------
local PASS_ATTRIBUTES = {
	[CONFIG.DOUBLE_MONEY_PASS_ID] = "DoubleMoney",
	[CONFIG.DOUBLE_MOG_PASS_ID] = "DoubleMog",
	[CONFIG.VIP_PASS_ID] = "VIP",
	[CONFIG.EXTRA_SLOTS_PASS_ID] = "ExtraSlots",
}
PASS_ATTRIBUTES[0] = nil

local function updateNameSign(player)
	local plot = playerPlot[player]
	if plot then
		plot.NameLabel.Text = (player:GetAttribute("VIP") and "[VIP] " or "") .. player.Name .. "'s Enclosure"
	end
end

local function grantPass(player, passId)
	local attr = PASS_ATTRIBUTES[passId]
	if not attr then
		return
	end
	player:SetAttribute(attr, true)
	updateNameSign(player)
end

local function checkPasses(player)
	for passId in pairs(PASS_ATTRIBUTES) do
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		if ok and owns then
			grantPass(player, passId)
		end
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if purchased then
		grantPass(player, passId)
		notify(player, "Thanks for your purchase!")
	end
end)

local handledReceipts = {}
MarketplaceService.ProcessReceipt = function(receipt)
	if handledReceipts[receipt.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local data = player and sessions[player]
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if receipt.ProductId == CONFIG.CASH_PACK_PRODUCT_ID then
		local amount = math.max(5000, math.floor((player:GetAttribute("Income") or 0) * 600))
		data.Cash = data.Cash + amount
		notify(player, "+$" .. fmt(amount) .. "!")
	elseif receipt.ProductId == CONFIG.SERVER_LUCK_PRODUCT_ID then
		luckUntil = math.max(os.clock(), luckUntil) + 900
		announce(player.Name .. " activated 2x SERVER LUCK for everyone! Thank you!")
	else
		warn("Unknown product: " .. tostring(receipt.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	handledReceipts[receipt.PurchaseId] = true
	updateStats(player)
	saveData(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

----------------------------------------------------------------------
-- LEADERBOARD
----------------------------------------------------------------------
local nameCache = {}
local function nameOf(userId)
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and type(name) == "string" then
		nameCache[userId] = name
		return name
	end
	return "Player"
end

local function updateLeaderboard()
	local entries
	if boardStore then
		for _, player in ipairs(Players:GetPlayers()) do
			local data = sessions[player]
			if data and not data.NoSave then
				pcall(function()
					boardStore:SetAsync(tostring(player.UserId), math.floor(data.Mog))
				end)
			end
		end
		local ok, page = pcall(function()
			return boardStore:GetSortedAsync(false, 10):GetCurrentPage()
		end)
		if ok and type(page) == "table" then
			entries = {}
			for _, e in ipairs(page) do
				table.insert(entries, { Name = nameOf(tonumber(e.key) or 0), Mog = e.value })
			end
			boardTitle.Text = "TOP MOG (ALL PLAYERS)"
		end
	end
	if not entries then
		entries = {}
		for _, player in ipairs(Players:GetPlayers()) do
			local data = sessions[player]
			if data then
				table.insert(entries, { Name = player.Name, Mog = data.Mog })
			end
		end
		table.sort(entries, function(x, y)
			return x.Mog > y.Mog
		end)
		boardTitle.Text = "TOP MOG (THIS SERVER)"
	end
	for i = 1, 10 do
		local e = entries[i]
		boardRows[i].Text = e and (i .. ". " .. e.Name .. "   " .. fmt(e.Mog) .. " MOG") or ""
	end
end

----------------------------------------------------------------------
-- JOIN / LEAVE
----------------------------------------------------------------------
local function spawnCFrame(player)
	local plot = playerPlot[player]
	if plot then
		return plot.CF * CFrame.new(0, 4, -PLOT_D / 2 - 6)
	end
	return CFrame.new(-250, 6, -20)
end

local function onCharacter(player, char)
	local hum = char:WaitForChild("Humanoid")
	char:WaitForChild("HumanoidRootPart")
	task.wait()
	char:PivotTo(spawnCFrame(player))
	applyMovement(player)
	giveHammer(player)
	applyAura(player)
	hum.Died:Connect(function()
		local m = carriers[player]
		if m then
			makeLoose(m, char:GetPivot().Position)
		end
		local b = battles[player]
		if b then
			endBattle(b, player)
		end
		stopTraining(player)
	end)
end

local function onPlayerAdded(player)
	local data = loadData(player)
	if not player.Parent then
		return
	end
	if not HAMMERS[data.Hammer] then
		data.Hammer = 1
	end
	if not SWINGS[data.Swing] then
		data.Swing = 1
	end
	sessions[player] = data

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in ipairs({ "MOG", "Cash", "Rebirths" }) do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = stats
	end
	stats.Parent = player
	updateStats(player)

	local plot
	for _, p in ipairs(plots) do
		if not p.Owner then
			plot = p
			break
		end
	end
	if plot then
		plot.Owner = player
		playerPlot[player] = plot
		updateNameSign(player)
	end

	checkPasses(player)

	if plot then
		for _, saved in ipairs(data.Monsters) do
			local slot = tonumber(saved.S)
			local variant = tonumber(saved.V) or 1
			if MONSTER_BY_ID[saved.Id] and VARIANTS[variant] and slot and not plot.Slots[slot] then
				local m = createMonster(saved.Id, variant)
				place(m, plot, slot, player)
			end
		end
	end

	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end

	if not plot then
		notify(player, "All enclosures are taken, try another server!")
	elseif data.NoSave then
		notify(player, "Saving is OFF (turn on API access in Game Settings).")
	end
	task.spawn(updateLeaderboard)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	local b = battles[player]
	if b then
		endBattle(b, player)
	end
	local carried = carriers[player]
	if carried then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			makeLoose(carried, root.Position)
		else
			returnToWild(carried)
		end
	end
	local plot = playerPlot[player]
	if plot then
		for _, m in pairs(plot.Slots) do
			destroyMonster(m)
		end
		plot.Slots = {}
		plot.Owner = nil
		plot.NameLabel.Text = "Empty Enclosure"
		plot.IncomeLabel.Text = ""
		plot.StatusLabel.Text = ""
	end
	playerPlot[player] = nil
	sessions[player] = nil
	trainers[player] = nil
	hammers[player] = nil
	lastThrow[player] = nil
	lastHit[player] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveData(player)
	end
end)

task.spawn(function()
	while true do
		task.wait(120)
		for _, player in ipairs(Players:GetPlayers()) do
			saveData(player)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(60)
		updateLeaderboard()
	end
end)

----------------------------------------------------------------------
-- GAME LOOPS
----------------------------------------------------------------------
local function timeText(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- Spawning in every zone, monsters walking around, MOG training
local zoneTimers = {}
for k = 1, #ZONES do
	zoneTimers[k] = (ZONES[k].Every or 0) * 0.8
end
RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	local rush = now < rushUntil
	for k, zone in ipairs(ZONES) do
		if zone.Every then
			zoneTimers[k] = zoneTimers[k] + dt * (rush and 3 or 1)
			if zoneTimers[k] >= zone.Every then
				zoneTimers[k] = 0
				if math.random() < GIGAMOG_CHANCE * luck() and zoneCount[#ZONES] < ZONES[#ZONES].Max then
					spawnZoneMonster(#ZONES, "Gigamog")
				elseif zoneCount[k] < zone.Max then
					spawnZoneMonster(k)
				end
			end
		end
	end

	for _, m in pairs(monstersByPart) do
		if (m.State == "Lane" or m.State == "Placed") and m.Region and m.Target then
			local pos = m.Part.Position
			if m.Pause > 0 then
				m.Pause = m.Pause - dt
			else
				local flat = Vector3.new(m.Target.X - pos.X, 0, m.Target.Z - pos.Z)
				if flat.Magnitude < 1 then
					m.Target = regionPoint(m.Region, m)
					m.Pause = 1 + math.random() * 4
					m.CurSpeed = 0
				else
					-- speed up slowly, turn smoothly, take small steps
					m.CurSpeed = math.min(m.Region.Speed, (m.CurSpeed or 0) + m.Region.Speed * dt * 1.5)
					local want = flat.Unit
					local facing = m.Facing or want
					facing = facing:Lerp(want, math.min(1, dt * 3))
					if facing.Magnitude < 0.01 then
						facing = want
					end
					facing = facing.Unit
					m.Facing = facing
					local step = facing * math.min(flat.Magnitude, m.CurSpeed * dt)
					m.Walked = m.Walked + step.Magnitude
					local bob = m.Hover > 0 and math.sin(now * 2) * 0.6 or math.abs(math.sin(m.Walked * 2.2)) * 0.12
					local baseY = m.Region.GroundY + m.Foot + m.Hover
					local newPos = Vector3.new(pos.X + step.X, baseY + bob, pos.Z + step.Z)
					m.Part.CFrame = CFrame.lookAt(newPos, newPos + facing)
				end
			end
		end
	end

	for player, t in pairs(trainers) do
		local data = sessions[player]
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not data or not root or not isAlive(player) then
			stopTraining(player)
		elseif (root.Position - t.Plot.Stone.Position).Magnitude > 16 then
			stopTraining(player, "You walked away - training stopped.")
		elseif now >= t.Next then
			t.Next = now + SWINGS[data.Swing].Time
			local gain = mogPerHit(player)
			data.Mog = data.Mog + gain
			updateStats(player)
			swingHammer(player)
			effectRemote:FireClient(player, t.Plot.Stone.Position + Vector3.new(0, 2, 0), Color3.fromRGB(255, 120, 200), "+" .. fmt(gain) .. " MOG")
		end
	end
end)

-- Every second: money, signs, events
local nextRush = os.clock() + CONFIG.FIRST_RUSH
task.spawn(function()
	while true do
		task.wait(1)
		local now = os.clock()

		for _, plot in ipairs(plots) do
			local owner = plot.Owner
			local data = owner and sessions[owner]
			if data then
				local income = 0
				for _, m in pairs(plot.Slots) do
					if m.State == "Placed" and m.Owner == owner then
						income = income + m.Income
					end
				end
				income = income * moneyMultiplier(owner)
				data.Cash = data.Cash + income
				owner:SetAttribute("Income", income)
				updateStats(owner)
				plot.IncomeLabel.Text = "$" .. fmt(income) .. "/s  |  " .. countMonsters(plot) .. "/" .. slotLimit(owner) .. " monsters"
				plot.StatusLabel.Text = fmt(data.Mog) .. " MOG" .. (data.Rebirths > 0 and ("  |  Rebirth " .. data.Rebirths) or "")
			end
		end

		if now >= nextRush then
			rushUntil = now + CONFIG.RUSH_TIME
			nextRush = now + CONFIG.RUSH_EVERY
			announce("LUCKY RUSH! 3x luck and 3x more monsters in all zones for 60 seconds!")
		end
		if now < rushUntil then
			rushLabel.Text = "LUCKY RUSH! " .. timeText(rushUntil - now)
			ReplicatedStorage:SetAttribute("RushIn", -math.ceil(rushUntil - now))
		else
			rushLabel.Text = "Lucky Rush in " .. timeText(nextRush - now)
			ReplicatedStorage:SetAttribute("RushIn", math.ceil(nextRush - now))
		end
		ReplicatedStorage:SetAttribute("LuckLeft", math.max(0, math.ceil(luckUntil - now)))
	end
end)

-- Fast loop: deliveries, zone gates, battle timeouts
task.spawn(function()
	while true do
		task.wait(0.2)
		local now = os.clock()

		for player, m in pairs(carriers) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local plot = playerPlot[player]
			if root and plot and plotAt(root.Position) == plot then
				local slot = freeSlot(plot, player)
				if slot then
					deliver(m, player, plot, slot)
				end
			end
		end

		for player, m in pairs(battles) do
			if not player.Parent or not isAlive(player) or now - (m.BattleStart or now) > CONFIG.BATTLE_MAX_TIME then
				endBattle(m, player)
			end
		end

		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and isAlive(player) then
				local here = zoneAtX(root.Position.X)
				local mog = playerMog(player)
				for k = 2, here do
					if mog < zoneInfo[k].Need then
						local z = math.clamp(root.Position.Z, -ROAD_W / 2 + 4, ROAD_W / 2 - 4)
						local back = Vector3.new(zoneInfo[k].X0 - 6, root.Position.Y + 1, z)
						char:PivotTo(CFrame.lookAt(back, back - Vector3.new(1, 0, 0)))
						notify(player, "You need " .. fmt(zoneInfo[k].Need) .. " MOG for ZONE " .. k .. "! Train at your MOG STONE.")
						break
					end
				end
			end
		end
	end
end)

print("MOG MONSTERS server v6 started OK!")
