local Stats = game:GetService('Stats')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Nurysium_Util = loadstring(game:HttpGet('https://raw.githubusercontent.com/flezzpe/Nurysium/main/nurysium_helper.lua'))()
local local_player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local closest_Entity = nil
local parry_remote = nil

getgenv().aura_Enabled = false
getgenv().night_mode_Enabled = false

local Services = {
    game:GetService('AdService'),
    game:GetService('SocialService')
}

local colors = {
    SchemeColor = Color3.fromRGB(194,195,255),
    Background = Color3.fromRGB(30, 30, 30),
    Header = Color3.fromRGB(30, 30, 30),
    TextColor = Color3.fromRGB(194,195,255),
    ElementColor = Color3.fromRGB(20, 20, 20)
}

-- Shop Functions
function SwordCrateManual()
    game:GetService("ReplicatedStorage").Remote.RemoteFunction:InvokeServer("PromptPurchaseCrate", workspace.Spawn.Crates.NormalSwordCrate)
end

function ExplosionCrateManual()
    game:GetService("ReplicatedStorage").Remote.RemoteFunction:InvokeServer("PromptPurchaseCrate", workspace.Spawn.Crates.NormalExplosionCrate)
end

function AutoSwordCrate()
    while getgenv().auto_SwordCrate_Enabled do
        game:GetService("ReplicatedStorage").Remote.RemoteFunction:InvokeServer("PromptPurchaseCrate", workspace.Spawn.Crates.NormalSwordCrate)
        wait(0.5)
    end
end

function AutoExplosionCrate()
    while getgenv().auto_ExplosionCrate_Enabled do
        game:GetService("ReplicatedStorage").Remote.RemoteFunction:InvokeServer("PromptPurchaseCrate", workspace.Spawn.Crates.NormalExplosionCrate)
        wait(0.5)
    end
end

-- Ui Library
local Library = loadstring(game:HttpGet("https://pastebin.com/raw/vff1bQ9F"))()
local Window = Library.CreateLib("Simple Ball - BXLESKY")
local Tab = Window:NewTab("Main")
local Tab2 = Window:NewTab("Shop")
local Tab3 = Window:NewTab("Misc")

local Combat = Tab:NewSection("Main")
local Shop = Tab2:NewSection("Shop")
local Misc = Tab3:NewSection("Misc")

local function get_closest_entity(Object: Part)
    task.spawn(function()
        local max_distance = math.huge
        for _, entity in ipairs(workspace.Alive:GetChildren()) do
            if entity.Name ~= Players.LocalPlayer.Name then
                local distance = (Object.Position - entity.HumanoidRootPart.Position).Magnitude
                if distance < max_distance then
                    closest_Entity = entity
                    max_distance = distance
                end
            end
        end
        return closest_Entity
    end)
end

-- Auto Parry
function resolve_parry_Remote()
    for _, service in ipairs(Services) do
        local temp_remote = service:FindFirstChildOfClass('RemoteEvent')
        if temp_remote and temp_remote.Name:find('\n') then
            parry_remote = temp_remote
            break
        end
    end
end

local aura_table = {
    canParry = true,
    is_Spamming = false,
    parry_Range = 0,
    spam_Range = 0,
    hit_Count = 0,
    hit_Time = tick(),
    ball_Warping = tick(),
    is_ball_Warping = false
}

ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
    -- Remove Hit Effect code
end)

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function()
    aura_table.hit_Count += 1
    task.delay(0.15, function()
        aura_table.hit_Count -= 1
    end)
end)

workspace:WaitForChild("Balls").ChildRemoved:Connect(function(child)
    aura_table.hit_Count = 0
    aura_table.is_ball_Warping = false
    aura_table.is_Spamming = false
end)

Combat:NewToggle("Auto Parry", "Hits Ball For You", function(toggled)
    resolve_parry_Remote()
    getgenv().aura_Enabled = toggled
end)

Shop:NewButton("Sword Crate", "Opens Sword Crate (Need Enough Money)", function(toggled)
    SwordCrateManual()
end)

Shop:NewToggle("Auto Sword Crate", "Automatically opens Sword Crates", function(toggled)
    getgenv().auto_SwordCrate_Enabled = toggled
    if toggled then
        task.spawn(AutoSwordCrate)
    end
end)

Shop:NewButton("Explosion Crate", "Opens Explosion Crate (Need Enough Money)", function(toggled)
    ExplosionCrateManual()
end)

Shop:NewToggle("Auto Explosion Crate", "Automatically opens Explosion Crates", function(toggled)
    getgenv().auto_ExplosionCrate_Enabled = toggled
    if toggled then
        task.spawn(AutoExplosionCrate)
    end
end)

Misc:NewToggle("Night/Day", "Toggles Night/Day", function(toggled)
    getgenv().night_mode_Enabled = toggled
end)

Misc:NewToggle("No Lag", "Removes MOST Lag", function(toggled)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Hosvile/Refinement/main/Destroy%20Particle%20Emitters", true))()
end)

Misc:NewKeybind("UI Toggle", "Toggles UI", Enum.KeyCode.Insert, function()
	Library:ToggleUI()
end)

-- Night Mode
task.defer(function()
    while task.wait(1) do
        if getgenv().night_mode_Enabled then
            game:GetService("TweenService"):Create(game:GetService("Lighting"), TweenInfo.new(3), {ClockTime = 3.9}):Play()
        else
            game:GetService("TweenService"):Create(game:GetService("Lighting"), TweenInfo.new(3), {ClockTime = 13.5}):Play()
        end
    end
end)

-- Aura
task.spawn(function()
    RunService.PreRender:Connect(function()
        if not getgenv().aura_Enabled then return end
        if closest_Entity then
            if workspace.Alive:FindFirstChild(closest_Entity.Name) and workspace.Alive:FindFirstChild(closest_Entity.Name).Humanoid.Health > 0 then
                if aura_table.is_Spamming then
                    if local_player:DistanceFromCharacter(closest_Entity.HumanoidRootPart.Position) <= aura_table.spam_Range then
                        parry_remote:FireServer(
                            0.5,
                            CFrame.new(camera.CFrame.Position, Vector3.zero),
                            {[closest_Entity.Name] = closest_Entity.HumanoidRootPart.Position},
                            {closest_Entity.HumanoidRootPart.Position.X, closest_Entity.HumanoidRootPart.Position.Y},
                            false
                        )
                    end
                end
            end
        end
    end)

    RunService.Heartbeat:Connect(function()
        if not getgenv().aura_Enabled then return end
        local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 10
        local self = Nurysium_Util.getBall()
        if not self then return end
        self:GetAttributeChangedSignal('target'):Once(function()
            aura_table.canParry = true
        end)

        if self:GetAttribute('target') ~= local_player.Name or not aura_table.canParry then return end
        get_closest_entity(local_player.Character.PrimaryPart)
        local player_Position = local_player.Character.PrimaryPart.Position
        local ball_Position = self.Position
        local ball_Velocity = self.AssemblyLinearVelocity

        if self:FindFirstChild('zoomies') then
            ball_Velocity = self.zoomies.VectorVelocity
        end

        local ball_Direction = (local_player.Character.PrimaryPart.Position - ball_Position).Unit
        local ball_Distance = local_player:DistanceFromCharacter(ball_Position)
        local ball_Dot = ball_Direction:Dot(ball_Velocity.Unit)
        local ball_Speed = ball_Velocity.Magnitude
        local ball_speed_Limited = math.min(ball_Speed / 1000, 0.1)
        local ball_predicted_Distance = (ball_Distance - ping / 15.5) - (ball_Speed / 3.5)
        local target_Position = closest_Entity.HumanoidRootPart.Position
        local target_Distance = local_player:DistanceFromCharacter(target_Position)
        local target_distance_Limited = math.min(target_Distance / 10000, 0.1)
        local target_Direction = (local_player.Character.PrimaryPart.Position - closest_Entity.HumanoidRootPart.Position).Unit
        local target_Velocity = closest_Entity.HumanoidRootPart.AssemblyLinearVelocity
        local target_isMoving = target_Velocity.Magnitude > 0
        local target_Dot = target_isMoving and math.max(target_Direction:Dot(target_Velocity.Unit), 0)

        aura_table.spam_Range = math.max(ping / 10, 15) + ball_Speed / 7
        aura_table.parry_Range = math.max(math.max(ping, 4) + ball_Speed / 3.5, 9.5)
        aura_table.is_Spamming = aura_table.hit_Count > 1 or ball_Distance < 13.5

        if ball_Dot < -0.2 then
            aura_table.ball_Warping = tick()
        end

        task.spawn(function()
            if (tick() - aura_table.ball_Warping) >= 0.15 + target_distance_Limited - ball_speed_Limited or ball_Distance <= 10 then
                aura_table.is_ball_Warping = false
                return
            end
            aura_table.is_ball_Warping = true
        end)

        if ball_Distance <= aura_table.parry_Range and not aura_table.is_Spamming and not aura_table.is_ball_Warping then
            parry_remote:FireServer(
                0.5,
                CFrame.new(camera.CFrame.Position, Vector3.new(math.random(0, 100), math.random(0, 1000), math.random(100, 1000))),
                {[closest_Entity.Name] = target_Position},
                {target_Position.X, target_Position.Y},
                false
            )
            aura_table.canParry = false
            aura_table.hit_Time = tick()
            aura_table.hit_Count += 1
            task.delay(0.15, function()
                aura_table.hit_Count -= 1
            end)
        end

        task.spawn(function()
            repeat
                RunService.Heartbeat:Wait()
            until (tick() - aura_table.hit_Time) >= 1
            aura_table.canParry = true
        end)
    end)
end)

-- Initialize
initializate('nurysium_temp')

-- UI Toggle Button
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScreenGui"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local Toggle = Instance.new("TextButton")
Toggle.Name = "Toggle"
Toggle.Parent = ScreenGui
Toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Toggle.Position = UDim2.new(0, 0, 0.454706937, 0)
Toggle.Size = UDim2.new(0, 90, 0, 38)
Toggle.Font = Enum.Font.SourceSans
Toggle.Text = "Toggle"
Toggle.TextColor3 = Color3.fromRGB(248, 248, 248)
Toggle.TextSize = 28.000
Toggle.Draggable = true
Toggle.MouseButton1Click:connect(function()
    Library:ToggleUI()
end)

local Corner = Instance.new("UICorner")
Corner.Name = "Corner"
Corner.Parent = Toggle
