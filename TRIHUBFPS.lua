local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Criar a janela principal
local Window = Fluent:CreateWindow({
    Title = "TRIHUB",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Criar abas
local Tabs = {
    Jogador = Window:AddTab({ Title = "Jogador" }),
    Teleporte = Window:AddTab({ Title = "Teleporte" }),
    ESP = Window:AddTab({ Title = "ESP" }),
    Configuracoes = Window:AddTab({ Title = "Configurações" })
}

-- Função para obter o personagem do jogador
local function getCharacter()
    local player = game.Players.LocalPlayer
    return player.Character or player.CharacterAdded:Wait()
end

-- Pulo infinito
local InfiniteJump = false
Tabs.Jogador:AddToggle("InfiniteJump", { Title = "Pulo Infinito" }):OnChanged(function(Value)
    InfiniteJump = Value
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if InfiniteJump then
        local character = getCharacter()
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Aimbot
local AimbotEnabled = false
local AimbotOnHead = false
Tabs.Jogador:AddToggle("Aimbot", { Title = "Aimbot" }):OnChanged(function(Value)
    AimbotEnabled = Value
end)

Tabs.Jogador:AddToggle("AimbotOnHead", { Title = "Aimbot na Cabeça" }):OnChanged(function(Value)
    AimbotOnHead = Value
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
        if closestPlayer and closestPlayer.Character then
            local aimPart = closestPlayer.Character:FindFirstChild(AimbotOnHead and "Head" or "HumanoidRootPart")
            if aimPart then
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, aimPart.Position)
            end
        end
    end
end)

-- Teleporte
Tabs.Teleporte:AddButton({
    Title = "Teleport Island",
    Callback = function()
        local character = getCharacter()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(6060.2, 400.4, 628.5)
        end
    end
})

-- ESP
local espEnabled = false
Tabs.ESP:AddToggle("ESPPlayer", { Title = "ESP Player" }):OnChanged(function(state)
    espEnabled = state
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Head") then
            if espEnabled then
                local box = Instance.new("BoxHandleAdornment")
                box.Size = player.Character:GetExtentsSize()
                box.Adornee = player.Character
                box.AlwaysOnTop = true
                box.ZIndex = 10
                box.Color3 = player.Team == game.Players.LocalPlayer.Team and Color3.fromRGB(0, 0, 255) or Color3.fromRGB(255, 0, 0)
                box.Transparency = 0.5
                box.Name = "ESPBox"
                box.Parent = player.Character.Head
            else
                local esp = player.Character.Head:FindFirstChild("ESPBox")
                if esp then esp:Destroy() end
            end
        end
    end
end)

-- Configurações
Tabs.Configuracoes:AddButton({
    Title = "Copiar Discord",
    Callback = function()
        setclipboard("https://discord.gg/seulink")
    end
})

-- Inicializar Managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Selecionar a primeira aba e notificar o usuário
Window:SelectTab(1)
Fluent:Notify({
    Title = "TRIHUB",
    Content = "O sistema foi carregado com sucesso!",
    Duration = 5
})
