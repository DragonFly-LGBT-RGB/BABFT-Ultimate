-- BABFT ULTIMATE HUB v1.0 FIXED - Исправлено создание UI
-- Фикс для инжекторов где CoreGui заблокирован
-- Добавлены дебаг принты и fallback на PlayerGui

print("[BABFT] Starting Ultimate Hub v1.0 FIXED...")
if not game:IsLoaded() then
    print("[BABFT] Waiting for game to load...")
    game.Loaded:Wait()
end

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end
print("[BABFT] LocalPlayer:", LocalPlayer.Name)

local Camera = Workspace.CurrentCamera

-- Global flags
getgenv().BABFT_Running = true
getgenv().BABFT_Ultimate_Loaded = true
print("[BABFT] Global flags set")

-- Robust GUI parent getter (FIXED)
local function GetGuiParent()
    -- Try gethui (most executors)
    if gethui then
        local success, result = pcall(gethui)
        if success and result then
            print("[BABFT] Using gethui() parent")
            return result
        end
    end
    -- Try syn protect_gui
    if syn and syn.protect_gui then
        print("[BABFT] Using syn.protect_gui")
        local sg = Instance.new("ScreenGui")
        pcall(function() syn.protect_gui(sg) end)
        sg.Parent = game:GetService("CoreGui")
        return sg.Parent
    end
    -- Try CoreGui
    local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if success and coreGui then
        print("[BABFT] Using CoreGui parent")
        return coreGui
    end
    -- Fallback to PlayerGui (always works)
    print("[BABFT] Fallback to PlayerGui")
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- Clean old UI (protected)
pcall(function()
    local parent = GetGuiParent()
    -- Check in CoreGui
    if game:GetService("CoreGui"):FindFirstChild("BABFT_Ultimate_Hub_v1") then
        game:GetService("CoreGui")["BABFT_Ultimate_Hub_v1"]:Destroy()
        print("[BABFT] Destroyed old CoreGui UI")
    end
    -- Check in PlayerGui
    if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("BABFT_Ultimate_Hub_v1") then
        LocalPlayer.PlayerGui["BABFT_Ultimate_Hub_v1"]:Destroy()
        print("[BABFT] Destroyed old PlayerGui UI")
    end
    -- Check in gethui
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui and hui:FindFirstChild("BABFT_Ultimate_Hub_v1") then
            hui["BABFT_Ultimate_Hub_v1"]:Destroy()
            print("[BABFT] Destroyed old gethui UI")
        end
    end
end)

print("[BABFT] Old UI cleaned")

-- State (same as before)
local State = {
    AutoFarm = false,
    FarmMethod = "Tween",
    TargetMode = "All Stages",
    FarmSpeed = 2.5,
    AutoReset = true,
    AutoClaim = true,
    AntiAFK = true,
    Fly = false,
    FlySpeed = 80,
    Noclip = false,
    WalkSpeed = 16,
    JumpPower = 50,
    InfJump = false,
    GodMode = false,
    Platform = false,
    Fullbright = false,
    NoFog = false,
    ESP = false,
    ESPChest = false,
    FOV = 70,
    ChestType = "Common Chest",
    BuyAmount = 1,
    BlackHole = false,
    BH_Radius = 35,
    BH_Power = 60,
}

local function getChar() return LocalPlayer.Character end
local function getHRP() local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=getChar() return c and c:FindFirstChildOfClass("Humanoid") end

local TargetLocations = {
    ["Stage 1"] = CFrame.new(-51.5, 65, 1369),
    ["Stage 2"] = CFrame.new(-51.5, 65, 2139),
    ["Stage 3"] = CFrame.new(-51.5, 65, 2909),
    ["Stage 4"] = CFrame.new(-51.5, 65, 3679),
    ["Stage 5"] = CFrame.new(-51.5, 65, 4449),
    ["Stage 6"] = CFrame.new(-51.5, 65, 5219),
    ["Stage 7"] = CFrame.new(-51.5, 65, 5989),
    ["Stage 8"] = CFrame.new(-51.5, 65, 6759),
    ["Stage 9"] = CFrame.new(-51.5, 65, 7529),
    ["Stage 10"] = CFrame.new(-51.5, 65, 8299),
    ["Golden Chest"] = CFrame.new(-54.331871, -345.398346, 9488.60645),
}
local StageSequence = {
    TargetLocations["Stage 1"], TargetLocations["Stage 2"], TargetLocations["Stage 3"],
    TargetLocations["Stage 4"], TargetLocations["Stage 5"], TargetLocations["Stage 6"],
    TargetLocations["Stage 7"], TargetLocations["Stage 8"], TargetLocations["Stage 9"],
    TargetLocations["Stage 10"], TargetLocations["Golden Chest"]
}
local BaseLocations = {
    ["🟢 Green"] = CFrame.new(-479, -10, 294),
    ["⚫ Black"] = CFrame.new(-478, -10, -69),
    ["⚪ White"] = CFrame.new(-50, -10, -495),
    ["🔴 Red"] = CFrame.new(371, -10, -65),
    ["🟡 Yellow"] = CFrame.new(-478, -10, 640),
    ["🔵 Blue"] = CFrame.new(371, -10, 300),
    ["🩷 Pink"] = CFrame.new(371, -10, 647),
    ["🛒 Shop"] = CFrame.new(-0, -10, 200),
    ["🏆 End"] = CFrame.new(-54, -345, 9488),
}

-- Core functions (shortened for fixed version, same logic)
local FarmRunning = false
local FarmThread = nil
local NormalGravity = Workspace.Gravity

local function ClaimReward()
    local success = false
    pcall(function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return end
        for _, gui in ipairs(pg:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, btn in ipairs(gui:GetDescendants()) do
                    if btn:IsA("TextButton") then
                        local t = (btn.Text or ""):lower()
                        local n = btn.Name:lower()
                        if n:find("claim") or n:find("collect") or n:find("reward") or t:find("claim") or t:find("получить") or t:find("забрать") or t:find("get") then
                            pcall(function()
                                if getconnections then
                                    local conns = getconnections(btn.MouseButton1Click)
                                    if conns then for _, c in ipairs(conns) do c:Fire() end end
                                end
                            end)
                            success = true
                            return
                        end
                    end
                end
            end
        end
    end)
    pcall(function()
        if Workspace:FindFirstChild("ClaimRiverResultsGold") then
            Workspace.ClaimRiverResultsGold:FireServer()
            success = true
        end
    end)
    return success
end

local function MoveToCF(cf, method, speed)
    local hrp = getHRP()
    if not hrp then return false end
    if method == "Teleport" then
        hrp.CFrame = cf
        task.wait(0.08)
        hrp.CFrame = cf
        return true
    elseif method == "Darkness" then
        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        hrp.CFrame = cf
        task.wait(speed)
        return true
    else
        local dist = (hrp.Position - cf.Position).Magnitude
        local dur = dist / 350
        dur = math.clamp(dur, 0.15, speed)
        local tween = TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = cf})
        tween:Play()
        local completed = false
        local conn = tween.Completed:Connect(function() completed = true end)
        local start = tick()
        repeat task.wait() until completed or tick()-start > dur+1 or not State.AutoFarm
        if conn then conn:Disconnect() end
        return true
    end
end

local function StartFarm()
    if FarmRunning then return end
    FarmRunning = true
    FarmThread = task.spawn(function()
        while State.AutoFarm and getgenv().BABFT_Running do
            local char = getChar()
            local hrp = getHRP()
            local hum = getHum()
            if not char or not hrp or not hum or hum.Health <=0 then task.wait(0.5) continue end
            Workspace.Gravity = 0
            local targets = {}
            if State.TargetMode == "All Stages" then
                local normalStages = Workspace:FindFirstChild("BoatStages") and Workspace.BoatStages:FindFirstChild("NormalStages")
                if normalStages then
                    for i=1,10 do
                        local cave = normalStages:FindFirstChild("CaveStage"..i)
                        if cave and cave:FindFirstChild("DarknessPart") then
                            table.insert(targets, cave.DarknessPart.CFrame)
                        end
                    end
                    if #targets < 10 then targets = StageSequence else table.insert(targets, TargetLocations["Golden Chest"]) end
                else
                    targets = StageSequence
                end
            else
                if TargetLocations[State.TargetMode] then targets = {TargetLocations[State.TargetMode]} end
            end
            for _, cf in ipairs(targets) do
                if not State.AutoFarm then break end
                if not getHRP() then break end
                MoveToCF(cf, State.FarmMethod, State.FarmSpeed)
                task.wait(0.12)
            end
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local bs = Workspace:FindFirstChild("BoatStages")
                if bs then
                    local ns = bs:FindFirstChild("NormalStages")
                    if ns then
                        local theEnd = ns:FindFirstChild("TheEnd")
                        if theEnd and theEnd:FindFirstChild("GoldenChest") then
                            local chest = theEnd.GoldenChest
                            if chest:FindFirstChild("Trigger") then
                                firetouchinterest(hrp, chest.Trigger, 0) task.wait(0.08) firetouchinterest(hrp, chest.Trigger, 1)
                            end
                        end
                    end
                end
                if Workspace:FindFirstChild("GoldenChest") and Workspace.GoldenChest:FindFirstChild("Collider") then
                    firetouchinterest(hrp, Workspace.GoldenChest.Collider, 0) task.wait(0.05) firetouchinterest(hrp, Workspace.GoldenChest.Collider, 1)
                end
                if Workspace:FindFirstChild("ClaimRiverResultsGold") then Workspace.ClaimRiverResultsGold:FireServer() end
            end)
            task.wait(0.4)
            if State.AutoReset and getHum() then
                local oldChar = getChar()
                pcall(function() getHum().Health = 0 end)
                local st = tick()
                repeat task.wait(0.2) until getChar() ~= oldChar or tick()-st > 7 or not State.AutoFarm
                task.wait(1.2)
            else
                task.wait(0.6)
            end
            Workspace.Gravity = NormalGravity
            if State.AutoClaim then for _=1,8 do if ClaimReward() then break end task.wait(0.4) end end
            task.wait(0.2)
        end
        Workspace.Gravity = NormalGravity
        FarmRunning = false
    end)
end

local function StopFarm()
    State.AutoFarm = false
    if FarmThread then pcall(function() task.cancel(FarmThread) end) FarmThread = nil end
    FarmRunning = false
    Workspace.Gravity = NormalGravity
end

-- ESP
local ESPObjects = {}
local function ClearESP()
    for _, o in ipairs(ESPObjects) do pcall(function() o:Destroy() end) end
    ESPObjects = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("ESPHighlight") then p.Character.ESPHighlight:Destroy() end
        local head = p.Character and p.Character:FindFirstChild("Head")
        if head and head:FindFirstChild("ESPTag") then head.ESPTag:Destroy() end
    end
end
local function CreateESP(part, color, text)
    if not part or not part.Parent then return nil end
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = part
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 2000
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = color
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)
    frame.Parent = billboard
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = frame
    billboard.Parent = part
    table.insert(ESPObjects, billboard)
    return billboard
end
local function UpdateESP()
    ClearESP()
    if not State.ESP then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local hp = hum and math.floor(hum.Health) or "?"
                local gold = 0
                pcall(function()
                    if plr:FindFirstChild("Data") and plr.Data:FindFirstChild("Gold") then gold = plr.Data.Gold.Value
                    elseif plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Gold") then gold = plr.leaderstats.Gold.Value end
                end)
                CreateESP(hrp, Color3.fromRGB(0, 140, 255), plr.DisplayName.."\n❤️ "..hp.." | 💰 "..gold)
                if not plr.Character:FindFirstChild("ESPHighlight") then
                    local hl = Instance.new("Highlight", plr.Character)
                    hl.Name = "ESPHighlight"
                    hl.FillColor = Color3.fromRGB(0, 110, 255)
                    hl.OutlineColor = Color3.fromRGB(255,255,255)
                    hl.FillTransparency = 0.5
                    table.insert(ESPObjects, hl)
                end
            end
        end
    end
end

-- Fly/Noclip
local FlyConn = nil
local function SetupFly()
    if FlyConn then FlyConn:Disconnect() end
    FlyConn = RunService.RenderStepped:Connect(function()
        if State.Fly and getHRP() then
            local hrp = getHRP()
            local moveDir = Vector3.new()
            local camCF = Workspace.CurrentCamera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0,1,0) end
            hrp.Velocity = Vector3.new(0,0,0)
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
            if moveDir.Magnitude >0 then hrp.CFrame = hrp.CFrame + moveDir.Unit * (State.FlySpeed/10) end
        end
    end)
end
SetupFly()

local NoclipConn = nil
local function SetupNoclip()
    if NoclipConn then NoclipConn:Disconnect() end
    NoclipConn = RunService.Stepped:Connect(function()
        if State.Noclip and getChar() then
            for _, part in ipairs(getChar():GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end
    end)
end
SetupNoclip()

UserInputService.JumpRequest:Connect(function()
    if State.InfJump and getHum() then getHum():ChangeState(Enum.HumanoidStateType.Jumping) end
end)

local AntiAFKConn = LocalPlayer.Idled:Connect(function()
    if State.AntiAFK then VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end
end)

-- Black Hole
local BHParts = {}
local function ClearBH() for _, p in ipairs(BHParts) do pcall(function() p:Destroy() end) end BHParts = {} end
task.spawn(function()
    while getgenv().BABFT_Running do
        if State.BlackHole and getHRP() then
            local hrpPos = getHRP().Position
            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(getChar()) then
                    local dist = (part.Position - hrpPos).Magnitude
                    if dist < State.BH_Radius then
                        local angle = math.atan2(part.Position.Z - hrpPos.Z, part.Position.X - hrpPos.X)
                        local newAngle = angle + (State.BH_Power * 0.008)
                        local orbit = dist * 0.85
                        local targetPos = hrpPos + Vector3.new(math.cos(newAngle)*orbit, (hrpPos.Y - part.Position.Y)*0.08, math.sin(newAngle)*orbit)
                        local vel = (targetPos - part.Position)*4 + Vector3.new(0,-3,0)
                        part.Velocity = vel
                        part.AssemblyLinearVelocity = vel
                    end
                end
            end
        end
        task.wait(0.06)
    end
end)

-- Build
local SavedBuild = {}
local function BuildPlatform()
    local hrp = getHRP()
    if not hrp then return end
    local platform = Instance.new("Part")
    platform.Size = Vector3.new(30, 2, 50)
    platform.Position = hrp.Position - Vector3.new(0, 6, 0)
    platform.Anchored = true
    platform.Material = Enum.Material.SmoothPlastic
    platform.Color = Color3.fromRGB(80, 80, 80)
    platform.Name = "BABFT_Ultimate_Platform"
    platform.Parent = Workspace
    Debris:AddItem(platform, 60)
    return platform
end
local function SaveBuild()
    SavedBuild = {}
    local hrp = getHRP()
    if hrp then
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part.Anchored and (part.Position - hrp.Position).Magnitude < 100 then
                if not part:IsDescendantOf(getChar()) then
                    table.insert(SavedBuild, {CFrame = part.CFrame, Size = part.Size, Color = part.Color, Material = part.Material.Name})
                end
            end
        end
    end
    return #SavedBuild
end
local function LoadBuild()
    if #SavedBuild == 0 then return 0 end
    local count = 0
    for _, data in ipairs(SavedBuild) do
        local part = Instance.new("Part")
        part.Size = data.Size
        part.CFrame = data.CFrame
        part.Color = data.Color
        part.Material = Enum.Material[data.Material] or Enum.Material.SmoothPlastic
        part.Anchored = false
        part.Parent = Workspace
        count +=1
        task.wait(0.02)
    end
    return count
end

local ChestMap = {["Common Chest"]="CommonChest",["Uncommon Chest"]="UncommonChest",["Rare Chest"]="RareChest",["Epic Chest"]="EpicChest",["Legendary Chest"]="LegendaryChest"}
local function BuyChest(name, amount)
    local internal = ChestMap[name] or name
    local remote = Workspace:FindFirstChild("ItemToBuy") and Workspace.ItemToBuy:FindFirstChild("BuyItemEvent")
    if remote then
        for i=1, amount do pcall(function() remote:InvokeServer(internal, 1) end) task.wait(0.12) end
        return true
    end
    return false
end
local function TeleportTo(cf) local hrp = getHRP() if not hrp then return end hrp.CFrame = cf task.wait(0.08) hrp.CFrame = cf end
local OldLighting = {Ambient = Lighting.Ambient, FogEnd = Lighting.FogEnd, Brightness = Lighting.Brightness}
local function SetFullbright(enabled)
    if enabled then Lighting.Ambient = Color3.fromRGB(255,255,255) Lighting.FogEnd = 100000 Lighting.Brightness = 2
    else Lighting.Ambient = OldLighting.Ambient Lighting.FogEnd = OldLighting.FogEnd Lighting.Brightness = OldLighting.Brightness end
end
local function ApplyMovement() local hum = getHum() if hum then hum.WalkSpeed = State.WalkSpeed hum.UseJumpPower = true hum.JumpPower = State.JumpPower end end
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5) ApplyMovement() end)

-- ==================== UI FIXED ====================
print("[BABFT] Creating UI...")

local function CreateScreenGuiFixed()
    local parent = GetGuiParent()
    local sg = Instance.new("ScreenGui")
    sg.Name = "BABFT_Ultimate_Hub_v1"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999
    sg.Enabled = true
    sg.Parent = parent
    print("[BABFT] ScreenGui parent:", parent:GetFullName())
    return sg
end

local ScreenGui = CreateScreenGuiFixed()

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 620, 0, 440)
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -220)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(80, 80, 100)
MainStroke.Thickness = 1.2
MainStroke.Transparency = 0.3

print("[BABFT] MainFrame created, Visible:", MainFrame.Visible)

-- Top Bar
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1,0,0,48)
TopBar.BackgroundColor3 = Color3.fromRGB(28,28,36)
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0,14)
local TopBarFix = Instance.new("Frame", TopBar)
TopBarFix.Size = UDim2.new(1,0,0,20)
TopBarFix.Position = UDim2.new(0,0,1,-10)
TopBarFix.BackgroundColor3 = Color3.fromRGB(28,28,36)
TopBarFix.BorderSizePixel = 0
local Gradient = Instance.new("UIGradient", TopBar)
Gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(235,137,53)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,80,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(80,140,255))}
Gradient.Rotation = 15
local TitleLabel = Instance.new("TextLabel", TopBar)
TitleLabel.Size = UDim2.new(1, -120, 1, 0)
TitleLabel.Position = UDim2.new(0, 18, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🚢 BABFT ULTIMATE HUB v1.0 FIXED | Press G to hide"
TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255,70,70)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,8)

local MinBtn = Instance.new("TextButton", TopBar)
MinBtn.Size = UDim2.new(0, 32, 0, 32)
MinBtn.Position = UDim2.new(1, -78, 0, 8)
MinBtn.BackgroundColor3 = Color3.fromRGB(70,70,80)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.BorderSizePixel = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,8)

-- Tab Bar
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(0, 150, 1, -58)
TabBar.Position = UDim2.new(0, 10, 0, 58)
TabBar.BackgroundColor3 = Color3.fromRGB(24,24,32)
TabBar.BorderSizePixel = 0
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0,10)
local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.Padding = UDim.new(0,6)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local TabPadding = Instance.new("UIPadding", TabBar)
TabPadding.PaddingTop = UDim.new(0,8)
TabPadding.PaddingBottom = UDim.new(0,8)
TabPadding.PaddingLeft = UDim.new(0,6)
TabPadding.PaddingRight = UDim.new(0,6)

-- Content
local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -180, 1, -68)
ContentFrame.Position = UDim2.new(0, 170, 0, 58)
ContentFrame.BackgroundColor3 = Color3.fromRGB(24,24,32)
ContentFrame.BorderSizePixel = 0
Instance.new("UICorner", ContentFrame).CornerRadius = UDim.new(0,10)

local Tabs = {}
local CurrentTab = nil

local function CreateTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,38)
    btn.BackgroundColor3 = Color3.fromRGB(34,34,44)
    btn.Text = icon.."  "..name
    btn.TextColor3 = Color3.fromRGB(180,180,190)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(60,60,70)
    stroke.Thickness = 1
    stroke.Transparency = 0.5

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1,0,1,0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = Color3.fromRGB(235,137,53)
    content.CanvasSize = UDim2.new(0,0,0,0)
    content.Visible = false
    content.Parent = ContentFrame
    local layout = Instance.new("UIListLayout", content)
    layout.Padding = UDim.new(0,8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", content)
    pad.PaddingAll = UDim.new(0,12)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 24)
    end)

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            t.Content.Visible = false
            TweenService:Create(t.Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(34,34,44), TextColor3 = Color3.fromRGB(180,180,190)}):Play()
            t.Button.UIStroke.Color = Color3.fromRGB(60,60,70)
        end
        content.Visible = true
        CurrentTab = name
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(235,137,53), TextColor3 = Color3.fromRGB(255,255,255)}):Play()
        stroke.Color = Color3.fromRGB(255,180,100)
    end)

    Tabs[name] = {Button = btn, Content = content}
    if not CurrentTab then
        content.Visible = true
        CurrentTab = name
        btn.BackgroundColor3 = Color3.fromRGB(235,137,53)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        stroke.Color = Color3.fromRGB(255,180,100)
    end
    return content
end

local FarmTab = CreateTab("Farm", "💰")
local BuildTab = CreateTab("Build", "🏗️")
local PlayerTab = CreateTab("Player", "🏃")
local WorldTab = CreateTab("World", "🌍")
local VisualTab = CreateTab("Visual", "👁️")
local EconomyTab = CreateTab("Economy", "🪙")
local FunTab = CreateTab("Fun", "🎉")
local SettingsTab = CreateTab("Settings", "⚙️")

print("[BABFT] Tabs created")

-- UI Components
local function CreateSection(parent, title)
    local sec = Instance.new("Frame")
    sec.Size = UDim2.new(1,0,0,30)
    sec.BackgroundColor3 = Color3.fromRGB(30,30,40)
    sec.BorderSizePixel = 0
    sec.Parent = parent
    Instance.new("UICorner", sec).CornerRadius = UDim.new(0,8)
    local lbl = Instance.new("TextLabel", sec)
    lbl.Size = UDim2.new(1,-12,1,0)
    lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return sec
end

local function CreateToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,36)
    frame.BackgroundColor3 = Color3.fromRGB(32,32,42)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-60,1,0)
    lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220,220,230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local toggleBg = Instance.new("Frame", frame)
    toggleBg.Size = UDim2.new(0,44,0,22)
    toggleBg.Position = UDim2.new(1,-52,0.5,-11)
    toggleBg.BackgroundColor3 = default and Color3.fromRGB(235,137,53) or Color3.fromRGB(60,60,70)
    toggleBg.BorderSizePixel = 0
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1,0)
    local circle = Instance.new("Frame", toggleBg)
    circle.Size = UDim2.new(0,18,0,18)
    circle.Position = default and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    circle.BorderSizePixel = 0
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1,0)
    local enabled = default
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        TweenService:Create(toggleBg, TweenInfo.new(0.2), {BackgroundColor3 = enabled and Color3.fromRGB(235,137,53) or Color3.fromRGB(60,60,70)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = enabled and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)}):Play()
        pcall(callback, enabled)
    end)
end

local function CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,52)
    frame.BackgroundColor3 = Color3.fromRGB(32,32,42)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.7,0,0,18)
    lbl.Position = UDim2.new(0,12,0,6)
    lbl.BackgroundTransparency = 1
    lbl.Text = text..": "..default
    lbl.TextColor3 = Color3.fromRGB(220,220,230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(1,-24,0,6)
    track.Position = UDim2.new(0,12,0,32)
    track.BackgroundColor3 = Color3.fromRGB(50,50,60)
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(235,137,53)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local thumb = Instance.new("Frame", track)
    thumb.Size = UDim2.new(0,14,0,14)
    thumb.Position = UDim2.new((default-min)/(max-min),-7,0.5,-7)
    thumb.BackgroundColor3 = Color3.fromRGB(255,255,255)
    thumb.BorderSizePixel = 0
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1,0)
    local dragging = false
    local function update(input)
        local pos = math.clamp((input.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0,1)
        local value = math.floor((min + (max-min)*pos)*10)/10
        fill.Size = UDim2.new(pos,0,1,0)
        thumb.Position = UDim2.new(pos,-7,0.5,-7)
        lbl.Text = text..": "..value
        pcall(callback, value)
    end
    thumb.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true end end)
    UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end end)
    track.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then update(inp) end end)
    UserInputService.InputChanged:Connect(function(inp) if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then update(inp) end end)
end

local function CreateButton(parent, text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,36)
    btn.BackgroundColor3 = color or Color3.fromRGB(235,137,53)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    btn.MouseButton1Click:Connect(function() pcall(callback) end)
    return btn
end

local function CreateDropdown(parent, text, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,36)
    frame.BackgroundColor3 = Color3.fromRGB(32,32,42)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    frame.ClipsDescendants = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.5,0,0,36)
    lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200,200,210)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.5,-12,0,28)
    btn.Position = UDim2.new(0.5,0,0,4)
    btn.BackgroundColor3 = Color3.fromRGB(44,44,56)
    btn.Text = default
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local expanded = false
    local listFrame = Instance.new("Frame", frame)
    listFrame.Size = UDim2.new(1,0,0,0)
    listFrame.Position = UDim2.new(0,0,0,36)
    listFrame.BackgroundTransparency = 1
    listFrame.Visible = false
    local listLayout = Instance.new("UIListLayout", listFrame)
    listLayout.Padding = UDim.new(0,4)
    local function toggle()
        expanded = not expanded
        if expanded then
            listFrame.Visible = true
            local count = #options
            frame.Size = UDim2.new(1,0,0,36 + count*32 + 8)
            listFrame.Size = UDim2.new(1,0,0,count*32)
        else
            frame.Size = UDim2.new(1,0,0,36)
            listFrame.Visible = false
        end
    end
    for _, opt in ipairs(options) do
        local obtn = Instance.new("TextButton", listFrame)
        obtn.Size = UDim2.new(1,-8,0,28)
        obtn.BackgroundColor3 = Color3.fromRGB(50,50,62)
        obtn.Text = opt
        obtn.TextColor3 = Color3.fromRGB(220,220,230)
        obtn.Font = Enum.Font.Gotham
        obtn.TextSize = 11
        obtn.BorderSizePixel = 0
        Instance.new("UICorner", obtn).CornerRadius = UDim.new(0,6)
        obtn.MouseButton1Click:Connect(function() btn.Text = opt toggle() pcall(callback, opt) end)
    end
    btn.MouseButton1Click:Connect(toggle)
end

-- Populate tabs
CreateSection(FarmTab, "💰 Auto Farm - Main")
CreateToggle(FarmTab, "Enable Auto Farm Gold", false, function(v) State.AutoFarm = v if v then StartFarm() else StopFarm() end end)
CreateDropdown(FarmTab, "Method", {"Tween", "Teleport", "Darkness"}, "Tween", function(v) State.FarmMethod = v end)
CreateDropdown(FarmTab, "Target", {"All Stages", "Stage 1","Stage 2","Stage 3","Stage 4","Stage 5","Stage 6","Stage 7","Stage 8","Stage 9","Stage 10","Golden Chest"}, "All Stages", function(v) State.TargetMode = v end)
CreateSlider(FarmTab, "Farm Speed", 0.5, 5, 2.5, function(v) State.FarmSpeed = v end)
CreateToggle(FarmTab, "Auto Reset", true, function(v) State.AutoReset = v end)
CreateToggle(FarmTab, "Auto Claim", true, function(v) State.AutoClaim = v end)
CreateToggle(FarmTab, "Anti-AFK", true, function(v) State.AntiAFK = v end)
CreateButton(FarmTab, "📍 Teleport to Golden Chest", Color3.fromRGB(255,180,0), function() TeleportTo(TargetLocations["Golden Chest"]) end)
CreateButton(FarmTab, "🔄 Claim Reward Now", Color3.fromRGB(80,200,120), function() ClaimReward() end)

CreateSection(BuildTab, "🏗️ Build")
CreateButton(BuildTab, "🧱 Build Platform", Color3.fromRGB(235,137,53), function() BuildPlatform() end)
CreateButton(BuildTab, "💾 Save Build", Color3.fromRGB(80,140,255), function() local c=SaveBuild() print("Saved",c) end)
CreateButton(BuildTab, "📂 Load Build", Color3.fromRGB(120,200,80), function() LoadBuild() end)

CreateSection(PlayerTab, "✈️ Movement")
CreateToggle(PlayerTab, "Fly (WASD+Space/Shift)", false, function(v) State.Fly = v end)
CreateSlider(PlayerTab, "Fly Speed", 10, 300, 80, function(v) State.FlySpeed = v end)
CreateToggle(PlayerTab, "Noclip", false, function(v) State.Noclip = v end)
CreateToggle(PlayerTab, "Infinite Jump", false, function(v) State.InfJump = v end)
CreateSlider(PlayerTab, "WalkSpeed", 16, 250, 16, function(v) State.WalkSpeed = v ApplyMovement() end)
CreateSlider(PlayerTab, "JumpPower", 50, 250, 50, function(v) State.JumpPower = v ApplyMovement() end)
CreateButton(PlayerTab, "⚡ Apply Speed", Color3.fromRGB(80,200,120), function() ApplyMovement() end)

CreateSection(WorldTab, "🌍 Teleports")
for name, cf in pairs(BaseLocations) do CreateButton(WorldTab, "📍 "..name, Color3.fromRGB(50,50,60), function() TeleportTo(cf) end) end
for i=1,10 do CreateButton(WorldTab, "🚩 Stage "..i, Color3.fromRGB(80,120,200), function() TeleportTo(TargetLocations["Stage "..i]) end) end
CreateSection(WorldTab, "World")
CreateToggle(WorldTab, "Fullbright", false, function(v) State.Fullbright = v SetFullbright(v) end)

CreateSection(VisualTab, "👁️ ESP")
CreateToggle(VisualTab, "Player ESP", false, function(v) State.ESP = v if not v then ClearESP() else UpdateESP() end end)
CreateButton(VisualTab, "🔄 Refresh ESP", Color3.fromRGB(80,140,255), function() UpdateESP() end)
CreateButton(VisualTab, "🧹 Clear ESP", Color3.fromRGB(100,100,110), function() ClearESP() end)
CreateSlider(VisualTab, "FOV", 30, 120, 70, function(v) State.FOV = v Workspace.CurrentCamera.FieldOfView = v end)

CreateSection(EconomyTab, "🪙 Buy")
CreateDropdown(EconomyTab, "Chest Type", {"Common Chest","Uncommon Chest","Rare Chest","Epic Chest","Legendary Chest"}, "Common Chest", function(v) State.ChestType = v end)
CreateSlider(EconomyTab, "Amount", 1, 10, 1, function(v) State.BuyAmount = v end)
CreateButton(EconomyTab, "🛒 Buy Chest", Color3.fromRGB(255,180,0), function() BuyChest(State.ChestType, State.BuyAmount) end)

CreateSection(FunTab, "🎉 Fun")
CreateToggle(FunTab, "🕳️ Black Hole", false, function(v) State.BlackHole = v if not v then ClearBH() end end)
CreateSlider(FunTab, "BH Radius", 10, 150, 35, function(v) State.BH_Radius = v end)
CreateSlider(FunTab, "BH Power", 10, 200, 60, function(v) State.BH_Power = v end)

CreateSection(SettingsTab, "⚙️ Control")
CreateButton(SettingsTab, "🔄 Rejoin", Color3.fromRGB(80,140,255), function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
CreateButton(SettingsTab, "🧹 Unload Hub", Color3.fromRGB(200,60,60), function()
    getgenv().BABFT_Running = false
    StopFarm() ClearESP() ClearBH()
    if FlyConn then FlyConn:Disconnect() end
    if NoclipConn then NoclipConn:Disconnect() end
    if AntiAFKConn then AntiAFKConn:Disconnect() end
    Workspace.Gravity = NormalGravity
    ScreenGui:Destroy()
end)

-- Top buttons
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().BABFT_Running = false
    StopFarm() ClearESP() ClearBH()
    ScreenGui:Destroy()
end)

local minimized = false
local originalSize = MainFrame.Size
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 620, 0, 48)}):Play()
        ContentFrame.Visible = false TabBar.Visible = false MinBtn.Text = "+"
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = originalSize}):Play()
        ContentFrame.Visible = true TabBar.Visible = true MinBtn.Text = "—"
    end
end)

-- Hotkey G
local uiVisible = true
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.G then
        uiVisible = not uiVisible
        MainFrame.Visible = uiVisible
        print("[BABFT] UI Visible:", uiVisible)
    end
end)

-- Final checks
print("[BABFT] UI Created successfully!")
print("[BABFT] MainFrame Visible:", MainFrame.Visible, "Parent:", ScreenGui.Parent:GetFullName())
print("[BABFT] ScreenGui Enabled:", ScreenGui.Enabled)

-- Extra fallback: if after 2 seconds MainFrame not visible, try PlayerGui
task.spawn(function()
    task.wait(2)
    if not MainFrame or not MainFrame.Parent then
        print("[BABFT] MainFrame missing, creating backup in PlayerGui")
        local backupParent = LocalPlayer:WaitForChild("PlayerGui")
        local backupGui = Instance.new("ScreenGui")
        backupGui.Name = "BABFT_Backup"
        backupGui.Parent = backupParent
        local clone = MainFrame:Clone()
        clone.Parent = backupGui
        print("[BABFT] Backup UI created in PlayerGui")
    end
end)

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {Title="BABFT v1.0 FIXED Loaded!", Text="Press G to hide | Check console F9 for logs", Duration=5})
end)

print("=== BABFT ULTIMATE HUB v1.0 FIXED LOADED ===")
