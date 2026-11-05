-- Rift Runner: playable prototype. Built with Roblox Luau.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local ROUND_SECONDS = 90
local BREAK_SECONDS = 15
local ISLAND_COUNT = 7
local COIN_VALUE = 10

Lighting.ClockTime = 14
Lighting.Brightness = 2

local old = Workspace:FindFirstChild("RiftRunnerWorld")
if old then old:Destroy() end
local world = Instance.new("Folder")
world.Name = "RiftRunnerWorld"
world.Parent = Workspace

local function part(name, size, position, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = position
    p.Anchored = true
    p.Color = color
    p.Material = material or Enum.Material.Grass
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = world
    return p
end

-- Central safe island and a ring of islands connected by narrow bridges.
part("SafeSpawn", Vector3.new(70, 5, 70), Vector3.new(0, 0, 0), Color3.fromRGB(70, 180, 100))
local spawn = Instance.new("SpawnLocation")
spawn.Name = "RiftSpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = Vector3.new(0, 3, 0)
spawn.Anchored = true
spawn.Neutral = true
spawn.Parent = world

local islands = {}
for i = 1, ISLAND_COUNT do
    local angle = (i / ISLAND_COUNT) * math.pi * 2
    local radius = 95
    local center = Vector3.new(math.cos(angle) * radius, math.random(8, 24), math.sin(angle) * radius)
    local island = part("Island_" .. i, Vector3.new(34, 5, 34), center, Color3.fromRGB(90, 155, 85))
    table.insert(islands, island)
    local bridge = part("Bridge_" .. i, Vector3.new(8, 2, radius - 28), Vector3.new(center.X/2, center.Y - 2, center.Z/2), Color3.fromRGB(125, 105, 80), Enum.Material.WoodPlanks)
    bridge.CFrame = CFrame.new(Vector3.new(center.X/2, center.Y - 2, center.Z/2), Vector3.new(center.X, center.Y - 2, center.Z))
    -- Bridge is decorative and anchored; use a long oriented part.
    bridge.Size = Vector3.new(8, 2, radius - 28)
    for c = 1, 3 do
        local coin = Instance.new("Part")
        coin.Name = "Coin"
        coin.Shape = Enum.PartType.Ball
        coin.Size = Vector3.new(2, 2, 2)
        coin.Position = center + Vector3.new(math.random(-10,10), 5, math.random(-10,10))
        coin.Anchored = true
        coin.CanCollide = false
        coin.Material = Enum.Material.Neon
        coin.Color = Color3.fromRGB(255, 205, 35)
        coin.Parent = world
        local taken = false
        coin.Touched:Connect(function(hit)
            if taken then return end
            local player = Players:GetPlayerFromCharacter(hit.Parent)
            if player then
                taken = true
                local stats = player:FindFirstChild("leaderstats")
                local coins = stats and stats:FindFirstChild("Coins")
                if coins then coins.Value += COIN_VALUE end
                coin:Destroy()
            end
        end)
    end
end

Players.PlayerAdded:Connect(function(player)
    local stats = Instance.new("Folder")
    stats.Name = "leaderstats"
    stats.Parent = player
    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0
    coins.Parent = stats
    local survived = Instance.new("IntValue")
    survived.Name = "Survivals"
    survived.Value = 0
    survived.Parent = stats
end)

local function broadcast(text)
    local hint = Workspace:FindFirstChild("RiftRoundMessage")
    if not hint then
        hint = Instance.new("Hint")
        hint.Name = "RiftRoundMessage"
        hint.Parent = Workspace
    end
    hint.Text = text
end

while true do
    for t = BREAK_SECONDS, 1, -1 do
        broadcast(("Rift opens in %d seconds — collect coins and get ready!"):format(t))
        task.wait(1)
    end
    broadcast("RIFT COLLAPSE! Stay on the islands for 90 seconds!")
    -- Randomly remove outer islands during the round to create a simple hazard.
    local active = table.clone(islands)
    for t = ROUND_SECONDS, 1, -1 do
        if t % 15 == 0 and #active > 1 then
            local index = math.random(1, #active)
            local island = table.remove(active, index)
            if island and island.Parent then island:Destroy() end
        end
        broadcast(("Survive the collapse: %d seconds remaining"):format(t))
        task.wait(1)
    end
    for _, player in ipairs(Players:GetPlayers()) do
        local stats = player:FindFirstChild("leaderstats")
        local survived = stats and stats:FindFirstChild("Survivals")
        if survived then survived.Value += 1 end
    end
    broadcast("You survived! The islands are rebuilding...")
    task.wait(5)
    -- Rebuild by restarting this server script's generated world.
    for _, child in ipairs(world:GetChildren()) do child:Destroy() end
    -- Reload current server script to regenerate map cleanly.
    script.Disabled = true
    task.wait(0.1)
    script.Disabled = false
end
