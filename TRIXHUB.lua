-- // TRIX HUB - Aimbot Fortalecido v4 (COMPLETO E FUNCIONAL) \\
-- // Aimbot + ESP Totalmente Funcionais \\

task.wait(2)

-- Verificar se o Rayfield já está carregado
local RayfieldLoaded = false
local Rayfield

local function LoadRayfield()
    local success, result = pcall(function()
        return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    
    if success and result then
        Rayfield = result
        RayfieldLoaded = true
        return true
    end
    return false
end

-- Tentar carregar o Rayfield com retry
for i = 1, 3 do
    if LoadRayfield() then break end
    task.wait(1)
end

if not RayfieldLoaded then
    warn("Falha ao carregar Rayfield")
    return
end

-- Criar Interface
local Window = Rayfield:CreateWindow({ 
    Name = "🔮 TRIX HUB v4", 
    LoadingTitle = "Carregando...",
    LoadingSubtitle = "Aimbot + ESP Completo"
})
task.wait(1)

-- Configurações principais
local Settings = {
    Aimbot = {
        Enabled = false,
        Smoothness = 0.12,
        FOVRadius = 200,
        TeamCheck = false,
        WallCheck = true,
        HitPart = "Head",
        Prediction = true,
        PredictionAmount = 0.12,
        LockTarget = true,
        Magnetic = true,
        MagneticStrength = 0.35,
        Triggerbot = false,
        TriggerbotDelay = 0.05,
        VisibleOnly = false,
        MaxDistance = 400,
        AimBind = "RightButton",
        TargetPriority = "Crosshair",
        AutoShoot = false,
        AutoShootDelay = 0.05,
        SwitchTargetDelay = 0.3,
        FOVVisible = true,
        NearestHitbox = true,
        AntiReset = true,
        SmoothType = "Sine"
    },
    Visuals = {
        FOVCircle = true,
        ESP = false,
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
        FOVColor = Color3.fromRGB(0, 255, 255),
        FOVTransparency = 0.6,
        BoxColor = Color3.fromRGB(0, 255, 0),
        BoxVisibleColor = Color3.fromRGB(0, 255, 0),
        BoxWallColor = Color3.fromRGB(255, 0, 0),
        TracerColor = Color3.fromRGB(0, 255, 0),
        SkeletonColor = Color3.fromRGB(255, 255, 255)
    }
}

-- Variáveis globais
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Variáveis de estado
local CurrentTarget = nil
local CurrentTargetPart = nil
local LastTargetTime = 0
local CacheESP = {}
local ESPEnabled = false
local LastShootTime = 0

-- Criar FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Color = Settings.Visuals.FOVColor
FOVCircle.Transparency = Settings.Visuals.FOVTransparency
FOVCircle.Filled = false
FOVCircle.NumSides = 128
FOVCircle.Visible = false
FOVCircle.Radius = Settings.Aimbot.FOVRadius
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

-- Criar mira personalizada
local Crosshair = Drawing.new("Circle")
Crosshair.Thickness = 1
Crosshair.Color = Color3.fromRGB(255, 255, 255)
Crosshair.Transparency = 0.7
Crosshair.Filled = false
Crosshair.NumSides = 16
Crosshair.Radius = 10
Crosshair.Visible = true
Crosshair.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

local CrosshairDot = Drawing.new("Circle")
CrosshairDot.Thickness = 0
CrosshairDot.Color = Color3.fromRGB(255, 0, 0)
CrosshairDot.Transparency = 0.4
CrosshairDot.Filled = true
CrosshairDot.Radius = 2
CrosshairDot.Visible = true
CrosshairDot.Position = Crosshair.Position

local CrosshairOuter = Drawing.new("Circle")
CrosshairOuter.Thickness = 0.5
CrosshairOuter.Color = Color3.fromRGB(0, 0, 0)
CrosshairOuter.Transparency = 0.5
CrosshairOuter.Filled = false
CrosshairOuter.Radius = 12
CrosshairOuter.Visible = true
CrosshairOuter.Position = Crosshair.Position

-- Atualizar posição central
local function UpdateCenter()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Position = center
    Crosshair.Position = center
    CrosshairDot.Position = center
    CrosshairOuter.Position = center
end

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateCenter)
UpdateCenter()

-- Raycast para visibilidade
local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

local function IsPlayerVisible(character)
    if not character or not LocalPlayer.Character then return true end
    
    local headPart = character:FindFirstChild("Head")
    local localHead = LocalPlayer.Character:FindFirstChild("Head")
    
    if not headPart or not localHead then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart or not localRoot then return true end
        headPart = rootPart
        localHead = localRoot
    end
    
    RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    
    local direction = (headPart.Position - localHead.Position)
    local distance = direction.Magnitude
    
    if distance > Settings.Aimbot.MaxDistance then return false end
    
    local raycastResult = workspace:Raycast(localHead.Position, direction.Unit * distance, RaycastParams)
    
    return not raycastResult or raycastResult.Instance:IsDescendantOf(character)
end

-- ==================== FUNÇÕES ESP COMPLETAS ====================

-- Criar Box ESP 2D
local function CreateBoxESP2D()
    local box = {
        Top = Drawing.new("Line"),
        Bottom = Drawing.new("Line"),
        Left = Drawing.new("Line"),
        Right = Drawing.new("Line"),
        Visible = false
    }
    
    for _, line in pairs(box) do
        line.Thickness = 2
        line.Transparency = 0.7
        line.Visible = false
    end
    
    return box
end

-- Criar Corner Box
local function CreateCornerBox()
    local corners = {
        TL_H = Drawing.new("Line"), TL_V = Drawing.new("Line"),
        TR_H = Drawing.new("Line"), TR_V = Drawing.new("Line"),
        BL_H = Drawing.new("Line"), BL_V = Drawing.new("Line"),
        BR_H = Drawing.new("Line"), BR_V = Drawing.new("Line"),
        Visible = false
    }
    
    for _, line in pairs(corners) do
        line.Thickness = 2
        line.Transparency = 0.7
        line.Visible = false
    end
    
    return corners
end

-- Atualizar Box 2D
local function UpdateBox2D(box, position, size, color, isVisible)
    local left, top = position.X, position.Y
    local right, bottom = position.X + size.X, position.Y + size.Y
    
    box.Top.From = Vector2.new(left, top)
    box.Top.To = Vector2.new(right, top)
    box.Bottom.From = Vector2.new(left, bottom)
    box.Bottom.To = Vector2.new(right, bottom)
    box.Left.From = Vector2.new(left, top)
    box.Left.To = Vector2.new(left, bottom)
    box.Right.From = Vector2.new(right, top)
    box.Right.To = Vector2.new(right, bottom)
    
    for _, line in pairs(box) do
        line.Color = color
        line.Visible = isVisible
    end
end

-- Atualizar Corner Box
local function UpdateCornerBox(box, position, size, color, isVisible)
    local left, top = position.X, position.Y
    local right, bottom = position.X + size.X, position.Y + size.Y
    local cornerSize = math.min(15, size.X / 3)
    
    box.TL_H.From = Vector2.new(left, top)
    box.TL_H.To = Vector2.new(left + cornerSize, top)
    box.TL_V.From = Vector2.new(left, top)
    box.TL_V.To = Vector2.new(left, top + cornerSize)
    box.TR_H.From = Vector2.new(right - cornerSize, top)
    box.TR_H.To = Vector2.new(right, top)
    box.TR_V.From = Vector2.new(right, top)
    box.TR_V.To = Vector2.new(right, top + cornerSize)
    box.BL_H.From = Vector2.new(left, bottom - cornerSize)
    box.BL_H.To = Vector2.new(left, bottom)
    box.BL_V.From = Vector2.new(left, bottom)
    box.BL_V.To = Vector2.new(left + cornerSize, bottom)
    box.BR_H.From = Vector2.new(right - cornerSize, bottom)
    box.BR_H.To = Vector2.new(right, bottom)
    box.BR_V.From = Vector2.new(right, bottom - cornerSize)
    box.BR_V.To = Vector2.new(right, bottom)
    
    for _, line in pairs(box) do
        line.Color = color
        line.Visible = isVisible
    end
end

-- Criar Health Bar
local function CreateHealthBar()
    local healthBar = {
        Background = Drawing.new("Line"),
        Fill = Drawing.new("Line")
    }
    healthBar.Background.Thickness = 4
    healthBar.Background.Transparency = 0.5
    healthBar.Fill.Thickness = 4
    healthBar.Fill.Transparency = 0.8
    return healthBar
end

-- Atualizar Health Bar
local function UpdateHealthBar(healthBar, position, size, healthPercent, isVisible)
    if not healthBar then return end
    local barX = position.X - 6
    local barY = position.Y
    local barHeight = size.Y
    local fillHeight = barHeight * healthPercent
    
    healthBar.Background.From = Vector2.new(barX, barY)
    healthBar.Background.To = Vector2.new(barX, barY + barHeight)
    healthBar.Background.Color = Color3.fromRGB(50, 50, 50)
    healthBar.Background.Visible = isVisible
    
    healthBar.Fill.From = Vector2.new(barX, barY + (barHeight - fillHeight))
    healthBar.Fill.To = Vector2.new(barX, barY + barHeight)
    healthBar.Fill.Color = Color3.fromHSV(healthPercent * 0.33, 1, 1)
    healthBar.Fill.Visible = isVisible
end

-- Criar Skeleton
local function CreateSkeletonESP(character)
    local skeleton = {}
    local connections = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
    }
    
    for _, conn in pairs(connections) do
        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Transparency = 0.6
        line.Visible = false
        table.insert(skeleton, {line = line, part1 = conn[1], part2 = conn[2]})
    end
    return skeleton
end

-- Atualizar Skeleton
local function UpdateSkeleton(skeleton, character, color, isVisible)
    for _, bone in pairs(skeleton) do
        local part1 = character:FindFirstChild(bone.part1)
        local part2 = character:FindFirstChild(bone.part2)
        if part1 and part2 then
            local pos1, on1 = Camera:WorldToViewportPoint(part1.Position)
            local pos2, on2 = Camera:WorldToViewportPoint(part2.Position)
            if on1 and on2 then
                bone.line.From = Vector2.new(pos1.X, pos1.Y)
                bone.line.To = Vector2.new(pos2.X, pos2.Y)
                bone.line.Color = color
                bone.line.Visible = isVisible
            else
                bone.line.Visible = false
            end
        else
            bone.line.Visible = false
        end
    end
end

-- Criar Tracer
local function CreateTracer()
    local tracer = Drawing.new("Line")
    tracer.Thickness = 1.5
    tracer.Transparency = 0.6
    tracer.Visible = false
    return tracer
end

-- Atualizar Tracer
local function UpdateTracer(tracer, targetPos, targetType, color)
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
    if not onScreen then tracer.Visible = false return end
    
    local startPos
    if targetType == "Bottom" then
        startPos = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
    elseif targetType == "Head" then
        startPos = Vector2.new(Camera.ViewportSize.X/2, 0)
    else
        startPos = UserInputService:GetMouseLocation()
    end
    
    tracer.From = startPos
    tracer.To = Vector2.new(screenPos.X, screenPos.Y)
    tracer.Color = color
    tracer.Visible = true
end

-- Criar Head Dot
local function CreateHeadDot()
    local dot = Drawing.new("Circle")
    dot.Thickness = 0
    dot.Filled = true
    dot.Radius = 3
    dot.Transparency = 0.4
    dot.Visible = false
    return dot
end

-- NameTag via BillboardGui
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
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 1
    frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    frame.Parent = billboard
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.Parent = frame
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0.25, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.4, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = ""
    distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distanceLabel.TextSize = 10
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.TextXAlignment = Enum.TextXAlignment.Center
    distanceLabel.Parent = frame
    
    local healthBarFrame = Instance.new("Frame")
    healthBarFrame.Size = UDim2.new(0.8, 0, 0.15, 0)
    healthBarFrame.Position = UDim2.new(0.1, 0, 0.7, 0)
    healthBarFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarFrame.BorderSizePixel = 1
    healthBarFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    healthBarFrame.Parent = frame
    
    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBarFrame
    
    local healthText = Instance.new("TextLabel")
    healthText.Size = UDim2.new(1, 0, 0.2, 0)
    healthText.Position = UDim2.new(0, 0, 0.85, 0)
    healthText.BackgroundTransparency = 1
    healthText.Text = ""
    healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthText.TextSize = 9
    healthText.Font = Enum.Font.Gotham
    healthText.TextXAlignment = Enum.TextXAlignment.Center
    healthText.Parent = frame
    
    return {
        Billboard = billboard,
        NameLabel = nameLabel,
        DistanceLabel = distanceLabel,
        HealthBar = healthFill,
        HealthText = healthText,
        Humanoid = character:FindFirstChild("Humanoid")
    }
end

-- Atualizar todo ESP
local function UpdateAllESP()
    if not ESPEnabled then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                
                if not CacheESP[player] then
                    local boxESP = nil
                    if Settings.Visuals.BoxESP then
                        if Settings.Visuals.BoxType == "2D" then
                            boxESP = CreateBoxESP2D()
                        else
                            boxESP = CreateCornerBox()
                        end
                    end
                    
                    CacheESP[player] = {
                        Box = boxESP,
                        HealthBar = Settings.Visuals.ShowHealth and CreateHealthBar() or nil,
                        Skeleton = Settings.Visuals.SkeletonESP and CreateSkeletonESP(player.Character) or nil,
                        NameTag = Settings.Visuals.ShowNames and CreateNameTag(player.Character, player) or nil,
                        Tracer = Settings.Visuals.Tracers and CreateTracer() or nil,
                        HeadDot = Settings.Visuals.ShowHeadDot and CreateHeadDot() or nil
                    }
                end
                
                local isVisible = IsPlayerVisible(player.Character)
                local espData = CacheESP[player]
                local boxColor = isVisible and Settings.Visuals.BoxVisibleColor or Settings.Visuals.BoxWallColor
                
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("UpperTorso")
                local headPart = player.Character:FindFirstChild("Head")
                
                if rootPart and headPart then
                    local rootPos, rootOn = Camera:WorldToViewportPoint(rootPart.Position)
                    local headPos, headOn = Camera:WorldToViewportPoint(headPart.Position)
                    
                    if rootOn and headOn then
                        local height = math.abs(rootPos.Y - headPos.Y) * 2.3
                        local width = height * 0.55
                        local boxPos = Vector2.new(rootPos.X - width/2, headPos.Y - (height * 0.1))
                        local boxSize = Vector2.new(width, height)
                        
                        if espData.Box and Settings.Visuals.BoxESP then
                            if Settings.Visuals.BoxType == "2D" then
                                UpdateBox2D(espData.Box, boxPos, boxSize, boxColor, true)
                            else
                                UpdateCornerBox(espData.Box, boxPos, boxSize, boxColor, true)
                            end
                        end
                        
                        if espData.HealthBar and Settings.Visuals.ShowHealth then
                            local healthPercent = math.max(0, humanoid.Health / humanoid.MaxHealth)
                            UpdateHealthBar(espData.HealthBar, boxPos, boxSize, healthPercent, true)
                        end
                    elseif espData.Box then
                        for _, line in pairs(espData.Box) do line.Visible = false end
                        if espData.HealthBar then
                            espData.HealthBar.Background.Visible = false
                            espData.HealthBar.Fill.Visible = false
                        end
                    end
                end
                
                if espData.Skeleton and Settings.Visuals.SkeletonESP then
                    UpdateSkeleton(espData.Skeleton, player.Character, Settings.Visuals.SkeletonColor, true)
                elseif espData.Skeleton then
                    for _, bone in pairs(espData.Skeleton) do bone.line.Visible = false end
                end
                
                if espData.NameTag and Settings.Visuals.ShowNames then
                    espData.NameTag.NameLabel.TextColor3 = isVisible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 100, 100)
                    
                    if Settings.Visuals.ShowDistance and rootPart then
                        local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if localRoot then
                            local distance = math.floor((rootPart.Position - localRoot.Position).Magnitude)
                            espData.NameTag.DistanceLabel.Text = distance .. "s"
                        end
                    end
                    
                    if Settings.Visuals.ShowHealth and espData.NameTag.Humanoid then
                        local healthPercent = math.max(0, humanoid.Health / humanoid.MaxHealth)
                        espData.NameTag.HealthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
                        espData.NameTag.HealthBar.BackgroundColor3 = Color3.fromHSV(healthPercent * 0.33, 1, 1)
                        if Settings.Visuals.ShowHealthBarText then
                            espData.NameTag.HealthText.Text = math.floor(humanoid.Health)
                        end
                    end
                    espData.NameTag.Billboard.Enabled = true
                elseif espData.NameTag then
                    espData.NameTag.Billboard.Enabled = false
                end
                
                if espData.Tracer and Settings.Visuals.Tracers and rootPart then
                    UpdateTracer(espData.Tracer, rootPart.Position, Settings.Visuals.TracerType, Settings.Visuals.TracerColor)
                elseif espData.Tracer then
                    espData.Tracer.Visible = false
                end
                
                if espData.HeadDot and Settings.Visuals.ShowHeadDot and headPart then
                    local headPos, headOn = Camera:WorldToViewportPoint(headPart.Position)
                    if headOn then
                        espData.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                        espData.HeadDot.Color = isVisible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                        espData.HeadDot.Visible = true
                    else
                        espData.HeadDot.Visible = false
                    end
                elseif espData.HeadDot then
                    espData.HeadDot.Visible = false
                end
            end
        end
    end
    
    -- Limpar jogadores que saíram
    for player, data in pairs(CacheESP) do
        if not player or not player.Parent or not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then
            if data.Box then for _, line in pairs(data.Box) do pcall(function() line:Remove() end) end end
            if data.HealthBar then pcall(function() data.HealthBar.Background:Remove() end) pcall(function() data.HealthBar.Fill:Remove() end) end
            if data.Skeleton then for _, bone in pairs(data.Skeleton) do pcall(function() bone.line:Remove() end) end end
            if data.NameTag and data.NameTag.Billboard then pcall(function() data.NameTag.Billboard:Destroy() end) end
            if data.Tracer then pcall(function() data.Tracer:Remove() end) end
            if data.HeadDot then pcall(function() data.HeadDot:Remove() end) end
            CacheESP[player] = nil
        end
    end
end

-- Limpar ESP
local function ClearAllESP()
    for _, data in pairs(CacheESP) do
        if data.Box then for _, line in pairs(data.Box) do pcall(function() line:Remove() end) end end
        if data.HealthBar then pcall(function() data.HealthBar.Background:Remove() end) pcall(function() data.HealthBar.Fill:Remove() end) end
        if data.Skeleton then for _, bone in pairs(data.Skeleton) do pcall(function() bone.line:Remove() end) end end
        if data.NameTag and data.NameTag.Billboard then pcall(function() data.NameTag.Billboard:Destroy() end) end
        if data.Tracer then pcall(function() data.Tracer:Remove() end) end
        if data.HeadDot then pcall(function() data.HeadDot:Remove() end) end
    end
    CacheESP = {}
end

-- ==================== AIMBOT FUNÇÕES ====================

local function ApplyEasing(t, type)
    if type == "Sine" then return 1 - math.sin(math.pi / 2 * (1 - t))
    elseif type == "Quad" then return t * t
    elseif type == "Cubic" then return t * t * t
    elseif type == "Quart" then return t * t * t * t
    end
    return t
end

local function GetNearestHitbox(character)
    local hitboxes = {"Head", "UpperTorso", "HumanoidRootPart"}
    local bestPart, bestDistance = nil, Settings.Aimbot.FOVRadius + 1
    
    for _, name in ipairs(hitboxes) do
        local part = character:FindFirstChild(name)
        if part then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if dist < bestDistance then
                    bestDistance, bestPart = dist, part
                end
            end
        end
    end
    return bestPart, bestDistance
end

local function GetPredictedPosition(character, hitPart)
    if not Settings.Aimbot.Prediction then return hitPart.Position end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return hitPart.Position end
    
    local velocity = rootPart.AssemblyLinearVelocity
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    local predictionFactor = math.clamp(Settings.Aimbot.PredictionAmount * (distance / 100), 0.05, 0.35)
    
    return hitPart.Position + (velocity * predictionFactor)
end

local function GetAimAngle(position)
    local cameraPos = Camera.CFrame.Position
    local cameraDir = Camera.CFrame.LookVector
    local targetDir = (position - cameraPos).Unit
    local dot = cameraDir:Dot(targetDir)
    return math.acos(math.clamp(dot, -1, 1)) * (180 / math.pi)
end

local function GetBestTarget()
    local bestTarget, bestTargetPart, bestScore = nil, nil, math.huge
    local currentTime = tick()
    
    if Settings.Aimbot.LockTarget and CurrentTarget and CurrentTarget.Parent then
        local char = CurrentTarget.Parent
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local part = char:FindFirstChild(Settings.Aimbot.HitPart) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
            if part and GetAimAngle(part.Position) <= Settings.Aimbot.FOVRadius then
                return part, char
            end
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if Settings.Aimbot.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then goto skip end
                if Settings.Aimbot.VisibleOnly and not IsPlayerVisible(player.Character) then goto skip end
                if Settings.Aimbot.WallCheck and not IsPlayerVisible(player.Character) then goto skip end
                
                local targetPart = player.Character:FindFirstChild(Settings.Aimbot.HitPart) or player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
                if not targetPart then goto skip end
                
                local distance = (targetPart.Position - Camera.CFrame.Position).Magnitude
                if distance > Settings.Aimbot.MaxDistance then goto skip end
                
                local finalPart = targetPart
                local aimDistance = GetAimAngle(GetPredictedPosition(player.Character, targetPart))
                
                if Settings.Aimbot.NearestHitbox then
                    local nearestPart, nearestDist = GetNearestHitbox(player.Character)
                    if nearestPart and nearestDist < aimDistance then
                        finalPart, aimDistance = nearestPart, nearestDist
                    end
                end
                
                if aimDistance > Settings.Aimbot.FOVRadius then goto skip end
                
                local score = Settings.Aimbot.TargetPriority == "Distance" and distance or aimDistance
                if score < bestScore then
                    bestScore, bestTarget, bestTargetPart = score, player.Character, finalPart
                end
                
                ::skip::
            end
        end
    end
    
    if bestTarget then LastTargetTime = currentTime end
    return bestTargetPart, bestTarget
end

local function IsAimPressed()
    local bind = Settings.Aimbot.AimBind
    if bind == "RightButton" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif bind == "LeftButton" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif bind == "MiddleButton" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
    else return UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) end
end

local function SmoothAim(currentCF, targetCF)
    local smoothFactor = math.clamp(Settings.Aimbot.Smoothness + (Settings.Aimbot.Magnetic and CurrentTarget and Settings.Aimbot.MagneticStrength or 0), 0.02, 0.5)
    local easedFactor = ApplyEasing(smoothFactor, Settings.Aimbot.SmoothType)
    return currentCF:Lerp(targetCF, easedFactor)
end

local function AutoShoot()
    if not Settings.Aimbot.AutoShoot or tick() - LastShootTime < Settings.Aimbot.AutoShootDelay then return end
    if CurrentTargetPart and GetAimAngle(CurrentTargetPart.Position) <= 20 then
        LastShootTime = tick()
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            vim:SendMouseButtonEvent(center, 0, true, Enum.UserInputType.MouseButton1, false)
            task.wait(0.01)
            vim:SendMouseButtonEvent(center, 0, false, Enum.UserInputType.MouseButton1, false)
        end)
    end
end

local function Triggerbot()
    if not Settings.Aimbot.Triggerbot or tick() - LastShootTime < Settings.Aimbot.TriggerbotDelay then return end
    local mousePos = UserInputService:GetMouseLocation()
    if (mousePos - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude > 75 then return end
    if CurrentTargetPart then
        local screenPos, onScreen = Camera:WorldToViewportPoint(CurrentTargetPart.Position)
        if onScreen and (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude <= 30 then
            LastShootTime = tick()
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                vim:SendMouseButtonEvent(mousePos, 0, true, Enum.UserInputType.MouseButton1, false)
                task.wait(0.01)
                vim:SendMouseButtonEvent(mousePos, 0, false, Enum.UserInputType.MouseButton1, false)
            end)
        end
    end
end

-- Aimbot loop
local aimbotConnection
local function StartAimbot()
    if aimbotConnection then aimbotConnection:Disconnect() end
    aimbotConnection = RunService.RenderStepped:Connect(function()
        if not Settings.Aimbot.Enabled then 
            CurrentTarget, CurrentTargetPart = nil, nil
            FOVCircle.Visible = false
            return 
        end
        
        FOVCircle.Visible = Settings.Visuals.FOVCircle and Settings.Aimbot.FOVVisible
        FOVCircle.Radius = Settings.Aimbot.FOVRadius
        
        local isAiming = IsAimPressed()
        
        if isAiming or Settings.Aimbot.AutoShoot then
            local targetPart, targetChar = GetBestTarget()
            if targetPart and targetChar then
                CurrentTarget, CurrentTargetPart = targetChar, targetPart
                local predictedPos = GetPredictedPosition(targetChar, targetPart)
                local lookAt = CFrame.lookAt(Camera.CFrame.Position, predictedPos)
                Camera.CFrame = Settings.Aimbot.Smoothness > 0 and SmoothAim(Camera.CFrame, lookAt) or lookAt
                AutoShoot()
            elseif not (Settings.Aimbot.AntiReset and CurrentTarget and CurrentTarget:FindFirstChild("Humanoid") and CurrentTarget.Humanoid:GetState() == Enum.HumanoidStateType.Jumping) then
                CurrentTarget, CurrentTargetPart = nil, nil
            end
        elseif not (Settings.Aimbot.AntiReset and CurrentTarget and CurrentTarget:FindFirstChild("Humanoid") and CurrentTarget.Humanoid:GetState() == Enum.HumanoidStateType.Jumping) then
            CurrentTarget, CurrentTargetPart = nil, nil
        end
        
        Triggerbot()
    end)
end

StartAimbot()

-- ESP loop
local espConnection
local function StartESP()
    if espConnection then espConnection:Disconnect() end
    espConnection = RunService.RenderStepped:Connect(function()
        Crosshair.Visible = true
        CrosshairDot.Visible = true
        CrosshairOuter.Visible = true
        
        if ESPEnabled then
            UpdateAllESP()
        else
            ClearAllESP()
        end
    end)
end

StartESP()

-- ==================== INTERFACE ====================

local MainTab = Window:CreateTab("Main")
local AimTab = Window:CreateTab("Aimbot")
local VisualsTab = Window:CreateTab("Visuals")
local ESPTab = Window:CreateTab("ESP")

-- MAIN TAB
MainTab:CreateToggle({Name = "ESP Master", CurrentValue = false, Callback = function(v) ESPEnabled = v end})
MainTab:CreateToggle({Name = "Aimbot Master", CurrentValue = false, Callback = function(v) Settings.Aimbot.Enabled = v end})
MainTab:CreateDivider()
MainTab:CreateDropdown({Name = "Aim Bind", Options = {"RightButton", "LeftButton", "MiddleButton", "LeftAlt"}, CurrentOption = "RightButton", Callback = function(v) Settings.Aimbot.AimBind = v end})
MainTab:CreateButton({Name = "Unload Script", Callback = function()
    ClearAllESP()
    FOVCircle:Remove()
    Crosshair:Remove()
    CrosshairDot:Remove()
    CrosshairOuter:Remove()
    aimbotConnection:Disconnect()
    espConnection:Disconnect()
    Rayfield:Destroy()
end})

-- AIMBOT TAB
AimTab:CreateSlider({Name = "Smoothness", Range = {0.02, 0.35}, Increment = 0.01, CurrentValue = 0.12, Callback = function(v) Settings.Aimbot.Smoothness = v end})
AimTab:CreateDropdown({Name = "Smooth Type", Options = {"Sine", "Quad", "Cubic", "Quart"}, CurrentOption = "Sine", Callback = function(v) Settings.Aimbot.SmoothType = v end})
AimTab:CreateDivider()
AimTab:CreateSlider({Name = "FOV Radius", Range = {50, 400}, Increment = 5, CurrentValue = 200, Callback = function(v) Settings.Aimbot.FOVRadius = v end})
AimTab:CreateSlider({Name = "Max Distance", Range = {100, 800}, Increment = 10, CurrentValue = 400, Callback = function(v) Settings.Aimbot.MaxDistance = v end})
AimTab:CreateDivider()
AimTab:CreateToggle({Name = "Prediction", CurrentValue = true, Callback = function(v) Settings.Aimbot.Prediction = v end})
AimTab:CreateSlider({Name = "Prediction Amount", Range = {0.05, 0.35}, Increment = 0.01, CurrentValue = 0.12, Callback = function(v) Settings.Aimbot.PredictionAmount = v end})
AimTab:CreateDivider()
AimTab:CreateToggle({Name = "Lock Target", CurrentValue = true, Callback = function(v) Settings.Aimbot.LockTarget = v end})
AimTab:CreateToggle({Name = "Magnetic Aim", CurrentValue = true, Callback = function(v) Settings.Aimbot.Magnetic = v end})
AimTab:CreateToggle({Name = "Nearest Hitbox", CurrentValue = true, Callback = function(v) Settings.Aimbot.NearestHitbox = v end})
AimTab:CreateToggle({Name = "Anti Reset", CurrentValue = true, Callback = function(v) Settings.Aimbot.AntiReset = v end})
AimTab:CreateDivider()
AimTab:CreateToggle({Name = "Auto Shoot", CurrentValue = false, Callback = function(v) Settings.Aimbot.AutoShoot = v end})
AimTab:CreateToggle({Name = "Triggerbot", CurrentValue = false, Callback = function(v) Settings.Aimbot.Triggerbot = v end})
AimTab:CreateDivider()
AimTab:CreateDropdown({Name = "Hit Part", Options = {"Head", "UpperTorso", "HumanoidRootPart"}, CurrentOption = "Head", Callback = function(v) Settings.Aimbot.HitPart = v end})
AimTab:CreateToggle({Name = "Team Check", CurrentValue = false, Callback = function(v) Settings.Aimbot.TeamCheck = v end})
AimTab:CreateToggle({Name = "Wall Check", CurrentValue = true, Callback = function(v) Settings.Aimbot.WallCheck = v end})
AimTab:CreateToggle({Name = "Show FOV", CurrentValue = true, Callback = function(v) Settings.Aimbot.FOVVisible = v end})

-- ESP TAB
ESPTab:CreateToggle({Name = "Box ESP", CurrentValue = true, Callback = function(v) Settings.Visuals.BoxESP = v end})
ESPTab:CreateDropdown({Name = "Box Type", Options = {"2D", "Corner"}, CurrentOption = "2D", Callback = function(v) Settings.Visuals.BoxType = v end})
ESPTab:CreateColorPicker({Name = "Box Color (Visible)", CurrentValue = Settings.Visuals.BoxVisibleColor, Callback = function(v) Settings.Visuals.BoxVisibleColor = v end})
ESPTab:CreateColorPicker({Name = "Box Color (Wall)", CurrentValue = Settings.Visuals.BoxWallColor, Callback = function(v) Settings.Visuals.BoxWallColor = v end})
ESPTab:CreateDivider()
ESPTab:CreateToggle({Name = "Skeleton ESP", CurrentValue = false, Callback = function(v) Settings.Visuals.SkeletonESP = v end})
ESPTab:CreateToggle({Name = "Tracers", CurrentValue = false, Callback = function(v) Settings.Visuals.Tracers = v end})
ESPTab:CreateDropdown({Name = "Tracer Origin", Options = {"Bottom", "Head", "Mouse"}, CurrentOption = "Bottom", Callback = function(v) Settings.Visuals.TracerType = v end})
ESPTab:CreateDivider()
ESPTab:CreateToggle({Name = "Name Tags", CurrentValue = true, Callback = function(v) Settings.Visuals.ShowNames = v end})
ESPTab:CreateToggle({Name = "Health Bar", CurrentValue = true, Callback = function(v) Settings.Visuals.ShowHealth = v end})
ESPTab:CreateToggle({Name = "Show Distance", CurrentValue = true, Callback = function(v) Settings.Visuals.ShowDistance = v end})
ESPTab:CreateToggle({Name = "Head Dot", CurrentValue = false, Callback = function(v) Settings.Visuals.ShowHeadDot = v end})

-- VISUALS TAB
VisualsTab:CreateToggle({Name = "Show FOV Circle", CurrentValue = true, Callback = function(v) Settings.Visuals.FOVCircle = v end})
VisualsTab:CreateColorPicker({Name = "FOV Color", CurrentValue = Settings.Visuals.FOVColor, Callback = function(v) Settings.Visuals.FOVColor = v end})

-- Notificação final
Rayfield:Notify({
    Title = "TRIX HUB v4",
    Content = "Script carregado com sucesso!\nAimbot + ESP totalmente funcionais.\nAtive o Aimbot Master e ESP Master na aba Main!",
    Duration = 8
})

print("TRIX HUB v4 - COMPLETAMENTE FUNCIONAL!")
