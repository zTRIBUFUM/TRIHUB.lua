-- // TRIX HUB v4 - Aimbot Ultra + ESP Completo \\
-- // Sistema Otimizado com Kavo UI \\
-- // NOVA INTERFACE - KAVO UI (MAIS ESTÁVEL) \\
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/Kavo.lua"))()
local Window = Library.CreateLib("🔮 TRIX HUB v4", "BloodTheme")

-- // CONFIGURAÇÕES \\
local Settings = {
    Aimbot = {
        Enabled = false,
        Smoothness = 0.12,
        FOVRadius = 200,
        TeamCheck = false,
        WallCheck = false,
        HitPart = "Head",
        Prediction = true,
        PredictionAmount = 0.135,
        LockTarget = true,
        Magnetic = true,
        MagneticStrength = 0.3,
        Triggerbot = false,
        TriggerbotDelay = 0.05,
        VisibleOnly = false,
        MaxDistance = 500,
        AimBind = "RightButton",
        TargetPriority = "Crosshair",
        SilentAim = true,
        NearestTarget = true
    },
    Visuals = {
        FOVCircle = true,
        BoxESP = true,
        SkeletonESP = false,
        Tracers = false,
        ShowNames = true,
        ShowHealth = true,
        ShowDistance = true,
        ShowHeadDot = false,
        ShowHealthBarText = true,
        BoxType = "2D",
        TracerType = "Bottom",
        FOVColor = Color3.fromRGB(180, 0, 255),
        FOVTransparency = 0.6,
        BoxVisibleColor = Color3.fromRGB(0, 255, 0),
        BoxWallColor = Color3.fromRGB(255, 0, 0),
        TracerColor = Color3.fromRGB(0, 255, 0),
        SkeletonColor = Color3.fromRGB(255, 255, 255),
        Chams = false,
        ChamsColor = Color3.fromRGB(0, 255, 255)
    }
}

-- // VARIÁVEIS GLOBAIS \\
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- // VARIÁVEIS DE ESTADO \\
local CurrentTarget = nil
local CacheESP = {}
local ESPEnabled = true
local ChamsCache = {}

-- // FUNÇÕES AUXILIARES \\
local function GetClosestPlayerToCursor()
    local closest = nil
    local shortestDistance = Settings.Aimbot.FOVRadius
    
    local mouseLocation = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            if humanoid.Health > 0 then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local vector, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local distance = (Vector2.new(vector.X, vector.Y) - mouseLocation).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closest = player
                        end
                    end
                end
            end
        end
    end
    
    return closest
end

-- // AIMBOT MELHORADO \\
local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

local function IsVisible(character)
    if not character or not LocalPlayer.Character then return true end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso")
    local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("UpperTorso")
    
    if not rootPart or not localRoot then return true end
    
    RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    
    local direction = (rootPart.Position - localRoot.Position)
    local raycastResult = workspace:Raycast(localRoot.Position, direction, RaycastParams)
    
    return not raycastResult or raycastResult.Instance:IsDescendantOf(character)
end

local function GetPredictedPosition(character, hitPart)
    if not Settings.Aimbot.Prediction then return hitPart.Position end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local velocity = rootPart and rootPart.AssemblyLinearVelocity or Vector3.zero
    local prediction = velocity * Settings.Aimbot.PredictionAmount
    
    return hitPart.Position + prediction
end

local function GetBestTarget()
    local bestTarget = nil
    local bestScore = Settings.Aimbot.FOVRadius + 1
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                
                if Settings.Aimbot.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                    continue
                end
                
                if Settings.Aimbot.VisibleOnly and not IsVisible(player.Character) then
                    continue
                end
                
                local targetPart = nil
                if Settings.Aimbot.HitPart == "Head" then
                    targetPart = player.Character:FindFirstChild("Head")
                elseif Settings.Aimbot.HitPart == "UpperTorso" then
                    targetPart = player.Character:FindFirstChild("UpperTorso")
                else
                    targetPart = player.Character:FindFirstChild("HumanoidRootPart")
                end
                
                if not targetPart then
                    targetPart = player.Character:FindFirstChild("HumanoidRootPart")
                end
                
                if targetPart then
                    local distance = (targetPart.Position - Camera.CFrame.Position).Magnitude
                    if distance > Settings.Aimbot.MaxDistance then
                        continue
                    end
                    
                    local predictedPos = GetPredictedPosition(player.Character, targetPart)
                    local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
                    
                    if onScreen then
                        local centerScreen = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                        local aimDistance = (Vector2.new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
                        
                        local score = aimDistance
                        if Settings.Aimbot.TargetPriority == "Distance" then
                            score = distance
                        end
                        
                        if score < bestScore and aimDistance <= Settings.Aimbot.FOVRadius then
                            bestScore = score
                            bestTarget = targetPart
                        end
                    end
                end
            end
        end
    end
    
    return bestTarget
end

local function IsAimPressed()
    if Settings.Aimbot.AimBind == "RightButton" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif Settings.Aimbot.AimBind == "LeftButton" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    else
        return UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
    end
end

-- // SILENT AIM \\
local function GetClosestPartToCursor()
    local closestPart = nil
    local shortestDistance = Settings.Aimbot.FOVRadius
    local mouseLocation = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            if humanoid.Health > 0 then
                local parts = {"Head", "UpperTorso", "HumanoidRootPart"}
                for _, partName in pairs(parts) do
                    local part = player.Character:FindFirstChild(partName)
                    if part then
                        local vector, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local distance = (Vector2.new(vector.X, vector.Y) - mouseLocation).Magnitude
                            if distance < shortestDistance then
                                shortestDistance = distance
                                closestPart = part
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closestPart
end

-- // HOOK PARA SILENT AIM \\
local oldNameCall
if Settings.Aimbot.SilentAim then
    oldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        if method == "Fire" and self == LocalPlayer.Character:FindFirstChildWhichIsA("Tool") and Settings.Aimbot.Enabled and IsAimPressed() then
            local targetPart = GetClosestPartToCursor()
            if targetPart then
                local predictedPos = GetPredictedPosition(targetPart.Parent, targetPart)
                args[1] = predictedPos
                return oldNameCall(self, unpack(args))
            end
        end
        
        return oldNameCall(self, ...)
    end)
end

-- // FOV CIRCLE \\
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Color = Settings.Visuals.FOVColor
FOVCircle.Transparency = Settings.Visuals.FOVTransparency
FOVCircle.Filled = false
FOVCircle.NumSides = 128
FOVCircle.Visible = false
FOVCircle.Radius = Settings.Aimbot.FOVRadius
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

local function UpdateFOVCircle()
    if Settings.Visuals.FOVCircle and Settings.Aimbot.Enabled then
        FOVCircle.Visible = true
        FOVCircle.Radius = Settings.Aimbot.FOVRadius
        FOVCircle.Color = Settings.Visuals.FOVColor
        FOVCircle.Transparency = Settings.Visuals.FOVTransparency
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    else
        FOVCircle.Visible = false
    end
end

-- // CHAMS \\
local function CreateChams(character)
    if not Settings.Visuals.Chams then return end
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local highlight = Instance.new("Highlight")
            highlight.Parent = part
            highlight.FillColor = Settings.Visuals.ChamsColor
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.OutlineTransparency = 0.3
            table.insert(ChamsCache, highlight)
        end
    end
end

local function RemoveChams()
    for _, highlight in pairs(ChamsCache) do
        pcall(function() highlight:Destroy() end)
    end
    ChamsCache = {}
end

-- // ESP FUNCTIONS (SIMPLIFICADAS E OTIMIZADAS) \\
local function CreateBoxESP()
    local box = {
        Top = Drawing.new("Line"),
        Bottom = Drawing.new("Line"),
        Left = Drawing.new("Line"),
        Right = Drawing.new("Line")
    }
    
    for _, line in pairs(box) do
        line.Thickness = 2
        line.Transparency = 0.7
        line.Visible = false
    end
    
    return box
end

local function CreateTracer()
    local tracer = Drawing.new("Line")
    tracer.Thickness = 2
    tracer.Transparency = 0.6
    tracer.Visible = false
    return tracer
end

local function CreateNameTag(character, player)
    local head = character:FindFirstChild("Head")
    if not head then return nil end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TRIX_NameTag"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 400
    billboard.ResetOnSpawn = false
    billboard.Parent = character
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mainFrame.BackgroundTransparency = 0.4
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    mainFrame.Parent = billboard
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.Parent = mainFrame
    
    local healthContainer = Instance.new("Frame")
    healthContainer.Size = UDim2.new(0.8, 0, 0.15, 0)
    healthContainer.Position = UDim2.new(0.1, 0, 0.55, 0)
    healthContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthContainer.BackgroundTransparency = 0.3
    healthContainer.BorderSizePixel = 1
    healthContainer.Parent = mainFrame
    
    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthContainer
    
    return {
        Billboard = billboard,
        NameLabel = nameLabel,
        HealthBar = healthBar,
        Humanoid = character:FindFirstChild("Humanoid")
    }
end

-- // ATUALIZAR ESP \\
local function UpdateAllESP()
    if not ESPEnabled then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                
                if not CacheESP[player] then
                    CacheESP[player] = {
                        Box = CreateBoxESP(),
                        Tracer = CreateTracer(),
                        NameTag = Settings.Visuals.ShowNames and CreateNameTag(player.Character, player) or nil
                    }
                    
                    if Settings.Visuals.Chams then
                        CreateChams(player.Character)
                    end
                end
                
                local isVisible = IsVisible(player.Character)
                local espData = CacheESP[player]
                local boxColor = isVisible and Settings.Visuals.BoxVisibleColor or Settings.Visuals.BoxWallColor
                
                -- Calcular posição da box
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                local headPart = player.Character:FindFirstChild("Head")
                
                if rootPart and headPart and Settings.Visuals.BoxESP then
                    local rootPos, rootOnScreen = Camera:WorldToViewportPoint(rootPart.Position)
                    local headPos, headOnScreen = Camera:WorldToViewportPoint(headPart.Position)
                    
                    if rootOnScreen and headOnScreen then
                        local height = math.abs(rootPos.Y - headPos.Y) * 2.2
                        local width = height * 0.55
                        local left = rootPos.X - width/2
                        local top = headPos.Y - (height * 0.1)
                        local right = left + width
                        local bottom = top + height
                        
                        espData.Box.Top.From = Vector2.new(left, top)
                        espData.Box.Top.To = Vector2.new(right, top)
                        espData.Box.Bottom.From = Vector2.new(left, bottom)
                        espData.Box.Bottom.To = Vector2.new(right, bottom)
                        espData.Box.Left.From = Vector2.new(left, top)
                        espData.Box.Left.To = Vector2.new(left, bottom)
                        espData.Box.Right.From = Vector2.new(right, top)
                        espData.Box.Right.To = Vector2.new(right, bottom)
                        
                        for _, line in pairs(espData.Box) do
                            line.Color = boxColor
                            line.Visible = true
                        end
                    else
                        for _, line in pairs(espData.Box) do
                            line.Visible = false
                        end
                    end
                end
                
                -- Tracers
                if espData.Tracer and Settings.Visuals.Tracers then
                    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                        if onScreen then
                            local startPos = Settings.Visuals.TracerType == "Bottom" and 
                                Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y) or
                                Vector2.new(Camera.ViewportSize.X/2, 0)
                            
                            espData.Tracer.From = startPos
                            espData.Tracer.To = Vector2.new(pos.X, pos.Y)
                            espData.Tracer.Color = Settings.Visuals.TracerColor
                            espData.Tracer.Visible = true
                        else
                            espData.Tracer.Visible = false
                        end
                    end
                end
                
                -- NameTag
                if espData.NameTag and Settings.Visuals.ShowNames then
                    espData.NameTag.NameLabel.TextColor3 = isVisible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 100, 100)
                    
                    if Settings.Visuals.ShowHealth and espData.NameTag.Humanoid then
                        local healthPercent = espData.NameTag.Humanoid.Health / espData.NameTag.Humanoid.MaxHealth
                        espData.NameTag.HealthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
                        espData.NameTag.HealthBar.BackgroundColor3 = Color3.fromHSV(healthPercent * 0.33, 1, 1)
                    end
                end
            end
        end
    end
end

-- // AIMBOT LOOP MELHORADO \\
local aimbotConnection
local function StartAimbot()
    aimbotConnection = RunService.RenderStepped:Connect(function()
        UpdateFOVCircle()
        
        if not Settings.Aimbot.Enabled then return end
        
        -- Triggerbot
        if Settings.Aimbot.Triggerbot then
            local target = GetBestTarget()
            if target and (target.Position - Camera.CFrame.Position).Magnitude < 100 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(target.Position)
                if onScreen and (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude < 50 then
                    local virtualInput = game:GetService("VirtualInputManager")
                    virtualInput:SendMouseButtonEvent(Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2), 0, true, Enum.UserInputType.MouseButton1, false)
                    task.wait(Settings.Aimbot.TriggerbotDelay)
                    virtualInput:SendMouseButtonEvent(Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2), 0, false, Enum.UserInputType.MouseButton1, false)
                end
            end
        end
        
        -- Aimbot (Camera Lock)
        if not Settings.Aimbot.SilentAim and IsAimPressed() then
            local target = GetBestTarget()
            if target then
                local targetPosition = GetPredictedPosition(target.Parent, target)
                local currentCFrame = Camera.CFrame
                local lookAt = CFrame.lookAt(currentCFrame.Position, targetPosition)
                
                local smoothness = Settings.Aimbot.Smoothness
                if Settings.Aimbot.Magnetic then
                    smoothness = smoothness + Settings.Aimbot.MagneticStrength
                end
                smoothness = math.clamp(smoothness, 0.03, 0.5)
                
                Camera.CFrame = currentCFrame:Lerp(lookAt, smoothness)
                CurrentTarget = target
            else
                CurrentTarget = nil
            end
        end
    end)
end

-- // ESP LOOP \\
local espConnection
local function StartESP()
    espConnection = RunService.RenderStepped:Connect(function()
        if ESPEnabled then
            UpdateAllESP()
        end
    end)
end

-- // CRIAR TABS (KAVO UI) \\
local MainTab = Window:NewTab("🎯 Main")
local AimbotTab = Window:NewTab("⚙️ Aimbot")
local VisualsTab = Window:NewTab("👁️ Visuals")
local ESPTab = Window:NewTab("📦 ESP")
local SettingsTab = Window:NewTab("⚙️ Settings")

-- Main Section
local MainSection = MainTab:NewSection("Controles Principais")
MainSection:NewToggle("ESP Master", "Liga/Desliga todo o ESP", function(v)
    ESPEnabled = v
    if not v then
        for _, data in pairs(CacheESP) do
            if data.Box then
                for _, line in pairs(data.Box) do line.Visible = false end
            end
            if data.Tracer then data.Tracer.Visible = false end
        end
    end
end)

MainSection:NewToggle("Aimbot Master", "Ativa/Desativa o aimbot", function(v)
    Settings.Aimbot.Enabled = v
end)

MainSection:NewKeybind("Aim Bind", "Tecla para ativar aimbot", Enum.KeyCode.MouseButton2, function(key)
    Settings.Aimbot.AimBind = key.Name
end)

MainSection:NewButton("Unload Script", "Remove o script", function()
    for _, data in pairs(CacheESP) do
        if data.Box then
            for _, line in pairs(data.Box) do pcall(function() line:Remove() end) end
        end
        if data.Tracer then pcall(function() data.Tracer:Remove() end) end
        if data.NameTag and data.NameTag.Billboard then pcall(function() data.NameTag.Billboard:Destroy() end) end
    end
    RemoveChams()
    FOVCircle:Remove()
    if aimbotConnection then aimbotConnection:Disconnect() end
    if espConnection then espConnection:Disconnect() end
    Library:Unload()
end)

-- Aimbot Section
local AimbotSection = AimbotTab:NewSection("Configurações do Aimbot")
AimbotSection:NewSlider("Smoothness", "Suavidade da mira", 500, 3, 12, function(v)
    Settings.Aimbot.Smoothness = v / 100
end)
AimbotSection:NewSlider("FOV Radius", "Raio do campo de mira", 500, 50, 200, function(v)
    Settings.Aimbot.FOVRadius = v
end)
AimbotSection:NewSlider("Max Distance", "Distância máxima", 1000, 100, 500, function(v)
    Settings.Aimbot.MaxDistance = v
end)
AimbotSection:NewSlider("Prediction Amount", "Quantidade de predição", 35, 5, 15, function(v)
    Settings.Aimbot.PredictionAmount = v / 100
end)

AimbotSection:NewDropdown("Hit Part", "Parte do corpo para mirar", {"Head", "UpperTorso", "HumanoidRootPart"}, function(v)
    Settings.Aimbot.HitPart = v
end)

AimbotSection:NewDropdown("Target Priority", "Prioridade do alvo", {"Crosshair", "Distance"}, function(v)
    Settings.Aimbot.TargetPriority = v
end)

AimbotSection:NewToggle("Prediction", "Predição de movimento", function(v)
    Settings.Aimbot.Prediction = v
end)

AimbotSection:NewToggle("Lock Target", "Trava no alvo", function(v)
    Settings.Aimbot.LockTarget = v
end)

AimbotSection:NewToggle("Silent Aim", "Aim sem mover câmera (MAIS EFICAZ)", function(v)
    Settings.Aimbot.SilentAim = v
end)

AimbotSection:NewToggle("Triggerbot", "Atira automaticamente", function(v)
    Settings.Aimbot.Triggerbot = v
end)

AimbotSection:NewSlider("Triggerbot Delay", "Delay do triggerbot", 200, 10, 50, function(v)
    Settings.Aimbot.TriggerbotDelay = v / 1000
end)

-- Visuals Section
local VisualsSection = VisualsTab:NewSection("Configurações Visuais")
VisualsSection:NewToggle("FOV Circle", "Mostrar círculo do FOV", function(v)
    Settings.Visuals.FOVCircle = v
end)

VisualsSection:NewColorPicker("FOV Color", "Cor do círculo", Color3.fromRGB(180, 0, 255), function(v)
    Settings.Visuals.FOVColor = v
end)

-- ESP Section
local ESPSection = ESPTab:NewSection("Configurações de ESP")
ESPSection:NewToggle("Box ESP", "Mostrar caixa ao redor do player", function(v)
    Settings.Visuals.BoxESP = v
end)

ESPSection:NewColorPicker("Box Color (Visible)", "Cor da caixa quando visível", Color3.fromRGB(0, 255, 0), function(v)
    Settings.Visuals.BoxVisibleColor = v
end)

ESPSection:NewColorPicker("Box Color (Wall)", "Cor da caixa atrás de parede", Color3.fromRGB(255, 0, 0), function(v)
    Settings.Visuals.BoxWallColor = v
end)

ESPSection:NewToggle("Tracers", "Mostrar linha até o player", function(v)
    Settings.Visuals.Tracers = v
end)

ESPSection:NewColorPicker("Tracer Color", "Cor do tracer", Color3.fromRGB(0, 255, 0), function(v)
    Settings.Visuals.TracerColor = v
end)

ESPSection:NewDropdown("Tracer Origin", "Origem do tracer", {"Bottom", "Top"}, function(v)
    Settings.Visuals.TracerType = v
end)

ESPSection:NewToggle("Name Tags", "Mostrar nome do player", function(v)
    Settings.Visuals.ShowNames = v
end)

ESPSection:NewToggle("Health Bar", "Mostrar barra de vida", function(v)
    Settings.Visuals.ShowHealth = v
end)

ESPSection:NewToggle("Chams", "Highlight nos players (mais visível)", function(v)
    Settings.Visuals.Chams = v
    if not v then RemoveChams() end
end)

ESPSection:NewColorPicker("Chams Color", "Cor do Chams", Color3.fromRGB(0, 255, 255), function(v)
    Settings.Visuals.ChamsColor = v
end)

-- Settings Section
local SettingsSection = SettingsTab:NewSection("Configurações Extras")
SettingsSection:NewToggle("Team Check", "Não mira no time", function(v)
    Settings.Aimbot.TeamCheck = v
end)

SettingsSection:NewToggle("Wall Check", "Verifica paredes", function(v)
    Settings.Aimbot.WallCheck = v
end)

SettingsSection:NewToggle("Visible Only", "Só mira se estiver visível", function(v)
    Settings.Aimbot.VisibleOnly = v
end)

-- Inicializar
StartAimbot()
StartESP()

-- Notificação
Library:Notification("TRIX HUB v4", "Aimbot Ultra + ESP Completo carregado!", "✅")

print("TRIX HUB v4 - Carregado com sucesso!")
print("Aimbot melhorado com Silent Aim e otimizações!")
