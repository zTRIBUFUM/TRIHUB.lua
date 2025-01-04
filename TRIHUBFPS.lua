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
    Admin = Window:AddTab({ Title = "Admin" }),
    Configuracoes = Window:AddTab({ Title = "Configurações" })
}

-- Jogador: Controle de Velocidade de Caminhada
local WalkSpeed = 16
Tabs.Jogador:AddLabel("Use + e - para alterar a velocidade de caminhada")
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if input.KeyCode == Enum.KeyCode.Equals or input.KeyCode == Enum.KeyCode.KeypadPlus then
        WalkSpeed = math.min(WalkSpeed + 1, 100)
        if humanoid then humanoid.WalkSpeed = WalkSpeed end
        Fluent:Notify({ Title = "Velocidade de Caminhada", Content = "Aumentada para " .. WalkSpeed, Duration = 2 })
    elseif input.KeyCode == Enum.KeyCode.Minus or input.KeyCode == Enum.KeyCode.KeypadMinus then
        WalkSpeed = math.max(WalkSpeed - 1, 0)
        if humanoid then humanoid.WalkSpeed = WalkSpeed end
        Fluent:Notify({ Title = "Velocidade de Caminhada", Content = "Reduzida para " .. WalkSpeed, Duration = 2 })
    end
end)

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

-- Teleporte
Tabs.Teleporte:AddButton({
    Title = "Teleportar para Ilha",
    Callback = function()
        Window:Dialog({
            Title = "Teleportar",
            Content = "Selecione um local:",
            Buttons = {
                {
                    Title = "Ilha da Cachoeira",
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

-- ESP
local espEnabled = false

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
            box.Color3 = Color3.new(1, 0, 0) -- Vermelho para inimigos
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

Tabs.ESP:AddToggle("ESPPlayer", { Title = "Ativar ESP" }):OnChanged(toggleESP)

-- Admin: Comando de Explosão
Tabs.Admin:AddButton({
    Title = "Explodir Jogador",
    Callback = function()
        local targetPlayer = game.Players:FindFirstChild("NomeDoJogador")
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local explosion = Instance.new("Explosion")
            explosion.Position = targetPlayer.Character.HumanoidRootPart.Position
            explosion.BlastRadius = 10
            explosion.BlastPressure = 50000
            explosion.Parent = workspace
        else
            Fluent:Notify({ Title = "Erro", Content = "Jogador não encontrado.", Duration = 3 })
        end
    end
})

-- Configurações
Tabs.Configuracoes:AddParagraph({
    Title = "Configurações",
    Content = "Configure suas preferências aqui."
})
Tabs.Configuracoes:AddButton({
    Title = "Copiar Discord",
    Callback = function()
        setclipboard("https://discord.gg/seulink")
    end
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
