--[[
    TRIX HUB v5 - Aimbot + ESP (Otimizado para Xeno Executor)
    100% Client-Side
    Correções principais em relação à v4:
      - Carregamento da Kavo UI protegido com pcall + fallback
      - Removidas chamadas inexistentes (Library:Notification / Library:Unload)
      - hookmetamethod com pcall, espera o Character carregar
      - RaycastFilterType.Exclude (API atual)
      - Keybind tratado por UserInputService (mouse e teclado) com mapa correto
      - Triggerbot usando debounce em vez de task.wait dentro do RenderStepped
      - ESP com cache anti-vazamento + tratamento de respawn (CharacterAdded/Removing)
      - Tudo em pcall para não derrubar o loop principal
]]

------------------------------------------------------------
-- 0) GUARDA: evita carregar duas vezes
------------------------------------------------------------
if _G.TRIX_HUB_LOADED then
    warn("[TRIX HUB] Já está carregado.")
    return
end
_G.TRIX_HUB_LOADED = true

------------------------------------------------------------
-- 1) SERVIÇOS
------------------------------------------------------------
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local VirtualInputManager= game:GetService("VirtualInputManager")
local CoreGui            = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

------------------------------------------------------------
-- 2) CONFIGURAÇÕES
------------------------------------------------------------
local Settings = {
    Aimbot = {
        Enabled         = false,
        Smoothness      = 0.20,
        FOVRadius       = 200,
        TeamCheck       = false,
        VisibleOnly     = false,
        HitPart         = "Head",
        Prediction      = true,
        PredictionAmount= 0.135,
        Triggerbot      = false,
        TriggerbotDelay = 0.05,
        MaxDistance     = 500,
        AimBind         = "MouseButton2", -- MouseButton1, MouseButton2, ou nome de KeyCode (LeftAlt, E...)
        TargetPriority  = "Crosshair",    -- Crosshair | Distance
        SilentAim       = false,          -- desligado por padrão (depende do remote do jogo)
    },
    Visuals = {
        FOVCircle        = true,
        BoxESP           = true,
        Tracers          = false,
        ShowNames        = true,
        ShowHealth       = true,
        Chams            = false,
        TracerType       = "Bottom",
        FOVColor         = Color3.fromRGB(180, 0, 255),
        FOVTransparency  = 0.6,
        BoxVisibleColor  = Color3.fromRGB(0, 255, 0),
        BoxWallColor     = Color3.fromRGB(255, 0, 0),
        TracerColor      = Color3.fromRGB(0, 255, 0),
        ChamsColor       = Color3.fromRGB(0, 255, 255),
    },
}

------------------------------------------------------------
-- 3) CARREGAR KAVO UI COM SEGURANÇA
------------------------------------------------------------
local Library
local okLib, errLib = pcall(function()
    Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/Kavo.lua"))()
end)
if not okLib or not Library then
    warn("[TRIX HUB] Falha ao carregar Kavo UI: "..tostring(errLib))
    return
end

local Window
local okWin, errWin = pcall(function()
    Window = Library.CreateLib("TRIX HUB v5", "BloodTheme")
end)
if not okWin or not Window then
    warn("[TRIX HUB] Falha ao criar janela: "..tostring(errWin))
    return
end

------------------------------------------------------------
-- 4) ESTADO INTERNO
------------------------------------------------------------
local ESPEnabled    = true
local CacheESP      = {}   -- [player] = {Box={}, Tracer, NameTag, Highlights={}, charConn}
local CurrentTarget = nil
local LastTriggerShot = 0

------------------------------------------------------------
-- 5) UTILIDADES
------------------------------------------------------------
local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[TRIX HUB] "..tostring(err)) end
end

local function getCharParts(char)
    if not char then return nil, nil, nil end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
    local head = char:FindFirstChild("Head")
    return hum, root, head
end

------------------------------------------------------------
-- 6) RAYCAST – wall check (API atual)
------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function IsVisible(character)
    if not character then return false end
    local _, targetRoot = getCharParts(character)
    local _, localRoot  = getCharParts(LocalPlayer.Character)
    if not targetRoot or not localRoot then return false end

    rayParams.FilterDescendantsInstances = { LocalPlayer.Character, character }
    local dir = targetRoot.Position - localRoot.Position
    local result = workspace:Raycast(localRoot.Position, dir, rayParams)
    if not result then return true end
    return result.Instance:IsDescendantOf(character)
end

------------------------------------------------------------
-- 7) PREDIÇÃO
------------------------------------------------------------
local function GetPredictedPosition(character, hitPart)
    if not hitPart then return Vector3.zero end
    if not Settings.Aimbot.Prediction then return hitPart.Position end
    local _, root = getCharParts(character)
    local vel = (root and root.AssemblyLinearVelocity) or Vector3.zero
    return hitPart.Position + vel * Settings.Aimbot.PredictionAmount
end

------------------------------------------------------------
-- 8) MELHOR ALVO
------------------------------------------------------------
local function GetBestTarget()
    local bestTarget, bestScore = nil, Settings.Aimbot.FOVRadius + 1
    local viewCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum, root, head = getCharParts(plr.Character)
            if hum and hum.Health > 0 and root then
                if not (Settings.Aimbot.TeamCheck and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                    if not Settings.Aimbot.VisibleOnly or IsVisible(plr.Character) then
                        local part = plr.Character:FindFirstChild(Settings.Aimbot.HitPart) or head or root
                        local dist = (part.Position - Camera.CFrame.Position).Magnitude
                        if dist <= Settings.Aimbot.MaxDistance then
                            local predicted = GetPredictedPosition(plr.Character, part)
                            local sp, onScreen = Camera:WorldToViewportPoint(predicted)
                            if onScreen then
                                local sd = (Vector2.new(sp.X, sp.Y) - viewCenter).Magnitude
                                local score = (Settings.Aimbot.TargetPriority == "Distance") and dist or sd
                                if sd <= Settings.Aimbot.FOVRadius and score < bestScore then
                                    bestScore = score
                                    bestTarget = part
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

------------------------------------------------------------
-- 9) KEYBIND – mouse e teclado
------------------------------------------------------------
local function IsAimPressed()
    local bind = Settings.Aimbot.AimBind
    if bind == "MouseButton1" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif bind == "MouseButton2" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif bind == "MouseButton3" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
    else
        local key = Enum.KeyCode[bind]
        if key then return UserInputService:IsKeyDown(key) end
    end
    return false
end

------------------------------------------------------------
-- 10) SILENT AIM (somente se o usuário ligar – depende do jogo)
------------------------------------------------------------
local silentAimHooked = false
local function TrySetupSilentAim()
    if silentAimHooked then return end
    if not hookmetamethod then return end -- nem todo executor expõe
    silentAimHooked = true
    local oldNamecall
    local ok, err = pcall(function()
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if Settings.Aimbot.SilentAim and Settings.Aimbot.Enabled and IsAimPressed() then
                if method == "FireServer" or method == "Fire" or method == "InvokeServer" then
                    local target = GetBestTarget()
                    if target then
                        local args = {...}
                        local predicted = GetPredictedPosition(target.Parent, target)
                        for i, v in ipairs(args) do
                            if typeof(v) == "Vector3" then args[i] = predicted end
                            if typeof(v) == "CFrame" then args[i] = CFrame.new(predicted) end
                        end
                        return oldNamecall(self, table.unpack(args))
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
    if not ok then warn("[TRIX HUB] SilentAim hook falhou: "..tostring(err)) end
end

------------------------------------------------------------
-- 11) FOV CIRCLE
------------------------------------------------------------
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness    = 2
FOVCircle.Color        = Settings.Visuals.FOVColor
FOVCircle.Transparency = Settings.Visuals.FOVTransparency
FOVCircle.Filled       = false
FOVCircle.NumSides     = 64
FOVCircle.Visible      = false
FOVCircle.Radius       = Settings.Aimbot.FOVRadius

local function UpdateFOVCircle()
    if Settings.Visuals.FOVCircle and Settings.Aimbot.Enabled then
        FOVCircle.Visible      = true
        FOVCircle.Radius       = Settings.Aimbot.FOVRadius
        FOVCircle.Color        = Settings.Visuals.FOVColor
        FOVCircle.Transparency = Settings.Visuals.FOVTransparency
        FOVCircle.Position     = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    else
        FOVCircle.Visible = false
    end
end

------------------------------------------------------------
-- 12) ESP – Drawing + Highlight
------------------------------------------------------------
local function newLine()
    local l = Drawing.new("Line")
    l.Thickness    = 1.5
    l.Transparency = 1
    l.Visible      = false
    return l
end

local function CreateESPEntry(plr)
    local entry = {
        Box     = { Top=newLine(), Bottom=newLine(), Left=newLine(), Right=newLine() },
        Tracer  = newLine(),
        NameTag = nil,
        Highlights = {},
    }
    return entry
end

local function CreateNameTag(char, plr)
    local head = char:FindFirstChild("Head")
    if not head then return nil end
    if char:FindFirstChild("TRIX_NameTag") then char.TRIX_NameTag:Destroy() end

    local bb = Instance.new("BillboardGui")
    bb.Name = "TRIX_NameTag"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 500
    bb.ResetOnSpawn = false

    local frame = Instance.new("Frame", bb)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0

    local nameLbl = Instance.new("TextLabel", frame)
    nameLbl.Size = UDim2.new(1, 0, 0.55, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = plr.Name
    nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLbl.TextSize = 13
    nameLbl.Font = Enum.Font.GothamBold

    local hpBg = Instance.new("Frame", frame)
    hpBg.Size = UDim2.new(0.85, 0, 0.18, 0)
    hpBg.Position = UDim2.new(0.075, 0, 0.62, 0)
    hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBg.BorderSizePixel = 0

    local hpBar = Instance.new("Frame", hpBg)
    hpBar.Size = UDim2.new(1, 0, 1, 0)
    hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    hpBar.BorderSizePixel = 0

    -- Tenta colocar em CoreGui para não morrer no respawn (se possível)
    local ok = pcall(function() bb.Parent = CoreGui end)
    if not ok then bb.Parent = char end

    return { Billboard = bb, NameLabel = nameLbl, HealthBar = hpBar }
end

local function ApplyChams(char, entry)
    if not Settings.Visuals.Chams then return end
    if entry.Highlights[char] then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = Settings.Visuals.ChamsColor
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0.2
    hl.Parent = char
    entry.Highlights[char] = hl
end

local function ClearEntry(entry)
    if not entry then return end
    for _, line in pairs(entry.Box) do pcall(function() line:Remove() end) end
    if entry.Tracer then pcall(function() entry.Tracer:Remove() end) end
    if entry.NameTag and entry.NameTag.Billboard then
        pcall(function() entry.NameTag.Billboard:Destroy() end)
    end
    for _, hl in pairs(entry.Highlights) do pcall(function() hl:Destroy() end) end
end

local function HideEntry(entry)
    for _, line in pairs(entry.Box) do line.Visible = false end
    if entry.Tracer then entry.Tracer.Visible = false end
end

local function UpdatePlayerESP(plr)
    if plr == LocalPlayer then return end
    local char = plr.Character
    if not char then return end

    local hum, root, head = getCharParts(char)
    if not (hum and hum.Health > 0 and root and head) then
        if CacheESP[plr] then HideEntry(CacheESP[plr]) end
        return
    end

    -- cria entrada se preciso
    if not CacheESP[plr] then
        CacheESP[plr] = CreateESPEntry(plr)
    end
    local entry = CacheESP[plr]

    -- NameTag
    if Settings.Visuals.ShowNames then
        if not entry.NameTag or not entry.NameTag.Billboard or not entry.NameTag.Billboard.Parent then
            entry.NameTag = CreateNameTag(char, plr)
        end
    elseif entry.NameTag then
        pcall(function() entry.NameTag.Billboard:Destroy() end)
        entry.NameTag = nil
    end

    -- Chams
    if Settings.Visuals.Chams then
        ApplyChams(char, entry)
    elseif next(entry.Highlights) then
        for c, hl in pairs(entry.Highlights) do pcall(function() hl:Destroy() end); entry.Highlights[c] = nil end
    end

    local visible = IsVisible(char)
    local boxColor = visible and Settings.Visuals.BoxVisibleColor or Settings.Visuals.BoxWallColor

    -- Box ESP
    if Settings.Visuals.BoxESP then
        local rootPos, rootOnScreen = Camera:WorldToViewportPoint(root.Position)
        local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
        if rootOnScreen and headOnScreen then
            local h = math.abs(rootPos.Y - headPos.Y) * 2.2
            local w = h * 0.55
            local left, top = rootPos.X - w/2, headPos.Y - h*0.1
            local right, bottom = left + w, top + h

            entry.Box.Top.From    = Vector2.new(left,  top)
            entry.Box.Top.To      = Vector2.new(right, top)
            entry.Box.Bottom.From = Vector2.new(left,  bottom)
            entry.Box.Bottom.To   = Vector2.new(right, bottom)
            entry.Box.Left.From   = Vector2.new(left,  top)
            entry.Box.Left.To     = Vector2.new(left,  bottom)
            entry.Box.Right.From  = Vector2.new(right, top)
            entry.Box.Right.To    = Vector2.new(right, bottom)

            for _, line in pairs(entry.Box) do
                line.Color   = boxColor
                line.Visible = true
            end
        else
            for _, line in pairs(entry.Box) do line.Visible = false end
        end
    else
        for _, line in pairs(entry.Box) do line.Visible = false end
    end

    -- Tracer
    if Settings.Visuals.Tracers then
        local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if onScreen then
            local startPos = Settings.Visuals.TracerType == "Top"
                and Vector2.new(Camera.ViewportSize.X/2, 0)
                 or Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            entry.Tracer.From    = startPos
            entry.Tracer.To      = Vector2.new(pos.X, pos.Y)
            entry.Tracer.Color   = Settings.Visuals.TracerColor
            entry.Tracer.Visible = true
        else
            entry.Tracer.Visible = false
        end
    else
        entry.Tracer.Visible = false
    end

    -- NameTag content update
    if entry.NameTag and Settings.Visuals.ShowNames then
        entry.NameTag.NameLabel.TextColor3 = visible and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 100, 100)
        if Settings.Visuals.ShowHealth and hum.MaxHealth > 0 then
            local p = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            entry.NameTag.HealthBar.Size = UDim2.new(p, 0, 1, 0)
            entry.NameTag.HealthBar.BackgroundColor3 = Color3.fromHSV(p * 0.33, 1, 1)
        end
    end
end

------------------------------------------------------------
-- 13) GERENCIAR PLAYERS (entrada/saída/respawn)
------------------------------------------------------------
local function SetupPlayer(plr)
    if plr == LocalPlayer then return end
    local function onCharRemoving()
        if CacheESP[plr] then HideEntry(CacheESP[plr]) end
    end
    plr.CharacterRemoving:Connect(onCharRemoving)
end

for _, plr in ipairs(Players:GetPlayers()) do SetupPlayer(plr) end
Players.PlayerAdded:Connect(SetupPlayer)
Players.PlayerRemoving:Connect(function(plr)
    if CacheESP[plr] then
        ClearEntry(CacheESP[plr])
        CacheESP[plr] = nil
    end
end)

------------------------------------------------------------
-- 14) LOOP PRINCIPAL (RenderStepped)
------------------------------------------------------------
local mainConn
mainConn = RunService.RenderStepped:Connect(function()
    safe(UpdateFOVCircle)

    -- ESP
    if ESPEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            safe(UpdatePlayerESP, plr)
        end
    else
        for _, e in pairs(CacheESP) do HideEntry(e) end
    end

    if not Settings.Aimbot.Enabled then return end

    -- Triggerbot (sem task.wait dentro do RenderStepped)
    if Settings.Aimbot.Triggerbot then
        local now = tick()
        if now - LastTriggerShot >= Settings.Aimbot.TriggerbotDelay then
            local target = GetBestTarget()
            if target then
                local sp, onScreen = Camera:WorldToViewportPoint(target.Position)
                if onScreen then
                    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                    if (Vector2.new(sp.X, sp.Y) - center).Magnitude < 40 then
                        LastTriggerShot = now
                        safe(function()
                            VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true,  game, 1)
                            VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
                        end)
                    end
                end
            end
        end
    end

    -- Aimbot (Camera Lock) – só se SilentAim desligado
    if not Settings.Aimbot.SilentAim and IsAimPressed() then
        local target = GetBestTarget()
        if target then
            local predicted = GetPredictedPosition(target.Parent, target)
            local cur = Camera.CFrame
            local look = CFrame.lookAt(cur.Position, predicted)
            local s = math.clamp(Settings.Aimbot.Smoothness, 0.05, 1)
            Camera.CFrame = cur:Lerp(look, s)
            CurrentTarget = target
        else
            CurrentTarget = nil
        end
    end
end)

------------------------------------------------------------
-- 15) UI – KAVO
------------------------------------------------------------
local MainTab    = Window:NewTab("Main")
local AimbotTab  = Window:NewTab("Aimbot")
local ESPTab     = Window:NewTab("ESP")
local ExtraTab   = Window:NewTab("Extras")

-- MAIN
local MainSec = MainTab:NewSection("Controles principais")
MainSec:NewToggle("Aimbot", "Liga/desliga o aimbot", function(v)
    Settings.Aimbot.Enabled = v
end)
MainSec:NewToggle("ESP Master", "Liga/desliga todo o ESP", function(v)
    ESPEnabled = v
    if not v then for _, e in pairs(CacheESP) do HideEntry(e) end end
end)
MainSec:NewButton("Unload", "Descarrega o script", function()
    safe(function() if mainConn then mainConn:Disconnect() end end)
    for _, e in pairs(CacheESP) do ClearEntry(e) end
    CacheESP = {}
    safe(function() FOVCircle:Remove() end)
    safe(function()
        -- Kavo não tem método oficial de unload; tenta esconder a UI
        for _, gui in ipairs(CoreGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name:lower():find("kavo") then
                gui:Destroy()
            end
        end
    end)
    _G.TRIX_HUB_LOADED = false
end)

-- AIMBOT
local AimSec = AimbotTab:NewSection("Configurações de Aimbot")
AimSec:NewSlider("Smoothness", "Suavidade (1-100)", 100, 5, function(v)
    Settings.Aimbot.Smoothness = v / 100
end)
AimSec:NewSlider("FOV Radius", "Raio do FOV", 600, 50, function(v)
    Settings.Aimbot.FOVRadius = v
end)
AimSec:NewSlider("Max Distance", "Distância máxima (studs)", 2000, 100, function(v)
    Settings.Aimbot.MaxDistance = v
end)
AimSec:NewSlider("Prediction (%)", "Quantidade de predição", 50, 0, function(v)
    Settings.Aimbot.PredictionAmount = v / 100
end)
AimSec:NewDropdown("Hit Part", "Parte do corpo", {"Head","UpperTorso","HumanoidRootPart"}, function(v)
    Settings.Aimbot.HitPart = v
end)
AimSec:NewDropdown("Aim Bind", "Tecla de mira", {"MouseButton2","MouseButton1","MouseButton3","LeftAlt","E","Q","V"}, function(v)
    Settings.Aimbot.AimBind = v
end)
AimSec:NewDropdown("Target Priority", "Prioridade", {"Crosshair","Distance"}, function(v)
    Settings.Aimbot.TargetPriority = v
end)
AimSec:NewToggle("Prediction", "Ativa a predição de movimento", function(v)
    Settings.Aimbot.Prediction = v
end)
AimSec:NewToggle("Visible Only", "Só mira quem está visível", function(v)
    Settings.Aimbot.VisibleOnly = v
end)
AimSec:NewToggle("Team Check", "Não mira no próprio time", function(v)
    Settings.Aimbot.TeamCheck = v
end)
AimSec:NewToggle("Silent Aim (experimental)", "Tenta interceptar remotes (depende do jogo)", function(v)
    Settings.Aimbot.SilentAim = v
    if v then TrySetupSilentAim() end
end)
AimSec:NewToggle("Triggerbot", "Atira automaticamente quando há alvo no centro", function(v)
    Settings.Aimbot.Triggerbot = v
end)
AimSec:NewSlider("Trigger Delay (ms)", "Cooldown do triggerbot", 500, 10, function(v)
    Settings.Aimbot.TriggerbotDelay = v / 1000
end)

-- ESP
local ESec = ESPTab:NewSection("Configurações de ESP")
ESec:NewToggle("Box ESP", "Caixa ao redor dos players", function(v) Settings.Visuals.BoxESP = v end)
ESec:NewToggle("Tracers", "Linha do canto da tela até o player", function(v) Settings.Visuals.Tracers = v end)
ESec:NewDropdown("Tracer Origin", "Origem do tracer", {"Bottom","Top"}, function(v) Settings.Visuals.TracerType = v end)
ESec:NewToggle("Name Tags", "Mostra nomes", function(v) Settings.Visuals.ShowNames = v end)
ESec:NewToggle("Health Bar", "Barra de vida no name tag", function(v) Settings.Visuals.ShowHealth = v end)
ESec:NewToggle("Chams", "Highlight no personagem", function(v)
    Settings.Visuals.Chams = v
    if not v then
        for _, e in pairs(CacheESP) do
            for c, hl in pairs(e.Highlights) do pcall(function() hl:Destroy() end); e.Highlights[c] = nil end
        end
    end
end)
ESec:NewToggle("FOV Circle", "Mostra o círculo do FOV", function(v) Settings.Visuals.FOVCircle = v end)
ESec:NewColorPicker("Box Visible", "Cor (visível)", Settings.Visuals.BoxVisibleColor, function(v) Settings.Visuals.BoxVisibleColor = v end)
ESec:NewColorPicker("Box Wall",    "Cor (parede)",  Settings.Visuals.BoxWallColor,    function(v) Settings.Visuals.BoxWallColor    = v end)
ESec:NewColorPicker("Tracer Color","Cor do tracer", Settings.Visuals.TracerColor,     function(v) Settings.Visuals.TracerColor     = v end)
ESec:NewColorPicker("Chams Color", "Cor do chams",  Settings.Visuals.ChamsColor,      function(v) Settings.Visuals.ChamsColor      = v end)
ESec:NewColorPicker("FOV Color",   "Cor do FOV",    Settings.Visuals.FOVColor,        function(v) Settings.Visuals.FOVColor        = v end)

-- EXTRAS
local XSec = ExtraTab:NewSection("Sobre")
XSec:NewLabel("TRIX HUB v5 - 100% Client Side")
XSec:NewLabel("Otimizado para Xeno Executor")

print("[TRIX HUB v5] Carregado com sucesso.")
