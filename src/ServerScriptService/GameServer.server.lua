--[[
	FLOOR IS LAVA OBBY  -  GameServer
	==================================
	Put this as a *Script* in ServerScriptService.

	The script builds the whole obby by itself when the game starts,
	and handles: checkpoints, coins, saving, shop, game passes and
	developer products (things you buy with Robux).

	>>> ONLY CHANGE THINGS IN THE "CONFIG" SECTION BELOW <<<
]]

----------------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------------
local CONFIG = {
	TOTAL_STAGES = 30,       -- how many stages the obby has
	SEED = 2026,             -- change this number to get a different obby layout

	COIN_VALUE = 5,          -- coins for picking up one coin
	STAGE_BONUS = 10,        -- coins for reaching a new checkpoint
	FINISH_BONUS = 150,      -- coins for finishing the whole obby
	COIN_RESPAWN = 45,       -- seconds before the same player can take a coin again

	RESPAWN_TIME = 1.5,      -- seconds before you respawn after dying
	SPEED_PASS_WALKSPEED = 24,

	-- Paste your IDs here after you create them on create.roblox.com
	-- (0 = not set up yet, the button will just say "coming soon")
	VIP_PASS_ID = 0,         -- Game Pass: 2x coins + Rainbow trail
	SPEED_PASS_ID = 0,       -- Game Pass: run faster
	SKIP_STAGE_PRODUCT_ID = 0, -- Developer Product: skip one stage
	COINS_PRODUCT_ID = 0,    -- Developer Product: +500 coins
	COINS_PRODUCT_AMOUNT = 500,
}

-- Trails you can buy with coins in the shop
local TRAILS = {
	{ Name = "Red",     Price = 100,  Colors = { Color3.fromRGB(255, 60, 60) } },
	{ Name = "Blue",    Price = 300,  Colors = { Color3.fromRGB(60, 140, 255) } },
	{ Name = "Toxic",   Price = 750,  Colors = { Color3.fromRGB(120, 255, 60), Color3.fromRGB(20, 120, 20) } },
	{ Name = "Galaxy",  Price = 1500, Colors = { Color3.fromRGB(140, 60, 255), Color3.fromRGB(20, 20, 80), Color3.fromRGB(255, 120, 255) } },
	{ Name = "Rainbow", Price = 0, VipOnly = true, Colors = {
		Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 160, 0), Color3.fromRGB(255, 255, 0),
		Color3.fromRGB(0, 220, 0), Color3.fromRGB(0, 120, 255), Color3.fromRGB(170, 0, 255),
	} },
}

----------------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

Players.CharacterAutoLoads = false

-- Share the IDs with the client script (so you only type them once)
ReplicatedStorage:SetAttribute("VipPassId", CONFIG.VIP_PASS_ID)
ReplicatedStorage:SetAttribute("SpeedPassId", CONFIG.SPEED_PASS_ID)
ReplicatedStorage:SetAttribute("SkipStageProductId", CONFIG.SKIP_STAGE_PRODUCT_ID)
ReplicatedStorage:SetAttribute("CoinsProductId", CONFIG.COINS_PRODUCT_ID)
ReplicatedStorage:SetAttribute("CoinsProductAmount", CONFIG.COINS_PRODUCT_AMOUNT)
ReplicatedStorage:SetAttribute("TotalStages", CONFIG.TOTAL_STAGES)

-- Remotes (how client and server talk)
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local shopRemote = Instance.new("RemoteFunction")
shopRemote.Name = "Shop"
shopRemote.Parent = remotes
local coinRemote = Instance.new("RemoteEvent")
coinRemote.Name = "CoinCollected"
coinRemote.Parent = remotes
local notifyRemote = Instance.new("RemoteEvent")
notifyRemote.Name = "Notify"
notifyRemote.Parent = remotes
remotes.Parent = ReplicatedStorage

local function notify(player, text)
	notifyRemote:FireClient(player, text)
end

----------------------------------------------------------------------
-- WORLD / MAP BUILDING
----------------------------------------------------------------------
local LAVA_COLOR = Color3.fromRGB(255, 80, 0)
local PAD_COLOR = Color3.fromRGB(70, 200, 90)
local STAGE_COLORS = {
	Color3.fromRGB(240, 240, 240), Color3.fromRGB(120, 180, 255),
	Color3.fromRGB(255, 220, 90), Color3.fromRGB(200, 130, 255),
	Color3.fromRGB(110, 230, 210), Color3.fromRGB(255, 150, 190),
}

-- Remove the default baseplate so the lava is the floor
local oldBaseplate = workspace:FindFirstChild("Baseplate")
if oldBaseplate then
	oldBaseplate:Destroy()
end

Lighting.ClockTime = 17.2
Lighting.Brightness = 2

local map = Instance.new("Folder")
map.Name = "ObbyMap"

local rng = Random.new(CONFIG.SEED)
local checkpoints = {} -- [stageNumber] = part
local spinners = {}    -- spinning lava bars

local function block(size, cframe, color, material, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function lava(size, cframe, parent)
	local p = block(size, cframe, LAVA_COLOR, Enum.Material.Neon, parent)
	p.Name = "Lava"
	CollectionService:AddTag(p, "Lava")
	return p
end

-- "top" = a point on the TOP surface where the part should be centered
local function platform(size, top, color, parent)
	return block(size, CFrame.new(top - Vector3.new(0, size.Y / 2, 0)), color, nil, parent)
end

local function addCoin(position, parent)
	local c = Instance.new("Part")
	c.Name = "Coin"
	c.Shape = Enum.PartType.Cylinder
	c.Size = Vector3.new(0.4, 2.5, 2.5)
	c.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(90), 0)
	c.Color = Color3.fromRGB(255, 205, 40)
	c.Material = Enum.Material.Neon
	c.Anchored = true
	c.CanCollide = false
	c.Parent = parent
	CollectionService:AddTag(c, "Coin")
	return c
end

local function addSign(part, text, face)
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
end

-- Every obstacle builder gets "s" = the point where it starts
-- (top surface, front edge of the previous checkpoint) and returns
-- the point where the next checkpoint should start.

local function buildJumps(folder, s, d)
	local count = 4 + math.min(d, 6)
	local size = math.max(3, 5 - d * 0.08)
	local color = STAGE_COLORS[(d % #STAGE_COLORS) + 1]
	local z, y = s.Z, s.Y
	for i = 1, count do
		local gap = rng:NextNumber(3, 4 + math.min(d, 10) * 0.2)
		z = z + gap + size / 2
		y = y + rng:NextNumber(-0.5, 1)
		local x = s.X + rng:NextNumber(-2, 2)
		local p = platform(Vector3.new(size, 1, size), Vector3.new(x, y, z), color, folder)
		if rng:NextNumber() < 0.25 then
			addCoin(p.Position + Vector3.new(0, 3.5, 0), folder)
		end
		z = z + size / 2
	end
	return Vector3.new(s.X, y, z + 4)
end

local function buildLavaStripes(folder, s, d)
	local width = math.max(5, 10 - d * 0.15)
	local stripes = 4 + math.floor(d / 4)
	local length = stripes * 8 + 4
	local walk = platform(Vector3.new(width, 1, length), s + Vector3.new(0, 0, length / 2), Color3.fromRGB(90, 90, 100), folder)
	walk.Material = Enum.Material.Slate
	for i = 1, stripes do
		local thick = rng:NextNumber(2, math.min(5, 2.5 + d * 0.12))
		local z = s.Z + i * 8
		lava(Vector3.new(width, 0.4, thick), CFrame.new(s.X, s.Y + 0.2, z), folder)
	end
	addCoin(s + Vector3.new(0, 5, length / 2), folder)
	return s + Vector3.new(0, 0, length)
end

local function buildDisappearing(folder, s, d)
	local count = 5 + math.min(d, 5)
	local z = s.Z
	for i = 1, count do
		z = z + rng:NextNumber(3, 4.5) + 2.5
		local x = s.X + rng:NextNumber(-1.5, 1.5)
		local p = platform(Vector3.new(5, 1, 5), Vector3.new(x, s.Y, z), Color3.fromRGB(150, 220, 255), folder)
		p.Material = Enum.Material.Glass
		p.Transparency = 0.15
		CollectionService:AddTag(p, "Disappearing")
		z = z + 2.5
	end
	return Vector3.new(s.X, s.Y, z + 4)
end

local function buildSpinner(folder, s, d)
	local radius = 14
	local center = s + Vector3.new(0, 0, radius)
	local disc = block(
		Vector3.new(1, radius * 2, radius * 2),
		CFrame.new(center - Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(60, 60, 70), Enum.Material.Metal, folder
	)
	disc.Shape = Enum.PartType.Cylinder

	local hub = block(Vector3.new(2, 3, 2), CFrame.new(center + Vector3.new(0, 1.5, 0)), Color3.fromRGB(30, 30, 30), Enum.Material.Metal, folder)
	hub.CanCollide = false

	local speed = math.min(3.2, 1.2 + d * 0.06)
	local bars = d >= 12 and 2 or 1
	for b = 1, bars do
		local bar = lava(Vector3.new(radius * 2 - 2, 1, 1), CFrame.new(center + Vector3.new(0, 1, 0)), folder)
		CollectionService:RemoveTag(bar, "Lava") -- handled by the spinner loop instead
		bar.CanCollide = false
		table.insert(spinners, {
			Part = bar,
			Center = CFrame.new(center + Vector3.new(0, 1, 0)),
			Speed = speed * (b == 1 and 1 or -0.8),
			Angle = (b - 1) * math.pi / 2,
		})
	end
	addCoin(center + Vector3.new(0, 6, 0), folder)
	return s + Vector3.new(0, 0, radius * 2)
end

local function buildTightrope(folder, s, d)
	local segments = 4 + math.floor(d / 5)
	local width = math.max(1, 2 - d * 0.03)
	local from = s
	local side = 1
	for i = 1, segments do
		local to = Vector3.new(s.X + 4 * side, s.Y, from.Z + 8)
		if i == segments then
			to = Vector3.new(s.X, s.Y, from.Z + 8)
		end
		local mid = (from + to) / 2
		local len = (to - from).Magnitude + width
		block(
			Vector3.new(width, 1, len),
			CFrame.lookAt(mid, mid + (to - from)) * CFrame.new(0, -0.5, 0),
			Color3.fromRGB(150, 100, 60), Enum.Material.Wood, folder
		)
		from = to
		side = -side
	end
	addCoin(s + Vector3.new(0, 4, (from.Z - s.Z) / 2), folder)
	return Vector3.new(s.X, s.Y, from.Z + 1)
end

local function buildClimb(folder, s, d)
	local height = 8 + math.min(d, 14)
	local truss = Instance.new("TrussPart")
	truss.Anchored = true
	truss.Size = Vector3.new(2, height, 2)
	truss.CFrame = CFrame.new(s + Vector3.new(0, height / 2, 4))
	truss.Color = Color3.fromRGB(80, 80, 80)
	truss.Parent = folder
	-- floor in front of the truss so you can walk to it
	platform(Vector3.new(4, 1, 3), s + Vector3.new(0, 0, 1.5), Color3.fromRGB(90, 90, 100), folder)
	-- lava blocks next to the truss to make it scary
	lava(Vector3.new(2, 2, 2), CFrame.new(s + Vector3.new(-4.5, height * 0.5, 4)), folder)
	lava(Vector3.new(2, 2, 2), CFrame.new(s + Vector3.new(4.5, height * 0.75, 4)), folder)
	local top = s + Vector3.new(0, height, 0)
	platform(Vector3.new(6, 1, 6), top + Vector3.new(0, 0, 8), Color3.fromRGB(90, 90, 100), folder)
	addCoin(top + Vector3.new(0, 3, 8), folder)
	return top + Vector3.new(0, 0, 15)
end

local BUILDERS = { buildJumps, buildLavaStripes, buildDisappearing, buildSpinner, buildTightrope, buildClimb }

local function makeCheckpoint(stage, edge, isFinish)
	local size = isFinish and Vector3.new(24, 1, 24) or Vector3.new(12, 1, 12)
	local pad = platform(size, edge + Vector3.new(0, 0, size.Z / 2), isFinish and Color3.fromRGB(255, 200, 40) or PAD_COLOR, map)
	pad.Name = "Checkpoint" .. stage
	pad.Material = Enum.Material.Neon
	pad:SetAttribute("Stage", stage)
	addSign(pad, isFinish and "FINISH!" or tostring(stage))
	checkpoints[stage] = pad
	return edge + Vector3.new(0, 0, size.Z)
end

local function buildMap()
	-- Lobby (stage 0)
	local lobby = platform(Vector3.new(40, 1, 40), Vector3.new(0, 0, 0), Color3.fromRGB(70, 70, 80), map)
	lobby.Name = "Lobby"
	lobby.Material = Enum.Material.Slate

	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 0.5, -10)
	spawn.Color = PAD_COLOR
	spawn.Material = Enum.Material.Neon
	spawn.Duration = 0 -- no forcefield
	spawn.Parent = map
	checkpoints[0] = spawn

	local sign = block(Vector3.new(30, 10, 1), CFrame.new(0, 7, -19.5), Color3.fromRGB(30, 30, 30), nil, map)
	addSign(sign, "FLOOR IS LAVA OBBY", Enum.NormalId.Front)
	addSign(sign, "FLOOR IS LAVA OBBY", Enum.NormalId.Back)

	for i = -1, 1 do
		addCoin(Vector3.new(i * 8, 3, 8), map)
	end

	local edge = Vector3.new(0, 0, 20)
	for stage = 1, CONFIG.TOTAL_STAGES do
		local folder = Instance.new("Folder")
		folder.Name = "Stage" .. stage
		folder.Parent = map

		-- Easy stages first, then random mix
		local builder
		if stage <= #BUILDERS then
			builder = BUILDERS[stage]
		else
			builder = BUILDERS[rng:NextInteger(1, #BUILDERS)]
		end
		local finish = builder(folder, edge, stage)
		edge = makeCheckpoint(stage, finish, stage == CONFIG.TOTAL_STAGES)
	end

	-- The lava lake under everything (tiled, because parts max out at 2048 studs)
	local length = edge.Z + 80
	local tile = 2000
	local z = -60
	while z < length do
		local l = lava(Vector3.new(600, 2, tile), CFrame.new(0, -25, z + tile / 2), map)
		l.Material = Enum.Material.Neon
		z = z + tile
	end

	map.Parent = workspace
end

buildMap()

----------------------------------------------------------------------
-- PLAYER DATA (saving)
----------------------------------------------------------------------
local store = DataStoreService:GetDataStore("FloorIsLavaObby_v1")
local sessions = {} -- [player] = data table

local function defaultData()
	return { Stage = 0, Coins = 0, Wins = 0, Owned = {}, Equipped = "None" }
end

local function loadData(player)
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return store:GetAsync("player_" .. player.UserId)
		end)
		if ok then
			local data = defaultData()
			if type(result) == "table" then
				for k, v in pairs(result) do
					data[k] = v
				end
			end
			return data
		end
		warn("Could not load data (attempt " .. attempt .. "): " .. tostring(result))
		task.wait(1)
	end
	-- DataStore not working (e.g. Studio API access is off) -> play without saving
	local data = defaultData()
	data.NoSave = true
	return data
end

local function saveData(player)
	local data = sessions[player]
	if not data or data.NoSave then
		return
	end
	local toSave = {
		Stage = data.Stage, Coins = data.Coins, Wins = data.Wins,
		Owned = data.Owned, Equipped = data.Equipped,
	}
	local ok, err = pcall(function()
		store:SetAsync("player_" .. player.UserId, toSave)
	end)
	if not ok then
		warn("Could not save data for " .. player.Name .. ": " .. tostring(err))
	end
end

local function updateLeaderstats(player)
	local data = sessions[player]
	local stats = player:FindFirstChild("leaderstats")
	if not data or not stats then
		return
	end
	stats.Stage.Value = data.Stage
	stats.Coins.Value = data.Coins
	stats.Wins.Value = data.Wins
end

local function addCoins(player, amount, useMultiplier)
	local data = sessions[player]
	if not data then
		return 0
	end
	if useMultiplier and player:GetAttribute("VIP") then
		amount = amount * 2
	end
	data.Coins = data.Coins + amount
	updateLeaderstats(player)
	return amount
end

----------------------------------------------------------------------
-- TRAILS
----------------------------------------------------------------------
local function findTrail(name)
	for _, t in ipairs(TRAILS) do
		if t.Name == name then
			return t
		end
	end
	return nil
end

local function ownsTrail(player, name)
	local data = sessions[player]
	local t = findTrail(name)
	if not data or not t then
		return false
	end
	if t.VipOnly then
		return player:GetAttribute("VIP") == true
	end
	return data.Owned[name] == true
end

local function applyTrail(player)
	local char = player.Character
	local data = sessions[player]
	if not char or not data then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local old = root:FindFirstChild("PlayerTrail")
	if old then
		old:Destroy()
	end
	for _, name in ipairs({ "TrailA0", "TrailA1" }) do
		local a = root:FindFirstChild(name)
		if a then
			a:Destroy()
		end
	end

	local t = findTrail(data.Equipped)
	if not t or not ownsTrail(player, t.Name) then
		return
	end

	local a0 = Instance.new("Attachment")
	a0.Name = "TrailA0"
	a0.Position = Vector3.new(0, 0.8, 0)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailA1"
	a1.Position = Vector3.new(0, -0.8, 0)
	a1.Parent = root

	local keypoints = {}
	local n = #t.Colors
	for i, c in ipairs(t.Colors) do
		local time = (n == 1) and (i - 1) or (i - 1) / (n - 1)
		table.insert(keypoints, ColorSequenceKeypoint.new(time, c))
	end
	if n == 1 then
		table.insert(keypoints, ColorSequenceKeypoint.new(1, t.Colors[1]))
	end

	local trail = Instance.new("Trail")
	trail.Name = "PlayerTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(keypoints)
	trail.Lifetime = 0.6
	trail.LightEmission = 0.5
	trail.Transparency = NumberSequence.new(0, 1)
	trail.Parent = root
end

----------------------------------------------------------------------
-- SPAWNING
----------------------------------------------------------------------
local function spawnCFrame(stage)
	local pad = checkpoints[stage] or checkpoints[0]
	local top = pad.Position + Vector3.new(0, pad.Size.Y / 2 + 3, 0)
	return CFrame.lookAt(top, top + Vector3.new(0, 0, 1))
end

local function teleportToCheckpoint(player)
	local data = sessions[player]
	local char = player.Character
	if data and char then
		char:PivotTo(spawnCFrame(data.Stage))
	end
end

local function onCharacter(player, char)
	local humanoid = char:WaitForChild("Humanoid")
	char:WaitForChild("HumanoidRootPart")
	task.wait() -- let Roblox finish placing the character
	teleportToCheckpoint(player)
	if player:GetAttribute("Speed") then
		humanoid.WalkSpeed = CONFIG.SPEED_PASS_WALKSPEED
	end
	applyTrail(player)
	humanoid.Died:Connect(function()
		task.wait(CONFIG.RESPAWN_TIME)
		if player.Parent then
			player:LoadCharacter()
		end
	end)
end

----------------------------------------------------------------------
-- GAME PASSES
----------------------------------------------------------------------
local function grantPass(player, passId)
	if passId == 0 then
		return
	end
	if passId == CONFIG.VIP_PASS_ID then
		player:SetAttribute("VIP", true)
		local data = sessions[player]
		if data and data.Equipped == "None" then
			data.Equipped = "Rainbow"
		end
		applyTrail(player)
	elseif passId == CONFIG.SPEED_PASS_ID then
		player:SetAttribute("Speed", true)
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = CONFIG.SPEED_PASS_WALKSPEED
		end
	end
end

local function checkPasses(player)
	for _, passId in ipairs({ CONFIG.VIP_PASS_ID, CONFIG.SPEED_PASS_ID }) do
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
		notify(player, "Thanks for your purchase! :)")
	end
end)

----------------------------------------------------------------------
-- DEVELOPER PRODUCTS (can be bought many times)
----------------------------------------------------------------------
local handledReceipts = {}

MarketplaceService.ProcessReceipt = function(receipt)
	if handledReceipts[receipt.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local data = player and sessions[player]
	if not data then
		-- Player left / not loaded: Roblox will try again later
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receipt.ProductId == CONFIG.SKIP_STAGE_PRODUCT_ID then
		if data.Stage < CONFIG.TOTAL_STAGES then
			data.Stage = data.Stage + 1
			updateLeaderstats(player)
			teleportToCheckpoint(player)
			notify(player, "Stage skipped!")
		else
			-- Already at the finish: give coins so the purchase isn't wasted
			addCoins(player, 100, false)
			notify(player, "You already finished! Here are 100 coins instead.")
		end
	elseif receipt.ProductId == CONFIG.COINS_PRODUCT_ID then
		addCoins(player, CONFIG.COINS_PRODUCT_AMOUNT, false)
		notify(player, "+" .. CONFIG.COINS_PRODUCT_AMOUNT .. " coins!")
	else
		warn("Unknown product id: " .. tostring(receipt.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	handledReceipts[receipt.PurchaseId] = true
	saveData(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

----------------------------------------------------------------------
-- PLAYERS JOIN / LEAVE
----------------------------------------------------------------------
local function onPlayerAdded(player)
	local data = loadData(player)
	if not player.Parent then
		return
	end
	data.Stage = math.clamp(data.Stage, 0, CONFIG.TOTAL_STAGES)
	sessions[player] = data

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in ipairs({ "Stage", "Coins", "Wins" }) do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = stats
	end
	stats.Parent = player
	updateLeaderstats(player)

	checkPasses(player)

	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	player:LoadCharacter()

	if data.NoSave then
		notify(player, "Saving is OFF (turn on API access in Game Settings to save).")
	elseif data.Stage > 0 then
		notify(player, "Welcome back! You are on stage " .. data.Stage)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	sessions[player] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		saveData(player)
	end
end)

-- Autosave every 2 minutes
task.spawn(function()
	while true do
		task.wait(120)
		for _, player in ipairs(Players:GetPlayers()) do
			saveData(player)
		end
	end
end)

----------------------------------------------------------------------
-- TOUCH LOGIC: lava, checkpoints, coins, disappearing platforms
----------------------------------------------------------------------
local function playerFromHit(hit)
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then
		return nil, nil
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end
	return Players:GetPlayerFromCharacter(model), humanoid
end

for _, part in ipairs(CollectionService:GetTagged("Lava")) do
	part.Touched:Connect(function(hit)
		local _, humanoid = playerFromHit(hit)
		if humanoid then
			humanoid.Health = 0
		end
	end)
end

for stage, pad in pairs(checkpoints) do
	if stage > 0 then
		pad.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			local data = player and sessions[player]
			if not data or stage <= data.Stage then
				return
			end
			data.Stage = stage
			if stage == CONFIG.TOTAL_STAGES then
				data.Wins = data.Wins + 1
				local got = addCoins(player, CONFIG.FINISH_BONUS, true)
				notify(player, "YOU WIN! +" .. got .. " coins. Press Restart in the shop to play again!")
			else
				local got = addCoins(player, CONFIG.STAGE_BONUS, true)
				notify(player, "Checkpoint " .. stage .. "!  +" .. got .. " coins")
			end
			updateLeaderstats(player)
		end)
	end
end

local coinCooldowns = {} -- [player] = { [coin] = time }
Players.PlayerRemoving:Connect(function(player)
	coinCooldowns[player] = nil
end)

for _, coin in ipairs(CollectionService:GetTagged("Coin")) do
	coin.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player or not sessions[player] then
			return
		end
		coinCooldowns[player] = coinCooldowns[player] or {}
		local last = coinCooldowns[player][coin]
		if last and os.clock() - last < CONFIG.COIN_RESPAWN then
			return
		end
		coinCooldowns[player][coin] = os.clock()
		local got = addCoins(player, CONFIG.COIN_VALUE, true)
		coinRemote:FireClient(player, coin, CONFIG.COIN_RESPAWN, got)
	end)
end

for _, p in ipairs(CollectionService:GetTagged("Disappearing")) do
	local busy = false
	p.Touched:Connect(function(hit)
		if busy then
			return
		end
		local _, humanoid = playerFromHit(hit)
		if not humanoid then
			return
		end
		busy = true
		task.wait(0.5)
		p.Transparency = 0.85
		p.CanCollide = false
		task.wait(2.5)
		p.Transparency = 0.15
		p.CanCollide = true
		busy = false
	end)
end

-- Spinning lava bars
local overlap = OverlapParams.new()
local checkTimer = 0
RunService.Heartbeat:Connect(function(dt)
	checkTimer = checkTimer + dt
	local doCheck = checkTimer >= 0.1
	if doCheck then
		checkTimer = 0
	end
	for _, s in ipairs(spinners) do
		s.Angle = s.Angle + s.Speed * dt
		s.Part.CFrame = s.Center * CFrame.Angles(0, s.Angle, 0)
		if doCheck then
			for _, hit in ipairs(workspace:GetPartsInPart(s.Part, overlap)) do
				local _, humanoid = playerFromHit(hit)
				if humanoid then
					humanoid.Health = 0
				end
			end
		end
	end
end)

----------------------------------------------------------------------
-- SHOP (client asks the server)
----------------------------------------------------------------------
shopRemote.OnServerInvoke = function(player, action, arg)
	local data = sessions[player]
	if not data then
		return false, "Loading..."
	end

	if action == "GetData" then
		local list = {}
		for _, t in ipairs(TRAILS) do
			table.insert(list, {
				Name = t.Name,
				Price = t.Price,
				VipOnly = t.VipOnly == true,
				Color = t.Colors[1],
				Owned = ownsTrail(player, t.Name),
			})
		end
		return true, { Trails = list, Equipped = data.Equipped, Coins = data.Coins }

	elseif action == "BuyTrail" then
		local t = findTrail(arg)
		if not t then
			return false, "Unknown trail"
		end
		if ownsTrail(player, t.Name) then
			return false, "You already own it"
		end
		if t.VipOnly then
			return false, "Buy VIP to get this trail!"
		end
		if data.Coins < t.Price then
			return false, "Not enough coins (need " .. t.Price .. ")"
		end
		data.Coins = data.Coins - t.Price
		data.Owned[t.Name] = true
		data.Equipped = t.Name
		updateLeaderstats(player)
		applyTrail(player)
		return true, "Bought " .. t.Name .. " trail!"

	elseif action == "EquipTrail" then
		if arg == "None" or ownsTrail(player, arg) then
			data.Equipped = arg
			applyTrail(player)
			return true, "Equipped!"
		end
		return false, "You don't own that"

	elseif action == "Restart" then
		data.Stage = 0
		updateLeaderstats(player)
		teleportToCheckpoint(player)
		return true, "Back to the start. Good luck!"
	end

	return false, "Unknown action"
end
