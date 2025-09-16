-- ✝ Jesus Hub — Robust version with visible fallback UI if RedzLib doesn't load
-- Save this as JesusHub_fallback.lua and run in client (executor) context.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("JesusHub: LocalPlayer not found. Run this script in a LocalPlayer context (client).")
    return
end

-- ===== Helpers =====
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title or "Jesus Hub", Text = text or "", Duration = duration or 4})
    end)
end

local function safeFindRE(name)
    if not ReplicatedStorage then return nil end
    local ok, RE = pcall(function() return ReplicatedStorage:FindFirstChild("RE") or ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage end)
    if not ok or not RE then return nil end
    local ok2, v = pcall(function() return RE:FindFirstChild(name) end)
    if ok2 then return v end
    return nil
end

local function safeFire(name, ...)
    local ev = safeFindRE(name)
    if ev and ev.FireServer then
        pcall(function() ev:FireServer(...) end)
        return true
    end
    return false
end

local function sendChatMessage(msg)
    local ok, channel = pcall(function() return TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral") end)
    if ok and channel and channel.SendAsync then
        pcall(function() channel:SendAsync(msg) end)
        return
    end
    local chatRemote = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatRemote and chatRemote:FindFirstChild("SayMessageRequest") then
        pcall(function() chatRemote.SayMessageRequest:FireServer(msg, "All") end)
    end
end

local function sendInParts(parts)
    task.spawn(function()
        for _, txt in ipairs(parts) do
            sendChatMessage(txt)
            task.wait(2.5)
        end
    end)
end

-- ===== Try to load RedzLib (defensive) =====
local RedzLib = nil
do
    local ok, res = pcall(function()
        if game and (game.HttpGet or game.HttpGetAsync) then
            local url = "https://raw.githubusercontent.com/tbao143/Library-ui/refs/heads/main/Redzhubui"
            local content
            if game.HttpGet then
                content = game:HttpGet(url)
            elseif game.HttpGetAsync then
                content = game:HttpGetAsync(url)
            end
            if content and type(content) == "string" and #content > 10 then
                local fn = loadstring and loadstring(content) or load(content)
                if fn then
                    local ok2, out = pcall(fn)
                    if ok2 and type(out) == "table" then
                        return out
                    end
                end
            end
        end
        return nil
    end)
    if ok and res then
        RedzLib = res
    else
        RedzLib = nil
    end
end

-- If RedzLib exists and has MakeWindow, we'll use it; otherwise create fallback UI.
local useFallback = false
if not RedzLib or type(RedzLib) ~= "table" or not RedzLib.MakeWindow then
    useFallback = true
end

-- ===== Fallback UI builder =====
local function createFallbackWindow()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "JesusHubFallbackGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- Main window
    local window = Instance.new("Frame")
    window.Name = "Window"
    window.Size = UDim2.new(0, 680, 0, 420)
    window.Position = UDim2.new(0.5, -340, 0.5, -210)
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.BackgroundColor3 = Color3.fromRGB(28,28,28)
    window.BorderSizePixel = 0
    window.Parent = screenGui
    window.ZIndex = 10

    -- Top bar
    local top = Instance.new("Frame", window)
    top.Name = "Top"
    top.Size = UDim2.new(1, 0, 0, 32)
    top.BackgroundColor3 = Color3.fromRGB(18,18,18)
    top.BorderSizePixel = 0

    local title = Instance.new("TextLabel", top)
    title.Size = UDim2.new(1, -64, 1, 0)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "✝ Jesus Hub"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton", top)
    closeBtn.Size = UDim2.new(0, 28, 0, 20)
    closeBtn.Position = UDim2.new(1, -36, 0, 6)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 16
    closeBtn.BackgroundColor3 = Color3.fromRGB(160,40,40)
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.BorderSizePixel = 0

    local minimizeBtn = Instance.new("TextButton", top)
    minimizeBtn.Size = UDim2.new(0, 28, 0, 20)
    minimizeBtn.Position = UDim2.new(1, -68, 0, 6)
    minimizeBtn.Text = "_"
    minimizeBtn.Font = Enum.Font.SourceSansBold
    minimizeBtn.TextSize = 16
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(90,90,90)
    minimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    minimizeBtn.BorderSizePixel = 0

    -- Left tabs column
    local tabsFrame = Instance.new("Frame", window)
    tabsFrame.Name = "Tabs"
    tabsFrame.Position = UDim2.new(0, 8, 0, 40)
    tabsFrame.Size = UDim2.new(0, 140, 0, 360)
    tabsFrame.BackgroundTransparency = 1

    local function makeTabButton(text, y)
        local b = Instance.new("TextButton", tabsFrame)
        b.Size = UDim2.new(1, -8, 0, 36)
        b.Position = UDim2.new(0, 4, 0, y)
        b.Text = text
        b.Font = Enum.Font.Gotham
        b.TextSize = 14
        b.BackgroundColor3 = Color3.fromRGB(36,36,36)
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.BorderSizePixel = 0
        return b
    end

    local btnPrincipal = makeTabButton("Principal", 0)
    local btnVerses = makeTabButton("Versículos", 44)
    local btnLouvor = makeTabButton("Louvor", 88)

    -- Right content area
    local content = Instance.new("Frame", window)
    content.Name = "Content"
    content.Position = UDim2.new(0, 156, 0, 40)
    content.Size = UDim2.new(1, -164, 0, 360)
    content.BackgroundTransparency = 1

    -- Utility to clear content and add new
    local function clearContent()
        for _, c in ipairs(content:GetChildren()) do
            if not (c:IsA("UIGridStyleLayout") or c.Name == "Keep") then
                c:Destroy()
            end
        end
    end

    -- PRINCIPAL CONTENT
    local function buildPrincipal()
        clearContent()
        local sectionTitle = Instance.new("TextLabel", content)
        sectionTitle.Size = UDim2.new(1, 0, 0, 24)
        sectionTitle.Position = UDim2.new(0, 0, 0, 0)
        sectionTitle.BackgroundTransparency = 1
        sectionTitle.Text = "📖 Versículo Principal"
        sectionTitle.Font = Enum.Font.GothamBold
        sectionTitle.TextSize = 16
        sectionTitle.TextColor3 = Color3.fromRGB(255,255,255)
        sectionTitle.TextXAlignment = Enum.TextXAlignment.Left

        local sendBtn = Instance.new("TextButton", content)
        sendBtn.Size = UDim2.new(0, 220, 0, 36)
        sendBtn.Position = UDim2.new(0, 0, 0, 36)
        sendBtn.Text = "Enviar João 14:6"
        sendBtn.Font = Enum.Font.Gotham
        sendBtn.TextSize = 14
        sendBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
        sendBtn.TextColor3 = Color3.fromRGB(255,255,255)
        sendBtn.BorderSizePixel = 0
        sendBtn.MouseButton1Click:Connect(function()
            sendInParts({"Eu sou","o caminho","a verdade","e a vida.","Ninguém vem ao Pai, a não ser por mim."})
        end)

        -- Player controls
        local playersLabel = Instance.new("TextLabel", content)
        playersLabel.Size = UDim2.new(1, -8, 0, 20)
        playersLabel.Position = UDim2.new(0, 230, 0, 36)
        playersLabel.BackgroundTransparency = 1
        playersLabel.Text = "🎮 Jogadores"
        playersLabel.Font = Enum.Font.GothamBold
        playersLabel.TextSize = 14
        playersLabel.TextColor3 = Color3.fromRGB(255,255,255)
        playersLabel.TextXAlignment = Enum.TextXAlignment.Left

        -- Dropdown-like list
        local dropdownFrame = Instance.new("Frame", content)
        dropdownFrame.Size = UDim2.new(0, 300, 0, 120)
        dropdownFrame.Position = UDim2.new(0, 0, 0, 84)
        dropdownFrame.BackgroundTransparency = 1

        local playerLabel = Instance.new("TextLabel", dropdownFrame)
        playerLabel.Size = UDim2.new(0.6, 0, 0, 28)
        playerLabel.Position = UDim2.new(0, 0, 0, 0)
        playerLabel.BackgroundColor3 = Color3.fromRGB(38,38,38)
        playerLabel.Text = "Selecionar jogador..."
        playerLabel.Font = Enum.Font.Gotham
        playerLabel.TextSize = 14
        playerLabel.TextColor3 = Color3.fromRGB(200,200,200)
        playerLabel.BorderSizePixel = 0
        playerLabel.TextXAlignment = Enum.TextXAlignment.Left
        playerLabel.Padding = nil

        local refreshBtn = Instance.new("TextButton", dropdownFrame)
        refreshBtn.Size = UDim2.new(0, 80, 0, 28)
        refreshBtn.Position = UDim2.new(0.62, 0, 0, 0)
        refreshBtn.Text = "Atualizar"
        refreshBtn.Font = Enum.Font.Gotham
        refreshBtn.TextSize = 14
        refreshBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        refreshBtn.TextColor3 = Color3.fromRGB(255,255,255)
        refreshBtn.BorderSizePixel = 0

        local listFrame = Instance.new("Frame", dropdownFrame)
        listFrame.Size = UDim2.new(1, 0, 0, 80)
        listFrame.Position = UDim2.new(0, 0, 0, 32)
        listFrame.BackgroundTransparency = 1

        local selectedName = nil
        local function populatePlayers()
            for _, v in ipairs(listFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
            local y = 0
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    local b = Instance.new("TextButton", listFrame)
                    b.Size = UDim2.new(1, -6, 0, 22)
                    b.Position = UDim2.new(0, 3, 0, y)
                    b.BackgroundColor3 = Color3.fromRGB(48,48,48)
                    b.TextColor3 = Color3.fromRGB(255,255,255)
                    b.Font = Enum.Font.Gotham
                    b.TextSize = 13
                    b.Text = p.Name
                    b.BorderSizePixel = 0
                    b.MouseButton1Click:Connect(function()
                        selectedName = p.Name
                        playerLabel.Text = p.Name
                    end)
                    y = y + 24
                end
            end
        end
        populatePlayers()
        refreshBtn.MouseButton1Click:Connect(populatePlayers)

        -- Teleport button
        local tpBtn = Instance.new("TextButton", dropdownFrame)
        tpBtn.Size = UDim2.new(0, 140, 0, 28)
        tpBtn.Position = UDim2.new(0, 0, 0, 112)
        tpBtn.Text = "Teleportar até Jogador"
        tpBtn.Font = Enum.Font.Gotham
        tpBtn.TextSize = 13
        tpBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        tpBtn.TextColor3 = Color3.fromRGB(255,255,255)
        tpBtn.BorderSizePixel = 0
        tpBtn.MouseButton1Click:Connect(function()
            if not selectedName then notify("Erro","Nenhum jogador selecionado",4); return end
            local target = Players:FindFirstChild(selectedName)
            if target and target.Character and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
                end)
            else
                notify("Erro","Jogador ou personagem inválido",4)
            end
        end)

        -- View toggle
        local viewToggle = Instance.new("TextButton", dropdownFrame)
        viewToggle.Size = UDim2.new(0, 140, 0, 28)
        viewToggle.Position = UDim2.new(0.5, 10, 0, 112)
        viewToggle.Text = "👁 Toggle View"
        viewToggle.Font = Enum.Font.Gotham
        viewToggle.TextSize = 13
        viewToggle.BackgroundColor3 = Color3.fromRGB(60,60,60)
        viewToggle.TextColor3 = Color3.fromRGB(255,255,255)
        viewToggle.BorderSizePixel = 0
        local viewing = false
        viewToggle.MouseButton1Click:Connect(function()
            viewing = not viewing
            if viewing then
                local t = Players:FindFirstChild(selectedName)
                if t and t.Character and t.Character:FindFirstChild("Humanoid") then
                    workspace.CurrentCamera.CameraSubject = t.Character.Humanoid
                end
            else
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
                end
            end
        end)
    end

    -- VERSES CONTENT
    local function buildVerses()
        clearContent()
        local header = Instance.new("TextLabel", content)
        header.Size = UDim2.new(1,0,0,24)
        header.BackgroundTransparency = 1
        header.Text = "📖 Versículos"
        header.Font = Enum.Font.GothamBold
        header.TextSize = 16
        header.TextColor3 = Color3.fromRGB(255,255,255)
        header.TextXAlignment = Enum.TextXAlignment.Left

        local verses = {
            {"João 8:12", {"Eu sou a luz do mundo;","quem me segue não andará em trevas,","mas terá a luz da vida."}},
            {"João 10:11", {"Eu sou o bom pastor.","O bom pastor dá a sua vida","pelas ovelhas."}},
            {"João 11:25", {"Eu sou a ressurreição","e a vida.","Quem crê em mim,","ainda que esteja morto,","viverá."}},
            {"João 15:5", {"Eu sou a videira;","vós sois os ramos.","Quem permanece em mim,","e eu nele,","esse dá muito fruto."}}
        }

        local y = 36
        for _, v in ipairs(verses) do
            local btn = Instance.new("TextButton", content)
            btn.Size = UDim2.new(0, 320, 0, 34)
            btn.Position = UDim2.new(0, 0, 0, y)
            btn.Text = v[1]
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.BorderSizePixel = 0
            btn.MouseButton1Click:Connect(function()
                sendInParts(v[2])
            end)
            y = y + 42
        end
    end

    -- LOUVOR CONTENT
    local function buildLouvor()
        clearContent()
        local header = Instance.new("TextLabel", content)
        header.Size = UDim2.new(1,0,0,24)
        header.BackgroundTransparency = 1
        header.Text = "🎵 Louvor"
        header.Font = Enum.Font.GothamBold
        header.TextSize = 16
        header.TextColor3 = Color3.fromRGB(255,255,255)
        header.TextXAlignment = Enum.TextXAlignment.Left

        local louvores = {
            {Name = "Louvor 1", ID = 101104830869507},
            {Name = "Louvor 2", ID = 104628837026645},
            {Name = "Louvor 3", ID = 105890931242589},
        }
        local selectedID = louvores[1].ID

        local idBox = Instance.new("TextBox", content)
        idBox.Size = UDim2.new(0, 240, 0, 30)
        idBox.Position = UDim2.new(0, 0, 0, 36)
        idBox.PlaceholderText = "Digite ID do louvor (opcional)"
        idBox.Text = ""
        idBox.Font = Enum.Font.Gotham
        idBox.TextSize = 14
        idBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
        idBox.TextColor3 = Color3.fromRGB(255,255,255)
        idBox.BorderSizePixel = 0

        local playBtn = Instance.new("TextButton", content)
        playBtn.Size = UDim2.new(0, 140, 0, 30)
        playBtn.Position = UDim2.new(0, 250, 0, 36)
        playBtn.Text = "▶ Tocar Louvor"
        playBtn.Font = Enum.Font.Gotham
        playBtn.TextSize = 14
        playBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
        playBtn.TextColor3 = Color3.fromRGB(255,255,255)
        playBtn.BorderSizePixel = 0

        local loopToggle = Instance.new("TextButton", content)
        loopToggle.Size = UDim2.new(0, 140, 0, 30)
        loopToggle.Position = UDim2.new(0, 400, 0, 36)
        loopToggle.Text = "Loop: OFF"
        loopToggle.Font = Enum.Font.Gotham
        loopToggle.TextSize = 14
        loopToggle.BackgroundColor3 = Color3.fromRGB(60,60,60)
        loopToggle.TextColor3 = Color3.fromRGB(255,255,255)
        loopToggle.BorderSizePixel = 0

        local estourarBtn = Instance.new("TextButton", content)
        estourarBtn.Size = UDim2.new(0, 220, 0, 34)
        estourarBtn.Position = UDim2.new(0, 0, 0, 84)
        estourarBtn.Text = "💥 Estourar ouvido de geral (toca até o fim)"
        estourarBtn.Font = Enum.Font.Gotham
        estourarBtn.TextSize = 14
        estourarBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        estourarBtn.TextColor3 = Color3.fromRGB(255,255,255)
        estourarBtn.BorderSizePixel = 0

        -- dropdown list for presets
        local presetsFrame = Instance.new("Frame", content)
        presetsFrame.Position = UDim2.new(0, 0, 0, 132)
        presetsFrame.Size = UDim2.new(0, 300, 0, 100)
        presetsFrame.BackgroundTransparency = 1

        local presetLabel = Instance.new("TextLabel", presetsFrame)
        presetLabel.Size = UDim2.new(1, 0, 0, 28)
        presetLabel.BackgroundTransparency = 1
        presetLabel.Text = "Presets:"
        presetLabel.Font = Enum.Font.GothamBold
        presetLabel.TextColor3 = Color3.fromRGB(255,255,255)
        presetLabel.TextXAlignment = Enum.TextXAlignment.Left

        local y = 32
        for _, p in ipairs(louvores) do
            local b = Instance.new("TextButton", presetsFrame)
            b.Size = UDim2.new(1, -6, 0, 24)
            b.Position = UDim2.new(0, 3, 0, y)
            b.Text = p.Name
            b.Font = Enum.Font.Gotham
            b.TextSize = 13
            b.BackgroundColor3 = Color3.fromRGB(45,45,45)
            b.TextColor3 = Color3.fromRGB(255,255,255)
            b.BorderSizePixel = 0
            b.MouseButton1Click:Connect(function()
                selectedID = p.ID
                idBox.Text = tostring(p.ID)
                notify("Louvor", "Selecionado "..p.Name, 2)
            end)
            y = y + 28
        end

        -- Loop management
        local looping = false
        local loopThread = nil
        loopToggle.MouseButton1Click:Connect(function()
            looping = not looping
            loopToggle.Text = "Loop: " .. (looping and "ON" or "OFF")
            if looping then
                loopThread = task.spawn(function()
                    while looping do
                        local idToPlay = tonumber(idBox.Text) or selectedID
                        if idToPlay then
                            local ev = safeFindRE("1Gu1nSound1s")
                            if ev and ev.FireServer then
                                pcall(function() ev:FireServer(workspace, idToPlay, 1) end)
                            end
                        end
                        task.wait(0.8)
                    end
                end)
            else
                looping = false
            end
        end)

        -- Play once button
        playBtn.MouseButton1Click:Connect(function()
            local idToPlay = tonumber(idBox.Text) or selectedID
            if not idToPlay then notify("Erro","Nenhum ID válido",3); return end
            local ev = safeFindRE("1Gu1nSound1s")
            if ev and ev.FireServer then
                pcall(function() ev:FireServer(workspace, idToPlay, 1) end)
            end
            -- play locally as fallback
            local folder = workspace:FindFirstChild("Louvor all client") or Instance.new("Folder", workspace)
            folder.Name = "Louvor all client"
            local sound = Instance.new("Sound", folder)
            sound.SoundId = "rbxassetid://" .. tostring(idToPlay)
            sound.Volume = 2
            sound.Looped = false
            sound:Play()
            sound.Ended:Connect(function()
                pcall(function() sound:Destroy() end)
            end)
        end)

        estourarBtn.MouseButton1Click:Connect(function()
            local idToPlay = tonumber(idBox.Text) or selectedID
            if not idToPlay then notify("Erro","Nenhum ID válido",3); return end
            -- server trigger
            local ev = safeFindRE("1Gu1nSound1s")
            if ev and ev.FireServer then
                pcall(function() ev:FireServer(workspace, idToPlay, 1) end)
            end
            -- local play until end
            local folder = workspace:FindFirstChild("Louvor all client") or Instance.new("Folder", workspace)
            folder.Name = "Louvor all client"
            local sound = Instance.new("Sound", folder)
            sound.SoundId = "rbxassetid://" .. tostring(idToPlay)
            sound.Volume = 3
            sound.Looped = false
            sound:Play()
            sound.Ended:Connect(function()
                pcall(function() sound:Destroy() end)
            end)
        end)
    end

    -- Connect tab buttons
    btnPrincipal.MouseButton1Click:Connect(buildPrincipal)
    btnVerses.MouseButton1Click:Connect(buildVerses)
    btnLouvor.MouseButton1Click:Connect(buildLouvor)

    -- Close and minimize
    closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)
    local minimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            for _,c in ipairs(window:GetChildren()) do if c ~= top then c.Visible = false end end
            window.Size = UDim2.new(0, 160, 0, 32)
        else
            for _,c in ipairs(window:GetChildren()) do c.Visible = true end
            window.Size = UDim2.new(0, 680, 0, 420)
        end
    end)

    -- Draggable top
    do
        local dragging = false
        local dragInput, dragStart, startPos
        top.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = window.Position
            end
        end)
        top.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        top.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- Initialize with Principal tab
    buildPrincipal()
    notify("Jesus Hub", "Interface carregada (fallback).", 3)
    print("Jesus Hub: fallback UI created")
    return screenGui
end

-- ===== Build using RedzLib or fallback =====
local createdGui = nil
if not useFallback then
    -- Try to build with RedzLib: keep original features but add graceful fallback if window nil
    local ok, Window = pcall(function() return RedzLib:MakeWindow({
        Title = "✝ Jesus Hub",
        SubTitle = "João 14:6",
        LoadText = "Jesus Hub iniciado",
        Flags = "JesusHub_Final"
    }) end)
    if ok and Window and type(Window) == "table" and Window.MakeTab then
        -- Build minimal tabs using RedzLib API (best-effort; original script had many features)
        local MainTab = Window:MakeTab({ Title = "Principal", Icon = "rbxassetid://6023426922" })
        MainTab:AddSection("📖 Versículo Principal")
        MainTab:AddButton({ Name = "Enviar João 14:6", Callback = function()
            sendInParts({"Eu sou","o caminho","a verdade","e a vida.","Ninguém vem ao Pai, a não ser por mim."})
        end })
        local VersesTab = Window:MakeTab({ Title = "Versículos", Icon = "rbxassetid://6022668888" })
        VersesTab:AddSection("📖 Palavras de Jesus")
        VersesTab:AddButton({ Name = "João 8:12", Callback = function() sendInParts({"Eu sou a luz do mundo;","quem me segue não andará em trevas,","mas terá a luz da vida."}) end })
        local LouvorTab = Window:MakeTab({ Title = "Louvor", Icon = "music" })
        -- We'll add louvor controls compatible with RedzLib API if available; otherwise fallback to GUI
        LouvorTab:AddSection({"Louvor Todos os Players"})
        LouvorTab:AddTextBox({ Name = "Insira o ID do Louvor", Description = "Digite o ID do Louvor", PlaceholderText = "ID do louvor", Callback = function(value) end })
        LouvorTab:AddButton({ Name = "▶ Tocar Louvor", Callback = function() notify("Script","Tocar louvor (RedzLib UI)",3) end })
        createdGui = true
    else
        createdGui = createFallbackWindow()
    end
else
    createdGui = createFallbackWindow()
end

-- Expose some API to global for debugging
getgenv().JesusHub = getgenv().JesusHub or {}
getgenv().JesusHub.Gui = createdGui
getgenv().JesusHub.PlayLouvor = function(id)
    if not id then return end
    local ev = safeFindRE("1Gu1nSound1s")
    if ev and ev.FireServer then pcall(function() ev:FireServer(workspace, id, 1) end) end
    local folder = workspace:FindFirstChild("Louvor all client") or Instance.new("Folder", workspace)
    folder.Name = "Louvor all client"
    local sound = Instance.new("Sound", folder)
    sound.SoundId = "rbxassetid://" .. tostring(id)
    sound.Looped = false
    sound.Volume = 2.5
    sound:Play()
    sound.Ended:Connect(function() pcall(function() sound:Destroy() end) end)
end

print("Jesus Hub loaded. useFallback =", tostring(useFallback))
