--[[
    TRIX HUB v6 - Aimbot + ESP (Rayfield UI)
    100% Client-Side | Otimizado para Xeno Executor
]]

------------------------------------------------------------
-- 0) ANTI DOUBLE LOAD
------------------------------------------------------------
if _G.TRIX_HUB_LOADED then
    warn("[TRIX HUB] Já está carregado.")
    return
end
_G.TRIX_HUB_LOADED = true

------------------------------------------------------------
-- 1) SERVIÇOS
------------------------------------------------------------
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui             = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

------------------------------------------------------------
-- 2) CONFIG
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
        AimBind         = "MouseButton2",
        TargetPriority  = "Crosshair",
        SilentAim       = false,
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
-- 3) RAYFIELD UI – CARREGAMENTO PROTEGIDO
------------------------------------------------------------
local Rayfield
local okLib, errLib = pcall(function()
    Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not okLib or not Rayfield then
    warn("[TRIX HUB] Falha ao carregar Rayfield: "..tostring(errLib))
    _G.TRIX_HUB_LOADED = false
    return
end

local Window = Rayfield:CreateWindow({
    Name             = "TRIX HUB v6",
    LoadingTitle     = "TRIX HUB",
    LoadingSubtitle  = "by você",
    ConfigurationSaving = {
        Enabled  = true,
        FolderName = "TrixHub",
        FileName   = "Config",
    },
    KeySystem = false,
})

------------------------------------------------------------
-- 4) ESTADO
------------------------------------------------------------
local ESPEnabled      = true
local CacheESP        = {}
local CurrentTarget   = nil
local LastTriggerShot = 0

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
-- 5) WALL CHECK
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
    local result = workspace:Raycast(localRoot.Position, targetRoot.Position - localRoot.Position, rayParams)
    if not result then return true end
    return result.Instance:IsDescendantOf(character)
end

------------------------------------------------------------
-- 6) PREDIÇÃO + MELHOR ALVO
------------------------------------------------------------
local function GetPredictedPosition(character, hitPart)
    if not hitPart then return Vector3.zero end
    if not Settings.Aimbot.Prediction then return hitPart.Position end
    local _, root = getCharParts(character)
    local vel = (root and root.AssemblyLinearVelocity) or Vector3.zero
    return hitPart.Position + vel * Settings.Aimbot.PredictionAmount
end

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
-- 7) KEYBIND
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
-- 8) SILENT AIM (opcional)
------------------------------------------------------------
local silentAimHooked = false
local function TrySetupSilentAim()
    if silentAimHooked then return end
    if not hookmetamethod then return end
    silentAimHooked = true
    local oldNamecall
    safe(function()
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
                            if typeof(v) == "CFrame"  then args[i] = CFrame.new(predicted) end
                        end
                        return oldNamecall(self, table.unpack(args))
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
end

------------------------------------------------------------
-- 9) FOV CIRCLE
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
-- 10) ESP
------------------------------------------------------------
local function newLine()
    local l = Drawing.new("Line")
    l.Thickness    = 1.5
    l.Transparency = 1
    l.Visible      = false
    return l
end

local function CreateESPEntry()
    return {
        Box        = { Top=newLine(), Bottom=newLine(), Left=newLine(), Right=newLine() },
        Tracer     = newLine(),
        NameTag    = nil,
        Highlights = {},
    }
end

local function CreateNameTag(char, plr)
    local head = char:FindFirstChild("Head")
    if not head then return nil end
    if char:FindFirstChild("TRIX_NameTag") then char.TRIX_NameTag:Destroy() end

    local bb = Instance.new("BillboardGui")
    bb.Name        = "TRIX_NameTag"
    bb.Adornee     = head
    bb.Size        = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 500
    bb.ResetOnSpawn= false

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

local function HideEntry(entry)
    for _, line in pairs(entry.Box) do line.Visible = false end
    if entry.Tracer then entry.Tracer.Visible = false end
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

local function UpdatePlayerESP(plr)
    if plr == LocalPlayer then return end
    local char = plr.Character
    if not char then return end

    local hum, root, head = getCharParts(char)
    if not (hum and hum.Health > 0 and root and head) then
        if CacheESP[plr] then HideEntry(CacheESP[plr]) end
        return
    end

    if not CacheESP[plr] then CacheESP[plr] = CreateESPEntry() end
    local entry = CacheESP[plr]

    if Settings.Visuals.ShowNames then
        if not entry.NameTag or not entry.NameTag.Billboard or not entry.NameTag.Billboard.Parent then
            entry.NameTag = CreateNameTag(char, plr)
        end
    elseif entry.NameTag then
        pcall(function() entry.NameTag.Billboard:Destroy() end)
        entry.NameTag = nil
    end

    if Settings.Visuals.Chams then
        ApplyChams(char, entry)
    elseif next(entry.Highlights) then
        for c, hl in pairs(entry.Highlights) do pcall(function() hl:Destroy() end); entry.Highlights[c] = nil end
    end

    local visible = IsVisible(char)
    local boxColor = visible and Settings.Visuals.BoxVisibleColor or Settings.Visuals.BoxWallColor

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
-- 11) PLAYER LIFECYCLE
------------------------------------------------------------
local function SetupPlayer(plr)
    if plr == LocalPlayer then return end
    plr.CharacterRemoving:Connect(function()
        if CacheESP[plr] then HideEntry(CacheESP[plr]) end
    end)
end
for _, plr in ipairs(Players:GetPlayers()) do SetupPlayer(plr) end
Players.PlayerAdded:Connect(SetupPlayer)
Players.PlayerRemoving:Connect(function(plr)
    if CacheESP[plr] then ClearEntry(CacheESP[plr]); CacheESP[plr] = nil end
end)

------------------------------------------------------------
-- 12) LOOP PRINCIPAL
------------------------------------------------------------
local mainConn
mainConn = RunService.RenderStepped:Connect(function()
    safe(UpdateFOVCircle)

    if ESPEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do safe(UpdatePlayerESP, plr) end
    else
        for _, e in pairs(CacheESP) do HideEntry(e) end
    end

    if not Settings.Aimbot.Enabled then return end

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
-- 13) INTERFACE RAYFIELD
------------------------------------------------------------
local MainTab   = Window:CreateTab("Main",    4483362458)
local AimTab    = Window:CreateTab("Aimbot",  4483362458)
local ESPTab    = Window:CreateTab("ESP",     4483362458)
local AboutTab  = Window:CreateTab("Sobre",   4483362458)

-- ===== MAIN =====
MainTab:CreateSection("Controles principais")

MainTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Flag = "AimbotEnabled",
    Callback = function(v) Settings.Aimbot.Enabled = v end,
})

MainTab:CreateToggle({
    Name = "ESP Master",
    CurrentValue = true,
    Flag = "ESPEnabled",
    Callback = function(v)
        ESPEnabled = v
        if not v then for _, e in pairs(CacheESP) do HideEntry(e) end end
    end,
})

MainTab:CreateButton({
    Name = "Unload Script",
    Callback = function()
        safe(function() if mainConn then mainConn:Disconnect() end end)
        for _, e in pairs(CacheESP) do ClearEntry(e) end
        CacheESP = {}
        safe(function() FOVCircle:Remove() end)
        safe(function() Rayfield:Destroy() end)
        _G.TRIX_HUB_LOADED = false
    end,
})

-- ===== AIMBOT =====
AimTab:CreateSection("Mira")

AimTab:CreateSlider({
    Name = "Smoothness",
    Range = {5, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 20,
    Flag = "Smooth",
    Callback = function(v) Settings.Aimbot.Smoothness = v / 100 end,
})

AimTab:CreateSlider({
    Name = "FOV Radius",
    Range = {50, 600},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 200,
    Flag = "FOVRadius",
    Callback = function(v) Settings.Aimbot.FOVRadius = v end,
})

AimTab:CreateSlider({
    Name = "Max Distance",
    Range = {50, 2000},
    Increment = 10,
    Suffix = "studs",
    CurrentValue = 500,
    Flag = "MaxDist",
    Callback = function(v) Settings.Aimbot.MaxDistance = v end,
})

AimTab:CreateSlider({
    Name = "Prediction",
    Range = {0, 50},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 14,
    Flag = "Pred",
    Callback = function(v) Settings.Aimbot.PredictionAmount = v / 100 end,
})

AimTab:CreateDropdown({
    Name = "Hit Part",
    Options = {"Head", "UpperTorso", "HumanoidRootPart"},
    CurrentOption = {"Head"},
    Flag = "HitPart",
    Callback = function(opt) Settings.Aimbot.HitPart = (typeof(opt)=="table" and opt[1]) or opt end,
})

AimTab:CreateDropdown({
    Name = "Aim Bind",
    Options = {"MouseButton2", "MouseButton1", "MouseButton3", "LeftAlt", "E", "Q", "V", "F"},
    CurrentOption = {"MouseButton2"},
    Flag = "AimBind",
    Callback = function(opt) Settings.Aimbot.AimBind = (typeof(opt)=="table" and opt[1]) or opt end,
})

AimTab:CreateDropdown({
    Name = "Target Priority",
    Options = {"Crosshair", "Distance"},
    CurrentOption = {"Crosshair"},
    Flag = "Priority",
    Callback = function(opt) Settings.Aimbot.TargetPriority = (typeof(opt)=="table" and opt[1]) or opt end,
})

AimTab:CreateToggle({ Name="Prediction",   CurrentValue=true,  Flag="PredOn",
    Callback=function(v) Settings.Aimbot.Prediction = v end })
AimTab:CreateToggle({ Name="Visible Only", CurrentValue=false, Flag="VisOnly",
    Callback=function(v) Settings.Aimbot.VisibleOnly = v end })
AimTab:CreateToggle({ Name="Team Check",   CurrentValue=false, Flag="TeamChk",
    Callback=function(v) Settings.Aimbot.TeamCheck = v end })

AimTab:CreateSection("Recursos avançados")

AimTab:CreateToggle({
    Name = "Silent Aim (depende do jogo)",
    CurrentValue = false,
    Flag = "SilentAim",
    Callback = function(v)
        Settings.Aimbot.SilentAim = v
        if v then TrySetupSilentAim() end
    end,
})
AimTab:CreateToggle({ Name="Triggerbot", CurrentValue=false, Flag="Trigger",
    Callback=function(v) Settings.Aimbot.Triggerbot = v end })
AimTab:CreateSlider({
    Name = "Trigger Delay",
    Range = {10, 500},
    Increment = 5,
    Suffix = "ms",
    CurrentValue = 50,
    Flag = "TrigDelay",
    Callback = function(v) Settings.Aimbot.TriggerbotDelay = v / 1000 end,
})

-- ===== ESP =====
ESPTab:CreateSection("ESP Visuals")

ESPTab:CreateToggle({ Name="FOV Circle", CurrentValue=true, Flag="FOVOn",
    Callback=function(v) Settings.Visuals.FOVCircle = v end })
ESPTab:CreateToggle({ Name="Box ESP", CurrentValue=true, Flag="BoxESP",
    Callback=function(v) Settings.Visuals.BoxESP = v end })
ESPTab:CreateToggle({ Name="Tracers", CurrentValue=false, Flag="TracersOn",
    Callback=function(v) Settings.Visuals.Tracers = v end })
ESPTab:CreateDropdown({
    Name = "Tracer Origin",
    Options = {"Bottom", "Top"},
    CurrentOption = {"Bottom"},
    Flag = "TracerOrigin",
    Callback = function(opt) Settings.Visuals.TracerType = (typeof(opt)=="table" and opt[1]) or opt end,
})
ESPTab:CreateToggle({ Name="Name Tags", CurrentValue=true, Flag="NameTags",
    Callback=function(v) Settings.Visuals.ShowNames = v end })
ESPTab:CreateToggle({ Name="Health Bar", CurrentValue=true, Flag="HpBar",
    Callback=function(v) Settings.Visuals.ShowHealth = v end })
ESPTab:CreateToggle({
    Name = "Chams (Highlight)",
    CurrentValue = false,
    Flag = "ChamsOn",
    Callback = function(v)
        Settings.Visuals.Chams = v
        if not v then
            for _, e in pairs(CacheESP) do
                for c, hl in pairs(e.Highlights) do pcall(function() hl:Destroy() end); e.Highlights[c] = nil end
            end
        end
    end,
})

ESPTab:CreateSection("Cores")

ESPTab:CreateColorPicker({ Name="FOV Color",      Color=Settings.Visuals.FOVColor,        Flag="FOVColor",
    Callback=function(v) Settings.Visuals.FOVColor = v end })
ESPTab:CreateColorPicker({ Name="Box (Visível)",  Color=Settings.Visuals.BoxVisibleColor, Flag="BoxVis",
    Callback=function(v) Settings.Visuals.BoxVisibleColor = v end })
ESPTab:CreateColorPicker({ Name="Box (Parede)",   Color=Settings.Visuals.BoxWallColor,    Flag="BoxWall",
    Callback=function(v) Settings.Visuals.BoxWallColor = v end })
ESPTab:CreateColorPicker({ Name="Tracer",         Color=Settings.Visuals.TracerColor,     Flag="TracerCol",
    Callback=function(v) Settings.Visuals.TracerColor = v end })
ESPTab:CreateColorPicker({ Name="Chams",          Color=Settings.Visuals.ChamsColor,      Flag="ChamsCol",
    Callback=function(v) Settings.Visuals.ChamsColor = v end })

-- ===== SOBRE =====
AboutTab:CreateSection("TRIX HUB v6")
AboutTab:CreateParagraph({Title = "Informações", Content =
    "TRIX HUB v6 - 100% client-side\n"..
    "UI: Rayfield\n"..
    "Compatível com Xeno Executor\n"..
    "Use o Aim Bind para ativar a mira em tempo real."
})

------------------------------------------------------------
-- 14) NOTIFICAÇÃO + LOAD CONFIG
------------------------------------------------------------
Rayfield:Notify({
    Title    = "TRIX HUB v6",
    Content  = "Carregado com sucesso!",
    Duration = 4,
})

pcall(function() Rayfield:LoadConfiguration() end)

print("[TRIX HUB v6] Carregado.")
