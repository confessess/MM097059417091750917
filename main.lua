do
	local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))();
	local Players = game:GetService("Players");
	local RunService = game:GetService("RunService");
	local ReplicatedStorage = game:GetService("ReplicatedStorage");
	local Workspace = game:GetService("Workspace");
	local CurrentCamera = Workspace.CurrentCamera;
	local LocalPlayer = Players.LocalPlayer;
	local CoreGui = game:GetService("CoreGui");
	local UserInputService = game:GetService("UserInputService");
	local HttpService = game:GetService("HttpService");
	local TeleportService = game:GetService("TeleportService");
	
	-- ==========================================
	-- CONNECTION TRACKING FOR TOGGLE SYSTEM
	-- ==========================================
	local ActiveConnections = {
		RenderStepped = {},
		Stepped = {},
		Heartbeat = {},
		PlayerRemoving = {},
		ChildAdded = {},
		OnTeleport = {}
	}
	local ScriptEnabled = true
	local GUIVisible = true
	local CtrlPressed = false
	local GUIToggleButton = nil
	local GUIToggleGui = nil
	
	-- Silent Aimbot Variables
	local SilentAimbot = {
		Enabled = false,
		TargetPart = "Head",
		FOV = 100,
		WallCheck = true,
		TeamCheck = false,
		Prediction = 0.165,
		CircleVisible = true,
		CircleColor = Color3.fromRGB(255, 255, 255),
		CircleRadius = 100,
		SelectedTarget = nil,
		Connection = nil
	}
	
	function gradient(text, startColor, endColor)
		local result = "";
		local length = #text;
		for i = 1, length do
			local t = (i - 1) / math.max(length - 1 , 1) ;
			local r = math.floor((startColor.R + ((endColor.R - startColor.R) * t)) * 255 );
			local g = math.floor((startColor.G + ((endColor.G - startColor.G) * t)) * 255 );
			local b = math.floor((startColor.B + ((endColor.B - startColor.B) * t)) * 255 );
			local char = text:sub(i, i);
			result = result   .. '<font color=\"rgb('   .. r   .. ", "   .. g   .. ", "   .. b   .. ')\">'   .. char   .. "</font>" ;
		end
		return result;
	end
	
	-- GUI Toggle Button
	local function CreateGUIToggleButton()
		if GUIToggleGui then return end
		GUIToggleGui = Instance.new("ScreenGui")
		GUIToggleGui.Name = "LightHub_GUIToggle"
		GUIToggleGui.ResetOnSpawn = false
		GUIToggleGui.DisplayOrder = 1000
		pcall(function()
			if typeof(gethui) == "function" then GUIToggleGui.Parent = gethui()
			else GUIToggleGui.Parent = game:GetService("CoreGui") end
		end)

		GUIToggleButton = Instance.new("TextButton")
		GUIToggleButton.Size = UDim2.fromOffset(50, 50)
		GUIToggleButton.Position = UDim2.new(0, 10, 0.5, -25)
		GUIToggleButton.BackgroundColor3 = Color3.fromRGB(30, 64, 175)
		GUIToggleButton.Text = "LH"
		GUIToggleButton.TextSize = 18
		GUIToggleButton.Font = Enum.Font.GothamBold
		GUIToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		GUIToggleButton.BorderSizePixel = 0
		GUIToggleButton.Active = true
		GUIToggleButton.Draggable = true

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = GUIToggleButton

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(59, 130, 246)
		stroke.Thickness = 2
		stroke.Parent = GUIToggleButton

		GUIToggleButton.MouseButton1Click:Connect(function()
			if GUIVisible then
				Window:Close()
				GUIVisible = false
			else
				Window:Open()
				GUIVisible = true
			end
		end)

		GUIToggleButton.Parent = GUIToggleGui
	end

	local Confirmed = false;
	WindUI:Popup({
		Title = "Murder Mystery 2",
		Icon = "rbxassetid://81641581642129",
		Content = "Updates in"   .. " Discord.gg/feuds" ,
		Buttons = {
			{
				Title = "Cancel",
				Callback = function()
				end,
				Variant = "Tertiary"
			},
			{
				Title = "Load",
				Callback = function()
					Confirmed = true;
				end,
				Variant = "Secondary"
			}
		}
	});
	repeat
		task.wait();
	until Confirmed
	
	WindUI:Notify({
		Title = "Murder Mystery 2",
		Content = "Script successfully loaded! Press Ctrl+M to toggle",
		Icon = "check-circle",
		Duration = 5
	});
	
	WindUI:AddTheme({
		Name = "BlueTheme",
		Accent = "#1E40AF",
		Outline = "#3B82F6",
		Text = "#FFFFFF",
		Background = "#0F172A"
	})

	local Window = WindUI:CreateWindow({
		Title = "Light Hub MM2",
		Icon = "rbxassetid://81641581642129",
		Author = "Light Hub",
		Folder = "MM2WindUI",
		Size = UDim2.fromOffset(350, 400),
		Transparent = false,
		Theme = "BlueTheme",
		SideBarWidth = 200,
		UserEnabled = true,
		HasOutline = true
	});
	
	CreateGUIToggleButton()

	Window:EditOpenButton({
		Title = "Open UI",
		Icon = "rbxassetid://81641581642129",
		CornerRadius = UDim.new(2, 6),
		StrokeThickness = 2,
		Color = ColorSequence.new(Color3.fromHex("1E3A8A"), Color3.fromHex("3B82F6")),
		Draggable = true
	});
	
	local Tabs = {
		CharacterTab = Window:Tab({
			Title = "CHARACTER",
			Icon = "file-cog"
		}),
		TeleportTab = Window:Tab({
			Title = "TELEPORT",
			Icon = "user"
		}),
		EspTab = Window:Tab({
			Title = "ESP",
			Icon = "eye"
		}),
		AimbotTab = Window:Tab({
			Title = "AIMBOT",
			Icon = "arrow-right"
		}),
		AutoFarm = Window:Tab({
			Title = "AUTOFARM",
			Icon = "user"
		}),
		bs = Window:Divider(),
		InnocentTab = Window:Tab({
			Title = "INNOCENT",
			Icon = "circle"
		}),
		MurderTab = Window:Tab({
			Title = "MURDER",
			Icon = "circle"
		}),
		SheriffTab = Window:Tab({
			Title = "SHERIFF",
			Icon = "circle"
		}),
		gh = Window:Divider(),
		ServerTab = Window:Tab({
			Title = "SERVER",
			Icon = "atom",
			Desc = "Server management tools"
		}),
		SettingsTab = Window:Tab({
			Title = "SETTINGS",
			Icon = "code"
		}),
		b = Window:Divider(),
		WindowTab = Window:Tab({
			Title = "CONFIGURATION",
			Icon = "settings",
			Desc = "Manage window settings and file configurations."
		}),
		CreateThemeTab = Window:Tab({
			Title = "THEMES",
			Icon = "palette",
			Desc = "Design and apply custom themes."
		}),
	};
	
	-- ==========================================
	-- MONO FEATURES BACKEND
	-- ==========================================
	local MonoFlags = {
		silentAim = false, aimbot = false, showFov = false, autoKill = false,
		gunWalls = false, knifeWalls = false, instantKnife = false,
		fly = false, flySpeed = 60, infJump = false,
		fullbright = false,
		murdererNotify = false, killFeed = false,
		flingPower = 10000, flingSeconds = 1,
	}

	local Lighting = game:GetService("Lighting")
	local monoConns = {}
	local function monoBind(sig, fn)
		local c = sig:Connect(fn)
		table.insert(monoConns, c)
		return c
	end

	local function getHRP(ch) return ch and ch:FindFirstChild("HumanoidRootPart") end

	local function monoNotify(title, content, icon, dur)
		WindUI:Notify({ Title = title, Content = content, Icon = icon or "info", Duration = dur or 3 })
	end

	local CRC = nil
	pcall(function() CRC = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CurrentRoundClient")) end)
	local function roundData(plr) return CRC and CRC.PlayerData and CRC.PlayerData[plr.Name] end

	local function computeRole(plr)
		local d = roundData(plr)
		local r = d and d.Role
		if r == "Murderer" then return "Murderer" end
		if r == "Sheriff" or r == "Hero" then return r end
		return r or "Innocent"
	end

	local function computeAlive(plr)
		local d = roundData(plr); if d and d.Dead == true then return false end
		local ch = plr.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		return ch and hum and hum.Health > 0 and getHRP(ch)
	end

	local roleCache, aliveCache, cacheStamp = {}, {}, 0
	local function sweepCaches()
		local now = os.clock()
		if now - cacheStamp > 0.05 then
			table.clear(roleCache); table.clear(aliveCache); cacheStamp = now
		end
	end

	local function roleOf(plr)
		sweepCaches()
		local v = roleCache[plr]
		if v == nil then v = computeRole(plr); roleCache[plr] = v end
		return v
	end

	local function alive(plr)
		sweepCaches()
		local v = aliveCache[plr]
		if v == nil then v = computeAlive(plr) or false; aliveCache[plr] = v end
		return v
	end

	local function myRole() return roleOf(LocalPlayer) end
	local function isGunRole(role) return role == "Sheriff" or role == "Hero" end

	local function findMurderer()
		for _, p in ipairs(Players:GetPlayers()) do
			if roleOf(p) == "Murderer" then return p end
		end
	end

	local function findWeapon(n)
		local ch = LocalPlayer.Character; local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
		return (ch and ch:FindFirstChild(n)) or (bp and bp:FindFirstChild(n))
	end

	local function equip(tool)
		local ch = LocalPlayer.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if tool and hum and tool.Parent ~= ch then pcall(function() hum:EquipTool(tool) end) end
	end

	local aimFov = 120
	local function fovTarget()
		local mr = myRole()
		local center = UserInputService:GetMouseLocation()
		local best, bd
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and alive(p) then
				local pr = roleOf(p)
				if (mr == "Murderer") or (isGunRole(mr) and pr == "Murderer") then
					local hrp = getHRP(p.Character)
					if hrp then
						local v, on = CurrentCamera:WorldToViewportPoint(hrp.Position)
						if on and v.Z > 0 then
							local d = (Vector2.new(v.X, v.Y) - center).Magnitude
							if d <= aimFov and (not bd or d < bd) then bd, best = d, p end
						end
					end
				end
			end
		end
		return best
	end

	local MonoFovCircle = Drawing.new("Circle")
	MonoFovCircle.Visible = false
	MonoFovCircle.Thickness = 1.5
	MonoFovCircle.NumSides = 64
	MonoFovCircle.Radius = aimFov
	MonoFovCircle.Color = Color3.fromRGB(59, 130, 246)
	MonoFovCircle.Filled = false

	monoBind(RunService.RenderStepped, function()
		if MonoFlags.showFov and (MonoFlags.aimbot or MonoFlags.silentAim) then
			MonoFovCircle.Visible = true
			MonoFovCircle.Radius = aimFov
			MonoFovCircle.Position = UserInputService:GetMouseLocation()
		else
			MonoFovCircle.Visible = false
		end
		if MonoFlags.aimbot then
			local t = fovTarget()
			if t then
				local th = t.Character:FindFirstChild("Head") or getHRP(t.Character)
				if th then
					CurrentCamera.CFrame = CurrentCamera.CFrame:Lerp(CFrame.new(CurrentCamera.CFrame.Position, th.Position), 0.45)
				end
			end
		end
	end)

	local KNIFE_PARTS = { "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso", "Head" }
	local function knifeKill(ev, targetChar)
		if not (ev and targetChar) then return end
		local ht = ev:FindFirstChild("HandleTouched"); local ks = ev:FindFirstChild("KnifeStabbed")
		if not ht then return end
		if ks then ks:FireServer() end
		for _, pn in ipairs(KNIFE_PARTS) do
			local part = targetChar:FindFirstChild(pn)
			if part then ht:FireServer(part) return end
		end
	end

	task.spawn(function()
		while true do
			pcall(function()
				if MonoFlags.autoKill then
					local role = myRole()
					if role == "Murderer" then
						local knife = findWeapon("Knife"); local ev = knife and knife:FindFirstChild("Events")
						if ev then
							equip(knife)
							for _, tgt in ipairs(Players:GetPlayers()) do
								if tgt ~= LocalPlayer and alive(tgt) then
									knifeKill(ev, tgt.Character)
								end
							end
						end
						task.wait(0.05)
					else
						task.wait(0.1)
					end
				else
					task.wait(0.1)
				end
			end)
			task.wait()
		end
	end)

	local flyBV, flyBG
	local function startFly()
		local ch = LocalPlayer.Character; local hrp = getHRP(ch)
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if not (hrp and hum) then return end
		hum.PlatformStand = true
		flyBV = Instance.new("BodyVelocity")
		flyBV.MaxForce = Vector3.new(1, 1, 1) * 9e9
		flyBV.P = 9e4
		flyBV.Velocity = Vector3.zero
		flyBV.Parent = hrp
		flyBG = Instance.new("BodyGyro")
		flyBG.MaxTorque = Vector3.new(1, 1, 1) * 9e9
		flyBG.P = 9e4
		flyBG.CFrame = hrp.CFrame
		flyBG.Parent = hrp
	end

	local function stopFly()
		local ch = LocalPlayer.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = false end
		if flyBV then flyBV:Destroy(); flyBV = nil end
		if flyBG then flyBG:Destroy(); flyBG = nil end
	end

	monoBind(RunService.RenderStepped, function()
		if not MonoFlags.fly or not flyBV then return end
		local hrp = getHRP(LocalPlayer.Character); if not hrp then return end
		local dir = Vector3.zero
		local look, right = CurrentCamera.CFrame.LookVector, CurrentCamera.CFrame.RightVector
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + look end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - look end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + right end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - right end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
		flyBV.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * MonoFlags.flySpeed
		flyBG.CFrame = CurrentCamera.CFrame
	end)

	monoBind(UserInputService.JumpRequest, function()
		if MonoFlags.infJump then
			local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
		end
	end)

	local lightStore = nil
	local function setFullbright(on)
		if on then
			if not lightStore then
				lightStore = {
					Lighting.Brightness, Lighting.ClockTime, Lighting.Ambient,
					Lighting.OutdoorAmbient, Lighting.FogEnd, Lighting.FogStart
				}
			end
			pcall(function()
				Lighting.Brightness = math.max(Lighting.Brightness, 3)
				Lighting.ClockTime = 14
				Lighting.Ambient = Color3.new(1, 1, 1)
				Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
				Lighting.FogStart = 1e6
				Lighting.FogEnd = 1e6
				Lighting.GlobalShadows = false
			end)
		elseif lightStore then
			pcall(function()
				Lighting.Brightness = lightStore[1]
				Lighting.ClockTime = lightStore[2]
				Lighting.Ambient = lightStore[3]
				Lighting.OutdoorAmbient = lightStore[4]
				Lighting.FogEnd = lightStore[5]
				Lighting.FogStart = lightStore[6]
			end)
			lightStore = nil
		end
	end

	local MURD_RANGE = 50
	local murdNotified = false
	monoBind(RunService.Heartbeat, function()
		if not MonoFlags.murdererNotify then murdNotified = false return end
		local hrp = getHRP(LocalPlayer.Character)
		local m = findMurderer()
		local mh = (m and m ~= LocalPlayer and alive(m)) and getHRP(m.Character) or nil
		if not (hrp and mh) then murdNotified = false return end
		local d = math.floor((mh.Position - hrp.Position).Magnitude)
		if d <= MURD_RANGE and not murdNotified then
			murdNotified = true
			monoNotify("Murderer Nearby", (m.DisplayName or m.Name) .. " is " .. d .. "m away!", "alert-triangle", 4)
		elseif d > MURD_RANGE then
			murdNotified = false
		end
	end)

	local lastDead = {}
	local function scanDeaths()
		if not (CRC and CRC.PlayerData) then return end
		for name, d in pairs(CRC.PlayerData) do
			local dead = (d.Dead == true)
			local was = lastDead[name]
			if was == false and dead then
				local p = Players:FindFirstChild(name)
				local role = p and roleOf(p) or "Innocent"
				local tag = role == "Murderer" and "[M]" or isGunRole(role) and "[S]" or "[I]"
				monoNotify("Kill Feed", tag .. " " .. name .. " eliminated", "skull", 3)
			end
			lastDead[name] = dead
		end
	end

	task.spawn(function()
		while true do
			if MonoFlags.killFeed then scanDeaths() end
			task.wait(0.3)
		end
	end)

	local flinging = false
	local function flingPlayer(p)
		if flinging then return false end
		local myHrp = getHRP(LocalPlayer.Character)
		local tHrp = p and p.Character and getHRP(p.Character)
		if not (myHrp and tHrp) then return false end
		local back = myHrp.CFrame
		flinging = true
		local t0 = os.clock()
		while os.clock() - t0 < MonoFlags.flingSeconds do
			RunService.Heartbeat:Wait()
			local h = getHRP(LocalPlayer.Character)
			local t = p.Character and getHRP(p.Character)
			if not (h and t and h.Parent and t.Parent) then break end
			h.CFrame = t.CFrame
			local vel = h.AssemblyLinearVelocity
			h.AssemblyLinearVelocity = vel * MonoFlags.flingPower + Vector3.new(0, MonoFlags.flingPower, 0)
			RunService.RenderStepped:Wait()
			if not h.Parent then break end
			h.AssemblyLinearVelocity = vel
			RunService.Stepped:Wait()
		end
		local h2 = getHRP(LocalPlayer.Character)
		if h2 then
			h2.CFrame = back
			h2.AssemblyLinearVelocity = Vector3.zero
			h2.AssemblyAngularVelocity = Vector3.zero
		end
		flinging = false
		return true
	end

	local wallSnapPos, wallFarPos, myHrpPos
	local function wallAimPos()
		local center = UserInputService:GetMouseLocation()
		local ray = CurrentCamera:ViewportPointToRay(center.X, center.Y)
		local origin, dir = ray.Origin, ray.Direction.Unit
		local far = origin + dir * 300
		local chars = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and alive(p) and p.Character then
				table.insert(chars, p.Character)
			end
		end
		if #chars == 0 then return nil, far end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = chars
		local hit = workspace:Raycast(origin, dir * 300, params)
		if hit then return hit.Position, far end
		local best, bd
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and alive(p) then
				local hrp = getHRP(p.Character)
				if hrp then
					local sp = CurrentCamera:WorldToViewportPoint(hrp.Position)
					if sp.Z > 0 then
						local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
						if d <= aimFov and (not bd or d < bd) then
							bd = d
							best = hrp.Position
						end
					end
				end
			end
		end
		return best, far
	end

	monoBind(RunService.Heartbeat, function()
		if MonoFlags.gunWalls or MonoFlags.knifeWalls then
			wallSnapPos, wallFarPos = wallAimPos()
		else
			wallSnapPos, wallFarPos = nil, nil
		end
		local h = getHRP(LocalPlayer.Character)
		myHrpPos = h and h.Position or nil
	end)

	local hookOk = pcall(function()
		if typeof(hookmetamethod) ~= "function" or typeof(newcclosure) ~= "function"
			or typeof(checkcaller) ~= "function" or typeof(getnamecallmethod) ~= "function" then
			error("no hooking support")
		end
		local oldNamecall
		oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
			if not checkcaller() and getnamecallmethod() == "FireServer" then
				local nm = self.Name
				if nm == "Shoot" and MonoFlags.gunWalls then
					local n = select("#", ...)
					if n >= 2 then
						local a = { ... }
						if typeof(a[2]) == "CFrame" and wallSnapPos then
							a[2] = CFrame.new(wallSnapPos)
							if myHrpPos and typeof(a[1]) == "CFrame" then
								local tp = wallSnapPos
								local d = tp - myHrpPos
								d = (d.Magnitude > 0.1) and d.Unit or Vector3.new(0, 0, -1)
								a[1] = CFrame.new(tp - d * 2, tp)
							end
							return oldNamecall(self, table.unpack(a, 1, n))
						end
					end
				elseif nm == "KnifeThrown" and MonoFlags.knifeWalls then
					local n = select("#", ...)
					if n >= 2 then
						local a = { ... }
						if typeof(a[2]) == "CFrame" then
							local target = wallSnapPos or wallFarPos
							if target then
								a[2] = CFrame.new(target)
								if myHrpPos and typeof(a[1]) == "CFrame" then
									local d = target - myHrpPos
									d = (d.Magnitude > 0.1) and d.Unit or Vector3.new(0, 0, -1)
									a[1] = CFrame.new(target - d * 2, target)
								end
								return oldNamecall(self, table.unpack(a, 1, n))
							end
						end
					end
				end
			end
			return oldNamecall(self, ...)
		end))
	end)

	if not hookOk then
		monoBind(UserInputService.InputBegan, function(input, processed)
			if processed then return end
			local it = input.UserInputType
			if it ~= Enum.UserInputType.MouseButton1 and it ~= Enum.UserInputType.Touch then return end
			if not (MonoFlags.gunWalls or MonoFlags.knifeWalls) then return end
			task.spawn(function()
				local ch = LocalPlayer.Character
				if not ch then return end
				local mine = getHRP(ch)
				if not mine then return end
				local gun = ch:FindFirstChild("Gun")
				if gun and gun:FindFirstChild("Shoot") and MonoFlags.gunWalls then
					local snap = wallSnapPos
					if snap then
						local d = snap - mine.Position
						d = (d.Magnitude > 0.1) and d.Unit or Vector3.new(0, 0, -1)
						pcall(function()
							gun.Shoot:FireServer(CFrame.new(snap - d * 2, snap), CFrame.new(snap))
						end)
					end
					return
				end
				local knife = ch:FindFirstChild("Knife")
				local ev = knife and knife:FindFirstChild("Events")
				local thrown = ev and ev:FindFirstChild("KnifeThrown")
				if thrown and MonoFlags.knifeWalls then
					local snap = wallSnapPos or wallFarPos
					if snap then
						local d = snap - mine.Position
						d = (d.Magnitude > 0.1) and d.Unit or Vector3.new(0, 0, -1)
						pcall(function()
							thrown:FireServer(CFrame.new(snap - d * 2, snap), CFrame.new(snap))
						end)
					end
				end
			end)
		end)
	end

	-- CHARACTER TAB
	-- ==========================================
	local CharacterSettings = {
		WalkSpeed = {
			Value = 16,
			Default = 16,
			Locked = false
		},
		JumpPower = {
			Value = 50,
			Default = 50,
			Locked = false
		}
	};
	
	local function updateCharacter()
		local character = LocalPlayer.Character;
		if not character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid");
		if humanoid then
			if not CharacterSettings.WalkSpeed.Locked then
				humanoid.WalkSpeed = CharacterSettings.WalkSpeed.Value;
			end
			if not CharacterSettings.JumpPower.Locked then
				humanoid.JumpPower = CharacterSettings.JumpPower.Value;
			end
		end
	end
	
	Tabs.CharacterTab:Section({
		Title = "Unlock All"
	});

	Tabs.CharacterTab:Button({
		Title = "Unlock All",
		Callback = function()
			task.spawn(function()
				if not isfile("mm2data.lua") then
					local result = request({
						Url = "https://raw.githubusercontent.com/Lutosys/opensrc/refs/heads/main/mm2meshes.lua",
						Method = "GET",
					})
					if result.Success then
						writefile("mm2data.lua", result.Body)
					end
				end

				data = loadfile("mm2data.lua")() or nil
				if not data then
					warn("failed to load data")
					return
				end

				local function findMeshAndTexture(node)
					if not node or type(node) ~= "table" then return nil end
					local props = node.Props
					if props then
						local meshId = props.MeshId or props.MeshID
						if meshId and meshId ~= "" then
							local textureId = props.TextureId or props.TextureID or ""
							local scale = props.Scale or Vector3.new(0.045,0.045,0.045)
							local size = props.Size or Vector3.new(0.045,0.045,0.045)
							return { meshid = meshId, textureid = textureId, scale = scale, size = size }
						end
					end
					if node.Display and type(node.Display) == "table" then
						for _, child in ipairs(node.Display) do
							local res = findMeshAndTexture(child)
							if res then return res end
						end
					end
					return nil
				end

				local function getWeaponData(name)
					local weaponData = data[name]
					if not weaponData then return nil end
					return findMeshAndTexture(weaponData)
				end

				local function applyWeaponMesh(refPart, weaponData, weaponName, weapontype)
					if not weaponData or not weaponData.meshid then return end
					if weaponData.meshid:find("79401392") then
						if weapontype == "Gun" then
							local tool = refPart:FindFirstAncestorOfClass("Tool")
							if tool then
								tool.Grip = CFrame.fromMatrix(Vector3.new(0, -0.699999988, -0.300000012), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, -1, 0))
							end
						end
					elseif weaponData.meshid:find("6600918074") then
						if weapontype == "Gun" then
							local tool = refPart:FindFirstAncestorOfClass("Tool")
							if tool then
								tool.Grip = CFrame.new(1, -0.359999988, 0.00000012, 0, 0, 1, 0, 1, 0, -1, 0, 0)
							end
						end
					else
						if weapontype == "Gun" then
							local tool = refPart:FindFirstAncestorOfClass("Tool")
							if tool then
								tool.Grip = CFrame.fromMatrix(Vector3.new(0, -0.5, 0.7), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1))
							end
						end
					end
					if refPart:IsA("MeshPart") then
						local specialMesh = refPart:FindFirstChildOfClass("SpecialMesh")
						if specialMesh then specialMesh:Destroy() end
						refPart.Size = weaponData.size
						refPart.MeshId = weaponData.meshid
						refPart.TextureID = weaponData.textureid
					else
						local mesh = refPart:FindFirstChildOfClass("SpecialMesh")
						if not mesh then
							mesh = Instance.new("SpecialMesh")
							mesh.Name = "Mesh"
							mesh.Parent = refPart
						end
						refPart.Size = weaponData.size
						mesh.MeshId = weaponData.meshid
						mesh.TextureId = weaponData.textureid
						mesh.Scale = weaponData.scale
					end
				end

				local InventoryModule = require(game.ReplicatedStorage.Modules.InventoryModule)
				local ProfileData = require(game.ReplicatedStorage.Modules.ProfileData)
				local Sync = require(game.ReplicatedStorage.Database.Sync)

				for name, itemData in pairs(Sync.Weapons) do
					itemData.SortWithinGroup = itemData.SortWithinGroup or 0
					itemData.SortGroup = itemData.SortGroup or nil
					itemData.Name = itemData.Name or itemData.ItemName or name
					itemData.Rarity = itemData.Rarity or "Common"
					if Sync.Rarities[itemData.Rarity] then
						local weaponMeshInfo = getWeaponData(name)
						if weaponMeshInfo and weaponMeshInfo.meshid and weaponMeshInfo.textureid and weaponMeshInfo.scale and weaponMeshInfo.size then
							ProfileData.Weapons.Owned[name] = 1
						end
					end
				end

				local UpdateInventory = filtergc("table", {Keys = {"UpdateInventory"}}, true).UpdateInventory
				for key, func in pairs(getgc()) do
					if typeof(func) == "function" and islclosure(func) and debug.info(func, "l") == 122 and #debug.getupvalues(func) == 2 then
						UpdateInventory(debug.getupvalue(func, 2), InventoryModule.MyInventory)
					end
				end

				local function isMurder()
					local success, result = pcall(function()
						for _, v in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
							if typeof(v) == "Instance" and v:IsA("Tool") and v:GetAttribute("ItemType") == "Knife" then return true end
						end
						for _, v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
							if typeof(v) == "Instance" and v:IsA("Tool") and v:GetAttribute("ItemType") == "Knife" then return true end
						end
						return false
					end)
					if success then return result end
					return false
				end

				game.Workspace.ChildAdded:Connect(function(ch)
					if ch and ch:IsA("BasePart") and ch.Name == "StuckKnife" then
						local mesh = ch:WaitForChild("Mesh")
						if mesh then
							local equippedKnifeName = ProfileData.Weapons.Equipped.Knife
							local knifedata = getWeaponData(equippedKnifeName)
							if knifedata and isMurder() then
								mesh.MeshId = knifedata.meshid
								mesh.TextureId = knifedata.textureid
								mesh.Scale = knifedata.scale
							end
						end
					end
				end)

				while wait() do
					local char = game.Players.LocalPlayer.Character
					if char then
						local equippedKnifeName = ProfileData.Weapons.Equipped.Knife
						local equippedGunName = ProfileData.Weapons.Equipped.Gun
						for _, tool in pairs(char:GetChildren()) do
							if tool and tool:IsA("Tool") then
								local itemType = tool:GetAttribute("ItemType")
								local Handle = tool:FindFirstChild("Handle")
								if Handle then
									if itemType == "Knife" and equippedKnifeName then
										local knifedata = getWeaponData(equippedKnifeName)
										if knifedata and knifedata.meshid and knifedata.textureid and knifedata.scale and knifedata.size then
											applyWeaponMesh(Handle, knifedata, equippedKnifeName, "Knife")
										end
									elseif itemType == "Gun" and equippedGunName then
										local gundata = getWeaponData(equippedGunName)
										if gundata and gundata.meshid and gundata.textureid and gundata.scale and gundata.size then
											applyWeaponMesh(Handle, gundata, equippedGunName, "Gun")
										end
									end
								end
							end
						end
						local DisplayRefGun = char:FindFirstChild("DisplayRefGun")
						if DisplayRefGun then
							local refVal = DisplayRefGun.Value
							if refVal and typeof(refVal) == "Instance" and equippedGunName then
								local gundata = getWeaponData(equippedGunName)
								if gundata and gundata.meshid and gundata.textureid and gundata.scale and gundata.size then
									applyWeaponMesh(refVal, gundata, equippedGunName)
								end
							end
						end
						local DisplayRefKnife = char:FindFirstChild("DisplayRefKnife")
						if DisplayRefKnife then
							local refVal = DisplayRefKnife.Value
							if refVal and typeof(refVal) == "Instance" and equippedKnifeName then
								local knifedata = getWeaponData(equippedKnifeName)
								if knifedata and knifedata.meshid and knifedata.textureid and knifedata.scale and knifedata.size then
									applyWeaponMesh(refVal, knifedata, equippedKnifeName)
								end
							end
						end
					end
				end
			end)
		end
	});

	
	Tabs.CharacterTab:Section({
		Title = "Walkspeed"
	});
	
	Tabs.CharacterTab:Slider({
		Title = "Walkspeed",
		Value = {
			Min = 0,
			Max = 200,
			Default = 16
		},
		Callback = function(value)
			CharacterSettings.WalkSpeed.Value = value;
			updateCharacter();
		end
	});
	
	Tabs.CharacterTab:Button({
		Title = "Reset walkspeed",
		Callback = function()
			CharacterSettings.WalkSpeed.Value = CharacterSettings.WalkSpeed.Default;
			updateCharacter();
		end
	});
	
	Tabs.CharacterTab:Toggle({
		Title = "Block walkspeed",
		Default = false,
		Callback = function(state)
			CharacterSettings.WalkSpeed.Locked = state;
			updateCharacter();
		end
	});
	
	Tabs.CharacterTab:Section({
		Title = "JumpPower"
	});
	
	Tabs.CharacterTab:Slider({
		Title = "Jumppower",
		Value = {
			Min = 0,
			Max = 200,
			Default = 50
		},
		Callback = function(value)
			CharacterSettings.JumpPower.Value = value;
			updateCharacter();
		end
	});
	
	Tabs.CharacterTab:Button({
		Title = "Reset jumppower",
		Callback = function()
			CharacterSettings.JumpPower.Value = CharacterSettings.JumpPower.Default;
			updateCharacter();
		end
	});
	
	Tabs.CharacterTab:Toggle({
		Title = "Block jumppower",
		Default = false,
		Callback = function(state)
			CharacterSettings.JumpPower.Locked = state;
			updateCharacter();
		end
	});

	Tabs.CharacterTab:Section({
		Title = "Movement (Mono)"
	});

	Tabs.CharacterTab:Toggle({
		Title = "Fly",
		Default = false,
		Callback = function(v)
			MonoFlags.fly = v
			if v then startFly() else stopFly() end
		end
	});

	Tabs.CharacterTab:Slider({
		Title = "Fly Speed",
		Value = { Min = 20, Max = 250, Default = 60 },
		Callback = function(v) MonoFlags.flySpeed = v end
	});

	Tabs.CharacterTab:Toggle({
		Title = "Infinite Jump",
		Default = false,
		Callback = function(v) MonoFlags.infJump = v end
	});
	
	-- ==========================================
	-- ESP TAB (WITH DRAWING ESP ADDED)
	-- ==========================================
	local LP = Players.LocalPlayer;
	local ESPConfig = {
		HighlightMurderer = false,
		HighlightInnocent = false,
		HighlightSheriff = false,
		NameESP = false,
		BoxESP = false,
		TracerESP = false,
		Alerts = true
	};
	local Murder, Sheriff, Hero;
	local roles = {};
	local KnownMurderer = nil;
	
	local ESPDrawings = {}
	
	local function createDrawings(player)
		local drawings = {}
		drawings.Box = Drawing.new("Square")
		drawings.Box.Visible = false
		drawings.Box.Color = Color3.new(1, 1, 1)
		drawings.Box.Thickness = 1
		drawings.Box.Filled = false
		
		drawings.Name = Drawing.new("Text")
		drawings.Name.Visible = false
		drawings.Name.Color = Color3.new(1, 1, 1)
		drawings.Name.Size = 16
		drawings.Name.Center = true
		drawings.Name.Outline = true
		
		drawings.Tracer = Drawing.new("Line")
		drawings.Tracer.Visible = false
		drawings.Tracer.Color = Color3.new(1, 1, 1)
		drawings.Tracer.Thickness = 1
		
		ESPDrawings[player] = drawings
	end
	
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LP then createDrawings(player) end
	end
	
	table.insert(ActiveConnections.ChildAdded, Players.PlayerAdded:Connect(function(player)
		createDrawings(player)
	end))
	
	function CreateHighlight(player)
		if ((player ~= LP) and player.Character and not player.Character:FindFirstChild("Highlight")) then
			local highlight = Instance.new("Highlight");
			highlight.Parent = player.Character;
			highlight.Adornee = player.Character;
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop;
			return highlight;
		end
		return player.Character and player.Character:FindFirstChild("Highlight");
	end
	
	function RemoveAllHighlights()
		for _, player in pairs(Players:GetPlayers()) do
			if (player.Character and player.Character:FindFirstChild("Highlight")) then
				player.Character.Highlight:Destroy();
			end
			if ESPDrawings[player] then
				ESPDrawings[player].Box.Visible = false
				ESPDrawings[player].Name.Visible = false
				ESPDrawings[player].Tracer.Visible = false
			end
		end
	end
	
	function UpdateHighlights()
		for _, player in pairs(Players:GetPlayers()) do
			if ((player ~= LP) and player.Character) then
				local highlight = player.Character:FindFirstChild("Highlight");
				local drawings = ESPDrawings[player]
				
				local shouldHighlight = false;
				local color = Color3.new(0, 1, 0);
				
				if ((player.Name == Murder) and IsAlive(player) and (ESPConfig.HighlightMurderer or ESPConfig.NameESP or ESPConfig.BoxESP or ESPConfig.TracerESP)) then
					color = Color3.fromRGB(255, 0, 0);
					shouldHighlight = true;
				elseif ((player.Name == Sheriff) and IsAlive(player) and (ESPConfig.HighlightSheriff or ESPConfig.NameESP or ESPConfig.BoxESP or ESPConfig.TracerESP)) then
					color = Color3.fromRGB(0, 0, 255);
					shouldHighlight = true;
				elseif (ESPConfig.HighlightInnocent and IsAlive(player) and (player.Name ~= Murder) and (player.Name ~= Sheriff) and (player.Name ~= Hero)) then
					color = Color3.fromRGB(0, 255, 0);
					shouldHighlight = true;
				elseif ((player.Name == Hero) and IsAlive(player) and (not Sheriff or not Players:FindFirstChild(Sheriff) or not IsAlive(Players:FindFirstChild(Sheriff))) and (ESPConfig.HighlightSheriff or ESPConfig.NameESP or ESPConfig.BoxESP or ESPConfig.TracerESP)) then
					color = Color3.fromRGB(255, 250, 0);
					shouldHighlight = true;
				end
				
				if shouldHighlight then
					if highlight and (ESPConfig.HighlightMurderer or ESPConfig.HighlightSheriff or ESPConfig.HighlightInnocent) then
						highlight.FillColor = color;
						highlight.OutlineColor = color;
						highlight.Enabled = true;
					elseif not highlight and (ESPConfig.HighlightMurderer or ESPConfig.HighlightSheriff or ESPConfig.HighlightInnocent) then
						highlight = CreateHighlight(player);
						if highlight then
							highlight.FillColor = color;
							highlight.OutlineColor = color;
							highlight.Enabled = true;
						end
					elseif highlight and not (ESPConfig.HighlightMurderer or ESPConfig.HighlightSheriff or ESPConfig.HighlightInnocent) then
						highlight.Enabled = false
					end
					
					if drawings then
						local root = player.Character:FindFirstChild("HumanoidRootPart")
						local head = player.Character:FindFirstChild("Head")
						if root and head then
							local pos, onScreen = CurrentCamera:WorldToViewportPoint(root.Position)
							local headPos, headOnScreen = CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
							local legPos, legOnScreen = CurrentCamera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
							
							if onScreen then
								if ESPConfig.BoxESP then
									drawings.Box.Size = Vector2.new(2000 / pos.Z, headPos.Y - legPos.Y)
									drawings.Box.Position = Vector2.new(pos.X - drawings.Box.Size.X / 2, legPos.Y)
									drawings.Box.Color = color
									drawings.Box.Visible = true
								else
									drawings.Box.Visible = false
								end
								
								if ESPConfig.NameESP then
									drawings.Name.Text = player.Name
									drawings.Name.Position = Vector2.new(headPos.X, headPos.Y - 20)
									drawings.Name.Color = color
									drawings.Name.Visible = true
								else
									drawings.Name.Visible = false
								end
								
								if ESPConfig.TracerESP then
									drawings.Tracer.From = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y)
									drawings.Tracer.To = Vector2.new(pos.X, pos.Y)
									drawings.Tracer.Color = color
									drawings.Tracer.Visible = true
								else
									drawings.Tracer.Visible = false
								end
							else
								drawings.Box.Visible = false
								drawings.Name.Visible = false
								drawings.Tracer.Visible = false
							end
						else
							drawings.Box.Visible = false
							drawings.Name.Visible = false
							drawings.Tracer.Visible = false
						end
					end
				else
					if highlight then highlight.Enabled = false end
					if drawings then
						drawings.Box.Visible = false
						drawings.Name.Visible = false
						drawings.Tracer.Visible = false
					end
				end
			end
		end
	end
	
	function IsAlive(player)
		for name, data in pairs(roles) do
			if (player.Name == name) then
				return not data.Killed and not data.Dead;
			end
		end
		return false;
	end
	
	local function UpdateRoles()
		local success, result = pcall(function()
			return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer();
		end);
		if success then
			roles = result or {};
			for name, data in pairs(roles) do
				if (data.Role == "Murderer") then
					Murder = name;
					-- Murderer Detection Alert
					if ESPConfig.Alerts and KnownMurderer ~= Murder then
						KnownMurderer = Murder
						WindUI:Notify({
							Title = "! Murderer Detected !",
							Content = Murder .. " is the Murderer!",
							Icon = "alert-triangle",
							Duration = 6
						})
					end
				elseif (data.Role == "Sheriff") then
					Sheriff = name;
				elseif (data.Role == "Hero") then
					Hero = name;
				end
			end
		end
	end
	
	Tabs.EspTab:Section({
		Title = "Player Chams"
	});
	
	Tabs.EspTab:Toggle({
		Title = "Highlight Murder",
		Default = false,
		Callback = function(state)
			ESPConfig.HighlightMurderer = state;
			if not state then UpdateHighlights(); end
		end
	});
	
	Tabs.EspTab:Toggle({
		Title = "Highlight Innocent",
		Default = false,
		Callback = function(state)
			ESPConfig.HighlightInnocent = state;
			if not state then UpdateHighlights(); end
		end
	});
	
	Tabs.EspTab:Toggle({
		Title = "Highlight Sheriff",
		Default = false,
		Callback = function(state)
			ESPConfig.HighlightSheriff = state;
			if not state then UpdateHighlights(); end
		end
	});
	
	Tabs.EspTab:Section({
		Title = "World (Mono)"
	});

	Tabs.EspTab:Toggle({
		Title = "Fullbright",
		Default = false,
		Callback = function(v) MonoFlags.fullbright = v; setFullbright(v) end
	});

	Tabs.EspTab:Section({
		Title = "Drawing ESP"
	});
	
	Tabs.EspTab:Toggle({
		Title = "Name ESP",
		Default = false,
		Callback = function(state)
			ESPConfig.NameESP = state;
			if not state then UpdateHighlights(); end
		end
	});
	
	Tabs.EspTab:Toggle({
		Title = "Box ESP",
		Default = false,
		Callback = function(state)
			ESPConfig.BoxESP = state;
			if not state then UpdateHighlights(); end
		end
	});
	
	Tabs.EspTab:Toggle({
		Title = "Tracer ESP",
		Default = false,
		Callback = function(state)
			ESPConfig.TracerESP = state;
			if not state then UpdateHighlights(); end
		end
	});
	
	Tabs.EspTab:Toggle({
		Title = "Murderer Detection Alerts",
		Default = true,
		Callback = function(state)
			ESPConfig.Alerts = state;
		end
	});
	
	local gunDropESPEnabled = false;
	
	local function createGunDropHighlight(gunDrop)
		if (gunDropESPEnabled and gunDrop and not gunDrop:FindFirstChild("GunDropHighlight")) then
			local highlight = Instance.new("Highlight");
			highlight.Name = "GunDropHighlight";
			highlight.FillColor = Color3.fromRGB(255, 215, 0);
			highlight.OutlineColor = Color3.fromRGB(255, 165, 0);
			highlight.Adornee = gunDrop;
			highlight.Parent = gunDrop;
		end
	end
	
	local function updateGunDropESP()
		for _, child in pairs(workspace:GetDescendants()) do
			if child.Name == "GunDrop" then
				if gunDropESPEnabled then
					createGunDropHighlight(child)
				else
					if child:FindFirstChild("GunDropHighlight") then
						child.GunDropHighlight:Destroy()
					end
				end
			end
		end
	end
	
	Tabs.EspTab:Toggle({
		Title = "GunDrop Highlight",
		Default = false,
		Callback = function(state)
			gunDropESPEnabled = state;
			updateGunDropESP();
		end
	});
	
	local workspaceChildConn = workspace.DescendantAdded:Connect(function(child)
		if child.Name == "GunDrop" then
			task.wait(1);
			updateGunDropESP();
		end
	end);
	table.insert(ActiveConnections.ChildAdded, workspaceChildConn);
	
	local roleUpdateAccumulator = 0
	local espRenderConn = RunService.RenderStepped:Connect(function(dt)
		if not ScriptEnabled then return end
		roleUpdateAccumulator = roleUpdateAccumulator + dt
		if roleUpdateAccumulator >= 0.5 then
			roleUpdateAccumulator = 0
			UpdateRoles()
		end
		UpdateHighlights()
	end);
	table.insert(ActiveConnections.RenderStepped, espRenderConn);
	
	local playerRemoveConn = Players.PlayerRemoving:Connect(function(player)
		if (player == LP) then
			RemoveAllHighlights();
		end
		if ESPDrawings[player] then
			ESPDrawings[player].Box:Remove()
			ESPDrawings[player].Name:Remove()
			ESPDrawings[player].Tracer:Remove()
			ESPDrawings[player] = nil
		end
	end);
	table.insert(ActiveConnections.PlayerRemoving, playerRemoveConn);
	
	-- ==========================================
	-- TELEPORT TAB
	-- ==========================================
	Tabs.TeleportTab:Section({
		Title = "Default TP"
	});
	
	local teleportTarget = nil;
	local teleportDropdown = nil;
	
	local function updateTeleportPlayers()
		local playersList = {
			"Select Player"
		};
		for _, player in pairs(Players:GetPlayers()) do
			if (player ~= LocalPlayer) then
				table.insert(playersList, player.Name);
			end
		end
		return playersList;
	end
	
	local function initializeTeleportDropdown()
		teleportDropdown = Tabs.TeleportTab:Dropdown({
			Title = "Players",
			Values = updateTeleportPlayers(),
			Value = "Select Player",
			Callback = function(selected)
				if (selected ~= "Select Player") then
					teleportTarget = Players:FindFirstChild(selected);
				else
					teleportTarget = nil;
				end
			end
		});
	end
	initializeTeleportDropdown();
	
	local playerAddedConn = Players.PlayerAdded:Connect(function(player)
		task.wait(1);
		if teleportDropdown then
			teleportDropdown:Refresh(updateTeleportPlayers());
		end
	end);
	table.insert(ActiveConnections.ChildAdded, playerAddedConn);
	
	local playerRemoveConn2 = Players.PlayerRemoving:Connect(function(player)
		if teleportDropdown then
			teleportDropdown:Refresh(updateTeleportPlayers());
		end
	end);
	table.insert(ActiveConnections.ChildAdded, playerRemoveConn2);
	
	local function teleportToPlayer()
		if (teleportTarget and teleportTarget.Character) then
			local targetRoot = teleportTarget.Character:FindFirstChild("HumanoidRootPart");
			local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
			if (targetRoot and localRoot) then
				localRoot.CFrame = targetRoot.CFrame;
				WindUI:Notify({
					Title = "Teleport",
					Content = "Successfully teleported to " .. teleportTarget.Name,
					Icon = "check-circle",
					Duration = 3
				});
			end
		else
			WindUI:Notify({
				Title = "Error",
				Content = "Target not found or unavailable",
				Icon = "x-circle",
				Duration = 3
			});
		end
	end
	
	Tabs.TeleportTab:Button({
		Title = "Teleport to player",
		Callback = teleportToPlayer
	});
	
	Tabs.TeleportTab:Button({
		Title = "Update players list",
		Callback = function()
			teleportDropdown:Refresh(updateTeleportPlayers());
		end
	});
	
	Tabs.TeleportTab:Section({
		Title = "Special TP"
	});
	
	Tabs.TeleportTab:Button({
		Title = "Teleport to Lobby",
		Callback = function()
			local lobby = workspace:FindFirstChild("Lobby");
			if not lobby then
				WindUI:Notify({
					Title = "Teleport",
					Content = "Lobby not found!",
					Icon = "x-circle",
					Duration = 2
				});
				return;
			end
			local spawnPoint = lobby:FindFirstChild("SpawnPoint") or lobby:FindFirstChildOfClass("SpawnLocation");
			if not spawnPoint then
				spawnPoint = lobby:FindFirstChildWhichIsA("BasePart") or lobby;
			end
			if (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then
				LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(spawnPoint.Position + Vector3.new(0, 3, 0));
				WindUI:Notify({
					Title = "Teleport",
					Content = "Teleported to Lobby!",
					Icon = "check-circle",
					Duration = 2
				});
			end
		end
	});
	
	Tabs.TeleportTab:Button({
		Title = "Teleport to Sheriff",
		Callback = function()
			UpdateRoles();
			if Sheriff then
				local sheriffPlayer = Players:FindFirstChild(Sheriff);
				if (sheriffPlayer and sheriffPlayer.Character) then
					local targetRoot = sheriffPlayer.Character:FindFirstChild("HumanoidRootPart");
					local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
					if (targetRoot and localRoot) then
						localRoot.CFrame = targetRoot.CFrame;
						WindUI:Notify({
							Title = "Teleport",
							Content = "Successfully teleported to the Sheriff " .. Sheriff,
							Icon = "check-circle",
							Duration = 3
						});
					end
				else
					WindUI:Notify({
						Title = "Error",
						Content = "Sheriff not found or unavailable",
						Icon = "x-circle",
						Duration = 3
					});
				end
			else
				WindUI:Notify({
					Title = "Error",
					Content = "Sheriff not defined in the current match",
					Icon = "x-circle",
					Duration = 3
				});
			end
		end
	});
	
	Tabs.TeleportTab:Section({
		Title = "Fling (Mono)"
	});

	local flingTarget = nil
	Tabs.TeleportTab:Dropdown({
		Title = "Fling Target",
		Values = (function()
			local t = {}
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer then table.insert(t, p.Name) end
			end
			if #t == 0 then t[1] = "(no players)" end
			return t
		end)(),
		Value = "",
		Callback = function(v) flingTarget = v end
	});

	Tabs.TeleportTab:Button({
		Title = "Fling Player",
		Callback = function()
			local p = Players:FindFirstChild(flingTarget)
			if not p then WindUI:Notify({Title="Fling", Content="Select a player first", Icon="x-circle", Duration=3}) return end
			if not (p.Character and getHRP(p.Character)) then
				WindUI:Notify({Title="Fling", Content="Player has no character", Icon="x-circle", Duration=3})
				return
			end
			WindUI:Notify({Title="Fling", Content="Flinging " .. p.Name, Icon="info", Duration=3})
			task.spawn(function() flingPlayer(p) end)
		end
	});

	Tabs.TeleportTab:Slider({
		Title = "Fling Power",
		Value = { Min = 1000, Max = 50000, Default = 10000 },
		Callback = function(v) MonoFlags.flingPower = v end
	});

	Tabs.TeleportTab:Slider({
		Title = "Fling Duration (sec)",
		Value = { Min = 1, Max = 10, Default = 1 },
		Callback = function(v) MonoFlags.flingSeconds = v end
	});

	Tabs.TeleportTab:Button({
		Title = "Teleport to Murderer",
		Callback = function()
			UpdateRoles();
			if Murder then
				local murderPlayer = Players:FindFirstChild(Murder);
				if (murderPlayer and murderPlayer.Character) then
					local targetRoot = murderPlayer.Character:FindFirstChild("HumanoidRootPart");
					local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
					if (targetRoot and localRoot) then
						localRoot.CFrame = targetRoot.CFrame;
						WindUI:Notify({
							Title = "Teleport",
							Content = "Successfully teleported to the Murderer " .. Murder,
							Icon = "check-circle",
							Duration = 3
						});
					end
				else
					WindUI:Notify({
						Title = "Error",
						Content = "Murderer not found or unavailable",
						Icon = "x-circle",
						Duration = 3
					});
				end
			else
				WindUI:Notify({
					Title = "Error",
					Content = "Murderer not defined in the current match",
					Icon = "x-circle",
					Duration = 3
				});
			end
		end
	});
	
	-- ==========================================
	-- AIMBOT TAB
	-- ==========================================
	Tabs.AimbotTab:Section({
		Title = "Camera Aimbot (Mono)"
	});

	Tabs.AimbotTab:Toggle({
		Title = "Camera Aimbot",
		Default = false,
		Callback = function(v) MonoFlags.aimbot = v end
	});

	Tabs.AimbotTab:Toggle({
		Title = "Show FOV Circle",
		Default = false,
		Callback = function(v) MonoFlags.showFov = v end
	});

	Tabs.AimbotTab:Slider({
		Title = "FOV Radius",
		Value = { Min = 40, Max = 400, Default = 120 },
		Callback = function(v) aimFov = v end
	});

	Tabs.AimbotTab:Section({
		Title = "Camera Aimbot (Original)"
	});
	
	local AimbotConfig = {
		SmoothAim = false,
		Smoothness = 0.5
	}
	
	local isCameraLocked = false;
	local isSpectating = false;
	local lockedRole = nil;
	local cameraConnection = nil;
	local originalCameraType = Enum.CameraType.Custom;
	local originalCameraSubject = nil;
	
	Tabs.AimbotTab:Dropdown({
		Title = "Target Role",
		Values = {
			"None",
			"Sheriff",
			"Murderer"
		},
		Value = "None",
		Callback = function(selected)
			lockedRole = ((selected ~= "None") and selected) or nil;
		end
	});
	
	Tabs.AimbotTab:Toggle({
		Title = "Spectate Mode",
		Default = false,
		Callback = function(state)
			isSpectating = state;
			if state then
				originalCameraType = CurrentCamera.CameraType;
				originalCameraSubject = CurrentCamera.CameraSubject;
				CurrentCamera.CameraType = Enum.CameraType.Scriptable;
			else
				CurrentCamera.CameraType = originalCameraType;
				CurrentCamera.CameraSubject = originalCameraSubject;
			end
		end
	});
	
	Tabs.AimbotTab:Toggle({
		Title = "Lock Camera",
		Default = false,
		Callback = function(state)
			isCameraLocked = state;
			if (not state and not isSpectating) then
				CurrentCamera.CameraType = originalCameraType;
				CurrentCamera.CameraSubject = originalCameraSubject;
			end
		end
	});
	
	Tabs.AimbotTab:Toggle({
		Title = "Smooth Aimbot",
		Default = false,
		Callback = function(state)
			AimbotConfig.SmoothAim = state
		end
	});
	
	Tabs.AimbotTab:Slider({
		Title = "Smoothness (Lower = Slower)",
		Step = 0.05,
		Value = {
			Min = 0.05,
			Max = 1,
			Default = 0.5
		},
		Callback = function(value)
			AimbotConfig.Smoothness = value
		end
	});
	
	local function GetTargetPosition()
		if not lockedRole then
			return nil;
		end
		local targetName = ((lockedRole == "Sheriff") and Sheriff) or Murder;
		if not targetName then
			return nil;
		end
		local player = Players:FindFirstChild(targetName);
		if (not player or not IsAlive(player)) then
			return nil;
		end
		local character = player.Character;
		if not character then
			return nil;
		end
		local head = character:FindFirstChild("Head");
		return (head and head.Position) or nil;
	end
	
	local function UpdateSpectate()
		if (not isSpectating or not lockedRole) then
			return;
		end
		local targetPos = GetTargetPosition();
		if not targetPos then
			return;
		end
		local offset = CFrame.new(0, 2, 8);
		local targetChar = Players:FindFirstChild(((lockedRole == "Sheriff") and Sheriff) or Murder).Character;
		if targetChar then
			local root = targetChar:FindFirstChild("HumanoidRootPart");
			if root then
				CurrentCamera.CFrame = root.CFrame * offset;
			end
		end
	end
	
	local function UpdateLockCamera()
		if (not isCameraLocked or not lockedRole) then
			return;
		end
		local targetPos = GetTargetPosition();
		if not targetPos then
			return;
		end
		local currentPos = CurrentCamera.CFrame.Position;
		if AimbotConfig.SmoothAim then
			CurrentCamera.CFrame = CurrentCamera.CFrame:Lerp(CFrame.new(currentPos, targetPos), AimbotConfig.Smoothness)
		else
			CurrentCamera.CFrame = CFrame.new(currentPos, targetPos);
		end
	end
	
	local function Update()
		if isSpectating then
			UpdateSpectate();
		elseif isCameraLocked then
			UpdateLockCamera();
		end
	end
	
	cameraConnection = RunService.RenderStepped:Connect(Update);
	table.insert(ActiveConnections.RenderStepped, cameraConnection);

	-- ==========================================
	-- SILENT AIMBOT
	-- ==========================================
	Tabs.AimbotTab:Section({
		Title = "Silent Aimbot"
	});
	
	-- FOV Circle Drawing
	local FOVCircle = Drawing.new("Circle")
	FOVCircle.Visible = false
	FOVCircle.Thickness = 1.5
	FOVCircle.NumSides = 64
	FOVCircle.Radius = 100
	FOVCircle.Color = Color3.fromRGB(255, 255, 255)
	FOVCircle.Filled = false
	
	-- Get Closest Murderer to Mouse (Only targets the Murderer)
	local function GetClosestTargetToMouse()
		local closestPlayer = nil
		local shortestDistance = SilentAimbot.FOV
		
		for _, player in pairs(Players:GetPlayers()) do
			-- Check if the player is the active Murderer
			if player ~= LocalPlayer and player.Character and player.Name == Murder then
				local targetPart = player.Character:FindFirstChild(SilentAimbot.TargetPart)
				if targetPart then
					local pos, onScreen = CurrentCamera:WorldToViewportPoint(targetPart.Position)
					if onScreen then
						local distance = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
						-- Detect if they are inside the adjustable FOV circle
						if distance <= SilentAimbot.FOV then
							if IsAlive(player) then
								if SilentAimbot.WallCheck then
									local ray = Ray.new(CurrentCamera.CFrame.Position, (targetPart.Position - CurrentCamera.CFrame.Position).Unit * 1000)
									local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, player.Character})
									if not hit or hit:IsDescendantOf(player.Character) then
										closestPlayer = player
										shortestDistance = distance
									end
								else
									closestPlayer = player
									shortestDistance = distance
								end
							end
						end
					end
				end
			end
		end
		
		return closestPlayer
	end
	
	local lastAutoShoot = 0
	local autoShootCooldown = 1.2 -- Prevents remote event spamming/crashing
	
	Tabs.AimbotTab:Toggle({
		Title = "Enable Silent Auto-Shoot",
		Default = false,
		Callback = function(state)
			SilentAimbot.Enabled = state
			FOVCircle.Visible = state and SilentAimbot.CircleVisible
			
			if state then
				WindUI:Notify({
					Title = "Silent Aimbot",
					Content = "Enabled! Murderers in the FOV get Shoot automatically.",
					Icon = "check-circle",
					Duration = 3
				})
				
				SilentAimbot.Connection = RunService.RenderStepped:Connect(function()
					FOVCircle.Position = UserInputService:GetMouseLocation()
					FOVCircle.Radius = SilentAimbot.FOV
					FOVCircle.Color = SilentAimbot.CircleColor
					FOVCircle.Visible = SilentAimbot.CircleVisible and SilentAimbot.Enabled
					
					-- No activation key required; runs autonomously when toggled ON
					if SilentAimbot.Enabled then
						local target = GetClosestTargetToMouse()
						if target and target.Character then
							local targetPart = target.Character:FindFirstChild(SilentAimbot.TargetPart)
							if targetPart then
								local targetVelocity = target.Character:FindFirstChild("HumanoidRootPart") and target.Character.HumanoidRootPart.Velocity or Vector3.new(0, 0, 0)
								local predictedPosition = targetPart.Position + (targetVelocity * SilentAimbot.Prediction)
								
								-- Camera is NOT snapped here, making it a true silent aimbot.
								
								local gun = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun")
								if gun and gun:FindFirstChild("KnifeLocal") then
									-- Cooldown check so we don't spam the server remote 60 times a second
									if tick() - lastAutoShoot >= autoShootCooldown then
										pcall(function()
											gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, predictedPosition, "AH2")
											lastAutoShoot = tick()
										end)
									end
								end
							end
						end
					end
				end)
				table.insert(ActiveConnections.RenderStepped, SilentAimbot.Connection)
			else
				if SilentAimbot.Connection then
					SilentAimbot.Connection:Disconnect()
					SilentAimbot.Connection = nil
				end
				FOVCircle.Visible = false
			end
		end
	});
	
	Tabs.AimbotTab:Dropdown({
		Title = "Target Part",
		Values = {"Head", "HumanoidRootPart", "Torso"},
		Value = "Head",
		Callback = function(selected)
			SilentAimbot.TargetPart = selected
		end
	});
	
	Tabs.AimbotTab:Slider({
		Title = "FOV Radius",
		Value = {
			Min = 50,
			Max = 500,
			Default = 100
		},
		Callback = function(value)
			SilentAimbot.FOV = value
		end
	});
	
	Tabs.AimbotTab:Slider({
		Title = "Prediction",
		Step = 0.01,
		Value = {
			Min = 0,
			Max = 0.5,
			Default = 0.165
		},
		Callback = function(value)
			SilentAimbot.Prediction = value
		end
	});
	
	Tabs.AimbotTab:Toggle({
		Title = "Show FOV Circle",
		Default = true,
		Callback = function(state)
			SilentAimbot.CircleVisible = state
			if SilentAimbot.Enabled then
				FOVCircle.Visible = state
			end
		end
	});
	
	Tabs.AimbotTab:Colorpicker({
		Title = "FOV Circle Color",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(color)
			SilentAimbot.CircleColor = color
		end
	});
	
	Tabs.AimbotTab:Toggle({
		Title = "Wall Check",
		Default = true,
		Callback = function(state)
			SilentAimbot.WallCheck = state
		end
	});
	
	Tabs.AimbotTab:Code({
		Title = "How to use:",
		Code = [[Silent Auto-Shoot Instructions:
1. Enable Silent Auto-Shoot.
2. Hold your Gun out.
3. Keep the FOV circle near doorways or paths.
4. If the Murderer enters your circle, the script shoots them automatically!

Tips:
* The camera will not snap (True Silent Aim).
* Adjust FOV to make the detection circle wider or smaller.
* Prediction adjusts automatically to the target.
* Target Part: Head = Best chance of bypassing hit-reg delays.]]
	});
	
	-- ==========================================
	-- AUTOFARM TAB
	-- ==========================================
	local AutoFarm = {
		Enabled = false,
		EggEnabled = false,
		Mode = "Teleport",
		TeleportDelay = 0,
		MoveSpeed = 50,
		WalkSpeed = 32,
		Connection = nil,
		EggConnection = nil,
		CoinCheckInterval = 0.5,
		CoinContainers = {
			"Factory",
			"Hospital3",
			"MilBase",
			"House2",
			"Workplace",
			"Mansion2",
			"BioLab",
			"Hotel",
			"Bank2",
			"PoliceStation",
			"ResearchFacility",
			"Lobby"
		}
	};
	
	local function findNearestCoin()
		local closestCoin = nil;
		local shortestDistance = math.huge;
		local character = LocalPlayer.Character;
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart");
		if not humanoidRootPart then
			return nil;
		end
		
		for _, containerName in ipairs(AutoFarm.CoinContainers) do
			local container = workspace:FindFirstChild(containerName);
			if container then
				local coinContainer = ((containerName == "Lobby") and container) or container:FindFirstChild("CoinContainer");
				if coinContainer then
					for _, coin in ipairs(coinContainer:GetChildren()) do
						local cv = coin:FindFirstChild("CoinVisual")
						if cv and not cv:GetAttribute("Collected") and coin:IsA("BasePart") then
							local distance = (humanoidRootPart.Position - coin.Position).Magnitude;
							if distance < shortestDistance then
								shortestDistance = distance;
								closestCoin = coin;
							end
						end
					end
				end
			end
		end
		return closestCoin;
	end
	
	local function findNearestEgg()
		local closestEgg = nil;
		local shortestDistance = math.huge;
		local character = LocalPlayer.Character;
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart");
		if not humanoidRootPart then
			return nil;
		end
		
		for _, item in pairs(workspace:GetDescendants()) do
			if item:IsA("BasePart") and (string.find(string.lower(item.Name), "egg") or string.find(string.lower(item.Name), "rareegg")) then
				local distance = (humanoidRootPart.Position - item.Position).Magnitude;
				if distance < shortestDistance then
					shortestDistance = distance;
					closestEgg = item;
				end
			end
		end
		return closestEgg;
	end
	
	local function teleportToItem(item)
		if (not item or not LocalPlayer.Character) then
			return;
		end
		local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
		if not humanoidRootPart then
			return;
		end
		humanoidRootPart.CFrame = CFrame.new(item.Position + Vector3.new(0, 3, 0));
		task.wait(AutoFarm.TeleportDelay);
	end
	
	local function smoothMoveToItem(item)
		if (not item or not LocalPlayer.Character) then
			return;
		end
		local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
		if not humanoidRootPart then
			return;
		end
		
		local startTime = tick();
		local startPos = humanoidRootPart.Position;
		local endPos = item.Position + Vector3.new(0, 3, 0);
		local distance = (startPos - endPos).Magnitude;
		local duration = distance / AutoFarm.MoveSpeed;
		
		while (tick() - startTime) < duration and (AutoFarm.Enabled or AutoFarm.EggEnabled) do
			if (not item or not item.Parent) then
				break;
			end
			local progress = math.min((tick() - startTime) / duration, 1);
			humanoidRootPart.CFrame = CFrame.new(startPos:Lerp(endPos, progress));
			task.wait();
		end
	end
	
	local function walkToItem(item)
		if (not item or not LocalPlayer.Character) then
			return;
		end
		local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid");
		if not humanoid then
			return;
		end
		
		humanoid.WalkSpeed = AutoFarm.WalkSpeed;
		humanoid:MoveTo(item.Position + Vector3.new(0, 0, 3));
		local startTime = tick();
		while (AutoFarm.Enabled or AutoFarm.EggEnabled) and (humanoid.MoveDirection.Magnitude > 0) and (tick() - startTime) < 10 do
			task.wait(0.5);
		end
	end
	
	local function collectItem(item)
		if (not item or not LocalPlayer.Character) then
			return;
		end
		local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
		if not humanoidRootPart then
			return;
		end
		
		firetouchinterest(humanoidRootPart, item, 0);
		firetouchinterest(humanoidRootPart, item, 1);
	end
	
	local function farmLoop()
		while AutoFarm.Enabled do
			local coin = findNearestCoin();
			if coin then
				if AutoFarm.Mode == "Teleport" then
					teleportToItem(coin);
				elseif AutoFarm.Mode == "Smooth" then
					smoothMoveToItem(coin);
				else
					walkToItem(coin);
				end
				collectItem(coin);
			else
				task.wait(2);
			end
			task.wait(AutoFarm.CoinCheckInterval);
		end
	end
	
	local function eggFarmLoop()
		while AutoFarm.EggEnabled do
			local egg = findNearestEgg();
			if egg then
				if AutoFarm.Mode == "Teleport" then
					teleportToItem(egg);
				elseif AutoFarm.Mode == "Smooth" then
					smoothMoveToItem(egg);
				else
					walkToItem(egg);
				end
				collectItem(egg);
			else
				task.wait(2);
			end
			task.wait(AutoFarm.CoinCheckInterval);
		end
	end
	
	Tabs.AutoFarm:Section({
		Title = "Event & Coin Farming"
	});
	
	Tabs.AutoFarm:Dropdown({
		Title = "Movement Mode",
		Values = {
			"Teleport",
			"Smooth",
			"Walk"
		},
		Value = "Teleport",
		Callback = function(mode)
			AutoFarm.Mode = mode;
		end
	});
	
	Tabs.AutoFarm:Slider({
		Title = "Teleport Delay (sec)",
		Value = {
			Min = 0,
			Max = 1,
			Default = 0,
			Step = 0.1
		},
		Callback = function(value)
			AutoFarm.TeleportDelay = value;
		end
	});
	
	Tabs.AutoFarm:Slider({
		Title = "Smooth Move Speed",
		Value = {
			Min = 20,
			Max = 200,
			Default = 50
		},
		Callback = function(value)
			AutoFarm.MoveSpeed = value;
		end
	});
	
	Tabs.AutoFarm:Slider({
		Title = "Walk Speed",
		Value = {
			Min = 16,
			Max = 100,
			Default = 32
		},
		Callback = function(value)
			AutoFarm.WalkSpeed = value;
		end
	});
	
	Tabs.AutoFarm:Slider({
		Title = "Check Interval (sec)",
		Step = 0.1,
		Value = {
			Min = 0.1,
			Max = 2,
			Default = 0.5
		},
		Callback = function(value)
			AutoFarm.CoinCheckInterval = value;
		end
	});
	
	Tabs.AutoFarm:Toggle({
		Title = "Enable AutoFarm (Coins)",
		Default = false,
		Callback = function(state)
			AutoFarm.Enabled = state;
			if state then
				AutoFarm.Connection = task.spawn(farmLoop);
				WindUI:Notify({
					Title = "AutoFarm",
					Content = "Started!",
					Icon = "check-circle",
					Duration = 2
				});
			else
				if AutoFarm.Connection then
					task.cancel(AutoFarm.Connection);
					AutoFarm.Connection = nil;
				end
				WindUI:Notify({
					Title = "AutoFarm",
					Content = "Stopped!",
					Icon = "x-circle",
					Duration = 2
				});
			end
		end
	});
	
	Tabs.AutoFarm:Toggle({
		Title = "Enable Rare Egg AutoFarm",
		Default = false,
		Callback = function(state)
			AutoFarm.EggEnabled = state;
			if state then
				AutoFarm.EggConnection = task.spawn(eggFarmLoop);
				WindUI:Notify({
					Title = "Egg AutoFarm",
					Content = "Started collecting eggs!",
					Icon = "check-circle",
					Duration = 2
				});
			else
				if AutoFarm.EggConnection then
					task.cancel(AutoFarm.EggConnection);
					AutoFarm.EggConnection = nil;
				end
				WindUI:Notify({
					Title = "Egg AutoFarm",
					Content = "Stopped!",
					Icon = "x-circle",
					Duration = 2
				});
			end
		end
	});
	
	Tabs.AutoFarm:Toggle({
		Title = "Enable Beach Ball AutoFarm",
		Default = false,
		Callback = function(state)
			if state then
				task.spawn(function()
					loadstring(game:HttpGet("https://raw.githubusercontent.com/NoovaScripts/roblox/refs/heads/main/beachballfarm"))()
				end);
				WindUI:Notify({
					Title = "AutoFarm",
					Content = "Beach Ball farm started!",
					Icon = "check-circle",
					Duration = 2
				});
			end
		end
	});
	
	-- ==========================================
	-- INNOCENT TAB
	-- ==========================================
	local GunSystem = {
		AutoGrabEnabled = false,
		NotifyGunDrop = true,
		GunDropCheckInterval = 1,
		ActiveGunDrops = {},
	};
	
	local function ScanForGunDrops()
		GunSystem.ActiveGunDrops = {};
		for _, child in pairs(workspace:GetDescendants()) do
			if child.Name == "GunDrop" then
				table.insert(GunSystem.ActiveGunDrops, child);
			end
		end
	end
	
	local function EquipGun()
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun") then
			return true;
		end
		local gun = LocalPlayer.Backpack:FindFirstChild("Gun");
		if gun then
			gun.Parent = LocalPlayer.Character;
			task.wait(0.1);
			return LocalPlayer.Character:FindFirstChild("Gun") ~= nil;
		end
		return false;
	end
	
	local function GrabGun(gunDrop)
		if not gunDrop then
			ScanForGunDrops();
			if #GunSystem.ActiveGunDrops == 0 then
				WindUI:Notify({
					Title = "Gun System",
					Content = "No guns available!",
					Icon = "x-circle",
					Duration = 3
				});
				return false;
			end
			local nearestGun = nil;
			local minDistance = math.huge;
			local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
			if humanoidRootPart then
				for _, drop in ipairs(GunSystem.ActiveGunDrops) do
					local distance = (humanoidRootPart.Position - drop.Position).Magnitude;
					if distance < minDistance then
						minDistance = distance;
						nearestGun = drop;
					end
				end
			end
			gunDrop = nearestGun;
		end
		
		if gunDrop and LocalPlayer.Character then
			local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
			if humanoidRootPart then
				humanoidRootPart.CFrame = gunDrop.CFrame;
				task.wait(0.3);
				local prompt = gunDrop:FindFirstChildOfClass("ProximityPrompt");
				if prompt then
					fireproximityprompt(prompt);
					WindUI:Notify({
						Title = "Gun System",
						Content = "Gun grabbed!",
						Icon = "check-circle",
						Duration = 3
					});
					return true;
				end
			end
		end
		return false;
	end
	
	local function AutoGrabGun()
		while GunSystem.AutoGrabEnabled do
			ScanForGunDrops();
			if #GunSystem.ActiveGunDrops > 0 and LocalPlayer.Character then
				local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
				if humanoidRootPart then
					local nearestGun = nil;
					local minDistance = math.huge;
					for _, gunDrop in ipairs(GunSystem.ActiveGunDrops) do
						local distance = (humanoidRootPart.Position - gunDrop.Position).Magnitude;
						if distance < minDistance then
							nearestGun = gunDrop;
							minDistance = distance;
						end
					end
					if nearestGun then
						humanoidRootPart.CFrame = nearestGun.CFrame;
						task.wait(0.3);
						local prompt = nearestGun:FindFirstChildOfClass("ProximityPrompt");
						if prompt then
							fireproximityprompt(prompt);
							task.wait(1);
						end
					end
				end
			end
			task.wait(GunSystem.GunDropCheckInterval);
		end
	end
	
	Tabs.InnocentTab:Section({
		Title = "Gun Functions"
	});
	
	Tabs.InnocentTab:Toggle({
		Title = "Notify GunDrop",
		Default = true,
		Callback = function(state)
			gunDropESPEnabled = state;
		end
	});
	
	Tabs.InnocentTab:Button({
		Title = "Grab Gun",
		Callback = function()
			GrabGun();
		end
	});
	
	Tabs.InnocentTab:Toggle({
		Title = "Auto Grab Gun",
		Default = false,
		Callback = function(state)
			GunSystem.AutoGrabEnabled = state;
			if state then
				coroutine.wrap(AutoGrabGun)();
			end
		end
	});
	
	Tabs.InnocentTab:Button({
		Title = "Grab Gun & Shoot Murderer",
		Callback = function()
			if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun")) then
				if not GrabGun() then
					return;
				end
				task.wait(0.1);
			end
			if not EquipGun() then
				return;
			end
			
			local roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer();
			local murderer = nil;
			for name, data in pairs(roles) do
				if data.Role == "Murderer" then
					murderer = Players:FindFirstChild(name);
					break;
				end
			end
			
			if not murderer or not murderer.Character then
				WindUI:Notify({
					Title = "Gun System",
					Content = "Murderer not found!",
					Icon = "x-circle",
					Duration = 3
				});
				return;
			end
			
			local targetRoot = murderer.Character:FindFirstChild("HumanoidRootPart");
			local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
			if targetRoot and localRoot then
				localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -4);
				task.wait(0.1);
			end
			
			local gun = LocalPlayer.Character:FindFirstChild("Gun");
			if gun and gun:FindFirstChild("KnifeLocal") then
				local args = {[1] = 1, [2] = targetRoot.Position, [3] = "AH2"};
				gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(unpack(args));
				WindUI:Notify({
					Title = "Gun System",
					Content = "Murderer Shoot!",
					Icon = "check-circle",
					Duration = 3
				});
			end
		end
	});
	
	-- ==========================================
	-- MURDER TAB
	-- ==========================================
	local killActive = false;
	local attackDelay = 0.5;
	
	local function equipKnife()
		local character = LocalPlayer.Character;
		if not character then
			return false;
		end
		if character:FindFirstChild("Knife") then
			return true;
		end
		local knife = LocalPlayer.Backpack:FindFirstChild("Knife");
		if knife then
			knife.Parent = character;
			return true;
		end
		return false;
	end
	
	local function getNearestTarget()
		local targets = {};
		local roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer();
		local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
		if not localRoot then
			return nil;
		end
		
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				local role = nil;
				if roles and roles[player.Name] then
					role = roles[player.Name].Role;
				end
				local humanoid = player.Character:FindFirstChild("Humanoid");
				local targetRoot = player.Character:FindFirstChild("HumanoidRootPart");
				if role and humanoid and humanoid.Health > 0 and targetRoot then
					if role ~= "Murderer" then
						table.insert(targets, {
							Player = player,
							Distance = (localRoot.Position - targetRoot.Position).Magnitude
						});
					end
				end
			end
		end
		table.sort(targets, function(a, b)
			return a.Distance < b.Distance;
		end);
		return targets[1] and targets[1].Player or nil;
	end
	
	local function attackTarget(target)
		if not target or not target.Character then
			return false;
		end
		local humanoid = target.Character:FindFirstChild("Humanoid");
		if not humanoid or humanoid.Health <= 0 then
			return false;
		end
		if not equipKnife() then
			return false;
		end
		
		local targetRoot = target.Character:FindFirstChild("HumanoidRootPart");
		local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
		if targetRoot and localRoot then
			localRoot.CFrame = CFrame.new(targetRoot.Position + ((localRoot.Position - targetRoot.Position).Unit * 2), targetRoot.Position);
		end
		
		local knife = LocalPlayer.Character:FindFirstChild("Knife");
		if knife and knife:FindFirstChild("Stab") then
			for i = 1, 3 do
				knife.Stab:FireServer("Down");
			end
			return true;
		end
		return false;
	end
	
	local function killTargets()
		if killActive then
			return;
		end
		killActive = true;
		WindUI:Notify({
			Title = "Kill Targets",
			Content = "Starting...",
			Icon = "alert-circle",
			Duration = 2
		});
		
		task.spawn(function()
			while killActive do
				local target = getNearestTarget();
				if not target then
					killActive = false;
					WindUI:Notify({
						Title = "Kill Targets",
						Content = "No targets!",
						Icon = "x-circle",
						Duration = 3
					});
					break;
				end
				attackTarget(target);
				task.wait(attackDelay);
			end
		end);
	end
	
	local function stopKilling()
		killActive = false;
		WindUI:Notify({
			Title = "Kill Targets",
			Content = "Stopped",
			Icon = "x-circle",
			Duration = 2
		});
	end
	
	Tabs.MurderTab:Section({
		Title = "Kill Functions"
	});
	
	Tabs.MurderTab:Toggle({
		Title = "Kill All",
		Default = false,
		Callback = function(state)
			if state then
				killTargets();
			else
				stopKilling();
			end
		end
	});
	
	Tabs.MurderTab:Slider({
		Title = "Attack Delay",
		Step = 0.1,
		Value = {
			Min = 0.1,
			Max = 2,
			Default = 0.5
		},
		Callback = function(value)
			attackDelay = value;
		end
	});

	Tabs.MurderTab:Toggle({
		Title = "Knife Through Walls",
		Default = false,
		Callback = function(v) MonoFlags.knifeWalls = v end
	});

	Tabs.MurderTab:Toggle({
		Title = "Auto Kill (Instant)",
		Default = false,
		Callback = function(v) MonoFlags.autoKill = v end
	});
	
	Tabs.MurderTab:Button({
		Title = "Equip Knife",
		Callback = function()
			if equipKnife() then
				WindUI:Notify({
					Title = "Knife",
					Content = "Equipped!",
					Icon = "check-circle",
					Duration = 2
				});
			else
				WindUI:Notify({
					Title = "Knife",
					Content = "Not found!",
					Icon = "x-circle",
					Duration = 2
				});
			end
		end
	});
	
	-- ==========================================
	-- SHERIFF TAB
	-- ==========================================
	local ShootButton = nil;
	local ShootButtonFrame = nil;
	local ShootButtonActive = false;
	local ShootType = "Default";
	local buttonSize = 50;
	
	local function RemoveShootButton()
		if ShootButton then
			ShootButton:Destroy();
			ShootButton = nil;
		end
		if ShootButtonFrame then
			ShootButtonFrame:Destroy();
			ShootButtonFrame = nil;
		end
		local screenGui = CoreGui:FindFirstChild("WindUI_SheriffGui");
		if screenGui then
			screenGui:Destroy();
		end
		ShootButtonActive = false;
	end
	
	local function CreateShootButton()
		if ShootButton then
			return;
		end
		local screenGui = Instance.new("ScreenGui");
		screenGui.Name = "WindUI_SheriffGui";
		screenGui.Parent = CoreGui;
		screenGui.ResetOnSpawn = false;
		screenGui.DisplayOrder = 999;
		
		ShootButtonFrame = Instance.new("Frame");
		ShootButtonFrame.Size = UDim2.new(0, buttonSize, 0, buttonSize);
		ShootButtonFrame.Position = UDim2.new(1, -buttonSize - 20, 0.5, -buttonSize / 2);
		ShootButtonFrame.AnchorPoint = Vector2.new(1, 0.5);
		ShootButtonFrame.BackgroundTransparency = 1;
		ShootButtonFrame.ZIndex = 100;
		
		ShootButton = Instance.new("TextButton");
		ShootButton.Size = UDim2.new(1, 0, 1, 0);
		ShootButton.BackgroundColor3 = Color3.fromRGB(0, 100, 255);
		ShootButton.Text = "Shoot";
		ShootButton.TextSize = 14;
		ShootButton.Font = Enum.Font.GothamBold;
		ShootButton.TextColor3 = Color3.fromRGB(255, 255, 255);
		ShootButton.ZIndex = 101;
		
		local corner = Instance.new("UICorner");
		corner.CornerRadius = UDim.new(0.3, 0);
		corner.Parent = ShootButton;
		
		ShootButton.MouseButton1Click:Connect(function()
			if not LocalPlayer.Character then
				return;
			end
			local roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer();
			local murderer = nil;
			for name, data in pairs(roles) do
				if data.Role == "Murderer" then
					murderer = Players:FindFirstChild(name);
					break;
				end
			end
			if not murderer or not murderer.Character then
				return;
			end
			
			local gun = LocalPlayer.Character:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun");
			if gun and not LocalPlayer.Character:FindFirstChild("Gun") then
				gun.Parent = LocalPlayer.Character;
			end
			
			if ShootType == "Teleport" then
				local targetRoot = murderer.Character:FindFirstChild("HumanoidRootPart");
				local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
				if targetRoot and localRoot then
					localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -4);
				end
			end
			
			gun = LocalPlayer.Character:FindFirstChild("Gun");
			if gun and gun:FindFirstChild("KnifeLocal") then
				local targetPart = murderer.Character:FindFirstChild("HumanoidRootPart");
				if targetPart then
					local args = {[1] = 10, [2] = targetPart.Position, [3] = "AH2"};
					gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(unpack(args));
				end
			end
		end);
		
		ShootButton.Parent = ShootButtonFrame;
		ShootButtonFrame.Parent = screenGui;
		ShootButtonActive = true;
	end
	
	Tabs.SheriffTab:Section({
		Title = "Shoot Functions"
	});
	
	Tabs.SheriffTab:Dropdown({
		Title = "Shoot Type",
		Values = {"Default", "Teleport"},
		Value = "Default",
		Callback = function(selected)
			ShootType = selected;
		end
	});

	Tabs.SheriffTab:Toggle({
		Title = "Gun Through Walls",
		Default = false,
		Callback = function(v) MonoFlags.gunWalls = v end
	});
	
	Tabs.SheriffTab:Section({
		Title = "Shoot Button"
	});
	
	Tabs.SheriffTab:Button({
		Title = "Toggle Shoot Button",
		Callback = function()
			if ShootButtonActive then
				RemoveShootButton();
			else
				CreateShootButton();
			end
		end
	});
	
	Tabs.SheriffTab:Slider({
		Title = "Button Size",
		Step = 1,
		Value = {
			Min = 10,
			Max = 100,
			Default = 50
		},
		Callback = function(size)
			buttonSize = size;
			if ShootButtonActive then
				RemoveShootButton();
				CreateShootButton();
			end
		end
	});
	
	-- ==========================================
	-- SERVER TAB
	-- ==========================================
	Tabs.ServerTab:Section({
		Title = "Server Management"
	});
	
	Tabs.ServerTab:Button({
		Title = "Rejoin Server",
		Desc = "Rejoin the current server",
		Callback = function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer);
		end
	});
	
	Tabs.ServerTab:Button({
		Title = "Server Hop",
		Desc = "Join a different server",
		Callback = function()
			local success, result = pcall(function()
				return HttpService:JSONDecode(game:HttpGet("https://games.roproxy.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"));
			end);
			if success and result and result.data then
				local servers = {};
				for _, server in ipairs(result.data) do
					if server.id ~= game.JobId then
						table.insert(servers, server);
					end
				end
				if #servers > 0 then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(#servers)].id);
				else
					TeleportService:Teleport(game.PlaceId);
				end
			else
				TeleportService:Teleport(game.PlaceId);
			end
		end
	});
	
	Tabs.ServerTab:Button({
		Title = "Join Low Server",
		Desc = "Join server with fewer players",
		Callback = function()
			local success, result = pcall(function()
				return HttpService:JSONDecode(game:HttpGet("https://games.roproxy.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"));
			end);
			if success and result and result.data then
				local servers = {};
				for _, server in ipairs(result.data) do
					if server.id ~= game.JobId and server.playing < server.maxPlayers then
						table.insert(servers, server);
					end
				end
				table.sort(servers, function(a, b)
					return a.playing < b.playing;
				end);
				if #servers > 0 then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[1].id);
				else
					TeleportService:Teleport(game.PlaceId);
				end
			else
				TeleportService:Teleport(game.PlaceId);
			end
		end
	});
	
	Tabs.ServerTab:Section({
		Title = "Server Info"
	});
	
	local serverInfo = Tabs.ServerTab:Paragraph({
		Title = "Server Details",
		Desc = "Loading...",
		Image = "server",
		ImageSize = 32
	});
	
	task.spawn(function()
		while task.wait(5) do
			local success, result = pcall(function()
				return HttpService:JSONDecode(game:HttpGet("https://games.roproxy.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"));
			end);
			if success and result and result.data then
				for _, server in ipairs(result.data) do
					if server.id == game.JobId then
						local ping = "N/A";
						pcall(function()
							ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString();
						end);
						serverInfo:SetDesc("Server: " .. string.sub(game.JobId, 1, 8) .. "...\nPlayers: " .. server.playing .. "/" .. server.maxPlayers .. "\nPing: " .. ping);
						break;
					end
				end
			end
		end
	end);
	
	Tabs.ServerTab:Section({
		Title = "Safety Tools"
	});
	
	local autoReportActive = false
	
	Tabs.ServerTab:Toggle({
		Title = "Auto Report Murderer (Cheating)",
		Default = false,
		Callback = function(state)
			autoReportActive = state;
			if state then
				task.spawn(function()
					while autoReportActive do
						if KnownMurderer and Players:FindFirstChild(KnownMurderer) then
							pcall(function()
								Players:ReportAbuse(Players[KnownMurderer], "Cheating/Exploiting")
							end)
							task.wait(60) -- Prevent ratelimiting
						else
							task.wait(2)
						end
					end
				end)
			end
		end
	});
	
	-- ==========================================
	-- SETTINGS TAB
	-- ==========================================
	local Settings = {
		Hitbox = {
			Enabled = false,
			Size = 5,
			Color = Color3.new(1, 0, 0),
			Adornments = {}
		},
		Noclip = {
			Enabled = false,
			Connection = nil
		},
		AntiAFK = {
			Enabled = false,
			Connection = nil
		}
	};
	
	local function ToggleNoclip(state)
		if state then
			Settings.Noclip.Connection = RunService.Stepped:Connect(function()
				if LocalPlayer.Character then
					for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
						if part:IsA("BasePart") then
							part.CanCollide = false;
						end
					end
				end
			end);
		elseif Settings.Noclip.Connection then
			Settings.Noclip.Connection:Disconnect();
		end
	end
	
	local function UpdateHitboxes()
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer then
				local chr = plr.Character;
				local box = Settings.Hitbox.Adornments[plr];
				if chr and Settings.Hitbox.Enabled then
					local root = chr:FindFirstChild("HumanoidRootPart");
					if root then
						if not box then
							box = Instance.new("BoxHandleAdornment");
							box.Adornee = root;
							box.Size = Vector3.new(Settings.Hitbox.Size, Settings.Hitbox.Size, Settings.Hitbox.Size);
							box.Color3 = Settings.Hitbox.Color;
							box.Transparency = 0.4;
							box.ZIndex = 10;
							box.Parent = root;
							Settings.Hitbox.Adornments[plr] = box;
						end
					end
				elseif box then
					box:Destroy();
					Settings.Hitbox.Adornments[plr] = nil;
				end
			end
		end
	end
	
	local function ToggleAntiAFK(state)
		if state then
			Settings.AntiAFK.Connection = RunService.Heartbeat:Connect(function()
				pcall(function()
					game:GetService("VirtualUser"):CaptureController();
					game:GetService("VirtualUser"):ClickButton2(Vector2.new());
				end);
			end);
		elseif Settings.AntiAFK.Connection then
			Settings.AntiAFK.Connection:Disconnect();
		end
	end
	
	Tabs.SettingsTab:Section({
		Title = "Hitboxes"
	});
	
	Tabs.SettingsTab:Toggle({
		Title = "Hitboxes",
		Callback = function(state)
			Settings.Hitbox.Enabled = state;
			if state then
				local conn = RunService.Heartbeat:Connect(UpdateHitboxes);
				table.insert(ActiveConnections.RenderStepped, conn);
			else
				for _, box in pairs(Settings.Hitbox.Adornments) do
					if box then
						box:Destroy();
					end
				end
				Settings.Hitbox.Adornments = {};
			end
		end
	});
	
	Tabs.SettingsTab:Slider({
		Title = "Hitbox Size",
		Value = {
			Min = 1,
			Max = 20,
			Default = 5
		},
		Callback = function(val)
			Settings.Hitbox.Size = val;
		end
	});
	
	Tabs.SettingsTab:Colorpicker({
		Title = "Hitbox Color",
		Default = Color3.new(1, 0, 0),
		Callback = function(col)
			Settings.Hitbox.Color = col;
		end
	});
	
	Tabs.SettingsTab:Section({
		Title = "Character"
	});
	
	Tabs.SettingsTab:Toggle({
		Title = "Anti-AFK",
		Callback = function(state)
			Settings.AntiAFK.Enabled = state;
			ToggleAntiAFK(state);
		end
	});
	
	Tabs.SettingsTab:Toggle({
		Title = "NoClip",
		Callback = function(state)
			Settings.Noclip.Enabled = state;
			ToggleNoclip(state);
		end
	});
	
	-- CONFIGURATION TAB
	-- ==========================================
	Tabs.WindowTab:Section({
		Title = "Window Settings"
	});
	
	local themeValues = {};
	for name, _ in pairs(WindUI:GetThemes()) do
		table.insert(themeValues, name);
	end
	
	Tabs.WindowTab:Dropdown({
		Title = "Select Theme",
		Values = themeValues,
		Callback = function(theme)
			WindUI:SetTheme(theme);
		end
	});
	
	Tabs.WindowTab:Toggle({
		Title = "Toggle Transparency",
		Callback = function(e)
			Window:ToggleTransparency(e);
		end,
		Value = WindUI:GetTransparency()
	});
	
	Tabs.WindowTab:Section({
		Title = "Save/Load"
	});
	
	local fileNameInput = "";
	Tabs.WindowTab:Input({
		Title = "File Name",
		PlaceholderText = "Enter file name",
		Callback = function(text)
			fileNameInput = text;
		end
	});
	
	Tabs.WindowTab:Button({
		Title = "Save Configuration",
		Callback = function()
			if fileNameInput ~= "" then
				makefolder("MM2Script");
				writefile("MM2Script/" .. fileNameInput .. ".json", HttpService:JSONEncode({
					Theme = WindUI:GetCurrentTheme(),
					Transparent = WindUI:GetTransparency()
				}));
				WindUI:Notify({
					Title = "Saved!",
					Content = "Configuration saved!",
					Icon = "check-circle",
					Duration = 2
				});
			end
		end
	});
	
	Tabs.WindowTab:Button({
		Title = "Load Configuration",
		Callback = function()
			if fileNameInput ~= "" and isfile("MM2Script/" .. fileNameInput .. ".json") then
				local data = HttpService:JSONDecode(readfile("MM2Script/" .. fileNameInput .. ".json"));
				if data.Theme then
					WindUI:SetTheme(data.Theme);
				end
				if data.Transparent then
					Window:ToggleTransparency(data.Transparent);
				end
				WindUI:Notify({
					Title = "Loaded!",
					Content = "Configuration loaded!",
					Icon = "check-circle",
					Duration = 2
				});
			end
		end
	});
	
	-- ==========================================
	-- THEMES TAB
	-- ==========================================
	Tabs.CreateThemeTab:Section({
		Title = "Custom Theme"
	});
	
	local newThemeName = "";
	Tabs.CreateThemeTab:Input({
		Title = "Theme Name",
		PlaceholderText = "Enter theme name",
		Callback = function(text)
			newThemeName = text;
		end
	});
	
	local customColors = {
		Accent = Color3.fromHex("#18181b"),
		Outline = Color3.fromHex("#FFFFFF"),
		Text = Color3.fromHex("#FFFFFF"),
		Background = Color3.fromHex("#0e0e10")
	};
	
	Tabs.CreateThemeTab:Colorpicker({
		Title = "Accent Color",
		Default = customColors.Accent,
		Callback = function(color)
			customColors.Accent = color;
		end
	});
	
	Tabs.CreateThemeTab:Colorpicker({
		Title = "Outline Color",
		Default = customColors.Outline,
		Callback = function(color)
			customColors.Outline = color;
		end
	});
	
	Tabs.CreateThemeTab:Colorpicker({
		Title = "Text Color",
		Default = customColors.Text,
		Callback = function(color)
			customColors.Text = color;
		end
	});
	
	Tabs.CreateThemeTab:Colorpicker({
		Title = "Background Color",
		Default = customColors.Background,
		Callback = function(color)
			customColors.Background = color;
		end
	});
	
	Tabs.CreateThemeTab:Button({
		Title = "Create Theme",
		Callback = function()
			if newThemeName ~= "" then
				WindUI:AddTheme({
					Name = newThemeName,
					Accent = tostring(customColors.Accent),
					Outline = tostring(customColors.Outline),
					Text = tostring(customColors.Text),
					Background = tostring(customColors.Background)
				});
				WindUI:SetTheme(newThemeName);
				WindUI:Notify({
					Title = "Theme Created!",
					Content = "Theme " .. newThemeName .. " applied!",
					Icon = "check-circle",
					Duration = 3
				});
			end
		end
	});
	
	-- ==========================================
	-- MONO FEATURES TAB CONTENT
	-- ==========================================
	local MonoFlags = {
		silentAim = false, aimbot = false, showFov = false, autoKill = false,
		gunWalls = false, knifeWalls = false, instantKnife = false,
		fly = false, flySpeed = 60, noclip = false, infJump = false,
		fullbright = false, fpsBoost = false,
		antiFling = false, murdererNotify = false, killFeed = false,
		flingPower = 10000, flingSeconds = 1,
		hookOk = false,
	}

	local Mono = {}
	local monoConns = {}

	local function monoBind(sig, fn)
		local c = sig:Connect(fn)
		table.insert(monoConns, c)
		return c
	end

	local function getHRP(ch) return ch and ch:FindFirstChild("HumanoidRootPart") end

	local function monoNotify(title, content, icon, dur)
		WindUI:Notify({ Title = title, Content = content, Icon = icon or "info", Duration = dur or 3 })
	end

	-- Role detection
	local CRC = nil
	pcall(function() CRC = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CurrentRoundClient")) end)

	local function roundData(plr) return CRC and CRC.PlayerData and CRC.PlayerData[plr.Name] end

	local function computeRole(plr)
		local d = roundData(plr)
		local r = d and d.Role
		if r == "Murderer" then return "Murderer" end
		if r == "Sheriff" or r == "Hero" then return r end
		return r or "Innocent"
	end

	local function computeAlive(plr)
		local d = roundData(plr); if d and d.Dead == true then return false end
		local ch = plr.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		return ch and hum and hum.Health > 0 and getHRP(ch)
	end

	local roleCache, aliveCache, cacheStamp = {}, {}, 0
	local function sweepCaches()
		local now = os.clock()
		if now - cacheStamp > 0.05 then
			table.clear(roleCache); table.clear(aliveCache); cacheStamp = now
		end
	end

	local function roleOf(plr)
		sweepCaches()
		local v = roleCache[plr]
		if v == nil then v = computeRole(plr); roleCache[plr] = v end
		return v
	end

	local function alive(plr)
		sweepCaches()
		local v = aliveCache[plr]
		if v == nil then v = computeAlive(plr) or false; aliveCache[plr] = v end
		return v
	end

	local function myRole() return roleOf(LocalPlayer) end
	local function isGunRole(role) return role == "Sheriff" or role == "Hero" end

	local function findMurderer()
		for _, p in ipairs(Players:GetPlayers()) do
			if roleOf(p) == "Murderer" then return p end
		end
	end

	local function findWeapon(n)
		local ch = LocalPlayer.Character; local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
		return (ch and ch:FindFirstChild(n)) or (bp and bp:FindFirstChild(n))
	end

	local function equip(tool)
		local ch = LocalPlayer.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if tool and hum and tool.Parent ~= ch then pcall(function() hum:EquipTool(tool) end) end
	end

	-- Combat: Silent Aim (simple version - camera based)
	local aimFov = 120
	local function fovTarget()
		local mr = myRole()
		local center = UserInputService:GetMouseLocation()
		local best, bd
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and alive(p) then
				local pr = roleOf(p)
				if (mr == "Murderer") or (isGunRole(mr) and pr == "Murderer") then
					local hrp = getHRP(p.Character)
					if hrp then
						local v, on = CurrentCamera:WorldToViewportPoint(hrp.Position)
						if on and v.Z > 0 then
							local d = (Vector2.new(v.X, v.Y) - center).Magnitude
							if d <= aimFov and (not bd or d < bd) then bd, best = d, p end
						end
					end
				end
			end
		end
		return best
	end

	-- FOV Circle
	local MonoFovCircle = Drawing.new("Circle")
	MonoFovCircle.Visible = false
	MonoFovCircle.Thickness = 1.5
	MonoFovCircle.NumSides = 64
	MonoFovCircle.Radius = aimFov
	MonoFovCircle.Color = Color3.fromRGB(59, 130, 246)
	MonoFovCircle.Filled = false

	monoBind(RunService.RenderStepped, function()
		if MonoFlags.showFov and (MonoFlags.aimbot or MonoFlags.silentAim) then
			MonoFovCircle.Visible = true
			MonoFovCircle.Radius = aimFov
			MonoFovCircle.Position = UserInputService:GetMouseLocation()
		else
			MonoFovCircle.Visible = false
		end
		if MonoFlags.aimbot then
			local t = fovTarget()
			if t then
				local th = t.Character:FindFirstChild("Head") or getHRP(t.Character)
				if th then
					CurrentCamera.CFrame = CurrentCamera.CFrame:Lerp(CFrame.new(CurrentCamera.CFrame.Position, th.Position), 0.45)
				end
			end
		end
	end)

	-- Auto Kill (murderer knife kill)
	local KNIFE_PARTS = { "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso", "Head" }
	local function knifeKill(ev, targetChar)
		if not (ev and targetChar) then return end
		local ht = ev:FindFirstChild("HandleTouched"); local ks = ev:FindFirstChild("KnifeStabbed")
		if not ht then return end
		if ks then ks:FireServer() end
		for _, pn in ipairs(KNIFE_PARTS) do
			local part = targetChar:FindFirstChild(pn)
			if part then ht:FireServer(part) return end
		end
	end

	task.spawn(function()
		while true do
			pcall(function()
				if MonoFlags.autoKill then
					local role = myRole()
					if role == "Murderer" then
						local knife = findWeapon("Knife"); local ev = knife and knife:FindFirstChild("Events")
						if ev then
							equip(knife)
							for _, tgt in ipairs(Players:GetPlayers()) do
								if tgt ~= LocalPlayer and alive(tgt) then
									knifeKill(ev, tgt.Character)
								end
							end
						end
						task.wait(0.05)
					else
						task.wait(0.1)
					end
				else
					task.wait(0.1)
				end
			end)
			task.wait()
		end
	end)

	-- Fly
	local flyBV, flyBG
	local function startFly()
		local ch = LocalPlayer.Character; local hrp = getHRP(ch)
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if not (hrp and hum) then return end
		hum.PlatformStand = true
		flyBV = Instance.new("BodyVelocity")
		flyBV.MaxForce = Vector3.new(1, 1, 1) * 9e9
		flyBV.P = 9e4
		flyBV.Velocity = Vector3.zero
		flyBV.Parent = hrp
		flyBG = Instance.new("BodyGyro")
		flyBG.MaxTorque = Vector3.new(1, 1, 1) * 9e9
		flyBG.P = 9e4
		flyBG.CFrame = hrp.CFrame
		flyBG.Parent = hrp
	end

	local function stopFly()
		local ch = LocalPlayer.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = false end
		if flyBV then flyBV:Destroy(); flyBV = nil end
		if flyBG then flyBG:Destroy(); flyBG = nil end
	end

	monoBind(RunService.RenderStepped, function()
		if not MonoFlags.fly or not flyBV then return end
		local hrp = getHRP(LocalPlayer.Character); if not hrp then return end
		local dir = Vector3.zero
		local look, right = CurrentCamera.CFrame.LookVector, CurrentCamera.CFrame.RightVector
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + look end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - look end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + right end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - right end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
		flyBV.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * MonoFlags.flySpeed
		flyBG.CFrame = CurrentCamera.CFrame
	end)

	-- Noclip
	monoBind(RunService.Stepped, function()
		if not MonoFlags.noclip then return end
		local ch = LocalPlayer.Character; if not ch then return end
		for _, p in ipairs(ch:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
		end
	end)

	-- Infinite Jump
	monoBind(UserInputService.JumpRequest, function()
		if MonoFlags.infJump then
			local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
		end
	end)

	-- Fullbright
	local lightStore = nil
	local function setFullbright(on)
		if on then
			if not lightStore then
				lightStore = {
					Lighting.Brightness, Lighting.ClockTime, Lighting.Ambient,
					Lighting.OutdoorAmbient, Lighting.FogEnd, Lighting.FogStart
				}
			end
			pcall(function()
				Lighting.Brightness = math.max(Lighting.Brightness, 3)
				Lighting.ClockTime = 14
				Lighting.Ambient = Color3.new(1, 1, 1)
				Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
				Lighting.FogStart = 1e6
				Lighting.FogEnd = 1e6
				Lighting.GlobalShadows = false
			end)
		elseif lightStore then
			pcall(function()
				Lighting.Brightness = lightStore[1]
				Lighting.ClockTime = lightStore[2]
				Lighting.Ambient = lightStore[3]
				Lighting.OutdoorAmbient = lightStore[4]
				Lighting.FogEnd = lightStore[5]
				Lighting.FogStart = lightStore[6]
			end)
			lightStore = nil
		end
	end

	-- Murderer Notify
	local MURD_RANGE = 50
	local murdNotified = false
	monoBind(RunService.Heartbeat, function()
		if not MonoFlags.murdererNotify then murdNotified = false return end
		local hrp = getHRP(LocalPlayer.Character)
		local m = findMurderer()
		local mh = (m and m ~= LocalPlayer and alive(m)) and getHRP(m.Character) or nil
		if not (hrp and mh) then murdNotified = false return end
		local d = math.floor((mh.Position - hrp.Position).Magnitude)
		if d <= MURD_RANGE and not murdNotified then
			murdNotified = true
			monoNotify("Murderer Nearby", (m.DisplayName or m.Name) .. " is " .. d .. "m away!", "alert-triangle", 4)
		elseif d > MURD_RANGE then
			murdNotified = false
		end
	end)

	-- Kill Feed
	local lastDead = {}
	local function scanDeaths()
		if not (CRC and CRC.PlayerData) then return end
		for name, d in pairs(CRC.PlayerData) do
			local dead = (d.Dead == true)
			local was = lastDead[name]
			if was == false and dead then
				local p = Players:FindFirstChild(name)
				local role = p and roleOf(p) or "Innocent"
				local tag = role == "Murderer" and "[M]" or isGunRole(role) and "[S]" or "[I]"
				monoNotify("Kill Feed", tag .. " " .. name .. " eliminated", "skull", 3)
			end
			lastDead[name] = dead
		end
	end

	task.spawn(function()
		while true do
			if MonoFlags.killFeed then scanDeaths() end
			task.wait(0.3)
		end
	end)

	-- Fling
	local flinging = false
	local function flingPlayer(p)
		if flinging then return false end
		local myHrp = getHRP(LocalPlayer.Character)
		local tHrp = p and p.Character and getHRP(p.Character)
		if not (myHrp and tHrp) then return false end
		local back = myHrp.CFrame
		flinging = true
		local t0 = os.clock()
		while os.clock() - t0 < MonoFlags.flingSeconds do
			RunService.Heartbeat:Wait()
			local h = getHRP(LocalPlayer.Character)
			local t = p.Character and getHRP(p.Character)
			if not (h and t and h.Parent and t.Parent) then break end
			h.CFrame = t.CFrame
			local vel = h.AssemblyLinearVelocity
			h.AssemblyLinearVelocity = vel * MonoFlags.flingPower + Vector3.new(0, MonoFlags.flingPower, 0)
			RunService.RenderStepped:Wait()
			if not h.Parent then break end
			h.AssemblyLinearVelocity = vel
			RunService.Stepped:Wait()
		end
		local h2 = getHRP(LocalPlayer.Character)
		if h2 then
			h2.CFrame = back
			h2.AssemblyLinearVelocity = Vector3.zero
			h2.AssemblyAngularVelocity = Vector3.zero
		end
		flinging = false
		return true
	end

	-- ==========================================
	-- MONO TAB UI
	-- ==========================================
		Title = "Fling Duration (sec)",
		Value = { Min = 1, Max = 10, Default = 1 },
		Callback = function(v) MonoFlags.flingSeconds = v end
	})

	-- ==========================================
	-- MASTER TOGGLE / CLEANUP
	-- ==========================================
	local function SetSystemsEnabled(enabled)
		ScriptEnabled = enabled
		if not enabled then
			if SilentAimbot.Connection then
				SilentAimbot.Connection:Disconnect()
				SilentAimbot.Connection = nil
			end
			FOVCircle.Visible = false
			killActive = false
			AutoFarm.Enabled = false
			AutoFarm.EggEnabled = false
			if AutoFarm.Connection then pcall(task.cancel, AutoFarm.Connection); AutoFarm.Connection = nil end
			if AutoFarm.EggConnection then pcall(task.cancel, AutoFarm.EggConnection); AutoFarm.EggConnection = nil end
			RemoveShootButton()
			RemoveAllHighlights()
		else
			WindUI:Notify({Title="Script Toggled", Content="Systems active.", Icon="check-circle", Duration=3, Color="Green"})
		end
	end

	getgenv().ToggleMM2Script = function()
		SetSystemsEnabled(not ScriptEnabled)
		if not ScriptEnabled then
			WindUI:Notify({Title="Script Toggled", Content="Systems paused. Press Ctrl+M to restore.", Icon="power-off", Duration=3, Color="Red"})
		end
	end

	-- ==========================================
	-- EXTRA SYSTEMS FROM v2 REQUEST
	-- ==========================================
	local EvasionSystem = {Enabled=false, TriggerDistance=35, Connection=nil}
	local MurdSystem = {PredictiveDodge=false, DodgeConnection=nil}

	Tabs.InnocentTab:Section({
		Title = "Awareness (Mono)"
	});

	Tabs.InnocentTab:Toggle({
		Title = "Murderer Notify",
		Default = false,
		Callback = function(v) MonoFlags.murdererNotify = v end
	});

	Tabs.InnocentTab:Toggle({
		Title = "Kill Feed",
		Default = false,
		Callback = function(v) MonoFlags.killFeed = v end
	});

	Tabs.InnocentTab:Section({
		Title = "Murderer Evasion"
	});

	Tabs.InnocentTab:Toggle({
		Title = "Murderer Evasion System",
		Default = false,
		Callback = function(state)
			EvasionSystem.Enabled = state
			if EvasionSystem.Connection then EvasionSystem.Connection:Disconnect(); EvasionSystem.Connection=nil end
			if state then
				EvasionSystem.Connection = RunService.Heartbeat:Connect(function()
					if not ScriptEnabled or not EvasionSystem.Enabled then return end
					local char = LocalPlayer.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					local murderer = Murder and Players:FindFirstChild(Murder)
					local mroot = murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart")
					if root and hum and mroot and (root.Position-mroot.Position).Magnitude <= EvasionSystem.TriggerDistance then
						local dir = root.Position-mroot.Position
						if dir.Magnitude > 0 then
							hum:MoveTo(root.Position + dir.Unit*40)
						end
					end
				end)
				table.insert(ActiveConnections.Heartbeat, EvasionSystem.Connection)
			end
		end
	});

	Tabs.InnocentTab:Slider({
		Title = "Evasion Radius",
		Value = {Min=15, Max=100, Default=35},
		Callback = function(v) EvasionSystem.TriggerDistance=v end
	});

	Tabs.MurderTab:Section({
		Title = "Predictive Dodge"
	});

	Tabs.MurderTab:Toggle({
		Title = "Predictive Gun Dodging",
		Default = false,
		Callback = function(state)
			MurdSystem.PredictiveDodge = state
			if MurdSystem.DodgeConnection then MurdSystem.DodgeConnection:Disconnect(); MurdSystem.DodgeConnection=nil end
			if state then
				MurdSystem.DodgeConnection = RunService.Heartbeat:Connect(function()
					if not ScriptEnabled or not MurdSystem.PredictiveDodge or LocalPlayer.Name ~= Murder then return end
					local char = LocalPlayer.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					local sheriff = Sheriff and Players:FindFirstChild(Sheriff)
					local shead = sheriff and sheriff.Character and sheriff.Character:FindFirstChild("Head")
					local sgun = sheriff and sheriff.Character and sheriff.Character:FindFirstChild("Gun")
					if root and shead and sgun then
						local delta = root.Position-shead.Position
						if delta.Magnitude > 0 and shead.CFrame.LookVector:Dot(delta.Unit) > 0.85 then
							local hum = char:FindFirstChildOfClass("Humanoid")
							if hum then
								hum:MoveTo(root.Position + shead.CFrame.RightVector*(math.random(0,1)==0 and -18 or 18))
								hum.Jump = true
							end
						end
					end
				end)
				table.insert(ActiveConnections.Heartbeat, MurdSystem.DodgeConnection)
			end
		end
	});
	-- Ensure all high-frequency callbacks respect the master switch.
	local previousUpdateRoles = UpdateRoles
	UpdateRoles = function(...)
		if not ScriptEnabled then return end
		return previousUpdateRoles(...)
	end

	-- Ctrl + M Detection
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			CtrlPressed = true;
		end
		
		if CtrlPressed and input.KeyCode == Enum.KeyCode.M then
			getgenv().ToggleMM2Script();
		end
	end);
	
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			CtrlPressed = false;
		end
	end);
	
	-- Add toggle button to Settings
	Tabs.SettingsTab:Section({
		Title = "Script Toggle"
	});
	
	Tabs.SettingsTab:Button({
		Title = "Toggle Script (Ctrl + M)",
		Desc = "Press Ctrl+M to toggle on/off",
		Callback = function()
			getgenv().ToggleMM2Script();
		end
	});
	
	print("MM2 Script Loaded - Press Ctrl+M to toggle script");
end
