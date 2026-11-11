--[[
    LOADER - R7FLOW-AFK + SPACE KEY (arquivo único)
    - Key System roda PRIMEIRO (bloqueante)
    - main.lua só é baixado/executado APÓS a key ser validada
    - Se o usuário fechar o painel sem validar -> main.lua NÃO roda
]]

local MAIN_URL = "https://raw.githubusercontent.com/guilhermersantoxavier2-cell/R7FLOW-FREE/refs/heads/main/main.lua"

-- ==========================================================
-- ============ KEY SYSTEM (EMBUTIDO) =======================
-- ==========================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local SPACEKEY_API = "https://spacekey-cusqu25y.manus.space"

local function getRequestFunction()
    if typeof(request) == "function" then return request end
    if typeof(http_request) == "function" then return http_request end
    if syn and typeof(syn.request) == "function" then return syn.request end
    if fluxus and typeof(fluxus.request) == "function" then return fluxus.request end
    return nil
end

local function api(method, path, body)
    local req = getRequestFunction()
    if not req then return nil, "Executor sem suporte HTTP (request)." end
    local options = {Url = SPACEKEY_API .. path, Method = method, Headers = {["Content-Type"] = "application/json"}}
    if body then options.Body = HttpService:JSONEncode(body) end
    local ok, response = pcall(req, options)
    if not ok or type(response) ~= "table" then return nil, "Falha ao conectar ao Space Key." end
    local status = tonumber(response.StatusCode or response.Status or 0) or 0
    local raw = response.Body or response.body or ""
    local decoded, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not decoded or type(data) ~= "table" then return nil, "Resposta inválida do servidor." end
    if status < 200 or status >= 300 or data.ok ~= true then return nil, data.error or "Solicitação recusada." end
    return data
end

-- Retorna true se validado, false se o usuário fechou sem validar
local function runKeySystem()
    -- 1) Sessão já ativa? Pula o painel.
    local status = api("GET", "/api/keys/status?userId=" .. tostring(player.UserId))
    if status and status.active and tonumber(status.expiresAt) and status.expiresAt > DateTime.now().UnixTimestampMillis then
        print("[SPACE KEY] Acesso já registrado até " .. os.date("!%d/%m/%Y %H:%M", math.floor(status.expiresAt / 1000)))
        return true
    end

    -- 2) Monta painel
    local old = playerGui:FindFirstChild("KeyPanelUI")
    if old then old:Destroy() end

    local mobile = isMobile
    local W, H = mobile and 340 or 440, mobile and 290 or 320
    local BG = Color3.fromRGB(15,12,15)
    local RED = Color3.fromRGB(220,30,50)
    local RED2 = Color3.fromRGB(255,60,80)
    local TXT = Color3.fromRGB(245,240,242)
    local MUTED = Color3.fromRGB(155,140,145)
    local BORDER = Color3.fromRGB(65,45,52)

    local gui = Instance.new("ScreenGui")
    gui.Name = "KeyPanelUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999; gui.Parent = playerGui

    local overlay = Instance.new("Frame", gui)
    overlay.Size = UDim2.fromScale(1,1); overlay.BackgroundColor3 = Color3.new(0,0,0)
    overlay.BackgroundTransparency = 0.45; overlay.BorderSizePixel = 0

    local panel = Instance.new("Frame", overlay)
    panel.Name = "Painel"; panel.Size = UDim2.fromOffset(W,H); panel.Position = UDim2.fromScale(.5,.5)
    panel.AnchorPoint = Vector2.new(.5,.5); panel.BackgroundColor3 = BG; panel.BorderSizePixel = 0
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, mobile and 14 or 18)
    local stroke = Instance.new("UIStroke", panel); stroke.Color = RED; stroke.Thickness = 2
    local bgGrad = Instance.new("UIGradient", panel); bgGrad.Color = ColorSequence.new(Color3.fromRGB(28,18,22), BG); bgGrad.Rotation = 45

    local header = Instance.new("Frame", panel); header.Size = UDim2.new(1,0,0,70); header.BackgroundTransparency = 1
    local logo = Instance.new("Frame", header); logo.Size = UDim2.fromOffset(44,44); logo.Position = UDim2.new(0,22,.5,0); logo.AnchorPoint = Vector2.new(0,.5); logo.BackgroundColor3 = RED
    Instance.new("UICorner", logo).CornerRadius = UDim.new(1,0)
    local lock = Instance.new("TextLabel", logo); lock.Size = UDim2.fromScale(1,1); lock.BackgroundTransparency = 1; lock.Text = "🔒"; lock.TextSize = 22
    local title = Instance.new("TextLabel", header); title.Position = UDim2.new(0,80,.5,-12); title.Size = UDim2.new(1,-130,0,22); title.BackgroundTransparency = 1; title.Text = "KEY SYSTEM"; title.TextColor3 = TXT; title.Font = Enum.Font.GothamBold; title.TextSize = 18; title.TextXAlignment = Enum.TextXAlignment.Left
    local sub = Instance.new("TextLabel", header); sub.Position = UDim2.new(0,80,.5,10); sub.Size = UDim2.new(1,-130,0,16); sub.BackgroundTransparency = 1; sub.Text = "Authentication Required"; sub.TextColor3 = RED2; sub.Font = Enum.Font.Gotham; sub.TextSize = 10; sub.TextXAlignment = Enum.TextXAlignment.Left
    local close = Instance.new("TextButton", header); close.Size = UDim2.fromOffset(32,32); close.Position = UDim2.new(1,-46,.5,0); close.AnchorPoint = Vector2.new(0,.5); close.BackgroundTransparency = 1; close.Text = "✕"; close.TextColor3 = MUTED; close.TextSize = 18; close.Font = Enum.Font.GothamBold
    close.MouseButton1Click:Connect(function() gui:Destroy() end)
    local divider = Instance.new("Frame", panel); divider.Position = UDim2.new(0,24,0,70); divider.Size = UDim2.new(1,-48,0,1); divider.BackgroundColor3 = BORDER; divider.BorderSizePixel = 0
    local content = Instance.new("Frame", panel); content.Position = UDim2.new(0,24,0,91); content.Size = UDim2.new(1,-48,1,-132); content.BackgroundTransparency = 1
    local desc = Instance.new("TextLabel", content); desc.Size = UDim2.new(1,0,0,20); desc.BackgroundTransparency = 1; desc.Text = "Insira sua key para continuar"; desc.TextColor3 = MUTED; desc.Font = Enum.Font.Gotham; desc.TextSize = 12; desc.TextXAlignment = Enum.TextXAlignment.Left
    local inputFrame = Instance.new("Frame", content); inputFrame.Position = UDim2.new(0,0,0,30); inputFrame.Size = UDim2.new(1,0,0,48); inputFrame.BackgroundColor3 = Color3.fromRGB(30,22,26); inputFrame.BorderSizePixel = 0
    Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0,10)
    local inputStroke = Instance.new("UIStroke", inputFrame); inputStroke.Color = BORDER; inputStroke.Thickness = 1.5
    local keyIcon = Instance.new("TextLabel", inputFrame); keyIcon.Size = UDim2.fromOffset(38,48); keyIcon.BackgroundTransparency = 1; keyIcon.Text = "🔑"; keyIcon.TextSize = 16
    local box = Instance.new("TextBox", inputFrame); box.Name = "KeyInput"; box.Position = UDim2.new(0,42,0,0); box.Size = UDim2.new(1,-50,1,0); box.BackgroundTransparency = 1; box.Text = ""; box.PlaceholderText = "SPK-XXXXXXXX-XXXXXXXX"; box.PlaceholderColor3 = Color3.fromRGB(100,85,90); box.TextColor3 = TXT; box.TextSize = 13; box.Font = Enum.Font.GothamMedium; box.TextXAlignment = Enum.TextXAlignment.Left; box.ClearTextOnFocus = false
    box.Focused:Connect(function() TweenService:Create(inputStroke,TweenInfo.new(.2),{Color=RED,Thickness=2}):Play() end)
    box.FocusLost:Connect(function() TweenService:Create(inputStroke,TweenInfo.new(.2),{Color=BORDER,Thickness=1.5}):Play() end)
    local button = Instance.new("TextButton", content); button.Position = UDim2.new(0,0,0,94); button.Size = UDim2.new(1,0,0,48); button.BackgroundColor3 = RED; button.BorderSizePixel = 0; button.Text = "VERIFICAR KEY"; button.TextColor3 = Color3.new(1,1,1); button.TextSize = 14; button.Font = Enum.Font.GothamBold; button.AutoButtonColor = true
    Instance.new("UICorner", button).CornerRadius = UDim.new(0,10)
    local buttonGrad = Instance.new("UIGradient", button); buttonGrad.Color = ColorSequence.new(RED,RED2,RED)
    local footer = Instance.new("TextLabel", panel); footer.Position = UDim2.new(0,20,1,-27); footer.Size = UDim2.new(1,-40,0,14); footer.BackgroundTransparency = 1; footer.Text = "🔒 Protected by Space Key • Executor Edition"; footer.TextColor3 = Color3.fromRGB(90,75,80); footer.TextSize = 9; footer.Font = Enum.Font.Gotham

    local validated = false
    local busy = false

    button.MouseButton1Click:Connect(function()
        if busy then return end
        local candidate = tostring(box.Text or ""):gsub("%s+",""):upper()
        if candidate == "" then button.Text = "INSIRA UMA KEY"; task.wait(1); button.Text = "VERIFICAR KEY"; return end
        busy = true; button.Active = false; button.Text = "VERIFICANDO..."
        local result, err = api("POST", "/api/keys/claim", {key=candidate,userId=tostring(player.UserId)})
        if result and result.registered then
            button.Text = "✓ KEY VÁLIDA"
            validated = true
            task.wait(.5)
            gui:Destroy()
        else
            button.Text = string.upper(err or "KEY INVÁLIDA")
            task.wait(2)
            button.Text = "VERIFICAR KEY"
            button.Active = true
            busy = false
        end
    end)

    -- Arrastar
    local dragging, dragStart, startPos = false, nil, nil
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = panel.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    panel.Size = UDim2.fromOffset(0,0)
    TweenService:Create(panel,TweenInfo.new(.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(W,H)}):Play()
    print("[SPACE KEY] Painel carregado. Aguardando key...")

    -- ⏳ BLOQUEIA até validar OU fechar o painel
    while not validated and gui.Parent do
        task.wait(0.1)
    end

    if not validated then
        print("[SPACE KEY] Painel fechado sem validação. Abortando.")
        return false
    end

    print("[SPACE KEY] ✅ Key validada com sucesso.")
    return true
end

-- ==========================================================
-- ============ FETCH DO SCRIPT PRINCIPAL ===================
-- ==========================================================
local function fetchScript(url)
    local methods = {
        function() return game:HttpGet(url) end,
        function() return game:HttpGetAsync(url) end,
        function() return request({ Url = url, Method = "GET" }).Body end,
        function() return syn.request({ Url = url, Method = "GET" }).Body end,
        function() return http_request({ Url = url, Method = "GET" }).Body end,
    }
    for _, method in ipairs(methods) do
        local ok, result = pcall(method)
        if ok and type(result) == "string" and #result > 0 and not result:find("404: Not Found") then
            return result
        end
    end
    return nil
end

-- ==========================================================
-- ============ FLUXO PRINCIPAL =============================
-- ==========================================================

-- 1) PRIMEIRO: roda o key system (bloqueia aqui até validar)
print("[LOADER] Iniciando Key System...")
local keyOk, keyResult = pcall(runKeySystem)

if not keyOk then
    warn("[LOADER] ❌ Erro no Key System: " .. tostring(keyResult))
    return
end

if not keyResult then
    warn("[LOADER] ❌ Key não validada. Script principal NÃO será executado.")
    return
end

-- 2) SÓ DEPOIS: baixa e executa o main.lua
print("[LOADER] ✅ Key validada. Baixando script principal...")

local source = fetchScript(MAIN_URL)
if not source then
    warn("[LOADER] ❌ Falha ao baixar main.lua. Verifique a URL/conexão.")
    return
end

if source:find("404: Not Found") then
    warn("[LOADER] ❌ main.lua não encontrado no repositório (404).")
    return
end

local chunk, err = loadstring(source, "@R7FLOW-AFK/main.lua")
if not chunk then
    warn("[LOADER] ❌ Erro ao compilar main.lua: " .. tostring(err))
    return
end

local runOk, runErr = pcall(chunk)
if runOk then
    print("[LOADER] ✅ Script principal carregado com sucesso!")
else
    warn("[LOADER] ❌ Erro na execução do main.lua: " .. tostring(runErr))
end
