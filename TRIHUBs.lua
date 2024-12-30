-- Carregar bibliotecas
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

-- Outros sistemas...

Window:SelectTab(1)
Fluent:Notify({
    Title = "TRIHUB",
    Content = "O sistema foi carregado com sucesso!",
    Duration = 8
})
