--[[
	👹 MOG MONSTERS - GameClient 👹
	===============================
	Put this as a *LocalScript* in StarterPlayer > StarterPlayerScripts.

	Makes all the screens: money, MOG, menus (Shop, Upgrades, Daily,
	Auras, Index, Rebirth), Fusion, MOG battles, THROW button and effects.
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
local panelRemote = remotes:WaitForChild("OpenPanel")
local throwRemote = remotes:WaitForChild("Throw")
local effectRemote = remotes:WaitForChild("Effect")
local requestRemote = remotes:WaitForChild("Request")
local battleRemote = remotes:WaitForChild("Battle")

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
local trainingLabel = label(gui, "", UDim2.new(0, 400, 0, 40), UDim2.new(0.5, -200, 1, -230))
trainingLabel.TextColor3 = Color3.fromRGB(255, 120, 200)
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
	if player:GetAttribute("Training") then
		trainingLabel.Text = "TRAINING MOG...  (E or walk away to stop)"
	else
		trainingLabel.Text = ""
	end
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
-- MOG CLASH (mini game): you vs the monster, click anywhere to push!
----------------------------------------------------------------------
local battleFrame = Instance.new("Frame")
battleFrame.AnchorPoint = Vector2.new(0.5, 1)
battleFrame.Position = UDim2.new(0.5, 0, 1, -120)
battleFrame.Size = UDim2.new(0, 720, 0, 230)
battleFrame.BackgroundTransparency = 1
battleFrame.Visible = false
battleFrame.ZIndex = 10
battleFrame.Parent = gui
local battleScale = Instance.new("UIScale")
battleScale.Parent = battleFrame
local fitBattle = Instance.new("UISizeConstraint")
fitBattle.MaxSize = Vector2.new(720, 230)
fitBattle.Parent = battleFrame

local bTitle = label(battleFrame, "MOG CLASH!", UDim2.new(0.6, 0, 0, 48), UDim2.new(0.2, 0, 0, 0))
bTitle.TextColor3 = Color3.fromRGB(255, 225, 70)
bTitle.TextStrokeTransparency = 0
local titleStroke = Instance.new("UIStroke")
titleStroke.Thickness = 3
titleStroke.Color = Color3.fromRGB(120, 30, 90)
titleStroke.Parent = bTitle

local function circle(parent, pos, color)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0, 84, 0, 84)
	f.Position = pos
	f.BackgroundColor3 = color
	f.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = f
	local st = Instance.new("UIStroke")
	st.Thickness = 4
	st.Color = Color3.new(1, 1, 1)
	st.Parent = f
	return f
end
-- you (left)
local youCircle = circle(battleFrame, UDim2.new(0, 0, 0, 62), Color3.fromRGB(90, 200, 110))
local youImage = Instance.new("ImageLabel")
youImage.Size = UDim2.fromScale(1, 1)
youImage.BackgroundTransparency = 1
youImage.Parent = youCircle
local youCorner = Instance.new("UICorner")
youCorner.CornerRadius = UDim.new(1, 0)
youCorner.Parent = youImage
task.spawn(function()
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if ok and type(img) == "string" then
		youImage.Image = img
	end
end)
local youName = label(battleFrame, "YOU", UDim2.new(0, 120, 0, 30), UDim2.new(0, -18, 0, 150))
youName.TextColor3 = Color3.fromRGB(140, 255, 140)
-- monster (right)
local monCircle = circle(battleFrame, UDim2.new(1, -84, 0, 62), Color3.fromRGB(200, 60, 70))
local monIcon = label(monCircle, "👹", UDim2.fromScale(0.8, 0.8), UDim2.fromScale(0.1, 0.1))
monIcon.TextStrokeTransparency = 1
local monName = label(battleFrame, "", UDim2.new(0, 200, 0, 30), UDim2.new(1, -142, 0, 150))

-- the bar
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, -220, 0, 52)
bar.Position = UDim2.new(0, 110, 0, 78)
bar.BackgroundColor3 = Color3.fromRGB(235, 70, 70)
bar.ClipsDescendants = true
bar.Parent = battleFrame
corner(bar, 14)
local barStroke = Instance.new("UIStroke")
barStroke.Thickness = 4
barStroke.Color = Color3.fromRGB(20, 20, 30)
barStroke.Parent = bar
local redGrad = Instance.new("UIGradient")
redGrad.Color = ColorSequence.new(Color3.fromRGB(255, 120, 90), Color3.fromRGB(200, 30, 50))
redGrad.Rotation = 90
redGrad.Parent = bar
local fill = Instance.new("Frame")
fill.Size = UDim2.new(0.5, 0, 1, 0)
fill.BackgroundColor3 = Color3.new(1, 1, 1)
fill.BorderSizePixel = 0
fill.Parent = bar
local greenGrad = Instance.new("UIGradient")
greenGrad.Color = ColorSequence.new(Color3.fromRGB(170, 255, 120), Color3.fromRGB(50, 190, 80))
greenGrad.Rotation = 90
greenGrad.Parent = fill
local knob = Instance.new("Frame")
knob.Size = UDim2.new(0, 14, 1, 10)
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = UDim2.new(0.5, 0, 0.5, 0)
knob.BackgroundColor3 = Color3.new(1, 1, 1)
knob.Parent = bar
corner(knob, 6)
local greenZone = Instance.new("Frame")
greenZone.Size = UDim2.new(0.2, 0, 1, 0)
greenZone.BackgroundColor3 = Color3.fromRGB(80, 230, 100)
greenZone.BorderSizePixel = 0
greenZone.Parent = bar
local needle = Instance.new("Frame")
needle.Size = UDim2.new(0, 8, 1, 0)
needle.BackgroundColor3 = Color3.new(1, 1, 1)
needle.BorderSizePixel = 0
needle.Parent = bar

local bHelp = label(battleFrame, "", UDim2.new(1, -220, 0, 34), UDim2.new(0, 110, 0, 138))
bHelp.TextStrokeTransparency = 0
local bPower = label(battleFrame, "", UDim2.new(0, 110, 0, 30), UDim2.new(0, 110, 0, 178))
bPower.TextColor3 = Color3.fromRGB(140, 255, 140)
bPower.TextXAlignment = Enum.TextXAlignment.Left
local bTimer = label(battleFrame, "", UDim2.new(0, 110, 0, 30), UDim2.new(1, -220, 0, 178))
bTimer.TextXAlignment = Enum.TextXAlignment.Right
local bScore = label(battleFrame, "", UDim2.new(0, 220, 0, 30), UDim2.new(0.5, -110, 0, 178))
local quitBtn = button(battleFrame, "X", Color3.fromRGB(150, 60, 60), UDim2.new(0, 36, 0, 36), UDim2.new(1, -36, 0, 4))

-- AUTO MOG toggle (always on screen)
local autoMog = false
local autoBtn = button(gui, "AUTO MOG: OFF", Color3.fromRGB(110, 110, 130), UDim2.new(0, 200, 0, 46), UDim2.new(0.5, -100, 1, -64))
autoBtn.Activated:Connect(function()
	autoMog = not autoMog
	autoBtn.Text = autoMog and "AUTO MOG: ON" or "AUTO MOG: OFF"
	autoBtn.BackgroundColor3 = autoMog and Color3.fromRGB(230, 60, 80) or Color3.fromRGB(110, 110, 130)
	showMessage(autoMog and "Auto Mog ON: it clicks for you in battles (clicking yourself is stronger!)" or "Auto Mog OFF")
end)

local battle = nil

local function finishBattle(won)
	local b = battle
	if not b or b.Done then
		return
	end
	b.Done = true
	bTitle.Text = won and "YOU MOGGED IT!" or "IT MOGGED YOU..."
	bTitle.TextColor3 = won and Color3.fromRGB(140, 255, 140) or Color3.fromRGB(255, 110, 110)
	if won and b.Elapsed < 2.2 then
		task.wait(2.2 - b.Elapsed)
	end
	local _, msg = requestRemote:InvokeServer("BattleResult", b.Part, won)
	showMessage(msg or "", won and Color3.fromRGB(110, 255, 110) or Color3.fromRGB(255, 120, 120))
	task.wait(0.8)
	if battle == b then
		battle = nil
		battleFrame.Visible = false
	end
end

local function newGreenZone(b)
	b.ZoneStart = 0.05 + math.random() * (0.9 - b.Info.ZoneWidth)
	greenZone.Position = UDim2.new(b.ZoneStart, 0, 0, 0)
	greenZone.Size = UDim2.new(b.Info.ZoneWidth, 0, 1, 0)
end

local function pop()
	battleScale.Scale = 1.04
	TweenService:Create(battleScale, TweenInfo.new(0.12), { Scale = 1 }):Play()
end

local function battleAction(strength)
	local b = battle
	if not b or b.Done then
		return
	end
	if b.Info.Type == "Clash" then
		b.Progress = b.Progress + (b.Info.ClickPower or 0.07) * (strength or 1)
		pop()
	else
		if b.Needle >= b.ZoneStart and b.Needle <= b.ZoneStart + b.Info.ZoneWidth then
			b.Hits = b.Hits + 1
			greenZone.BackgroundColor3 = Color3.new(1, 1, 1)
			task.delay(0.1, function()
				greenZone.BackgroundColor3 = Color3.fromRGB(80, 230, 100)
			end)
			pop()
			if b.Hits >= 3 then
				task.spawn(finishBattle, true)
				return
			end
			newGreenZone(b)
		else
			b.Misses = b.Misses + 1
			if b.Misses >= 3 then
				task.spawn(finishBattle, false)
			end
		end
	end
end

battleRemote.OnClientEvent:Connect(function(part, info)
	if type(info) ~= "table" then
		return
	end
	battle = { Part = part, Info = info, Time = info.Time or 12, Elapsed = 0, Progress = 0.5, Needle = 0, Dir = 1, Hits = 0, Misses = 0, AutoTimer = 0 }
	bTitle.Text = info.Type == "Clash" and "MOG CLASH!" or "MOG STARE!"
	bTitle.TextColor3 = Color3.fromRGB(255, 225, 70)
	monName.Text = tostring(info.Name)
	monName.TextColor3 = typeof(info.Color) == "Color3" and info.Color or Color3.new(1, 1, 1)
	monCircle.BackgroundColor3 = typeof(info.Color) == "Color3" and info.Color:Lerp(Color3.new(0, 0, 0), 0.25) or Color3.fromRGB(200, 60, 70)
	bPower.Text = "Power x" .. tostring(info.ClickMult or 1)
	local clash = info.Type == "Clash"
	fill.Visible = clash
	knob.Visible = clash
	greenZone.Visible = not clash
	needle.Visible = not clash
	bar.BackgroundColor3 = clash and Color3.fromRGB(235, 70, 70) or Color3.fromRGB(60, 60, 80)
	redGrad.Enabled = clash
	if clash then
		bHelp.Text = "CLICK / TAP / SPACE as fast as you can!"
	else
		bHelp.Text = "CLICK when the needle is in the GREEN zone! (3 times)"
		newGreenZone(battle)
	end
	battleFrame.Visible = true
end)

quitBtn.Activated:Connect(function()
	task.spawn(finishBattle, false)
end)
-- click / tap ANYWHERE on the screen, or press space
UserInputService.InputBegan:Connect(function(input, processed)
	if not battle then
		return
	end
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or (not processed and input.KeyCode == Enum.KeyCode.Space) then
		battleAction(1)
	end
end)

RunService.RenderStepped:Connect(function(dt)
	local b = battle
	if not b or b.Done then
		return
	end
	b.Elapsed = b.Elapsed + dt
	local left = b.Time - b.Elapsed
	bTimer.Text = string.format("%.1fs", math.max(0, left))
	if b.Info.Type == "Clash" then
		if autoMog then
			b.AutoTimer = b.AutoTimer + dt
			if b.AutoTimer >= 0.25 then -- auto mog clicks 4 times per second
				b.AutoTimer = 0
				battleAction(1)
			end
		end
		b.Progress = b.Progress - (b.Info.Pull or 0.3) * dt
		local p = math.clamp(b.Progress, 0, 1)
		fill.Size = UDim2.new(p, 0, 1, 0)
		knob.Position = UDim2.new(p, 0, 0.5, 0)
		bScore.Text = math.floor(p * 100) .. "%"
		if b.Progress >= 1 then
			task.spawn(finishBattle, true)
		elseif b.Progress <= 0 then
			task.spawn(finishBattle, false)
		end
	else
		b.Needle = b.Needle + b.Dir * (b.Info.Speed or 1) * dt
		if b.Needle >= 1 then
			b.Needle, b.Dir = 1, -1
		elseif b.Needle <= 0 then
			b.Needle, b.Dir = 0, 1
		end
		needle.Position = UDim2.new(b.Needle, -4, 0, 0)
		if autoMog then
			local mid = b.ZoneStart + b.Info.ZoneWidth / 2
			if math.abs(b.Needle - mid) < b.Info.ZoneWidth * 0.2 then
				b.AutoTimer = b.AutoTimer + dt
				if b.AutoTimer > 0.05 then
					b.AutoTimer = -0.5
					battleAction(1)
				end
			end
		end
		bScore.Text = "Hits " .. b.Hits .. "/3   Misses " .. b.Misses .. "/3"
	end
	if left <= 0 then
		task.spawn(finishBattle, false)
	end
end)

----------------------------------------------------------------------
-- PANELS
----------------------------------------------------------------------
local panels = {}

local function makePanel(title, color, bottomSpace)
	local frame = box(gui, UDim2.new(0, 480, 0, 440), UDim2.new(0.5, -240, 0.5, -220), Color3.fromRGB(28, 28, 42))
	frame.Visible = false
	frame.ZIndex = 5
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 58)
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	bar.Parent = frame
	corner(bar, 12)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(color or Color3.fromRGB(120, 120, 255), (color or Color3.fromRGB(120, 120, 255)):Lerp(Color3.new(0, 0, 0), 0.4))
	g.Parent = bar
	local t = label(frame, title, UDim2.new(1, -80, 0, 44), UDim2.new(0, 16, 0, 8))
	t.TextColor3 = Color3.new(1, 1, 1)
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
-- CARD SHOPS (pretty cards side by side)
----------------------------------------------------------------------
local TIER_COLORS = {
	Common = { Color3.fromRGB(190, 195, 205), Color3.fromRGB(120, 125, 140) },
	Rare = { Color3.fromRGB(100, 185, 255), Color3.fromRGB(40, 90, 210) },
	Epic = { Color3.fromRGB(210, 120, 255), Color3.fromRGB(120, 40, 210) },
	Legendary = { Color3.fromRGB(255, 215, 80), Color3.fromRGB(240, 120, 20) },
	Mythic = { Color3.fromRGB(255, 100, 160), Color3.fromRGB(200, 30, 90) },
	Secret = { Color3.fromRGB(70, 70, 85), Color3.fromRGB(15, 15, 20) },
	Divine = "rainbow",
}
local RAINBOW_SEQ = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 230, 120)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(70, 160, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 80, 255)),
})

local function gradient(parent, colors, rotation)
	local g = Instance.new("UIGradient")
	if colors == "rainbow" then
		g.Color = RAINBOW_SEQ
	else
		g.Color = ColorSequence.new(colors[1], colors[2])
	end
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

-- spinning 3D previews inside cards
local spinners = {}
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for model, info in pairs(spinners) do
		if not model.Parent then
			spinners[model] = nil
		else
			model:PivotTo(CFrame.new(0, math.sin(t * 2) * 0.15, 0) * CFrame.Angles(0, t * 1.2, 0))
			if info.Rainbow then
				local c = Color3.fromHSV((t * 0.3) % 1, 0.8, 1)
				for _, p in ipairs(info.Rainbow) do
					p.Color = c
				end
			end
		end
	end
end)

local function viewport(parent)
	local vf = Instance.new("ViewportFrame")
	vf.Size = UDim2.fromScale(1, 1)
	vf.BackgroundTransparency = 1
	vf.Ambient = Color3.fromRGB(200, 200, 200)
	vf.LightColor = Color3.new(1, 1, 1)
	vf.LightDirection = Vector3.new(-1, -1, -1)
	vf.Parent = parent
	local cam = Instance.new("Camera")
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 0.6, -9), Vector3.new(0, 0, 0))
	cam.FieldOfView = 45
	cam.Parent = vf
	vf.CurrentCamera = cam
	local model = Instance.new("Model")
	model.Parent = vf
	return vf, model
end

local function vpPart(model, size, cf, color, material, shape, transparency)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Transparency = transparency or 0
	p.Parent = model
	if not model.PrimaryPart then
		model.PrimaryPart = p
	end
	return p
end

-- a little player figure with an aura around it
local function auraPreview(parent, color, rainbow)
	local _, model = viewport(parent)
	local body = Color3.fromRGB(235, 235, 240)
	vpPart(model, Vector3.new(2, 2, 1), CFrame.new(0, 0, 0), body)
	vpPart(model, Vector3.new(1.25, 1.25, 1.25), CFrame.new(0, 1.65, 0), Color3.fromRGB(255, 220, 180), nil, Enum.PartType.Ball)
	for _, sx in ipairs({ -1, 1 }) do
		vpPart(model, Vector3.new(1, 2, 1), CFrame.new(sx * 1.5, 0, 0), body)
		vpPart(model, Vector3.new(1, 2, 1), CFrame.new(sx * 0.5, -2, 0), Color3.fromRGB(80, 90, 120))
	end
	local glow = {}
	table.insert(glow, vpPart(model, Vector3.new(6.2, 6.2, 6.2), CFrame.new(0, 0, 0), color, Enum.Material.Neon, Enum.PartType.Ball, 0.78))
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		table.insert(glow, vpPart(model, Vector3.new(0.5, 0.5, 0.5), CFrame.new(math.cos(a) * 2.6, math.sin(a * 2) * 1.8, math.sin(a) * 2.6), color, Enum.Material.Neon, Enum.PartType.Ball))
	end
	spinners[model] = { Rainbow = rainbow and glow or nil }
end

local function makeCardPanel(title, headerColors)
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(0.82, 0.66)
	frame.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
	frame.Visible = false
	frame.ZIndex = 5
	frame.Parent = gui
	corner(frame, 18)
	local st = Instance.new("UIStroke")
	st.Thickness = 4
	st.Color = Color3.fromRGB(15, 15, 22)
	st.Parent = frame
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(860, 480)
	limit.MinSize = Vector2.new(400, 320)
	limit.Parent = frame

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 58)
	header.BackgroundColor3 = Color3.new(1, 1, 1)
	header.Parent = frame
	corner(header, 18)
	gradient(header, headerColors, 0)
	local t = label(header, title, UDim2.new(1, -90, 0.8, 0), UDim2.new(0, 18, 0.1, 0))
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextStrokeTransparency = 0
	local close = button(header, "X", Color3.fromRGB(230, 60, 60), UDim2.new(0, 46, 0, 46), UDim2.new(1, -56, 0, 6))
	close.Activated:Connect(function()
		frame.Visible = false
	end)

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -24, 1, -74)
	list.Position = UDim2.new(0, 12, 0, 66)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 8
	list.ScrollingDirection = Enum.ScrollingDirection.X
	list.AutomaticCanvasSize = Enum.AutomaticSize.X
	list.CanvasSize = UDim2.new()
	list.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
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
	-- opts: Title, Tag, Colors, Icon, Preview(function(area)), Badge, Info, Button, ButtonColor, OnClick, Wide
	function panel.Card(opts)
		panel.Order = panel.Order + 1
		local card = Instance.new("Frame")
		card.Size = UDim2.new(0, opts.Wide and 300 or 172, 1, -14)
		card.BackgroundColor3 = Color3.new(1, 1, 1)
		card.LayoutOrder = panel.Order
		card.Parent = list
		corner(card, 16)
		gradient(card, opts.Colors or TIER_COLORS.Common, 90)
		local cs = Instance.new("UIStroke")
		cs.Thickness = 3
		cs.Color = Color3.fromRGB(255, 255, 255)
		cs.Transparency = 0.2
		cs.Parent = card

		local ttl = label(card, opts.Title or "", UDim2.new(1, -12, 0.11, 0), UDim2.new(0, 6, 0.02, 0))
		ttl.TextStrokeTransparency = 0
		if opts.Tag then
			local tag = label(card, opts.Tag, UDim2.new(1, -12, 0.07, 0), UDim2.new(0, 6, 0.13, 0))
			tag.TextColor3 = opts.TagColor or Color3.new(1, 1, 1)
			tag.TextStrokeTransparency = 0.2
		end
		local area = Instance.new("Frame")
		area.Size = UDim2.new(1, -16, 0.42, 0)
		area.Position = UDim2.new(0, 8, 0.21, 0)
		area.BackgroundColor3 = Color3.new(0, 0, 0)
		area.BackgroundTransparency = 0.75
		area.Parent = card
		corner(area, 12)
		if opts.Preview then
			opts.Preview(area)
		elseif opts.Icon then
			local ic = label(area, opts.Icon, UDim2.fromScale(0.9, 0.9), UDim2.fromScale(0.05, 0.05))
			ic.TextStrokeTransparency = 1
		end
		if opts.Lines then
			local txt = label(area, table.concat(opts.Lines, "\n"), UDim2.new(1, -12, 1, -8), UDim2.new(0, 6, 0, 4))
			txt.TextXAlignment = Enum.TextXAlignment.Left
			txt.TextYAlignment = Enum.TextYAlignment.Top
		end
		if opts.Badge then
			local pill = Instance.new("Frame")
			pill.Size = UDim2.new(0.86, 0, 0.1, 0)
			pill.Position = UDim2.new(0.07, 0, 0.65, 0)
			pill.BackgroundColor3 = opts.BadgeColor or Color3.fromRGB(70, 210, 100)
			pill.Parent = card
			corner(pill, 10)
			stroke(pill)
			label(pill, opts.Badge, UDim2.new(1, -8, 0.86, 0), UDim2.new(0, 4, 0.07, 0))
		end
		if opts.Info then
			local inf = label(card, opts.Info, UDim2.new(1, -12, 0.07, 0), UDim2.new(0, 6, 0.76, 0))
			inf.TextStrokeTransparency = 0.2
		end
		local b = button(card, opts.Button or "", opts.ButtonColor or Color3.fromRGB(60, 200, 90), UDim2.new(0.86, 0, 0.13, 0), UDim2.new(0.07, 0, 0.84, 0))
		if opts.OnClick then
			b.Activated:Connect(opts.OnClick)
		end
		return card, b
	end
	table.insert(panels, panel)
	return panel
end

local BUY_GREEN = Color3.fromRGB(60, 200, 90)
local EQUIP_BLUE = Color3.fromRGB(60, 140, 240)
local DONE_GRAY = Color3.fromRGB(110, 110, 120)

----------------------------------------------------------------------
-- SHOP (Robux)
----------------------------------------------------------------------
local shopPanel = makeCardPanel("ROBUX SHOP", { Color3.fromRGB(60, 210, 110), Color3.fromRGB(20, 140, 200) })

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
	{ Title = "2x MONEY", Icon = "💰", Info = "Forever!", Badge = "x2 Money", Attr = "DoubleMoneyPassId", Pass = true, Owned = "DoubleMoney", Tier = "Legendary" },
	{ Title = "2x MOG", Icon = "💪", Info = "Forever!", Badge = "x2 MOG", Attr = "DoubleMogPassId", Pass = true, Owned = "DoubleMog", Tier = "Mythic" },
	{ Title = "VIP", Icon = "👑", Info = "Tag + 2x daily", Badge = "+20% Money", Attr = "VipPassId", Pass = true, Owned = "VIP", Tier = "Divine" },
	{ Title = "BIG ENCLOSURE", Icon = "🏠", Info = "Forever!", Badge = "+5 Monsters", Attr = "ExtraSlotsPassId", Pass = true, Owned = "ExtraSlots", Tier = "Rare" },
	{ Title = "SERVER LUCK", Icon = "🍀", Info = "15 min, everyone!", Badge = "x2 Luck", Attr = "ServerLuckProductId", Tier = "Epic" },
	{ Title = "CASH PACK", Icon = "💵", Info = "10 min of income", Badge = "Instant cash", Attr = "CashPackProductId", Tier = "Common" },
}

local function refreshShop()
	shopPanel.Clear()
	for _, item in ipairs(SHOP_ITEMS) do
		local owned = item.Owned and player:GetAttribute(item.Owned)
		shopPanel.Card({
			Title = item.Title, Tag = item.Pass and "Game Pass" or "Boost", Colors = TIER_COLORS[item.Tier],
			Icon = item.Icon, Badge = item.Badge, Info = item.Info,
			Button = owned and "OWNED" or "R$ BUY", ButtonColor = owned and DONE_GRAY or BUY_GREEN,
			OnClick = function()
				if not owned then
					promptBuy(item.Attr, item.Pass)
				end
			end,
		})
	end
end
player.AttributeChanged:Connect(function(name)
	if shopPanel.Frame.Visible and (name == "DoubleMoney" or name == "DoubleMog" or name == "VIP" or name == "ExtraSlots") then
		refreshShop()
	end
end)

----------------------------------------------------------------------
-- UPGRADES
----------------------------------------------------------------------
local upgradePanel = makeCardPanel("UPGRADES", { Color3.fromRGB(80, 160, 255), Color3.fromRGB(120, 80, 255) })

local refreshUpgrades
local function buy(action, refresh)
	local _, msg = requestRemote:InvokeServer(action)
	showMessage(msg)
	refresh()
end

refreshUpgrades = function()
	local info = getInfo()
	upgradePanel.Clear()
	if not info then
		return
	end
	upgradePanel.Card({
		Title = "HAMMER", Tag = "Level " .. info.Hammer .. "/" .. info.MaxHammer, Colors = TIER_COLORS.Legendary, Icon = "🔨",
		Badge = info.NextHammerPower and ("+" .. fmt(info.HammerPower) .. " -> +" .. fmt(info.NextHammerPower)) or ("+" .. fmt(info.HammerPower) .. " MOG"),
		Info = "MOG per hit",
		Button = info.NextHammerCost and ("$" .. fmt(info.NextHammerCost)) or "MAX", ButtonColor = info.NextHammerCost and BUY_GREEN or DONE_GRAY,
		OnClick = function()
			buy("BuyHammer", refreshUpgrades)
		end,
	})
	upgradePanel.Card({
		Title = "SWING SPEED", Tag = "Level " .. info.Swing .. "/" .. info.MaxSwing, Colors = TIER_COLORS.Rare, Icon = "⚡",
		Badge = info.NextSwingTime and (info.SwingTime .. "s -> " .. info.NextSwingTime .. "s") or (info.SwingTime .. "s"),
		Info = "time between hits",
		Button = info.NextSwingCost and ("$" .. fmt(info.NextSwingCost)) or "MAX", ButtonColor = info.NextSwingCost and BUY_GREEN or DONE_GRAY,
		OnClick = function()
			buy("BuySwing", refreshUpgrades)
		end,
	})
	local slotsMaxed = info.BaseSlots >= info.MaxSlots
	upgradePanel.Card({
		Title = "ENCLOSURE", Tag = info.Slots .. " monsters", Colors = TIER_COLORS.Epic, Icon = "🏠",
		Badge = slotsMaxed and "MAX SIZE" or (info.Slots .. " -> " .. (info.Slots + 1)),
		Info = "room for monsters",
		Button = slotsMaxed and "MAX" or ("$" .. fmt(info.SlotCost)), ButtonColor = slotsMaxed and DONE_GRAY or BUY_GREEN,
		OnClick = function()
			buy("BuySlot", refreshUpgrades)
		end,
	})
	upgradePanel.Card({
		Title = "MONEY BOOST", Tag = "x" .. info.Boost, Colors = TIER_COLORS.Mythic, Icon = "💸",
		Badge = info.NextBoost and ("x" .. info.Boost .. " -> x" .. info.NextBoost) or ("x" .. info.Boost),
		Info = "monsters earn more",
		Button = info.BoostCost and ("$" .. fmt(info.BoostCost)) or "MAX", ButtonColor = info.BoostCost and BUY_GREEN or DONE_GRAY,
		OnClick = function()
			buy("BuyBoost", refreshUpgrades)
		end,
	})
	upgradePanel.Card({
		Title = "YOUR MOG", Tag = "+" .. fmt(info.MogPerHit) .. " per hit", Colors = TIER_COLORS.Secret, Icon = "💪",
		Badge = fmt(info.Mog) .. " MOG", BadgeColor = Color3.fromRGB(255, 110, 200),
		Info = "train at your MOG STONE",
		Button = "TRAIN!", ButtonColor = EQUIP_BLUE,
		OnClick = function()
			showMessage("Go to the MOG STONE next to your enclosure and press E!")
		end,
	})
end

----------------------------------------------------------------------
-- AURAS
----------------------------------------------------------------------
local auraPanel = makeCardPanel("AURAS", { Color3.fromRGB(255, 120, 220), Color3.fromRGB(140, 80, 255) })

local refreshAuras
refreshAuras = function()
	local info = getInfo()
	auraPanel.Clear()
	if not info then
		return
	end
	for _, a in ipairs(info.Auras) do
		local text, color
		if info.Aura == a.Name then
			text, color = "UNEQUIP", DONE_GRAY
		elseif a.Owned then
			text, color = "EQUIP", EQUIP_BLUE
		else
			text, color = "$" .. fmt(a.Cost), BUY_GREEN
		end
		auraPanel.Card({
			Title = a.Name, Tag = a.Tier, TagColor = Color3.new(1, 1, 1), Colors = TIER_COLORS[a.Tier] or TIER_COLORS.Common,
			Preview = function(area)
				auraPreview(area, a.Color, a.Tier == "Divine")
			end,
			Badge = "x" .. a.Mult .. " MOG",
			Button = text, ButtonColor = color,
			OnClick = function()
				local action = info.Aura == a.Name and "UnequipAura" or (a.Owned and "EquipAura" or "BuyAura")
				local _, msg = requestRemote:InvokeServer(action, a.Name)
				showMessage(msg)
				refreshAuras()
			end,
		})
	end
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
		local odds = m.Exclusive and "Rebirth 10 only" or ("Zone " .. m.Zone .. (m.Odds > 1 and (", 1 in " .. fmt(m.Odds)) or ""))
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
local LEVEL_NAMES = { "Normal", "Silver", "Golden", "Diamond", "Rainbow", "Cosmic", "Rainbow Cosmic" }

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
		local text = m.Name .. "  $" .. fmt(m.Income) .. "/s"
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
local rebirthPanel = makeCardPanel("REBIRTH", { Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 90, 60) })

local function refreshRebirth()
	local info = getInfo()
	rebirthPanel.Clear()
	if not info then
		return
	end
	local now, nextR = 1 + info.Rebirths, 2 + info.Rebirths
	local enough = info.Cash >= info.RebirthCost
	rebirthPanel.Card({
		Title = "REBIRTH " .. (info.Rebirths + 1), Tag = "You have " .. info.Rebirths, Colors = TIER_COLORS.Legendary, Icon = "🔄",
		Badge = "x" .. now .. " -> x" .. nextR, Info = "MOG + money forever",
		Button = enough and "REBIRTH!" or ("$" .. fmt(info.RebirthCost)), ButtonColor = enough and BUY_GREEN or DONE_GRAY,
		OnClick = function()
			local _, msg = requestRemote:InvokeServer("Rebirth")
			showMessage(msg, Color3.fromRGB(255, 210, 60))
			refreshRebirth()
		end,
	})
	rebirthPanel.Card({
		Title = "PROGRESS", Tag = "$" .. fmt(info.Cash) .. " / $" .. fmt(info.RebirthCost), Colors = TIER_COLORS.Rare,
		Icon = math.floor(math.clamp(info.Cash / info.RebirthCost, 0, 1) * 100) .. "%",
		Badge = enough and "READY!" or "Keep going!", BadgeColor = enough and Color3.fromRGB(70, 210, 100) or Color3.fromRGB(240, 150, 40),
		Button = "OK", ButtonColor = DONE_GRAY,
	})
	rebirthPanel.Card({
		Title = "YOU KEEP", Tag = "after rebirth", Colors = TIER_COLORS.Epic,
		Lines = { "Your auras", "Your index", "Your rebirth bonus" },
		Badge = "SAFE", Button = "OK", ButtonColor = DONE_GRAY,
	})
	rebirthPanel.Card({
		Title = "YOU LOSE", Tag = "after rebirth", Colors = TIER_COLORS.Mythic,
		Lines = { "Cash and MOG", "Your monsters", "Hammer, speed,", "enclosure, boost" },
		Badge = "RESET", BadgeColor = Color3.fromRGB(230, 70, 70), Button = "OK", ButtonColor = DONE_GRAY,
	})
	rebirthPanel.Card({
		Title = "REBIRTH 10", Tag = "special reward", Colors = TIER_COLORS.Divine, Icon = "🔥",
		Badge = "Golden Phoenixmog", Info = "+ faster from Rebirth 3",
		Button = info.Rebirths >= 10 and "UNLOCKED" or "LOCKED", ButtonColor = DONE_GRAY,
	})
end

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
menu.Size = UDim2.new(0, 140, 0, 384)
menu.Position = UDim2.new(1, -150, 0.5, -180)
menu.Parent = gui
local menuItems = {
	{ "SHOP", Color3.fromRGB(40, 170, 80), shopPanel, refreshShop },
	{ "UPGRADES", Color3.fromRGB(70, 120, 220), upgradePanel, refreshUpgrades },
	{ "AURAS", Color3.fromRGB(220, 90, 220), auraPanel, refreshAuras },
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
	for _, p in ipairs(part:GetChildren()) do
		if p:IsA("ProximityPrompt") then
			local n = p.Name
			p.Enabled = (n == "Mog" and state == "Lane")
				or (n == "Sell" and state == "Placed" and mine)
				or (n == "Grab" and state == "Loose")
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
local animated = {}

-- find the moving body parts (legs, arms, wings, tails)
local function collectLimbs(part)
	local limbs = {}
	for _, d in ipairs(part:GetDescendants()) do
		if d:IsA("Weld") and d.Name == "LimbWeld" and d.Part1 then
			local p = d.Part1
			table.insert(limbs, {
				Weld = d, Base = d.C0, Kind = p:GetAttribute("Limb") or "walk",
				Phase = p:GetAttribute("Phase") or 0, Pivot = p:GetAttribute("Pivot") or Vector3.new(),
				Amp = p:GetAttribute("Amp") or 0.4,
			})
		end
	end
	if #limbs > 0 then
		animated[part] = {
			Limbs = limbs, Last = part.Position, Phase = 0, Intensity = 0,
			Stride = 4 / math.max(part.Size.Magnitude, 1),
		}
	end
end

local function trackMonster(part)
	updateMonster(part)
	collectLimbs(part)
	part.AttributeChanged:Connect(function()
		updateMonster(part)
	end)
	local pending = false
	part.DescendantAdded:Connect(function()
		updateMonster(part)
		if not pending then
			pending = true
			task.delay(0.2, function()
				pending = false
				if part.Parent then
					collectLimbs(part)
				end
			end)
		end
	end)
	local v = part:GetAttribute("Variant")
	if v == "Rainbow" or v == "Rainbow Cosmic" then
		local skins = {}
		if part:GetAttribute("Skin") then
			table.insert(skins, part)
		end
		for _, d in ipairs(part:GetDescendants()) do
			if d:IsA("BasePart") and d:GetAttribute("Skin") then
				table.insert(skins, d)
			end
		end
		rainbowParts[part] = skins
	end
end
for _, part in ipairs(CollectionService:GetTagged("Monster")) do
	trackMonster(part)
end
CollectionService:GetInstanceAddedSignal("Monster"):Connect(trackMonster)
CollectionService:GetInstanceRemovedSignal("Monster"):Connect(function(part)
	rainbowParts[part] = nil
	animated[part] = nil
end)

-- walking animation: legs and arms swing while the monster moves,
-- wings flap and tails wag (only for monsters close to you)
RunService.RenderStepped:Connect(function(dt)
	local camPos = camera.CFrame.Position
	local t = os.clock()
	for part, a in pairs(animated) do
		if not part.Parent then
			animated[part] = nil
		else
			local pos = part.Position
			if (pos - camPos).Magnitude < 200 then
				local moved = Vector3.new(pos.X - a.Last.X, 0, pos.Z - a.Last.Z).Magnitude
				a.Last = pos
				local speed = dt > 0 and moved / dt or 0
				if speed > 40 then
					speed, moved = 0, 0 -- teleported / flying home
				end
				local target = math.clamp(speed / 3, 0, 1)
				a.Intensity = a.Intensity + (target - a.Intensity) * math.min(1, dt * 6)
				a.Phase = a.Phase + moved * a.Stride * 2.5
				for _, l in ipairs(a.Limbs) do
					local rot
					if l.Kind == "walk" then
						rot = CFrame.Angles(math.sin(a.Phase + l.Phase * math.pi) * l.Amp * a.Intensity, 0, 0)
					elseif l.Kind == "flap" then
						local side = l.Phase == 0 and 1 or -1
						rot = CFrame.Angles(0, 0, math.sin(t * (2.5 + a.Intensity * 5)) * l.Amp * side)
					else
						rot = CFrame.Angles(0, math.sin(t * (2 + a.Intensity * 4) + l.Phase * 6) * l.Amp, 0)
					end
					l.Weld.C0 = CFrame.new(l.Pivot) * rot * CFrame.new(-l.Pivot) * l.Base
				end
			else
				a.Last = pos
			end
		end
	end
end)
local function refreshAllMonsters()
	for _, part in ipairs(CollectionService:GetTagged("Monster")) do
		updateMonster(part)
	end
end
player:GetAttributeChangedSignal("Mog"):Connect(refreshAllMonsters)

RunService.RenderStepped:Connect(function()
	local color = Color3.fromHSV((os.clock() * 0.3) % 1, 1, 1)
	for _, skins in pairs(rainbowParts) do
		for _, p in ipairs(skins) do
			p.Color = color
		end
	end
end)

----------------------------------------------------------------------
-- WELCOME
----------------------------------------------------------------------
task.delay(2, function()
	showMessage("Welcome to MOG MONSTERS! Train at your MOG STONE, then win MOG BATTLES on the MOG ROAD!", Color3.fromRGB(255, 210, 60))
end)

print("MOG MONSTERS client v6 started OK!")
