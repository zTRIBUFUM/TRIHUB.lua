local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "TRIHUB",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Jogador = Window:AddTab({ Title = "Jogador" }),
    Teleporte = Window:AddTab({ Title = "Teleporte" }),
    ESP = Window:AddTab({ Title = "ESP" }),
    Configuracoes = Window:AddTab({ Title = "Configurações" })
}

local InfiniteJump = false
Tabs.Jogador:AddToggle("InfiniteJump", { Title = "Pulo Infinito" }):OnChanged(function(Value)
    InfiniteJump = Value
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if InfiniteJump then
        local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

local WalkOnWater = false
Tabs.Jogador:AddToggle("WalkOnWater", { Title = "Walk on Water" }):OnChanged(function(Value)
    WalkOnWater = Value
    local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")

    if WalkOnWater then
        rootPart.Touched:Connect(function(hit)
            if hit.Name == "Ocean" then
                rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 0, rootPart.Velocity.Z)
            end
        end)
    end
end)

local AimbotEnabled = false
Tabs.Jogador:AddToggle("Aimbot", { Title = "Aimbot" }):OnChanged(function(Value)
    AimbotEnabled = Value
end)

local function getClosestEnemyPlayer()
    local localPlayer = game.Players.LocalPlayer
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= localPlayer and player.Team ~= localPlayer.Team and player.Character and player.Character:FindFirstChild("Head") then
            local distance = (localPlayer.Character.Head.Position - player.Character.Head.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestPlayer = player
            end
        end
    end

    return closestPlayer
end

local aimbotConnection

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and AimbotEnabled and input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimbotConnection = game:GetService("RunService").RenderStepped:Connect(function()
            local closestPlayer = getClosestEnemyPlayer()
            if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("Head") then
                local currentPosition = workspace.CurrentCamera.CFrame.Position
                local targetPosition = closestPlayer.Character.Head.Position
                local newCFrame = CFrame.new(currentPosition, targetPosition)
                workspace.CurrentCamera.CFrame = newCFrame:Lerp(newCFrame, 0.5)
            end
        end)
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if aimbotConnection then
            aimbotConnection:Disconnect()
        end
    end
end)

-- Jogador: Configurável WalkSpeed
local WalkSpeed = 16 -- Velocidade padrão de caminhada

Tabs.Jogador:AddSlider("WalkSpeedSlider", {
    Title = "Velocidade de Caminhada",
    Min = 0,
    Max = 100,
    Default = 16,
    OnChanged = function(Value)
        WalkSpeed = Value
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = WalkSpeed
        end
    end
})

local espEnabled = false

local function getTeamColor(player)
    if player.Team == game.Players.LocalPlayer.Team then
        return Color3.fromRGB(0, 0, 255) -- Azul
    else
        return Color3.fromRGB(255, 0, 0) -- Vermelho
    end
end

local function addESP(player)
    if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
        local head = player.Character.Head

        if not head:FindFirstChild("ESPBox") then
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "ESPBox"
            box.Size = player.Character:GetExtentsSize()
            box.Adornee = player.Character
            box.AlwaysOnTop = true
            box.ZIndex = 10
            box.Color3 = getTeamColor(player)
            box.Transparency = 0.5
            box.Parent = head
        end
    end
end

local function removeESP(player)
    if player.Character and player.Character:FindFirstChild("Head") then
        local esp = player.Character.Head:FindFirstChild("ESPBox")
        if esp then
            esp:Destroy()
        end
    end
end

local function toggleESP(state)
    espEnabled = state
    if espEnabled then
        for _, player in pairs(game.Players:GetPlayers()) do
            addESP(player)
        end
        game.Players.PlayerAdded:Connect(addESP)
        game.Players.PlayerRemoving:Connect(removeESP)
    else
        for _, player in pairs(game.Players:GetPlayers()) do
            removeESP(player)
        end
    end
end

Tabs.ESP:AddToggle("ESPPlayer", { Title = "ESP Player" }):OnChanged(toggleESP)

Tabs.Configuracoes:AddParagraph({
    Title = "Configurações",
    Content = "Configure suas preferências aqui."
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

Window:SelectTab(1)
Fluent:Notify({
    Title = "TRIHUB",
    Content = "O sistema foi carregado com sucesso!",
    Duration = 5
})
