--[[
	EGG HEIST: THROW & STEAL  -  GameServer
	========================================
	Put this as a *Script* in ServerScriptService.

	The script builds the whole map by itself and runs the game:
	  - Eggs ride along the Egg Road. Buy them, they earn cash in your base.
	  - Steal eggs from other bases.
	  - THROW a stolen egg into your own base (press F) instead of walking!
	  - Bonk thieves with your bat so they drop the egg.
	  - When an egg hatches it gives 2x cash and can unlock a SUPERPOWER.
	  - Lock your base for a short time.

	>>> ONLY CHANGE THINGS IN THE "CONFIG" SECTION BELOW <<<
]]

----------------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------------
local CONFIG = {
	START_CASH = 100,
	EGG_SPAWN_EVERY = 3,      -- seconds between new eggs on the road
	ROAD_SPEED = 8,           -- how fast the eggs move (studs per second)
	NORMAL_SLOTS = 9,         -- egg pedestals everyone gets
	VIP_SLOTS = 3,            -- extra pedestals for VIP
	LOCK_TIME = 45,           -- seconds the base is locked
	LOCK_COOLDOWN = 30,       -- seconds before you can lock again
	LOOSE_EGG_TIME = 15,      -- seconds a dropped egg lies on the ground
	RESPAWN_TIME = 3,
	THROW_POWER = 75,
	SELL_PERCENT = 0.5,       -- you get 50% of the price back when you sell
	CASH_PACK_AMOUNT = 25000,

	-- Paste your IDs here after you create them on create.roblox.com
	-- (0 = not set up yet, the button will just say "coming soon")
	VIP_PASS_ID = 0,          -- Game Pass: +3 egg slots + VIP tag
	DOUBLE_CASH_PASS_ID = 0,  -- Game Pass: 2x cash forever
	LUCKY_EGG_PRODUCT_ID = 0, -- Developer Product: Legendary or Mythic egg
	SUPER_LOCK_PRODUCT_ID = 0,-- Developer Product: lock base for 3 minutes
	CASH_PACK_PRODUCT_ID = 0, -- Developer Product: +25K cash
}

local RARITIES = {
	{ Name = "Common",    Weight = 62,  Color = Color3.fromRGB(200, 200, 200), HatchTime = 60 },
	{ Name = "Rare",      Weight = 24,  Color = Color3.fromRGB(70, 150, 255),  HatchTime = 120 },
	{ Name = "Epic",      Weight = 10,  Color = Color3.fromRGB(180, 90, 255),  HatchTime = 240 },
	{ Name = "Legendary", Weight = 3.5, Color = Color3.fromRGB(255, 200, 40),  HatchTime = 480 },
	{ Name = "Mythic",    Weight = 0.5, Color = Color3.fromRGB(255, 60, 120),  HatchTime = 900 },
}

-- Rarity: 1 = Common ... 5 = Mythic.  Income = cash per second.
local EGGS = {
	{ Id = "Pebble",  Name = "Pebble Egg",  Rarity = 1, Price = 25,     Income = 1,    Color = Color3.fromRGB(150, 140, 130) },
	{ Id = "Leafy",   Name = "Leafy Egg",   Rarity = 1, Price = 60,     Income = 2,    Color = Color3.fromRGB(90, 200, 90) },
	{ Id = "Bubble",  Name = "Bubble Egg",  Rarity = 1, Price = 120,    Income = 4,    Color = Color3.fromRGB(150, 220, 255) },
	{ Id = "Zap",     Name = "Zap Egg",     Rarity = 2, Price = 400,    Income = 10,   Color = Color3.fromRGB(255, 240, 60),  Power = "Speed" },
	{ Id = "Bouncy",  Name = "Bouncy Egg",  Rarity = 2, Price = 900,    Income = 20,   Color = Color3.fromRGB(255, 120, 200), Power = "Jump" },
	{ Id = "Frost",   Name = "Frost Egg",   Rarity = 3, Price = 2500,   Income = 50,   Color = Color3.fromRGB(180, 240, 255) },
	{ Id = "Muscle",  Name = "Muscle Egg",  Rarity = 3, Price = 6000,   Income = 110,  Color = Color3.fromRGB(230, 110, 60),  Power = "StrongArm" },
	{ Id = "Phantom", Name = "Phantom Egg", Rarity = 4, Price = 20000,  Income = 300,  Color = Color3.fromRGB(120, 255, 220), Power = "Ghost" },
	{ Id = "Titan",   Name = "Titan Egg",   Rarity = 4, Price = 50000,  Income = 650,  Color = Color3.fromRGB(120, 120, 140), Power = "IronGrip" },
	{ Id = "Cosmic",  Name = "Cosmic Egg",  Rarity = 5, Price = 200000, Income = 2000, Color = Color3.fromRGB(110, 40, 200) },
}

local POWERS = {
	Speed = "Super Speed",
	Jump = "Mega Jump",
	StrongArm = "Strong Arm (throw farther)",
	Ghost = "Ghost (walk through locked bases)",
	IronGrip = "Iron Grip (can't be bonked loose)",
}

----------------------------------------------------------------------
-- SERVICES & REMOTES
----------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

Players.CharacterAutoLoads = false

for key, value in pairs({
	VipPassId = CONFIG.VIP_PASS_ID,
	DoubleCashPassId = CONFIG.DOUBLE_CASH_PASS_ID,
	LuckyEggProductId = CONFIG.LUCKY_EGG_PRODUCT_ID,
	SuperLockProductId = CONFIG.SUPER_LOCK_PRODUCT_ID,
	CashPackProductId = CONFIG.CASH_PACK_PRODUCT_ID,
	CashPackAmount = CONFIG.CASH_PACK_AMOUNT,
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
local notifyRemote = remote("RemoteEvent", "Notify")     -- message to one player
local announceRemote = remote("RemoteEvent", "Announce") -- message to everyone
local throwRemote = remote("RemoteEvent", "Throw")
remotes.Parent = ReplicatedStorage

local function notify(player, text)
	notifyRemote:FireClient(player, text)
end

local function announce(text)
	announceRemote:FireAllClients(text)
end

local function fmt(n)
	n = math.floor(n)
	if n >= 1e9 then
		return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(n)
end

local EGG_BY_ID = {}
for _, def in ipairs(EGGS) do
	EGG_BY_ID[def.Id] = def
end

----------------------------------------------------------------------
-- MAP BUILDING
----------------------------------------------------------------------
local oldBaseplate = workspace:FindFirstChild("Baseplate")
if oldBaseplate then
	oldBaseplate:Destroy()
end

local map = Instance.new("Folder")
map.Name = "Map"
map.Parent = workspace
local eggFolder = Instance.new("Folder")
eggFolder.Name = "Eggs"
eggFolder.Parent = workspace

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
	gui.PixelsPerStud = 30
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

-- Ground
block(Vector3.new(420, 2, 320), CFrame.new(0, -1, 0), Color3.fromRGB(90, 170, 80), Enum.Material.Grass)

-- Egg Road (conveyor) along the X axis
local ROAD_START, ROAD_END = -185, 185
local EGG_Y = 1.2 + 1.9
local road = block(Vector3.new(ROAD_END - ROAD_START, 1.2, 14), CFrame.new(0, 0.6, 0), Color3.fromRGB(45, 45, 55), Enum.Material.DiamondPlate)
road.Name = "EggRoad"
for _, z in ipairs({ -7.5, 7.5 }) do
	block(Vector3.new(ROAD_END - ROAD_START, 2, 1), CFrame.new(0, 1, z), Color3.fromRGB(255, 200, 40), Enum.Material.Neon)
end
local roadSign = block(Vector3.new(30, 8, 1), CFrame.new(ROAD_START + 5, 6, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(30, 30, 40))
surfaceText(roadSign, "EGG ROAD", Enum.NormalId.Front)
surfaceText(roadSign, "EGG ROAD", Enum.NormalId.Back)

-- Bases
local PLOT_W, PLOT_D = 60, 50
local PLOT_COLORS = {
	Color3.fromRGB(255, 120, 120), Color3.fromRGB(120, 180, 255), Color3.fromRGB(140, 230, 140), Color3.fromRGB(255, 210, 110),
	Color3.fromRGB(210, 140, 255), Color3.fromRGB(120, 230, 230), Color3.fromRGB(255, 160, 210), Color3.fromRGB(200, 200, 200),
}

local plots = {}
local playerPlot = {} -- [player] = plot

local function buildPlot(index, center, rotation)
	local cf = CFrame.new(center) * CFrame.Angles(0, rotation, 0) -- looks toward the road (-Z local)
	local color = PLOT_COLORS[index]
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. index
	folder.Parent = map

	block(Vector3.new(PLOT_W, 1, PLOT_D), cf * CFrame.new(0, 0.5, 0), color:Lerp(Color3.new(1, 1, 1), 0.4), Enum.Material.SmoothPlastic, folder)
	local wallColor = color:Lerp(Color3.new(0, 0, 0), 0.25)
	block(Vector3.new(PLOT_W, 8, 1), cf * CFrame.new(0, 5, PLOT_D / 2 - 0.5), wallColor, nil, folder)
	block(Vector3.new(1, 8, PLOT_D), cf * CFrame.new(PLOT_W / 2 - 0.5, 5, 0), wallColor, nil, folder)
	block(Vector3.new(1, 8, PLOT_D), cf * CFrame.new(-PLOT_W / 2 + 0.5, 5, 0), wallColor, nil, folder)
	local doorW = 14
	local sideW = (PLOT_W - doorW) / 2
	for _, sx in ipairs({ -1, 1 }) do
		block(Vector3.new(sideW, 8, 1), cf * CFrame.new(sx * (doorW / 2 + sideW / 2), 5, -PLOT_D / 2 + 0.5), wallColor, nil, folder)
	end

	local laser = block(Vector3.new(doorW, 8, 0.5), cf * CFrame.new(0, 5, -PLOT_D / 2 + 0.5), Color3.fromRGB(255, 30, 30), Enum.Material.Neon, folder)
	laser.Name = "Laser"
	laser.CanCollide = false
	laser.Transparency = 1

	local pedestals = {}
	local total = CONFIG.NORMAL_SLOTS + CONFIG.VIP_SLOTS
	for i = 1, total do
		local row = (i - 1) // 6
		local col = (i - 1) % 6
		local vip = i > CONFIG.NORMAL_SLOTS
		local ped = block(Vector3.new(4, 2, 4), cf * CFrame.new(-22.5 + col * 9, 2, 4 + row * 12),
			vip and Color3.fromRGB(255, 200, 40) or Color3.fromRGB(235, 235, 240), Enum.Material.Marble, folder)
		ped.Name = vip and "VipPedestal" or "Pedestal"
		if vip then
			surfaceText(ped, "VIP", Enum.NormalId.Back)
		end
		table.insert(pedestals, ped)
	end

	local lockPad = block(Vector3.new(6, 0.4, 6), cf * CFrame.new(-22, 1.2, -18), Color3.fromRGB(255, 60, 60), Enum.Material.Neon, folder)
	lockPad.Name = "LockPad"
	surfaceText(lockPad, "LOCK")

	local signPart = block(Vector3.new(1, 1, 1), cf * CFrame.new(0, 12, -PLOT_D / 2), color, nil, folder)
	signPart.Transparency = 1
	signPart.CanCollide = false
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 260, 0, 70)
	bb.MaxDistance = 250
	bb.Parent = signPart
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = color
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Text = "Empty Base"
	nameLabel.Parent = bb
	local lockLabel = nameLabel:Clone()
	lockLabel.Size = UDim2.new(1, 0, 0.4, 0)
	lockLabel.Position = UDim2.new(0, 0, 0.6, 0)
	lockLabel.TextColor3 = Color3.new(1, 1, 1)
	lockLabel.Text = ""
	lockLabel.Parent = bb

	local plot = {
		Index = index, CF = cf, Owner = nil, Pedestals = pedestals, Slots = {},
		Laser = laser, LockPad = lockPad, NameLabel = nameLabel, LockLabel = lockLabel,
		LockUntil = 0, LockCooldownUntil = 0,
	}
	plots[index] = plot
	return plot
end

do
	local xs = { -112.5, -37.5, 37.5, 112.5 }
	local i = 0
	for _, x in ipairs(xs) do
		i = i + 1
		buildPlot(i, Vector3.new(x, 0, 55), 0)        -- north side, door faces the road
	end
	for _, x in ipairs(xs) do
		i = i + 1
		buildPlot(i, Vector3.new(x, 0, -55), math.pi) -- south side
	end
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

----------------------------------------------------------------------
-- PLAYER DATA
----------------------------------------------------------------------
local store = DataStoreService:GetDataStore("EggHeist_v1")
local sessions = {} -- [player] = data

local function loadData(player)
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return store:GetAsync("player_" .. player.UserId)
		end)
		if ok then
			local data = { Cash = CONFIG.START_CASH, Stolen = 0, Powers = {}, Eggs = {} }
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
	return { Cash = CONFIG.START_CASH, Stolen = 0, Powers = {}, Eggs = {}, NoSave = true }
end

local function saveData(player)
	local data = sessions[player]
	local plot = playerPlot[player]
	if not data or data.NoSave then
		return
	end
	local eggs = {}
	if plot then
		for slot, egg in pairs(plot.Slots) do
			if egg.Owner == player then
				table.insert(eggs, { Id = egg.Id, P = egg.Progress, H = egg.Hatched, S = slot })
			end
		end
	end
	local toSave = { Cash = data.Cash, Stolen = data.Stolen, Powers = data.Powers, Eggs = eggs }
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
		stats.Stolen.Value = data.Stolen
	end
end

local function hasPower(player, power)
	local data = sessions[player]
	return data ~= nil and data.Powers[power] == true
end

----------------------------------------------------------------------
-- EGGS
----------------------------------------------------------------------
local eggsByPart = {}  -- [part] = egg
local roadEggs = {}    -- [egg] = true
local carriers = {}    -- [player] = egg they carry

local applyMovement -- defined later

local function setState(egg, state)
	egg.State = state
	egg.Part:SetAttribute("State", state)
end

local function updateEggLabel(egg)
	local def = egg.Def
	local rarity = RARITIES[def.Rarity]
	local top = egg.Label
	local state = egg.State
	if state == "Road" then
		top.Text = "$" .. fmt(def.Price) .. "  |  +$" .. fmt(def.Income) .. "/s"
	elseif state == "Placed" or state == "Flying" then
		local mult = egg.Hatched and 2 or 1
		local hatchText
		if egg.Hatched then
			hatchText = "HATCHED x2"
		else
			hatchText = math.floor(egg.Progress / rarity.HatchTime * 100) .. "% hatched"
		end
		top.Text = "+$" .. fmt(def.Income * mult) .. "/s  |  " .. hatchText
	elseif state == "Loose" then
		top.Text = "DROPPED! Grab it!"
	else
		top.Text = "STOLEN!"
	end
end

local function styleHatched(egg)
	if egg.Part:FindFirstChild("HatchSparkles") then
		return
	end
	local s = Instance.new("Sparkles")
	s.Name = "HatchSparkles"
	s.SparkleColor = RARITIES[egg.Def.Rarity].Color
	s.Parent = egg.Part
end

local onEggPrompt -- defined later

local function createEgg(id)
	local def = EGG_BY_ID[id]
	local rarity = RARITIES[def.Rarity]

	local part = Instance.new("Part")
	part.Name = "Egg"
	part.Size = Vector3.new(3, 3.8, 3)
	part.Color = def.Color
	part.Material = def.Rarity >= 4 and Enum.Material.Neon or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CustomPhysicalProperties = PhysicalProperties.new(1, 1, 0, 1, 1)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	if def.Rarity >= 4 then
		local light = Instance.new("PointLight")
		light.Color = rarity.Color
		light.Range = 10
		light.Parent = part
	end

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 220, 0, 64)
	bb.StudsOffset = Vector3.new(0, 3.6, 0)
	bb.MaxDistance = 70
	bb.Parent = part
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextColor3 = rarity.Color
	nameLabel.Text = def.Name .. " (" .. rarity.Name .. ")"
	nameLabel.Parent = bb
	local infoLabel = nameLabel:Clone()
	infoLabel.Size = UDim2.new(1, 0, 0.45, 0)
	infoLabel.Position = UDim2.new(0, 0, 0.55, 0)
	infoLabel.TextColor3 = Color3.new(1, 1, 1)
	infoLabel.Parent = bb

	local prompts = {
		{ Name = "Buy", Action = "Buy $" .. fmt(def.Price), Hold = 0 },
		{ Name = "Steal", Action = "Steal", Hold = 0.5 + def.Rarity * 0.5 },
		{ Name = "Sell", Action = "Sell $" .. fmt(def.Price * CONFIG.SELL_PERCENT), Hold = 1 },
		{ Name = "Grab", Action = "Grab", Hold = 0.3 },
	}
	local egg = {
		Part = part, Id = id, Def = def, Label = infoLabel,
		Progress = 0, Hatched = false, State = "New",
	}
	for _, info in ipairs(prompts) do
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = info.Name
		prompt.ActionText = info.Action
		prompt.ObjectText = def.Name
		prompt.HoldDuration = info.Hold
		prompt.MaxActivationDistance = 11
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
		prompt.Triggered:Connect(function(player)
			onEggPrompt(egg, info.Name, player)
		end)
	end

	part:SetAttribute("OwnerId", 0)
	part:SetAttribute("State", "New")
	CollectionService:AddTag(part, "Egg")
	eggsByPart[part] = egg
	part.Parent = eggFolder
	return egg
end

local function destroyEgg(egg)
	eggsByPart[egg.Part] = nil
	roadEggs[egg] = nil
	if egg.Plot and egg.Plot.Slots[egg.Slot] == egg then
		egg.Plot.Slots[egg.Slot] = nil
	end
	egg.Part:Destroy()
end

local function eggAlive(egg)
	return eggsByPart[egg.Part] == egg
end

local function freeSlot(plot, player)
	for i = 1, #plot.Pedestals do
		if not plot.Slots[i] and (i <= CONFIG.NORMAL_SLOTS or player:GetAttribute("VIP")) then
			return i
		end
	end
	return nil
end

local function slotCFrame(plot, slot)
	local ped = plot.Pedestals[slot]
	return CFrame.new(ped.Position + Vector3.new(0, ped.Size.Y / 2 + 1.9, 0))
end

local function place(egg, plot, slot, owner)
	plot.Slots[slot] = egg
	egg.Plot, egg.Slot, egg.Owner = plot, slot, owner
	egg.HomeOwner, egg.HomeSlot = nil, nil
	local part = egg.Part
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = slotCFrame(plot, slot)
	part:SetAttribute("OwnerId", owner.UserId)
	setState(egg, "Placed")
	if egg.Hatched then
		styleHatched(egg)
	end
	updateEggLabel(egg)
end

local function flyToSlot(egg, plot, slot, owner)
	plot.Slots[slot] = egg -- reserve the pedestal
	egg.Plot, egg.Slot, egg.Owner = plot, slot, owner
	local part = egg.Part
	part.Anchored = true
	part.CanCollide = false
	part:SetAttribute("OwnerId", owner.UserId)
	setState(egg, "Flying")
	updateEggLabel(egg)
	local target = slotCFrame(plot, slot)
	local tween = TweenService:Create(part, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = target })
	tween.Completed:Connect(function()
		if eggAlive(egg) and egg.State == "Flying" and plot.Slots[slot] == egg and owner.Parent then
			place(egg, plot, slot, owner)
		end
	end)
	tween:Play()
end

local function attachToCarrier(egg, player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local part = egg.Part
	part.CanCollide = false
	part.Massless = true
	part.CFrame = root.CFrame * CFrame.new(0, 4.5, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	part.Anchored = false
	egg.Carrier = player
	carriers[player] = egg
	player:SetAttribute("Carrying", true)
	part:SetAttribute("OwnerId", 0)
	setState(egg, "Carried")
	updateEggLabel(egg)
	applyMovement(player)
	return true
end

local function detach(egg)
	local part = egg.Part
	local weld = part:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	part.Anchored = true
	part.Massless = false
	local carrier = egg.Carrier
	egg.Carrier = nil
	if carrier then
		carriers[carrier] = nil
		carrier:SetAttribute("Carrying", false)
		applyMovement(carrier)
	end
end

-- Send an egg back to the base it was stolen from
local function returnHome(egg)
	if not eggAlive(egg) then
		return
	end
	detach(egg)
	local owner = egg.HomeOwner
	local plot = owner and owner.Parent and playerPlot[owner]
	if plot then
		local slot = egg.HomeSlot
		if not slot or plot.Slots[slot] then
			slot = freeSlot(plot, owner)
		end
		if slot then
			egg.HomeOwner, egg.HomeSlot = nil, nil
			flyToSlot(egg, plot, slot, owner)
			return
		end
	end
	destroyEgg(egg) -- owner left the game: the egg vanishes
end

local function deliver(egg, player, plot, slot)
	local victim = egg.HomeOwner
	detach(egg)
	place(egg, plot, slot, player)
	if victim and victim ~= player then
		local data = sessions[player]
		if data then
			data.Stolen = data.Stolen + 1
			updateStats(player)
		end
		notify(player, "You stole a " .. egg.Def.Name .. "!")
		if victim.Parent then
			notify(victim, player.Name .. " stole your " .. egg.Def.Name .. "!")
		end
		if egg.Def.Rarity >= 4 then
			announce(player.Name .. " stole a " .. RARITIES[egg.Def.Rarity].Name .. " " .. egg.Def.Name .. "!")
		end
	end
end

local function groundBelow(position)
	local params = RaycastParams.new()
	local ignore = { eggFolder }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	params.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -100, 0), params)
	if result then
		return result.Position + Vector3.new(0, 1.9, 0)
	end
	return Vector3.new(position.X, EGG_Y, position.Z)
end

-- Egg lies on the ground: anyone can grab it
local function makeLoose(egg, position)
	detach(egg)
	local part = egg.Part
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = CFrame.new(groundBelow(position))
	part:SetAttribute("OwnerId", 0)
	setState(egg, "Loose")
	updateEggLabel(egg)
	local token = {}
	egg.LooseToken = token
	task.delay(CONFIG.LOOSE_EGG_TIME, function()
		if eggAlive(egg) and egg.State == "Loose" and egg.LooseToken == token then
			returnHome(egg)
		end
	end)
end

local function spawnRoadEgg(id)
	local egg = createEgg(id)
	egg.Part.CFrame = CFrame.new(ROAD_START, EGG_Y, 0)
	setState(egg, "Road")
	updateEggLabel(egg)
	roadEggs[egg] = true
	return egg
end

local function randomEggId(minRarity)
	minRarity = minRarity or 1
	local totalWeight = 0
	for r = minRarity, #RARITIES do
		totalWeight = totalWeight + RARITIES[r].Weight
	end
	local roll = math.random() * totalWeight
	local rarity = #RARITIES
	for r = minRarity, #RARITIES do
		roll = roll - RARITIES[r].Weight
		if roll <= 0 then
			rarity = r
			break
		end
	end
	local options = {}
	for _, def in ipairs(EGGS) do
		if def.Rarity == rarity then
			table.insert(options, def.Id)
		end
	end
	return options[math.random(1, #options)]
end

----------------------------------------------------------------------
-- EGG ACTIONS (Buy / Steal / Sell / Grab)
----------------------------------------------------------------------
local function isAlive(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

onEggPrompt = function(egg, action, player)
	local data = sessions[player]
	local plot = playerPlot[player]
	if not data or not plot or not eggAlive(egg) or not isAlive(player) then
		return
	end
	local def = egg.Def

	if action == "Buy" then
		if egg.State ~= "Road" then
			return
		end
		if data.Cash < def.Price then
			notify(player, "Not enough cash! You need $" .. fmt(def.Price))
			return
		end
		local slot = freeSlot(plot, player)
		if not slot then
			notify(player, "Your base is full! Sell an egg first.")
			return
		end
		data.Cash = data.Cash - def.Price
		updateStats(player)
		roadEggs[egg] = nil
		flyToSlot(egg, plot, slot, player)
		if def.Rarity >= 4 then
			announce(player.Name .. " bought a " .. RARITIES[def.Rarity].Name .. " " .. def.Name .. "!")
		end

	elseif action == "Steal" then
		if egg.State ~= "Placed" or egg.Owner == player or carriers[player] then
			return
		end
		if not freeSlot(plot, player) then
			notify(player, "Your base is full! Sell an egg first.")
			return
		end
		local victim = egg.Owner
		local fromPlot, fromSlot = egg.Plot, egg.Slot
		if not attachToCarrier(egg, player) then
			return
		end
		fromPlot.Slots[fromSlot] = nil
		egg.Plot, egg.Slot, egg.Owner = nil, nil, nil
		egg.HomeOwner, egg.HomeSlot = victim, fromSlot
		notify(player, "Run home or THROW it into your base! (F)")
		if victim and victim.Parent then
			notify(victim, "!! " .. player.Name .. " is stealing your " .. def.Name .. "! Bonk them!")
		end

	elseif action == "Sell" then
		if egg.State ~= "Placed" or egg.Owner ~= player then
			return
		end
		local amount = math.floor(def.Price * CONFIG.SELL_PERCENT)
		data.Cash = data.Cash + amount
		updateStats(player)
		destroyEgg(egg)
		notify(player, "Sold for $" .. fmt(amount))

	elseif action == "Grab" then
		if egg.State ~= "Loose" or carriers[player] then
			return
		end
		if egg.HomeOwner == player then
			returnHome(egg)
			notify(player, "You got your egg back!")
			return
		end
		if not freeSlot(plot, player) then
			notify(player, "Your base is full! Sell an egg first.")
			return
		end
		attachToCarrier(egg, player)
	end
end

----------------------------------------------------------------------
-- THROWING
----------------------------------------------------------------------
local lastThrow = {}

local function landed(egg, thrower)
	if not eggAlive(egg) or egg.State ~= "Thrown" then
		return
	end
	local pos = egg.Part.Position
	local plot = plotAt(pos)
	if plot and plot.Owner == thrower and thrower.Parent then
		local slot = freeSlot(plot, thrower)
		if slot then
			deliver(egg, thrower, plot, slot)
			return
		end
	end
	if plot and plot.Owner and plot.Owner == egg.HomeOwner then
		returnHome(egg)
		return
	end
	makeLoose(egg, pos)
end

throwRemote.OnServerEvent:Connect(function(player, direction)
	local egg = carriers[player]
	if not egg or typeof(direction) ~= "Vector3" then
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
	if flat.Magnitude < 0.1 or flat.Magnitude ~= flat.Magnitude then -- also catches NaN
		flat = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	end
	flat = flat.Unit

	detach(egg)
	setState(egg, "Thrown")
	updateEggLabel(egg)
	local part = egg.Part
	part.CFrame = CFrame.new(root.Position + Vector3.new(0, 4, 0) + flat * 3)
	part.CanCollide = true
	part.Anchored = false
	part:SetNetworkOwner(nil)
	local power = CONFIG.THROW_POWER * (hasPower(player, "StrongArm") and 1.5 or 1)
	part.AssemblyLinearVelocity = flat * power + Vector3.new(0, power * 0.9, 0)

	task.spawn(function()
		local start = os.clock()
		while eggAlive(egg) and egg.State == "Thrown" do
			task.wait(0.1)
			local t = os.clock() - start
			if part.Position.Y < -30 then
				returnHome(egg)
				return
			end
			if (t > 0.5 and part.AssemblyLinearVelocity.Magnitude < 4) or t > 5 then
				landed(egg, player)
				return
			end
		end
	end)
end)

----------------------------------------------------------------------
-- MOVEMENT & POWERS
----------------------------------------------------------------------
applyMovement = function(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local speed = 16
	if hasPower(player, "Speed") then
		speed = speed + 10
	end
	if carriers[player] then
		speed = speed - 4
	end
	hum.WalkSpeed = speed
	hum.UseJumpPower = true
	hum.JumpPower = hasPower(player, "Jump") and 75 or 50
end

local function unlockPower(player, power)
	local data = sessions[player]
	if not data or not power or data.Powers[power] then
		return
	end
	data.Powers[power] = true
	player:SetAttribute("Power_" .. power, true)
	applyMovement(player)
	notify(player, "NEW SUPERPOWER: " .. POWERS[power] .. "!")
end

----------------------------------------------------------------------
-- BONK BAT
----------------------------------------------------------------------
local lastBonk = {}

local function knockback(root, direction)
	local att = Instance.new("Attachment")
	att.Parent = root
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.MaxForce = 1e6
	lv.VectorVelocity = direction * 55 + Vector3.new(0, 30, 0)
	lv.Parent = root
	Debris:AddItem(lv, 0.15)
	Debris:AddItem(att, 0.15)
end

local function bonk(player)
	if lastBonk[player] and os.clock() - lastBonk[player] < 0.8 then
		return
	end
	lastBonk[player] = os.clock()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not isAlive(player) then
		return
	end
	for _, other in ipairs(Players:GetPlayers()) do
		local oroot = other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if oroot and isAlive(other) then
			local offset = oroot.Position - root.Position
			if offset.Magnitude < 9 and root.CFrame.LookVector:Dot(offset.Unit) > 0.2 then
				local flat = Vector3.new(offset.X, 0, offset.Z)
				knockback(oroot, flat.Magnitude > 0.1 and flat.Unit or root.CFrame.LookVector)
				local egg = carriers[other]
				if egg then
					if hasPower(other, "IronGrip") then
						notify(player, other.Name .. " has IRON GRIP!")
					else
						makeLoose(egg, oroot.Position)
						notify(player, "BONK! " .. other.Name .. " dropped the egg!")
						notify(other, "You got bonked and dropped the egg!")
					end
				end
			end
		end
	end
end

local function giveBat(player)
	local tool = Instance.new("Tool")
	tool.Name = "Bonk Bat"
	tool.CanBeDropped = false
	tool.GripForward = Vector3.new(-1, 0, 0)
	tool.GripRight = Vector3.new(0, 1, 0)
	tool.GripUp = Vector3.new(0, 0, 1)
	tool.GripPos = Vector3.new(0, 0, -1.5)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.7, 0.7, 4.5)
	handle.Color = Color3.fromRGB(150, 100, 50)
	handle.Material = Enum.Material.Wood
	handle.Parent = tool
	tool.Activated:Connect(function()
		bonk(player)
	end)
	tool.Parent = player:WaitForChild("Backpack")
end

----------------------------------------------------------------------
-- BASE LOCK
----------------------------------------------------------------------
local function lockBase(plot, seconds)
	local now = os.clock()
	plot.LockUntil = now + seconds
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
-- GAME PASSES & PRODUCTS
----------------------------------------------------------------------
local function grantPass(player, passId)
	if passId == 0 then
		return
	end
	if passId == CONFIG.VIP_PASS_ID then
		player:SetAttribute("VIP", true)
		local plot = playerPlot[player]
		if plot then
			plot.NameLabel.Text = "[VIP] " .. player.Name .. "'s Base"
		end
	elseif passId == CONFIG.DOUBLE_CASH_PASS_ID then
		player:SetAttribute("DoubleCash", true)
	end
end

local function checkPasses(player)
	for _, passId in ipairs({ CONFIG.VIP_PASS_ID, CONFIG.DOUBLE_CASH_PASS_ID }) do
		if passId ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			if ok and owns then
				grantPass(player, passId)
			end
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
		data.Cash = data.Cash + CONFIG.CASH_PACK_AMOUNT
		notify(player, "+$" .. fmt(CONFIG.CASH_PACK_AMOUNT) .. "!")

	elseif receipt.ProductId == CONFIG.SUPER_LOCK_PRODUCT_ID then
		lockBase(plot, 180)
		notify(player, "SUPER LOCK! Your base is locked for 3 minutes.")

	elseif receipt.ProductId == CONFIG.LUCKY_EGG_PRODUCT_ID then
		local id = randomEggId(4)
		local def = EGG_BY_ID[id]
		local slot = freeSlot(plot, player)
		if slot then
			local egg = createEgg(id)
			egg.Part.CFrame = slotCFrame(plot, slot) + Vector3.new(0, 40, 0)
			flyToSlot(egg, plot, slot, player)
			announce(player.Name .. " opened a LUCKY EGG and got a " .. RARITIES[def.Rarity].Name .. " " .. def.Name .. "!")
		else
			data.Cash = data.Cash + def.Price
			notify(player, "Base full! You got $" .. fmt(def.Price) .. " instead.")
		end

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
		return plot.CF * CFrame.new(0, 4, 12)
	end
	return CFrame.new(0, 6, 20)
end

local function onCharacter(player, char)
	local hum = char:WaitForChild("Humanoid")
	char:WaitForChild("HumanoidRootPart")
	task.wait()
	char:PivotTo(spawnCFrame(player))
	applyMovement(player)
	giveBat(player)
	hum.Died:Connect(function()
		local egg = carriers[player]
		if egg then
			returnHome(egg)
		end
		task.wait(CONFIG.RESPAWN_TIME)
		if player.Parent then
			player:LoadCharacter()
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
	for _, name in ipairs({ "Cash", "Stolen" }) do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = stats
	end
	stats.Parent = player
	updateStats(player)

	for power in pairs(data.Powers) do
		player:SetAttribute("Power_" .. power, true)
	end

	-- Give the player a free base
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
		plot.NameLabel.Text = player.Name .. "'s Base"
		plot.LockUntil, plot.LockCooldownUntil = 0, 0
	end

	checkPasses(player)

	if plot then
		for _, saved in ipairs(data.Eggs) do
			local def = EGG_BY_ID[saved.Id]
			local slot = tonumber(saved.S)
			if def and slot and plot.Pedestals[slot] and not plot.Slots[slot] then
				local egg = createEgg(saved.Id)
				egg.Progress = saved.P or 0
				egg.Hatched = saved.H == true
				place(egg, plot, slot, player)
			end
		end
	end

	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	player:LoadCharacter()

	if not plot then
		notify(player, "Server is full of bases, try another server!")
	elseif data.NoSave then
		notify(player, "Saving is OFF (turn on API access in Game Settings).")
	else
		notify(player, "Buy eggs on the Egg Road, steal from others and THROW them home!")
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
	for _, egg in pairs(eggsByPart) do
		if egg.HomeOwner == player then
			egg.HomeOwner = nil
		end
	end
	local plot = playerPlot[player]
	if plot then
		for _, egg in pairs(plot.Slots) do
			destroyEgg(egg)
		end
		plot.Slots = {}
		plot.Owner = nil
		plot.NameLabel.Text = "Empty Base"
		plot.LockUntil, plot.LockCooldownUntil = 0, 0
	end
	playerPlot[player] = nil
	sessions[player] = nil
	lastThrow[player] = nil
	lastBonk[player] = nil
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
-- Move road eggs + spawn new ones
local spawnTimer = 0
RunService.Heartbeat:Connect(function(dt)
	spawnTimer = spawnTimer + dt
	if spawnTimer >= CONFIG.EGG_SPAWN_EVERY then
		spawnTimer = 0
		spawnRoadEgg(randomEggId())
	end
	local move = Vector3.new(CONFIG.ROAD_SPEED * dt, 0, 0)
	for egg in pairs(roadEggs) do
		local part = egg.Part
		part.CFrame = (part.CFrame + move) * CFrame.Angles(0, dt, 0)
		if part.Position.X > ROAD_END then
			destroyEgg(egg)
		end
	end
end)

-- Every second: cash, hatching, lock signs
task.spawn(function()
	while true do
		task.wait(1)
		local now = os.clock()
		for _, plot in ipairs(plots) do
			local owner = plot.Owner
			local data = owner and sessions[owner]
			if data then
				local income = 0
				for _, egg in pairs(plot.Slots) do
					if egg.State == "Placed" and egg.Owner == owner then
						egg.Progress = egg.Progress + 1
						if not egg.Hatched and egg.Progress >= RARITIES[egg.Def.Rarity].HatchTime then
							egg.Hatched = true
							styleHatched(egg)
							notify(owner, "Your " .. egg.Def.Name .. " HATCHED! 2x cash!")
							if egg.Def.Power then
								unlockPower(owner, egg.Def.Power)
							end
						end
						income = income + egg.Def.Income * (egg.Hatched and 2 or 1)
						updateEggLabel(egg)
					end
				end
				if owner:GetAttribute("DoubleCash") then
					income = income * 2
				end
				data.Cash = data.Cash + income
				updateStats(owner)
			end

			local locked = now < plot.LockUntil
			plot.Laser.Transparency = locked and 0.35 or 1
			if not owner then
				plot.LockLabel.Text = ""
			elseif locked then
				plot.LockLabel.Text = "LOCKED " .. math.ceil(plot.LockUntil - now) .. "s"
			elseif now < plot.LockCooldownUntil then
				plot.LockLabel.Text = "Lock ready in " .. math.ceil(plot.LockCooldownUntil - now) .. "s"
			else
				plot.LockLabel.Text = "Unlocked"
			end
		end
	end
end)

-- Fast checks: deliver carried eggs, kick intruders out of locked bases
task.spawn(function()
	while true do
		task.wait(0.2)
		for player, egg in pairs(carriers) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local plot = playerPlot[player]
			if root and plot and plotAt(root.Position) == plot then
				local slot = freeSlot(plot, player)
				if slot then
					deliver(egg, player, plot, slot)
				end
			end
		end

		local now = os.clock()
		for _, plot in ipairs(plots) do
			if plot.Owner and now < plot.LockUntil then
				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= plot.Owner and not hasPower(player, "Ghost") then
						local char = player.Character
						local root = char and char:FindFirstChild("HumanoidRootPart")
						if root and plotAt(root.Position) == plot then
							char:PivotTo(plot.CF * CFrame.new(0, 4, -PLOT_D / 2 - 8))
							notify(player, "This base is LOCKED!")
						end
					end
				end
			end
		end
	end
end)
