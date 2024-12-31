local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Criação da janela principal
local Window = Fluent:CreateWindow({
    Title = "TRIHUB",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Abas
local Tabs = {
    Jogador = Window:AddTab({ Title = "Jogador" }),
    Teleporte = Window:AddTab({ Title = "Teleporte" }),
    ESP = Window:AddTab({ Title = "ESP" }),
    Configuracoes = Window:AddTab({ Title = "Configurações" })
}

-- Jogador: Pulo infinito
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

-- Jogador: Walk on Water
local WalkOnWater = false
Tabs.Jogador:AddToggle("WalkOnWater", { Title = "Walk on Water" }):OnChanged(function(Value)
    WalkOnWater = Value
    local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")

    if WalkOnWater then
        rootPart.Touched:Connect(function(hit)
            if hit.Name == "Water" then
                rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 0, rootPart.Velocity.Z)
            end
        end)
    end
end)

-- Jogador: Aimbot
local AimbotEnabled = false
Tabs.Jogador:AddToggle("Aimbot", { Title = "Aimbot" }):OnChanged(function(Value)
    AimbotEnabled = Value
end)

local function getClosestPlayer()
    local localPlayer = game.Players.LocalPlayer
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local distance = (localPlayer.Character.Head.Position - player.Character.Head.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestPlayer = player
            end
        end
    end

    return closestPlayer
end

game:GetService("RunService").RenderStepped:Connect(function()
    if AimbotEnabled then
        local closestPlayer = getClosestPlayer()
        if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("Head") then
            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, closestPlayer.Character.Head.Position)
        end
    end
end)

-- Teleporte: Teleport Island
Tabs.Teleporte:AddButton({
    Title = "Teleport Island",
    Callback = function()
        Window:Dialog({
            Title = "Teleport Island",
            Content = "Selecione um local:",
            Buttons = {
                {
                    Title = "Cachoeira",
                    Callback = function()
                        local player = game.Players.LocalPlayer
                        local character = player.Character or player.CharacterAdded:Wait()
                        local rootPart = character:WaitForChild("HumanoidRootPart")
                        rootPart.CFrame = CFrame.new(6060.2, 400.4, 628.5)
                    end
                }
            }
        })
    end
})

-- ESP: ESP Player
local espEnabled = false
local espColor = Color3.fromRGB(0, 255, 0) -- Verde por padrão

Tabs.ESP:AddColorPicker("ESPColor", {
    Title = "Cor da Borda",
    Default = espColor
}):OnChanged(function(Color)
    espColor = Color
end)

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
            box.Color3 = espColor
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

-- Configurações
Tabs.Configuracoes:AddParagraph({
    Title = "Configurações",
    Content = "Configure suas preferências aqui."
})

-- Inicializar Managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Finalizar
Window:SelectTab(1)
Fluent:Notify({
    Title = "TRIHUB",
    Content = "O sistema foi carregado com sucesso!",
    Duration = 5
})
