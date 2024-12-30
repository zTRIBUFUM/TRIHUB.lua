local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Variável para controle de exibição da interface
local isInterfaceVisible = false

-- Criar pop-up inicial
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Popup = Instance.new("ImageButton", ScreenGui)
Popup.Name = "Popup"
Popup.Size = UDim2.new(0, 400, 0, 200)
Popup.Position = UDim2.new(0.5, -200, 0.5, -100)
Popup.AnchorPoint = Vector2.new(0.5, 0.5)
Popup.Image = "rbxassetid://100742801634817"
Popup.BackgroundTransparency = 1

-- Ocultar pop-up e alternar interface ao clicar
Popup.MouseButton1Click:Connect(function()
    isInterfaceVisible = not isInterfaceVisible
    if isInterfaceVisible then
        Window:SetVisible(true)
    else
        Window:SetVisible(false)
    end
end)

-- Criar janela principal
local Window = Fluent:CreateWindow({
    Title = "TRIHUB",
    SubTitle = " (discord.gg/NSrkdKHxZn)",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Definir como invisível no início
Window:SetVisible(false)

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
-- Misc: Walk On Water
local WalkZone = "Ocean"
local WalkOnWater = Tabs.Misc:AddToggle("WalkOnWater", {Title = "Walk On Water", Default = false })
WalkOnWater:OnChanged(function()
    for i, v in pairs(workspace.zones.fishing:GetChildren()) do
        if v.Name == WalkZone then
            v.CanCollide = WalkOnWater.Value
            if v.Name == "Ocean" then
                for _, subZone in pairs(workspace.zones.fishing:GetChildren()) do
                    if subZone.Name == "Deep Ocean" then
                        subZone.CanCollide = WalkOnWater.Value
                    end
                end
            end
        end
    end
end)

local WalkOnWaterZone = Tabs.Misc:AddDropdown("WalkOnWaterZone", {
    Title = "Walk On Water Zone",
    Values = {"Ocean", "Desolate Deep", "The Depths"},
    Multi = false,
    Default = "Ocean",
})
WalkOnWaterZone:OnChanged(function(Value)
    WalkZone = Value
end)

local WalkSpeedSliderUI = Tabs.Misc:AddSlider("WalkSpeedSliderUI", {
    Title = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Rounding = 1,
})
WalkSpeedSliderUI:OnChanged(function(value)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
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

-- ESP: Funções agrupadas
local espEnabled = false

local function addESP(player)
    if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
        local billboard = Instance.new("BillboardGui", player.Character.Head)
        billboard.Name = "ESP"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.AlwaysOnTop = true

        local textLabel = Instance.new("TextLabel", billboard)
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        textLabel.Text = player.Name
    end
end

local function removeESP(player)
    if player.Character and player.Character:FindFirstChild("Head") then
        local esp = player.Character.Head:FindFirstChild("ESP")
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
