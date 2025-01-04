-- Carregar Bibliotecas
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

-- Criar Abas
local Tabs = {
    Jogador = Window:AddTab({ Title = "Jogador" }),
    Teleporte = Window:AddTab({ Title = "Teleporte" }),
    ESP = Window:AddTab({ Title = "ESP" }),
    Aimbot = Window:AddTab({ Title = "Aimbot" }),
    Configuracoes = Window:AddTab({ Title = "Configurações" })
}

-- Variáveis
local WalkSpeed = 16
local InfiniteJump = false
local WalkOnWater = false
local espEnabled = false
local UserInputService = game:GetService("UserInputService")

-- Funções de utilidade
local function ensureCharacterAndHumanoid()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return character, humanoid
end

-- Jogador - Controle de Velocidade
Tabs.Jogador:AddLabel("Use + e - para alterar a velocidade de caminhada")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local _, humanoid = ensureCharacterAndHumanoid()
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

-- Jogador - Pulo Infinito
Tabs.Jogador:AddToggle("InfiniteJump", { Title = "Pulo Infinito" }):OnChanged(function(Value)
    InfiniteJump = Value
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if InfiniteJump then
        local _, humanoid = ensureCharacterAndHumanoid()
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Jogador - Walk on Water
Tabs.Jogador:AddToggle("WalkOnWater", { Title = "Walk on Water" }):OnChanged(function(Value)
    WalkOnWater = Value
end)

-- Teleporte
Tabs.Teleporte:AddButton({
    Title = "Teleport Island - Cachoeira",
    Callback = function()
        local character = ensureCharacterAndHumanoid()
        local rootPart = character:WaitForChild("HumanoidRootPart")
        rootPart.CFrame = CFrame.new(6060.2, 400.4, 628.5) -- Coordenadas da Cachoeira
    end
})

-- ESP Player
local function createESP(player)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = player.Character
    highlight.FillColor = Color3.new(1, 0, 0)
    highlight.OutlineColor = Color3.new(0, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = player.Character
end

local function removeESP(player)
    if player.Character then
        local highlight = player.Character:FindFirstChildOfClass("Highlight")
        if highlight then highlight:Destroy() end
    end
end

local function updateESP(state)
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            if state then createESP(player) else removeESP(player) end
        end
    end
end

game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if espEnabled then createESP(player) end
    end)
end)

game.Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

Tabs.ESP:AddToggle("ESPPlayer", { Title = "ESP Player" }):OnChanged(function(Value)
    espEnabled = Value
    updateESP(espEnabled)
end)

-- Configurações
Tabs.Configuracoes:AddToggle("BrightnessControl", { Title = "Controle de Brilho" }):OnChanged(function(Value)
    if Value then
        game:GetService("Lighting").Brightness = 2
    else
        game:GetService("Lighting").Brightness = 1
    end
end)

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
Fluent:Notify({ Title = "TRIHUB", Content = "O sistema foi carregado com sucesso!", Duration = 5 })
