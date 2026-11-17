--[[
	EGG HEIST: THROW & STEAL  -  GameClient
	========================================
	Put this as a *LocalScript* in StarterPlayer > StarterPlayerScripts.

	Makes the cash display, THROW button, shop, superpower list and
	messages. You don't need to change anything in here.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyRemote = remotes:WaitForChild("Notify")
local announceRemote = remotes:WaitForChild("Announce")
local throwRemote = remotes:WaitForChild("Throw")

local POWER_NAMES = {
	Speed = "Super Speed",
	Jump = "Mega Jump",
	StrongArm = "Strong Arm",
	Ghost = "Ghost",
	IronGrip = "Iron Grip",
}

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

----------------------------------------------------------------------
-- UI HELPERS
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "EggHeistGui"
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
-- CASH DISPLAY
----------------------------------------------------------------------
local cashFrame = Instance.new("Frame")
cashFrame.Size = UDim2.new(0, 240, 0, 50)
cashFrame.Position = UDim2.new(0.5, -120, 0, 8)
cashFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
cashFrame.BackgroundTransparency = 0.2
cashFrame.Parent = gui
corner(cashFrame, 14)
stroke(cashFrame)
local cashLabel = label(cashFrame, "$0", UDim2.new(1, -20, 0.8, 0), UDim2.new(0, 10, 0.1, 0))
cashLabel.TextColor3 = Color3.fromRGB(110, 255, 110)

task.spawn(function()
	local stats = player:WaitForChild("leaderstats")
	local cash = stats:WaitForChild("Cash")
	local function refresh()
		cashLabel.Text = "$" .. fmt(cash.Value)
	end
	cash.Changed:Connect(refresh)
	refresh()
end)

----------------------------------------------------------------------
-- MESSAGES
----------------------------------------------------------------------
local toast = label(gui, "", UDim2.new(0, 560, 0, 36), UDim2.new(0.5, -280, 0, 64))
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
	task.delay(3.5, function()
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

----------------------------------------------------------------------
-- SUPERPOWERS LIST (left side)
----------------------------------------------------------------------
local powerFrame = Instance.new("Frame")
powerFrame.Size = UDim2.new(0, 190, 0, 200)
powerFrame.Position = UDim2.new(0, 10, 0.5, -100)
powerFrame.BackgroundTransparency = 1
powerFrame.Parent = gui
local powerTitle = label(powerFrame, "SUPERPOWERS", UDim2.new(1, 0, 0, 26))
powerTitle.TextColor3 = Color3.fromRGB(255, 210, 60)
powerTitle.TextXAlignment = Enum.TextXAlignment.Left
local powerList = label(powerFrame, "", UDim2.new(1, 0, 1, -30), UDim2.new(0, 0, 0, 30))
powerList.TextScaled = false
powerList.TextSize = 18
powerList.TextXAlignment = Enum.TextXAlignment.Left
powerList.TextYAlignment = Enum.TextYAlignment.Top

local function refreshPowers()
	local lines = {}
	for key, name in pairs(POWER_NAMES) do
		if player:GetAttribute("Power_" .. key) then
			table.insert(lines, "* " .. name)
		end
	end
	table.sort(lines)
	if #lines == 0 then
		powerList.Text = "None yet.\nHatch special eggs\nto unlock powers!"
	else
		powerList.Text = table.concat(lines, "\n")
	end
end
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 6) == "Power_" then
		refreshPowers()
	end
end)
refreshPowers()

----------------------------------------------------------------------
-- THROW
----------------------------------------------------------------------
local throwBtn = button(gui, "THROW! (F)", Color3.fromRGB(255, 120, 30), UDim2.new(0, 200, 0, 70), UDim2.new(0.5, -100, 1, -170))
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
-- ROBUX SHOP
----------------------------------------------------------------------
local function prompt(attr, isPass)
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

local shopBtn = button(gui, "SHOP", Color3.fromRGB(60, 180, 90), UDim2.new(0, 140, 0, 54), UDim2.new(1, -150, 0.5, -27))

local shop = Instance.new("Frame")
shop.Size = UDim2.new(0, 440, 0, 400)
shop.Position = UDim2.new(0.5, -220, 0.5, -200)
shop.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
shop.Visible = false
shop.Parent = gui
corner(shop, 16)
stroke(shop)
label(shop, "SHOP", UDim2.new(1, -80, 0, 44), UDim2.new(0, 16, 0, 8))
local closeBtn = button(shop, "X", Color3.fromRGB(220, 60, 60), UDim2.new(0, 44, 0, 44), UDim2.new(1, -56, 0, 8))

local items = {
	{ Text = "VIP: +3 egg slots + VIP tag", Attr = "VipPassId", Pass = true, Owned = "VIP" },
	{ Text = "2x Cash forever", Attr = "DoubleCashPassId", Pass = true, Owned = "DoubleCash" },
	{ Text = "Lucky Egg (Legendary or Mythic!)", Attr = "LuckyEggProductId" },
	{ Text = "Super Lock (3 minutes)", Attr = "SuperLockProductId" },
	{ Text = "+$" .. fmt(ReplicatedStorage:GetAttribute("CashPackAmount") or 0) .. " cash", Attr = "CashPackProductId" },
}

local itemButtons = {}
for i, item in ipairs(items) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -24, 0, 56)
	row.Position = UDim2.new(0, 12, 0, 60 + (i - 1) * 64)
	row.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
	row.Parent = shop
	corner(row, 10)
	local l = label(row, item.Text, UDim2.new(0.62, -10, 0.7, 0), UDim2.new(0, 10, 0.15, 0))
	l.TextXAlignment = Enum.TextXAlignment.Left
	local b = button(row, "BUY R$", Color3.fromRGB(40, 170, 80), UDim2.new(0.35, 0, 0.8, 0), UDim2.new(0.63, 0, 0.1, 0))
	b.Activated:Connect(function()
		if item.Owned and player:GetAttribute(item.Owned) then
			return
		end
		prompt(item.Attr, item.Pass)
	end)
	itemButtons[i] = b
end

local function refreshShop()
	for i, item in ipairs(items) do
		if item.Owned and player:GetAttribute(item.Owned) then
			itemButtons[i].Text = "OWNED"
			itemButtons[i].BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		end
	end
end
player:GetAttributeChangedSignal("VIP"):Connect(refreshShop)
player:GetAttributeChangedSignal("DoubleCash"):Connect(refreshShop)
refreshShop()

shopBtn.Activated:Connect(function()
	shop.Visible = not shop.Visible
end)
closeBtn.Activated:Connect(function()
	shop.Visible = false
end)

----------------------------------------------------------------------
-- EGG PROMPTS: only show the ones that make sense for you
----------------------------------------------------------------------
local function updatePrompts(part)
	local state = part:GetAttribute("State")
	local mine = part:GetAttribute("OwnerId") == player.UserId
	for _, p in ipairs(part:GetChildren()) do
		if p:IsA("ProximityPrompt") then
			local n = p.Name
			p.Enabled = (n == "Buy" and state == "Road")
				or (n == "Steal" and state == "Placed" and not mine)
				or (n == "Sell" and state == "Placed" and mine)
				or (n == "Grab" and state == "Loose")
		end
	end
end

local function trackEgg(part)
	updatePrompts(part)
	part.AttributeChanged:Connect(function()
		updatePrompts(part)
	end)
	part.ChildAdded:Connect(function()
		updatePrompts(part)
	end)
end
for _, part in ipairs(CollectionService:GetTagged("Egg")) do
	trackEgg(part)
end
CollectionService:GetInstanceAddedSignal("Egg"):Connect(trackEgg)

----------------------------------------------------------------------
-- WELCOME
----------------------------------------------------------------------
task.delay(2, function()
	showMessage("Buy eggs on the EGG ROAD. Steal from others. Press F to THROW!")
end)
