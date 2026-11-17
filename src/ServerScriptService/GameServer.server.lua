--[[
	⚡ POWER EMPIRE - Steal, Build & Become OP ⚡
	=============================================
	Put this as a *Script* in ServerScriptService.

	This script builds the whole map and runs the game:
	  * Your own base with pedestals. Powers on them make money every second.
	  * POWER MARKET with limited stock that restocks every 90 seconds.
	  * STEAL powers from other bases. Run home or THROW them (F) into your base.
	  * Protect your base: Lock (laser forcefield), Turret, Alarm and VAULT
	    (vault powers can never be stolen and survive rebirth).
	  * POWER FUSION: combine two powers into a new one. Secret recipes!
	  * MUTATIONS: Neon, Golden, Corrupted, Rainbow, Galaxy.
	  * REBIRTH for permanent bonuses.
	  * BATTLE ARENA: your best power decides your attack.
	  * SECRET PORTAL event, DAILY REWARDS, SERVER LUCK.

	>>> ONLY CHANGE THINGS IN THE "CONFIG" SECTION BELOW <<<
]]

----------------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------------
local CONFIG = {
	START_CASH = 150,
	START_SLOTS = 6,          -- pedestals you start with
	MAX_SLOTS = 12,           -- pedestals you can buy with cash
	SLOT_BASE_COST = 1000,    -- price of slot 7 (then x3 every slot)
	RESTOCK_TIME = 90,        -- seconds between market restocks
	LOCK_TIME = 45,
	LOCK_COOLDOWN = 45,
	LOOSE_TIME = 15,          -- seconds a dropped power lies on the ground
	RESPAWN_TIME = 3,
	THROW_POWER = 75,
	SELL_PERCENT = 0.5,
	FUSE_COST_PERCENT = 0.1,  -- fusion costs 10% of the two powers' price
	REBIRTH_BASE_COST = 500000,
	REBIRTH_COST_MULT = 3,
	TURRET_COSTS = { 5000, 75000, 1000000 },
	TURRET_COOLDOWN = { 4, 2.5, 1.5 },
	PORTAL_EVERY = 600,       -- secret portal opens every 10 minutes
	PORTAL_OPEN_TIME = 60,
	FIRST_PORTAL = 300,       -- first portal 5 minutes after the server starts

	-- Paste your IDs here after you create them on create.roblox.com
	-- (0 = not set up yet, the button just says "coming soon")
	DOUBLE_MONEY_PASS_ID = 0, -- 2x money
	VIP_PASS_ID = 0,          -- VIP tag, +20% money, 2x daily reward
	EXTRA_SLOTS_PASS_ID = 0,  -- +3 pedestals
	FAST_STEAL_PASS_ID = 0,   -- steal 2x faster, no slow-down when carrying
	EXTRA_VAULT_PASS_ID = 0,  -- +1 vault slot
	SERVER_LUCK_PRODUCT_ID = 0, -- 2x luck for EVERYONE for 15 minutes
	SUPER_LOCK_PRODUCT_ID = 0,  -- lock your base for 3 minutes
	CASH_PACK_PRODUCT_ID = 0,   -- 10 minutes of income (min 10K)
}

local RARITIES = {
	{ Name = "Common",    Color = Color3.fromRGB(200, 200, 200) },
	{ Name = "Uncommon",  Color = Color3.fromRGB(90, 220, 90) },
	{ Name = "Rare",      Color = Color3.fromRGB(70, 150, 255) },
	{ Name = "Epic",      Color = Color3.fromRGB(180, 90, 255) },
	{ Name = "Legendary", Color = Color3.fromRGB(255, 200, 40) },
	{ Name = "Mythic",    Color = Color3.fromRGB(255, 60, 120) },
	{ Name = "Secret",    Color = Color3.fromRGB(20, 20, 20) },
}

-- Element = which attack you get in battle when this is your best power
local POWERS = {
	-- Market powers
	{ Id = "Fire",      Name = "Fire",      Rarity = 1, Price = 100,     Income = 5,     Color = Color3.fromRGB(255, 110, 30),  Element = "Fire",      Market = true },
	{ Id = "Earth",     Name = "Earth",     Rarity = 1, Price = 180,     Income = 8,     Color = Color3.fromRGB(140, 95, 60),   Element = "Gravity",   Market = true },
	{ Id = "Ice",       Name = "Ice",       Rarity = 2, Price = 600,     Income = 15,    Color = Color3.fromRGB(150, 230, 255), Element = "Ice",       Market = true },
	{ Id = "Wind",      Name = "Wind",      Rarity = 2, Price = 900,     Income = 22,    Color = Color3.fromRGB(200, 255, 220), Element = "Lightning", Market = true },
	{ Id = "Lightning", Name = "Lightning", Rarity = 3, Price = 3000,    Income = 50,    Color = Color3.fromRGB(255, 245, 70),  Element = "Lightning", Market = true },
	{ Id = "Poison",    Name = "Poison",    Rarity = 3, Price = 4500,    Income = 70,    Color = Color3.fromRGB(130, 255, 60),  Element = "Shadow",    Market = true },
	{ Id = "Shadow",    Name = "Shadow",    Rarity = 4, Price = 18000,   Income = 200,   Color = Color3.fromRGB(60, 30, 90),    Element = "Shadow",    Market = true },
	{ Id = "Gravity",   Name = "Gravity",   Rarity = 4, Price = 28000,   Income = 300,   Color = Color3.fromRGB(120, 80, 255),  Element = "Gravity",   Market = true },
	{ Id = "Dragon",    Name = "Dragon",    Rarity = 5, Price = 120000,  Income = 1000,  Color = Color3.fromRGB(220, 40, 40),   Element = "Dragon",    Market = true },
	{ Id = "Void",      Name = "Void",      Rarity = 6, Price = 700000,  Income = 5000,  Color = Color3.fromRGB(10, 0, 30),     Element = "Gravity",   Market = true },
	{ Id = "Celestial", Name = "Celestial", Rarity = 7, Price = 5000000, Income = 25000, Color = Color3.fromRGB(255, 250, 220), Element = "Dragon",    Market = true },
	{ Id = "Sand",      Name = "Sand",      Rarity = 1, Price = 140,     Income = 6,     Color = Color3.fromRGB(230, 200, 130), Element = "Gravity",   Market = true },
	{ Id = "Water",     Name = "Water",     Rarity = 2, Price = 750,     Income = 18,    Color = Color3.fromRGB(40, 120, 255),  Element = "Ice",       Market = true },
	{ Id = "Crystal",   Name = "Crystal",   Rarity = 3, Price = 3800,    Income = 60,    Color = Color3.fromRGB(160, 255, 255), Element = "Ice",       Market = true },
	{ Id = "Light",     Name = "Light",     Rarity = 4, Price = 22000,   Income = 250,   Color = Color3.fromRGB(255, 255, 200), Element = "Lightning", Market = true },
	{ Id = "Time",      Name = "Time",      Rarity = 5, Price = 150000,  Income = 1200,  Color = Color3.fromRGB(200, 170, 90),  Element = "Shadow",    Market = true },

	-- Fusion-only powers
	{ Id = "Magma",          Name = "Magma",           Rarity = 2, Price = 900,      Income = 30,     Color = Color3.fromRGB(255, 70, 0),    Element = "Fire" },
	{ Id = "Steam",          Name = "Steam",           Rarity = 2, Price = 1000,     Income = 35,     Color = Color3.fromRGB(230, 230, 230), Element = "Ice" },
	{ Id = "Blizzard",       Name = "Blizzard",        Rarity = 3, Price = 4000,     Income = 70,     Color = Color3.fromRGB(220, 250, 255), Element = "Ice" },
	{ Id = "Plasma",         Name = "Plasma",          Rarity = 3, Price = 7000,     Income = 110,    Color = Color3.fromRGB(255, 80, 220),  Element = "Lightning" },
	{ Id = "Storm",          Name = "Storm",           Rarity = 3, Price = 9000,     Income = 150,    Color = Color3.fromRGB(90, 110, 160),  Element = "Lightning" },
	{ Id = "FrozenDarkness", Name = "Frozen Darkness", Rarity = 4, Price = 45000,    Income = 500,    Color = Color3.fromRGB(40, 60, 120),   Element = "Ice" },
	{ Id = "ToxicShadow",    Name = "Toxic Shadow",    Rarity = 4, Price = 55000,    Income = 600,    Color = Color3.fromRGB(60, 120, 30),   Element = "Shadow" },
	{ Id = "SolarDragon",    Name = "Solar Dragon",    Rarity = 5, Price = 280000,   Income = 2300,   Color = Color3.fromRGB(255, 170, 0),   Element = "Dragon" },
	{ Id = "ThunderDragon",  Name = "Thunder Dragon",  Rarity = 5, Price = 300000,   Income = 2500,   Color = Color3.fromRGB(255, 230, 0),   Element = "Dragon" },
	{ Id = "Phoenix",        Name = "Phoenix",         Rarity = 6, Price = 1000000,  Income = 8000,   Color = Color3.fromRGB(255, 120, 40),  Element = "Fire" },
	{ Id = "BlackHole",      Name = "Black Hole",      Rarity = 6, Price = 1600000,  Income = 12000,  Color = Color3.fromRGB(5, 5, 5),       Element = "Gravity" },
	{ Id = "Eclipse",        Name = "Eclipse",         Rarity = 7, Price = 10000000, Income = 60000,  Color = Color3.fromRGB(255, 140, 0),   Element = "Shadow" },
	{ Id = "Glass",          Name = "Glass",           Rarity = 2, Price = 800,      Income = 28,     Color = Color3.fromRGB(200, 240, 255), Element = "Ice" },
	{ Id = "Tsunami",        Name = "Tsunami",         Rarity = 3, Price = 4500,     Income = 80,     Color = Color3.fromRGB(0, 90, 200),    Element = "Ice" },
	{ Id = "Prism",          Name = "Prism",           Rarity = 4, Price = 60000,    Income = 700,    Color = Color3.fromRGB(255, 150, 255), Element = "Lightning" },
	{ Id = "ChronoDragon",   Name = "Chrono Dragon",   Rarity = 6, Price = 700000,   Income = 5000,   Color = Color3.fromRGB(190, 140, 40),  Element = "Dragon" },
	{ Id = "Supernova",      Name = "Supernova",       Rarity = 7, Price = 12000000, Income = 70000,  Color = Color3.fromRGB(255, 255, 255), Element = "Dragon" },
}

-- Fusion recipes (order doesn't matter). Players have to discover them!
local RECIPES = {
	{ "Fire", "Earth", "Magma" },
	{ "Fire", "Ice", "Steam" },
	{ "Ice", "Wind", "Blizzard" },
	{ "Fire", "Lightning", "Plasma" },
	{ "Wind", "Lightning", "Storm" },
	{ "Ice", "Shadow", "FrozenDarkness" },
	{ "Poison", "Shadow", "ToxicShadow" },
	{ "Dragon", "Fire", "SolarDragon" },
	{ "Dragon", "Lightning", "ThunderDragon" },
	{ "Gravity", "Void", "BlackHole" },
	{ "Celestial", "Shadow", "Eclipse" },
	{ "Sand", "Fire", "Glass" },
	{ "Water", "Wind", "Tsunami" },
	{ "Crystal", "Light", "Prism" },
	{ "Time", "Dragon", "ChronoDragon" },
	{ "Light", "Celestial", "Supernova" },
}

-- Chance is in percent
local MUTATIONS = {
	{ Name = "Galaxy",    Mult = 10,  Chance = 0.1, Color = Color3.fromRGB(70, 20, 140) },
	{ Name = "Rainbow",   Mult = 5,   Chance = 0.4 },
	{ Name = "Corrupted", Mult = 3,   Chance = 1,   Color = Color3.fromRGB(110, 0, 0) },
	{ Name = "Golden",    Mult = 2,   Chance = 2.5, Color = Color3.fromRGB(255, 200, 40) },
	{ Name = "Neon",      Mult = 1.5, Chance = 4 },
}

-- Battle attacks
local ELEMENTS = {
	Punch     = { Damage = 10, Cooldown = 1.0, Range = 12, Width = 0.4, Color = Color3.fromRGB(255, 255, 255) },
	Fire      = { Damage = 25, Cooldown = 0.8, Range = 80, Width = 0.8, Color = Color3.fromRGB(255, 110, 30) },
	Ice       = { Damage = 15, Cooldown = 1.5, Range = 80, Width = 0.6, Color = Color3.fromRGB(150, 230, 255), Freeze = 1.3 },
	Lightning = { Damage = 12, Cooldown = 0.35, Range = 90, Width = 0.3, Color = Color3.fromRGB(255, 245, 70) },
	Shadow    = { Damage = 20, Cooldown = 2.0, Range = 70, Width = 0.6, Color = Color3.fromRGB(80, 40, 120), Invisible = 3 },
	Gravity   = { Damage = 15, Cooldown = 2.0, Range = 70, Width = 0.7, Color = Color3.fromRGB(120, 80, 255), Pull = true },
	Dragon    = { Damage = 55, Cooldown = 3.0, Range = 90, Width = 2.0, Color = Color3.fromRGB(220, 40, 40) },
}

----------------------------------------------------------------------
-- SERVICES, REMOTES, HELPERS
----------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

Players.RespawnTime = CONFIG.RESPAWN_TIME
Lighting.ClockTime = 14.5
local function addLightingEffect(className, props)
	if Lighting:FindFirstChildOfClass(className) then
		return
	end
	local e = Instance.new(className)
	for k, v in pairs(props) do
		e[k] = v
	end
	e.Parent = Lighting
end
addLightingEffect("Atmosphere", { Density = 0.25, Haze = 1, Color = Color3.fromRGB(200, 215, 255), Decay = Color3.fromRGB(120, 140, 200) })
addLightingEffect("BloomEffect", { Intensity = 0.7, Size = 24, Threshold = 1.5 })
addLightingEffect("ColorCorrectionEffect", { Saturation = 0.15, Contrast = 0.05 })
addLightingEffect("SunRaysEffect", { Intensity = 0.06, Spread = 0.8 })

for key, value in pairs({
	DoubleMoneyPassId = CONFIG.DOUBLE_MONEY_PASS_ID,
	VipPassId = CONFIG.VIP_PASS_ID,
	ExtraSlotsPassId = CONFIG.EXTRA_SLOTS_PASS_ID,
	FastStealPassId = CONFIG.FAST_STEAL_PASS_ID,
	ExtraVaultPassId = CONFIG.EXTRA_VAULT_PASS_ID,
	ServerLuckProductId = CONFIG.SERVER_LUCK_PRODUCT_ID,
	SuperLockProductId = CONFIG.SUPER_LOCK_PRODUCT_ID,
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
local alarmRemote = remote("RemoteEvent", "Alarm")
local panelRemote = remote("RemoteEvent", "OpenPanel")
local throwRemote = remote("RemoteEvent", "Throw")
local effectRemote = remote("RemoteEvent", "Effect")
local blastRemote = remote("RemoteEvent", "Blast")
local requestRemote = remote("RemoteFunction", "Request")
remotes.Parent = ReplicatedStorage

local function notify(player, text)
	notifyRemote:FireClient(player, text)
end
local function announce(text)
	announceRemote:FireAllClients(text)
end
-- burst of particles + floating text, shown on every screen
local function effect(position, color, text)
	effectRemote:FireAllClients(position, color, text)
end

local function fmt(n)
	n = math.floor(n)
	if n >= 1e12 then
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

local POWER_BY_ID = {}
for _, def in ipairs(POWERS) do
	POWER_BY_ID[def.Id] = def
end
local MUT_BY_NAME = {}
for _, m in ipairs(MUTATIONS) do
	MUT_BY_NAME[m.Name] = m
end

local function recipeKey(a, b)
	if a > b then
		a, b = b, a
	end
	return a .. "+" .. b
end
local RECIPE_BY_KEY = {}
for _, r in ipairs(RECIPES) do
	RECIPE_BY_KEY[recipeKey(r[1], r[2])] = r[3]
end

local function displayName(id, mut)
	local def = POWER_BY_ID[id]
	if mut then
		return mut .. " " .. def.Name
	end
	return def.Name
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
local powerFolder = Instance.new("Folder")
powerFolder.Name = "Powers"
powerFolder.Parent = workspace

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

local function stationSign(position, text, color)
	local p = block(Vector3.new(1, 1, 1), CFrame.new(position), color)
	p.Transparency = 1
	p.CanCollide = false
	local _, labels = billboard(p, 300, 80, Vector3.new(), 2)
	labels[1].Text = text
	labels[1].TextColor3 = color
	return labels[2]
end

-- Ground + central plaza
block(Vector3.new(560, 2, 560), CFrame.new(0, -1, 0), Color3.fromRGB(85, 165, 75), Enum.Material.Grass)
local plaza = block(Vector3.new(2, 220, 220), CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(170, 170, 180), Enum.Material.Slate)
plaza.Shape = Enum.PartType.Cylinder

-- POWER MARKET
local marketPodiums = {}
for i = 1, 10 do
	local x = -45 + (i - 1) * 10
	local podium = block(Vector3.new(6, 3, 6), CFrame.new(x, 1.5, -62), Color3.fromRGB(60, 60, 75), Enum.Material.Marble)
	podium.Name = "MarketPodium"
	marketPodiums[i] = podium
end
block(Vector3.new(104, 1, 14), CFrame.new(0, 14, -64), Color3.fromRGB(255, 200, 40), Enum.Material.Neon)
local marketTimerLabel = stationSign(Vector3.new(0, 20, -64), "POWER MARKET", Color3.fromRGB(255, 200, 40))

-- FUSION STATION
local fusionPos = Vector3.new(-70, 0, 0)
local fusionBase = block(Vector3.new(2, 16, 16), CFrame.new(fusionPos + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(50, 30, 80), Enum.Material.Metal)
fusionBase.Shape = Enum.PartType.Cylinder
local fusionCore = block(Vector3.new(6, 6, 6), CFrame.new(fusionPos + Vector3.new(0, 7, 0)), Color3.fromRGB(200, 80, 255), Enum.Material.ForceField)
fusionCore.Shape = Enum.PartType.Ball
fusionCore.CanCollide = false
local fusionPrompt = Instance.new("ProximityPrompt")
fusionPrompt.ActionText = "Fuse Powers"
fusionPrompt.ObjectText = "Fusion Station"
fusionPrompt.MaxActivationDistance = 16
fusionPrompt.RequiresLineOfSight = false
fusionPrompt.Parent = fusionCore
stationSign(fusionPos + Vector3.new(0, 14, 0), "POWER FUSION", Color3.fromRGB(200, 80, 255)).Text = "Combine 2 powers!"

-- BATTLE ARENA
local ARENA_CENTER = Vector3.new(0, 0, 62)
local ARENA_RADIUS = 28
local arenaFloor = block(Vector3.new(1.5, ARENA_RADIUS * 2, ARENA_RADIUS * 2), CFrame.new(ARENA_CENTER + Vector3.new(0, 0.75, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 40, 40), Enum.Material.Slate)
arenaFloor.Shape = Enum.PartType.Cylinder
for i = 0, 11 do
	if i % 3 ~= 0 then -- leave openings
		local a = math.rad(i * 30)
		local pos = ARENA_CENTER + Vector3.new(math.sin(a) * ARENA_RADIUS, 2.5, math.cos(a) * ARENA_RADIUS)
		block(Vector3.new(14, 3, 1), CFrame.lookAt(pos, ARENA_CENTER + Vector3.new(0, 2.5, 0)), Color3.fromRGB(90, 20, 20), Enum.Material.Brick)
	end
end
stationSign(ARENA_CENTER + Vector3.new(0, 16, 0), "BATTLE ARENA", Color3.fromRGB(255, 80, 80)).Text = "Equip Power Blast and fight!"

local function inArena(position)
	local flat = Vector3.new(position.X - ARENA_CENTER.X, 0, position.Z - ARENA_CENTER.Z)
	return flat.Magnitude <= ARENA_RADIUS and position.Y < 30
end

-- SECRET PORTAL
local portalPos = Vector3.new(0, 0, 0)
local portalFrame = block(Vector3.new(14, 16, 2), CFrame.new(portalPos + Vector3.new(0, 8, 0)), Color3.fromRGB(30, 10, 50), Enum.Material.Basalt)
portalFrame.CanCollide = false
portalFrame.Transparency = 0.2
local portal = block(Vector3.new(1, 12, 12), CFrame.new(portalPos + Vector3.new(0, 8, 0)) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(170, 60, 255), Enum.Material.Neon)
portal.Shape = Enum.PartType.Cylinder
portal.CanCollide = false
portal.Transparency = 1
local portalLabel = stationSign(portalPos + Vector3.new(0, 19, 0), "SECRET PORTAL", Color3.fromRGB(170, 60, 255))

-- BASES (in a circle around the plaza)
local PLOT_W, PLOT_D = 72, 64
local BASE_RADIUS = 175
local PLOT_COLORS = {
	Color3.fromRGB(255, 120, 120), Color3.fromRGB(120, 180, 255), Color3.fromRGB(140, 230, 140), Color3.fromRGB(255, 210, 110),
	Color3.fromRGB(210, 140, 255), Color3.fromRGB(120, 230, 230), Color3.fromRGB(255, 160, 210), Color3.fromRGB(220, 220, 220),
}
local NORMAL_PEDESTALS = 15 -- 12 buyable + 3 from the Extra Slots pass
local VAULT_PEDESTALS = 4
local VAULT_OFFSET = 100    -- vault slots are numbered 101, 102, ...

local plots = {}
local playerPlot = {}

local function buildPlot(index)
	local angle = math.rad((index - 1) * 45)
	local center = Vector3.new(math.sin(angle) * BASE_RADIUS, 0, math.cos(angle) * BASE_RADIUS)
	local cf = CFrame.lookAt(center, Vector3.new(0, 0, 0)) -- -Z points at the plaza
	local color = PLOT_COLORS[index]
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. index
	folder.Parent = map

	block(Vector3.new(PLOT_W, 1, PLOT_D), cf * CFrame.new(0, 0.5, 0), color:Lerp(Color3.new(1, 1, 1), 0.45), nil, folder)
	local wallColor = color:Lerp(Color3.new(0, 0, 0), 0.25)
	block(Vector3.new(PLOT_W, 8, 1), cf * CFrame.new(0, 5, PLOT_D / 2 - 0.5), wallColor, nil, folder)
	block(Vector3.new(1, 8, PLOT_D), cf * CFrame.new(PLOT_W / 2 - 0.5, 5, 0), wallColor, nil, folder)
	block(Vector3.new(1, 8, PLOT_D), cf * CFrame.new(-PLOT_W / 2 + 0.5, 5, 0), wallColor, nil, folder)
	local doorW = 16
	local sideW = (PLOT_W - doorW) / 2
	for _, sx in ipairs({ -1, 1 }) do
		block(Vector3.new(sideW, 8, 1), cf * CFrame.new(sx * (doorW / 2 + sideW / 2), 5, -PLOT_D / 2 + 0.5), wallColor, nil, folder)
	end

	local laser = block(Vector3.new(doorW, 8, 0.5), cf * CFrame.new(0, 5, -PLOT_D / 2 + 0.5), Color3.fromRGB(255, 30, 30), Enum.Material.Neon, folder)
	laser.CanCollide = false
	laser.Transparency = 1

	local pedestals = {}
	for i = 1, NORMAL_PEDESTALS do
		local row = (i - 1) // 5
		local col = (i - 1) % 5
		local ped = block(Vector3.new(5, 2, 5), cf * CFrame.new(-24 + col * 12, 2, -12 + row * 12), Color3.fromRGB(235, 235, 240), Enum.Material.Marble, folder)
		ped.Name = "Pedestal"
		pedestals[i] = ped
	end
	-- Vault: raised platform at the back
	block(Vector3.new(PLOT_W - 4, 2, 10), cf * CFrame.new(0, 2, 25), Color3.fromRGB(40, 60, 110), Enum.Material.DiamondPlate, folder)
	for i = 1, VAULT_PEDESTALS do
		local ped = block(Vector3.new(5, 2, 5), cf * CFrame.new(-24 + (i - 1) * 16, 4, 25), Color3.fromRGB(80, 160, 255), Enum.Material.Glass, folder)
		ped.Name = "VaultPedestal"
		pedestals[VAULT_OFFSET + i] = ped
		local dome = block(Vector3.new(7, 7, 7), ped.CFrame * CFrame.new(0, 3, 0), Color3.fromRGB(80, 160, 255), Enum.Material.ForceField, folder)
		dome.Shape = Enum.PartType.Ball
		dome.CanCollide = false
		dome.CanQuery = false
		dome.CanTouch = false
	end
	local vaultSign = block(Vector3.new(20, 3, 0.5), cf * CFrame.new(0, 9, PLOT_D / 2 - 1.5), Color3.fromRGB(40, 60, 110), nil, folder)
	surfaceText(vaultSign, "VAULT (can't be stolen)", Enum.NormalId.Front)

	local lockPad = block(Vector3.new(6, 0.4, 6), cf * CFrame.new(-28, 1.2, -24), Color3.fromRGB(255, 60, 60), Enum.Material.Neon, folder)
	surfaceText(lockPad, "LOCK")

	-- Turret tower (front right corner)
	block(Vector3.new(4, 10, 4), cf * CFrame.new(31, 5, -27), Color3.fromRGB(70, 70, 80), Enum.Material.Metal, folder)
	local turretHead = block(Vector3.new(3, 3, 3), cf * CFrame.new(31, 11.5, -27), Color3.fromRGB(40, 40, 40), Enum.Material.Metal, folder)
	turretHead.Shape = Enum.PartType.Ball

	local signPart = block(Vector3.new(1, 1, 1), cf * CFrame.new(0, 13, -PLOT_D / 2), color, nil, folder)
	signPart.Transparency = 1
	signPart.CanCollide = false
	local _, labels = billboard(signPart, 300, 90, Vector3.new(), 3)
	labels[1].TextColor3 = color
	labels[1].Text = "Empty Base"
	local alarmLight = Instance.new("PointLight")
	alarmLight.Color = Color3.fromRGB(255, 0, 0)
	alarmLight.Range = 60
	alarmLight.Brightness = 5
	alarmLight.Enabled = false
	alarmLight.Parent = signPart

	local plot = {
		Index = index, CF = cf, Owner = nil, Pedestals = pedestals, Slots = {},
		Laser = laser, LockPad = lockPad, TurretHead = turretHead, AlarmLight = alarmLight,
		NameLabel = labels[1], IncomeLabel = labels[2], StatusLabel = labels[3],
		LockUntil = 0, LockCooldownUntil = 0, AlarmUntil = 0, TurretNext = 0,
	}
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

-- DECORATIONS: paths, lamps and trees
do
	local deco = Instance.new("Folder")
	deco.Name = "Decorations"
	deco.Parent = map
	local PLAZA_R = 110
	local pathDirs = {}

	for _, plot in ipairs(plots) do
		local door = (plot.CF * CFrame.new(0, 0, -PLOT_D / 2)).Position
		local d = Vector3.new(door.X, 0, door.Z).Unit
		table.insert(pathDirs, d)
		local inner, outer = PLAZA_R - 4, door.Magnitude
		local center = d * ((inner + outer) / 2) + Vector3.new(0, 0.1, 0)
		local path = block(Vector3.new(16, 0.2, outer - inner), CFrame.lookAt(center, center + d), Color3.fromRGB(150, 140, 125), Enum.Material.Cobblestone, deco)
		path.Name = "Path"
		for _, side in ipairs({ -1, 1 }) do
			local edge = block(Vector3.new(0.6, 0.6, outer - inner), CFrame.lookAt(center, center + d) * CFrame.new(side * 8.3, 0.2, 0), Color3.fromRGB(255, 200, 60), Enum.Material.Neon, deco)
			edge.CanCollide = false
		end
	end

	-- lamp posts around the plaza, between the paths
	for i = 0, 7 do
		local a = math.rad(22.5 + i * 45)
		local pos = Vector3.new(math.sin(a) * (PLAZA_R - 3), 0, math.cos(a) * (PLAZA_R - 3))
		block(Vector3.new(0.8, 12, 0.8), CFrame.new(pos + Vector3.new(0, 6, 0)), Color3.fromRGB(40, 40, 50), Enum.Material.Metal, deco)
		local bulb = block(Vector3.new(2.2, 2.2, 2.2), CFrame.new(pos + Vector3.new(0, 12.6, 0)), Color3.fromRGB(255, 220, 150), Enum.Material.Neon, deco)
		bulb.Shape = Enum.PartType.Ball
		bulb.CanCollide = false
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 210, 140)
		light.Range = 28
		light.Brightness = 1.5
		light.Parent = bulb
	end

	-- trees out on the grass (same layout every time)
	local rng = Random.new(42)
	local placed = 0
	for _ = 1, 400 do
		if placed >= 70 then
			break
		end
		local pos = Vector3.new(rng:NextNumber(-265, 265), 0, rng:NextNumber(-265, 265))
		local r = pos.Magnitude
		local ok = r > PLAZA_R + 8
		for _, plot in ipairs(plots) do
			if (plot.CF.Position - pos).Magnitude < 58 then
				ok = false
			end
		end
		if ok and r < 160 then
			for _, d in ipairs(pathDirs) do
				local along = pos:Dot(d)
				local off = (pos - d * along).Magnitude
				if along > 0 and off < 14 then
					ok = false
				end
			end
		end
		if ok then
			placed = placed + 1
			local h = rng:NextNumber(7, 13)
			local trunk = block(Vector3.new(h, 1.8, 1.8), CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 75, 45), Enum.Material.Wood, deco)
			trunk.Shape = Enum.PartType.Cylinder
			local size = rng:NextNumber(8, 13)
			local leaves = block(Vector3.new(size, size, size), CFrame.new(pos + Vector3.new(0, h + size * 0.3, 0)), Color3.fromRGB(rng:NextInteger(50, 90), rng:NextInteger(140, 190), rng:NextInteger(50, 80)), Enum.Material.Grass, deco)
			leaves.Shape = Enum.PartType.Ball
		end
	end
end

----------------------------------------------------------------------
-- PLAYER DATA
----------------------------------------------------------------------
-- In Studio (or before the game is published) DataStores may not work.
-- Then the game still runs, it just doesn't save.
local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("PowerEmpire_v1")
	end)
	if ok then
		store = result
	else
		warn("Saving is off: " .. tostring(result))
	end
end
local sessions = {}

local function newData()
	return {
		Cash = CONFIG.START_CASH, Steals = 0, Rebirths = 0, Slots = CONFIG.START_SLOTS,
		Turret = 0, Powers = {}, Discovered = {}, LastDaily = 0, Streak = 0,
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
	local powers = {}
	if plot then
		for slot, power in pairs(plot.Slots) do
			if power.Owner == player then
				table.insert(powers, { Id = power.Id, M = power.Mut, S = slot })
			end
		end
	end
	local toSave = {}
	for k, v in pairs(data) do
		toSave[k] = v
	end
	toSave.Powers = powers
	toSave.NoSave = nil
	local ok, err = pcall(function()
		store:SetAsync("player_" .. player.UserId, toSave)
	end)
	if not ok then
		warn("Save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

local function updateStats(player)
	local data = sessions[player]
	local stats = player:FindFirstChild("leaderstats")
	if data and stats then
		stats.Cash.Value = math.floor(data.Cash)
		stats.Rebirths.Value = data.Rebirths
		stats.Steals.Value = data.Steals
	end
end

local function normalLimit(player)
	local data = sessions[player]
	local n = data and data.Slots or CONFIG.START_SLOTS
	if player:GetAttribute("ExtraSlots") then
		n = n + 3
	end
	return math.min(n, NORMAL_PEDESTALS)
end

local function vaultLimit(player)
	local data = sessions[player]
	local r = data and data.Rebirths or 0
	local n = 1
	if r >= 2 then
		n = n + 1
	end
	if r >= 5 then
		n = n + 1
	end
	if player:GetAttribute("ExtraVault") then
		n = n + 1
	end
	return math.min(n, VAULT_PEDESTALS)
end

local function incomeMultiplier(player)
	local data = sessions[player]
	local m = 1 + (data and data.Rebirths or 0)
	if player:GetAttribute("DoubleMoney") then
		m = m * 2
	end
	if player:GetAttribute("VIP") then
		m = m * 1.2
	end
	return m
end

local function rebirthCost(data)
	return CONFIG.REBIRTH_BASE_COST * CONFIG.REBIRTH_COST_MULT ^ data.Rebirths
end

local function slotCost(data)
	return CONFIG.SLOT_BASE_COST * 3 ^ (data.Slots - CONFIG.START_SLOTS)
end

----------------------------------------------------------------------
-- LUCK & RANDOM
----------------------------------------------------------------------
local luckUntil = 0
local function luck()
	return os.clock() < luckUntil and 2 or 1
end

local function rollMutation(extraLuck)
	local l = luck() * (extraLuck or 1)
	for _, m in ipairs(MUTATIONS) do
		if math.random() * 100 < m.Chance * l then
			return m.Name
		end
	end
	return nil
end

-- weights = { [rarity] = weight }. Luck boosts Epic and above.
local function rollRarity(weights, extraLuck)
	local l = luck() * (extraLuck or 1)
	local total = 0
	local adjusted = {}
	for r, w in pairs(weights) do
		local aw = r >= 4 and w * l or w
		adjusted[r] = aw
		total = total + aw
	end
	local roll = math.random() * total
	local best = 1
	for r = 1, #RARITIES do
		local w = adjusted[r]
		if w then
			best = r
			roll = roll - w
			if roll <= 0 then
				return r
			end
		end
	end
	return best
end

local function randomMarketPower(rarity)
	local options = {}
	for _, def in ipairs(POWERS) do
		if def.Market and def.Rarity == rarity then
			table.insert(options, def.Id)
		end
	end
	if #options == 0 then
		return "Fire"
	end
	return options[math.random(1, #options)]
end

----------------------------------------------------------------------
-- POWER OBJECTS
----------------------------------------------------------------------
local powersByPart = {}
local carriers = {}
local marketStock = {} -- [podiumIndex] = power

local applyMovement
local onPowerPrompt

local function powerIncome(power)
	local m = power.Mut and MUT_BY_NAME[power.Mut]
	return power.Def.Income * (m and m.Mult or 1)
end

local function setState(power, state)
	power.State = state
	power.Part:SetAttribute("State", state)
end

local function isVaultSlot(slot)
	return slot ~= nil and slot > VAULT_OFFSET
end

local function updatePowerLabel(power)
	local def = power.Def
	local rarity = RARITIES[def.Rarity]
	local info = power.InfoLabel
	if power.State == "Market" then
		info.Text = "$" .. fmt(def.Price) .. "  |  +$" .. fmt(powerIncome(power)) .. "/s"
	elseif power.State == "Placed" or power.State == "Flying" then
		info.Text = "+$" .. fmt(powerIncome(power)) .. "/s" .. (isVaultSlot(power.Slot) and "  (VAULT)" or "")
	elseif power.State == "Loose" then
		info.Text = "DROPPED! Grab it!"
	else
		info.Text = "STOLEN!"
	end
	power.RarityLabel.Text = string.upper(rarity.Name)
end

local function createPower(id, mut)
	local def = POWER_BY_ID[id]
	local rarity = RARITIES[def.Rarity]
	local mutation = mut and MUT_BY_NAME[mut]

	local part = Instance.new("Part")
	part.Name = "Power"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(3.2, 3.2, 3.2)
	part.Color = (mutation and mutation.Color) or def.Color
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CustomPhysicalProperties = PhysicalProperties.new(1, 1, 0, 1, 1)

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(part.Color)
	particles.LightEmission = 1
	particles.Rate = 8 + def.Rarity * 4
	particles.Lifetime = NumberRange.new(0.6, 1.2)
	particles.Speed = NumberRange.new(1, 3)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Size = NumberSequence.new(0.6, 0)
	particles.Parent = part
	if def.Element == "Fire" or def.Element == "Dragon" then
		local fire = Instance.new("Fire")
		fire.Size = 4
		fire.Heat = 6
		fire.Color = def.Color
		fire.Parent = part
	elseif def.Element == "Shadow" or mut == "Corrupted" then
		local smoke = Instance.new("Smoke")
		smoke.Color = Color3.fromRGB(30, 0, 40)
		smoke.Size = 2
		smoke.RiseVelocity = 1
		smoke.Parent = part
	end
	if def.Rarity >= 4 or mut then
		local light = Instance.new("PointLight")
		light.Color = part.Color
		light.Range = 8 + def.Rarity * 2
		light.Brightness = 2
		light.Parent = part
	end
	if mut == "Galaxy" or def.Rarity == 7 then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.fromRGB(255, 255, 255)
		sparkles.Parent = part
	end

	local _, labels = billboard(part, 240, 78, Vector3.new(0, 3.6, 0), 3)
	labels[1].Text = displayName(id, mut)
	labels[1].TextColor3 = def.Rarity == 7 and Color3.new(1, 1, 1) or rarity.Color
	labels[2].TextColor3 = rarity.Color
	if def.Rarity == 7 then
		labels[2].TextStrokeColor3 = Color3.new(1, 1, 1)
		labels[2].TextStrokeTransparency = 0
	end
	labels[1].Parent.MaxDistance = 80

	local power = {
		Part = part, Id = id, Def = def, Mut = mut, State = "New",
		RarityLabel = labels[2], InfoLabel = labels[3],
	}

	local prompts = {
		{ Name = "Buy", Action = "Buy $" .. fmt(def.Price), Hold = 0 },
		{ Name = "Steal", Action = "STEAL", Hold = 1 + def.Rarity * 0.5 },
		{ Name = "Sell", Action = "Sell $" .. fmt(def.Price * CONFIG.SELL_PERCENT), Hold = 1, Key = Enum.KeyCode.R },
		{ Name = "Vault", Action = "Move to/from Vault", Hold = 0.3 },
		{ Name = "Grab", Action = "Grab", Hold = 0.3 },
	}
	for _, info in ipairs(prompts) do
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = info.Name
		prompt.ActionText = info.Action
		prompt.ObjectText = displayName(id, mut)
		prompt.HoldDuration = info.Hold
		prompt.MaxActivationDistance = 11
		prompt.RequiresLineOfSight = false
		if info.Key then
			prompt.KeyboardKeyCode = info.Key
		end
		prompt.Parent = part
		prompt.Triggered:Connect(function(player)
			onPowerPrompt(power, info.Name, player)
		end)
	end

	part:SetAttribute("PowerId", id)
	part:SetAttribute("Mut", mut or "")
	part:SetAttribute("OwnerId", 0)
	part:SetAttribute("Slot", 0)
	part:SetAttribute("State", "New")
	CollectionService:AddTag(part, "Power")
	powersByPart[part] = power
	part.Parent = powerFolder
	return power
end

local function powerAlive(power)
	return powersByPart[power.Part] == power
end

local function destroyPower(power)
	powersByPart[power.Part] = nil
	if power.Plot and power.Plot.Slots[power.Slot] == power then
		power.Plot.Slots[power.Slot] = nil
	end
	for i, p in pairs(marketStock) do
		if p == power then
			marketStock[i] = nil
		end
	end
	power.Part:Destroy()
end

local function freeSlot(plot, player)
	for i = 1, normalLimit(player) do
		if not plot.Slots[i] then
			return i
		end
	end
	return nil
end

local function freeVaultSlot(plot, player)
	for i = 1, vaultLimit(player) do
		if not plot.Slots[VAULT_OFFSET + i] then
			return VAULT_OFFSET + i
		end
	end
	return nil
end

local function slotCFrame(plot, slot)
	local ped = plot.Pedestals[slot]
	return CFrame.new(ped.Position + Vector3.new(0, ped.Size.Y / 2 + 2, 0))
end

local function refreshPedestals(plot)
	local owner = plot.Owner
	for slot, ped in pairs(plot.Pedestals) do
		local unlocked
		if not owner then
			unlocked = false
		elseif isVaultSlot(slot) then
			unlocked = slot - VAULT_OFFSET <= vaultLimit(owner)
		else
			unlocked = slot <= normalLimit(owner)
		end
		ped.Transparency = unlocked and 0 or 0.7
	end
end

local function place(power, plot, slot, owner)
	plot.Slots[slot] = power
	power.Plot, power.Slot, power.Owner = plot, slot, owner
	power.HomeOwner, power.HomeSlot = nil, nil
	local part = power.Part
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = slotCFrame(plot, slot)
	part:SetAttribute("OwnerId", owner.UserId)
	part:SetAttribute("Slot", slot)
	setState(power, "Placed")
	updatePowerLabel(power)
end

local function flyToSlot(power, plot, slot, owner)
	plot.Slots[slot] = power
	power.Plot, power.Slot, power.Owner = plot, slot, owner
	local part = power.Part
	part.Anchored = true
	part.CanCollide = false
	part:SetAttribute("OwnerId", owner.UserId)
	part:SetAttribute("Slot", slot)
	setState(power, "Flying")
	updatePowerLabel(power)
	local tween = TweenService:Create(part, TweenInfo.new(1.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = slotCFrame(plot, slot) })
	tween.Completed:Connect(function()
		if powerAlive(power) and power.State == "Flying" and plot.Slots[slot] == power and owner.Parent then
			place(power, plot, slot, owner)
		end
	end)
	tween:Play()
end

local function attachToCarrier(power, player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local part = power.Part
	part.CanCollide = false
	part.Massless = true
	part.CFrame = root.CFrame * CFrame.new(0, 4.5, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	part.Anchored = false
	power.Carrier = player
	carriers[player] = power
	player:SetAttribute("Carrying", true)
	part:SetAttribute("OwnerId", 0)
	setState(power, "Carried")
	updatePowerLabel(power)
	applyMovement(player)
	return true
end

local function detach(power)
	local part = power.Part
	local weld = part:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	part.Anchored = true
	part.Massless = false
	local carrier = power.Carrier
	power.Carrier = nil
	if carrier then
		carriers[carrier] = nil
		carrier:SetAttribute("Carrying", false)
		applyMovement(carrier)
	end
end

local function returnHome(power)
	if not powerAlive(power) then
		return
	end
	detach(power)
	local owner = power.HomeOwner
	local plot = owner and owner.Parent and playerPlot[owner]
	if plot then
		local slot = power.HomeSlot
		if not slot or plot.Slots[slot] then
			slot = freeSlot(plot, owner)
		end
		if slot then
			power.HomeOwner, power.HomeSlot = nil, nil
			flyToSlot(power, plot, slot, owner)
			return
		end
	end
	destroyPower(power)
end

local function deliver(power, player, plot, slot)
	local victim = power.HomeOwner
	detach(power)
	place(power, plot, slot, player)
	if victim and victim ~= player then
		local data = sessions[player]
		if data then
			data.Steals = data.Steals + 1
			updateStats(player)
		end
		local name = displayName(power.Id, power.Mut)
		effect(power.Part.Position, Color3.fromRGB(255, 60, 60), "STOLEN!")
		notify(player, "You stole " .. name .. " from " .. victim.Name .. "!")
		if victim.Parent then
			notify(victim, player.Name .. " STOLE your " .. name .. "!")
		end
		if power.Def.Rarity >= 5 or power.Mut then
			announce(player.Name .. " stole " .. victim.Name .. "'s " .. RARITIES[power.Def.Rarity].Name .. " " .. name .. "!")
		end
	end
end

local function groundBelow(position)
	local params = RaycastParams.new()
	local ignore = { powerFolder }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	params.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -100, 0), params)
	if result then
		return result.Position + Vector3.new(0, 1.8, 0)
	end
	return Vector3.new(position.X, 2, position.Z)
end

local function makeLoose(power, position)
	detach(power)
	local part = power.Part
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = CFrame.new(groundBelow(position))
	part:SetAttribute("OwnerId", 0)
	setState(power, "Loose")
	updatePowerLabel(power)
	local token = {}
	power.LooseToken = token
	task.delay(CONFIG.LOOSE_TIME, function()
		if powerAlive(power) and power.State == "Loose" and power.LooseToken == token then
			returnHome(power)
		end
	end)
end

-- Give a player a brand new power (portal, daily, rebirth reward)
local function givePower(player, id, mut, fromPosition)
	local plot = playerPlot[player]
	if not plot then
		return false
	end
	local slot = freeSlot(plot, player) or freeVaultSlot(plot, player)
	if not slot then
		return false
	end
	local power = createPower(id, mut)
	power.Part.CFrame = CFrame.new(fromPosition or (slotCFrame(plot, slot).Position + Vector3.new(0, 40, 0)))
	flyToSlot(power, plot, slot, player)
	return true
end

----------------------------------------------------------------------
-- MOVEMENT
----------------------------------------------------------------------
local frozenUntil = {}

applyMovement = function(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local data = sessions[player]
	if not hum or not data then
		return
	end
	local speed = 16
	if data.Rebirths >= 3 then
		speed = speed + math.min(10, 4 + (data.Rebirths - 3) * 2)
	end
	if carriers[player] and not player:GetAttribute("FastSteal") then
		speed = speed - 3
	end
	if frozenUntil[player] and os.clock() < frozenUntil[player] then
		speed = 0
	end
	hum.WalkSpeed = speed
end

----------------------------------------------------------------------
-- MARKET
----------------------------------------------------------------------
local nextRestock = 0

local function restockMarket()
	for i, power in pairs(marketStock) do
		if powerAlive(power) and power.State == "Market" then
			destroyPower(power)
		end
		marketStock[i] = nil
	end
	for i = 1, #marketPodiums do
		local rarity
		if i <= 5 then
			rarity = rollRarity({ [1] = 70, [2] = 30 })
		elseif i <= 8 then
			rarity = rollRarity({ [2] = 50, [3] = 35, [4] = 15 })
		elseif i == 9 then
			rarity = rollRarity({ [4] = 60, [5] = 40 })
		else
			rarity = rollRarity({ [3] = 40, [4] = 34, [5] = 19, [6] = 6, [7] = 1 })
		end
		local id = randomMarketPower(rarity)
		local mut = rollMutation()
		local power = createPower(id, mut)
		local podium = marketPodiums[i]
		power.Part.CFrame = CFrame.new(podium.Position + Vector3.new(0, podium.Size.Y / 2 + 2, 0))
		setState(power, "Market")
		updatePowerLabel(power)
		marketStock[i] = power
		if rarity >= 6 or (mut and rarity >= 4) then
			announce("A " .. RARITIES[rarity].Name:upper() .. " " .. displayName(id, mut) .. " is in the POWER MARKET!")
		end
	end
	nextRestock = os.clock() + CONFIG.RESTOCK_TIME
end

----------------------------------------------------------------------
-- POWER PROMPTS (Buy / Steal / Sell / Vault / Grab)
----------------------------------------------------------------------
local function isAlive(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

onPowerPrompt = function(power, action, player)
	local data = sessions[player]
	local plot = playerPlot[player]
	if not data or not plot or not powerAlive(power) or not isAlive(player) then
		return
	end
	local def = power.Def
	local name = displayName(power.Id, power.Mut)

	if action == "Buy" then
		if power.State ~= "Market" then
			return
		end
		if data.Cash < def.Price then
			notify(player, "Not enough cash! You need $" .. fmt(def.Price))
			return
		end
		local slot = freeSlot(plot, player)
		if not slot then
			notify(player, "Your base is full! Sell a power or buy more slots (BASE menu).")
			return
		end
		data.Cash = data.Cash - def.Price
		updateStats(player)
		for i, p in pairs(marketStock) do
			if p == power then
				marketStock[i] = nil
			end
		end
		effect(power.Part.Position, RARITIES[def.Rarity].Color, "+" .. name)
		flyToSlot(power, plot, slot, player)
		if def.Rarity >= 5 then
			announce(player.Name .. " bought a " .. RARITIES[def.Rarity].Name .. " " .. name .. "!")
		end

	elseif action == "Steal" then
		if power.State ~= "Placed" or power.Owner == player or carriers[player] or isVaultSlot(power.Slot) then
			return
		end
		if not freeSlot(plot, player) then
			notify(player, "Your base is full! Make room first.")
			return
		end
		local victim, fromPlot, fromSlot = power.Owner, power.Plot, power.Slot
		if not attachToCarrier(power, player) then
			return
		end
		fromPlot.Slots[fromSlot] = nil
		power.Plot, power.Slot, power.Owner = nil, nil, nil
		power.HomeOwner, power.HomeSlot = victim, fromSlot
		fromPlot.AlarmUntil = os.clock() + 10
		notify(player, "Run home or THROW it into your base! (F)")
		if victim and victim.Parent then
			alarmRemote:FireClient(victim, player.Name .. " is stealing your " .. name .. "!")
		end

	elseif action == "Sell" then
		if power.State ~= "Placed" or power.Owner ~= player then
			return
		end
		local amount = math.floor(def.Price * CONFIG.SELL_PERCENT)
		data.Cash = data.Cash + amount
		updateStats(player)
		destroyPower(power)
		notify(player, "Sold " .. name .. " for $" .. fmt(amount))

	elseif action == "Vault" then
		if power.State ~= "Placed" or power.Owner ~= player then
			return
		end
		local target
		if isVaultSlot(power.Slot) then
			target = freeSlot(plot, player)
			if not target then
				notify(player, "No free pedestal outside the vault.")
				return
			end
		else
			target = freeVaultSlot(plot, player)
			if not target then
				notify(player, "Your vault is full! Rebirth or get Extra Vault for more.")
				return
			end
		end
		plot.Slots[power.Slot] = nil
		flyToSlot(power, plot, target, player)

	elseif action == "Grab" then
		if power.State ~= "Loose" or carriers[player] then
			return
		end
		if power.HomeOwner == player then
			returnHome(power)
			notify(player, "You got your " .. name .. " back!")
			return
		end
		if not freeSlot(plot, player) then
			notify(player, "Your base is full! Make room first.")
			return
		end
		attachToCarrier(power, player)
	end
end

----------------------------------------------------------------------
-- THROWING
----------------------------------------------------------------------
local lastThrow = {}

local function landed(power, thrower)
	if not powerAlive(power) or power.State ~= "Thrown" then
		return
	end
	local pos = power.Part.Position
	local plot = plotAt(pos)
	if plot and plot.Owner == thrower and thrower.Parent then
		local slot = freeSlot(plot, thrower)
		if slot then
			deliver(power, thrower, plot, slot)
			return
		end
	end
	if plot and plot.Owner and plot.Owner == power.HomeOwner then
		returnHome(power)
		return
	end
	makeLoose(power, pos)
end

throwRemote.OnServerEvent:Connect(function(player, direction)
	local power = carriers[player]
	if not power or typeof(direction) ~= "Vector3" then
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

	detach(power)
	setState(power, "Thrown")
	updatePowerLabel(power)
	local part = power.Part
	part.CFrame = CFrame.new(root.Position + Vector3.new(0, 4, 0) + flat * 3)
	part.CanCollide = true
	part.Anchored = false
	part:SetNetworkOwner(nil)
	local speed = CONFIG.THROW_POWER
	part.AssemblyLinearVelocity = flat * speed + Vector3.new(0, speed * 0.9, 0)

	task.spawn(function()
		local start = os.clock()
		while powerAlive(power) and power.State == "Thrown" do
			task.wait(0.1)
			local t = os.clock() - start
			if part.Position.Y < -30 then
				returnHome(power)
				return
			end
			if (t > 0.5 and part.AssemblyLinearVelocity.Magnitude < 4) or t > 5 then
				landed(power, player)
				return
			end
		end
	end)
end)

----------------------------------------------------------------------
-- BATTLE: POWER BLAST
----------------------------------------------------------------------
local lastBlast = {}

local function bestPower(player)
	local plot = playerPlot[player]
	local best, bestIncome = nil, -1
	if plot then
		for _, power in pairs(plot.Slots) do
			if power.Owner == player and powerIncome(power) > bestIncome then
				best, bestIncome = power, powerIncome(power)
			end
		end
	end
	return best
end

local function elementOf(player)
	local best = bestPower(player)
	return best and best.Def.Element or "Punch"
end

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

local function beam(from, to, element)
	local e = ELEMENTS[element]
	local dist = (to - from).Magnitude
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.Neon
	p.Color = e.Color
	p.Size = Vector3.new(e.Width, e.Width, dist)
	p.CFrame = CFrame.lookAt((from + to) / 2, to)
	p.Parent = workspace
	TweenService:Create(p, TweenInfo.new(0.25), { Transparency = 1 }):Play()
	Debris:AddItem(p, 0.3)
end

local function makeInvisible(player, seconds)
	local char = player.Character
	if not char then
		return
	end
	local changed = {}
	for _, d in ipairs(char:GetDescendants()) do
		if (d:IsA("BasePart") and d.Name ~= "HumanoidRootPart") or d:IsA("Decal") then
			changed[d] = d.Transparency
			d.Transparency = 0.92
		end
	end
	task.delay(seconds, function()
		for d, t in pairs(changed) do
			if d.Parent then
				d.Transparency = t
			end
		end
	end)
end

local function onKO(attacker, victim)
	local data = sessions[attacker]
	if not data then
		return
	end
	local reward = math.max(100, math.floor((attacker:GetAttribute("Income") or 0) * 30))
	data.Cash = data.Cash + reward
	updateStats(attacker)
	notify(attacker, "KO! You beat " .. victim.Name .. " and got $" .. fmt(reward))
	notify(victim, attacker.Name .. " knocked you out in the arena!")
end

blastRemote.OnServerEvent:Connect(function(player, target)
	if typeof(target) ~= "Vector3" or target.Magnitude ~= target.Magnitude then
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local head = char and char:FindFirstChild("Head")
	if not root or not head or not isAlive(player) or not char:FindFirstChild("Power Blast") then
		return
	end
	local element = elementOf(player)
	local e = ELEMENTS[element]
	if lastBlast[player] and os.clock() - lastBlast[player] < e.Cooldown then
		return
	end
	lastBlast[player] = os.clock()

	local origin = head.Position
	local dir = target - origin
	if dir.Magnitude < 0.1 then
		dir = root.CFrame.LookVector
	end
	dir = dir.Unit * e.Range
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { char, powerFolder }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:Raycast(origin, dir, params)
	local hitPos = result and result.Position or (origin + dir)
	beam(origin, hitPos, element)

	if e.Invisible then
		makeInvisible(player, e.Invisible)
	end
	if not result then
		return
	end
	local model = result.Instance:FindFirstAncestorOfClass("Model")
	local victim = model and Players:GetPlayerFromCharacter(model)
	local vhum = model and model:FindFirstChildOfClass("Humanoid")
	local vroot = model and model:FindFirstChild("HumanoidRootPart")
	if not victim or victim == player or not vhum or vhum.Health <= 0 or not vroot then
		return
	end

	local arenaFight = inArena(root.Position) and inArena(vroot.Position)
	local carrying = carriers[victim]
	local defending = playerPlot[player] ~= nil and plotAt(vroot.Position) == playerPlot[player]
	if not arenaFight and not carrying and not defending then
		return -- no fighting outside the arena, except vs thieves
	end

	local push = Vector3.new(dir.X, 0, dir.Z)
	push = push.Magnitude > 0.1 and push.Unit or root.CFrame.LookVector
	if e.Pull then
		knockback(vroot, -push * 45 + Vector3.new(0, 15, 0))
	else
		knockback(vroot, push * (element == "Dragon" and 80 or 45) + Vector3.new(0, 25, 0))
	end
	if e.Freeze then
		frozenUntil[victim] = os.clock() + e.Freeze
		applyMovement(victim)
		task.delay(e.Freeze, function()
			if victim.Parent then
				applyMovement(victim)
			end
		end)
	end
	if carrying then
		makeLoose(carrying, vroot.Position)
		notify(player, "You hit " .. victim.Name .. " and they DROPPED the power!")
		notify(victim, "You got hit and dropped the power!")
	end
	if arenaFight then
		vhum:TakeDamage(e.Damage)
		if vhum.Health <= 0 then
			onKO(player, victim)
		end
	end
end)

local function givePowerBlast(player)
	local tool = Instance.new("Tool")
	tool.Name = "Power Blast"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Ball
	handle.Size = Vector3.new(1.2, 1.2, 1.2)
	handle.Material = Enum.Material.Neon
	handle.Color = ELEMENTS[elementOf(player)].Color
	handle.CanCollide = false
	handle.Parent = tool
	tool.Parent = player:WaitForChild("Backpack")
end

----------------------------------------------------------------------
-- BASE LOCK
----------------------------------------------------------------------
local function lockBase(plot, seconds)
	plot.LockUntil = os.clock() + seconds
	plot.LockCooldownUntil = plot.LockUntil + CONFIG.LOCK_COOLDOWN
end

for _, plot in ipairs(plots) do
	plot.LockPad.Touched:Connect(function(hit)
		local model = hit:FindFirstAncestorOfClass("Model")
		local player = model and Players:GetPlayerFromCharacter(model)
		if not player or plot.Owner ~= player then
			return
		end
		local now = os.clock()
		if now < plot.LockUntil then
			return
		end
		if now < plot.LockCooldownUntil then
			notify(player, "Lock ready in " .. math.ceil(plot.LockCooldownUntil - now) .. "s")
			return
		end
		lockBase(plot, CONFIG.LOCK_TIME)
		notify(player, "Base LOCKED for " .. CONFIG.LOCK_TIME .. " seconds!")
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
-- SECRET PORTAL
----------------------------------------------------------------------
local portalOpenUntil = 0
local nextPortal = os.clock() + CONFIG.FIRST_PORTAL
local portalUsed = {}

portal.Touched:Connect(function(hit)
	if os.clock() >= portalOpenUntil then
		return
	end
	local model = hit:FindFirstAncestorOfClass("Model")
	local player = model and Players:GetPlayerFromCharacter(model)
	if not player or portalUsed[player] or not sessions[player] then
		return
	end
	portalUsed[player] = true
	local rarity = rollRarity({ [3] = 50, [4] = 30, [5] = 15, [6] = 4.5, [7] = 0.5 })
	local id = randomMarketPower(rarity)
	local mut = rollMutation(2)
	if givePower(player, id, mut, portal.Position) then
		notify(player, "The portal gave you " .. displayName(id, mut) .. "!")
		effect(portal.Position, Color3.fromRGB(170, 60, 255), displayName(id, mut) .. "!")
		if rarity >= 5 then
			announce(player.Name .. " got a " .. RARITIES[rarity].Name .. " " .. displayName(id, mut) .. " from the SECRET PORTAL!")
		end
	else
		portalUsed[player] = nil
		notify(player, "Your base is full! Make room and come back.")
	end
end)

----------------------------------------------------------------------
-- REQUESTS FROM THE CLIENT (menus)
----------------------------------------------------------------------
local function myPowersList(player)
	local plot = playerPlot[player]
	local list = {}
	if plot then
		for slot, power in pairs(plot.Slots) do
			if power.Owner == player and power.State == "Placed" then
				table.insert(list, {
					Slot = slot, Id = power.Id, Mut = power.Mut,
					Name = displayName(power.Id, power.Mut),
					Rarity = power.Def.Rarity, Income = powerIncome(power),
					Price = power.Def.Price, Vault = isVaultSlot(slot),
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
	local now = os.time()
	local since = now - (data.LastDaily or 0)
	local ready = since >= 20 * 3600
	return ready, math.max(0, 20 * 3600 - since)
end

local function getInfo(player)
	local data = sessions[player]
	local discovered = {}
	for _, r in ipairs(RECIPES) do
		local key = recipeKey(r[1], r[2])
		if data.Discovered[key] then
			table.insert(discovered, { A = r[1], B = r[2], Result = r[3], Name = POWER_BY_ID[r[3]].Name })
		else
			table.insert(discovered, { Hidden = true, Rarity = POWER_BY_ID[r[3]].Rarity })
		end
	end
	local ready, wait = dailyStatus(data)
	local names = {}
	for _, def in ipairs(POWERS) do
		names[def.Id] = def.Name
	end
	return {
		Cash = data.Cash, Rebirths = data.Rebirths, RebirthCost = rebirthCost(data),
		Slots = normalLimit(player), MaxSlots = CONFIG.MAX_SLOTS, BaseSlots = data.Slots,
		SlotCost = slotCost(data), Vaults = vaultLimit(player),
		Turret = data.Turret, TurretCost = CONFIG.TURRET_COSTS[data.Turret + 1],
		DailyReady = ready, DailyWait = wait, Streak = data.Streak,
		Recipes = discovered, Powers = myPowersList(player), Names = names,
		FuseCostPercent = CONFIG.FUSE_COST_PERCENT,
	}
end

local function doFuse(player, slotA, slotB)
	local data = sessions[player]
	local plot = playerPlot[player]
	if not plot or type(slotA) ~= "number" or type(slotB) ~= "number" or slotA == slotB then
		return false, "Pick two different powers"
	end
	if not near(player, fusionPos, 30) then
		return false, "Go to the Fusion Station!"
	end
	local a, b = plot.Slots[slotA], plot.Slots[slotB]
	if not a or not b or a.Owner ~= player or b.Owner ~= player or a.State ~= "Placed" or b.State ~= "Placed" then
		return false, "Those powers are not in your base"
	end
	local cost = math.floor((a.Def.Price + b.Def.Price) * CONFIG.FUSE_COST_PERCENT)
	if data.Cash < cost then
		return false, "Fusion costs $" .. fmt(cost)
	end
	data.Cash = data.Cash - cost

	local key = recipeKey(a.Id, b.Id)
	local resultId = RECIPE_BY_KEY[key]
	local discoveredNew = false
	if resultId then
		if not data.Discovered[key] then
			data.Discovered[key] = true
			discoveredNew = true
		end
	else
		-- No recipe: random power, sometimes one rarity higher
		local rarity = math.max(a.Def.Rarity, b.Def.Rarity)
		if math.random() < 0.2 then
			rarity = math.min(rarity + 1, 6)
		end
		resultId = randomMarketPower(rarity)
	end

	local mut = rollMutation(1.5)
	if not mut and math.random() < 0.5 then
		local am, bm = a.Mut and MUT_BY_NAME[a.Mut], b.Mut and MUT_BY_NAME[b.Mut]
		if am and (not bm or am.Mult >= bm.Mult) then
			mut = a.Mut
		elseif bm then
			mut = b.Mut
		end
	end

	destroyPower(a)
	destroyPower(b)
	local result = createPower(resultId, mut)
	result.Part.CFrame = fusionCore.CFrame
	flyToSlot(result, plot, slotA, player)
	updateStats(player)

	local name = displayName(resultId, mut)
	local rarity = POWER_BY_ID[resultId].Rarity
	effect(fusionCore.Position, RARITIES[rarity].Color, name .. "!")
	if discoveredNew then
		notify(player, "NEW RECIPE DISCOVERED: " .. name .. "!")
		if rarity >= 4 then
			announce(player.Name .. " discovered a secret fusion: " .. POWER_BY_ID[resultId].Name .. "!")
		end
	elseif rarity >= 5 then
		announce(player.Name .. " fused a " .. RARITIES[rarity].Name .. " " .. name .. "!")
	end
	return true, "You made " .. name .. "!"
end

local function doRebirth(player)
	local data = sessions[player]
	local plot = playerPlot[player]
	if not plot then
		return false, "No base"
	end
	local cost = rebirthCost(data)
	if data.Cash < cost then
		return false, "You need $" .. fmt(cost)
	end
	for slot, power in pairs(plot.Slots) do
		if not isVaultSlot(slot) and power.Owner == player then
			destroyPower(power)
		end
	end
	data.Rebirths = data.Rebirths + 1
	data.Cash = CONFIG.START_CASH
	data.Slots = CONFIG.START_SLOTS
	refreshPedestals(plot)
	applyMovement(player)
	updateStats(player)
	announce(player.Name .. " reached REBIRTH " .. data.Rebirths .. "!")
	if data.Rebirths == 10 then
		givePower(player, "Phoenix", "Golden")
		announce(player.Name .. " unlocked the exclusive PHOENIX power!")
	end
	saveData(player)
	return true, "REBIRTH " .. data.Rebirths .. "! Your vault powers were kept."
end

requestRemote.OnServerInvoke = function(player, action, a, b)
	local data = sessions[player]
	local plot = playerPlot[player]
	if not data or not plot then
		return false, "Loading..."
	end

	if action == "GetInfo" then
		return true, getInfo(player)

	elseif action == "Fuse" then
		return doFuse(player, a, b)

	elseif action == "Rebirth" then
		return doRebirth(player)

	elseif action == "BuySlot" then
		if data.Slots >= CONFIG.MAX_SLOTS then
			return false, "You have all slots!"
		end
		local cost = slotCost(data)
		if data.Cash < cost then
			return false, "You need $" .. fmt(cost)
		end
		data.Cash = data.Cash - cost
		data.Slots = data.Slots + 1
		refreshPedestals(plot)
		updateStats(player)
		return true, "New pedestal unlocked!"

	elseif action == "BuyTurret" then
		local cost = CONFIG.TURRET_COSTS[data.Turret + 1]
		if not cost then
			return false, "Turret is max level!"
		end
		if data.Cash < cost then
			return false, "You need $" .. fmt(cost)
		end
		data.Cash = data.Cash - cost
		data.Turret = data.Turret + 1
		updateStats(player)
		return true, "Turret upgraded to level " .. data.Turret .. "!"

	elseif action == "ClaimDaily" then
		local ready = dailyStatus(data)
		if not ready then
			return false, "Come back later!"
		end
		if os.time() - (data.LastDaily or 0) > 48 * 3600 then
			data.Streak = 0
		end
		data.Streak = data.Streak + 1
		data.LastDaily = os.time()
		local day = ((data.Streak - 1) % 7) + 1
		local reward = math.floor((500 + (player:GetAttribute("Income") or 0) * 120) * day)
		if player:GetAttribute("VIP") then
			reward = reward * 2
		end
		data.Cash = data.Cash + reward
		updateStats(player)
		local msg = "Day " .. day .. " reward: $" .. fmt(reward) .. "!"
		if day == 7 then
			local id = randomMarketPower(rollRarity({ [4] = 70, [5] = 25, [6] = 5 }))
			if givePower(player, id, rollMutation(2)) then
				msg = msg .. " + a free " .. POWER_BY_ID[id].Name .. " power!"
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
	[CONFIG.VIP_PASS_ID] = "VIP",
	[CONFIG.EXTRA_SLOTS_PASS_ID] = "ExtraSlots",
	[CONFIG.FAST_STEAL_PASS_ID] = "FastSteal",
	[CONFIG.EXTRA_VAULT_PASS_ID] = "ExtraVault",
}
PASS_ATTRIBUTES[0] = nil

local function updateNameSign(player)
	local plot = playerPlot[player]
	if plot then
		plot.NameLabel.Text = (player:GetAttribute("VIP") and "[VIP] " or "") .. player.Name .. "'s Empire"
	end
end

local function grantPass(player, passId)
	local attr = PASS_ATTRIBUTES[passId]
	if not attr then
		return
	end
	player:SetAttribute(attr, true)
	local plot = playerPlot[player]
	if plot then
		refreshPedestals(plot)
	end
	updateNameSign(player)
	applyMovement(player)
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
	local plot = player and playerPlot[player]
	if not data or not plot then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receipt.ProductId == CONFIG.CASH_PACK_PRODUCT_ID then
		local amount = math.max(10000, math.floor((player:GetAttribute("Income") or 0) * 600))
		data.Cash = data.Cash + amount
		notify(player, "+$" .. fmt(amount) .. "!")
	elseif receipt.ProductId == CONFIG.SUPER_LOCK_PRODUCT_ID then
		lockBase(plot, 180)
		notify(player, "SUPER LOCK! Your base is locked for 3 minutes.")
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
-- JOIN / LEAVE
----------------------------------------------------------------------
local function spawnCFrame(player)
	local plot = playerPlot[player]
	if plot then
		return plot.CF * CFrame.new(0, 4, -20)
	end
	return CFrame.new(0, 6, -20)
end

local function onCharacter(player, char)
	local hum = char:WaitForChild("Humanoid")
	char:WaitForChild("HumanoidRootPart")
	task.wait()
	char:PivotTo(spawnCFrame(player))
	applyMovement(player)
	givePowerBlast(player)
	hum.Died:Connect(function()
		local power = carriers[player]
		if power then
			returnHome(power)
		end
	end)
end

local function onPlayerAdded(player)
	local data = loadData(player)
	if not player.Parent then
		return
	end
	sessions[player] = data

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in ipairs({ "Cash", "Rebirths", "Steals" }) do
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
		plot.LockUntil, plot.LockCooldownUntil, plot.AlarmUntil = 0, 0, 0
		updateNameSign(player)
	end

	checkPasses(player)

	if plot then
		refreshPedestals(plot)
		for _, saved in ipairs(data.Powers) do
			local slot = tonumber(saved.S)
			if POWER_BY_ID[saved.Id] and slot and plot.Pedestals[slot] and not plot.Slots[slot] then
				local mut = saved.M
				if mut == "" or not MUT_BY_NAME[mut] then
					mut = nil
				end
				local power = createPower(saved.Id, mut)
				place(power, plot, slot, player)
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
		notify(player, "All bases are taken, try another server!")
	elseif data.NoSave then
		notify(player, "Saving is OFF (turn on API access in Game Settings).")
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	local carried = carriers[player]
	if carried then
		returnHome(carried)
	end
	for _, power in pairs(powersByPart) do
		if power.HomeOwner == player then
			power.HomeOwner = nil
		end
	end
	local plot = playerPlot[player]
	if plot then
		for _, power in pairs(plot.Slots) do
			destroyPower(power)
		end
		plot.Slots = {}
		plot.Owner = nil
		plot.NameLabel.Text = "Empty Base"
		plot.IncomeLabel.Text = ""
		plot.StatusLabel.Text = ""
		plot.LockUntil, plot.LockCooldownUntil, plot.AlarmUntil = 0, 0, 0
		refreshPedestals(plot)
	end
	playerPlot[player] = nil
	sessions[player] = nil
	lastThrow[player] = nil
	lastBlast[player] = nil
	frozenUntil[player] = nil
	portalUsed[player] = nil
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

----------------------------------------------------------------------
-- GAME LOOPS
----------------------------------------------------------------------
local function timeText(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

restockMarket()

-- Every second: money, signs, market, portal
task.spawn(function()
	while true do
		task.wait(1)
		local now = os.clock()

		for _, plot in ipairs(plots) do
			local owner = plot.Owner
			local data = owner and sessions[owner]
			if data then
				local income = 0
				for _, power in pairs(plot.Slots) do
					if power.State == "Placed" and power.Owner == owner then
						income = income + powerIncome(power)
					end
				end
				income = income * incomeMultiplier(owner)
				data.Cash = data.Cash + income
				owner:SetAttribute("Income", income)
				owner:SetAttribute("Element", elementOf(owner))
				updateStats(owner)
				plot.IncomeLabel.Text = "$" .. fmt(income) .. "/s" .. (data.Rebirths > 0 and ("  |  Rebirth " .. data.Rebirths) or "")
				local status
				if now < plot.LockUntil then
					status = "LOCKED " .. math.ceil(plot.LockUntil - now) .. "s"
				elseif now < plot.LockCooldownUntil then
					status = "Lock ready in " .. math.ceil(plot.LockCooldownUntil - now) .. "s"
				else
					status = "Unlocked"
				end
				if data.Turret > 0 then
					status = status .. "  |  Turret Lv." .. data.Turret
				end
				plot.StatusLabel.Text = status
			end
			plot.Laser.Transparency = now < plot.LockUntil and 0.35 or 1
		end

		if now >= nextRestock then
			restockMarket()
			announce("The POWER MARKET has restocked!")
		end
		marketTimerLabel.Text = "Restock in " .. timeText(nextRestock - now)
		ReplicatedStorage:SetAttribute("RestockIn", math.ceil(nextRestock - now))

		if now >= nextPortal then
			portalOpenUntil = now + CONFIG.PORTAL_OPEN_TIME
			nextPortal = now + CONFIG.PORTAL_EVERY
			portalUsed = {}
			announce("The SECRET PORTAL is OPEN for 60 seconds! Run to the middle!")
		end
		if now < portalOpenUntil then
			portal.Transparency = 0.2
			portalLabel.Text = "OPEN! " .. timeText(portalOpenUntil - now)
			ReplicatedStorage:SetAttribute("PortalIn", -math.ceil(portalOpenUntil - now))
		else
			portal.Transparency = 1
			portalLabel.Text = "Opens in " .. timeText(nextPortal - now)
			ReplicatedStorage:SetAttribute("PortalIn", math.ceil(nextPortal - now))
		end
		ReplicatedStorage:SetAttribute("LuckLeft", math.max(0, math.ceil(luckUntil - now)))
	end
end)

-- Fast loop: deliveries, locks, turrets, alarms
task.spawn(function()
	local flash = false
	while true do
		task.wait(0.2)
		local now = os.clock()
		flash = not flash

		for player, power in pairs(carriers) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local plot = playerPlot[player]
			if root and plot and plotAt(root.Position) == plot then
				local slot = freeSlot(plot, player)
				if slot then
					deliver(power, player, plot, slot)
				end
			end
		end

		for _, plot in ipairs(plots) do
			local owner = plot.Owner
			plot.AlarmLight.Enabled = now < plot.AlarmUntil and flash
			if owner then
				local data = sessions[owner]
				local locked = now < plot.LockUntil
				local turretReady = data and data.Turret > 0 and now >= plot.TurretNext
				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= owner then
						local char = player.Character
						local root = char and char:FindFirstChild("HumanoidRootPart")
						if root and isAlive(player) and plotAt(root.Position) == plot then
							if locked then
								char:PivotTo(plot.CF * CFrame.new(0, 4, -PLOT_D / 2 - 8))
								notify(player, "This base is LOCKED!")
							elseif turretReady then
								turretReady = false
								plot.TurretNext = now + CONFIG.TURRET_COOLDOWN[data.Turret]
								beam(plot.TurretHead.Position, root.Position, "Lightning")
								local away = Vector3.new(root.Position.X - plot.CF.Position.X, 0, root.Position.Z - plot.CF.Position.Z)
								if away.Magnitude > 0.1 then
									knockback(root, away.Unit * 50 + Vector3.new(0, 25, 0))
								end
								local carried = carriers[player]
								if carried then
									makeLoose(carried, root.Position)
									notify(player, "The TURRET zapped you! You dropped the power!")
								else
									notify(player, "The TURRET zapped you!")
								end
							end
						end
					end
				end
			end
		end
	end
end)

print("POWER EMPIRE server v4 started OK!")
