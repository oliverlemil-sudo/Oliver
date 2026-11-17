--[[
	👹 MOG MONSTERS - GameClient 👹
	===============================
	Put this as a *LocalScript* in StarterPlayer > StarterPlayerScripts.

	Makes all the screens: money, MOG, menus (Shop, Upgrades, Daily,
	Index, Rebirth), Fusion, the THROW button, alarms and effects.
	You don't need to change anything in here.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyRemote = remotes:WaitForChild("Notify")
local announceRemote = remotes:WaitForChild("Announce")
local alarmRemote = remotes:WaitForChild("Alarm")
local panelRemote = remotes:WaitForChild("OpenPanel")
local throwRemote = remotes:WaitForChild("Throw")
local effectRemote = remotes:WaitForChild("Effect")
local requestRemote = remotes:WaitForChild("Request")

local RARITY_NAMES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "GODLY" }
local RARITY_COLORS = {
	Color3.fromRGB(200, 200, 200), Color3.fromRGB(90, 220, 90), Color3.fromRGB(70, 150, 255),
	Color3.fromRGB(180, 90, 255), Color3.fromRGB(255, 200, 40), Color3.fromRGB(255, 60, 120),
	Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255),
}

local function fmt(n)
	n = math.floor(n or 0)
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

local function timeText(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	if seconds >= 3600 then
		return string.format("%dh %02dm", seconds // 3600, (seconds % 3600) // 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

----------------------------------------------------------------------
-- UI HELPERS
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "MogMonstersGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
end

local function stroke(parent)
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = Color3.fromRGB(15, 15, 20)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

local function label(parent, text, size, pos)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos or UDim2.new()
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.3
	l.Text = text
	l.Parent = parent
	return l
end

local function button(parent, text, color, size, pos)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos or UDim2.new()
	b.BackgroundColor3 = color
	b.Font = Enum.Font.FredokaOne
	b.TextScaled = true
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextStrokeTransparency = 0.3
	b.Text = text
	b.Parent = parent
	corner(b, 10)
	stroke(b)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.15, 0)
	pad.PaddingBottom = UDim.new(0.15, 0)
	pad.PaddingLeft = UDim.new(0.05, 0)
	pad.PaddingRight = UDim.new(0.05, 0)
	pad.Parent = b
	return b
end

local function box(parent, size, pos, color, transparency)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos or UDim2.new()
	f.BackgroundColor3 = color or Color3.fromRGB(30, 30, 42)
	f.BackgroundTransparency = transparency or 0
	f.Parent = parent
	corner(f, 12)
	stroke(f)
	return f
end

----------------------------------------------------------------------
-- MESSAGES & ALARM
----------------------------------------------------------------------
local toast = label(gui, "", UDim2.new(0, 620, 0, 34), UDim2.new(0.5, -310, 0, 92))
toast.TextTransparency = 1
toast.TextStrokeTransparency = 1
local toastId = 0

local function showMessage(text, color)
	toastId = toastId + 1
	local myId = toastId
	toast.Text = text
	toast.TextColor3 = color or Color3.new(1, 1, 1)
	toast.TextTransparency = 0
	toast.TextStrokeTransparency = 0.3
	task.delay(4, function()
		if myId == toastId then
			TweenService:Create(toast, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end
notifyRemote.OnClientEvent:Connect(function(text)
	showMessage(text)
end)
announceRemote.OnClientEvent:Connect(function(text)
	showMessage(text, Color3.fromRGB(255, 210, 60))
end)

local alarmFrame = Instance.new("Frame")
alarmFrame.Size = UDim2.fromScale(1, 1)
alarmFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
alarmFrame.BackgroundTransparency = 1
alarmFrame.ZIndex = 0
alarmFrame.Parent = gui
local alarmText = label(gui, "", UDim2.new(0, 700, 0, 50), UDim2.new(0.5, -350, 0.3, 0))
alarmText.TextColor3 = Color3.fromRGB(255, 70, 70)

alarmRemote.OnClientEvent:Connect(function(text)
	alarmText.Text = "ALARM! " .. text
	for _ = 1, 5 do
		alarmFrame.BackgroundTransparency = 0.6
		TweenService:Create(alarmFrame, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		task.wait(0.5)
	end
	alarmText.Text = ""
end)

----------------------------------------------------------------------
-- EFFECTS: particle burst + floating text
----------------------------------------------------------------------
effectRemote.OnClientEvent:Connect(function(position, color, text)
	if typeof(position) ~= "Vector3" then
		return
	end
	color = typeof(color) == "Color3" and color or Color3.new(1, 1, 1)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = CFrame.new(position)
	p.Parent = workspace

	local burst = Instance.new("ParticleEmitter")
	burst.Color = ColorSequence.new(color)
	burst.LightEmission = 1
	burst.Rate = 0
	burst.Speed = NumberRange.new(12, 24)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Lifetime = NumberRange.new(0.5, 1)
	burst.Size = NumberSequence.new(1.2, 0)
	burst.Parent = p
	burst:Emit(40)

	if type(text) == "string" then
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 260, 0, 50)
		bb.StudsOffset = Vector3.new(0, 3, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 120
		bb.Parent = p
		local l = label(bb, text, UDim2.fromScale(1, 1))
		l.TextColor3 = color
		l.TextStrokeTransparency = 0
		TweenService:Create(bb, TweenInfo.new(1.6), { StudsOffset = Vector3.new(0, 10, 0) }):Play()
		TweenService:Create(l, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end
	Debris:AddItem(p, 2)
end)

----------------------------------------------------------------------
-- TOP: CASH, MOG, EVENTS
----------------------------------------------------------------------
local cashBox = box(gui, UDim2.new(0, 300, 0, 74), UDim2.new(0.5, -150, 0, 8), Color3.fromRGB(30, 30, 42), 0.15)
local cashLabel = label(cashBox, "$0", UDim2.new(1, -20, 0.6, 0), UDim2.new(0, 10, 0.05, 0))
cashLabel.TextColor3 = Color3.fromRGB(110, 255, 110)
local incomeLabel = label(cashBox, "+$0/s", UDim2.new(1, -20, 0.32, 0), UDim2.new(0, 10, 0.64, 0))
incomeLabel.TextColor3 = Color3.fromRGB(200, 255, 200)

local mogBox = box(gui, UDim2.new(0, 220, 0, 64), UDim2.new(0, 10, 1, -160), Color3.fromRGB(30, 30, 42), 0.15)
local mogTitle = label(mogBox, "YOUR MOG", UDim2.new(1, -16, 0.38, 0), UDim2.new(0, 8, 0.05, 0))
mogTitle.TextColor3 = Color3.fromRGB(255, 120, 200)
mogTitle.TextXAlignment = Enum.TextXAlignment.Left
local mogLabel = label(mogBox, "10", UDim2.new(1, -16, 0.52, 0), UDim2.new(0, 8, 0.43, 0))
mogLabel.TextXAlignment = Enum.TextXAlignment.Left

local eventBox = box(gui, UDim2.new(0, 230, 0, 64), UDim2.new(1, -240, 0, 8), Color3.fromRGB(30, 30, 42), 0.15)
local rushLabel = label(eventBox, "", UDim2.new(1, -16, 0.42, 0), UDim2.new(0, 8, 0.05, 0))
local luckLabel = label(eventBox, "", UDim2.new(1, -16, 0.42, 0), UDim2.new(0, 8, 0.53, 0))
rushLabel.TextXAlignment = Enum.TextXAlignment.Left
luckLabel.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
	local cash = player:WaitForChild("leaderstats"):WaitForChild("Cash")
	local function refresh()
		cashLabel.Text = "$" .. fmt(cash.Value)
	end
	cash.Changed:Connect(refresh)
	refresh()
end)

RunService.Heartbeat:Connect(function()
	incomeLabel.Text = "+$" .. fmt(player:GetAttribute("Income") or 0) .. "/s"
	mogLabel.Text = fmt(player:GetAttribute("Mog") or 0)
	local rush = ReplicatedStorage:GetAttribute("RushIn") or 0
	if rush < 0 then
		rushLabel.Text = "LUCKY RUSH! " .. timeText(-rush)
		rushLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
	else
		rushLabel.Text = "Lucky Rush: " .. timeText(rush)
		rushLabel.TextColor3 = Color3.new(1, 1, 1)
	end
	local luck = ReplicatedStorage:GetAttribute("LuckLeft") or 0
	if luck > 0 then
		luckLabel.Text = "2x SERVER LUCK " .. timeText(luck)
		luckLabel.TextColor3 = Color3.fromRGB(110, 255, 110)
	else
		luckLabel.Text = "Server luck: 1x"
		luckLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	end
end)

----------------------------------------------------------------------
-- THROW
----------------------------------------------------------------------
local throwBtn = button(gui, "THROW! (F)", Color3.fromRGB(255, 120, 30), UDim2.new(0, 210, 0, 70), UDim2.new(0.5, -105, 1, -180))
throwBtn.Visible = false

local function throw()
	if player:GetAttribute("Carrying") then
		throwRemote:FireServer(camera.CFrame.LookVector)
	end
end
throwBtn.Activated:Connect(throw)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.F then
		throw()
	end
end)
player:GetAttributeChangedSignal("Carrying"):Connect(function()
	throwBtn.Visible = player:GetAttribute("Carrying") == true
end)

----------------------------------------------------------------------
-- PANELS
----------------------------------------------------------------------
local panels = {}

local function makePanel(title, color, bottomSpace)
	local frame = box(gui, UDim2.new(0, 480, 0, 440), UDim2.new(0.5, -240, 0.5, -220), Color3.fromRGB(35, 35, 50))
	frame.Visible = false
	frame.ZIndex = 5
	local t = label(frame, title, UDim2.new(1, -80, 0, 44), UDim2.new(0, 16, 0, 8))
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextXAlignment = Enum.TextXAlignment.Left
	local close = button(frame, "X", Color3.fromRGB(220, 60, 60), UDim2.new(0, 44, 0, 44), UDim2.new(1, -56, 0, 8))
	close.Activated:Connect(function()
		frame.Visible = false
	end)
	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -24, 1, -70 - (bottomSpace or 0))
	list.Position = UDim2.new(0, 12, 0, 60)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 8
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local panel = { Frame = frame, List = list, Order = 0 }
	function panel.Clear()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		panel.Order = 0
	end
	function panel.Row(height)
		panel.Order = panel.Order + 1
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1, -12, 0, height or 52)
		f.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
		f.LayoutOrder = panel.Order
		f.Parent = list
		corner(f, 10)
		return f
	end
	function panel.Text(text, color, height)
		local f = panel.Row(height or 30)
		f.BackgroundTransparency = 1
		local l = label(f, text, UDim2.fromScale(1, 1))
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextColor3 = color or Color3.new(1, 1, 1)
		return l
	end
	function panel.ButtonRow(text, btnText, btnColor, onClick)
		local f = panel.Row()
		local l = label(f, text, UDim2.new(0.62, -10, 0.7, 0), UDim2.new(0, 10, 0.15, 0))
		l.TextXAlignment = Enum.TextXAlignment.Left
		local b = button(f, btnText, btnColor, UDim2.new(0.35, 0, 0.8, 0), UDim2.new(0.63, 0, 0.1, 0))
		if onClick then
			b.Activated:Connect(onClick)
		end
		return b, l
	end
	table.insert(panels, panel)
	return panel
end

local function openPanel(panel, refresh)
	for _, p in ipairs(panels) do
		p.Frame.Visible = false
	end
	panel.Frame.Visible = true
	if refresh then
		refresh()
	end
end

local function getInfo()
	local ok, info = requestRemote:InvokeServer("GetInfo")
	if ok then
		return info
	end
	return nil
end

local GREEN, GRAY = Color3.fromRGB(40, 170, 80), Color3.fromRGB(90, 90, 90)

----------------------------------------------------------------------
-- SHOP (Robux)
----------------------------------------------------------------------
local shopPanel = makePanel("ROBUX SHOP", Color3.fromRGB(110, 255, 110))

local function promptBuy(attr, isPass)
	local id = ReplicatedStorage:GetAttribute(attr) or 0
	if id == 0 then
		showMessage("Coming soon!")
		return
	end
	if isPass then
		MarketplaceService:PromptGamePassPurchase(player, id)
	else
		MarketplaceService:PromptProductPurchase(player, id)
	end
end

local SHOP_ITEMS = {
	{ Header = "GAME PASSES (forever)" },
	{ Text = "2x Money", Attr = "DoubleMoneyPassId", Pass = true, Owned = "DoubleMoney" },
	{ Text = "VIP: tag, +20% money, 2x daily", Attr = "VipPassId", Pass = true, Owned = "VIP" },
	{ Text = "+3 Monster Spots", Attr = "ExtraSlotsPassId", Pass = true, Owned = "ExtraSlots" },
	{ Text = "Fast Stealing", Attr = "FastStealPassId", Pass = true, Owned = "FastSteal" },
	{ Text = "+1 Vault Spot", Attr = "ExtraVaultPassId", Pass = true, Owned = "ExtraVault" },
	{ Header = "BOOSTS" },
	{ Text = "2x SERVER LUCK (15 min, everyone!)", Attr = "ServerLuckProductId" },
	{ Text = "Super Lock (3 min)", Attr = "SuperLockProductId" },
	{ Text = "Cash Pack (10 min of income)", Attr = "CashPackProductId" },
}

local function refreshShop()
	shopPanel.Clear()
	for _, item in ipairs(SHOP_ITEMS) do
		if item.Header then
			shopPanel.Text(item.Header, Color3.fromRGB(255, 210, 80))
		else
			local owned = item.Owned and player:GetAttribute(item.Owned)
			shopPanel.ButtonRow(item.Text, owned and "OWNED" or "BUY R$", owned and GRAY or GREEN, function()
				if not owned then
					promptBuy(item.Attr, item.Pass)
				end
			end)
		end
	end
end
player.AttributeChanged:Connect(function(name)
	if shopPanel.Frame.Visible and name ~= "Income" and name ~= "Mog" then
		refreshShop()
	end
end)

----------------------------------------------------------------------
-- UPGRADES
----------------------------------------------------------------------
local upgradePanel = makePanel("UPGRADES", Color3.fromRGB(120, 180, 255))

local refreshUpgrades
local function buy(action)
	local _, msg = requestRemote:InvokeServer(action)
	showMessage(msg)
	refreshUpgrades()
end

refreshUpgrades = function()
	local info = getInfo()
	upgradePanel.Clear()
	if not info then
		return
	end
	upgradePanel.Text("MOG " .. fmt(info.Mog) .. "  ->  " .. fmt(info.NextMog), Color3.fromRGB(255, 120, 200))
	upgradePanel.ButtonRow("Train MOG (mog better monsters!)", "$" .. fmt(info.MogCost), GREEN, function()
		buy("TrainMog")
	end)
	upgradePanel.Text("Money Boost: x" .. info.Boost .. (info.NextBoost and ("  ->  x" .. info.NextBoost) or ""), Color3.fromRGB(110, 255, 110))
	if info.BoostCost then
		upgradePanel.ButtonRow("Monsters make more money", "$" .. fmt(info.BoostCost), GREEN, function()
			buy("BuyBoost")
		end)
	else
		upgradePanel.ButtonRow("Money Boost", "MAX", GRAY)
	end
	upgradePanel.Text("Monster spots: " .. info.Slots, Color3.fromRGB(255, 210, 80))
	if info.BaseSlots < info.MaxSlots then
		upgradePanel.ButtonRow("+1 monster spot", "$" .. fmt(info.SlotCost), GREEN, function()
			buy("BuySlot")
		end)
	else
		upgradePanel.ButtonRow("Monster spots", "MAX", GRAY)
	end
	upgradePanel.Text("Vault spots: " .. info.Vaults .. " (can't be stolen)", nil, 26)
	upgradePanel.Text("Stand on the red LOCK pad to lock your base", nil, 26)
	upgradePanel.Text("Use MOG SLAP on thieves to make them drop it", nil, 26)
end

----------------------------------------------------------------------
-- DAILY REWARD
----------------------------------------------------------------------
local dailyPanel = makePanel("DAILY REWARD", Color3.fromRGB(255, 210, 60))

local function refreshDaily()
	local info = getInfo()
	dailyPanel.Clear()
	if not info then
		return
	end
	dailyPanel.Text("Streak: " .. info.Streak .. " days", Color3.fromRGB(255, 210, 80))
	dailyPanel.Text("Come back every day for bigger rewards!", nil, 26)
	dailyPanel.Text("Day 7 = a FREE Epic or Legendary monster!", nil, 26)
	if info.DailyReady then
		dailyPanel.ButtonRow("Your reward is ready!", "CLAIM", GREEN, function()
			local _, msg = requestRemote:InvokeServer("ClaimDaily")
			showMessage(msg, Color3.fromRGB(255, 210, 60))
			refreshDaily()
		end)
	else
		dailyPanel.ButtonRow("Next reward in " .. timeText(info.DailyWait), "WAIT", GRAY)
	end
end

----------------------------------------------------------------------
-- INDEX
----------------------------------------------------------------------
local indexPanel = makePanel("MONSTER INDEX", Color3.fromRGB(200, 120, 255))

local function refreshIndex()
	local info = getInfo()
	indexPanel.Clear()
	if not info then
		return
	end
	local found = 0
	indexPanel.Text("MONSTERS", Color3.fromRGB(255, 210, 80))
	for _, m in ipairs(info.Index) do
		local odds = m.Exclusive and "Rebirth 10 only" or ("1 in " .. fmt(m.Odds))
		if m.Found then
			found = found + 1
			indexPanel.Text(m.Name .. "  (" .. RARITY_NAMES[m.Rarity] .. ", " .. odds .. ")", RARITY_COLORS[m.Rarity], 26)
		else
			local l = indexPanel.Text("???  (" .. RARITY_NAMES[m.Rarity] .. ", " .. odds .. ")", RARITY_COLORS[m.Rarity], 26)
			l.TextTransparency = 0.35
		end
	end
	indexPanel.Text("Found " .. found .. "/" .. #info.Index, nil, 26)
	indexPanel.Text("LEVELS", Color3.fromRGB(255, 210, 80))
	for i, v in ipairs(info.Variants) do
		local odds = i == 1 and "" or ("  (1 in " .. fmt(v.Odds) .. ")")
		indexPanel.Text(v.Name .. "  x" .. v.Mult .. odds, nil, 26)
	end
	indexPanel.Text("Fuse 2 of the same = next level!", Color3.fromRGB(220, 150, 255), 26)
end

----------------------------------------------------------------------
-- FUSION
----------------------------------------------------------------------
local fusionPanel = makePanel("FUSION MACHINE", Color3.fromRGB(200, 80, 255), 110)
local fusionBottom = Instance.new("Frame")
fusionBottom.Size = UDim2.new(1, -24, 0, 100)
fusionBottom.Position = UDim2.new(0, 12, 1, -108)
fusionBottom.BackgroundTransparency = 1
fusionBottom.Parent = fusionPanel.Frame
local fusionPreview = label(fusionBottom, "Pick 2 of the same monster", UDim2.new(1, 0, 0.4, 0))
local fuseBtn = button(fusionBottom, "FUSE!", Color3.fromRGB(170, 60, 255), UDim2.new(0.6, 0, 0.5, 0), UDim2.new(0.2, 0, 0.48, 0))
local LEVEL_NAMES = { "Normal", "Golden", "Diamond", "Rainbow", "Cosmic", "Rainbow Cosmic" }

local selected = {}
local refreshFusion

local function baseName(m)
	local name = m.Name
	for i = #LEVEL_NAMES, 2, -1 do
		local prefix = LEVEL_NAMES[i] .. " "
		if string.sub(name, 1, #prefix) == prefix then
			return string.sub(name, #prefix + 1)
		end
	end
	return name
end

local function updateFusionPreview()
	if #selected < 2 then
		fusionPreview.Text = "Pick 2 of the same monster (" .. #selected .. "/2)"
		return
	end
	local a, b = selected[1], selected[2]
	if a.Id ~= b.Id or a.Variant ~= b.Variant then
		fusionPreview.Text = "They must be the SAME monster and level!"
	elseif a.Variant >= #LEVEL_NAMES then
		fusionPreview.Text = "Already max level!"
	else
		local nextName = LEVEL_NAMES[a.Variant + 1]
		fusionPreview.Text = "= " .. nextName .. " " .. baseName(a) .. "  ($" .. fmt(a.Value * 0.5) .. ")"
	end
end

refreshFusion = function()
	local info = getInfo()
	selected = {}
	fusionPanel.Clear()
	if not info then
		return
	end
	if #info.Monsters < 2 then
		fusionPanel.Text("You need at least 2 monsters in your base!", nil, 30)
	end
	for _, m in ipairs(info.Monsters) do
		local text = m.Name .. "  $" .. fmt(m.Income) .. "/s" .. (m.Vault and " [V]" or "")
		local b, l = fusionPanel.ButtonRow(text, "SELECT", Color3.fromRGB(70, 110, 200))
		l.TextColor3 = RARITY_COLORS[m.Rarity]
		b.Activated:Connect(function()
			for i, s in ipairs(selected) do
				if s == m then
					table.remove(selected, i)
					b.Text = "SELECT"
					b.BackgroundColor3 = Color3.fromRGB(70, 110, 200)
					updateFusionPreview()
					return
				end
			end
			if #selected >= 2 then
				showMessage("You can only pick 2!")
				return
			end
			table.insert(selected, m)
			b.Text = "PICKED"
			b.BackgroundColor3 = Color3.fromRGB(170, 60, 255)
			updateFusionPreview()
		end)
	end
	updateFusionPreview()
end

fuseBtn.Activated:Connect(function()
	if #selected < 2 then
		showMessage("Pick 2 monsters first!")
		return
	end
	local _, msg = requestRemote:InvokeServer("Fuse", selected[1].Slot, selected[2].Slot)
	showMessage(msg, Color3.fromRGB(220, 150, 255))
	task.wait(0.3)
	refreshFusion()
end)

----------------------------------------------------------------------
-- REBIRTH
----------------------------------------------------------------------
local rebirthPanel = makePanel("REBIRTH", Color3.fromRGB(255, 255, 255), 80)
local rebirthBtn = button(rebirthPanel.Frame, "REBIRTH!", Color3.fromRGB(255, 170, 40), UDim2.new(0.6, 0, 0, 56), UDim2.new(0.2, 0, 1, -72))

local function refreshRebirth()
	local info = getInfo()
	rebirthPanel.Clear()
	if not info then
		return
	end
	rebirthPanel.Text("Rebirths: " .. info.Rebirths, Color3.fromRGB(255, 210, 80))
	rebirthPanel.Text("Cost: $" .. fmt(info.RebirthCost) .. "  (you have $" .. fmt(info.Cash) .. ")", nil, 28)
	rebirthPanel.Text("You LOSE: cash, monsters outside the vault, upgrades", Color3.fromRGB(255, 120, 120), 26)
	rebirthPanel.Text("You KEEP: vault monsters, index", Color3.fromRGB(110, 255, 110), 26)
	rebirthPanel.Text("REWARDS", Color3.fromRGB(255, 210, 80))
	rebirthPanel.Text("Every rebirth: +1x money AND +1x MOG", nil, 26)
	rebirthPanel.Text("Rebirth 2 and 5: +1 vault spot", nil, 26)
	rebirthPanel.Text("Rebirth 3+: run faster", nil, 26)
	rebirthPanel.Text("Rebirth 10: exclusive GOLDEN PHOENIXMOG!", Color3.fromRGB(255, 160, 60), 26)
end

rebirthBtn.Activated:Connect(function()
	local _, msg = requestRemote:InvokeServer("Rebirth")
	showMessage(msg, Color3.fromRGB(255, 210, 60))
	refreshRebirth()
end)

panelRemote.OnClientEvent:Connect(function(name)
	if name == "Fusion" then
		openPanel(fusionPanel, refreshFusion)
	end
end)

----------------------------------------------------------------------
-- MENU BUTTONS (right side)
----------------------------------------------------------------------
local menu = Instance.new("Frame")
menu.BackgroundTransparency = 1
menu.Size = UDim2.new(0, 140, 0, 320)
menu.Position = UDim2.new(1, -150, 0.5, -140)
menu.Parent = gui
local menuItems = {
	{ "SHOP", Color3.fromRGB(40, 170, 80), shopPanel, refreshShop },
	{ "UPGRADES", Color3.fromRGB(70, 120, 220), upgradePanel, refreshUpgrades },
	{ "DAILY", Color3.fromRGB(230, 160, 30), dailyPanel, refreshDaily },
	{ "INDEX", Color3.fromRGB(150, 70, 220), indexPanel, refreshIndex },
	{ "REBIRTH", Color3.fromRGB(255, 150, 30), rebirthPanel, refreshRebirth },
}
for i, item in ipairs(menuItems) do
	local b = button(menu, item[1], item[2], UDim2.new(1, 0, 0, 54), UDim2.new(0, 0, 0, (i - 1) * 64))
	b.Activated:Connect(function()
		if item[3].Frame.Visible then
			item[3].Frame.Visible = false
		else
			openPanel(item[3], item[4])
		end
	end)
end

----------------------------------------------------------------------
-- MONSTER PROMPTS + MOG colors
----------------------------------------------------------------------
local function updateMonster(part)
	local state = part:GetAttribute("State")
	local mine = part:GetAttribute("OwnerId") == player.UserId
	local vault = (part:GetAttribute("Slot") or 0) > 100
	local fast = player:GetAttribute("FastSteal") == true
	for _, p in ipairs(part:GetChildren()) do
		if p:IsA("ProximityPrompt") then
			local n = p.Name
			p.Enabled = (n == "Mog" and state == "Lane")
				or (n == "Steal" and state == "Placed" and not mine and not vault)
				or (n == "Sell" and state == "Placed" and mine)
				or (n == "Vault" and state == "Placed" and mine)
				or (n == "Grab" and state == "Loose")
			if n == "Steal" then
				local base = p:GetAttribute("BaseHold")
				if not base then
					base = p.HoldDuration
					p:SetAttribute("BaseHold", base)
				end
				p.HoldDuration = fast and base / 2 or base
			end
		end
	end
	-- green MOG text = you can mog it, red = train more MOG
	local mogLabelInst = part:FindFirstChild("MogLabel", true)
	if mogLabelInst and state == "Lane" then
		local enough = (player:GetAttribute("Mog") or 0) >= (part:GetAttribute("MogReq") or 0)
		mogLabelInst.TextColor3 = enough and Color3.fromRGB(110, 255, 110) or Color3.fromRGB(255, 90, 90)
	elseif mogLabelInst then
		mogLabelInst.TextColor3 = Color3.new(1, 1, 1)
	end
end

local rainbowParts = {}

local function trackMonster(part)
	updateMonster(part)
	part.AttributeChanged:Connect(function()
		updateMonster(part)
	end)
	part.DescendantAdded:Connect(function()
		updateMonster(part)
	end)
	local v = part:GetAttribute("Variant")
	if v == "Rainbow" or v == "Rainbow Cosmic" then
		rainbowParts[part] = true
	end
end
for _, part in ipairs(CollectionService:GetTagged("Monster")) do
	trackMonster(part)
end
CollectionService:GetInstanceAddedSignal("Monster"):Connect(trackMonster)
CollectionService:GetInstanceRemovedSignal("Monster"):Connect(function(part)
	rainbowParts[part] = nil
end)
local function refreshAllMonsters()
	for _, part in ipairs(CollectionService:GetTagged("Monster")) do
		updateMonster(part)
	end
end
player:GetAttributeChangedSignal("FastSteal"):Connect(refreshAllMonsters)
player:GetAttributeChangedSignal("Mog"):Connect(refreshAllMonsters)

RunService.RenderStepped:Connect(function()
	local color = Color3.fromHSV((os.clock() * 0.3) % 1, 1, 1)
	for part in pairs(rainbowParts) do
		part.Color = color
	end
end)

----------------------------------------------------------------------
-- WELCOME
----------------------------------------------------------------------
task.delay(2, function()
	showMessage("Welcome to MOG MONSTERS! Hold E on monsters with GREEN mog to MOG them!", Color3.fromRGB(255, 210, 60))
end)

print("MOG MONSTERS client v1 started OK!")
