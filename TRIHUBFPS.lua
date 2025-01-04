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
    Aimbot = Window:AddTab({ Title = "Aimbot" }),
    Configuracoes = Window:AddTab({ Title = "Configurações" })
}

-- Variáveis
local WalkSpeed = 16
local UserInputService = game:GetService("UserInputService")
local espEnabled = false

-- Funções de utilidade
local function ensureCharacterAndHumanoid()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return character, humanoid
end

-- Controle de Velocidade de Caminhada com + e -
Tabs.Jogador:AddLabel("Use + e - para alterar a velocidade de caminhada")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Equals or input.KeyCode == Enum.KeyCode.KeypadPlus then
        -- Aumentar velocidade
        WalkSpeed = math.min(WalkSpeed + 1, 100)
        local _, humanoid = ensureCharacterAndHumanoid()
        if humanoid then
            humanoid.WalkSpeed = WalkSpeed
        end
        Fluent:Notify({ Title = "Velocidade de Caminhada", Content = "Aumentada para " .. WalkSpeed, Duration = 2 })
    elseif input.KeyCode == Enum.KeyCode.Minus or input.KeyCode == Enum.KeyCode.KeypadMinus then
        -- Diminuir velocidade
        WalkSpeed = math.max(WalkSpeed - 1, 0)
        local _, humanoid = ensureCharacterAndHumanoid()
        if humanoid then
            humanoid.WalkSpeed = WalkSpeed
        end
        Fluent:Notify({ Title = "Velocidade de Caminhada", Content = "Reduzida para " .. WalkSpeed, Duration = 2 })
    end
end)

-- Pulo Infinito
local InfiniteJump = false
Tabs.Jogador:AddToggle("InfiniteJump", { Title = "Pulo Infinito" }):OnChanged(function(Value)
    InfiniteJump = Value
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if InfiniteJump then
        local _, humanoid = ensureCharacterAndHumanoid()
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Walk on Water
local WalkOnWater = false
Tabs.Jogador:AddToggle("WalkOnWater", { Title = "Walk on Water" }):OnChanged(function(Value)
    WalkOnWater = Value
    local character, humanoid = ensureCharacterAndHumanoid()
    local rootPart = character:WaitForChild("HumanoidRootPart")

    if WalkOnWater then
        rootPart.Touched:Connect(function(hit)
            if hit.Name == "Ocean" then
                rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 0, rootPart.Velocity.Z)
            end
        end)
    end
end)

-- Teleporte
Tabs.Teleporte:AddButton({
    Title = "Teleport Island - Cachoeira",
    Callback = function()
        local character, humanoid = ensureCharacterAndHumanoid()
        local rootPart = character:WaitForChild("HumanoidRootPart")
        rootPart.CFrame = CFrame.new(6060.2, 400.4, 628.5) -- Coordenadas da Cachoeira
    end
})

-- ESP: ESP Player
local function createESP(player)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = player.Character
    highlight.FillColor = Color3.new(1, 0, 0) -- Vermelho
    highlight.OutlineColor = Color3.new(0, 0, 0) -- Preto
    highlight.FillTransparency = 0.5 -- Transparência do preenchimento
    highlight.OutlineTransparency = 0
    highlight.Parent = player.Character
end

local function removeESP(player)
    if player.Character then
        local highlight = player.Character:FindFirstChildOfClass("Highlight")
        if highlight then
            highlight:Destroy()
        end
    end
end

local function updateESP(state)
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            if state then
                createESP(player)
            else
                removeESP(player)
            end
        end
    end
end

-- Monitorar novos jogadores entrando ou saindo
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if espEnabled then
            createESP(player)
        end
    end)
end)

game.Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

Tabs.ESP:AddToggle("ESPPlayer", { Title = "ESP Player" }):OnChanged(function(Value)
    espEnabled = Value
    updateESP(espEnabled)
end)

-- Configurações: Controle de Brilho
local brightnessEnabled = false
Tabs.Configuracoes:AddToggle("BrightnessControl", { Title = "Controle de Brilho" }):OnChanged(function(Value)
    brightnessEnabled = Value
    if not brightnessEnabled then
        game:GetService("Lighting").Brightness = 1
    end
end)

Tabs.Configuracoes:AddButton({
    Title = "Copiar Discord",
    Callback = function()
        setclipboard("https://discord.gg/seulink") -- Insira o link desejado
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
