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

-- Função para evitar erros com personagens/características ainda não carregadas
local function getCharacter()
    local player = game.Players.LocalPlayer
    return player.Character or player.CharacterAdded:Wait()
end

-- Jogador: Pulo infinito
local InfiniteJump = false
Tabs.Jogador:AddToggle("InfiniteJump", { Title = "Pulo Infinito" }):OnChanged(function(Value)
    InfiniteJump = Value
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if InfiniteJump then
        local humanoid = getCharacter():FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Jogador: Velocidade de Caminhada
local WalkSpeed = 16
Tabs.Jogador:AddSlider("WalkSpeedSlider", {
    Title = "Velocidade de Caminhada",
    Min = 0,
    Max = 100,
    Default = 16
}):OnChanged(function(Value)
    WalkSpeed = Value
    local humanoid = getCharacter():FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = WalkSpeed
    end
end)

-- Teleporte: Teleport Island
Tabs.Teleporte:AddButton({
    Title = "Teleport Island",
    Callback = function()
        local rootPart = getCharacter():WaitForChild("HumanoidRootPart")
        rootPart.CFrame = CFrame.new(6060.2, 400.4, 628.5)
    end
})

-- ESP: ESP Player com cores de equipe
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

local function refreshESP()
    for _, player in pairs(game.Players:GetPlayers()) do
        addESP(player)
    end
end

Tabs.ESP:AddToggle("ESPPlayer", { Title = "ESP Player" }):OnChanged(function(Value)
    espEnabled = Value
    if espEnabled then
        refreshESP()
    else
        for _, player in pairs(game.Players:GetPlayers()) do
            local head = player.Character and player.Character:FindFirstChild("Head")
            local esp = head and head:FindFirstChild("ESPBox")
            if esp then
                esp:Destroy()
            end
        end
    end
end)

-- Configurações: Controle de Brilho
local brightnessEnabled = false
Tabs.Configuracoes:AddToggle("BrightnessControl", { Title = "Controle de Brilho" }):OnChanged(function(Value)
    brightnessEnabled = Value
    if not brightnessEnabled then
        game:GetService("Lighting").Brightness = 1
    end
end)

Tabs.Configuracoes:AddSlider("BrightnessSlider", {
    Title = "Ajuste de Brilho",
    Min = 0,
    Max = 100,
    Default = 100
}):OnChanged(function(Value)
    if brightnessEnabled then
        game:GetService("Lighting").Brightness = Value / 100
    end
end)

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
