-- ============================================================
-- LIGHT HUB MM2 - COMBINED
-- Merged from Mono MM2 (Fleece) + WindUI MM2 (Feuds)
-- GUI: AIRFLOW (github.com/confessess/AIRFLOW0978109571095710975)
-- ============================================================

-- ============================================================
-- LIGHT HUB MM2 - PART 1: CORE
-- Merged from Mono MM2 (Fleece) + WindUI MM2 (Feuds)
-- GUI: AIRFLOW
-- ============================================================

local AIRFLOW_URL = "https://raw.githubusercontent.com/confessess/AIRFLOW0978109571095710975/main/source.lua"

local function fetchUrl(url)
    -- Try game:HttpGet first
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res) == "string" and #res > 100 then return res end
    -- Try request() if available
    if typeof(request) == "function" then
        local ok2, r = pcall(function()
            return request({ Url = url, Method = "GET" })
        end)
        if ok2 and r and type(r.Body) == "string" and #r.Body > 100 then return r.Body end
    end
    -- Try http_request
    if typeof(http_request) == "function" then
        local ok3, r = pcall(function()
            return http_request({ Url = url, Method = "GET" })
        end)
        if ok3 and r and type(r.Body) == "string" and #r.Body > 100 then return r.Body end
    end
    return nil
end

local AirFlow
do
    local raw = fetchUrl(AIRFLOW_URL)
    if not raw then
        error("[LightHub] Could not download AIRFLOW UI from GitHub. Check your executor's HTTP access.")
    end
    local chunk, loadErr = loadstring(raw)
    if not chunk then
        error("[LightHub] AIRFLOW failed to compile: " .. tostring(loadErr))
    end
    local ok, result = pcall(chunk)
    if not ok then
        error("[LightHub] AIRFLOW crashed on load: " .. tostring(result))
    end
    if type(result) ~= "table" then
        error("[LightHub] AIRFLOW returned unexpected type: " .. type(result))
    end
    AirFlow = result
end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local CollectionService= game:GetService("CollectionService")
local GuiService       = game:GetService("GuiService")
local VirtualUser; pcall(function() VirtualUser = game:GetService("VirtualUser") end)
local Stats            = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ============================================================
-- CONNECTION / STATE TRACKING
-- ============================================================
local conns = {}
local function bind(sig, fn)
    local c = sig:Connect(fn)
    table.insert(conns, c)
    return c
end

local Unloaded = false
local function isDead() return Unloaded end

local flags = {
    -- Combat
    autoKill=false, silentAim=false, aimbot=false, showFov=false,
    gunWalls=false, knifeWalls=false, instantKnife=false,
    gunEsp=false, gunEspDist=false, autoGun=false,
    -- Movement
    fly=false, flySpeed=60, noclip=false, infJump=false, unlockCam=false,
    walkSpeedOn=false, walkSpeed=16, jumpPowerOn=false, jumpPower=50,
    -- ESP
    espBox=false, espChams=false, espNames=false, espRoleTags=false,
    espSkeleton=false, espTracers=false, espAvatar=false, espFill=false,
    espBox3D=false, espMaxDist=0, espTracerFrom="Bottom",
    footstepTrails=false, footMine=false,
    coinEsp=false, trapEsp=false, gunDropEsp=false,
    -- World
    fullbright=false, fpsBoost=false, fovOn=false, fovValue=70,
    -- Farm
    autoCoins=false, eggFarm=false, beachBallFarm=false,
    -- Safety
    antiFling=false, antiTrap=false, murdererNotify=false, antiAfk=false,
    autoReport=false, evasion=false, evasionDist=35, predictiveDodge=false,
    hitboxEnabled=false, hitboxSize=5,
    -- Teleport / Fling
    autoFlingMurderer=false, autoFlingSheriff=false,
    flingPower=10000, flingSeconds=1,
}

local aimFov = 120

local notify = function(title, content, ntype, dur)
    local w = _G.LightHubWindow
    if not w then return end
    pcall(function()
        w:Notify({ Title = title or "Light Hub", Content = tostring(content),
            Type = ntype or "Info", Duration = dur or 3 })
    end)
end

-- ============================================================
-- GAME CHECK (MM2 only)
-- ============================================================
local MM2_UNIVERSE = 66654135
if game.GameId ~= MM2_UNIVERSE then
    local w = AirFlow:CreateWindow({ Title = "Light Hub MM2", Description = "Murder Mystery 2" })
    w:Notify({ Title = "Wrong game", Content = "Light Hub MM2 only works in Murder Mystery 2.", Type = "Error", Duration = 6 })
    return
end

-- ============================================================
-- MOUNT / PROTECT HELPERS
-- ============================================================
local mountTarget
do
    local function try(f) local ok, v = pcall(f); if ok and typeof(v) == "Instance" then return v end end
    mountTarget = (typeof(gethui) == "function") and try(gethui) or nil
    if not mountTarget then
        mountTarget = try(function()
            local c = game:GetService("CoreGui")
            local probe = Instance.new("Folder"); probe.Parent = c; probe:Destroy()
            return c
        end)
    end
    if not mountTarget then
        mountTarget = try(function() return LocalPlayer:FindFirstChildOfClass("PlayerGui") end)
            or LocalPlayer:WaitForChild("PlayerGui", 10)
    end
end

local TRACKED = {}
local function trackGui(inst) table.insert(TRACKED, inst); return inst end
local function protect(inst)
    pcall(function()
        if typeof(syn) == "table" and syn.protect_gui then syn.protect_gui(inst)
        elseif typeof(protectgui) == "function" then protectgui(inst) end
    end)
end

local function create(class, props, children)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = o end
    return o
end

local rndSeed = Random.new(tick() * 1e6 % 2147483647)
local function rnd(len)
    local pool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local out = {}
    for i = 1, (len or rndSeed:NextInteger(9, 15)) do
        local j = rndSeed:NextInteger(1, #pool)
        out[i] = pool:sub(j, j)
    end
    return table.concat(out)
end

-- ESP drawing host
local EspGui = trackGui(create("ScreenGui", { Name = rnd(), ResetOnSpawn = false,
    IgnoreGuiInset = false, DisplayOrder = 998, Parent = mountTarget }))
protect(EspGui)

-- ============================================================
-- SHARED HELPERS
-- ============================================================
local function getHRP(ch) return ch and ch:FindFirstChild("HumanoidRootPart") end

local function badVec(v)
    if typeof(v) ~= "Vector3" then return true end
    if v.X ~= v.X or v.Y ~= v.Y or v.Z ~= v.Z then return true end
    local inf = math.huge
    if v.X == inf or v.X == -inf then return true end
    if v.Y == inf or v.Y == -inf then return true end
    if v.Z == inf or v.Z == -inf then return true end
    return false
end

local CRC; pcall(function() CRC = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CurrentRoundClient")) end)
local function roundData(plr) return CRC and CRC.PlayerData and CRC.PlayerData[plr.Name] end

local Mono = {
    plrs = {},
    unclip = setmetatable({}, { __mode = "k" }),
    tpAt = -10, TP_GRACE = 2.5,
    selfTpAt = -10,
    COIN_MAX_DIST = 250,
    wantPS = false, wantNoclip = false,
    tagOwners = {},
    drawn = {},
    SNAP_HEIGHT = 5,
    GUN_COOLDOWN = 3.25,
    SNAP_COOLDOWN = 3.25,
    snapAt = -10,
    SILENT_HOLD = 1.8,
    WALL_BACKOFF = 0.6,
    FLING_MAX_DY = 140,
    FLING_MAX_RISE = 320,
    flungAt = setmetatable({}, { __mode = "k" }),
    silentPlr = nil, silentAt = 0,
    TextService = game:GetService("TextService"),
}
function Mono.teleporting() return os.clock() - Mono.tpAt < Mono.TP_GRACE end
function Mono.markTeleport() Mono.tpAt = os.clock() end
function Mono.markSelfTP() Mono.selfTpAt = os.clock() end
function Mono.selfTeleporting() return os.clock() - Mono.selfTpAt < 0.35 end

function Mono.refreshTags()
    for _, tag in ipairs({ "Weapon_Gun", "Weapon_Knife" }) do
        local m = Mono.tagOwners[tag]
        if m then table.clear(m) else m = {}; Mono.tagOwners[tag] = m end
        for _, t in ipairs(CollectionService:GetTagged(tag)) do
            local par = t.Parent
            if par then m[par] = true end
        end
    end
end
Mono.refreshTags()

local function charHasWeapon(ch, kind)
    for _, t in ipairs(ch:GetChildren()) do
        if t:IsA("Tool") then
            if kind == "Gun" and (t.Name == "Gun" or t:FindFirstChild("Shoot")) then return true end
            if kind == "Knife" and (t.Name == "Knife" or t:FindFirstChild("Events")) then return true end
        end
    end
    return false
end

local function playerHasTagged(plr, tag)
    local m = Mono.tagOwners[tag]; if not m then return false end
    local ch = plr.Character
    if ch and m[ch] then return true end
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp and m[bp] then return true end
    return false
end

local function computeRole(plr)
    local d = roundData(plr)
    local r = d and d.Role
    if r == "Murderer" then return "Murderer" end
    if r == "Sheriff" or r == "Hero" then return r end
    local ch = plr.Character
    if playerHasTagged(plr, "Weapon_Gun") or (ch and charHasWeapon(ch, "Gun")) then return "Hero" end
    if playerHasTagged(plr, "Weapon_Knife") or (ch and charHasWeapon(ch, "Knife")) then return "Murderer" end
    return r or "Innocent"
end

local function computeAlive(plr)
    local d = roundData(plr); if d and d.Dead == true then return false end
    local ch = plr.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    return ch and hum and hum.Health > 0 and getHRP(ch)
end

local CACHE_TTL = 0.05
local roleCache, aliveCache, cacheStamp = {}, {}, 0
local function sweepCaches()
    local now = os.clock()
    if now - cacheStamp > CACHE_TTL then
        table.clear(roleCache); table.clear(aliveCache); cacheStamp = now
        Mono.refreshTags()
    end
    if now - (Mono.rosterAt or 0) > 2 then
        Mono.rosterAt = now
        Mono.refreshPlrs()
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

function Mono.hasBody(plr)
    local ch = plr.Character
    if not ch then return nil end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not (hum and hum.Health > 0) then return nil end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    return ch, hum, hrp
end

local function myRole() return roleOf(LocalPlayer) end
local function isGunRole(role) return role == "Sheriff" or role == "Hero" end
local function isEnemyOf(myrole, role)
    if myrole == "Murderer" then return true end
    if isGunRole(myrole) then return role == "Murderer" end
    return false
end

function Mono.refreshPlrs()
    local ok, list = pcall(function() return Players:GetPlayers() end)
    if ok and type(list) == "table" then Mono.plrs = list end
end
Mono.refreshPlrs()
bind(Players.PlayerAdded, Mono.refreshPlrs)
bind(Players.PlayerRemoving, function() task.defer(Mono.refreshPlrs) end)

local function findMurderer() for _, p in ipairs(Mono.plrs) do if roleOf(p) == "Murderer" then return p end end end
local function findWeapon(n)
    local ch = LocalPlayer.Character; local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    return (ch and ch:FindFirstChild(n)) or (bp and bp:FindFirstChild(n))
end
local function equip(tool)
    local ch = LocalPlayer.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if tool and hum and tool.Parent ~= ch then pcall(function() hum:EquipTool(tool) end) end
end

function Mono.canAct()
    if Mono.teleporting() then return false end
    local ch = LocalPlayer.Character
    if not ch or not ch.Parent then return false end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not (hum and hum.Health > 0) then return false end
    if not getHRP(ch) then return false end
    if LocalPlayer:GetAttribute("Alive") == false then return false end
    local d = roundData(LocalPlayer)
    if d and d.Dead == true then return false end
    return true
end

function Mono.aimCenter()
    local m = UserInputService:GetMouseLocation()
    return Vector2.new(m.X, m.Y)
end
function Mono.aimViewport() return Mono.aimCenter() end

-- Drawing abstraction (Drawing lib or GUI frames)
do
    local lineMT = {}
    local function apply(t)
        local f = rawget(t, "_f")
        if not (f and f.Parent) then return end
        local a, b = rawget(t, "_From"), rawget(t, "_To")
        if not (a and b) then return end
        local d = b - a
        f.Position = UDim2.fromOffset((a.X + b.X) * 0.5, (a.Y + b.Y) * 0.5)
        f.Size = UDim2.fromOffset(math.max(d.Magnitude, 1), math.max(rawget(t, "_Thickness") or 1, 1))
        f.Rotation = math.deg(math.atan2(d.Y, d.X))
    end
    local function remove(t)
        local f = rawget(t, "_f")
        if f then pcall(function() f:Destroy() end) end
    end
    lineMT.__index = function(t, k)
        if k == "Remove" then return remove end
        return rawget(t, "_" .. k)
    end
    lineMT.__newindex = function(t, k, v)
        rawset(t, "_" .. k, v)
        local f = rawget(t, "_f")
        if not (f and f.Parent) then return end
        if k == "Visible" then f.Visible = (v == true)
        elseif k == "Color" then f.BackgroundColor3 = v
        elseif k == "Transparency" then f.BackgroundTransparency = 1 - (tonumber(v) or 1)
        elseif k == "From" or k == "To" or k == "Thickness" then apply(t) end
    end
    Mono.hasDrawing = (typeof(Drawing) == "table") and (pcall(function()
        local probe = Drawing.new("Line"); probe:Remove()
    end))
    function Mono.trackDraw(o) Mono.drawn[o] = true; return o end
    function Mono.dropDraw(o)
        if o == nil then return end
        Mono.drawn[o] = nil
        pcall(function() o:Remove() end)
    end
    function Mono.clearDrawn()
        for o in pairs(Mono.drawn) do pcall(function() o:Remove() end) end
        table.clear(Mono.drawn)
    end
    function Mono.newLine(thickness)
        if Mono.hasDrawing then
            local l = Drawing.new("Line"); l.Thickness = thickness; l.Transparency = 1; l.Visible = false
            return Mono.trackDraw(l)
        end
        local t = setmetatable({}, lineMT)
        rawset(t, "_f", create("Frame", { Name = rnd(), AnchorPoint = Vector2.new(0.5, 0.5),
            BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), Visible = false, ZIndex = 3, Parent = EspGui }))
        rawset(t, "_Thickness", thickness)
        rawset(t, "_Visible", false)
        return t
    end
end

print("[LightHub] Part 1 loaded")


-- ============================================================
-- LIGHT HUB MM2 - PART 2: COMBAT
-- ============================================================

function Mono.aimPointFor(p)
    local ch = p and p.Character; local hrp = ch and getHRP(ch); if not hrp then return end
    local part = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or hrp
    return part.Position
end

function Mono.aimPoint(ch)
    local part = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("UpperTorso")
        or ch:FindFirstChild("Torso") or ch:FindFirstChild("Head")
    return part and part.Position
end

-- ============================================================
-- KNIFE KILL (murderer melee)
-- ============================================================
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

-- ============================================================
-- GUN SNAP-SHOT (sheriff)
-- ============================================================
local snapping = false
function Mono.gunOrigin()
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local att = hrp:FindFirstChild("GunRaycastAttachment")
    if att then return att.WorldCFrame end
    return hrp.CFrame
end

function Mono.gunBusy(lead)
    local gun = findWeapon("Gun")
    if not gun then return false end
    if os.clock() - Mono.snapAt < Mono.GUN_COOLDOWN - (lead or 0) then return true end
    return false
end

do
    local cs = ReplicatedStorage:FindFirstChild("ClientServices")
    local ws = cs and cs:FindFirstChild("WeaponService")
    local gf = ws and ws:FindFirstChild("GunFired")
    if gf and gf:IsA("RemoteEvent") then
        bind(gf.OnClientEvent, function(handle)
            local ch = LocalPlayer.Character
            if ch and typeof(handle) == "Instance" and handle:IsDescendantOf(ch) then
                local rt = os.clock() - Mono.snapAt
                if rt > 0 and rt < 1.5 then Mono.shotLag = (Mono.shotLag or 0.08) * 0.7 + rt * 0.3 end
                Mono.snapAt = os.clock()
            end
        end)
    end
end

local function snapShot(target)
    if snapping then return false end
    local lagT = math.clamp(Mono.shotLag or 0.08, 0.03, 0.25)
    local preLock = math.clamp(lagT * 1.5, 0.12, 0.35)
    if Mono.gunBusy(preLock) then return false end
    local gun = findWeapon("Gun"); if not gun then return false end
    local shoot = gun:FindFirstChild("Shoot"); if not shoot then return false end
    local myHrp = getHRP(LocalPlayer.Character)
    local tChar = target and target.Character
    local tHrp = tChar and getHRP(tChar)
    if not (myHrp and tHrp and Mono.canAct()) then return false end
    snapping = true

    local home = myHrp.CFrame
    local homeVel = myHrp.AssemblyLinearVelocity
    local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local homeState = myHum and myHum:GetState() or nil
    local fired = false

    pcall(function()
        equip(gun)
        local deadline = os.clock() + 0.4
        while os.clock() < deadline do
            local h = getHRP(LocalPlayer.Character)
            if h and h:FindFirstChild("GunRaycastAttachment") then break end
            RunService.Heartbeat:Wait()
        end

        Mono.markSelfTP()
        local aim = Mono.aimPoint(tChar)
        if not aim then return end
        local side = home.Position - aim
        side = Vector3.new(side.X, 0, side.Z)
        if side.Magnitude < 0.5 then
            local lv = tHrp.CFrame.LookVector
            side = Vector3.new(lv.X, 0, lv.Z)
        end
        if side.Magnitude < 0.5 then side = Vector3.new(0, 0, 1) end
        side = side.Unit
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { tChar, LocalPlayer.Character }
        if workspace:Raycast(aim, side * Mono.SNAP_HEIGHT, rp) then side = -side end
        local relOff = side * Mono.SNAP_HEIGHT

        local chest = aim
        local function lockOn(dur)
            local t0 = os.clock()
            repeat
                local h = getHRP(LocalPlayer.Character)
                local tr = target.Character and getHRP(target.Character)
                if not (h and tr) then return false end
                if Mono.teleporting() then return false end
                local nxt = Mono.aimPoint(target.Character)
                if nxt and (nxt - chest).Magnitude > 60 then return false end
                chest = nxt or chest
                h.CFrame = CFrame.new(chest + relOff, chest)
                h.AssemblyLinearVelocity = Vector3.zero
                h.AssemblyAngularVelocity = Vector3.zero
                Mono.markSelfTP()
                RunService.Heartbeat:Wait()
            until os.clock() - t0 >= dur
            return true
        end

        if not lockOn(preLock) then return end

        local origin = Mono.gunOrigin()
        if origin then
            local tr2 = target.Character and getHRP(target.Character)
            local vel = tr2 and tr2.AssemblyLinearVelocity or Vector3.zero
            shoot:FireServer(origin, CFrame.new(chest + vel * lagT))
            Mono.snapAt = os.clock()
            fired = true
            lockOn(math.clamp(lagT * 2, 0.16, 0.5))
        end
    end)

    RunService.Heartbeat:Wait()
    Mono.markSelfTP()
    local h3 = getHRP(LocalPlayer.Character)
    if h3 then
        h3.CFrame = home
        h3.AssemblyLinearVelocity = homeVel
        h3.AssemblyAngularVelocity = Vector3.zero
    end
    local hum3 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum3 then
        if homeState and homeState ~= Enum.HumanoidStateType.Dead then
            pcall(function() hum3:ChangeState(homeState) end)
        else
            pcall(function() hum3:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
        pcall(function() hum3:Move(hum3.MoveDirection, false) end)
    end
    snapping = false
    return fired
end

local function enemies()
    local role = myRole(); local list = {}
    if isGunRole(role) then
        local m = findMurderer(); if m and alive(m) then table.insert(list, m) end
    else
        for _, p in ipairs(Mono.plrs) do
            if p ~= LocalPlayer and alive(p) then table.insert(list, p) end
        end
    end
    return list, role
end

local function fovTarget()
    local mr = myRole()
    local center = Mono.aimViewport(); local best, bd
    for _, p in ipairs(Mono.plrs) do
        if p ~= LocalPlayer and alive(p) then
            local pr = roleOf(p)
            if isEnemyOf(mr, pr) or pr == "Murderer" then
                local hrp = getHRP(p.Character)
                if hrp then
                    local v, on = Camera:WorldToViewportPoint(hrp.Position)
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

-- ============================================================
-- AUTO KILL LOOP
-- ============================================================
task.spawn(function()
    while not isDead() do
        local okLoop, errLoop = pcall(function()
            if flags.autoKill then
                local list, role = enemies()
                if role == "Murderer" then
                    local knife = findWeapon("Knife"); local ev = knife and knife:FindFirstChild("Events")
                    if ev then
                        equip(knife)
                        for _, tgt in ipairs(list) do
                            if not flags.autoKill then break end
                            knifeKill(ev, tgt.Character)
                        end
                    end
                    task.wait(0.05)
                elseif isGunRole(role) then
                    local m = list[1]
                    if m and alive(m) then snapShot(m) end
                    task.wait(0.05)
                else
                    task.wait(0.1)
                end
            else
                task.wait(0.08)
            end
        end)
        if not okLoop then warn("[LightHub] auto kill: " .. tostring(errLoop)); task.wait(0.25) end
    end
end)

-- ============================================================
-- SILENT AIM
-- ============================================================
local silentAimPos
local function crosshairAnyPlayerPos(radius)
    local center = Mono.aimViewport()
    local best, bd
    for _, p in ipairs(Mono.plrs) do
        if p ~= LocalPlayer and alive(p) then
            local ch = p.Character; local hrp = getHRP(ch)
            if hrp then
                local sp = Camera:WorldToViewportPoint(hrp.Position)
                if sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= radius and (not bd or d < bd) then bd, best = d, p end
                end
            end
        end
    end
    return best and Mono.aimPointFor(best) or nil
end

function Mono.crosshairPlayer(radius)
    local center = Mono.aimViewport()
    local best, bd
    for _, p in ipairs(Mono.plrs) do
        if p ~= LocalPlayer and alive(p) then
            local hrp = getHRP(p.Character)
            if hrp then
                local sp = Camera:WorldToViewportPoint(hrp.Position)
                if sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= radius and (not bd or d < bd) then bd, best = d, p end
                end
            end
        end
    end
    return best
end

local function computeSilentTarget()
    if myRole() ~= "Murderer" then Mono.silentPlr = nil return nil end
    local p = Mono.crosshairPlayer(aimFov)
    if p then
        Mono.silentPlr = p
        Mono.silentAt = os.clock()
        return Mono.aimPointFor(p)
    end
    local last = Mono.silentPlr
    if last and os.clock() - (Mono.silentAt or -10) < Mono.SILENT_HOLD and alive(last) then
        local held = Mono.aimPointFor(last)
        if held then return held end
    end
    Mono.silentPlr = nil
    return nil
end

local function aimRay()
    local c = Mono.aimCenter()
    return Camera:ViewportPointToRay(c.X, c.Y)
end

local function wallAimPos()
    local ray = aimRay()
    local origin, dir = ray.Origin, ray.Direction.Unit
    local far = origin + dir * 300
    local chars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and alive(p) and p.Character then chars[#chars + 1] = p.Character end
    end
    if #chars == 0 then return nil, far end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = chars
    local hit = workspace:Raycast(origin, dir * 300, params)
    if hit then return hit.Position, far end
    return crosshairAnyPlayerPos(aimFov), far
end

local wallSnapPos, wallFarPos, myHrpPos
bind(RunService.Heartbeat, function()
    silentAimPos = flags.silentAim and computeSilentTarget() or nil
    if flags.knifeWalls or flags.gunWalls then
        wallSnapPos, wallFarPos = wallAimPos()
    else
        wallSnapPos, wallFarPos = nil, nil
    end
    local h = getHRP(LocalPlayer.Character); myHrpPos = h and h.Position or nil
end)

-- __namecall hook (primary silent aim / walls method)
local instantFiredAt = -10
Mono.hookOk = pcall(function()
    if typeof(hookmetamethod) ~= "function" or typeof(newcclosure) ~= "function"
        or typeof(checkcaller) ~= "function" or typeof(getnamecallmethod) ~= "function" then
        error("executor has no __namecall hooking")
    end
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if not Unloaded and not checkcaller() and getnamecallmethod() == "FireServer" then
            local nm = self.Name
            if nm == "Shoot" or nm == "KnifeThrown" then
                if nm == "Shoot" and flags.silentAim and not snapping and not Mono.gunBusy()
                    and os.clock() - Mono.snapAt >= Mono.SNAP_COOLDOWN and isGunRole(myRole()) then
                    local ft = fovTarget()
                    if ft then
                        task.spawn(function() snapShot(ft) end)
                        return
                    end
                end
                local walls = (nm == "Shoot" and flags.gunWalls) or (nm == "KnifeThrown" and flags.knifeWalls)
                if nm == "KnifeThrown" and flags.instantKnife and os.clock() - instantFiredAt < 0.6 then
                    return
                end
                local silent = flags.silentAim and silentAimPos
                local wallTarget
                if walls then
                    if nm == "Shoot" then wallTarget = wallSnapPos
                    else wallTarget = wallSnapPos or wallFarPos end
                end
                local retarget = (silent and silentAimPos) or wallTarget or nil
                if retarget then
                    local n = select("#", ...)
                    if n >= 2 then
                        local a = { ... }
                        if typeof(a[2]) == "CFrame" then
                            a[2] = CFrame.new(retarget)
                            if walls and retarget and myHrpPos and typeof(a[1]) == "CFrame" then
                                local tp = a[2].Position
                                local d = tp - myHrpPos
                                d = (d.Magnitude > 0.1) and d.Unit or Vector3.new(0, 0, -1)
                                a[1] = CFrame.new(tp - d * Mono.WALL_BACKOFF, tp)
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

-- Fallback direct-fire when hooking unavailable
local WeaponService
pcall(function() WeaponService = require(ReplicatedStorage:WaitForChild("ClientServices"):WaitForChild("WeaponService")) end)
local function gameAimCFrame()
    if WeaponService then
        local ok, cf = pcall(function() return WeaponService:GetMouseTargetCFrame() end)
        if ok and typeof(cf) == "CFrame" then return cf end
    end
    local ray = aimRay()
    return CFrame.new(ray.Origin + ray.Direction.Unit * 300)
end

if not Mono.hookOk then
    bind(UserInputService.InputBegan, function(input, processed)
        if processed or isDead() then return end
        local it = input.UserInputType
        if it ~= Enum.UserInputType.MouseButton1 and it ~= Enum.UserInputType.Touch then return end
        if not (flags.gunWalls or flags.knifeWalls or flags.silentAim) then return end
        task.spawn(function()
            local ch = LocalPlayer.Character
            if not (ch and Mono.canAct()) then return end
            local mine = getHRP(ch); if not mine then return end
            local gun = ch:FindFirstChild("Gun")
            if gun and gun:FindFirstChild("Shoot") then
                if Mono.gunBusy() then return end
                if flags.silentAim and isGunRole(myRole()) then
                    local ft = fovTarget()
                    if ft then snapShot(ft) return end
                end
                if flags.gunWalls then
                    local snap = wallAimPos()
                    if snap then
                        local d = snap - mine.Position
                        d = (d.Magnitude > 0.1) and d.Unit or Vector3.new(0, 0, -1)
                        pcall(function() gun.Shoot:FireServer(CFrame.new(snap - d * 2, snap), CFrame.new(snap)) end)
                    end
                end
                return
            end
            local knife = ch:FindFirstChild("Knife")
            local ev = knife and knife:FindFirstChild("Events")
            local thrown = ev and ev:FindFirstChild("KnifeThrown")
            if thrown and (flags.knifeWalls or flags.silentAim) then
                local snap = (flags.silentAim and crosshairAnyPlayerPos(aimFov)) or wallAimPos()
                if snap then
                    local d = snap - mine.Position
                    d = (d.Magnitude > 0.1) and d.Unit or Vector3.new(0, 0, -1)
                    local h2 = knife:FindFirstChild("Handle")
                    local o2
                    if flags.knifeWalls or not h2 then
                        o2 = CFrame.new(snap - d * Mono.WALL_BACKOFF, snap)
                    else
                        o2 = h2.CFrame
                    end
                    pcall(function() thrown:FireServer(o2, CFrame.new(snap)) end)
                end
            end
        end)
    end)
end

-- ============================================================
-- INSTANT KNIFE THROW
-- ============================================================
local function throwKnifeNow(ignoreCooldown)
    local ch = LocalPlayer.Character
    if not ch then return false end
    local knife = ch:FindFirstChild("Knife")
    if not knife then
        local bp = LocalPlayer:FindFirstChild("Backpack")
        local stowed = bp and bp:FindFirstChild("Knife")
        if stowed then
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:EquipTool(stowed) end) end
            knife = ch:FindFirstChild("Knife") or stowed
        end
    end
    if not knife then return false end
    local ev = knife:FindFirstChild("Events")
    local thrown = ev and ev:FindFirstChild("KnifeThrown")
    if not thrown then return false end
    if knife:GetAttribute("Disabled") == true then return false end
    if not ignoreCooldown then
        local cd = 2 * (tonumber(knife:GetAttribute("ThrowSpeed")) or 1)
        if os.clock() - instantFiredAt < cd then return false end
    end
    local target = silentAimPos
    if not target then
        if flags.knifeWalls then
            local snap, far = wallAimPos()
            target = snap or far
        else
            target = gameAimCFrame().Position
        end
    end
    if not target then return false end
    local hrp = getHRP(ch); if not hrp then return false end
    local d = target - hrp.Position
    d = (d.Magnitude > 0.1) and d.Unit or Vector3.new(0, 0, -1)
    instantFiredAt = os.clock()
    local handle = knife:FindFirstChild("Handle")
    local origin
    if flags.knifeWalls or not handle then
        origin = CFrame.new(target - d * Mono.WALL_BACKOFF, target)
    else
        origin = handle.CFrame
    end
    thrown:FireServer(origin, CFrame.new(target))
    return true
end

bind(UserInputService.InputBegan, function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
    if flags.instantKnife then throwKnifeNow(false) end
end)

task.spawn(function()
    local ok, act = pcall(function()
        local ic = LocalPlayer:WaitForChild("PlayerGui", 10):WaitForChild("InputContext", 10)
        return ic:WaitForChild("GameplayContext", 10):WaitForChild("Throw", 10)
    end)
    if ok and act then
        pcall(function()
            bind(act.Pressed, function()
                if flags.instantKnife then throwKnifeNow(false) end
            end)
        end)
    end
end)

-- ============================================================
-- AIMBOT (camera)
-- ============================================================
local FovCircle = create("Frame", { Name = rnd(), AnchorPoint = Vector2.new(.5, .5),
    Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(240, 240),
    BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Parent = EspGui },
    { create("UICorner", { CornerRadius = UDim.new(1, 0) }),
      create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1.5, Transparency = 0.25 }) })

bind(RunService.RenderStepped, function()
    if flags.showFov and (flags.aimbot or flags.silentAim) then
        FovCircle.Visible = true
        FovCircle.Size = UDim2.fromOffset(aimFov * 2, aimFov * 2)
        local mp = Mono.aimCenter()
        FovCircle.Position = UDim2.fromOffset(mp.X, mp.Y)
    else
        FovCircle.Visible = false
    end
    if flags.aimbot then
        local t = fovTarget()
        if t then
            local th = t.Character:FindFirstChild("Head") or getHRP(t.Character)
            if th then Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, th.Position), 0.45) end
        end
    end
end)

-- ============================================================
-- DROPPED GUN ESP + AUTO GRAB
-- ============================================================
local droppedGun
local gunEspHL, gunEspBB
task.spawn(function()
    while not isDead() do
        if not flags.gunEsp then
            if gunEspHL then gunEspHL.Enabled = false end
            if gunEspBB then gunEspBB.Enabled = false end
            task.wait(0.5)
        else
        local h = droppedGun
        if h and h.Parent then
            if not gunEspHL then
                gunEspHL = create("Highlight", { Name = rnd(), FillColor = Color3.fromRGB(90, 150, 255),
                    FillTransparency = 0.35, OutlineColor = Color3.fromRGB(170, 210, 255),
                    OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Parent = EspGui })
            end
            if not gunEspBB then
                gunEspBB = create("BillboardGui", { Name = rnd(), Size = UDim2.fromOffset(160, 18),
                    AlwaysOnTop = true, StudsOffsetWorldSpace = Vector3.new(0, 2, 0), Parent = EspGui },
                    { create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
                        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(140, 190, 255),
                        TextStrokeTransparency = .4, Text = "GUN" }) })
            end
            gunEspHL.Adornee = h; gunEspHL.Enabled = true
            gunEspBB.Adornee = h; gunEspBB.Enabled = flags.gunEspDist
            if flags.gunEspDist then
                local hrp = getHRP(LocalPlayer.Character)
                local dist = hrp and math.floor((h.Position - hrp.Position).Magnitude) or 0
                local lbl = gunEspBB:FindFirstChildOfClass("TextLabel")
                if lbl then lbl.Text = "DROPPED GUN  ·  " .. dist .. "m" end
            end
        else
            if gunEspHL then gunEspHL.Enabled = false end
            if gunEspBB then gunEspBB.Enabled = false end
        end
        end
        task.wait(0.1)
    end
end)

local grabbing = false
local function touchGun(h)
    local hrp = getHRP(LocalPlayer.Character)
    if not (hrp and h and h.Parent) then return false end
    if typeof(firetouchinterest) == "function" then
        pcall(function()
            for _ = 1, 4 do
                firetouchinterest(hrp, h, 0)
                firetouchinterest(hrp, h, 1)
            end
        end)
    end
    return findWeapon("Gun") ~= nil
end

local function grabGunOnce(target)
    if grabbing then return false end
    local h = target or droppedGun or findDroppedGun()
    local hrp = getHRP(LocalPlayer.Character)
    if not (h and h.Parent and hrp and Mono.canAct()) then return false end
    grabbing = true
    if touchGun(h) then
        notify("Gun System", "Grabbed the Sheriff gun!", "Success")
        grabbing = false
        return true
    end
    local back = hrp.CFrame
    for _ = 1, 10 do
        local myhrp = getHRP(LocalPlayer.Character)
        if not (myhrp and h.Parent) then break end
        if not Mono.canAct() then break end
        Mono.markSelfTP()
        myhrp.CFrame = CFrame.new(h.Position); myhrp.AssemblyLinearVelocity = Vector3.zero
        if touchGun(h) then break end
        RunService.Heartbeat:Wait()
    end
    local myhrp = getHRP(LocalPlayer.Character)
    if myhrp then myhrp.CFrame = back; myhrp.AssemblyLinearVelocity = Vector3.zero end
    local got = findWeapon("Gun") ~= nil
    if got then notify("Gun System", "Grabbed the Sheriff gun!", "Success") end
    grabbing = false
    return got
end

local function findDroppedGun()
    for _, p in ipairs(CollectionService:GetTagged("GunDrop")) do
        if p:IsA("BasePart") and p:IsDescendantOf(workspace) then return p end
    end
    local map = CollectionService:GetTagged("CurrentMap")[1]
    if map then
        local g = map:FindFirstChild("GunDrop")
        if g and g:IsA("BasePart") then return g end
    end
    for _, d in ipairs(workspace:GetChildren()) do
        if d:IsA("BasePart") and d.Name == "GunDrop" then return d end
        if d:IsA("Model") then
            local g = d:FindFirstChild("GunDrop")
            if g and g:IsA("BasePart") then return g end
        end
    end
end

local function onGunAppeared(inst)
    if not (inst and inst:IsA("BasePart") and inst:IsDescendantOf(workspace)) then return end
    droppedGun = inst
    if flags.autoGun and not grabbing and myRole() ~= "Murderer" and not findWeapon("Gun") and Mono.canAct() then
        task.spawn(grabGunOnce, inst)
    end
end
pcall(function()
    bind(CollectionService:GetInstanceAddedSignal("GunDrop"), onGunAppeared)
    bind(CollectionService:GetInstanceRemovedSignal("GunDrop"), function(i)
        if droppedGun == i then droppedGun = nil end
    end)
end)
bind(workspace.DescendantAdded, function(d)
    if d.Name == "GunDrop" then task.defer(onGunAppeared, d) end
end)
task.spawn(function()
    while not isDead() do
        if flags.gunEsp or flags.autoGun then
            local g = findDroppedGun()
            droppedGun = g
            if g and flags.autoGun and not grabbing and myRole() ~= "Murderer" and not findWeapon("Gun") and Mono.canAct() then
                grabGunOnce(g)
            end
        elseif droppedGun then
            droppedGun = nil
        end
        task.wait((flags.gunEsp or flags.autoGun) and 0.1 or 0.6)
    end
end)

-- Grab Gun & Shoot Murderer (one-off, WindUI port)
local function grabGunAndShoot()
    if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun")) then
        if not grabGunOnce() then
            notify("Gun System", "No gun available!", "Error")
            return
        end
        task.wait(0.1)
    end
    equip(findWeapon("Gun"))
    local m = findMurderer()
    if not (m and m.Character) then
        notify("Gun System", "Murderer not found!", "Error")
        return
    end
    local targetRoot = getHRP(m.Character)
    local localRoot = getHRP(LocalPlayer.Character)
    if targetRoot and localRoot then
        Mono.markSelfTP()
        localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -4)
        task.wait(0.1)
    end
    local gun = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun")
    if gun then
        local ok = snapShot(m)
        notify("Gun System", ok and "Shot fired at murderer!" or "Shot failed", ok and "Success" or "Warning")
    end
end

print("[LightHub] Part 2 loaded")


-- ============================================================
-- LIGHT HUB MM2 - PART 3: ESP + VISUALS
-- ============================================================

-- ============================================================
-- NAMETAG / CHAMS ESP
-- ============================================================
local espStore = {}
Mono.nameHidden = setmetatable({}, { __mode = "k" })

function Mono.setRobloxNames(hide)
    for _, p in ipairs(Mono.plrs) do
        if p ~= LocalPlayer then
            local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if hide then
                    if Mono.nameHidden[hum] == nil then
                        Mono.nameHidden[hum] = { hum.DisplayDistanceType, hum.HealthDisplayDistance, hum.NameDisplayDistance }
                    end
                    if hum.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None then
                        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                    end
                else
                    local o = Mono.nameHidden[hum]
                    if o then
                        pcall(function()
                            hum.DisplayDistanceType = o[1]
                            hum.HealthDisplayDistance = o[2]
                            hum.NameDisplayDistance = o[3]
                        end)
                        Mono.nameHidden[hum] = nil
                    end
                end
            end
        end
    end
end

local function clearEsp(plr)
    local e = espStore[plr]; if not e then return end
    if e.hl then e.hl:Destroy() end
    if e.bb then e.bb:Destroy() end
    espStore[plr] = nil
end

function Mono.espRole(plr)
    local d = roundData(plr)
    if d and d.Dead == true then return "Innocent" end
    return roleOf(plr)
end

local function espColor(role)
    if not flags.espRoleTags then return Color3.fromRGB(214, 214, 220) end
    if role == "Murderer" then return Color3.fromRGB(255, 80, 80)
    elseif isGunRole(role) then return Color3.fromRGB(90, 150, 255)
    else return Color3.fromRGB(95, 225, 125) end
end

local function tagOf(role) return role == "Murderer" and "[M]" or isGunRole(role) and "[S]" or "[I]" end

local guiRects = {}
function Mono.addRect(o)
    if not (o and o.Visible and o.AbsoluteSize.X > 1 and o.AbsoluteSize.Y > 1) then return end
    if o:IsA("Frame") and o.BackgroundTransparency >= 1 then
        for _, c in ipairs(o:GetChildren()) do
            if c:IsA("GuiObject") then Mono.addRect(c) end
        end
        return
    end
    local p, s = o.AbsolutePosition, o.AbsoluteSize
    local oy = p.Y + Mono.guiIns
    Mono.guiN = Mono.guiN + 1
    local r = guiRects[Mono.guiN]
    if r then r[1], r[2], r[3], r[4] = p.X, oy, p.X + s.X, oy + s.Y
    else guiRects[Mono.guiN] = { p.X, oy, p.X + s.X, oy + s.Y } end
end

local function refreshGuiRects(force)
    local now = os.clock()
    if not force and now - Mono.guiT < 0.1 then return end
    Mono.guiT = now
    Mono.guiIns = GuiService:GetGuiInset().Y
    Mono.guiN = 0
    local w = _G.LightHubWindow
    local sg = w and w._gui
    if sg then
        for _, c in ipairs(sg:GetChildren()) do
            if c:IsA("GuiObject") then Mono.addRect(c) end
        end
    end
end

local function pointBlocked(x, y)
    for i = 1, Mono.guiN do
        local r = guiRects[i]
        if x >= r[1] and x <= r[3] and y >= r[2] and y <= r[4] then return true end
    end
    return false
end

local function rectBlocked(x1, y1, x2, y2)
    for i = 1, Mono.guiN do
        local r = guiRects[i]
        if x1 <= r[3] and x2 >= r[1] and y1 <= r[4] and y2 >= r[2] then return true end
    end
    return false
end

local function ensureEsp(plr)
    if espStore[plr] then return espStore[plr] end
    local e = {}
    e.hl = create("Highlight", { Name = rnd(), FillTransparency = 1, OutlineTransparency = 0,
        Enabled = false, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Parent = EspGui })
    e.bb = create("BillboardGui", { Name = rnd(), Size = UDim2.fromOffset(198, 40), AlwaysOnTop = true,
        Enabled = false, StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0), Parent = EspGui })
    e.scale = create("UIScale", { Scale = 1, Parent = e.bb })
    e.card = create("Frame", { Name = rnd(), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1),
        Size = UDim2.fromOffset(198, 32), BackgroundColor3 = Color3.fromRGB(16, 16, 18),
        BackgroundTransparency = 0.2, BorderSizePixel = 0, Parent = e.bb },
        { create("UICorner", { CornerRadius = UDim.new(0, 10) }),
          create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({
              NumberSequenceKeypoint.new(0, 0.04), NumberSequenceKeypoint.new(1, 0.28) }) }) })
    e.edge = create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1,
        Transparency = 0.75, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = e.card })
    e.avatar = create("ImageLabel", { Name = rnd(), AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = Color3.fromRGB(38, 38, 44), BackgroundTransparency = 0.25,
        ScaleType = Enum.ScaleType.Fit, Image = "", Parent = e.card },
        { create("UICorner", { CornerRadius = UDim.new(0, 6) }) })
    e.name = create("TextLabel", { Name = rnd(), BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 36, 0.5, 0), Size = UDim2.new(1, -116, 0, 15),
        Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        Text = "", TextColor3 = Color3.fromRGB(255, 255, 255), Parent = e.card })
    e.sub = create("TextLabel", { Name = rnd(), BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(74, 14),
        Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right,
        Text = "", TextColor3 = Color3.fromRGB(176, 176, 188), Parent = e.card })
    espStore[plr] = e
    return e
end

task.spawn(function()
    while not isDead() do
        local anyEsp = flags.espChams or flags.espNames or flags.espRoleTags
        if not anyEsp then
            if next(espStore) then for p in pairs(espStore) do clearEsp(p) end end
            task.wait(0.5)
        else
        if Mono._rnFlag ~= flags.espNames or os.clock() - (Mono._rnAt or 0) > 0.5 then
            Mono._rnFlag = flags.espNames
            Mono._rnAt = os.clock()
            Mono.setRobloxNames(flags.espNames)
        end
        local camP = Camera.CFrame.Position
        for _, plr in ipairs(Mono.plrs) do
            if plr ~= LocalPlayer then
                local ch, _, tHRP = Mono.hasBody(plr)
                if anyEsp and ch then
                    local e = ensureEsp(plr); local role = Mono.espRole(plr); local col = espColor(role)
                    local wantCh = flags.espChams and true or false
                    if e._ch ~= wantCh then e._ch = wantCh; e.hl.Enabled = wantCh end
                    if wantCh then
                        if e.hl.Adornee ~= ch then e.hl.Adornee = ch end
                        local ft = flags.espFill and 0.6 or 1
                        if e._hlCol ~= col then e._hlCol = col; e.hl.OutlineColor = col; e.hl.FillColor = col end
                        if e._hlFill ~= ft then e._hlFill = ft; e.hl.FillTransparency = ft end
                    end
                    local dist = math.floor((tHRP.Position - camP).Magnitude)
                    local inRange = (flags.espMaxDist <= 0 or dist <= flags.espMaxDist)
                    e.dist = dist; e.inRange = inRange; e.col = col
                    if flags.espNames and inRange then
                        e.bb.Enabled = true; e.bb.Adornee = ch:FindFirstChild("Head") or tHRP
                        local nm = plr.Name
                        if flags.espRoleTags then nm = tagOf(role) .. "  " .. nm end
                        if e._nm ~= nm then e._nm = nm; e.name.Text = nm; e._nw = nil end
                        local rd = roundData(plr); local coins = rd and rd.Coins
                        local sub = dist .. "m"
                        if coins then sub = coins .. "c  ·  " .. sub end
                        if e._sub ~= sub then e._sub = sub; e.sub.Text = sub end
                        if e._col ~= col then e._col = col; e.name.TextColor3 = col; e.edge.Color = col end
                        local near, far = 18, 220
                        local t = math.clamp((dist - near) / (far - near), 0, 1)
                        local dim = t * 0.55
                        if e._dim ~= dim then
                            e._dim = dim
                            e.scale.Scale = 1 - (t * 0.45)
                            e.card.BackgroundTransparency = 0.2 + dim * 0.5
                            e.edge.Transparency = 0.75 + dim * 0.2
                            e.name.TextTransparency = dim
                            e.sub.TextTransparency = math.min(1, dim * 1.25)
                            e.avatar.ImageTransparency = dim
                        end
                        local wantAv = flags.espAvatar and true or false
                        if e._av ~= wantAv then
                            e._av = wantAv
                            e.avatar.Visible = wantAv
                            e.name.Position = UDim2.new(0, wantAv and 36 or 12, 0.5, 0)
                            e._nw = nil
                        end
                        if e._nw ~= (nm .. sub .. tostring(wantAv)) then
                            e._nw = nm .. sub .. tostring(wantAv)
                            local okN, nz = pcall(function()
                                return Mono.TextService:GetTextSize(nm, e.name.TextSize, e.name.Font, Vector2.new(4000, 40))
                            end)
                            local okS, sz2 = pcall(function()
                                return Mono.TextService:GetTextSize(sub, e.sub.TextSize, e.sub.Font, Vector2.new(4000, 40))
                            end)
                            local nw = okN and nz.X or (#nm * 8)
                            local sw = okS and sz2.X or (#sub * 6)
                            local left = wantAv and 36 or 12
                            local w = math.clamp(math.ceil(left + nw + 14 + sw + 10), 150, 520)
                            e.name.Size = UDim2.fromOffset(math.ceil(nw) + 2, 15)
                            e.sub.Size = UDim2.fromOffset(math.ceil(sw) + 2, 14)
                            e.card.Size = UDim2.fromOffset(w, 32)
                            e.bb.Size = UDim2.fromOffset(w, 40)
                        end
                        if flags.espAvatar and e.avatar.Image == "" and os.clock() - (e._avAt or -99) > 4 then
                            local uid = plr.UserId
                            e._avAt = os.clock()
                            task.spawn(function()
                                local ok, url = pcall(function()
                                    return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                                end)
                                if ok and url and e.avatar and e.avatar.Parent then e.avatar.Image = url end
                            end)
                        end
                    else
                        e.bb.Enabled = false
                    end
                else
                    clearEsp(plr)
                end
            end
        end
        task.wait(0.05)
        end
    end
end)

-- ============================================================
-- BOX / 3D BOX / TRACER / SKELETON ESP
-- ============================================================
local boxStore = {}
local function clearBox(plr)
    local b = boxStore[plr]
    if b then for _, l in ipairs(b) do Mono.dropDraw(l) end; boxStore[plr] = nil end
end
local function ensureBox(plr)
    local b = boxStore[plr]
    if b then return b end
    b = {}
    for i = 1, 4 do b[i] = Mono.newLine(1) end
    boxStore[plr] = b
    return b
end

local tracerStore = {}
local function clearTracer(plr)
    local t = tracerStore[plr]
    if t then Mono.dropDraw(t); tracerStore[plr] = nil end
end
local function ensureTracer(plr)
    local t = tracerStore[plr]
    if t then return t end
    t = Mono.newLine(2)
    tracerStore[plr] = t
    return t
end

local function tracerOrigin()
    local vp = Camera.ViewportSize
    local from = flags.espTracerFrom
    if from == "Top" then return Vector2.new(vp.X * 0.5, 0)
    elseif from == "Center" then return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    elseif from == "Bottom Left" then return Vector2.new(0, vp.Y)
    elseif from == "Bottom Right" then return Vector2.new(vp.X, vp.Y)
    elseif from == "Mouse" then
        local m = UserInputService:GetMouseLocation()
        return Vector2.new(m.X, m.Y)
    end
    return Vector2.new(vp.X * 0.5, vp.Y)
end

local CORNERS = {
    Vector3.new(-1, -1, -1), Vector3.new(-1, -1, 1), Vector3.new(-1, 1, -1), Vector3.new(-1, 1, 1),
    Vector3.new(1, -1, -1), Vector3.new(1, -1, 1), Vector3.new(1, 1, -1), Vector3.new(1, 1, 1),
}
Mono.boundsCache = setmetatable({}, { __mode = "k" })
Mono.bodyCache = setmetatable({}, { __mode = "k" })

function Mono.bodyParts(ch)
    local e = Mono.bodyCache[ch]
    if e then
        if not e.dirty then return e.list end
    else
        e = { dirty = true, list = {} }
        Mono.bodyCache[ch] = e
        local function soil() e.dirty = true end
        ch.ChildAdded:Connect(soil)
        ch.ChildRemoved:Connect(soil)
    end
    local l = e.list
    table.clear(l)
    for _, d in ipairs(ch:GetChildren()) do
        if d:IsA("BasePart") then l[#l + 1] = d end
    end
    e.dirty = false
    return l
end

local function charBounds(ch)
    local hrp = getHRP(ch); if not hrp then return nil end
    local base = hrp.CFrame
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    local found = false
    local body = Mono.bodyParts(ch)
    for i = 1, #body do
        local d = body[i]
        if d.Parent then
            local rel = base:PointToObjectSpace(d.Position)
            local h = d.Size * 0.5
            local r = math.max(h.X, h.Y, h.Z)
            if rel.X - h.X < minX then minX = rel.X - h.X end
            if rel.X + h.X > maxX then maxX = rel.X + h.X end
            if rel.Y - h.Y < minY then minY = rel.Y - h.Y end
            if rel.Y + h.Y > maxY then maxY = rel.Y + h.Y end
            if rel.Z - r < minZ then minZ = rel.Z - r end
            if rel.Z + r > maxZ then maxZ = rel.Z + r end
            found = true
        end
    end
    if not found then return base, Vector3.new(4, 6, 2) end
    local size = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
    local off = Vector3.new((minX + maxX) * 0.5, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5)
    local prev = Mono.boundsCache[ch]
    if prev then
        local a = 0.25
        size = prev.size:Lerp(size, a)
        off = prev.off:Lerp(off, a)
        prev.size, prev.off = size, off
    else
        Mono.boundsCache[ch] = { size = size, off = off }
    end
    return base * CFrame.new(off), size
end

local box3Store = {}
local function clearBox3(plr)
    local b = box3Store[plr]
    if b then for _, l in ipairs(b) do Mono.dropDraw(l) end; box3Store[plr] = nil end
end
local function ensureBox3(plr)
    local b = box3Store[plr]
    if b then return b end
    b = {}
    for i = 1, 12 do b[i] = Mono.newLine(1) end
    box3Store[plr] = b
    return b
end
local BOX3_EDGES = {
    {1,2},{1,3},{1,5},{2,4},{2,6},{3,4},{3,7},{4,8},{5,6},{5,7},{6,8},{7,8},
}

local R15Bones = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local R6Bones = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
local skelStore = {}
local function clearSkel(plr)
    local s = skelStore[plr]
    if not s then return end
    for _, l in ipairs(s.lines) do Mono.dropDraw(l) end
    skelStore[plr] = nil
end
local function ensureSkel(plr, ch)
    local bones = ch:FindFirstChild("UpperTorso") and R15Bones or R6Bones
    local s = skelStore[plr]
    if s and s.bones == bones and s.char == ch then return s end
    if s then clearSkel(plr) end
    s = { bones = bones, lines = {}, char = ch, uniq = {}, pair = {}, vx = {}, vy = {}, vok = {} }
    local idx = {}
    for i = 1, #bones do
        s.lines[i] = Mono.newLine(2)
        local ja, jb
        for k = 1, 2 do
            local p = ch:FindFirstChild(bones[i][k])
            local j
            if p then
                j = idx[p]
                if not j then s.uniq[#s.uniq + 1] = p; j = #s.uniq; idx[p] = j end
            end
            if k == 1 then ja = j else jb = j end
        end
        s.pair[i] = { ja, jb }
    end
    skelStore[plr] = s
    return s
end

bind(RunService.RenderStepped, function()
    local doBox, doSkel, doTracer, doBox3 = flags.espBox, flags.espSkeleton, flags.espTracers, flags.espBox3D
    if not doBox and next(boxStore) then for p in pairs(boxStore) do clearBox(p) end end
    if not doSkel and next(skelStore) then for p in pairs(skelStore) do clearSkel(p) end end
    if not doTracer and next(tracerStore) then for p in pairs(tracerStore) do clearTracer(p) end end
    if not doBox3 and next(box3Store) then for p in pairs(box3Store) do clearBox3(p) end end
    if not (doBox or doSkel or doTracer or doBox3) then return end
    refreshGuiRects()
    local needCorners = doBox or doBox3
    local camCF = Camera.CFrame
    local camPos, camLook = camCF.Position, camCF.LookVector
    local tOrigin = doTracer and tracerOrigin() or nil
    for _, plr in ipairs(Mono.plrs) do
        if plr ~= LocalPlayer then
            local ch, _, cullRoot = Mono.hasBody(plr)
            if ch then
                if cullRoot and (cullRoot.Position - camPos):Dot(camLook) <= 0 then
                    local hb = boxStore[plr]
                    if hb then for i = 1, #hb do hb[i].Visible = false end end
                    local h3 = box3Store[plr]
                    if h3 then for i = 1, #h3 do h3[i].Visible = false end end
                    local ht = tracerStore[plr]
                    if ht then ht.Visible = false end
                    local hs = skelStore[plr]
                    if hs then for i = 1, #hs.lines do local l = hs.lines[i]; if l then l.Visible = false end end end
                else
                local col = espColor(Mono.espRole(plr))
                local pts, okPts
                local bx1, by1, bx2, by2
                local allAhead = false
                if needCorners then
                    local cf, size = charBounds(ch)
                    if cf then
                        pts, okPts = {}, true
                        bx1, by1, bx2, by2 = math.huge, math.huge, -math.huge, -math.huge
                        local half = size * 0.5
                        local hx, hy, hz = half.X, half.Y, half.Z
                        local ahead = 0
                        for i = 1, 8 do
                            local c = CORNERS[i]
                            local v = Camera:WorldToViewportPoint(cf:PointToWorldSpace(Vector3.new(c.X * hx, c.Y * hy, c.Z * hz)))
                            pts[i] = Vector2.new(v.X, v.Y)
                            if v.Z > 0 then
                                ahead = ahead + 1
                                if v.X < bx1 then bx1 = v.X end
                                if v.X > bx2 then bx2 = v.X end
                                if v.Y < by1 then by1 = v.Y end
                                if v.Y > by2 then by2 = v.Y end
                            end
                        end
                        allAhead = (ahead == 8)
                        if ahead < 4 then okPts = false end
                        if okPts and ((bx2 - bx1) < 1 or (by2 - by1) < 1) then okPts = false end
                    else
                        okPts = false
                    end
                end
                local blocked = okPts and rectBlocked(bx1, by1, bx2, by2) or false

                if doBox then
                    local b = ensureBox(plr)
                    if okPts and not blocked then
                        local tl, tr = Vector2.new(bx1, by1), Vector2.new(bx2, by1)
                        local bl, br = Vector2.new(bx1, by2), Vector2.new(bx2, by2)
                        local segs = { {tl, tr}, {tr, br}, {br, bl}, {bl, tl} }
                        for i = 1, 4 do
                            local seg, l = segs[i], b[i]
                            l.From, l.To, l.Color, l.Visible = seg[1], seg[2], col, true
                        end
                    else
                        for _, l in ipairs(b) do l.Visible = false end
                    end
                end
                if doBox3 then
                    local b = ensureBox3(plr)
                    if okPts and allAhead and not blocked then
                        for i = 1, 12 do
                            local e2 = BOX3_EDGES[i]
                            local l = b[i]
                            l.From, l.To, l.Color, l.Visible = pts[e2[1]], pts[e2[2]], col, true
                        end
                    else
                        for _, l in ipairs(b) do l.Visible = false end
                    end
                end
                if doTracer then
                    local t = ensureTracer(plr)
                    local tx, ty
                    local thrp = cullRoot
                    local far = false
                    if thrp and flags.espMaxDist > 0 then
                        far = (thrp.Position - camPos).Magnitude > flags.espMaxDist
                    end
                    if not far then
                        if okPts then
                            tx, ty = (bx1 + bx2) * 0.5, by2
                        elseif thrp then
                            local v = Camera:WorldToViewportPoint(thrp.Position - Vector3.new(0, 3, 0))
                            if v.Z > 0 then tx, ty = v.X, v.Y end
                        end
                    end
                    if tx and not pointBlocked(tx, ty) then
                        t.From = tOrigin; t.To = Vector2.new(tx, ty); t.Color = col; t.Visible = true
                    else
                        t.Visible = false
                    end
                end
                if doSkel then
                    local s = ensureSkel(plr, ch)
                    local rootHrp = cullRoot
                    local vis = false
                    if rootHrp then
                        local rv = Camera:WorldToViewportPoint(rootHrp.Position)
                        local vp = Camera.ViewportSize
                        vis = rv.Z > 0 and rv.X > -250 and rv.X < vp.X + 250 and rv.Y > -250 and rv.Y < vp.Y + 250
                    end
                    if not vis then
                        for i = 1, #s.lines do local l = s.lines[i]; if l then l.Visible = false end end
                    else
                        local uq, vx, vy, vok = s.uniq, s.vx, s.vy, s.vok
                        for j = 1, #uq do
                            local p = uq[j]
                            if p.Parent then
                                local v = Camera:WorldToViewportPoint(p.Position)
                                vx[j], vy[j], vok[j] = v.X, v.Y, v.Z > 0
                            else
                                vok[j] = false
                            end
                        end
                        for i = 1, #s.bones do
                            local line = s.lines[i]
                            if line then
                                local pr = s.pair[i]
                                local ja, jb = pr[1], pr[2]
                                if ja and jb and vok[ja] and vok[jb]
                                    and not pointBlocked(vx[ja], vy[ja]) and not pointBlocked(vx[jb], vy[jb]) then
                                    line.From = Vector2.new(vx[ja], vy[ja]); line.To = Vector2.new(vx[jb], vy[jb])
                                    line.Color = col; line.Visible = true
                                else
                                    line.Visible = false
                                end
                            end
                        end
                    end
                end
                end
            else
                if doBox then clearBox(plr) end
                if doSkel then clearSkel(plr) end
                if doTracer then clearTracer(plr) end
                if doBox3 then clearBox3(plr) end
            end
        end
    end
end)
bind(Players.PlayerRemoving, function(plr)
    clearEsp(plr); clearSkel(plr); clearBox(plr); clearTracer(plr); clearBox3(plr)
end)

-- ============================================================
-- COIN ESP + AUTO COLLECT
-- ============================================================
local coinContainerRef
local function getCoinContainer()
    if coinContainerRef and coinContainerRef.Parent then return coinContainerRef end
    local map = CollectionService:GetTagged("CurrentMap")[1]
    coinContainerRef = (map and map:FindFirstChild("CoinContainer")) or workspace:FindFirstChild("CoinContainer", true)
    return coinContainerRef
end

local function coinTaken(d)
    local c = d:GetAttribute("Collected")
    return c == true or c == "true"
end

local function freshCoins()
    local out = {}
    local tagged = CollectionService:GetTagged("ServerCoinPart")
    if #tagged > 0 then
        for _, d in ipairs(tagged) do
            if d:IsA("BasePart") and d.Parent and not coinTaken(d) then out[#out + 1] = d end
        end
        return out
    end
    local c = getCoinContainer()
    if c then
        for _, d in ipairs(c:GetChildren()) do
            if d:IsA("BasePart") and (d:GetAttribute("CoinID") ~= nil or d.Name == "Coin_Server") and not coinTaken(d) then
                out[#out + 1] = d
            end
        end
    end
    return out
end

local coinCache = {}
task.spawn(function()
    while not isDead() do
        if flags.coinEsp or flags.autoCoins then
            coinCache = freshCoins(); task.wait(0.2)
        else
            if #coinCache > 0 then coinCache = {} end
            task.wait(1)
        end
    end
end)

local coinEspStore = {}
task.spawn(function()
    while not isDead() do
        if flags.coinEsp then
            local seen = {}
            for _, coin in ipairs(coinCache) do
                seen[coin] = true
                if not coinEspStore[coin] then
                    local vis = coin:FindFirstChild("CoinVisual")
                    local ad = (vis and vis:FindFirstChild("MainCoin")) or vis or coin
                    coinEspStore[coin] = create("Highlight", { Name = rnd(), Adornee = ad,
                        FillColor = Color3.fromRGB(255, 205, 55), FillTransparency = 0.25,
                        OutlineColor = Color3.fromRGB(255, 235, 150), OutlineTransparency = 0,
                        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Parent = EspGui })
                end
            end
            for coin, hl in pairs(coinEspStore) do
                if not seen[coin] or not coin.Parent then hl:Destroy(); coinEspStore[coin] = nil end
            end
        elseif next(coinEspStore) then
            for coin, hl in pairs(coinEspStore) do hl:Destroy(); coinEspStore[coin] = nil end
        end
        task.wait(0.15)
    end
end)

-- Round teleport markers
local GameplayR = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay")
for _, rn in ipairs({ "TeleportToPart", "RoundStart", "RoundEndFade", "LoadingMap", "GameOver", "VictoryScreen" }) do
    local r = GameplayR:FindFirstChild(rn)
    if r and r:IsA("RemoteEvent") then bind(r.OnClientEvent, Mono.markTeleport) end
end
bind(LocalPlayer.CharacterAdded, Mono.markTeleport)

local coinBagFull = false
local CoinCollectedR = GameplayR:FindFirstChild("CoinCollected")
local CoinsStartedR = GameplayR:FindFirstChild("CoinsStarted")
if CoinCollectedR then
    bind(CoinCollectedR.OnClientEvent, function(_, collected, capacity)
        if type(collected) == "number" and type(capacity) == "number" and capacity > 0 and collected >= capacity then
            if not coinBagFull then
                coinBagFull = true
                if flags.autoCoins then notify("AutoFarm", "Coin bag full, auto collect stopped", "Warning", 4) end
            end
        end
    end)
end
if CoinsStartedR then bind(CoinsStartedR.OnClientEvent, function() coinBagFull = false end) end

-- Auto collect coins loop
local COLLECT_SPEED = 16
local farmBlack = {}
local unstick
task.spawn(function()
    local target, since, farming, prevWS
    local function standDown()
        if not farming then return end
        farming = false
        local ch2 = LocalPlayer.Character
        local hum2 = ch2 and ch2:FindFirstChildOfClass("Humanoid")
        if hum2 then
            pcall(function()
                hum2.PlatformStand = false
                if prevWS then hum2.WalkSpeed = prevWS end
            end)
        end
        Mono.wantPS = false
        Mono.wantNoclip = false
        Mono.recollide(hum2)
        if unstick then unstick(ch2) end
        prevWS = nil
    end
    while not isDead() do
        if flags.autoCoins and not coinBagFull and alive(LocalPlayer) and not Mono.teleporting() then
            local ch = LocalPlayer.Character; local hrp = getHRP(ch)
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                local coin, bd
                for _, c in ipairs(coinCache) do
                    if c.Parent and not coinTaken(c) and not (farmBlack[c] and os.clock() < farmBlack[c]) then
                        local d = (c.Position - hrp.Position).Magnitude
                        if d <= Mono.COIN_MAX_DIST and (not bd or d < bd) then bd, coin = d, c end
                    end
                end
                if coin then
                    if not farming then
                        farming = true; prevWS = hum.WalkSpeed
                        pcall(function() hum.PlatformStand = true end)
                        Mono.wantPS = true; Mono.wantNoclip = true
                    end
                    local spd = COLLECT_SPEED
                    pcall(function() hum.WalkSpeed = spd end)
                    if coin ~= target then target = coin; since = os.clock() end
                    if os.clock() - since > 5 then
                        farmBlack[coin] = os.clock() + 8; target = nil; task.wait()
                    else
                        local dt = RunService.RenderStepped:Wait()
                        for _, p in ipairs(getCharParts(ch)) do
                            if p.CanCollide then p.CanCollide = false; Mono.unclip[p] = true end
                        end
                        local dir = coin.Position - hrp.Position
                        if dir.Magnitude > 2 then
                            hrp.CFrame = CFrame.new(hrp.Position + dir.Unit * math.min(dir.Magnitude, spd * dt))
                            hrp.AssemblyLinearVelocity = Vector3.zero
                        end
                        if typeof(firetouchinterest) == "function" then
                            pcall(function()
                                firetouchinterest(hrp, coin, 0); firetouchinterest(hrp, coin, 1)
                            end)
                        end
                    end
                else
                    standDown(); target = nil; task.wait(0.25)
                end
            else
                task.wait(0.1)
            end
        else
            standDown(); target = nil; task.wait(0.2)
        end
    end
end)

-- ============================================================
-- TRAP ESP
-- ============================================================
do
    local TrapSystem = ReplicatedStorage:FindFirstChild("TrapSystem")
    local trapHls = {}
    local function dropTrap(part)
        local h = trapHls[part]
        if h then
            pcall(function() h.hl:Destroy() end)
            pcall(function() h.bb:Destroy() end)
            trapHls[part] = nil
        end
    end
    local function addTrap(part)
        if trapHls[part] or not part:IsA("BasePart") then return end
        local hl = create("Highlight", { Name = rnd(), Adornee = part,
            FillColor = Color3.fromRGB(255, 90, 255), FillTransparency = 0.4,
            OutlineColor = Color3.fromRGB(255, 170, 255), OutlineTransparency = 0,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = false, Parent = EspGui })
        local bb = create("BillboardGui", { Name = rnd(), Size = UDim2.fromOffset(90, 16),
            AlwaysOnTop = true, StudsOffsetWorldSpace = Vector3.new(0, 2, 0), Adornee = part,
            Enabled = false, Parent = EspGui },
            { create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
                Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(255, 150, 255),
                TextStrokeTransparency = .4, Text = "TRAP" }) })
        trapHls[part] = { hl = hl, bb = bb }
    end
    for _, d in ipairs(workspace:GetDescendants()) do
        if d.Name == "TrapVisual" then addTrap(d) end
    end
    bind(workspace.DescendantAdded, function(d)
        if d.Name == "TrapVisual" then task.defer(addTrap, d) end
    end)
    bind(workspace.DescendantRemoving, function(d)
        if trapHls[d] then dropTrap(d) end
    end)
    task.spawn(function()
        while not isDead() do
            for part, h in pairs(trapHls) do
                if not part.Parent then dropTrap(part)
                else
                    h.hl.Enabled = flags.trapEsp
                    h.bb.Enabled = flags.trapEsp
                end
            end
            task.wait(0.1)
        end
    end)

    if TrapSystem then
        local thl = TrapSystem:FindFirstChild("TrapHitLocal")
        if thl then
            bind(thl.OnClientEvent, function()
                if not flags.antiTrap then return end
                task.spawn(function()
                    local ch = LocalPlayer.Character
                    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                    if not hum then return end
                    local want = flags.walkSpeedOn and flags.walkSpeed or 16
                    local t0 = os.clock()
                    while os.clock() - t0 < 4.6 do
                        if hum.Parent then
                            if hum.WalkSpeed < want then hum.WalkSpeed = want end
                            if hum.JumpPower < 40 then hum.UseJumpPower = true; hum.JumpPower = 50 end
                        end
                        RunService.Heartbeat:Wait()
                    end
                end)
            end)
        end
    end
end

-- ============================================================
-- FOOTSTEP TRAILS
-- ============================================================
do
    local FS = { prints = {}, last = setmetatable({}, { __mode = "k" }),
                 side = setmetatable({}, { __mode = "k" }),
                 folder = nil, life = 8, at = 0, ray = RaycastParams.new() }
    FS.ray.FilterType = Enum.RaycastFilterType.Exclude

    function FS.tint(role)
        if role == "Murderer" then return Color3.fromRGB(255, 80, 80) end
        if isGunRole(role) then return Color3.fromRGB(90, 150, 255) end
        return Color3.fromRGB(95, 225, 125)
    end
    function FS.clear()
        for i = #FS.prints, 1, -1 do
            local e = FS.prints[i]
            pcall(function() e.part:Destroy() end)
            if e.toe then pcall(function() e.toe:Destroy() end) end
            FS.prints[i] = nil
        end
        table.clear(FS.last); table.clear(FS.side)
        if FS.folder then pcall(function() FS.folder:Destroy() end); FS.folder = nil end
    end
    function FS.drop(cf, col)
        if #FS.prints >= 220 then
            local old = table.remove(FS.prints, 1)
            if old then
                pcall(function() old.part:Destroy() end)
                if old.toe then pcall(function() old.toe:Destroy() end) end
            end
        end
        if not (FS.folder and FS.folder.Parent) then
            FS.folder = create("Folder", { Name = rnd(), Parent = workspace })
        end
        local part = create("Part", { Name = rnd(), Anchored = true, CanCollide = false,
            CanQuery = false, CanTouch = false, CastShadow = false,
            Size = Vector3.new(0.4, 0.07, 0.66), Material = Enum.Material.Neon,
            Color = col, Transparency = 0.15, CFrame = cf, Parent = FS.folder },
            { create("SpecialMesh", { MeshType = Enum.MeshType.Sphere }) })
        local toe = create("Part", { Name = rnd(), Anchored = true, CanCollide = false,
            CanQuery = false, CanTouch = false, CastShadow = false,
            Size = Vector3.new(0.26, 0.06, 0.2), Material = Enum.Material.Neon,
            Color = col, Transparency = 0.15, CFrame = cf * CFrame.new(0, 0, -0.46),
            Parent = FS.folder },
            { create("SpecialMesh", { MeshType = Enum.MeshType.Sphere }) })
        FS.prints[#FS.prints + 1] = { part = part, toe = toe, born = os.clock() }
    end

    Mono.FS = FS
    bind(RunService.Heartbeat, function()
        if not flags.footstepTrails then
            if #FS.prints > 0 or FS.folder then FS.clear() end
            return
        end
        local now = os.clock()
        for i = #FS.prints, 1, -1 do
            local e = FS.prints[i]
            local age = now - e.born
            if age >= FS.life or not e.part.Parent then
                pcall(function() e.part:Destroy() end)
                if e.toe then pcall(function() e.toe:Destroy() end) end
                table.remove(FS.prints, i)
            else
                local t = 0.15 + 0.85 * (age / FS.life)
                e.part.Transparency = t
                if e.toe then e.toe.Transparency = t end
            end
        end
        if now - FS.at < 0.08 then return end
        FS.at = now
        local me = LocalPlayer.Character
        for _, plr in ipairs(Mono.plrs) do
            local ch, _, hrp = Mono.hasBody(plr)
            if (plr ~= LocalPlayer or flags.footMine) and ch then
                if hrp then
                    local pos = hrp.Position
                    local prev = FS.last[plr]
                    if not prev then
                        FS.last[plr] = pos
                    elseif (pos - prev).Magnitude >= 3.5 then
                        FS.last[plr] = pos
                        FS.ray.FilterDescendantsInstances = { ch, me, FS.folder }
                        local hit = workspace:Raycast(pos, Vector3.new(0, -8, 0), FS.ray)
                        if hit then
                            local n = hit.Normal
                            local travel = pos - prev
                            local look = (travel.Magnitude > 0.5) and travel.Unit or hrp.CFrame.LookVector
                            local fwd = look - n * look:Dot(n)
                            fwd = (fwd.Magnitude > 1e-3) and fwd.Unit or Vector3.new(0, 0, -1)
                            local side = fwd:Cross(n)
                            FS.side[plr] = not FS.side[plr]
                            local base = hit.Position + side * (FS.side[plr] and 0.3 or -0.3) + n * 0.045
                            FS.drop(CFrame.lookAt(base, base + fwd, n), FS.tint(Mono.espRole(plr)))
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================================
-- FULLBRIGHT / FPS BOOST / FOV
-- ============================================================
Mono.lightStore = nil
Mono.shadowOrig = nil
function Mono.shadowsOff()
    if Mono.shadowOrig == nil then Mono.shadowOrig = Lighting.GlobalShadows end
    pcall(function() Lighting.GlobalShadows = false end)
end
function Mono.shadowsRestore()
    if flags.fullbright or flags.fpsBoost then return end
    if Mono.shadowOrig ~= nil then
        pcall(function() Lighting.GlobalShadows = Mono.shadowOrig end)
        Mono.shadowOrig = nil
    end
end
function Mono.brightApply()
    if not Mono.lightStore then
        Mono.lightStore = { Lighting.Brightness, Lighting.ClockTime, Lighting.Ambient,
            Lighting.OutdoorAmbient, Lighting.FogEnd, Lighting.FogStart, Lighting.ExposureCompensation }
    end
    pcall(function()
        Lighting.Brightness = math.max(Lighting.Brightness, 3)
        Lighting.ClockTime = 14
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.FogStart = 1e6
        Lighting.FogEnd = 1e6
        Lighting.ExposureCompensation = 0
    end)
    Mono.shadowsOff()
end
function Mono.brightRestore()
    local s = Mono.lightStore
    if s then
        pcall(function()
            Lighting.Brightness, Lighting.ClockTime, Lighting.Ambient = s[1], s[2], s[3]
            Lighting.OutdoorAmbient, Lighting.FogEnd, Lighting.FogStart, Lighting.ExposureCompensation = s[4], s[5], s[6], s[7]
        end)
        Mono.lightStore = nil
    end
    Mono.shadowsRestore()
end
function Mono.gfxApply()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if atm and not Mono.atmStore then
        Mono.atmStore = { atm, atm.Density, atm.Haze, atm.Glare }
        pcall(function() atm.Density = 0; atm.Haze = 0; atm.Glare = 0 end)
    end
    Mono.shadowsOff()
end
function Mono.gfxRestore()
    local a = Mono.atmStore
    if a then
        pcall(function() if a[1].Parent then a[1].Density = a[2]; a[1].Haze = a[3]; a[1].Glare = a[4] end end)
        Mono.atmStore = nil
    end
    Mono.shadowsRestore()
end
local function setFullbright(on)
    if on then Mono.brightApply() else Mono.brightRestore() end
end

local fpsStore, fpsConn
local function fxKill(e, store)
    if store[e] ~= nil then return end
    if e:IsA("PostEffect") then
        if e.Enabled then e.Enabled = false; store[e] = { "en" } end
    elseif e:IsA("ParticleEmitter") or e:IsA("Trail") or e:IsA("Smoke") or e:IsA("Fire") or e:IsA("Sparkles") or e:IsA("Beam") then
        if e.Enabled then e.Enabled = false; store[e] = { "en" } end
    elseif e:IsA("Decal") or e:IsA("Texture") then
        store[e] = { "tr", e.Transparency }; e.Transparency = 1
    elseif e:IsA("SurfaceAppearance") then
        store[e] = { "par", e.Parent }; e.Parent = nil
    elseif e:IsA("BasePart") then
        local mat, refl = e.Material, e.Reflectance
        local tex = e:IsA("MeshPart") and e.TextureID or nil
        if mat ~= Enum.Material.SmoothPlastic or refl ~= 0 or (tex and tex ~= "") then
            store[e] = { "part", mat, refl, tex }
            pcall(function()
                e.Material = Enum.Material.SmoothPlastic
                e.Reflectance = 0
                if tex and tex ~= "" then e.TextureID = "" end
            end)
        end
    end
end

local function setFPSBoost(on)
    if on then
        fpsStore = { changed = Mono.fxPending or {} }
        Mono.fxPending = nil
        Mono.gfxApply()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            local okD, d = pcall(function() return terrain.Decoration end)
            if okD then fpsStore.decor = d; pcall(function() terrain.Decoration = false end) end
            fpsStore.water = { terrain.WaterWaveSize, terrain.WaterWaveSpeed, terrain.WaterReflectance }
            terrain.WaterWaveSize = 0; terrain.WaterWaveSpeed = 0; terrain.WaterReflectance = 0
        end
        fpsConn = workspace.DescendantAdded:Connect(function(e)
            if flags.fpsBoost and fpsStore then task.defer(fxKill, e, fpsStore.changed) end
        end)
        table.insert(conns, fpsConn)
        task.spawn(function()
            local s = fpsStore.changed; local n = 0
            for _, e in ipairs(Lighting:GetDescendants()) do fxKill(e, s) end
            for _, e in ipairs(workspace:GetDescendants()) do
                if not (flags.fpsBoost and fpsStore and fpsStore.changed == s) then return end
                fxKill(e, s); n = n + 1; if n % 900 == 0 then RunService.Heartbeat:Wait() end
            end
        end)
    elseif fpsStore then
        local s = fpsStore.changed
        Mono.fxPending = s
        Mono.gfxRestore()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain and fpsStore.water then
            terrain.WaterWaveSize, terrain.WaterWaveSpeed, terrain.WaterReflectance = fpsStore.water[1], fpsStore.water[2], fpsStore.water[3]
        end
        if terrain and fpsStore.decor ~= nil then pcall(function() terrain.Decoration = fpsStore.decor end) end
        if fpsConn then fpsConn:Disconnect(); fpsConn = nil end
        fpsStore = nil
        task.spawn(function()
            local n = 0
            for e, info in pairs(s) do
                if Mono.fxPending ~= s then return end
                pcall(function()
                    if info[1] == "en" then e.Enabled = true
                    elseif info[1] == "tr" then e.Transparency = info[2]
                    elseif info[1] == "par" then e.Parent = info[2]
                    elseif info[1] == "part" then
                        e.Material = info[2]; e.Reflectance = info[3]
                        if info[4] and info[4] ~= "" then e.TextureID = info[4] end
                    end
                end)
                s[e] = nil
                n = n + 1; if n % 900 == 0 then RunService.Heartbeat:Wait() end
            end
            if Mono.fxPending == s then Mono.fxPending = nil end
        end)
    end
end
Mono.setFPSBoost = setFPSBoost

-- Field of View
local function applyFov(v) pcall(function() Camera.FieldOfView = v end) end

-- ============================================================
-- CHARACTER PARTS / UNCLIP HELPERS
-- ============================================================
local charParts, charPartsFor = {}, nil
local function refreshCharParts(ch)
    charParts = {}
    if Mono.cpConn then Mono.cpConn:Disconnect(); Mono.cpConn = nil end
    if not ch then charPartsFor = nil return end
    for _, p in ipairs(ch:GetDescendants()) do
        if p:IsA("BasePart") then charParts[#charParts + 1] = p end
    end
    charPartsFor = ch
    Mono.cpConn = ch.DescendantAdded:Connect(function(d)
        if ch == charPartsFor and d:IsA("BasePart") then charParts[#charParts + 1] = d end
    end)
    table.insert(conns, Mono.cpConn)
end
local function getCharParts(ch)
    if ch ~= charPartsFor then refreshCharParts(ch) end
    return charParts
end
bind(LocalPlayer.CharacterAdded, function(ch)
    task.defer(function() refreshCharParts(ch) end)
end)
if LocalPlayer.Character then refreshCharParts(LocalPlayer.Character) end

local function uncollide(ch)
    for _, p in ipairs(getCharParts(ch)) do
        if p.Parent and p.CanCollide then p.CanCollide = false; Mono.unclip[p] = true end
    end
end
function Mono.recollide(hum, force)
    if (not force) and (flags.noclip or flinging or Mono.wantNoclip) then return end
    for p in pairs(Mono.unclip) do
        if p.Parent then p.CanCollide = true end
    end
    table.clear(Mono.unclip)
    if hum then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
end

unstick = function(ch)
    if not ch then return end
    local hrp = getHRP(ch); if not hrp then return end
    task.spawn(function()
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { ch }
        local from = hrp.Position + Vector3.new(0, 6, 0)
        local hit = workspace:Raycast(from, Vector3.new(0, -200, 0), params)
        Mono.markSelfTP()
        if hit then
            hrp.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3.5, 0))
        else
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 4, 0)
        end
        hrp.AssemblyLinearVelocity = Vector3.zero
        RunService.Heartbeat:Wait()
        for p in pairs(Mono.unclip) do
            if p.Parent and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
        end
        table.clear(Mono.unclip)
    end)
end

local function tpTo(pos)
    local hrp = getHRP(LocalPlayer.Character); if not hrp then return false end
    Mono.markSelfTP()
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    return true
end
Mono.tpTo = tpTo

local function resolvePlayer(v)
    if typeof(v) == "Instance" and v:IsA("Player") then return v end
    if type(v) == "string" and #v > 0 then
        local p = Players:FindFirstChild(v); if p and p:IsA("Player") then return p end
        local lv = v:lower()
        for _, q in ipairs(Mono.plrs) do
            if q.Name:lower() == lv or (q.DisplayName or ""):lower() == lv then return q end
        end
    end
    return nil
end
Mono.resolvePlayer = resolvePlayer

print("[LightHub] Part 3 loaded")


-- ============================================================
-- LIGHT HUB MM2 - PART 4: MOVEMENT / SAFETY / UTILITY
-- ============================================================

-- ============================================================
-- FLY
-- ============================================================
local controlModule
local function getControls()
    if not controlModule then
        pcall(function()
            controlModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
        end)
    end
    return controlModule
end

local lastJumpAt = -10
local flyBV, flyBG
local function startFly()
    local ch = LocalPlayer.Character; local hrp = getHRP(ch)
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum) then return end
    hum.PlatformStand = true; Mono.wantPS = true
    flyBV = create("BodyVelocity", { MaxForce = Vector3.new(1, 1, 1) * 9e9, P = 9e4,
        Velocity = Vector3.zero, Parent = hrp })
    flyBG = create("BodyGyro", { MaxTorque = Vector3.new(1, 1, 1) * 9e9, P = 9e4,
        CFrame = hrp.CFrame, Parent = hrp })
end
local function stopFly()
    local ch = LocalPlayer.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
    Mono.wantPS = false
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
end
Mono.stopFly = stopFly

bind(RunService.RenderStepped, function()
    if not flags.fly or not flyBV then return end
    local hrp = getHRP(LocalPlayer.Character); if not hrp then return end
    local dir = Vector3.zero
    local look, right = Camera.CFrame.LookVector, Camera.CFrame.RightVector
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + look end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - look end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + right end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - right end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or Mono.mobUp then dir = dir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or Mono.mobDown then dir = dir - Vector3.new(0, 1, 0) end
    if dir.Magnitude == 0 then
        local c = getControls()
        local mv = c and c:GetMoveVector()
        if mv and mv.Magnitude > 0 then dir = dir + (look * (-mv.Z)) + (right * mv.X) end
    end
    if os.clock() - lastJumpAt < 0.25 then dir = dir + Vector3.new(0, 1, 0) end
    flyBV.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * flags.flySpeed
    flyBG.CFrame = Camera.CFrame
end)

-- Mobile fly buttons
do
    local TOUCH_ONLY = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local pad, btns = nil, {}
    local function build()
        local gui = trackGui(create("ScreenGui", { Name = rnd(), ResetOnSpawn = false,
            IgnoreGuiInset = false, DisplayOrder = 999, Parent = mountTarget }))
        protect(gui)
        pad = create("Frame", { Name = rnd(), AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -20, 1, -150), Size = UDim2.fromOffset(70, 252),
            BackgroundTransparency = 1, Visible = false, Parent = gui })
        local grip = create("Frame", { Name = rnd(), Size = UDim2.fromOffset(70, 18),
            BackgroundColor3 = Color3.fromRGB(19, 19, 21), BackgroundTransparency = 0.25,
            BorderSizePixel = 0, Parent = pad },
            { create("UICorner", { CornerRadius = UDim.new(1, 0) }),
              create("Frame", { Name = rnd(), AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(26, 2),
                BackgroundColor3 = Color3.fromRGB(150, 150, 155), BackgroundTransparency = 0.3,
                BorderSizePixel = 0 }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) }) })
        local function pill(y, glyph, set)
            local b = create("TextButton", { Name = rnd(), Position = UDim2.fromOffset(0, y),
                Size = UDim2.fromOffset(70, 70), BackgroundColor3 = Color3.fromRGB(19, 19, 21),
                BackgroundTransparency = 0.15, AutoButtonColor = false, Text = glyph,
                TextColor3 = Color3.fromRGB(238, 238, 240), TextSize = 27,
                Font = Enum.Font.GothamMedium, Visible = false, Parent = pad },
                { create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                  create("UIStroke", { Color = Color3.fromRGB(72, 72, 76), Thickness = 1, Transparency = 0.35 }) })
            b.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch then set(true); b.BackgroundTransparency = 0 end
            end)
            b.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Touch then set(false); b.BackgroundTransparency = 0.15 end
            end)
            return b
        end
        btns.up = pill(26, "▲", function(v) Mono.mobUp = v end)
        btns.down = pill(117, "▼", function(v) Mono.mobDown = v end)
        btns.aim = pill(208, "◎", function(v) Mono.mobAim = v end)

        local drag, startPos, startIn = false, nil, nil
        grip.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch then
                drag = true; startPos = pad.Position; startIn = i.Position
            end
        end)
        grip.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch then drag = false end
        end)
        bind(UserInputService.InputChanged, function(i)
            if drag and i.UserInputType == Enum.UserInputType.Touch and startPos then
                local d = i.Position - startIn
                pad.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
    end

    local last = 0
    bind(RunService.Heartbeat, function()
        if not TOUCH_ONLY then return end
        local now = os.clock()
        if now - last < 0.25 then return end
        last = now
        local wantFly = flags.fly and true or false
        local wantAim = flags.aimbot and true or false
        if not (wantFly or wantAim) then
            if pad then pad.Visible = false end
            Mono.mobUp, Mono.mobDown, Mono.mobAim = false, false, false
            return
        end
        if not pad then build() end
        btns.up.Visible = wantFly
        btns.down.Visible = wantFly
        btns.aim.Visible = wantAim
        btns.aim.Position = UDim2.fromOffset(0, wantFly and 208 or 26)
        pad.Size = UDim2.fromOffset(70, 26 + (wantFly and 182 or 0) + (wantAim and 70 or 0))
        pad.Visible = true
    end)
end

-- ============================================================
-- NOCLIP / INF JUMP / UNLOCK CAM
-- ============================================================
local flinging = false
bind(RunService.Stepped, function()
    if flinging and os.clock() - (Mono.flingAt or 0) > (flags.flingSeconds or 3) + 8 then flinging = false end
    if not (flags.noclip or flinging or Mono.wantNoclip) then
        if next(Mono.unclip) then
            Mono.recollide(LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
        end
        return
    end
    local ch = LocalPlayer.Character; if not ch then return end
    uncollide(ch)
end)

bind(UserInputService.JumpRequest, function()
    lastJumpAt = os.clock()
    if flags.infJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local origMaxZoom = LocalPlayer.CameraMaxZoomDistance
local function setUnlockCam(on)
    pcall(function() LocalPlayer.CameraMaxZoomDistance = on and 10000 or origMaxZoom end)
end
Mono.setUnlockCam = setUnlockCam

local camCams, origOccUpdate
local function getCams()
    if camCams then return camCams end
    if os.clock() - (Mono.camTryAt or -10) < 2 then return nil end
    Mono.camTryAt = os.clock()
    pcall(function()
        camCams = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetCameras()
    end)
    return camCams
end
local function setCamThruWalls(on)
    if Mono.camThru == on then return end
    Mono.camThru = on
    local cams = getCams(); if not cams then Mono.camThru = nil return end
    local occ = cams.activeOcclusionModule; if not (occ and occ.Update) then return end
    if on and not occ.__monoHook then
        origOccUpdate = occ.Update; occ.__monoHook = true
        occ.Update = function(_, _, desiredCF, desiredFocus) return desiredCF, desiredFocus end
    elseif (not on) and occ.__monoHook then
        occ.Update = origOccUpdate; occ.__monoHook = false
    end
end
Mono.setCamThruWalls = setCamThruWalls

bind(RunService.Heartbeat, function()
    if flags.unlockCam and LocalPlayer.CameraMaxZoomDistance < 9999 then setUnlockCam(true) end
    setCamThruWalls(flags.unlockCam and flags.noclip)
end)

-- Walk speed / jump power live enforcement
local function applyWalkSpeed()
    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = flags.walkSpeedOn and flags.walkSpeed or 16 end
end
local function applyJumpPower()
    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.UseJumpPower = true; h.JumpPower = flags.jumpPowerOn and flags.jumpPower or 50 end
end
bind(LocalPlayer.CharacterAdded, function(ch)
    task.defer(function()
        task.wait(0.5)
        applyWalkSpeed(); applyJumpPower()
    end)
end)

-- ============================================================
-- FLING
-- ============================================================
Mono.canClaim = (typeof(sethiddenproperty) == "function")
function Mono.voidY()
    local ok, v = pcall(function() return workspace.FallenPartsDestroyHeight end)
    return (ok and type(v) == "number") and v or -500
end
function Mono.alreadyFlung(p)
    local hrp = p and p.Character and getHRP(p.Character)
    if not hrp then return true end
    if os.clock() - (Mono.flungAt[p] or -60) < 4 then return true end
    if hrp.AssemblyLinearVelocity.Magnitude > 100 then return true end
    if hrp.Position.Y < Mono.voidY() + 150 then return true end
    local mine = getHRP(LocalPlayer.Character)
    if mine then
        local dy = hrp.Position.Y - mine.Position.Y
        if dy < -60 or dy > 120 then return true end
    end
    return false
end

local function flingPlayer(p, keepPos)
    if flinging then return false, "already flinging someone" end
    local myCh = LocalPlayer.Character; local myHrp = getHRP(myCh)
    local hum = myCh and myCh:FindFirstChildOfClass("Humanoid")
    local tHrp = p and p.Character and getHRP(p.Character)
    if not (myHrp and hum and tHrp) then return false, "they have no character right now" end
    local back = keepPos or myHrp.CFrame
    if Mono.teleporting() then return false, "the round just moved you, try again in a second" end
    if math.abs(tHrp.Position.Y - back.Position.Y) > Mono.FLING_MAX_DY then
        return false, "they are too far above or below you"
    end
    if tHrp.AssemblyLinearVelocity.Magnitude > 340 then
        return false, "they are already flying, wait for them to land"
    end

    Mono.flingAt = os.clock()
    flinging = true
    local moved = false
    local movel = 0.1
    local t0 = os.clock()
    local claimed
    while os.clock() - t0 < flags.flingSeconds do
        if Mono.teleporting() then break end
        RunService.Heartbeat:Wait()
        local h = getHRP(LocalPlayer.Character)
        local t = p.Character and getHRP(p.Character)
        if not (h and t and h.Parent and t.Parent) then break end
        local tp = t.Position
        if tp.Y < Mono.voidY() + 400 then break end
        if t.AssemblyLinearVelocity.Magnitude > 340 then break end
        if tp.Y > back.Position.Y + Mono.FLING_MAX_RISE then break end
        if tp.Y < back.Position.Y - Mono.FLING_MAX_DY then break end
        h.CFrame = t.CFrame
        moved = true
        Mono.flungAt[p] = os.clock()
        if Mono.canClaim then
            pcall(function() sethiddenproperty(h, "PhysicsRepRootPart", t) end)
            claimed = h
        end
        local vel = h.AssemblyLinearVelocity
        h.AssemblyLinearVelocity = vel * flags.flingPower + Vector3.new(0, flags.flingPower, 0)
        RunService.RenderStepped:Wait()
        if not h.Parent then break end
        h.AssemblyLinearVelocity = vel
        RunService.Stepped:Wait()
        if not h.Parent then break end
        h.AssemblyLinearVelocity = vel + Vector3.new(0, movel, 0)
        movel = -movel
    end

    local function release(part)
        if part and Mono.canClaim then
            pcall(function() sethiddenproperty(part, "PhysicsRepRootPart", nil) end)
        end
    end
    release(claimed)
    local nowHrp = getHRP(LocalPlayer.Character)
    if nowHrp and nowHrp ~= claimed then release(nowHrp) end

    if not moved then
        flinging = false
        Mono.recollide(LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), true)
        return false, "could not get a grip on them, try again"
    end

    local home = CFrame.new(back.Position + Vector3.new(0, 4, 0))
    for _ = 1, 6 do
        local ch2 = LocalPlayer.Character
        if not ch2 then break end
        for _, pp in ipairs(getCharParts(ch2)) do
            if pp.Parent then
                pp.AssemblyLinearVelocity = Vector3.zero
                pp.AssemblyAngularVelocity = Vector3.zero
            end
        end
        RunService.Heartbeat:Wait()
    end
    local h2 = getHRP(LocalPlayer.Character)
    if h2 then
        h2.CFrame = home
        h2.AssemblyLinearVelocity = Vector3.zero
        h2.AssemblyAngularVelocity = Vector3.zero
    end
    flinging = false
    local hum2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    Mono.recollide(hum2, true)
    local watch = os.clock()
    while os.clock() - watch < 1.5 do
        RunService.Heartbeat:Wait()
        if Mono.teleporting() then break end
        local h3 = getHRP(LocalPlayer.Character)
        if not h3 then break end
        local lv = h3.AssemblyLinearVelocity
        local av = h3.AssemblyAngularVelocity
        if badVec(lv) or badVec(av) or lv.Magnitude > 200 or av.Magnitude > 25 then
            h3.AssemblyLinearVelocity = Vector3.zero
            h3.AssemblyAngularVelocity = Vector3.zero
            h3.CFrame = home
        end
    end
    Mono.recollide(LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), true)
    return true
end
Mono.flingPlayer = flingPlayer

local function flingAll()
    local myHrp = getHRP(LocalPlayer.Character)
    if not myHrp then notify("Fling", "You have no character", "Warning") return end
    local home = myHrp.CFrame
    task.spawn(function()
        local n = 0
        for _, p in ipairs(Mono.plrs) do
            if p ~= LocalPlayer and Mono.hasBody(p) then
                if flingPlayer(p, home) then n = n + 1 end
                task.wait(0.1)
            end
        end
        local h = getHRP(LocalPlayer.Character)
        if h then h.CFrame = home; h.AssemblyLinearVelocity = Vector3.zero end
        notify("Fling", "Flung " .. n .. " player" .. (n == 1 and "" or "s"), "Success")
    end)
end
Mono.flingAll = flingAll

task.spawn(function()
    while not isDead() do
        if (flags.autoFlingMurderer or flags.autoFlingSheriff)
            and Mono.hasBody(LocalPlayer) and not flinging and not Mono.teleporting() then
            local want
            for _, p in ipairs(Mono.plrs) do
                if p ~= LocalPlayer and alive(p) and p.Character and getHRP(p.Character) then
                    local r = roleOf(p)
                    if ((flags.autoFlingMurderer and r == "Murderer")
                        or (flags.autoFlingSheriff and isGunRole(r)))
                        and not Mono.alreadyFlung(p) then
                        want = p; break
                    end
                end
            end
            if want then flingPlayer(want) end
        end
        task.wait(0.5)
    end
end)

-- ============================================================
-- MURDERER NOTIFY / KILL FEED / ROLE NOTIFY
-- ============================================================
local MURD_ALERT_RANGE = 50
local murdNotif = nil
local murdInRange = false
local function closeMurdNotif()
    murdInRange = false
    if murdNotif then
        pcall(function() murdNotif:Close() end)
        murdNotif = nil
    end
end

bind(RunService.Heartbeat, function()
    if not flags.murdererNotify then closeMurdNotif() return end
    local hrp = getHRP(LocalPlayer.Character)
    local m = findMurderer()
    local mh = (m and m ~= LocalPlayer and alive(m)) and getHRP(m.Character) or nil
    if not (hrp and mh) then closeMurdNotif() return end
    local d = math.floor((mh.Position - hrp.Position).Magnitude)
    if d > MURD_ALERT_RANGE then
        if murdInRange then closeMurdNotif() end
        return
    end
    if not murdInRange then
        murdInRange = true
        notify("Murderer Nearby", (m.DisplayName or m.Name) .. "  ·  " .. d .. "m", "Warning", 4)
    end
end)

local GiveWeaponR = GameplayR:FindFirstChild("GiveWeapon")
if GiveWeaponR then
    bind(GiveWeaponR.OnClientEvent, function(w)
        if w == "Knife" or w == "Gun" then
            notify("Role", "You are the " .. (w == "Knife" and "MURDERER" or "SHERIFF") .. "!", "Success", 3)
        end
    end)
end

-- Kill feed
do
    local function feedNotify(name, killType, role, color)
        local tag = role and (" [" .. (role == "Murderer" and "M" or isGunRole(role) and "S" or "I") .. "]") or ""
        notify("Kill Feed", tostring(name) .. tag .. "  ·  " .. tostring(killType or "Eliminated"), "Info", 4)
    end
    local recentKillEvent = {}
    local KillEventR = GameplayR:FindFirstChild("KillEvent")
    if KillEventR then
        bind(KillEventR.OnClientEvent, function(victim, roleColor, _, killType)
            if not victim then return end
            local nm = tostring(victim)
            recentKillEvent[nm] = os.clock()
            if flags.killFeed then
                local p = Players:FindFirstChild(nm)
                feedNotify(nm, killType, p and roleOf(p) or nil,
                    typeof(roleColor) == "Color3" and roleColor or nil)
            end
        end)
    end
    local lastDead = {}
    local function scanDeaths()
        if not (CRC and CRC.PlayerData) then return end
        for name, d in pairs(CRC.PlayerData) do
            local dead = (d.Dead == true)
            local was = lastDead[name]
            if was == false and dead then
                local seen = recentKillEvent[name]
                if flags.killFeed and not (seen and os.clock() - seen < 2) then
                    feedNotify(name, nil, d.Role)
                end
            end
            lastDead[name] = dead
        end
    end
    local function watchDeaths(plr)
        if plr == LocalPlayer then return end
        local function hookChar(ch)
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            local c
            c = hum.Died:Connect(function()
                local nm = plr.Name
                local seen = recentKillEvent[nm]
                if flags.killFeed and not (seen and os.clock() - seen < 2) then
                    recentKillEvent[nm] = os.clock()
                    feedNotify(plr.DisplayName or nm, nil, roleOf(plr))
                end
            end)
            table.insert(conns, c)
        end
        if plr.Character then hookChar(plr.Character) end
        table.insert(conns, plr.CharacterAdded:Connect(function(ch)
            task.defer(function() hookChar(ch) end)
        end))
    end
    for _, p in ipairs(Mono.plrs) do watchDeaths(p) end
    bind(Players.PlayerAdded, watchDeaths)
    local PlayerDataChangedR = GameplayR:FindFirstChild("PlayerDataChanged")
    if PlayerDataChangedR then bind(PlayerDataChangedR.OnClientEvent, function() task.defer(scanDeaths) end) end
    local RoundStartR = GameplayR:FindFirstChild("RoundStart")
    if RoundStartR then
        bind(RoundStartR.OnClientEvent, function()
            lastDead = {}; recentKillEvent = {}; coinBagFull = false
            task.defer(scanDeaths)
        end)
    end
    task.spawn(function()
        while not isDead() do
            if flags.killFeed then scanDeaths(); task.wait(0.2) else task.wait(0.75) end
        end
    end)
end

-- ============================================================
-- ANTI AFK
-- ============================================================
Mono.afkFires = 0
bind(LocalPlayer.Idled, function()
    if not flags.antiAfk then return end
    if not VirtualUser then pcall(function() VirtualUser = game:GetService("VirtualUser") end) end
    if not VirtualUser then return end
    local ch = LocalPlayer.Character
    local armed = false
    if ch then
        for _, t in ipairs(ch:GetChildren()) do
            if t:IsA("Tool") then armed = true break end
        end
    end
    local ok = pcall(function()
        VirtualUser:CaptureController()
        if armed then
            VirtualUser:MoveMouse(Vector2.new(0, 0))
            VirtualUser:MoveMouse(Vector2.new(2, 2))
        else
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
    if not ok then return end
    Mono.afkFires = Mono.afkFires + 1
    if Mono.afkFires == 1 then notify("Anti AFK", "Anti AFK is working, you will not be kicked", "Success", 4) end
end)

-- ============================================================
-- ANTI FLING
-- ============================================================
do
    local MAX_LINEAR = 200
    local MAX_ANGULAR = 20
    local ANCHOR_MIN = 35
    local lastGood = nil
    local lastGoodAt = 0
    local otherParts = {}
    local flipped = setmetatable({}, { __mode = "k" })
    local nParts = 0
    local function addPart(d)
        if d:IsA("BasePart") then
            nParts = nParts + 1
            otherParts[nParts] = d
            if flags.antiFling and d.CanCollide then d.CanCollide = false; flipped[d] = true end
        end
    end
    local function restoreOthers()
        for d in pairs(flipped) do
            if d and d.Parent and d:IsA("BasePart") then d.CanCollide = true end
        end
        table.clear(flipped)
    end
    Mono.antiFlingRestore = restoreOthers
    local function hookChar(ch)
        if not ch then return end
        for _, d in ipairs(ch:GetDescendants()) do addPart(d) end
        bind(ch.DescendantAdded, function(d)
            if flags.antiFling then task.defer(addPart, d) end
        end)
    end
    local function rebuildOthers()
        table.clear(otherParts)
        nParts = 0
        for _, p in ipairs(Mono.plrs) do
            if p ~= LocalPlayer and p.Character then
                for _, d in ipairs(p.Character:GetDescendants()) do addPart(d) end
            end
        end
    end
    local function watch(p)
        if p == LocalPlayer then return end
        hookChar(p.Character)
        bind(p.CharacterAdded, function(ch) task.defer(function() hookChar(ch); rebuildOthers() end) end)
    end
    for _, p in ipairs(Mono.plrs) do watch(p) end
    bind(Players.PlayerAdded, function(p) watch(p); task.defer(rebuildOthers) end)
    bind(Players.PlayerRemoving, function() task.defer(rebuildOthers) end)
    task.spawn(function()
        while not isDead() do
            if flags.antiFling then rebuildOthers() end
            task.wait(3)
        end
    end)

    local function selfBusy() return flinging or flags.fly end
    local function guard()
        if not flags.antiFling or selfBusy() then return end
        local ch = LocalPlayer.Character
        local hrp = getHRP(ch)
        if not hrp then lastGood = nil return end

        if badCF(hrp.CFrame) then
            if lastGood then pcall(function() hrp.CFrame = lastGood end) end
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            return
        end

        local lv = hrp.AssemblyLinearVelocity
        if badVec(lv) then hrp.AssemblyLinearVelocity = Vector3.zero
        elseif lv.Magnitude > MAX_LINEAR then hrp.AssemblyLinearVelocity = lv.Unit * MAX_LINEAR end
        local av = hrp.AssemblyAngularVelocity
        if badVec(av) or av.Magnitude > MAX_ANGULAR then hrp.AssemblyAngularVelocity = Vector3.zero end

        local hum0 = ch:FindFirstChildOfClass("Humanoid")
        local maxRise = 60
        if hum0 and hum0.UseJumpPower then maxRise = math.max(60, hum0.JumpPower * 1.4) end
        local lv2 = hrp.AssemblyLinearVelocity
        if (not flags.infJump) and lv2.Y > maxRise then
            hrp.AssemblyLinearVelocity = Vector3.new(lv2.X, maxRise, lv2.Z)
        end

        local cp = getCharParts(ch)
        for i = 1, #cp do
            local p = cp[i]
            if p.Parent then
                if badVec(p.AssemblyLinearVelocity) then p.AssemblyLinearVelocity = Vector3.zero end
                local pav = p.AssemblyAngularVelocity
                if badVec(pav) or pav.Magnitude > MAX_ANGULAR then p.AssemblyAngularVelocity = Vector3.zero end
                if badCF(p.CFrame) and lastGood then pcall(function() p.CFrame = lastGood end) end
            end
        end

        if not Mono.wantPS then
            if hum0 and hum0.PlatformStand then hum0.PlatformStand = false end
        end

        local now = os.clock()
        local exempt = Mono.teleporting() or Mono.selfTeleporting() or flags.autoCoins
        if lastGood and not exempt then
            local dt = math.clamp(now - lastGoodAt, 1 / 240, 0.5)
            local allow = math.max(ANCHOR_MIN, (MAX_LINEAR + 100) * dt)
            if (hrp.Position - lastGood.Position).Magnitude > allow then
                pcall(function() hrp.CFrame = lastGood end)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                return
            end
        end
        lastGood = hrp.CFrame
        lastGoodAt = now
    end
    local function sweepCollide()
        if not flags.antiFling or flinging then return end
        for i = 1, nParts do
            local d = otherParts[i]
            if d and d.Parent and d.CanCollide then d.CanCollide = false; flipped[d] = true end
        end
    end
    bind(RunService.Heartbeat, sweepCollide)
    bind(RunService.Stepped, guard)
    bind(RunService.Heartbeat, guard)
    bind(RunService.RenderStepped, guard)

    local MOVERS = { "BodyVelocity", "BodyAngularVelocity", "BodyThrust", "BodyForce", "BodyPosition", "BodyGyro",
        "LinearVelocity", "AngularVelocity", "VectorForce", "Torque", "AlignPosition", "AlignOrientation",
        "RocketPropulsion" }
    local function isMover(d)
        for _, c in ipairs(MOVERS) do if d:IsA(c) then return true end end
        return false
    end
    local function killMover(d)
        if d == flyBV or d == flyBG or flags.fly or flinging then return end
        if d.Parent then pcall(function() d:Destroy() end) end
    end
    local function watchSelf(ch)
        if not ch then return end
        bind(ch.DescendantAdded, function(d)
            if not flags.antiFling or flags.fly then return end
            if not isMover(d) then return end
            task.defer(killMover, d)
        end)
    end
    task.spawn(function()
        while not isDead() do
            if flags.antiFling and not flags.fly and not flinging then
                local ch = LocalPlayer.Character
                if ch then
                    for _, d in ipairs(ch:GetDescendants()) do
                        if isMover(d) then killMover(d) end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
    watchSelf(LocalPlayer.Character)
    bind(LocalPlayer.CharacterAdded, watchSelf)
end

-- ============================================================
-- MURDERER EVASION (WindUI port)
-- ============================================================
local evasionConn = nil
local function setEvasion(on)
    if evasionConn then evasionConn:Disconnect(); evasionConn = nil end
    if on then
        evasionConn = RunService.Heartbeat:Connect(function()
            if not flags.evasion then return end
            local ch = LocalPlayer.Character
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local m = findMurderer()
            local mroot = (m and m ~= LocalPlayer and alive(m)) and getHRP(m.Character) or nil
            if root and hum and mroot and (root.Position - mroot.Position).Magnitude <= flags.evasionDist then
                local dir = root.Position - mroot.Position
                if dir.Magnitude > 0 then hum:MoveTo(root.Position + dir.Unit * 40) end
            end
        end)
        table.insert(conns, evasionConn)
    end
end

-- ============================================================
-- PREDICTIVE GUN DODGE (murderer, WindUI port)
-- ============================================================
local dodgeConn = nil
local function setDodge(on)
    if dodgeConn then dodgeConn:Disconnect(); dodgeConn = nil end
    if on then
        dodgeConn = RunService.Heartbeat:Connect(function()
            if not flags.predictiveDodge then return end
            if myRole() ~= "Murderer" then return end
            local ch = LocalPlayer.Character
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            if not root then return end
            for _, p in ipairs(Mono.plrs) do
                if p ~= LocalPlayer and isGunRole(roleOf(p)) and alive(p) and p.Character then
                    local shead = p.Character:FindFirstChild("Head")
                    local sgun = p.Character:FindFirstChild("Gun")
                    if shead and sgun then
                        local delta = root.Position - shead.Position
                        if delta.Magnitude > 0 and shead.CFrame.LookVector:Dot(delta.Unit) > 0.85 then
                            local hum = ch:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum:MoveTo(root.Position + shead.CFrame.RightVector * (math.random(0, 1) == 0 and -18 or 18))
                                hum.Jump = true
                            end
                        end
                    end
                end
            end
        end)
        table.insert(conns, dodgeConn)
    end
end

-- ============================================================
-- AUTO REPORT MURDERER (WindUI port)
-- ============================================================
local autoReportActive = false
task.spawn(function()
    while not isDead() do
        if flags.autoReport then
            local m = findMurderer()
            if m and m ~= LocalPlayer and Players:FindFirstChild(m.Name) then
                pcall(function() Players:ReportAbuse(m, "Cheating/Exploiting") end)
                task.wait(60)
            else
                task.wait(2)
            end
        else
            task.wait(2)
        end
    end
end)

-- ============================================================
-- HITBOX EXPANDER (WindUI port)
-- ============================================================
local hitboxAdornments = {}
local hitboxConn = nil
local function updateHitboxes()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local chr = plr.Character
            local box = hitboxAdornments[plr]
            if chr and flags.hitboxEnabled then
                local root = chr:FindFirstChild("HumanoidRootPart")
                if root then
                    if not box then
                        box = Instance.new("BoxHandleAdornment")
                        box.Adornee = root
                        box.Size = Vector3.new(flags.hitboxSize, flags.hitboxSize, flags.hitboxSize)
                        box.Color3 = Color3.new(1, 0, 0)
                        box.Transparency = 0.4
                        box.ZIndex = 10
                        box.Parent = root
                        hitboxAdornments[plr] = box
                    else
                        box.Size = Vector3.new(flags.hitboxSize, flags.hitboxSize, flags.hitboxSize)
                    end
                end
            elseif box then
                box:Destroy()
                hitboxAdornments[plr] = nil
            end
        end
    end
end
local function setHitbox(on)
    if hitboxConn then hitboxConn:Disconnect(); hitboxConn = nil end
    if on then
        hitboxConn = RunService.Heartbeat:Connect(updateHitboxes)
        table.insert(conns, hitboxConn)
    else
        for _, box in pairs(hitboxAdornments) do
            if box then box:Destroy() end
        end
        hitboxAdornments = {}
    end
end

-- ============================================================
-- RARE EGG FARM (WindUI port)
-- ============================================================
local eggFarmConn = nil
local function findNearestEgg()
    local closestEgg = nil
    local shortestDistance = math.huge
    local hrp = getHRP(LocalPlayer.Character)
    if not hrp then return nil end
    for _, item in pairs(workspace:GetDescendants()) do
        if item:IsA("BasePart") and (string.find(string.lower(item.Name), "egg") or string.find(string.lower(item.Name), "rareegg")) then
            local distance = (hrp.Position - item.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestEgg = item
            end
        end
    end
    return closestEgg
end

local function eggFarmLoop()
    while flags.eggFarm do
        local egg = findNearestEgg()
        if egg then
            local hrp = getHRP(LocalPlayer.Character)
            if hrp then
                Mono.markSelfTP()
                hrp.CFrame = CFrame.new(egg.Position + Vector3.new(0, 3, 0))
                if typeof(firetouchinterest) == "function" then
                    pcall(function()
                        firetouchinterest(hrp, egg, 0)
                        firetouchinterest(hrp, egg, 1)
                    end)
                end
            end
        else
            task.wait(2)
        end
        task.wait(0.5)
    end
end
local function setEggFarm(on)
    if eggFarmConn then pcall(task.cancel, eggFarmConn); eggFarmConn = nil end
    if on then eggFarmConn = task.spawn(eggFarmLoop) end
end

-- Beach ball farm (external)
local function startBeachBallFarm()
    task.spawn(function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/NoovaScripts/roblox/refs/heads/main/beachballfarm"))()
        end)
    end)
    notify("AutoFarm", "Beach Ball farm started!", "Success", 2)
end

-- ============================================================
-- UNLOCK ALL (WindUI port)
-- ============================================================
local function unlockAll()
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

        local data = loadfile("mm2data.lua")() or nil
        if not data then
            notify("Unlock All", "Failed to load mesh data", "Error")
            return
        end

        local function findMeshAndTexture(node)
            if not node or type(node) ~= "table" then return nil end
            local props = node.Props
            if props then
                local meshId = props.MeshId or props.MeshID
                if meshId and meshId ~= "" then
                    local textureId = props.TextureId or props.TextureID or ""
                    local scale = props.Scale or Vector3.new(0.045, 0.045, 0.045)
                    local size = props.Size or Vector3.new(0.045, 0.045, 0.045)
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

        local okInv, InventoryModule = pcall(function() return require(game.ReplicatedStorage.Modules.InventoryModule) end)
        local okPD, ProfileData = pcall(function() return require(game.ReplicatedStorage.Modules.ProfileData) end)
        local okS, Sync = pcall(function() return require(game.ReplicatedStorage.Database.Sync) end)
        if not (okInv and okPD and okS) then
            notify("Unlock All", "Could not load game modules", "Error")
            return
        end

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

        pcall(function()
            local UpdateInventory = filtergc("table", { Keys = { "UpdateInventory" } }, true).UpdateInventory
            for key, func in pairs(getgc()) do
                if typeof(func) == "function" and islclosure(func) and debug.info(func, "l") == 122 and #debug.getupvalues(func) == 2 then
                    UpdateInventory(debug.getupvalue(func, 2), InventoryModule.MyInventory)
                end
            end
        end)

        local function isMurder()
            local success, result = pcall(function()
                for _, v in pairs(LocalPlayer.Character and LocalPlayer.Character:GetChildren() or {}) do
                    if typeof(v) == "Instance" and v:IsA("Tool") and v:GetAttribute("ItemType") == "Knife" then return true end
                end
                for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if typeof(v) == "Instance" and v:IsA("Tool") and v:GetAttribute("ItemType") == "Knife" then return true end
                end
                return false
            end)
            if success then return result end
            return false
        end

        bind(workspace.ChildAdded, function(ch)
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

        notify("Unlock All", "Unlock All applied! (client-side visual)", "Success", 4)
        -- Continuous mesh apply loop
        while not isDead() do
            local char = LocalPlayer.Character
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
            task.wait(1)
        end
    end)
end
Mono.unlockAll = unlockAll

-- ============================================================
-- SERVER HOP / REJOIN
-- ============================================================
local hopFallbackPlace
local function fetchServers(placeId, maxPages, order)
    local out, cursor = {}, nil
    for _ = 1, (maxPages or 4) do
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=" .. (order or "Asc") .. "&limit=100"
        if cursor then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if not ok then break end
        local ok2, d = pcall(function() return HttpService:JSONDecode(res) end)
        if not (ok2 and d and d.data) then break end
        for _, sv in ipairs(d.data) do out[#out + 1] = sv end
        cursor = d.nextPageCursor
        if not cursor then break end
    end
    return out
end

bind(TeleportService.TeleportInitFailed, function(plr)
    if plr == LocalPlayer then Mono.hopFailed = true end
end)

local function hopServers(placeId, excludeJob, fallbackTeleport)
    task.spawn(function()
        local function gather(all, minFree)
            local t = {}
            for _, sv in ipairs(all) do
                if sv.id and sv.id ~= excludeJob
                    and ((sv.maxPlayers or 0) - (sv.playing or 0)) >= minFree then t[#t + 1] = sv end
            end
            return t
        end
        local all = fetchServers(placeId, 2, "Desc")
        local cand = gather(all, 2)
        if #cand == 0 then
            all = fetchServers(placeId, 3, "Asc")
            cand = gather(all, 2)
        end
        if #cand == 0 then cand = gather(all, 1) end
        if #cand == 0 then
            if fallbackTeleport then
                notify("Server", "Letting Roblox pick a server...", "Info")
                pcall(function() TeleportService:Teleport(placeId, LocalPlayer) end)
            else
                notify("Server", "No joinable servers came back, try again in a moment", "Warning", 5)
            end
            return
        end
        table.sort(cand, function(a, b) return (a.playing or 0) > (b.playing or 0) end)
        local top = math.min(#cand, 15)
        for i = top, 2, -1 do local j = math.random(1, i); cand[i], cand[j] = cand[j], cand[i] end
        hopFallbackPlace = placeId
        for i = 1, math.min(#cand, 4) do
            Mono.hopFailed = false
            local sv = cand[i]
            pcall(function() TeleportService:TeleportToPlaceInstance(placeId, sv.id, LocalPlayer) end)
            local t0 = os.clock()
            while os.clock() - t0 < 7 and not Mono.hopFailed do task.wait(0.2) end
            if not Mono.hopFailed then return end
            notify("Server", "That server filled up, trying another...", "Info", 2)
        end
        hopFallbackPlace = nil
        notify("Server", "Every server tried was full, try again in a moment", "Warning", 5)
    end)
end
Mono.hopServers = hopServers

local function rejoin()
    notify("Server", "Rejoining...", "Info")
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
end
Mono.rejoin = rejoin

local function serverHop()
    notify("Server", "Finding a server...", "Info")
    hopServers(game.PlaceId, game.JobId, true)
end
Mono.serverHop = serverHop

bind(TeleportService.TeleportInitFailed, function()
    local p = hopFallbackPlace
    if not p then return end
    hopFallbackPlace = nil
    notify("Server", "That server was full, letting Roblox pick one", "Info")
    pcall(function() TeleportService:Teleport(p, LocalPlayer) end)
end)

-- ============================================================
-- FPS CAP
-- ============================================================
Mono.origFps = (function()
    local ok, v = pcall(function()
        return UserSettings():GetService("UserGameSettings").FramerateCap
    end)
    if ok and type(v) == "number" and v >= 0 then return math.floor(v + 0.5) end
    if typeof(getfpscap) == "function" then
        local ok2, v2 = pcall(getfpscap)
        if ok2 and type(v2) == "number" and v2 >= 0 then return math.floor(v2 + 0.5) end
    end
    return 0
end)()

local fpsCapValue = 60
local function applyFpsCap(v)
    if typeof(setfpscap) == "function" then pcall(setfpscap, v) end
end
Mono.applyFpsCap = applyFpsCap
Mono.fpsCapValue = fpsCapValue

-- ============================================================
-- KILL ALL (murderer, WindUI-style with Mono's knife kill)
-- ============================================================
local killAllActive = false
local function killAllLoop()
    while killAllActive do
        if myRole() == "Murderer" then
            local knife = findWeapon("Knife")
            local ev = knife and knife:FindFirstChild("Events")
            if ev then
                equip(knife)
                for _, p in ipairs(Mono.plrs) do
                    if p ~= LocalPlayer and alive(p) and roleOf(p) ~= "Murderer" then
                        knifeKill(ev, p.Character)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end
local function setKillAll(on)
    killAllActive = on
    if on then task.spawn(killAllLoop) end
end

-- ============================================================
-- SHOOT BUTTON (mobile / quick fire, WindUI port)
-- ============================================================
local shootBtn, shootBtnFrame, shootBtnGui, shootBtnActive = nil, nil, nil, false
local shootBtnSize = 50
local function removeShootButton()
    if shootBtnGui then pcall(function() shootBtnGui:Destroy() end) end
    shootBtn, shootBtnFrame, shootBtnGui = nil, nil, nil
    shootBtnActive = false
end
local function createShootButton()
    if shootBtnGui then return end
    shootBtnGui = Instance.new("ScreenGui")
    shootBtnGui.Name = rnd()
    shootBtnGui.Parent = mountTarget
    shootBtnGui.ResetOnSpawn = false
    shootBtnGui.DisplayOrder = 999
    protect(shootBtnGui)
    trackGui(shootBtnGui)

    shootBtnFrame = Instance.new("Frame")
    shootBtnFrame.Size = UDim2.new(0, shootBtnSize, 0, shootBtnSize)
    shootBtnFrame.Position = UDim2.new(1, -shootBtnSize - 20, 0.5, -shootBtnSize / 2)
    shootBtnFrame.AnchorPoint = Vector2.new(1, 0.5)
    shootBtnFrame.BackgroundTransparency = 1
    shootBtnFrame.ZIndex = 100

    shootBtn = Instance.new("TextButton")
    shootBtn.Size = UDim2.new(1, 0, 1, 0)
    shootBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
    shootBtn.Text = "Shoot"
    shootBtn.TextSize = 14
    shootBtn.Font = Enum.Font.GothamBold
    shootBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    shootBtn.ZIndex = 101
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.3, 0)
    corner.Parent = shootBtn

    shootBtn.MouseButton1Click:Connect(function()
        if not LocalPlayer.Character then return end
        local m = findMurderer()
        if not (m and m.Character) then return end
        local gun = findWeapon("Gun")
        if gun and not LocalPlayer.Character:FindFirstChild("Gun") then
            pcall(function() gun.Parent = LocalPlayer.Character end)
        end
        local targetRoot = getHRP(m.Character)
        local localRoot = getHRP(LocalPlayer.Character)
        if targetRoot and localRoot then
            Mono.markSelfTP()
            localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -4)
        end
        if isGunRole(myRole()) then
            snapShot(m)
        end
    end)

    shootBtn.Parent = shootBtnFrame
    shootBtnFrame.Parent = shootBtnGui
    shootBtnActive = true
end
Mono.createShootButton = createShootButton
Mono.removeShootButton = removeShootButton

print("[LightHub] Part 4 loaded")


-- ============================================================
-- LIGHT HUB MM2 - PART 5: GUI (AIRFLOW) + INIT
-- ============================================================

local Window = AirFlow:CreateWindow({
    Title = "Light Hub MM2",
    Description = "Murder Mystery 2",
})
_G.LightHubWindow = Window

-- Helper to safely reference the window gui for ESP occlusion
do
    local ok, gui = pcall(function()
        -- AIRFLOW stores the ScreenGui on the window table in various ways
        return Window._gui or Window.gui or (Window.ScreenGui)
    end)
    if ok and gui then
        Window._gui = gui
    end
end

-- ============================================================
-- TABS
-- ============================================================
local CombatTab     = Window:Tab({ Title = "Combat",     Icon = "crosshair" })
local MovementTab   = Window:Tab({ Title = "Movement",   Icon = "user" })
local EspTab        = Window:Tab({ Title = "ESP",        Icon = "eye" })
local FarmTab       = Window:Tab({ Title = "AutoFarm",   Icon = "coins" })
local TeleportTab   = Window:Tab({ Title = "Teleport",   Icon = "map-pin" })
local SafetyTab     = Window:Tab({ Title = "Safety",     Icon = "shield" })
local MiscTab       = Window:Tab({ Title = "Misc",       Icon = "wrench" })
local ServerTab     = Window:Tab({ Title = "Server",     Icon = "server" })

-- ============================================================
-- COMBAT TAB
-- ============================================================
CombatTab:Section("Murderer + Sheriff")

CombatTab:Toggle({
    Title = "Auto Kill",
    Description = "Murderer: knifes everyone alive. Sheriff: snap-shots the murderer.",
    Default = false,
    Callback = function(v) flags.autoKill = v end,
})

CombatTab:Toggle({
    Title = "Silent Aim",
    Description = "Shots and throws redirect to closest player in FOV (hook method, fallback if unavailable).",
    Default = false,
    Callback = function(v) flags.silentAim = v end,
})

CombatTab:Toggle({
    Title = "Aimbot",
    Description = "Snaps camera to closest enemy in FOV.",
    Default = false,
    Callback = function(v) flags.aimbot = v end,
})

CombatTab:Slider({
    Title = "FOV Radius",
    Description = "Aim radius for silent aim / aimbot.",
    Min = 40, Max = 400, Default = 120,
    Callback = function(v) aimFov = v end,
})

CombatTab:Toggle({
    Title = "Show FOV Circle",
    Description = "Draws the aim radius.",
    Default = false,
    Callback = function(v) flags.showFov = v end,
})

CombatTab:Section("Sheriff")

CombatTab:Toggle({
    Title = "Gun Through Walls",
    Description = "Shots ignore geometry.",
    Default = false,
    Callback = function(v) flags.gunWalls = v end,
})

CombatTab:Toggle({
    Title = "Dropped Gun ESP",
    Description = "Highlights the sheriff gun on the ground.",
    Default = false,
    Callback = function(v) flags.gunEsp = v end,
})

CombatTab:Toggle({
    Title = "Gun ESP Distance",
    Description = "Adds distance label to dropped gun.",
    Default = false,
    Callback = function(v) flags.gunEspDist = v end,
})

CombatTab:Toggle({
    Title = "Auto Grab Gun",
    Description = "Grabs dropped gun the moment it appears.",
    Default = false,
    Callback = function(v) flags.autoGun = v end,
})

CombatTab:Button({
    Title = "Grab Gun Now",
    Description = "One-off grab of the dropped gun.",
    Callback = function()
        if findWeapon("Gun") then notify("Gun System", "You already have a gun", "Info") return end
        if not (droppedGun or findDroppedGun()) then notify("Gun System", "No dropped gun on the map", "Warning") return end
        grabGunOnce()
    end,
})

CombatTab:Button({
    Title = "Grab Gun & Shoot Murderer",
    Description = "Grabs the gun and snap-shots the murderer.",
    Callback = grabGunAndShoot,
})

CombatTab:Section("Murderer")

CombatTab:Toggle({
    Title = "Knife Through Walls",
    Description = "Thrown knives ignore geometry.",
    Default = false,
    Callback = function(v) flags.knifeWalls = v end,
})

CombatTab:Toggle({
    Title = "Instant Knife Throw",
    Description = "Skips wind up and flight time.",
    Default = false,
    Callback = function(v) flags.instantKnife = v end,
})

CombatTab:Toggle({
    Title = "Kill All",
    Description = "Continuously knifes all alive non-murderers.",
    Default = false,
    Callback = function(v) setKillAll(v) end,
})

-- ============================================================
-- MOVEMENT TAB
-- ============================================================
MovementTab:Section("Movement")

MovementTab:Toggle({
    Title = "Fly",
    Description = "Free movement relative to camera (WASD + Space/Ctrl).",
    Default = false,
    Callback = function(v)
        flags.fly = v
        if v then startFly() else stopFly() end
    end,
})

MovementTab:Slider({
    Title = "Fly Speed",
    Min = 20, Max = 250, Default = 60,
    Callback = function(v) flags.flySpeed = v end,
})

MovementTab:Toggle({
    Title = "Noclip",
    Description = "Walk through walls.",
    Default = false,
    Callback = function(v)
        flags.noclip = v
        if not v then
            local ch = LocalPlayer.Character
            Mono.recollide(ch and ch:FindFirstChildOfClass("Humanoid"))
        end
    end,
})

MovementTab:Toggle({
    Title = "Infinite Jump",
    Description = "Jump again any time, including mid-air.",
    Default = false,
    Callback = function(v) flags.infJump = v end,
})

MovementTab:Toggle({
    Title = "Unlock Camera",
    Description = "Removes zoom limit; passes through walls with noclip.",
    Default = false,
    Callback = function(v) flags.unlockCam = v; setUnlockCam(v) end,
})

MovementTab:Section("Stats")

MovementTab:Toggle({
    Title = "Walk Speed",
    Description = "Enable custom walk speed.",
    Default = false,
    Callback = function(v) flags.walkSpeedOn = v; applyWalkSpeed() end,
})

MovementTab:Slider({
    Title = "Walk Speed Value",
    Min = 16, Max = 120, Default = 16,
    Callback = function(v) flags.walkSpeed = v; if flags.walkSpeedOn then applyWalkSpeed() end end,
})

MovementTab:Toggle({
    Title = "Jump Power",
    Description = "Enable custom jump power.",
    Default = false,
    Callback = function(v) flags.jumpPowerOn = v; applyJumpPower() end,
})

MovementTab:Slider({
    Title = "Jump Power Value",
    Min = 50, Max = 250, Default = 50,
    Callback = function(v) flags.jumpPower = v; if flags.jumpPowerOn then applyJumpPower() end end,
})

MovementTab:Button({
    Title = "Reset Character",
    Description = "Kills you so you respawn.",
    Callback = function()
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.Health = 0 else notify("Character", "No character right now", "Warning") end
    end,
})

-- ============================================================
-- ESP TAB
-- ============================================================
EspTab:Section("Player ESP")

EspTab:Toggle({
    Title = "Nametag ESP",
    Description = "Name, distance and coins above each player.",
    Default = false,
    Callback = function(v)
        flags.espNames = v
        if not v then pcall(Mono.setRobloxNames, false) end
    end,
})

EspTab:Toggle({
    Title = "Box ESP",
    Description = "2D rectangle around each player.",
    Default = false,
    Callback = function(v) flags.espBox = v end,
})

EspTab:Toggle({
    Title = "3D Box ESP",
    Description = "World-space box that tracks pose.",
    Default = false,
    Callback = function(v) flags.espBox3D = v end,
})

EspTab:Toggle({
    Title = "Chams",
    Description = "Through-wall outline on each player.",
    Default = false,
    Callback = function(v) flags.espChams = v end,
})

EspTab:Toggle({
    Title = "Fill Body",
    Description = "Fills chams body (requires Chams).",
    Default = false,
    Callback = function(v) flags.espFill = v end,
})

EspTab:Toggle({
    Title = "Role Tags",
    Description = "Colors ESP by role, shows [M] [S] [I].",
    Default = false,
    Callback = function(v) flags.espRoleTags = v end,
})

EspTab:Toggle({
    Title = "Avatar Icons",
    Description = "Shows headshot on nametag.",
    Default = false,
    Callback = function(v) flags.espAvatar = v end,
})

EspTab:Toggle({
    Title = "Tracers",
    Description = "Line from origin to each player.",
    Default = false,
    Callback = function(v) flags.espTracers = v end,
})

EspTab:Dropdown({
    Title = "Tracer Origin",
    Values = { "Bottom", "Bottom Left", "Bottom Right", "Center", "Top", "Mouse" },
    Default = "Bottom",
    Callback = function(v) flags.espTracerFrom = v end,
})

EspTab:Toggle({
    Title = "Skeleton ESP",
    Description = "Bone lines over each player.",
    Default = false,
    Callback = function(v) flags.espSkeleton = v end,
})

EspTab:Toggle({
    Title = "ESP Distance Limit",
    Description = "Limit nametag/tracer range.",
    Default = false,
    Callback = function(v) flags.espMaxDist = v and (Mono.espLimit or 250) or 0 end,
})

EspTab:Slider({
    Title = "Max Distance",
    Min = 25, Max = 1000, Default = 250,
    Callback = function(v) Mono.espLimit = v; if flags.espMaxDist > 0 then flags.espMaxDist = v end end,
})

EspTab:Section("World ESP")

EspTab:Toggle({
    Title = "Coin ESP",
    Description = "Highlights uncollected coins.",
    Default = false,
    Callback = function(v) flags.coinEsp = v end,
})

EspTab:Toggle({
    Title = "Trap ESP",
    Description = "Shows murderer traps through walls.",
    Default = false,
    Callback = function(v) flags.trapEsp = v end,
})

EspTab:Section("Trails & Render")

EspTab:Toggle({
    Title = "Footstep Trails",
    Description = "Colored footprints behind every player.",
    Default = false,
    Callback = function(v)
        flags.footstepTrails = v
        if not v and Mono.FS then Mono.FS.clear() end
    end,
})

EspTab:Slider({
    Title = "Trail Length (sec)",
    Min = 3, Max = 30, Default = 8,
    Callback = function(v) if Mono.FS then Mono.FS.life = v end end,
})

EspTab:Toggle({
    Title = "Include My Own",
    Description = "Show your own footprints.",
    Default = false,
    Callback = function(v) flags.footMine = v end,
})

EspTab:Toggle({
    Title = "Fullbright",
    Description = "Removes darkness.",
    Default = false,
    Callback = function(v) flags.fullbright = v; setFullbright(v) end,
})

EspTab:Toggle({
    Title = "FPS Boost",
    Description = "Strips textures, shadows, particles.",
    Default = false,
    Callback = function(v) flags.fpsBoost = v; setFPSBoost(v) end,
})

EspTab:Toggle({
    Title = "Field of View",
    Description = "Widen camera view.",
    Default = false,
    Callback = function(v) flags.fovOn = v; applyFov(v and flags.fovValue or 70) end,
})

EspTab:Slider({
    Title = "FOV Value",
    Min = 70, Max = 120, Default = 70,
    Callback = function(v) flags.fovValue = v; if flags.fovOn then applyFov(v) end end,
})

-- ============================================================
-- AUTOFARM TAB
-- ============================================================
FarmTab:Section("Coins")

FarmTab:Toggle({
    Title = "Auto Collect Coins",
    Description = "Walks you coin to coin at normal speed.",
    Default = false,
    Callback = function(v)
        flags.autoCoins = v
        if v then
            if coinBagFull then notify("AutoFarm", "Coin bag is already full", "Warning")
            else notify("AutoFarm", "Auto collect on", "Success") end
        end
    end,
})

FarmTab:Button({
    Title = "Teleport To Nearest Coin",
    Description = "One hop to closest coin.",
    Callback = function()
        local hrp = getHRP(LocalPlayer.Character)
        if not hrp then notify("Teleport", "No character", "Warning") return end
        local pool = coinCache
        if #pool == 0 then pool = freshCoins() end
        local best, bd
        for _, c in ipairs(pool) do
            if c.Parent and not coinTaken(c) then
                local d = (c.Position - hrp.Position).Magnitude
                if not bd or d < bd then bd, best = d, c end
            end
        end
        if not best then notify("Teleport", "No coins on map", "Info") return end
        if tpTo(best.Position) then notify("Teleport", "Teleported to coin", "Success")
        else notify("Teleport", "No character", "Warning") end
    end,
})

FarmTab:Section("Events")

FarmTab:Toggle({
    Title = "Rare Egg AutoFarm",
    Description = "Teleports to and collects eggs.",
    Default = false,
    Callback = function(v) flags.eggFarm = v; setEggFarm(v) end,
})

FarmTab:Button({
    Title = "Beach Ball AutoFarm",
    Description = "Starts external beach ball farm.",
    Callback = startBeachBallFarm,
})

-- ============================================================
-- TELEPORT TAB
-- ============================================================
TeleportTab:Section("Player")

local tpTargetName = nil
local function tpPlayerList()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then t[#t + 1] = p.Name end
    end
    if #t == 0 then t[1] = "(nobody else here)" end
    return t
end

TeleportTab:Dropdown({
    Title = "Target Player",
    Values = tpPlayerList(),
    Default = "",
    Callback = function(v) tpTargetName = v end,
})

TeleportTab:Button({
    Title = "Teleport To Player",
    Description = "Drops you above the selected player.",
    Callback = function()
        local p = resolvePlayer(tpTargetName)
        if not p then notify("Teleport", "Pick a player first", "Warning") return end
        local ch = p.Character; local h = ch and ch:FindFirstChildOfClass("Humanoid")
        local root = (h and h.RootPart) or getHRP(ch)
        if not root then notify("Teleport", (p.DisplayName or p.Name) .. " has no character", "Warning") return end
        if tpTo(root.Position) then notify("Teleport", "Teleported to " .. (p.DisplayName or p.Name), "Success")
        else notify("Teleport", "No character", "Warning") end
    end,
})

TeleportTab:Button({
    Title = "Refresh Player List",
    Description = "Refresh the dropdown values.",
    Callback = function()
        -- AIRFLOW dropdowns may support Refresh; recreate if not
        notify("Teleport", "Re-open the dropdown to see new players", "Info")
    end,
})

TeleportTab:Section("Fling")

TeleportTab:Button({
    Title = "Fling Player",
    Description = "Launches the selected player using physics.",
    Callback = function()
        local p = resolvePlayer(tpTargetName)
        if not p then notify("Fling", "Pick a player first", "Warning") return end
        if not (p.Character and getHRP(p.Character)) then
            notify("Fling", (p.DisplayName or p.Name) .. " has no character", "Warning") return
        end
        notify("Fling", "Flinging " .. (p.DisplayName or p.Name), "Info")
        task.spawn(function()
            local ok, why = flingPlayer(p)
            if not ok and why then notify("Fling", why, "Warning", 4) end
        end)
    end,
})

TeleportTab:Button({
    Title = "Fling All Players",
    Description = "Flings everyone, then puts you back.",
    Callback = flingAll,
})

TeleportTab:Toggle({
    Title = "Auto Fling Murderer",
    Description = "Flings murderer on sight, repeatedly.",
    Default = false,
    Callback = function(v) flags.autoFlingMurderer = v end,
})

TeleportTab:Toggle({
    Title = "Auto Fling Sheriff",
    Description = "Flings sheriff/hero on sight, repeatedly.",
    Default = false,
    Callback = function(v) flags.autoFlingSheriff = v end,
})

TeleportTab:Slider({
    Title = "Fling Power",
    Min = 1000, Max = 50000, Default = 10000,
    Callback = function(v) flags.flingPower = v end,
})

TeleportTab:Slider({
    Title = "Fling Duration (sec)",
    Min = 1, Max = 10, Default = 1,
    Callback = function(v) flags.flingSeconds = v end,
})

TeleportTab:Section("Locations")

TeleportTab:Button({
    Title = "Teleport to Lobby",
    Description = "Teleports to lobby spawn.",
    Callback = function()
        local lobby = workspace:FindFirstChild("Lobby")
        if not lobby then notify("Teleport", "Lobby not found", "Error") return end
        local spawnPoint = lobby:FindFirstChild("SpawnPoint") or lobby:FindFirstChildOfClass("SpawnLocation")
        if not spawnPoint then spawnPoint = lobby:FindFirstChildWhichIsA("BasePart") or lobby end
        if tpTo(spawnPoint.Position) then notify("Teleport", "Teleported to Lobby", "Success") end
    end,
})

TeleportTab:Button({
    Title = "Teleport to Murderer",
    Description = "TP to the murderer.",
    Callback = function()
        local m = findMurderer()
        if not (m and m.Character and getHRP(m.Character)) then
            notify("Teleport", "Murderer not found", "Warning") return
        end
        if tpTo(getHRP(m.Character).Position) then
            notify("Teleport", "Teleported to murderer", "Success")
        end
    end,
})

TeleportTab:Button({
    Title = "Teleport to Sheriff",
    Description = "TP to the sheriff/hero.",
    Callback = function()
        for _, p in ipairs(Mono.plrs) do
            if p ~= LocalPlayer and isGunRole(roleOf(p)) and alive(p) and getHRP(p.Character) then
                if tpTo(getHRP(p.Character).Position) then
                    notify("Teleport", "Teleported to " .. (p.DisplayName or p.Name), "Success")
                    return
                end
            end
        end
        notify("Teleport", "Sheriff not found", "Warning")
    end,
})

-- ============================================================
-- SAFETY TAB
-- ============================================================
SafetyTab:Section("Protection")

SafetyTab:Toggle({
    Title = "Anti Fling",
    Description = "Blocks other exploiters from flinging you.",
    Default = false,
    Callback = function(v)
        flags.antiFling = v
        if not v and Mono.antiFlingRestore then Mono.antiFlingRestore() end
    end,
})

SafetyTab:Toggle({
    Title = "Anti Trap",
    Description = "Keeps speed when walking into a trap.",
    Default = false,
    Callback = function(v) flags.antiTrap = v end,
})

SafetyTab:Toggle({
    Title = "Murderer Evasion",
    Description = "Auto-runs away when murderer gets close.",
    Default = false,
    Callback = function(v) flags.evasion = v; setEvasion(v) end,
})

SafetyTab:Slider({
    Title = "Evasion Radius",
    Min = 15, Max = 100, Default = 35,
    Callback = function(v) flags.evasionDist = v end,
})

SafetyTab:Toggle({
    Title = "Predictive Gun Dodge",
    Description = "Murderer only: sidesteps when a gun aims at you.",
    Default = false,
    Callback = function(v) flags.predictiveDodge = v; setDodge(v) end,
})

SafetyTab:Section("Awareness")

SafetyTab:Toggle({
    Title = "Murderer Notify",
    Description = "Warns when murderer is within 50 studs.",
    Default = false,
    Callback = function(v) flags.murdererNotify = v end,
})

SafetyTab:Toggle({
    Title = "Kill Feed",
    Description = "Notifies of every elimination.",
    Default = false,
    Callback = function(v) flags.killFeed = v end,
})

SafetyTab:Toggle({
    Title = "Anti AFK",
    Description = "Stops the 20 minute idle kick.",
    Default = false,
    Callback = function(v) flags.antiAfk = v end,
})

SafetyTab:Toggle({
    Title = "Auto Report Murderer",
    Description = "Reports the murderer for cheating every 60s.",
    Default = false,
    Callback = function(v) flags.autoReport = v end,
})

SafetyTab:Section("Hitbox")

SafetyTab:Toggle({
    Title = "Hitbox Expander",
    Description = "Visual hitbox boxes on other players.",
    Default = false,
    Callback = function(v) flags.hitboxEnabled = v; setHitbox(v) end,
})

SafetyTab:Slider({
    Title = "Hitbox Size",
    Min = 1, Max = 20, Default = 5,
    Callback = function(v) flags.hitboxSize = v end,
})

-- ============================================================
-- MISC TAB
-- ============================================================
MiscTab:Section("Visual Unlocks")

MiscTab:Button({
    Title = "Unlock All",
    Description = "Client-side unlock all knives/guns (visual).",
    Callback = unlockAll,
})

MiscTab:Section("Quick Actions")

MiscTab:Button({
    Title = "Toggle Shoot Button",
    Description = "Mobile/quick-fire shoot button.",
    Callback = function()
        if shootBtnActive then removeShootButton() else createShootButton() end
    end,
})

MiscTab:Slider({
    Title = "Shoot Button Size",
    Min = 10, Max = 100, Default = 50,
    Callback = function(v)
        shootBtnSize = v
        if shootBtnActive then removeShootButton(); createShootButton() end
    end,
})

MiscTab:Section("Performance")

MiscTab:Toggle({
    Title = "FPS Cap",
    Description = "Limits frame rate to save battery.",
    Default = false,
    Callback = function(v)
        applyFpsCap(v and fpsCapValue or (Mono.origFps or 0))
    end,
})

MiscTab:Slider({
    Title = "FPS Limit (0 = unlimited)",
    Min = 0, Max = 360, Default = 60,
    Callback = function(v)
        fpsCapValue = v
        if v > 0 and v < 5 then fpsCapValue = 5 end
        applyFpsCap(fpsCapValue)
    end,
})

-- ============================================================
-- SERVER TAB
-- ============================================================
ServerTab:Section("Server")

ServerTab:Button({
    Title = "Rejoin",
    Description = "Rejoins this same server.",
    Callback = rejoin,
})

ServerTab:Button({
    Title = "Server Hop",
    Description = "Joins the busiest server with room.",
    Callback = serverHop,
})

local serverInfoLabel = ServerTab:Label({ Text = "Loading server info..." })

task.spawn(function()
    while not isDead() do
        local ok, ping = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
        end)
        local up = math.floor(workspace.DistributedGameTime)
        local txt = string.format("Players: %d/%d  |  Uptime: %dh %dm %ds  |  Ping: %s",
            #Players:GetPlayers(), Players.MaxPlayers,
            math.floor(up / 3600), math.floor((up % 3600) / 60), up % 60,
            ok and ping or "?")
        pcall(function() serverInfoLabel:Set(txt) end)
        task.wait(1)
    end
end)

-- ============================================================
-- UNLOAD
-- ============================================================
local function unload()
    if Unloaded then return end
    Unloaded = true

    -- Turn off all toggles
    for k in pairs(flags) do
        if type(flags[k]) == "boolean" then flags[k] = false end
    end

    pcall(function() Mono.setRobloxNames(false) end)
    pcall(function() setCamThruWalls(false) end)
    pcall(function() setUnlockCam(false) end)
    pcall(function() stopFly() end)
    pcall(function() setFullbright(false) end)
    pcall(function() setFPSBoost(false) end)
    pcall(function() if Mono.antiFlingRestore then Mono.antiFlingRestore() end end)
    pcall(function() setHitbox(false) end)
    pcall(function() setEvasion(false) end)
    pcall(function() setDodge(false) end)
    pcall(function() setKillAll(false) end)
    pcall(function() setEggFarm(false) end)
    pcall(function() removeShootButton() end)
    pcall(function() applyFov(70) end)
    pcall(function() applyFpsCap(Mono.origFps or 0) end)
    pcall(function()
        local ch = LocalPlayer.Character
        Mono.recollide(ch and ch:FindFirstChildOfClass("Humanoid"), true)
    end)
    pcall(function() Mono.clearDrawn() end)
    pcall(function() if typeof(cleardrawcache) == "function" then cleardrawcache() end end)

    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    table.clear(conns)

    for _, g in ipairs(TRACKED) do pcall(function() g:Destroy() end) end
    table.clear(TRACKED)

    pcall(function() EspGui:Destroy() end)
    pcall(function() FovCircle:Destroy() end)

    notify("Light Hub", "Unloaded. Re-run the script to load again.", "Info", 4)
    print("[LightHub] Unloaded")
end
_G.LightHubUnload = unload

-- Notify on load
task.delay(0.5, function()
    notify("Light Hub MM2", "Loaded! Check the tabs for features.", "Success", 4)
end)

print("[LightHub] Part 5 loaded - GUI ready")
