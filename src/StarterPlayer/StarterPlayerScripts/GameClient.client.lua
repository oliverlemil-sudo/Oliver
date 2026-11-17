--[[
	⚡ POWER EMPIRE - GameClient ⚡
	==============================
	Put this as a *LocalScript* in StarterPlayer > StarterPlayerScripts.

	Makes all the screens: money, menus (Shop, Base, Daily, Index),
	Fusion, Rebirth, the THROW button, alarms and attacks.
	You don't need to change anything in here.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyRemote = remotes:WaitForChild("Notify")
local announceRemote = remotes:WaitForChild("Announce")
local alarmRemote = remotes:WaitForChild("Alarm")
local panelRemote = remotes:WaitForChild("OpenPanel")
local throwRemote = remotes:WaitForChild("Throw")
local blastRemote = remotes:WaitForChild("Blast")
local requestRemote = remotes:WaitForChild("Request")
local effectRemote = remotes:WaitForChild("Effect")
local Debris = game:GetService("Debris")

local RARITY_NAMES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }
local RARITY_COLORS = {
	Color3.fromRGB(200, 200, 200), Color3.fromRGB(90, 220, 90), Color3.fromRGB(70, 150, 255),
	Color3.fromRGB(180, 90, 255), Color3.fromRGB(255, 200, 40), Color3.fromRGB(255, 60, 120),
	Color3.fromRGB(255, 255, 255),
}
local ELEMENT_INFO = {
	Punch = "Punch (get a power!)",
	Fire = "Fireball",
	Ice = "Ice Blast (freezes)",
	Lightning = "Lightning (super fast)",
	Shadow = "Shadow Shot (go invisible)",
	Gravity = "Gravity Pull",
	Dragon = "DRAGON BLAST",
}

local function fmt(n)
	n = math.floor(n or 0)
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
gui.Name = "PowerEmpireGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
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
-- TOP: CASH + EVENTS
----------------------------------------------------------------------
local cashBox = box(gui, UDim2.new(0, 300, 0, 74), UDim2.new(0.5, -150, 0, 8), Color3.fromRGB(30, 30, 42), 0.15)
local cashLabel = label(cashBox, "$0", UDim2.new(1, -20, 0.6, 0), UDim2.new(0, 10, 0.05, 0))
cashLabel.TextColor3 = Color3.fromRGB(110, 255, 110)
local incomeLabel = label(cashBox, "+$0/s", UDim2.new(1, -20, 0.32, 0), UDim2.new(0, 10, 0.64, 0))
incomeLabel.TextColor3 = Color3.fromRGB(200, 255, 200)

task.spawn(function()
	local cash = player:WaitForChild("leaderstats"):WaitForChild("Cash")
	local function refresh()
		cashLabel.Text = "$" .. fmt(cash.Value)
	end
	cash.Changed:Connect(refresh)
	refresh()
end)

local eventBox = box(gui, UDim2.new(0, 230, 0, 92), UDim2.new(1, -240, 0, 8), Color3.fromRGB(30, 30, 42), 0.15)
local restockLabel = label(eventBox, "", UDim2.new(1, -16, 0.3, 0), UDim2.new(0, 8, 0.03, 0))
local portalLabel = label(eventBox, "", UDim2.new(1, -16, 0.3, 0), UDim2.new(0, 8, 0.35, 0))
local luckLabel = label(eventBox, "", UDim2.new(1, -16, 0.3, 0), UDim2.new(0, 8, 0.67, 0))
for _, l in ipairs({ restockLabel, portalLabel, luckLabel }) do
	l.TextXAlignment = Enum.TextXAlignment.Left
end

-- Attack info (bottom left)
local attackBox = box(gui, UDim2.new(0, 250, 0, 56), UDim2.new(0, 10, 1, -150), Color3.fromRGB(30, 30, 42), 0.15)
local attackTitle = label(attackBox, "YOUR ATTACK", UDim2.new(1, -16, 0.4, 0), UDim2.new(0, 8, 0.05, 0))
attackTitle.TextColor3 = Color3.fromRGB(255, 200, 60)
attackTitle.TextXAlignment = Enum.TextXAlignment.Left
local attackLabel = label(attackBox, "", UDim2.new(1, -16, 0.5, 0), UDim2.new(0, 8, 0.45, 0))
attackLabel.TextXAlignment = Enum.TextXAlignment.Left

RunService.Heartbeat:Connect(function()
	incomeLabel.Text = "+$" .. fmt(player:GetAttribute("Income") or 0) .. "/s"
	attackLabel.Text = ELEMENT_INFO[player:GetAttribute("Element") or "Punch"] or ""
	restockLabel.Text = "Market restock: " .. timeText(ReplicatedStorage:GetAttribute("RestockIn"))
	local portalIn = ReplicatedStorage:GetAttribute("PortalIn") or 0
	if portalIn < 0 then
		portalLabel.Text = "PORTAL OPEN! " .. timeText(-portalIn)
		portalLabel.TextColor3 = Color3.fromRGB(200, 120, 255)
	else
		portalLabel.Text = "Secret portal: " .. timeText(portalIn)
		portalLabel.TextColor3 = Color3.new(1, 1, 1)
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
-- ATTACK (Power Blast tool)
----------------------------------------------------------------------
local function hookTool(tool)
	if tool:IsA("Tool") and tool.Name == "Power Blast" and not tool:GetAttribute("Hooked") then
		tool:SetAttribute("Hooked", true)
		tool.Activated:Connect(function()
			blastRemote:FireServer(mouse.Hit.Position)
		end)
	end
end
local function hookCharacter(char)
	char.ChildAdded:Connect(hookTool)
	for _, c in ipairs(char:GetChildren()) do
		hookTool(c)
	end
end
if player.Character then
	hookCharacter(player.Character)
end
player.CharacterAdded:Connect(hookCharacter)

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
	{ Text = "+3 Extra Pedestals", Attr = "ExtraSlotsPassId", Pass = true, Owned = "ExtraSlots" },
	{ Text = "Fast Stealing", Attr = "FastStealPassId", Pass = true, Owned = "FastSteal" },
	{ Text = "+1 Vault Slot", Attr = "ExtraVaultPassId", Pass = true, Owned = "ExtraVault" },
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
			shopPanel.ButtonRow(item.Text, owned and "OWNED" or "BUY R$",
				owned and Color3.fromRGB(90, 90, 90) or Color3.fromRGB(40, 170, 80),
				function()
					if not owned then
						promptBuy(item.Attr, item.Pass)
					end
				end)
		end
	end
end
player.AttributeChanged:Connect(function()
	if shopPanel.Frame.Visible then
		refreshShop()
	end
end)

----------------------------------------------------------------------
-- BASE MENU
----------------------------------------------------------------------
local basePanel = makePanel("MY BASE", Color3.fromRGB(120, 180, 255))

local function refreshBase()
	local info = getInfo()
	basePanel.Clear()
	if not info then
		return
	end
	basePanel.Text("UPGRADES", Color3.fromRGB(255, 210, 80))
	if info.BaseSlots < info.MaxSlots then
		basePanel.ButtonRow("Pedestals: " .. info.Slots .. "  (+1 slot)", "$" .. fmt(info.SlotCost), Color3.fromRGB(40, 170, 80), function()
			local _, msg = requestRemote:InvokeServer("BuySlot")
			showMessage(msg)
			refreshBase()
		end)
	else
		basePanel.ButtonRow("Pedestals: " .. info.Slots, "MAX", Color3.fromRGB(90, 90, 90))
	end
	if info.TurretCost then
		basePanel.ButtonRow("Turret: Level " .. info.Turret .. "/3", "$" .. fmt(info.TurretCost), Color3.fromRGB(40, 170, 80), function()
			local _, msg = requestRemote:InvokeServer("BuyTurret")
			showMessage(msg)
			refreshBase()
		end)
	else
		basePanel.ButtonRow("Turret: Level 3/3", "MAX", Color3.fromRGB(90, 90, 90))
	end
	basePanel.Text("DEFENSE TIPS", Color3.fromRGB(255, 210, 80))
	basePanel.Text("Vault slots: " .. info.Vaults .. " (vault powers can't be stolen)", nil, 26)
	basePanel.Text("Stand on the red LOCK pad to lock your base", nil, 26)
	basePanel.Text("Hit thieves with Power Blast to make them drop it", nil, 26)
	basePanel.Text("REBIRTH", Color3.fromRGB(255, 210, 80))
	basePanel.Text("Rebirths: " .. info.Rebirths .. "  |  Next: $" .. fmt(info.RebirthCost), nil, 26)
	basePanel.Text("Press the REBIRTH button on the right side", nil, 26)
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
	dailyPanel.Text("Day 7 = a FREE Epic or better power!", nil, 26)
	if info.DailyReady then
		dailyPanel.ButtonRow("Your reward is ready!", "CLAIM", Color3.fromRGB(40, 170, 80), function()
			local _, msg = requestRemote:InvokeServer("ClaimDaily")
			showMessage(msg, Color3.fromRGB(255, 210, 60))
			refreshDaily()
		end)
	else
		dailyPanel.ButtonRow("Next reward in " .. timeText(info.DailyWait), "WAIT", Color3.fromRGB(90, 90, 90))
	end
end

----------------------------------------------------------------------
-- INDEX (recipes & mutations)
----------------------------------------------------------------------
local indexPanel = makePanel("POWER INDEX", Color3.fromRGB(200, 120, 255))

local function refreshIndex()
	local info = getInfo()
	indexPanel.Clear()
	if not info then
		return
	end
	indexPanel.Text("FUSION RECIPES", Color3.fromRGB(255, 210, 80))
	local found = 0
	for _, r in ipairs(info.Recipes) do
		if r.Hidden then
			local l = indexPanel.Text("??? + ??? = ??? (" .. RARITY_NAMES[r.Rarity] .. ")", RARITY_COLORS[r.Rarity], 26)
			l.TextTransparency = 0.3
		else
			found = found + 1
			indexPanel.Text(info.Names[r.A] .. " + " .. info.Names[r.B] .. " = " .. r.Name, Color3.fromRGB(110, 255, 110), 26)
		end
	end
	indexPanel.Text("Found " .. found .. "/" .. #info.Recipes .. " - try fusing different powers!", nil, 26)
	indexPanel.Text("MUTATIONS", Color3.fromRGB(255, 210, 80))
	indexPanel.Text("Neon x1.5  |  Golden x2  |  Corrupted x3", nil, 26)
	indexPanel.Text("Rainbow x5  |  Galaxy x10", nil, 26)
end

----------------------------------------------------------------------
-- FUSION
----------------------------------------------------------------------
local fusionPanel = makePanel("POWER FUSION", Color3.fromRGB(200, 80, 255), 110)
local fusionBottom = Instance.new("Frame")
fusionBottom.Size = UDim2.new(1, -24, 0, 100)
fusionBottom.Position = UDim2.new(0, 12, 1, -108)
fusionBottom.BackgroundTransparency = 1
fusionBottom.Parent = fusionPanel.Frame
local fusionPreview = label(fusionBottom, "Pick 2 powers", UDim2.new(1, 0, 0.4, 0))
local fuseBtn = button(fusionBottom, "FUSE!", Color3.fromRGB(170, 60, 255), UDim2.new(0.6, 0, 0.5, 0), UDim2.new(0.2, 0, 0.48, 0))

local selected = {}
local fusionInfo = nil
local refreshFusion

local function updateFusionPreview()
	if #selected < 2 or not fusionInfo then
		fusionPreview.Text = "Pick 2 powers (" .. #selected .. "/2)"
		return
	end
	local a, b = selected[1], selected[2]
	local cost = math.floor((a.Price + b.Price) * fusionInfo.FuseCostPercent)
	local result = "???"
	for _, r in ipairs(fusionInfo.Recipes) do
		if not r.Hidden and ((r.A == a.Id and r.B == b.Id) or (r.A == b.Id and r.B == a.Id)) then
			result = r.Name
		end
	end
	fusionPreview.Text = a.Name .. " + " .. b.Name .. " = " .. result .. "  ($" .. fmt(cost) .. ")"
end

refreshFusion = function()
	fusionInfo = getInfo()
	selected = {}
	fusionPanel.Clear()
	if not fusionInfo then
		return
	end
	if #fusionInfo.Powers < 2 then
		fusionPanel.Text("You need at least 2 powers in your base!", nil, 30)
	end
	for _, p in ipairs(fusionInfo.Powers) do
		local text = p.Name .. " (" .. RARITY_NAMES[p.Rarity] .. ")  $" .. fmt(p.Income) .. "/s" .. (p.Vault and " [V]" or "")
		local b, l = fusionPanel.ButtonRow(text, "SELECT", Color3.fromRGB(70, 110, 200))
		l.TextColor3 = RARITY_COLORS[p.Rarity]
		b.Activated:Connect(function()
			for i, s in ipairs(selected) do
				if s == p then
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
			table.insert(selected, p)
			b.Text = "PICKED"
			b.BackgroundColor3 = Color3.fromRGB(170, 60, 255)
			updateFusionPreview()
		end)
	end
	updateFusionPreview()
end

fuseBtn.Activated:Connect(function()
	if #selected < 2 then
		showMessage("Pick 2 powers first!")
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
	rebirthPanel.Text("You LOSE: cash, powers outside the vault, bought slots", Color3.fromRGB(255, 120, 120), 26)
	rebirthPanel.Text("You KEEP: vault powers, turret, recipes", Color3.fromRGB(110, 255, 110), 26)
	rebirthPanel.Text("REWARDS", Color3.fromRGB(255, 210, 80))
	rebirthPanel.Text("Every rebirth: +1x money (Rebirth 1 = 2x)", nil, 26)
	rebirthPanel.Text("Rebirth 2 and 5: +1 vault slot", nil, 26)
	rebirthPanel.Text("Rebirth 3+: run faster", nil, 26)
	rebirthPanel.Text("Rebirth 10: exclusive GOLDEN PHOENIX power!", Color3.fromRGB(255, 160, 60), 26)
end

rebirthBtn.Activated:Connect(function()
	local _, msg = requestRemote:InvokeServer("Rebirth")
	showMessage(msg, Color3.fromRGB(255, 210, 60))
	refreshRebirth()
end)

panelRemote.OnClientEvent:Connect(function(name)
	if name == "Fusion" then
		openPanel(fusionPanel, refreshFusion)
	elseif name == "Rebirth" then
		openPanel(rebirthPanel, refreshRebirth)
	end
end)

----------------------------------------------------------------------
-- MENU BUTTONS (right side)
----------------------------------------------------------------------
local menu = Instance.new("Frame")
menu.BackgroundTransparency = 1
menu.Size = UDim2.new(0, 130, 0, 320)
menu.Position = UDim2.new(1, -140, 0.5, -140)
menu.Parent = gui
local menuItems = {
	{ "SHOP", Color3.fromRGB(40, 170, 80), shopPanel, refreshShop },
	{ "BASE", Color3.fromRGB(70, 120, 220), basePanel, refreshBase },
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
-- POWER PROMPTS: only show the ones that make sense for you
----------------------------------------------------------------------
local function updatePrompts(part)
	local state = part:GetAttribute("State")
	local mine = part:GetAttribute("OwnerId") == player.UserId
	local vault = (part:GetAttribute("Slot") or 0) > 100
	local fast = player:GetAttribute("FastSteal") == true
	for _, p in ipairs(part:GetChildren()) do
		if p:IsA("ProximityPrompt") then
			local n = p.Name
			p.Enabled = (n == "Buy" and state == "Market")
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
end

local rainbowParts = {}

local function trackPower(part)
	updatePrompts(part)
	part.AttributeChanged:Connect(function()
		updatePrompts(part)
	end)
	part.ChildAdded:Connect(function()
		updatePrompts(part)
	end)
	if part:GetAttribute("Mut") == "Rainbow" then
		rainbowParts[part] = true
	end
end
for _, part in ipairs(CollectionService:GetTagged("Power")) do
	trackPower(part)
end
CollectionService:GetInstanceAddedSignal("Power"):Connect(trackPower)
CollectionService:GetInstanceRemovedSignal("Power"):Connect(function(part)
	rainbowParts[part] = nil
end)
player:GetAttributeChangedSignal("FastSteal"):Connect(function()
	for _, part in ipairs(CollectionService:GetTagged("Power")) do
		updatePrompts(part)
	end
end)

-- Rainbow mutation: cycle colors
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
	showMessage("Welcome to POWER EMPIRE! Buy powers in the MARKET, steal from others, press F to THROW!", Color3.fromRGB(255, 210, 60))
end)

print("POWER EMPIRE client v4 started OK!")
