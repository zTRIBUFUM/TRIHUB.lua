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

-- Jogador: Aimbot
local AimbotEnabled = false
local AimbotOnHead = false
Tabs.Jogador:AddToggle("Aimbot", { Title = "Aimbot" }):OnChanged(function(Value)
    AimbotEnabled = Value
end)

Tabs.Jogador:AddToggle("AimbotOnHead", { Title = "Aimbot na Cabeça" }):OnChanged(function(Value)
    AimbotOnHead = Value
end)

local function getClosestEnemy()
    local localPlayer = game.Players.LocalPlayer
    local closestEnemy = nil
    local shortestDistance = math.huge

    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= localPlayer and player.Team ~= localPlayer.Team and player.Character and player.Character:FindFirstChild("Head") then
            local distance = (localPlayer.Character.Head.Position - player.Character.Head.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestEnemy = player
            end
        end
    end

    return closestEnemy
end

game:GetService("RunService").RenderStepped:Connect(function()
    if AimbotEnabled then
        local closestEnemy = getClosestEnemy()
        if closestEnemy and closestEnemy.Character and closestEnemy.Character:FindFirstChild("Head") then
            local aimPart = AimbotOnHead and closestEnemy.Character.Head or closestEnemy.Character.PrimaryPart
            if aimPart then
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, aimPart.Position)
            end
        end
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
