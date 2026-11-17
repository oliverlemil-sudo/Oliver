--[[
	👹 MOG MONSTERS 👹
	==================
	Put this as a *Script* in ServerScriptService.

	This script builds the whole map and runs the game:
	  * The MOG ROAD has 8 ZONES. Every gate needs more MOG to pass.
	    Further out = rarer monsters. Hold E to MOG them - then they
	    run home to your fenced base.
	  * Monsters in your base make money every second.
	  * Variants: Normal, Golden, Diamond, Rainbow, Cosmic, RAINBOW COSMIC.
	  * Rarities down to GIGAMOG: 1 in 1,000,000,000!
	  * Upgrades: Train MOG, Money Boost, more spots.
	  * STEAL monsters from other bases, THROW them home (F), MOG SLAP thieves.
	  * Vault (can't be stolen), base lock, fusion (2 same = next level),
	    rebirth, Lucky Rush event, daily rewards, Robux shop.

	>>> ONLY CHANGE THINGS IN THE "CONFIG" SECTION BELOW <<<
]]

----------------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------------
local CONFIG = {
	START_CASH = 0,
	START_SLOTS = 6,          -- monster spots you start with
	MAX_SLOTS = 12,           -- spots you can buy with cash
	SLOT_BASE_COST = 500,     -- price of spot 7 (then x3 every spot)
	WANDER_SPEED = 4,         -- how fast monsters walk around in their zone
	LOCK_TIME = 45,
	LOCK_COOLDOWN = 45,
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
	VIP_PASS_ID = 0,          -- VIP tag, +20% money, 2x daily reward
	EXTRA_SLOTS_PASS_ID = 0,  -- +3 spots
	FAST_STEAL_PASS_ID = 0,   -- steal 2x faster, no slow-down when carrying
	EXTRA_VAULT_PASS_ID = 0,  -- +1 vault slot
	SERVER_LUCK_PRODUCT_ID = 0, -- 2x luck for EVERYONE for 15 minutes
	SUPER_LOCK_PRODUCT_ID = 0,  -- lock your base for 3 minutes
	CASH_PACK_PRODUCT_ID = 0,   -- 10 minutes of income (min 5K)
}

-- Mog = MOG you need (also the MOG to enter that zone), Income = money per second
local RARITIES = {
	{ Name = "Common",    Mog = 10,        Income = 2,       Color = Color3.fromRGB(200, 200, 200) },
	{ Name = "Uncommon",  Mog = 40,        Income = 6,       Color = Color3.fromRGB(90, 220, 90) },
	{ Name = "Rare",      Mog = 200,       Income = 25,      Color = Color3.fromRGB(70, 150, 255) },
	{ Name = "Epic",      Mog = 1500,      Income = 100,     Color = Color3.fromRGB(180, 90, 255) },
	{ Name = "Legendary", Mog = 12000,     Income = 600,     Color = Color3.fromRGB(255, 200, 40) },
	{ Name = "Mythic",    Mog = 100000,    Income = 4000,    Color = Color3.fromRGB(255, 60, 120) },
	{ Name = "Secret",    Mog = 2000000,   Income = 50000,   Color = Color3.fromRGB(30, 30, 30) },
	{ Name = "GODLY",     Mog = 100000000, Income = 1000000, Color = Color3.fromRGB(255, 255, 255) },
}

-- One ZONE per rarity along the Mog Road. Need = MOG to enter.
-- Every = seconds between new monsters, Max = most monsters at once.
local ZONES = {
	{ Every = 3,   Max = 10 },
	{ Every = 5,   Max = 8 },
	{ Every = 8,   Max = 6 },
	{ Every = 15,  Max = 5 },
	{ Every = 30,  Max = 4 },
	{ Every = 60,  Max = 3 },
	{ Every = 180, Max = 2 },
	{ Every = nil, Max = 1 }, -- GODLY zone: only a GIGAMOG (1 in a billion per spawn)
}
local GIGAMOG_CHANCE = 1 / 1000000000

local MONSTERS = {
	{ Id = "Blobby",      Name = "Blobby",      Rarity = 1, Color = Color3.fromRGB(100, 220, 100) },
	{ Id = "Pebblo",      Name = "Pebblo",      Rarity = 1, Color = Color3.fromRGB(150, 140, 130) },
	{ Id = "Zappit",      Name = "Zappit",      Rarity = 2, Color = Color3.fromRGB(255, 240, 70) },
	{ Id = "Mudmaw",      Name = "Mudmaw",      Rarity = 2, Color = Color3.fromRGB(140, 100, 60) },
	{ Id = "Frostfang",   Name = "Frostfang",   Rarity = 3, Color = Color3.fromRGB(150, 230, 255) },
	{ Id = "Emberclaw",   Name = "Emberclaw",   Rarity = 3, Color = Color3.fromRGB(255, 110, 30) },
	{ Id = "Shadowgloom", Name = "Shadowgloom", Rarity = 4, Color = Color3.fromRGB(80, 45, 120) },
	{ Id = "Crystalix",   Name = "Crystalix",   Rarity = 4, Color = Color3.fromRGB(160, 255, 255) },
	{ Id = "Thunderhorn", Name = "Thunderhorn", Rarity = 5, Color = Color3.fromRGB(255, 220, 0) },
	{ Id = "Magmaroth",   Name = "Magmaroth",   Rarity = 5, Color = Color3.fromRGB(220, 50, 20) },
	{ Id = "Voidwyrm",    Name = "Voidwyrm",    Rarity = 6, Color = Color3.fromRGB(40, 0, 80) },
	{ Id = "Solaris",     Name = "Solaris",     Rarity = 6, Color = Color3.fromRGB(255, 170, 40) },
	{ Id = "Celestion",   Name = "Celestion",   Rarity = 7, Color = Color3.fromRGB(255, 250, 220) },
	{ Id = "Glitchling",  Name = "Glitchling",  Rarity = 7, Color = Color3.fromRGB(0, 255, 170) },
	{ Id = "Gigamog",     Name = "GIGAMOG",     Rarity = 8, Color = Color3.fromRGB(255, 255, 255) },
	-- Only from Rebirth 10:
	{ Id = "Phoenixmog",  Name = "Phoenixmog",  Rarity = 6, Color = Color3.fromRGB(255, 120, 40), Exclusive = true },
}

-- Levels. Chance is per monster. Mult boosts money AND the MOG you need.
local VARIANTS = {
	{ Name = "Normal",         Chance = nil,         Mult = 1 },
	{ Name = "Golden",         Chance = 1 / 25,      Mult = 2,   Color = Color3.fromRGB(255, 200, 40) },
	{ Name = "Diamond",        Chance = 1 / 150,     Mult = 4,   Color = Color3.fromRGB(170, 240, 255) },
	{ Name = "Rainbow",        Chance = 1 / 1000,    Mult = 8 },
	{ Name = "Cosmic",         Chance = 1 / 10000,   Mult = 20,  Color = Color3.fromRGB(50, 10, 100) },
	{ Name = "Rainbow Cosmic", Chance = 1 / 1000000, Mult = 100 },
}

-- Money Boost upgrade levels
local BOOST_MULTS = { 1, 1.5, 2, 3, 5, 8, 12, 20, 35, 60 }
local BOOST_BASE_COST = 200

----------------------------------------------------------------------
-- SERVICES, REMOTES, HELPERS
----------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
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
local SPECIES_PER_RARITY = {}
for _, def in ipairs(MONSTERS) do
	MONSTER_BY_ID[def.Id] = def
	if not def.Exclusive then
		SPECIES_PER_RARITY[def.Rarity] = (SPECIES_PER_RARITY[def.Rarity] or 0) + 1
	end
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
	return RARITIES[MONSTER_BY_ID[id].Rarity].Mog * VARIANTS[variant].Mult
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

-- Ground + hub (between the two rows of bases)
block(Vector3.new(980, 2, 520), CFrame.new(70, -1, 0), Color3.fromRGB(85, 165, 75), Enum.Material.Grass)
block(Vector3.new(330, 0.2, 100), CFrame.new(-180, 0.1, 0), Color3.fromRGB(165, 160, 150), Enum.Material.Cobblestone)

-- MOG ROAD with zones (along +X)
local ROAD_X0 = 0
local ZONE_LEN = 55
local ROAD_W = 44
local ROAD_END = ROAD_X0 + ZONE_LEN * #ZONES
block(Vector3.new(40, 0.4, ROAD_W), CFrame.new(-20, 0.2, 0), Color3.fromRGB(165, 160, 150), Enum.Material.Cobblestone)
local zoneInfo = {}
for k = 1, #ZONES do
	local rarity = RARITIES[k]
	local x0 = ROAD_X0 + (k - 1) * ZONE_LEN
	local floorPart = block(Vector3.new(ZONE_LEN, 0.4, ROAD_W), CFrame.new(x0 + ZONE_LEN / 2, 0.2, 0), rarity.Color:Lerp(Color3.fromRGB(40, 40, 50), 0.55), Enum.Material.Slate)
	floorPart.Name = "Zone" .. k
	-- side rails
	for _, z in ipairs({ -ROAD_W / 2, ROAD_W / 2 }) do
		local rail = block(Vector3.new(ZONE_LEN, 1.2, 0.8), CFrame.new(x0 + ZONE_LEN / 2, 1, z), rarity.Color, Enum.Material.Neon)
		rail.CanCollide = false
	end
	-- gate arch + barrier
	for _, z in ipairs({ -ROAD_W / 2 - 1, ROAD_W / 2 + 1 }) do
		block(Vector3.new(2, 18, 2), CFrame.new(x0, 9, z), Color3.fromRGB(45, 40, 60), Enum.Material.Basalt)
	end
	local top = block(Vector3.new(2, 4, ROAD_W + 4), CFrame.new(x0, 19, 0), Color3.fromRGB(45, 40, 60), Enum.Material.Basalt)
	local gateText = "ZONE " .. k .. ": " .. rarity.Name:upper() .. (k > 1 and ("  |  NEED " .. fmt(rarity.Mog) .. " MOG") or "")
	surfaceText(top, gateText, Enum.NormalId.Left).TextColor3 = rarity.Color
	surfaceText(top, gateText, Enum.NormalId.Right).TextColor3 = rarity.Color
	if k > 1 then
		local barrier = block(Vector3.new(0.4, 16, ROAD_W), CFrame.new(x0, 8, 0), rarity.Color, Enum.Material.ForceField)
		barrier.CanCollide = false
		barrier.CanQuery = false
		barrier.Transparency = 0.3
	end
	zoneInfo[k] = { X0 = x0, X1 = x0 + ZONE_LEN, Need = k == 1 and 0 or rarity.Mog }
end
local endWall = block(Vector3.new(2, 20, ROAD_W + 4), CFrame.new(ROAD_END + 1, 10, 0), Color3.fromRGB(45, 40, 60), Enum.Material.Basalt)
surfaceText(endWall, "MORE ZONES COMING SOON...", Enum.NormalId.Left)
local rushLabel = sign(Vector3.new(-12, 24, 0), "MOG ROAD", Color3.fromRGB(255, 80, 80))

local function zoneAtX(x)
	if x < ROAD_X0 then
		return 0
	end
	return math.clamp(math.floor((x - ROAD_X0) / ZONE_LEN) + 1, 1, #ZONES)
end

-- FUSION MACHINE
local fusionPos = Vector3.new(-170, 0, 0)
local fusionBase = block(Vector3.new(2, 16, 16), CFrame.new(fusionPos + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(50, 30, 80), Enum.Material.Metal)
fusionBase.Shape = Enum.PartType.Cylinder
local fusionCore = block(Vector3.new(6, 6, 6), CFrame.new(fusionPos + Vector3.new(0, 7, 0)), Color3.fromRGB(200, 80, 255), Enum.Material.ForceField)
fusionCore.Shape = Enum.PartType.Ball
fusionCore.CanCollide = false
local fusionPrompt = Instance.new("ProximityPrompt")
fusionPrompt.ActionText = "Fuse Monsters"
fusionPrompt.ObjectText = "Fusion Machine"
fusionPrompt.MaxActivationDistance = 16
fusionPrompt.RequiresLineOfSight = false
fusionPrompt.Parent = fusionCore
sign(fusionPos + Vector3.new(0, 14, 0), "FUSION MACHINE", Color3.fromRGB(200, 80, 255)).Text = "2 same monsters = next level!"

-- BASES (fenced pens in two rows next to the hub)
local PLOT_W, PLOT_D = 72, 64
local PLOT_COLORS = {
	Color3.fromRGB(255, 120, 120), Color3.fromRGB(120, 180, 255), Color3.fromRGB(140, 230, 140), Color3.fromRGB(255, 210, 110),
	Color3.fromRGB(210, 140, 255), Color3.fromRGB(120, 230, 230), Color3.fromRGB(255, 160, 210), Color3.fromRGB(220, 220, 220),
}
local SPOTS = {}
for row = 0, 2 do
	for col = 0, 4 do
		table.insert(SPOTS, { -24 + col * 12, -12 + row * 13 })
	end
end
local NORMAL_SPOTS = #SPOTS -- 15 (12 buyable + 3 from the Extra Slots pass)
local VAULT_SPOTS = 4
local VAULT_OFFSET = 100

local plots = {}
local playerPlot = {}

local function buildPlot(index)
	local north = index <= 4
	local col = (index - 1) % 4
	local center = Vector3.new(-300 + col * 80, 0, north and 88 or -88)
	local cf = CFrame.lookAt(center, center + Vector3.new(0, 0, north and -1 or 1)) -- -Z points at the hub
	local color = PLOT_COLORS[index]
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. index
	folder.Parent = map

	block(Vector3.new(PLOT_W, 1, PLOT_D), cf * CFrame.new(0, 0.5, 0), color:Lerp(Color3.fromRGB(110, 190, 90), 0.6), Enum.Material.Grass, folder)

	-- wooden fence with a gate at the front
	local wood = Color3.fromRGB(150, 105, 60)
	local fenceH = 5
	local function fenceLine(x1, z1, x2, z2)
		local a, b = Vector3.new(x1, 0, z1), Vector3.new(x2, 0, z2)
		local len = (b - a).Magnitude
		local mid = (a + b) / 2
		local dirCF = cf * CFrame.lookAt(mid, b)
		for _, h in ipairs({ 1.8, 3.8 }) do
			block(Vector3.new(0.5, 0.6, len), dirCF * CFrame.new(0, h, 0), wood, Enum.Material.WoodPlanks, folder)
		end
		local posts = math.max(1, math.floor(len / 6))
		for i = 0, posts do
			local p = a:Lerp(b, i / posts)
			block(Vector3.new(0.9, fenceH, 0.9), cf * CFrame.new(p.X, fenceH / 2 + 0.5, p.Z), wood:Lerp(Color3.new(0, 0, 0), 0.2), Enum.Material.Wood, folder)
		end
		-- invisible wall so nobody can just jump over
		local wall = block(Vector3.new(0.5, 10, len), dirCF * CFrame.new(0, 5.5, 0), wood, nil, folder)
		wall.Transparency = 1
	end
	local hw, hd, door = PLOT_W / 2, PLOT_D / 2, 8
	fenceLine(-hw, hd, hw, hd)
	fenceLine(-hw, -hd, -hw, hd)
	fenceLine(hw, -hd, hw, hd)
	fenceLine(-hw, -hd, -door, -hd)
	fenceLine(door, -hd, hw, -hd)

	local laser = block(Vector3.new(door * 2, 8, 0.5), cf * CFrame.new(0, 4.5, -hd), Color3.fromRGB(255, 30, 30), Enum.Material.Neon, folder)
	laser.CanCollide = false
	laser.Transparency = 1

	-- monster spots
	local pedestals = {}
	for i, spot in ipairs(SPOTS) do
		local ped = block(Vector3.new(0.6, 6, 6), cf * CFrame.new(spot[1], 1.3, spot[2]) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(235, 235, 240), Enum.Material.Marble, folder)
		ped.Shape = Enum.PartType.Cylinder
		ped.Name = "Spot"
		pedestals[i] = ped
	end
	block(Vector3.new(PLOT_W - 4, 1, 8), cf * CFrame.new(0, 1.5, 27), Color3.fromRGB(40, 60, 110), Enum.Material.DiamondPlate, folder)
	for i = 1, VAULT_SPOTS do
		local ped = block(Vector3.new(0.6, 6, 6), cf * CFrame.new(-24 + (i - 1) * 16, 2.3, 27) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(80, 160, 255), Enum.Material.Glass, folder)
		ped.Shape = Enum.PartType.Cylinder
		ped.Name = "VaultSpot"
		pedestals[VAULT_OFFSET + i] = ped
		local dome = block(Vector3.new(9, 9, 9), cf * CFrame.new(-24 + (i - 1) * 16, 6, 27), Color3.fromRGB(80, 160, 255), Enum.Material.ForceField, folder)
		dome.Shape = Enum.PartType.Ball
		dome.CanCollide = false
		dome.CanQuery = false
		dome.CanTouch = false
	end
	local vaultSign = block(Vector3.new(24, 3, 0.5), cf * CFrame.new(0, 11, hd - 0.5), Color3.fromRGB(40, 60, 110), nil, folder)
	surfaceText(vaultSign, "VAULT (can't be stolen)", Enum.NormalId.Front)

	local lockPad = block(Vector3.new(5, 0.4, 5), cf * CFrame.new(-30, 1.2, -27), Color3.fromRGB(255, 60, 60), Enum.Material.Neon, folder)
	surfaceText(lockPad, "LOCK")

	local signPart = block(Vector3.new(1, 1, 1), cf * CFrame.new(0, 12, -hd), color, nil, folder)
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
		Laser = laser, LockPad = lockPad, AlarmLight = alarmLight,
		NameLabel = labels[1], IncomeLabel = labels[2], StatusLabel = labels[3],
		LockUntil = 0, LockCooldownUntil = 0, AlarmUntil = 0,
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

-- DECORATIONS: lamps and trees
do
	local deco = Instance.new("Folder")
	deco.Name = "Decorations"
	deco.Parent = map
	for x = -330, -30, 50 do
		for _, z in ipairs({ -46, 46 }) do
			block(Vector3.new(0.8, 12, 0.8), CFrame.new(x, 6, z), Color3.fromRGB(40, 40, 50), Enum.Material.Metal, deco)
			local bulb = block(Vector3.new(2.2, 2.2, 2.2), CFrame.new(x, 12.6, z), Color3.fromRGB(255, 220, 150), Enum.Material.Neon, deco)
			bulb.Shape = Enum.PartType.Ball
			bulb.CanCollide = false
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 210, 140)
			light.Range = 28
			light.Parent = bulb
		end
	end
	local rng = Random.new(42)
	local placed = 0
	for _ = 1, 600 do
		if placed >= 80 then
			break
		end
		local pos = Vector3.new(rng:NextNumber(-400, 540), 0, rng:NextNumber(-250, 250))
		local inBases = pos.X > -350 and pos.X < -10 and math.abs(pos.Z) < 130
		local onRoad = pos.X > -40 and pos.X < ROAD_END + 20 and math.abs(pos.Z) < ROAD_W / 2 + 12
		if not inBases and not onRoad then
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
local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("MogMonsters_v1")
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
		Cash = CONFIG.START_CASH, MogLevel = 0, Boost = 0, Slots = CONFIG.START_SLOTS,
		Rebirths = 0, Steals = 0, Monsters = {}, Discovered = {}, LastDaily = 0, Streak = 0,
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

local function mogAtLevel(level, rebirths)
	return math.floor(10 * 1.5 ^ level) * (1 + rebirths)
end

local function playerMog(player)
	local data = sessions[player]
	if not data then
		return 0
	end
	return mogAtLevel(data.MogLevel, data.Rebirths)
end

local function updateStats(player)
	local data = sessions[player]
	local stats = player:FindFirstChild("leaderstats")
	if data and stats then
		stats.Cash.Value = math.floor(data.Cash)
		stats.MOG.Value = playerMog(player)
		stats.Rebirths.Value = data.Rebirths
	end
	if data then
		player:SetAttribute("Mog", playerMog(player))
	end
end

local function normalLimit(player)
	local data = sessions[player]
	local n = data and data.Slots or CONFIG.START_SLOTS
	if player:GetAttribute("ExtraSlots") then
		n = n + 3
	end
	return math.min(n, NORMAL_SPOTS)
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
	return math.min(n, VAULT_SPOTS)
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

local function rebirthCost(data)
	return CONFIG.REBIRTH_BASE_COST * CONFIG.REBIRTH_COST_MULT ^ data.Rebirths
end
local function slotCost(data)
	return CONFIG.SLOT_BASE_COST * 3 ^ (data.Slots - CONFIG.START_SLOTS)
end
local function mogCost(data)
	return math.floor(40 * 1.7 ^ data.MogLevel)
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
-- MONSTER OBJECTS
----------------------------------------------------------------------
local monstersByPart = {}
local carriers = {}
local laneMonsters = {}

local applyMovement
local onMonsterPrompt

local function setState(m, state)
	m.State = state
	m.Part:SetAttribute("State", state)
end

local function isVaultSlot(slot)
	return slot ~= nil and slot > VAULT_OFFSET
end

local function updateLabel(m)
	local info = m.InfoLabel
	if m.State == "Lane" then
		info.Text = "NEED " .. fmt(m.MogReq) .. " MOG  |  $" .. fmt(m.Income) .. "/s"
	elseif m.State == "Placed" or m.State == "Flying" then
		info.Text = "$" .. fmt(m.Income) .. "/s" .. (isVaultSlot(m.Slot) and "  (VAULT)" or "")
	elseif m.State == "Loose" then
		info.Text = "DROPPED! Grab it!"
	else
		info.Text = "STOLEN!"
	end
end

-- builds a cute monster out of parts (all welded to the body)
local function createMonster(id, variant)
	local def = MONSTER_BY_ID[id]
	local rarity = RARITIES[def.Rarity]
	local v = VARIANTS[variant]
	local s = 2.6 + def.Rarity * 0.45

	local body = Instance.new("Part")
	body.Name = "Monster"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(s, s, s)
	body.Color = v.Color or def.Color
	body.Material = (variant == 2 and Enum.Material.Foil) or (variant == 3 and Enum.Material.Glass) or Enum.Material.SmoothPlastic
	if variant >= 5 then
		body.Material = Enum.Material.Neon
	end
	body.Anchored = true
	body.CanCollide = false
	body.CustomPhysicalProperties = PhysicalProperties.new(1, 1, 0, 1, 1)
	body.CFrame = CFrame.new()

	local function deco(size, offset, color, material, shape)
		local p = Instance.new("Part")
		p.Name = "Deco"
		p.Shape = shape or Enum.PartType.Ball
		p.Size = size
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.Anchored = false
		p.CFrame = offset
		local w = Instance.new("WeldConstraint")
		w.Part0 = body
		w.Part1 = p
		w.Parent = p
		p.Parent = body
		return p
	end
	local white, black = Color3.new(1, 1, 1), Color3.fromRGB(20, 20, 20)
	for _, sx in ipairs({ -1, 1 }) do
		deco(Vector3.new(s * 0.32, s * 0.32, s * 0.32), CFrame.new(sx * s * 0.2, s * 0.15, -s * 0.38), white)
		deco(Vector3.new(s * 0.14, s * 0.14, s * 0.14), CFrame.new(sx * s * 0.2, s * 0.15, -s * 0.52), black)
		deco(Vector3.new(s * 0.3, s * 0.3, s * 0.3), CFrame.new(sx * s * 0.25, -s * 0.45, -s * 0.05), body.Color:Lerp(black, 0.4))
		if def.Rarity >= 3 then
			deco(Vector3.new(s * 0.14, s * 0.4, s * 0.14), CFrame.new(sx * s * 0.25, s * 0.52, 0) * CFrame.Angles(0, 0, -sx * 0.4), rarity.Color, Enum.Material.Neon, Enum.PartType.Block)
		end
	end
	deco(Vector3.new(s * 0.35, s * 0.08, s * 0.1), CFrame.new(0, -s * 0.08, -s * 0.48), black, nil, Enum.PartType.Block)
	if def.Rarity >= 5 then
		deco(Vector3.new(s * 0.5, s * 0.18, s * 0.5), CFrame.new(0, s * 0.55, 0), Color3.fromRGB(255, 210, 50), Enum.Material.Neon, Enum.PartType.Block)
	end

	if def.Rarity >= 5 or variant >= 4 then
		local light = Instance.new("PointLight")
		light.Color = rarity.Color
		light.Range = 8 + def.Rarity * 2
		light.Brightness = 2
		light.Parent = body
	end
	if variant >= 5 or def.Rarity >= 7 then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.new(1, 1, 1)
		sparkles.Parent = body
	end
	if def.Rarity >= 4 then
		local aura = Instance.new("ParticleEmitter")
		aura.Color = ColorSequence.new(rarity.Color)
		aura.LightEmission = 1
		aura.Rate = 4 + def.Rarity * 3
		aura.Lifetime = NumberRange.new(0.8, 1.4)
		aura.Speed = NumberRange.new(1, 2)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Size = NumberSequence.new(0.5, 0)
		aura.Parent = body
	end

	local _, labels = billboard(body, 250, 84, Vector3.new(0, s * 0.5 + 2.6, 0), 3)
	labels[1].Text = displayName(id, variant)
	labels[1].TextColor3 = variant > 1 and (v.Color or Color3.fromRGB(255, 120, 255)) or rarity.Color
	local odds = oddsOf(id, variant)
	labels[2].Text = rarity.Name .. ((odds > 1) and ("  |  1 in " .. fmt(odds)) or "")
	labels[2].TextColor3 = rarity.Color
	if def.Rarity >= 7 then
		labels[2].TextStrokeColor3 = Color3.new(1, 1, 1)
	end
	labels[3].Name = "MogLabel"
	labels[1].Parent.MaxDistance = 90

	local m = {
		Part = body, Id = id, Def = def, Variant = variant, State = "New",
		Income = monsterIncome(id, variant), MogReq = monsterMog(id, variant), Value = monsterValue(id, variant),
		InfoLabel = labels[3],
	}

	local prompts = {
		{ Name = "Mog", Action = "MOG IT!", Hold = 0.4 + def.Rarity * 0.2 },
		{ Name = "Steal", Action = "STEAL", Hold = 1 + def.Rarity * 0.4 },
		{ Name = "Sell", Action = "Sell $" .. fmt(m.Value * CONFIG.SELL_PERCENT), Hold = 1, Key = Enum.KeyCode.R },
		{ Name = "Vault", Action = "Move to/from Vault", Hold = 0.3 },
		{ Name = "Grab", Action = "Grab", Hold = 0.3 },
	}
	for _, info in ipairs(prompts) do
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = info.Name
		prompt.ActionText = info.Action
		prompt.ObjectText = displayName(id, variant)
		prompt.HoldDuration = info.Hold
		prompt.MaxActivationDistance = 12
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

local leaveZone -- defined below
local function destroyMonster(m)
	monstersByPart[m.Part] = nil
	if laneMonsters[m] then
		leaveZone(m)
	end
	if m.Plot and m.Plot.Slots[m.Slot] == m then
		m.Plot.Slots[m.Slot] = nil
	end
	m.Part:Destroy()
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

local function slotCFrame(plot, slot, m)
	local ped = plot.Pedestals[slot]
	local pos = ped.Position + Vector3.new(0, 0.3 + m.Part.Size.Y / 2 + 0.3, 0)
	return CFrame.new(pos) * plot.CF.Rotation -- face the gate
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

local function place(m, plot, slot, owner)
	plot.Slots[slot] = m
	m.Plot, m.Slot, m.Owner = plot, slot, owner
	m.HomeOwner, m.HomeSlot = nil, nil
	local part = m.Part
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = slotCFrame(plot, slot, m)
	part:SetAttribute("OwnerId", owner.UserId)
	part:SetAttribute("Slot", slot)
	setState(m, "Placed")
	updateLabel(m)
end

local function flyToSlot(m, plot, slot, owner)
	plot.Slots[slot] = m
	m.Plot, m.Slot, m.Owner = plot, slot, owner
	local part = m.Part
	part.Anchored = true
	part.CanCollide = false
	part:SetAttribute("OwnerId", owner.UserId)
	part:SetAttribute("Slot", slot)
	setState(m, "Flying")
	updateLabel(m)
	local tween = TweenService:Create(part, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = slotCFrame(plot, slot, m) })
	tween.Completed:Connect(function()
		if monsterAlive(m) and m.State == "Flying" and plot.Slots[slot] == m and owner.Parent then
			place(m, plot, slot, owner)
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
	part.CFrame = root.CFrame * CFrame.new(0, 3 + part.Size.Y / 2, 0)
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

local function returnHome(m)
	if not monsterAlive(m) then
		return
	end
	detach(m)
	local owner = m.HomeOwner
	local plot = owner and owner.Parent and playerPlot[owner]
	if plot then
		local slot = m.HomeSlot
		if not slot or plot.Slots[slot] then
			slot = freeSlot(plot, owner)
		end
		if slot then
			m.HomeOwner, m.HomeSlot = nil, nil
			flyToSlot(m, plot, slot, owner)
			return
		end
	end
	destroyMonster(m)
end

local function discover(player, m)
	local data = sessions[player]
	if data and not data.Discovered[m.Id] then
		data.Discovered[m.Id] = true
		notify(player, "NEW MONSTER DISCOVERED: " .. m.Def.Name .. "!")
	end
end

local function deliver(m, player, plot, slot)
	local victim = m.HomeOwner
	detach(m)
	place(m, plot, slot, player)
	discover(player, m)
	if victim and victim ~= player then
		local data = sessions[player]
		if data then
			data.Steals = data.Steals + 1
		end
		local name = displayName(m.Id, m.Variant)
		effect(m.Part.Position, Color3.fromRGB(255, 60, 60), "STOLEN!")
		notify(player, "You stole " .. name .. " from " .. victim.Name .. "!")
		if victim.Parent then
			notify(victim, player.Name .. " STOLE your " .. name .. "!")
		end
		if m.Def.Rarity >= 5 or m.Variant >= 3 then
			announce(player.Name .. " stole " .. victim.Name .. "'s " .. name .. "!")
		end
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
		return result.Position + Vector3.new(0, 2, 0)
	end
	return Vector3.new(position.X, 3, position.Z)
end

local function makeLoose(m, position)
	detach(m)
	local part = m.Part
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = CFrame.new(groundBelow(position))
	part:SetAttribute("OwnerId", 0)
	setState(m, "Loose")
	updateLabel(m)
	local token = {}
	m.LooseToken = token
	task.delay(CONFIG.LOOSE_TIME, function()
		if monsterAlive(m) and m.State == "Loose" and m.LooseToken == token then
			returnHome(m)
		end
	end)
end

-- give a player a brand new monster (daily, rebirth reward)
local function giveMonster(player, id, variant, fromPosition)
	local plot = playerPlot[player]
	if not plot then
		return false
	end
	local slot = freeSlot(plot, player) or freeVaultSlot(plot, player)
	if not slot then
		return false
	end
	local m = createMonster(id, variant)
	m.Part.CFrame = CFrame.new(fromPosition or (plot.CF.Position + Vector3.new(0, 50, 0)))
	flyToSlot(m, plot, slot, player)
	discover(player, m)
	return true
end

----------------------------------------------------------------------
-- MOVEMENT
----------------------------------------------------------------------
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
	hum.WalkSpeed = speed
end

----------------------------------------------------------------------
-- ZONE SPAWNING
----------------------------------------------------------------------
local zoneCount = {}
for k = 1, #ZONES do
	zoneCount[k] = 0
end

leaveZone = function(m)
	if laneMonsters[m] then
		laneMonsters[m] = nil
		zoneCount[m.Zone] = math.max(0, zoneCount[m.Zone] - 1)
	end
end

local function randomPointInZone(k)
	local z = zoneInfo[k]
	return Vector3.new(math.random() * (ZONE_LEN - 12) + z.X0 + 6, 0, (math.random() - 0.5) * (ROAD_W - 10))
end

local function spawnZoneMonster(k, id)
	id = id or randomSpecies(k)
	local variant = rollVariant()
	local m = createMonster(id, variant)
	local y = 0.4 + m.Part.Size.Y / 2 + 0.3
	local start = randomPointInZone(k)
	m.Part.CFrame = CFrame.new(start.X, y, start.Z)
	m.Zone = k
	m.GroundY = y
	m.Target = randomPointInZone(k)
	m.Pause = 0
	m.Walked = 0
	setState(m, "Lane")
	updateLabel(m)
	laneMonsters[m] = true
	zoneCount[k] = zoneCount[k] + 1
	effect(m.Part.Position, RARITIES[k].Color, nil)
	if k >= 6 or variant >= 4 or (k >= 5 and variant >= 2) then
		announce("A " .. RARITIES[k].Name:upper() .. " " .. displayName(id, variant) .. " appeared in ZONE " .. k .. "!")
	end
end

----------------------------------------------------------------------
-- MONSTER PROMPTS (Mog / Steal / Sell / Vault / Grab)
----------------------------------------------------------------------
local function isAlive(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

onMonsterPrompt = function(m, action, player)
	local data = sessions[player]
	local plot = playerPlot[player]
	if not data or not plot or not monsterAlive(m) or not isAlive(player) then
		return
	end
	local name = displayName(m.Id, m.Variant)

	if action == "Mog" then
		if m.State ~= "Lane" then
			return
		end
		local mog = playerMog(player)
		if mog < m.MogReq then
			notify(player, "Your MOG is too low! You have " .. fmt(mog) .. ", need " .. fmt(m.MogReq) .. ". Train MOG in UPGRADES!")
			return
		end
		local slot = freeSlot(plot, player)
		if not slot then
			notify(player, "Your base is full! Sell a monster or buy more spots (UPGRADES).")
			return
		end
		leaveZone(m)
		effect(m.Part.Position, RARITIES[m.Def.Rarity].Color, "MOGGED!")
		flyToSlot(m, plot, slot, player)
		discover(player, m)
		if m.Def.Rarity >= 5 or m.Variant >= 3 then
			announce(player.Name .. " MOGGED a " .. RARITIES[m.Def.Rarity].Name .. " " .. name .. "!")
		end

	elseif action == "Steal" then
		if m.State ~= "Placed" or m.Owner == player or carriers[player] or isVaultSlot(m.Slot) then
			return
		end
		if not freeSlot(plot, player) then
			notify(player, "Your base is full! Make room first.")
			return
		end
		local victim, fromPlot, fromSlot = m.Owner, m.Plot, m.Slot
		if not attachToCarrier(m, player) then
			return
		end
		fromPlot.Slots[fromSlot] = nil
		m.Plot, m.Slot, m.Owner = nil, nil, nil
		m.HomeOwner, m.HomeSlot = victim, fromSlot
		fromPlot.AlarmUntil = os.clock() + 10
		notify(player, "Run home or THROW it into your base! (F)")
		if victim and victim.Parent then
			alarmRemote:FireClient(victim, player.Name .. " is stealing your " .. name .. "!")
		end

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

	elseif action == "Vault" then
		if m.State ~= "Placed" or m.Owner ~= player then
			return
		end
		local target
		if isVaultSlot(m.Slot) then
			target = freeSlot(plot, player)
			if not target then
				notify(player, "No free spot outside the vault.")
				return
			end
		else
			target = freeVaultSlot(plot, player)
			if not target then
				notify(player, "Your vault is full! Rebirth or get Extra Vault for more.")
				return
			end
		end
		plot.Slots[m.Slot] = nil
		flyToSlot(m, plot, target, player)

	elseif action == "Grab" then
		if m.State ~= "Loose" or carriers[player] then
			return
		end
		if m.HomeOwner == player then
			returnHome(m)
			notify(player, "You got your " .. name .. " back!")
			return
		end
		if not freeSlot(plot, player) then
			notify(player, "Your base is full! Make room first.")
			return
		end
		attachToCarrier(m, player)
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
	if plot and plot.Owner and plot.Owner == m.HomeOwner then
		returnHome(m)
		return
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
				returnHome(m)
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
-- MOG SLAP (defense tool)
----------------------------------------------------------------------
local lastSlap = {}

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

local function slap(player)
	if lastSlap[player] and os.clock() - lastSlap[player] < 0.7 then
		return
	end
	lastSlap[player] = os.clock()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not isAlive(player) then
		return
	end
	local myPlot = playerPlot[player]
	for _, other in ipairs(Players:GetPlayers()) do
		local oroot = other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if oroot and isAlive(other) then
			local offset = oroot.Position - root.Position
			if offset.Magnitude < 10 and offset.Magnitude > 0 and root.CFrame.LookVector:Dot(offset.Unit) > 0.2 then
				local carrying = carriers[other]
				local intruder = myPlot ~= nil and plotAt(oroot.Position) == myPlot
				if carrying or intruder then
					local flat = Vector3.new(offset.X, 0, offset.Z)
					knockback(oroot, (flat.Magnitude > 0.1 and flat.Unit or root.CFrame.LookVector) * 55 + Vector3.new(0, 30, 0))
					effect(oroot.Position, Color3.fromRGB(255, 220, 60), "MOG SLAP!")
					if carrying then
						makeLoose(carrying, oroot.Position)
						notify(player, "You slapped " .. other.Name .. " and they DROPPED it!")
						notify(other, "You got MOG SLAPPED and dropped the monster!")
					end
				end
			end
		end
	end
end

local function giveSlap(player)
	local tool = Instance.new("Tool")
	tool.Name = "Mog Slap"
	tool.CanBeDropped = false
	tool.GripForward = Vector3.new(-1, 0, 0)
	tool.GripRight = Vector3.new(0, 1, 0)
	tool.GripUp = Vector3.new(0, 0, 1)
	tool.GripPos = Vector3.new(0, 0, -1)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1.2, 0.4, 2.4)
	handle.Color = Color3.fromRGB(255, 200, 60)
	handle.Material = Enum.Material.Neon
	handle.CanCollide = false
	handle.Parent = tool
	tool.Activated:Connect(function()
		slap(player)
	end)
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
-- REQUESTS FROM THE CLIENT (menus)
----------------------------------------------------------------------
local function myMonstersList(player)
	local plot = playerPlot[player]
	local list = {}
	if plot then
		for slot, m in pairs(plot.Slots) do
			if m.Owner == player and m.State == "Placed" then
				table.insert(list, {
					Slot = slot, Id = m.Id, Variant = m.Variant, Name = displayName(m.Id, m.Variant),
					Rarity = m.Def.Rarity, Income = m.Income, Value = m.Value, Vault = isVaultSlot(slot),
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
	local ready, wait = dailyStatus(data)
	return {
		Cash = data.Cash, Rebirths = data.Rebirths, RebirthCost = rebirthCost(data),
		Slots = normalLimit(player), BaseSlots = data.Slots, MaxSlots = CONFIG.MAX_SLOTS, SlotCost = slotCost(data),
		Vaults = vaultLimit(player), Mog = playerMog(player), MogCost = mogCost(data),
		NextMog = mogAtLevel(data.MogLevel + 1, data.Rebirths),
		Boost = BOOST_MULTS[data.Boost + 1], NextBoost = BOOST_MULTS[data.Boost + 2],
		BoostCost = BOOST_MULTS[data.Boost + 2] and boostCost(data) or nil,
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
		return false, "Those monsters are not in your base"
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
	if variant >= 4 then
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
	for slot, m in pairs(plot.Slots) do
		if not isVaultSlot(slot) and m.Owner == player then
			destroyMonster(m)
		end
	end
	data.Rebirths = data.Rebirths + 1
	data.Cash = CONFIG.START_CASH
	data.MogLevel = 0
	data.Boost = 0
	data.Slots = CONFIG.START_SLOTS
	refreshPedestals(plot)
	applyMovement(player)
	updateStats(player)
	announce(player.Name .. " reached REBIRTH " .. data.Rebirths .. "!")
	if data.Rebirths == 10 then
		giveMonster(player, "Phoenixmog", 2)
		announce(player.Name .. " unlocked the exclusive GOLDEN PHOENIXMOG!")
	end
	saveData(player)
	return true, "REBIRTH " .. data.Rebirths .. "! Your vault monsters were kept."
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

	elseif action == "TrainMog" then
		local cost = mogCost(data)
		if data.Cash < cost then
			return false, "You need $" .. fmt(cost)
		end
		data.Cash = data.Cash - cost
		data.MogLevel = data.MogLevel + 1
		updateStats(player)
		return true, "MOG is now " .. fmt(playerMog(player)) .. "!"

	elseif action == "BuyBoost" then
		if not BOOST_MULTS[data.Boost + 2] then
			return false, "Money Boost is max level!"
		end
		local cost = boostCost(data)
		if data.Cash < cost then
			return false, "You need $" .. fmt(cost)
		end
		data.Cash = data.Cash - cost
		data.Boost = data.Boost + 1
		updateStats(player)
		return true, "Money Boost is now x" .. BOOST_MULTS[data.Boost + 1] .. "!"

	elseif action == "BuySlot" then
		if data.Slots >= CONFIG.MAX_SLOTS then
			return false, "You have all spots!"
		end
		local cost = slotCost(data)
		if data.Cash < cost then
			return false, "You need $" .. fmt(cost)
		end
		data.Cash = data.Cash - cost
		data.Slots = data.Slots + 1
		refreshPedestals(plot)
		updateStats(player)
		return true, "New spot unlocked!"

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
	[CONFIG.VIP_PASS_ID] = "VIP",
	[CONFIG.EXTRA_SLOTS_PASS_ID] = "ExtraSlots",
	[CONFIG.FAST_STEAL_PASS_ID] = "FastSteal",
	[CONFIG.EXTRA_VAULT_PASS_ID] = "ExtraVault",
}
PASS_ATTRIBUTES[0] = nil

local function updateNameSign(player)
	local plot = playerPlot[player]
	if plot then
		plot.NameLabel.Text = (player:GetAttribute("VIP") and "[VIP] " or "") .. player.Name .. "'s Base"
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
		local amount = math.max(5000, math.floor((player:GetAttribute("Income") or 0) * 600))
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
		return plot.CF * CFrame.new(0, 4, -24)
	end
	return CFrame.new(0, 6, -30)
end

local function onCharacter(player, char)
	local hum = char:WaitForChild("Humanoid")
	char:WaitForChild("HumanoidRootPart")
	task.wait()
	char:PivotTo(spawnCFrame(player))
	applyMovement(player)
	giveSlap(player)
	hum.Died:Connect(function()
		local m = carriers[player]
		if m then
			returnHome(m)
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
	for _, name in ipairs({ "Cash", "MOG", "Rebirths" }) do
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
		for _, saved in ipairs(data.Monsters) do
			local slot = tonumber(saved.S)
			local variant = tonumber(saved.V) or 1
			if MONSTER_BY_ID[saved.Id] and VARIANTS[variant] and slot and plot.Pedestals[slot] and not plot.Slots[slot] then
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
	for _, m in pairs(monstersByPart) do
		if m.HomeOwner == player then
			m.HomeOwner = nil
		end
	end
	local plot = playerPlot[player]
	if plot then
		for _, m in pairs(plot.Slots) do
			destroyMonster(m)
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
	lastSlap[player] = nil
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

-- Spawning in every zone + monsters walking around
local zoneTimers = {}
for k = 1, #ZONES do
	zoneTimers[k] = (ZONES[k].Every or 0) * 0.8 -- first monsters come quickly
end
RunService.Heartbeat:Connect(function(dt)
	local rush = os.clock() < rushUntil
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
	for m in pairs(laneMonsters) do
		local pos = m.Part.Position
		if m.Pause > 0 then
			m.Pause = m.Pause - dt
		else
			local flat = Vector3.new(m.Target.X - pos.X, 0, m.Target.Z - pos.Z)
			if flat.Magnitude < 1 then
				m.Target = randomPointInZone(m.Zone)
				m.Pause = math.random() * 3
			else
				local step = flat.Unit * math.min(flat.Magnitude, CONFIG.WANDER_SPEED * dt)
				m.Walked = m.Walked + step.Magnitude
				local bob = math.abs(math.sin(m.Walked * 1.5)) * 0.6
				local newPos = Vector3.new(pos.X + step.X, m.GroundY + bob, pos.Z + step.Z)
				m.Part.CFrame = CFrame.lookAt(newPos, newPos + Vector3.new(step.X, 0, step.Z))
			end
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
				plot.IncomeLabel.Text = "$" .. fmt(income) .. "/s" .. (data.Rebirths > 0 and ("  |  Rebirth " .. data.Rebirths) or "")
				if now < plot.LockUntil then
					plot.StatusLabel.Text = "LOCKED " .. math.ceil(plot.LockUntil - now) .. "s"
				elseif now < plot.LockCooldownUntil then
					plot.StatusLabel.Text = "Lock ready in " .. math.ceil(plot.LockCooldownUntil - now) .. "s"
				else
					plot.StatusLabel.Text = "Unlocked"
				end
			end
			plot.Laser.Transparency = now < plot.LockUntil and 0.35 or 1
		end

		if now >= nextRush then
			rushUntil = now + CONFIG.RUSH_TIME
			nextRush = now + CONFIG.RUSH_EVERY
			announce("LUCKY RUSH! 3x luck and more monsters on the lane for 60 seconds!")
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

-- Fast loop: deliveries, locks, alarms
task.spawn(function()
	local flash = false
	while true do
		task.wait(0.2)
		local now = os.clock()
		flash = not flash

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

		-- zone gates: push players back if their MOG is too low
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and isAlive(player) then
				local here = zoneAtX(root.Position.X)
				local mog = playerMog(player)
				for k = 2, here do
					if mog < zoneInfo[k].Need then
						local z = math.clamp(root.Position.Z, -ROAD_W / 2 + 3, ROAD_W / 2 - 3)
						local back = Vector3.new(zoneInfo[k].X0 - 5, root.Position.Y + 1, z)
						char:PivotTo(CFrame.lookAt(back, back - Vector3.new(1, 0, 0)))
						notify(player, "You need " .. fmt(zoneInfo[k].Need) .. " MOG for ZONE " .. k .. "! Train MOG in UPGRADES.")
						break
					end
				end
			end
		end

		for _, plot in ipairs(plots) do
			plot.AlarmLight.Enabled = now < plot.AlarmUntil and flash
			if plot.Owner and now < plot.LockUntil then
				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= plot.Owner then
						local char = player.Character
						local root = char and char:FindFirstChild("HumanoidRootPart")
						if root and isAlive(player) and plotAt(root.Position) == plot then
							char:PivotTo(plot.CF * CFrame.new(0, 4, -PLOT_D / 2 - 10))
							notify(player, "This base is LOCKED!")
						end
					end
				end
			end
		end
	end
end)

print("MOG MONSTERS server v2 started OK!")
