-- ============================================================
--  SaveInstance Plus - DM @cvtmvtt on discord if you come across any errors with-
--  my portion of thee additions (I can't modify synsaveinstance directly, I might-
--  be able to create work arounds for some things though)
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local UserInputService  = game:GetService("UserInputService")

local player      = Players.LocalPlayer
local playerGui   = player:WaitForChild("PlayerGui")
local character   = player.Character or player.CharacterAdded:Wait()
if not character.PrimaryPart then character:WaitForChild("HumanoidRootPart") end

-- ============================================================
--  LOAD UniversalSynSaveInstance
-- ============================================================
local synsaveinstance
do
    local ok, result = pcall(function()
        local base = "https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/main/"
        return loadstring(game:HttpGet(base .. "saveinstance.luau", true), "saveinstance")()
    end)
    if not ok then
        error("UniversalSynSaveInstance failed to load: " .. tostring(result))
    end
    synsaveinstance = result
    print("[SaveInstance] Library loaded.")
end

-- ============================================================
--  PLATFORM
-- ============================================================
local platform, spawnLocation

local function createLocalPlatform()
    local p  = Instance.new("Part")
    p.Name          = "LocalOnly_Platform"
    p.Size          = Vector3.new(20, 1, 20)
    p.Anchored      = true
    p.CanCollide    = true
    p.Transparency  = 0.5
    p.BrickColor    = BrickColor.new("Bright blue")

    local char = player.Character
    local rootPos = char and char.PrimaryPart and char.PrimaryPart.Position
    if not rootPos then
        rootPos = Vector3.new(0, 100, 0)
        warn("[Platform] Character not found, using fallback position.")
    end
    p.Position = rootPos - Vector3.new(0, 250, 0)
    p.Parent   = workspace

    local sl = Instance.new("SpawnLocation")
    sl.Name         = "LocalOnly_Spawn"
    sl.Size         = Vector3.new(10, 1, 10)
    sl.Anchored     = true
    sl.CanCollide   = false
    sl.Transparency = 1
    sl.Position     = p.Position + Vector3.new(0, 2, 0)
    sl.Neutral      = true
    sl.Parent       = workspace

    print("[Platform] Created at", p.Position, " (250 studs below character)")
    return p, sl
end

local function destroyPlatform()
    if platform      then platform:Destroy();      platform      = nil end
    if spawnLocation then spawnLocation:Destroy();  spawnLocation = nil end
end

-- ============================================================
--  TELEPORT LOOP
-- ============================================================
local teleportLoopRunning = false
local teleportConnection

local function startTeleportLoop()
    if teleportLoopRunning or not platform then return end
    teleportLoopRunning = true
    teleportConnection  = RunService.Heartbeat:Connect(function()
        local ch = player.Character
        if ch and ch.PrimaryPart then
            ch:PivotTo(CFrame.new(platform.Position + Vector3.new(0, 5, 0)))
        end
        task.wait(0.5)
    end)
    print("[Platform] Teleport loop started.")
end

local function stopTeleportLoop()
    if teleportConnection then
        teleportConnection:Disconnect()
        teleportConnection = nil
    end
    teleportLoopRunning = false
end

-- ============================================================
--  STREAMING BYPASS
-- ============================================================
local function bypassStreaming()
    local ok1 = pcall(function()
        workspace.StreamingEnabled = false
    end)
    if ok1 then
        print("[Streaming] StreamingEnabled set to false.")
    else
        warn("[Streaming] Could not disable StreamingEnabled (server-enforced).")
    end

    pcall(function()
        workspace.StreamingMinRadius    = 10000
        workspace.StreamingTargetRadius = 100000
        print("[Streaming] Streaming radii pushed to max.")
    end)

    pcall(function()
        if setpropertyignored then
            setpropertyignored(workspace, "StreamingEnabled", false)
        end
    end)
end

-- ============================================================
--  MAP CAPTURE — CAMERA SWEEP
-- ============================================================
local function performCameraSweep(onComplete)
    print("[CameraSweep] Starting sweep to force chunk loading...")
    local camera       = workspace.CurrentCamera
    local origCFrame   = camera.CFrame
    local origType     = camera.CameraType

    camera.CameraType  = Enum.CameraType.Scriptable

    task.spawn(function()
        local range    = 6000
        local step     = 800
        local altitude = 6000

        for x = -range, range, step do
            for z = -range, range, step do
                local pos = Vector3.new(x, altitude, z)
                camera.CFrame = CFrame.new(pos, pos - Vector3.new(0, altitude, 0))
                task.wait(0.04)
            end
        end

        camera.CameraType = origType
        camera.CFrame     = origCFrame
        print("[CameraSweep] Complete.")
        if onComplete then onComplete() end
    end)
end

-- ============================================================
--  EXPERIMENTAL MAP SCAN
-- ============================================================
local experimentalCacheConn   = nil
local experimentalCacheFolder = nil

local function detectMapBounds()
    print("[Experimental] ============================================")
    print("[Experimental] Phase 1: Detecting map bounds...")
    print("[Experimental] ============================================")

    local minX, minY, minZ =  math.huge,  math.huge,  math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    local count = 0

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart")
            and not obj.Name:find("LocalOnly")
            and obj ~= platform
            and obj ~= spawnLocation
        then
            local pos  = obj.Position
            local half = obj.Size * 0.5
            if pos.X - half.X < minX then minX = pos.X - half.X end
            if pos.Y - half.Y < minY then minY = pos.Y - half.Y end
            if pos.Z - half.Z < minZ then minZ = pos.Z - half.Z end
            if pos.X + half.X > maxX then maxX = pos.X + half.X end
            if pos.Y + half.Y > maxY then maxY = pos.Y + half.Y end
            if pos.Z + half.Z > maxZ then maxZ = pos.Z + half.Z end
            count += 1
        end
    end

    if count == 0 then
        warn("[Experimental] No BaseParts found — falling back to default ±1000 stud bounds.")
        return { minX=-1000, minY=-100, minZ=-1000, maxX=1000, maxY=500, maxZ=1000, count=0 }
    end

    local spanX = maxX - minX
    local spanY = maxY - minY
    local spanZ = maxZ - minZ

    print(string.format("[Experimental] Scanned %d BaseParts.", count))
    print(string.format("[Experimental]   X range : %.1f  →  %.1f   (span %.1f)", minX, maxX, spanX))
    print(string.format("[Experimental]   Y range : %.1f  →  %.1f   (span %.1f)", minY, maxY, spanY))
    print(string.format("[Experimental]   Z range : %.1f  →  %.1f   (span %.1f)", minZ, maxZ, spanZ))
    print(string.format("[Experimental]   Farthest corners:"))
    print(string.format("[Experimental]     NW (%.1f, %.1f)   NE (%.1f, %.1f)", minX, minZ, maxX, minZ))
    print(string.format("[Experimental]     SW (%.1f, %.1f)   SE (%.1f, %.1f)", minX, maxZ, maxX, maxZ))

    return { minX=minX, minY=minY, minZ=minZ, maxX=maxX, maxY=maxY, maxZ=maxZ, count=count }
end

local function startExperimentalCache()
    if experimentalCacheFolder then experimentalCacheFolder:Destroy() end

    experimentalCacheFolder        = Instance.new("Folder")
    experimentalCacheFolder.Name   = "_ExperimentalCache"
    experimentalCacheFolder.Parent = workspace.CurrentCamera

    print("[Experimental] ============================================")
    print("[Experimental] Phase 2: Building initial cache snapshot...")
    print("[Experimental] ============================================")

    local cloned = 0
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name ~= "LocalOnly_Platform"
            and obj.Name ~= "LocalOnly_Spawn"
            and obj ~= workspace.CurrentCamera
            and obj ~= experimentalCacheFolder
        then
            local ok, clone = pcall(function() return obj:Clone() end)
            if ok and clone then
                clone.Parent = experimentalCacheFolder
                cloned += 1
                print(string.format("[Experimental] [Cache] Initial clone: %s (%s)", obj.Name, obj.ClassName))
            else
                warn(string.format("[Experimental] [Cache] Failed to clone: %s", obj.Name))
            end
        end
    end

    print(string.format("[Experimental] Initial cache complete — %d top-level objects cloned.", cloned))
    print("[Experimental] Starting live-cache watcher (ChildAdded)...")

    experimentalCacheConn = workspace.ChildAdded:Connect(function(child)
        if child.Name:find("LocalOnly") then return end
        if child == experimentalCacheFolder then return end

        task.wait(0.15)

        if not experimentalCacheFolder:FindFirstChild(child.Name) then
            local ok, clone = pcall(function() return child:Clone() end)
            if ok and clone then
                clone.Parent = experimentalCacheFolder
                print(string.format("[Experimental] [Cache] NEW stream-in cached: %s (%s)", child.Name, child.ClassName))
            else
                warn(string.format("[Experimental] [Cache] Failed to cache stream-in: %s", child.Name))
            end
        else
            print(string.format("[Experimental] [Cache] Stream-in already cached, skipping: %s", child.Name))
        end
    end)

    print("[Experimental] Live-cache watcher active.")
end

local function stopExperimentalCache()
    if experimentalCacheConn then
        experimentalCacheConn:Disconnect()
        experimentalCacheConn = nil
        print("[Experimental] [Cache] Live-cache watcher stopped.")
    end
end

local function destroyExperimentalCache()
    stopExperimentalCache()
    if experimentalCacheFolder then
        experimentalCacheFolder:Destroy()
        experimentalCacheFolder = nil
        print("[Experimental] [Cache] Cache folder destroyed.")
    end
end

local EXPERIMENTAL_STEP  = 200
local EXPERIMENTAL_DWELL = 0.18

local function performExperimentalSweep(bounds, onComplete)
    print("[Experimental] ============================================")
    print("[Experimental] Phase 3: Character-position sweep starting")
    print("[Experimental] ============================================")

    local ch = player.Character
    if not ch or not ch.PrimaryPart then
        warn("[Experimental] Character not available — skipping character sweep.")
        if onComplete then onComplete() end
        return
    end

    local origCFrame = ch:GetPivot()
    print(string.format("[Experimental] Origin CFrame saved: (%.1f, %.1f, %.1f)",
        origCFrame.Position.X, origCFrame.Position.Y, origCFrame.Position.Z))

    local spanX  = bounds.maxX - bounds.minX
    local spanZ  = bounds.maxZ - bounds.minZ
    local sweepY = bounds.maxY + 250
    local stepsX = math.ceil(spanX / EXPERIMENTAL_STEP) + 1
    local stepsZ = math.ceil(spanZ / EXPERIMENTAL_STEP) + 1
    local total  = stepsX * stepsZ

    print(string.format("[Experimental] Map footprint : X=%.0f studs,  Z=%.0f studs", spanX, spanZ))
    print(string.format("[Experimental] Step size     : %d studs", EXPERIMENTAL_STEP))
    print(string.format("[Experimental] Sweep altitude: Y=%.0f", sweepY))
    print(string.format("[Experimental] Grid           : %d × %d = %d positions", stepsX, stepsZ, total))
    print(string.format("[Experimental] Est. time      : ~%.0f seconds (%.1f min)",
        total * EXPERIMENTAL_DWELL, total * EXPERIMENTAL_DWELL / 60))
    print("[Experimental] ============================================")

    task.spawn(function()
        local visited    = 0
        local cacheStart = #experimentalCacheFolder:GetChildren()

        for ix = 0, stepsX - 1 do
            for iz = 0, stepsZ - 1 do
                local wx  = bounds.minX + ix * EXPERIMENTAL_STEP + EXPERIMENTAL_STEP * 0.5
                local wz  = bounds.minZ + iz * EXPERIMENTAL_STEP + EXPERIMENTAL_STEP * 0.5
                local pos = Vector3.new(wx, sweepY, wz)

                local cur = player.Character
                if cur and cur.PrimaryPart then
                    cur:PivotTo(CFrame.new(pos))
                else
                    warn("[Experimental] [Sweep] Character lost mid-sweep, waiting for respawn...")
                    task.wait(2)
                    cur = player.Character
                    if cur and cur.PrimaryPart then
                        cur:PivotTo(CFrame.new(pos))
                    end
                end

                visited += 1
                local pct         = math.floor(visited / total * 100)
                local cacheNow    = #experimentalCacheFolder:GetChildren()
                local newlyCached = cacheNow - cacheStart

                print(string.format(
                    "[Experimental] [Sweep] %d/%d (%.0f%%)  pos=(%.0f, %.0f, %.0f)  cached_total=%d  new_this_sweep=+%d",
                    visited, total, pct, wx, sweepY, wz, cacheNow, newlyCached
                ))

                task.wait(EXPERIMENTAL_DWELL)
            end

            print(string.format("[Experimental] [Sweep] --- Row %d/%d complete ---", ix + 1, stepsX))
        end

        local cur = player.Character
        if cur and cur.PrimaryPart then
            cur:PivotTo(origCFrame)
            print(string.format("[Experimental] Character returned to (%.1f, %.1f, %.1f).",
                origCFrame.Position.X, origCFrame.Position.Y, origCFrame.Position.Z))
        end

        local finalCache = #experimentalCacheFolder:GetChildren()
        print("[Experimental] ============================================")
        print("[Experimental] Sweep COMPLETE.")
        print(string.format("[Experimental]   Positions visited : %d / %d", visited, total))
        print(string.format("[Experimental]   Objects in cache  : %d  (started with %d)", finalCache, cacheStart))
        print(string.format("[Experimental]   New objects found : +%d", finalCache - cacheStart))
        print("[Experimental] ============================================")

        if onComplete then onComplete() end
    end)
end

local function runExperimentalCapture(onComplete)
    print("[Experimental] ============================================")
    print("[Experimental] EXPERIMENTAL MODE ACTIVATED")
    print("[Experimental] Pipeline: bounds detect → cache start → char sweep → save")
    print("[Experimental] ============================================")

    local bounds = detectMapBounds()
    startExperimentalCache()

    performExperimentalSweep(bounds, function()
        stopExperimentalCache()
        print("[Experimental] All phases done, handing off to save logic.")
        if onComplete then onComplete() end
    end)
end

-- ============================================================
--  UI THEME
-- ============================================================
local T = {
    bg         = Color3.fromRGB(12,  13,  18),
    panel      = Color3.fromRGB(20,  22,  32),
    panelAlt   = Color3.fromRGB(24,  26,  38),
    accent     = Color3.fromRGB(82, 130, 255),
    accentGlow = Color3.fromRGB(110, 160, 255),
    success    = Color3.fromRGB(52, 211, 153),
    warning    = Color3.fromRGB(251, 191,  36),
    danger     = Color3.fromRGB(248,  90,  90),
    text       = Color3.fromRGB(230, 235, 255),
    sub        = Color3.fromRGB(120, 128, 165),
    border     = Color3.fromRGB(38,  42,  62),
    toggleOff  = Color3.fromRGB(42,  44,  62),
    toggleOn   = Color3.fromRGB(82, 130, 255),
    expAccent  = Color3.fromRGB(180, 100, 255),
}

-- ============================================================
--  UI UTILITIES
-- ============================================================
local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, col, thick)
    local s = Instance.new("UIStroke")
    s.Color     = col   or T.border
    s.Thickness = thick or 1
    s.Parent    = parent
    return s
end

local function tween(obj, props, t, style, dir)
    return TweenService:Create(
        obj,
        TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    )
end

-- ============================================================
--  TOGGLE COMPONENT
-- ============================================================
local function createToggle(parent, icon, label, default, order, customAccent)
    local onColor = customAccent or T.toggleOn

    local row = Instance.new("Frame")
    row.Size              = UDim2.new(1, -16, 0, 46)
    row.BackgroundColor3  = T.panelAlt
    row.BorderSizePixel   = 0
    row.LayoutOrder       = order
    row.Parent            = parent
    corner(row, 10)
    stroke(row)

    local ico = Instance.new("TextLabel")
    ico.Size                   = UDim2.new(0, 32, 1, 0)
    ico.Position               = UDim2.new(0, 10, 0, 0)
    ico.BackgroundTransparency = 1
    ico.Text                   = icon
    ico.TextSize               = 16
    ico.Font                   = Enum.Font.Gotham
    ico.TextColor3             = T.sub
    ico.Parent                 = row

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, -108, 1, 0)
    lbl.Position               = UDim2.new(0, 46, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = label
    lbl.TextColor3             = T.text
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.Font                   = Enum.Font.Gotham
    lbl.TextSize               = 13
    lbl.Parent                 = row

    local track = Instance.new("Frame")
    track.Size              = UDim2.new(0, 46, 0, 24)
    track.Position          = UDim2.new(1, -58, 0.5, -12)
    track.BackgroundColor3  = default and onColor or T.toggleOff
    track.BorderSizePixel   = 0
    track.Parent            = row
    corner(track, 12)

    local knob = Instance.new("Frame")
    knob.Size               = UDim2.new(0, 18, 0, 18)
    knob.Position           = default and UDim2.new(0, 25, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel    = 0
    knob.Parent             = track
    corner(knob, 9)

    local isOn     = default
    local blocking = false

    local hitbox = Instance.new("TextButton")
    hitbox.Size                   = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text                   = ""
    hitbox.Parent                 = row

    hitbox.MouseButton1Click:Connect(function()
        if blocking then return end
        blocking = true
        isOn     = not isOn

        local bgColor = isOn and onColor or T.toggleOff
        local knobPos = isOn and UDim2.new(0, 25, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)

        tween(track, {BackgroundColor3 = bgColor}, 0.18):Play()
        local kt = tween(knob, {Position = knobPos}, 0.18)
        kt:Play()
        kt.Completed:Connect(function() blocking = false end)
    end)

    return {
        Frame = row,
        IsOn  = function() return isOn end,
        Set   = function(v)
            isOn                   = v
            track.BackgroundColor3 = v and onColor or T.toggleOff
            knob.Position          = v and UDim2.new(0, 25, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        end,
    }
end

-- ============================================================
--  PLATFORM PROMPT
-- ============================================================
local function showPlatformPrompt(callback)
    local gui = Instance.new("ScreenGui")
    gui.Name            = "PlatformPrompt"
    gui.ResetOnSpawn    = false
    gui.IgnoreGuiInset  = true
    gui.DisplayOrder    = 2147483647
    gui.Parent          = playerGui

    local overlay = Instance.new("Frame")
    overlay.Size                   = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.35
    overlay.BorderSizePixel        = 0
    overlay.Parent                 = gui

    local card = Instance.new("Frame")
    card.Size             = UDim2.new(0, 440, 0, 280)
    card.Position         = UDim2.new(0.5, -220, 0.5, -140)
    card.BackgroundColor3 = T.panel
    card.BorderSizePixel  = 0
    card.Parent           = gui
    corner(card, 16)
    stroke(card)

    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(1, 0, 0, 3)
    bar.BackgroundColor3 = T.accent
    bar.BorderSizePixel  = 0
    bar.Parent           = card
    corner(bar, 2)

    local iconBg = Instance.new("Frame")
    iconBg.Size             = UDim2.new(0, 48, 0, 48)
    iconBg.Position         = UDim2.new(0, 20, 0, 22)
    iconBg.BackgroundColor3 = Color3.fromRGB(30, 36, 60)
    iconBg.BorderSizePixel  = 0
    iconBg.Parent           = card
    corner(iconBg, 24)
    stroke(iconBg)

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size                   = UDim2.new(1, 0, 1, 0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text                   = "🏗"
    iconLbl.TextSize               = 24
    iconLbl.Font                   = Enum.Font.Gotham
    iconLbl.Parent                 = iconBg

    local title = Instance.new("TextLabel")
    title.Size                   = UDim2.new(1, -86, 0, 32)
    title.Position               = UDim2.new(0, 78, 0, 22)
    title.BackgroundTransparency = 1
    title.Text                   = "Use Floating Platform?"
    title.TextColor3             = T.text
    title.TextXAlignment         = Enum.TextXAlignment.Left
    title.Font                   = Enum.Font.GothamBold
    title.TextSize               = 19
    title.Parent                 = card

    local sub = Instance.new("TextLabel")
    sub.Size                   = UDim2.new(1, -40, 0, 78)
    sub.Position               = UDim2.new(0, 20, 0, 86)
    sub.BackgroundTransparency = 1
    sub.Text                   = "Teleports your character to a hidden platform far from the map, "
                               .. "reducing server-side detection and interference while the instance saves.\n\n"
                               .. "Recommended for large or active servers."
    sub.TextColor3             = T.sub
    sub.TextXAlignment         = Enum.TextXAlignment.Left
    sub.TextWrapped            = true
    sub.Font                   = Enum.Font.Gotham
    sub.TextSize               = 12
    sub.Parent                 = card

    local div = Instance.new("Frame")
    div.Size             = UDim2.new(1, -40, 0, 1)
    div.Position         = UDim2.new(0, 20, 0, 176)
    div.BackgroundColor3 = T.border
    div.BorderSizePixel  = 0
    div.Parent           = card

    local btnNo = Instance.new("TextButton")
    btnNo.Size             = UDim2.new(0, 180, 0, 44)
    btnNo.Position         = UDim2.new(0, 20, 0, 190)
    btnNo.BackgroundColor3 = T.toggleOff
    btnNo.Text             = "Skip — No Platform"
    btnNo.TextColor3       = T.sub
    btnNo.Font             = Enum.Font.GothamBold
    btnNo.TextSize         = 13
    btnNo.BorderSizePixel  = 0
    btnNo.AutoButtonColor  = false
    btnNo.Parent           = card
    corner(btnNo, 10)
    stroke(btnNo)

    local btnYes = Instance.new("TextButton")
    btnYes.Size             = UDim2.new(0, 200, 0, 44)
    btnYes.Position         = UDim2.new(1, -220, 0, 190)
    btnYes.BackgroundColor3 = T.accent
    btnYes.Text             = "Enable Platform  ✓"
    btnYes.TextColor3       = Color3.fromRGB(255, 255, 255)
    btnYes.Font             = Enum.Font.GothamBold
    btnYes.TextSize         = 13
    btnYes.BorderSizePixel  = 0
    btnYes.AutoButtonColor  = false
    btnYes.Parent           = card
    corner(btnYes, 10)

    btnNo.MouseEnter:Connect(function()  tween(btnNo,  {BackgroundColor3 = Color3.fromRGB(55, 57, 80)}, 0.12):Play() end)
    btnNo.MouseLeave:Connect(function()  tween(btnNo,  {BackgroundColor3 = T.toggleOff},               0.12):Play() end)
    btnYes.MouseEnter:Connect(function() tween(btnYes, {BackgroundColor3 = T.accentGlow},              0.12):Play() end)
    btnYes.MouseLeave:Connect(function() tween(btnYes, {BackgroundColor3 = T.accent},                  0.12):Play() end)

    btnNo.MouseButton1Click:Connect(function()  gui:Destroy(); callback(false) end)
    btnYes.MouseButton1Click:Connect(function() gui:Destroy(); callback(true)  end)
end

-- ============================================================
--  MAIN SAVE UI
-- ============================================================
local function createMainUI()
    local gui = Instance.new("ScreenGui")
    gui.Name            = "SaveInstanceMenu"
    gui.ResetOnSpawn    = false
    gui.IgnoreGuiInset  = true
    gui.DisplayOrder    = 2147483646
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    gui.Parent          = playerGui

    local win = Instance.new("Frame")
    win.Name             = "Window"
    win.Size             = UDim2.new(0, 470, 0, 580)
    win.Position         = UDim2.new(0.5, -235, 0.5, -290)
    win.BackgroundColor3 = T.bg
    win.BorderSizePixel  = 0
    win.Parent           = gui
    corner(win, 16)
    stroke(win)

    -- ── Top accent bar ───────────────────────────────────────
    local topBar = Instance.new("Frame")
    topBar.Size             = UDim2.new(1, 0, 0, 3)
    topBar.BackgroundColor3 = T.accent
    topBar.BorderSizePixel  = 0
    topBar.Parent           = win
    corner(topBar, 2)

    -- ── Header (drag handle) ─────────────────────────────────
    local header = Instance.new("Frame")
    header.Size             = UDim2.new(1, 0, 0, 58)
    header.Position         = UDim2.new(0, 0, 0, 3)
    header.BackgroundColor3 = T.panel
    header.BorderSizePixel  = 0
    header.Parent           = win

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size                   = UDim2.new(1, -160, 1, 0)
    titleLbl.Position               = UDim2.new(0, 18, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text                   = "💾  Save Instance"
    titleLbl.TextColor3             = T.text
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
    titleLbl.Font                   = Enum.Font.GothamBold
    titleLbl.TextSize               = 18
    titleLbl.Parent                 = header

    local pill = Instance.new("TextLabel")
    pill.Name             = "StatusPill"
    pill.Size             = UDim2.new(0, 80, 0, 26)
    pill.Position         = UDim2.new(1, -136, 0.5, -13)
    pill.BackgroundColor3 = T.success
    pill.Text             = "  Ready  "
    pill.TextColor3       = Color3.fromRGB(10, 10, 10)
    pill.Font             = Enum.Font.GothamBold
    pill.TextSize         = 11
    pill.BorderSizePixel  = 0
    pill.Parent           = header
    corner(pill, 13)

    -- ── Close button ─────────────────────────────────────────
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size             = UDim2.new(0, 30, 0, 30)
    closeBtn.Position         = UDim2.new(1, -42, 0.5, -15)
    closeBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
    closeBtn.Text             = "✕"
    closeBtn.TextColor3       = T.danger
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.TextSize         = 14
    closeBtn.BorderSizePixel  = 0
    closeBtn.AutoButtonColor  = false
    closeBtn.Parent           = header
    corner(closeBtn, 8)

    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(90, 40, 40)}, 0.12):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(60, 40, 40)}, 0.12):Play()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    -- ── Drag logic ───────────────────────────────────────────
    local dragging  = false
    local dragStart = nil
    local winStart  = nil

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            winStart  = win.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            win.Position = UDim2.new(
                winStart.X.Scale, winStart.X.Offset + delta.X,
                winStart.Y.Scale, winStart.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- ── Section labels & scroll ──────────────────────────────
    local y = 72

    local function sectionLabel(text, yOff, col)
        local lbl = Instance.new("TextLabel")
        lbl.Size                   = UDim2.new(1, -36, 0, 20)
        lbl.Position               = UDim2.new(0, 18, 0, yOff)
        lbl.BackgroundTransparency = 1
        lbl.Text                   = text
        lbl.TextColor3             = col or T.accent
        lbl.TextXAlignment         = Enum.TextXAlignment.Left
        lbl.Font                   = Enum.Font.GothamBold
        lbl.TextSize               = 10
        lbl.Parent                 = win
        return lbl
    end

    sectionLabel("SAVE OPTIONS", y) y += 24

    -- Scroll container for toggles
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size                   = UDim2.new(1, -36, 0, 420)
    scroll.Position               = UDim2.new(0, 18, 0, y)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel        = 0
    scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness     = 3
    scroll.ScrollBarImageColor3   = T.accent
    scroll.Parent                 = win

    local list = Instance.new("UIListLayout")
    list.Padding             = UDim.new(0, 6)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.SortOrder           = Enum.SortOrder.LayoutOrder
    list.Parent              = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 4)
    pad.Parent     = scroll

    local toggles = {}
    toggles.Map              = createToggle(scroll, "💾", "Save Map",                             true,  1)
    toggles.UI               = createToggle(scroll, "🖥", "Save UI (PlayerGui / CoreGui)",         true,  2)
    toggles.Scripts          = createToggle(scroll, "📜", "Save LocalScripts",                    true,  3)
    toggles.SafeMode         = createToggle(scroll, "🛡", "SafeMode — Anti-Detection",             true,  4)
    toggles.AntiIdle         = createToggle(scroll, "⏳", "Anti-Idle — Prevent AFK Kick",          true,  5)
    toggles.Anon             = createToggle(scroll, "🕵", "Anonymous — Strip User Info",           false, 6)
    toggles.Bytecode         = createToggle(scroll, "⚙", "Save Bytecode",                         false, 7)
    toggles.StreamingBypass  = createToggle(scroll, "📡", "Disable StreamingEnabled on Run",       true,  8)
    toggles.CameraSweep      = createToggle(scroll, "🎥", "Camera Sweep — Force Chunk Loading",    true,  9)
    toggles.Experimental     = createToggle(scroll, "🧪", "Experimental — Char-Position Sweep",   false, 10, T.expAccent)

    -- Note under experimental toggle
    local expNote = Instance.new("TextLabel")
    expNote.Size                   = UDim2.new(1, -16, 0, 26)
    expNote.BackgroundTransparency = 1
    expNote.Text                   = "⚠  Teleports character across map to force streaming + caches unloaded chunks"
    expNote.TextColor3             = Color3.fromRGB(160, 110, 220)
    expNote.TextXAlignment         = Enum.TextXAlignment.Left
    expNote.TextWrapped            = true
    expNote.Font                   = Enum.Font.Gotham
    expNote.TextSize               = 10
    expNote.LayoutOrder            = 11
    expNote.Parent                 = scroll

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 10)
    end)

    -- ── Run button ───────────────────────────────────────────
    local runBtn = Instance.new("TextButton")
    runBtn.Size             = UDim2.new(1, -36, 0, 50)
    runBtn.Position         = UDim2.new(0, 18, 1, -64)
    runBtn.BackgroundColor3 = T.accent
    runBtn.Text             = "▶  Run & Save Instance"
    runBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    runBtn.Font             = Enum.Font.GothamBold
    runBtn.TextSize         = 15
    runBtn.BorderSizePixel  = 0
    runBtn.AutoButtonColor  = false
    runBtn.Parent           = win
    corner(runBtn, 12)

    runBtn.MouseEnter:Connect(function()
        tween(runBtn, {BackgroundColor3 = T.accentGlow}, 0.15):Play()
    end)
    runBtn.MouseLeave:Connect(function()
        tween(runBtn, {BackgroundColor3 = T.accent}, 0.15):Play()
    end)

    return gui, runBtn, toggles, pill
end

-- ============================================================
--  SAVE LOGIC
-- ============================================================
local function generateFileName()
    local ts  = os.date("%Y%m%d_%H%M%S")
    local rnd = HttpService:GenerateGUID():sub(1, 6)
    local nm  = player.Name:gsub("[^%w]", "")
    return string.format("RobloxSave_%s_%s_%s", nm, ts, rnd)
end

local function buildOptions(toggles)
    local opts = {
        mode          = "optimized",
        FilePath      = generateFileName(),
        SafeMode      = toggles.SafeMode.IsOn(),
        AntiIdle      = toggles.AntiIdle.IsOn(),
        Anonymous     = toggles.Anon.IsOn(),
        SaveBytecode  = toggles.Bytecode.IsOn(),
        ShowStatus    = true,
        KillAllScripts= toggles.SafeMode.IsOn(),
        IgnoreList    = {},
        ExtraInstances= {},
    }
    if not toggles.Map.IsOn() then
        table.insert(opts.IgnoreList, workspace)
    end
    if not toggles.UI.IsOn() then
        table.insert(opts.IgnoreList, "PlayerGui")
        table.insert(opts.IgnoreList, "StarterGui")
        table.insert(opts.IgnoreList, "CoreGui")
    end
    if not toggles.Scripts.IsOn() then
        opts.noscripts = true
    end

    if experimentalCacheFolder then
        table.insert(opts.ExtraInstances, experimentalCacheFolder)
        print("[Experimental] Cache folder injected into ExtraInstances for save.")
    end

    return opts
end

-- ============================================================
--  BOOT  (platform prompt → main UI)
-- ============================================================
showPlatformPrompt(function(wantsPlatform)

    -- 1. Platform (optional)
    if wantsPlatform then
        platform, spawnLocation = createLocalPlatform()
        if spawnLocation then
            player.RespawnLocation = spawnLocation
        end
        startTeleportLoop()
    end

    -- 2. Show main UI
    local gui, runBtn, toggles, pill = createMainUI()

    -- 3. Wire up Run button
    runBtn.MouseButton1Click:Connect(function()

        local useExperimental   = toggles.Experimental.IsOn()
        local useStreaming      = toggles.StreamingBypass.IsOn()
        local useCameraSweep    = toggles.CameraSweep.IsOn()

        -- Always apply streaming bypass first if toggled
        if useStreaming then
            bypassStreaming()
        end

        if useExperimental then
            -- ── EXPERIMENTAL FLOW ────────────────────────────
            print("[Experimental] Run button pressed — experimental mode ON.")
            runBtn.Text             = "🧪  Detecting bounds..."
            runBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 120)
            pill.Text               = "  Scanning  "
            pill.BackgroundColor3   = T.expAccent

            local wasLooping = teleportLoopRunning
            if wasLooping then
                stopTeleportLoop()
                print("[Experimental] Teleport loop paused for sweep.")
            end

            runExperimentalCapture(function()
                runBtn.Text           = "💾  Saving (experimental)..."
                pill.Text             = "  Saving  "
                pill.BackgroundColor3 = T.warning

                local opts = buildOptions(toggles)
                print("[Save] Options:", HttpService:JSONEncode(opts))

                local ok, err = pcall(function()
                    synsaveinstance(opts)
                end)

                destroyExperimentalCache()

                if ok then
                    print("[Save] Done (experimental)! →", opts.FilePath .. ".rbxl")
                    pill.Text               = "  Saved ✓  "
                    pill.BackgroundColor3   = T.success
                    runBtn.Text             = "✓  Saved — Run Again?"
                    runBtn.BackgroundColor3 = T.success
                else
                    warn("[Save] Failed:", err)
                    pill.Text               = "  Failed  "
                    pill.BackgroundColor3   = T.danger
                    runBtn.Text             = "✗  Failed — Retry?"
                    runBtn.BackgroundColor3 = T.danger
                end

                if wasLooping then
                    startTeleportLoop()
                    print("[Experimental] Teleport loop resumed.")
                end

                task.wait(2.5)
                tween(runBtn, {BackgroundColor3 = T.accent}, 0.3):Play()
                runBtn.Text           = "▶  Run & Save Instance"
                pill.Text             = "  Ready  "
                pill.BackgroundColor3 = T.success
            end)

        else
            -- ── STANDARD FLOW ────────────────────────────────
            local wasLooping = teleportLoopRunning
            if wasLooping then stopTeleportLoop() end

            local function doSave()
                runBtn.Text             = "💾  Saving..."
                pill.Text               = "  Saving  "
                pill.BackgroundColor3   = T.warning

                local opts = buildOptions(toggles)
                print("[Save] Options:", HttpService:JSONEncode(opts))

                local ok, err = pcall(function()
                    synsaveinstance(opts)
                end)

                if ok then
                    print("[Save] Done! →", opts.FilePath .. ".rbxl")
                    pill.Text               = "  Saved ✓  "
                    pill.BackgroundColor3   = T.success
                    runBtn.Text             = "✓  Saved — Run Again?"
                    runBtn.BackgroundColor3 = T.success
                else
                    warn("[Save] Failed:", err)
                    pill.Text               = "  Failed  "
                    pill.BackgroundColor3   = T.danger
                    runBtn.Text             = "✗  Failed — Retry?"
                    runBtn.BackgroundColor3 = T.danger
                end

                if wasLooping then startTeleportLoop() end

                task.wait(2.5)
                tween(runBtn, {BackgroundColor3 = T.accent}, 0.3):Play()
                runBtn.Text           = "▶  Run & Save Instance"
                pill.Text             = "  Ready  "
                pill.BackgroundColor3 = T.success
            end

            if useCameraSweep then
                runBtn.Text             = "⏳  Camera sweep..."
                runBtn.BackgroundColor3 = Color3.fromRGB(60, 65, 100)
                pill.Text               = "  Sweeping  "
                pill.BackgroundColor3   = T.warning

                performCameraSweep(function()
                    doSave()
                end)
            else
                doSave()
            end
        end
    end)
end)

-- ============================================================
--  CLEANUP
-- ============================================================
local function cleanup()
    stopTeleportLoop()
    destroyPlatform()
    destroyExperimentalCache()
    local g = playerGui:FindFirstChild("SaveInstanceMenu")
    if g then g:Destroy() end
    local p = playerGui:FindFirstChild("PlatformPrompt")
    if p then p:Destroy() end
    print("[SaveInstance] Cleanup done.")
end
