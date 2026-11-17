--[[
	FLOOR IS LAVA OBBY  -  GameClient
	==================================
	Put this as a *LocalScript* in StarterPlayer > StarterPlayerScripts.

	Makes the buttons and the shop on the screen, spins the coins and
	shows messages. You don't need to change anything in here.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local shopRemote = remotes:WaitForChild("Shop")
local coinRemote = remotes:WaitForChild("CoinCollected")
local notifyRemote = remotes:WaitForChild("Notify")

----------------------------------------------------------------------
-- UI HELPERS
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "ObbyGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
end

local function stroke(parent)
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = Color3.fromRGB(20, 20, 20)
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
	b.AutoButtonColor = true
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

----------------------------------------------------------------------
-- TOP BAR: stage + coins
----------------------------------------------------------------------
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, 360, 0, 50)
topBar.Position = UDim2.new(0.5, -180, 0, 8)
topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
topBar.BackgroundTransparency = 0.2
topBar.Parent = gui
corner(topBar, 14)
stroke(topBar)

local stageLabel = label(topBar, "Stage 0", UDim2.new(0.55, -10, 0.8, 0), UDim2.new(0, 10, 0.1, 0))
local coinsLabel = label(topBar, "Coins: 0", UDim2.new(0.45, -10, 0.8, 0), UDim2.new(0.55, 0, 0.1, 0))
coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 60)

local function hookStats()
	local stats = player:WaitForChild("leaderstats")
	local stage = stats:WaitForChild("Stage")
	local coins = stats:WaitForChild("Coins")
	local function refresh()
		local total = ReplicatedStorage:GetAttribute("TotalStages") or 0
		if stage.Value >= total and total > 0 then
			stageLabel.Text = "FINISHED!"
		else
			stageLabel.Text = "Stage " .. stage.Value .. " / " .. total
		end
		coinsLabel.Text = "Coins: " .. coins.Value
	end
	stage.Changed:Connect(refresh)
	coins.Changed:Connect(refresh)
	refresh()
end
task.spawn(hookStats)

----------------------------------------------------------------------
-- NOTIFICATIONS
----------------------------------------------------------------------
local toast = label(gui, "", UDim2.new(0, 500, 0, 40), UDim2.new(0.5, -250, 0, 66))
toast.TextTransparency = 1
toast.TextStrokeTransparency = 1
local toastId = 0

local function showMessage(text)
	toastId = toastId + 1
	local myId = toastId
	toast.Text = text
	toast.TextTransparency = 0
	toast.TextStrokeTransparency = 0.3
	task.delay(3, function()
		if myId == toastId then
			TweenService:Create(toast, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end
notifyRemote.OnClientEvent:Connect(showMessage)

----------------------------------------------------------------------
-- BUYING WITH ROBUX
----------------------------------------------------------------------
local function promptPass(attr)
	local id = ReplicatedStorage:GetAttribute(attr) or 0
	if id == 0 then
		showMessage("Coming soon!")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, id)
end

local function promptProduct(attr)
	local id = ReplicatedStorage:GetAttribute(attr) or 0
	if id == 0 then
		showMessage("Coming soon!")
		return
	end
	MarketplaceService:PromptProductPurchase(player, id)
end

----------------------------------------------------------------------
-- SIDE BUTTONS
----------------------------------------------------------------------
local side = Instance.new("Frame")
side.BackgroundTransparency = 1
side.Size = UDim2.new(0, 160, 0, 130)
side.Position = UDim2.new(1, -170, 0.5, -65)
side.Parent = gui

local skipBtn = button(side, "SKIP STAGE", Color3.fromRGB(255, 120, 30), UDim2.new(1, 0, 0, 56), UDim2.new(0, 0, 0, 0))
local shopBtn = button(side, "SHOP", Color3.fromRGB(60, 180, 90), UDim2.new(1, 0, 0, 56), UDim2.new(0, 0, 0, 70))

skipBtn.Activated:Connect(function()
	promptProduct("SkipStageProductId")
end)

----------------------------------------------------------------------
-- SHOP WINDOW
----------------------------------------------------------------------
local shop = Instance.new("Frame")
shop.Size = UDim2.new(0, 420, 0, 420)
shop.Position = UDim2.new(0.5, -210, 0.5, -210)
shop.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
shop.Visible = false
shop.Parent = gui
corner(shop, 16)
stroke(shop)

label(shop, "SHOP", UDim2.new(1, -80, 0, 44), UDim2.new(0, 16, 0, 8))
local closeBtn = button(shop, "X", Color3.fromRGB(220, 60, 60), UDim2.new(0, 44, 0, 44), UDim2.new(1, -56, 0, 8))

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -24, 1, -70)
list.Position = UDim2.new(0, 12, 0, 60)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 8
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = shop

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local order = 0
local function row(height)
	order = order + 1
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -12, 0, height or 50)
	f.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
	f.LayoutOrder = order
	f.Parent = list
	corner(f, 10)
	return f
end

local function header(text)
	local f = row(34)
	f.BackgroundTransparency = 1
	local l = label(f, text, UDim2.fromScale(1, 1))
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = Color3.fromRGB(255, 210, 80)
end

local refreshShop -- defined below

local function buildShop()
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	order = 0

	-- Robux items
	header("ROBUX STORE")
	local robuxItems = {
		{ Text = "VIP: 2x coins + Rainbow trail", Attr = "VipPassId", Pass = true },
		{ Text = "Speed: run faster!", Attr = "SpeedPassId", Pass = true },
		{ Text = "+" .. (ReplicatedStorage:GetAttribute("CoinsProductAmount") or 0) .. " coins", Attr = "CoinsProductId", Pass = false },
	}
	for _, item in ipairs(robuxItems) do
		local f = row()
		local l = label(f, item.Text, UDim2.new(0.62, -10, 0.8, 0), UDim2.new(0, 10, 0.1, 0))
		l.TextXAlignment = Enum.TextXAlignment.Left
		local owned = item.Pass and item.Attr == "VipPassId" and player:GetAttribute("VIP")
			or item.Pass and item.Attr == "SpeedPassId" and player:GetAttribute("Speed")
		local b = button(f, owned and "OWNED" or "BUY R$", owned and Color3.fromRGB(90, 90, 90) or Color3.fromRGB(40, 170, 80),
			UDim2.new(0.35, 0, 0.8, 0), UDim2.new(0.63, 0, 0.1, 0))
		if not owned then
			b.Activated:Connect(function()
				if item.Pass then
					promptPass(item.Attr)
				else
					promptProduct(item.Attr)
				end
			end)
		end
	end

	-- Trails
	header("TRAILS (buy with coins)")
	local ok, data = shopRemote:InvokeServer("GetData")
	if not ok then
		return
	end
	local noneRow = row()
	label(noneRow, "No trail", UDim2.new(0.62, -10, 0.8, 0), UDim2.new(0, 10, 0.1, 0)).TextXAlignment = Enum.TextXAlignment.Left
	local noneBtn = button(noneRow, data.Equipped == "None" and "EQUIPPED" or "EQUIP", Color3.fromRGB(70, 110, 200),
		UDim2.new(0.35, 0, 0.8, 0), UDim2.new(0.63, 0, 0.1, 0))
	noneBtn.Activated:Connect(function()
		shopRemote:InvokeServer("EquipTrail", "None")
		refreshShop()
	end)

	for _, t in ipairs(data.Trails) do
		local f = row()
		local swatch = Instance.new("Frame")
		swatch.Size = UDim2.new(0, 30, 0, 30)
		swatch.Position = UDim2.new(0, 10, 0.5, -15)
		swatch.BackgroundColor3 = t.Color
		swatch.Parent = f
		corner(swatch, 15)

		local name = t.Name .. (t.VipOnly and "  (VIP)" or "  - " .. t.Price .. " coins")
		local l = label(f, name, UDim2.new(0.62, -50, 0.8, 0), UDim2.new(0, 50, 0.1, 0))
		l.TextXAlignment = Enum.TextXAlignment.Left

		local text, color
		if data.Equipped == t.Name and t.Owned then
			text, color = "EQUIPPED", Color3.fromRGB(90, 90, 90)
		elseif t.Owned then
			text, color = "EQUIP", Color3.fromRGB(70, 110, 200)
		elseif t.VipOnly then
			text, color = "GET VIP", Color3.fromRGB(200, 150, 30)
		else
			text, color = "BUY", Color3.fromRGB(40, 170, 80)
		end
		local b = button(f, text, color, UDim2.new(0.35, 0, 0.8, 0), UDim2.new(0.63, 0, 0.1, 0))
		b.Activated:Connect(function()
			if t.Owned then
				shopRemote:InvokeServer("EquipTrail", t.Name)
			elseif t.VipOnly then
				promptPass("VipPassId")
				return
			else
				local _, msg = shopRemote:InvokeServer("BuyTrail", t.Name)
				showMessage(msg)
			end
			refreshShop()
		end)
	end

	-- Restart
	header("OTHER")
	local f = row()
	label(f, "Restart from stage 1", UDim2.new(0.62, -10, 0.8, 0), UDim2.new(0, 10, 0.1, 0)).TextXAlignment = Enum.TextXAlignment.Left
	local restart = button(f, "RESTART", Color3.fromRGB(200, 70, 70), UDim2.new(0.35, 0, 0.8, 0), UDim2.new(0.63, 0, 0.1, 0))
	restart.Activated:Connect(function()
		local _, msg = shopRemote:InvokeServer("Restart")
		showMessage(msg)
		shop.Visible = false
	end)
end

refreshShop = function()
	if shop.Visible then
		buildShop()
	end
end

shopBtn.Activated:Connect(function()
	shop.Visible = not shop.Visible
	refreshShop()
end)
closeBtn.Activated:Connect(function()
	shop.Visible = false
end)

-- Update shop when a game pass is bought
player:GetAttributeChangedSignal("VIP"):Connect(refreshShop)
player:GetAttributeChangedSignal("Speed"):Connect(refreshShop)

----------------------------------------------------------------------
-- COINS: spin + hide after pickup
----------------------------------------------------------------------
local coinBase = {}

local function trackCoin(coin)
	coinBase[coin] = coin.CFrame
end
for _, coin in ipairs(CollectionService:GetTagged("Coin")) do
	trackCoin(coin)
end
CollectionService:GetInstanceAddedSignal("Coin"):Connect(trackCoin)
CollectionService:GetInstanceRemovedSignal("Coin"):Connect(function(coin)
	coinBase[coin] = nil
end)

local spin = 0
RunService.RenderStepped:Connect(function(dt)
	spin = spin + dt * 2
	local bob = math.sin(spin * 1.5) * 0.3
	for coin, base in pairs(coinBase) do
		coin.CFrame = base * CFrame.new(0, bob, 0) * CFrame.Angles(0, spin, 0)
	end
end)

coinRemote.OnClientEvent:Connect(function(coin, respawnTime, amount)
	if coin and coin.Parent then
		coin.Transparency = 1
		task.delay(respawnTime, function()
			if coin.Parent then
				coin.Transparency = 0
			end
		end)
	end
	showMessage("+" .. tostring(amount) .. " coins")
end)
