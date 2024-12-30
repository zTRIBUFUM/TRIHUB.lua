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
            if hit.Name == "Ocean" then
                rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 0, rootPart.Velocity.Z)
            end
        end)
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
Tabs.ESP:AddToggle("ESPPlayer", { Title = "ESP Player" }):OnChanged(function(Value)
    if Value then
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                local character = player.Character or player.CharacterAdded:Wait()
                local billboard = Instance.new("BillboardGui", character:WaitForChild("Head"))
                billboard.Name = "ESP"
                billboard.Size = UDim2.new(0, 200, 0, 50)
                billboard.AlwaysOnTop = true

                local textLabel = Instance.new("TextLabel", billboard)
                textLabel.Size = UDim2.new(1, 0, 1, 0)
                textLabel.BackgroundTransparency = 1
                textLabel.TextColor3 = Color3.fromRGB(128, 0, 128) -- Roxo
                textLabel.Text = player.Name
            end
        end
    else
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("ESP") then
                player.Character.ESP:Destroy()
            end
        end
    end
end)

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
