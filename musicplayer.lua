local CFG = {
    MAX_DEPTH = 2,
    EXTENSIONS = { mp3 = true, ogg = true, wav = true },
    IMAGE_EXTENSIONS = { png = true, jpg = true, jpeg = true, webp = true },
    FALLBACK_URL = "https://media.discordapp.net/stickers/1499067663496777729.png", -- thanks weao for bao
    SAMPLE_URL = "https://raw.githubusercontent.com/eliassixseven09-web/slap-battless/main/Joji_-_Worldstar_Money_TRASH_remix_%28mp3.pm%29.mp3", -- thanks to hypergamy vw6222
    PLAYER_W = 376,
    TOPBAR_H = 28,
    BODY_H = 114,
    FULL_H = 142,
    CARD_R = 10,
    EQ_COUNT = 8,
    IMPORT_COMPACT_H = 58,
    IMPORT_EXPANDED_H = 248,
}

local PATHS = {
    BASE = "xzyp",
    LOCAL = "xzyp/Local Playlist",
    YT = "xzyp/YouTube Downloads",
    COVERS = "xzyp/Covers",
    SYS = "xzyp/System",
    ICONS = "xzyp/System/icons",
    CACHE = "xzyp/System/.cache",
    STATE = "xzyp/System/state.json",
    FALLBACK = "xzyp/System/fallback.png",
    LOG = "xzyp/System/debug_log.txt",
    SAMPLE = "xzyp/Local Playlist/Bad Apple.ogg",
}

local CLR = {
    BG_WINDOW = Color3.fromRGB(5, 5, 7),
    BG_HEADER = Color3.fromRGB(8, 8, 11),
    BG_SURFACE = Color3.fromRGB(12, 12, 16),
    BG_ELEVATED = Color3.fromRGB(19, 20, 25),
    BG_ACTIVE = Color3.fromRGB(25, 26, 33),
    BORDER_LINE = Color3.fromRGB(24, 25, 32),
    TEXT_PRIMARY = Color3.fromRGB(238, 238, 242),
    TEXT_SECONDARY = Color3.fromRGB(125, 128, 140),
    TEXT_MUTED = Color3.fromRGB(76, 79, 90),
    CLIENT_WHITE = Color3.fromRGB(238, 238, 242),
    SPOTIFY_GREEN = Color3.fromRGB(30, 215, 96),
    STATUS_OK = Color3.fromRGB(64, 214, 114),
    STATUS_WARN = Color3.fromRGB(245, 185, 75),
    STATUS_ERR = Color3.fromRGB(245, 95, 105),
}

local SRV = {
    Players = game:GetService("Players"),
    UIS = game:GetService("UserInputService"),
    TS = game:GetService("TweenService"),
    RS = game:GetService("RunService"),
    TXT = game:GetService("TextService"),
    Http = game:GetService("HttpService"),
    Sound = game:GetService("SoundService"),
}

local UI = {}
local RT = {
    debugLogs = {},
    collection = {},
    connections = {},
    categories = {},
    songs = {},
    songRows = {},
    filterButtons = {},
    eqBars = {},
    cur = nil,
    lastSong = nil,
    playing = false,
    startedAt = 0,
    pausedAt = 0,
    seeking = false,
    seekFrac = 0,
    seekHovering = false,
    volDragging = false,
    titleOverflow = 0,
    titleSetTime = 0,
    activeFilter = "ALL",
    downloading = false,
    searching = false,
    listeningKey = false,
    hideKey = nil,
    defaultCover = "",
}

local httpRequest = (syn and syn.request) or request or http_request or (http and http.request)

local function log(tag, ...)
    local args = { ... }
    local strArr = {}
    for i = 1, #args do
        strArr[i] = tostring(args[i])
    end
    local msg = string.format("[%s] [%.3f] %s", tag, os.clock(), table.concat(strArr, " "))
    RT.debugLogs[#RT.debugLogs + 1] = msg
    print(msg)
end

local function copyLogsToClipboard()
    local dump = table.concat(RT.debugLogs, "\n")
    local setclip = setclipboard or toclipboard or (Clipboard and Clipboard.set)
    if setclip then
        setclip(dump)
        log("DEBUG", "Copied logs to clipboard.")
        return true
    else
        pcall(writefile, PATHS.LOG, dump)
        log("DEBUG", "Saved logs to " .. PATHS.LOG)
        return false
    end
end

log("INIT", "xzyp music player starting up...")
log("ENV", "httpRequest:", httpRequest ~= nil, "| getcustomasset:", getcustomasset ~= nil)

local function mkdir(p)
    if not isfolder(p) then
        pcall(makefolder, p)
    end
end

local function moveFileSafe(src, dst)
    if src == dst or not isfile(src) then return false end
    local okR, data = pcall(readfile, src)
    if okR and type(data) == "string" and #data > 0 then
        local okW = pcall(writefile, dst, data)
        if okW and isfile(dst) then
            pcall(delfile, src)
            return true
        end
    end
    return false
end

local function fetch(path, url, png)
    if isfile(path) then return true end
    return (pcall(function()
        local data = game:HttpGet(url)
        if png then
            assert(data:sub(2, 4) == "PNG")
        else
            assert(#data > 4096)
        end
        writefile(path, data)
    end))
end

local State = {
    titles = {},
    meta = {},
    rainbow = true,
    spotifyGreen = false,
    shuffle = false,
    loopOne = false,
    scale = 1,
    volume = 1.14,
    apiKey = "",
    lastSong = "",
    hideKey = "",
}

local function saveState()
    pcall(function()
        writefile(PATHS.STATE, SRV.Http:JSONEncode(State))
    end)
end

do
    local firstRun = not isfolder(PATHS.BASE)
    mkdir(PATHS.BASE)
    mkdir(PATHS.LOCAL)
    mkdir(PATHS.YT)
    mkdir(PATHS.COVERS)
    mkdir(PATHS.SYS)
    mkdir(PATHS.ICONS)
    mkdir(PATHS.CACHE)

    local legacyState = PATHS.BASE .. "/Last State.txt"
    if isfile(legacyState) then
        if not isfile(PATHS.STATE) then
            moveFileSafe(legacyState, PATHS.STATE)
        else
            pcall(delfile, legacyState)
        end
    end
    if isfile(PATHS.BASE .. "/fallback.png") then
        moveFileSafe(PATHS.BASE .. "/fallback.png", PATHS.FALLBACK)
    end
    if isfile(PATHS.BASE .. "/debug_log.txt") then
        moveFileSafe(PATHS.BASE .. "/debug_log.txt", PATHS.LOG)
    end
    if not isfile(PATHS.STATE) then
        pcall(writefile, PATHS.STATE, "{}")
    end

    pcall(function()
        local decoded = SRV.Http:JSONDecode(readfile(PATHS.STATE))
        if type(decoded) == "table" then
            for k, v in pairs(decoded) do
                State[k] = v
            end
        end
    end)
    if type(State.titles) ~= "table" then State.titles = {} end
    if type(State.meta) ~= "table" then State.meta = {} end

    local legacyPlaylistDir = PATHS.BASE .. "/Your Playlist"
    if isfolder(legacyPlaylistDir) then
        local okList, oldFiles = pcall(listfiles, legacyPlaylistDir)
        if okList and type(oldFiles) == "table" then
            for _, oldPath in ipairs(oldFiles) do
                if not isfolder(oldPath) then
                    local fname = oldPath:match("([^/\\]+)$")
                    local ext = fname and fname:match("%.(%w+)$")
                    ext = ext and ext:lower()
                    if fname and ext then
                        local baseNoExt = fname:match("^(.+)%.%w+$") or fname
                        if CFG.IMAGE_EXTENSIONS[ext] then
                            moveFileSafe(oldPath, PATHS.COVERS .. "/" .. fname)
                        elseif CFG.EXTENSIONS[ext] then
                            local isYtFile = baseNoExt:match("^yt_[%w_%-]+$") ~= nil
                                or State.titles[baseNoExt] ~= nil
                                or State.meta[baseNoExt] ~= nil
                            moveFileSafe(oldPath, (isYtFile and PATHS.YT or PATHS.LOCAL) .. "/" .. fname)
                        end
                    end
                end
            end
        end
        pcall(delfolder, legacyPlaylistDir)
    end

    fetch(PATHS.FALLBACK, CFG.FALLBACK_URL, true)
    if firstRun then
        fetch(PATHS.SAMPLE, CFG.SAMPLE_URL, false)
    end
end

local Opts = {
    rainbow = State.rainbow ~= false,
    spotifyGreen = State.spotifyGreen == true,
    shuffle = State.shuffle == true,
    loopOne = State.loopOne == true,
    scale = math.clamp(tonumber(State.scale) or 1, 0.75, 1.35),
    volume = math.clamp(tonumber(State.volume) or 1.14, 0, 2),
    apiKey = type(State.apiKey) == "string" and State.apiKey or "",
}

RT.hideKey = (type(State.hideKey) == "string" and State.hideKey ~= "") and Enum.KeyCode[State.hideKey] or nil

local function getAccent()
    return Opts.spotifyGreen and CLR.SPOTIFY_GREEN or CLR.CLIENT_WHITE
end

local function getAccentText()
    return Color3.fromRGB(6, 6, 8)
end

local function make(class, parent, props)
    local o = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            o[k] = v
        end
    end
    o.Parent = parent
    RT.collection[#RT.collection + 1] = o
    return o
end

local function connect(signal, fn)
    local c = signal:Connect(fn)
    RT.connections[#RT.connections + 1] = c
    return c
end

local function cleanup()
    for _, c in ipairs(RT.connections) do
        pcall(function() c:Disconnect() end)
    end
    for i = #RT.collection, 1, -1 do
        pcall(function() RT.collection[i]:Destroy() end)
        RT.collection[i] = nil
    end
end

local function tween(o, t, props, style, dir)
    local tw = SRV.TS:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function norm(p)
    return (p:gsub("\\", "/"):gsub("/+$", ""))
end

local SKIP_DIRS = { icons = true, [".cache"] = true, system = true, covers = true }

local function scanDir(dir, depth)
    local ok, files = pcall(listfiles, dir)
    if (not ok or type(files) ~= "table") and dir == "" then
        ok, files = pcall(listfiles, ".")
    end
    if not ok or type(files) ~= "table" then return end

    local list, dirs, covers = {}, {}, {}
    for _, path in ipairs(files) do
        if isfolder(path) then
            local last = norm(path):match("([^/]+)$")
            if not (last and SKIP_DIRS[last:lower()]) then
                dirs[#dirs + 1] = path
            end
        else
            local ext = path:match("%.(%w+)$")
            ext = ext and ext:lower()
            if ext and CFG.EXTENSIONS[ext] then
                local rawBase = path:match("([^/\\]+)%.%w+$") or "Unknown Track"
                local ytIdMatch = rawBase:match("^yt_([%w_%-]+)$")
                local savedMeta = State.meta[rawBase] or (ytIdMatch and State.meta[ytIdMatch])
                local savedTitle = (type(savedMeta) == "table" and savedMeta.title)
                    or State.titles[rawBase]
                    or (ytIdMatch and State.titles[ytIdMatch])
                local displayName = savedTitle or rawBase
                local inYtDir = norm(dir):find("YouTube Downloads", 1, true) ~= nil
                local savedSrc = type(savedMeta) == "table" and savedMeta.source or nil
                local isYt = inYtDir or (ytIdMatch ~= nil) or (savedTitle ~= nil) or (savedSrc == "YT" or savedSrc == "SP+YT" or savedSrc == "Youtube")

                list[#list + 1] = {
                    path = path,
                    name = displayName,
                    creator = (type(savedMeta) == "table" and savedMeta.creator) or (isYt and "YouTube Creator" or "Local Audio"),
                    dir = dir,
                    source = isYt and "Youtube" or "LOCAL",
                    note = isYt and "Youtube" or "Local Playlist",
                    ytId = ytIdMatch,
                }
            elseif dir ~= "" and ext and CFG.IMAGE_EXTENSIONS[ext] then
                covers[#covers + 1] = path
            end
        end
    end

    if #list > 0 then
        local label = norm(dir)
        if label == "" then
            label = "Workspace"
        elseif label:sub(1, #PATHS.BASE + 1) == PATHS.BASE .. "/" then
            label = label:sub(#PATHS.BASE + 2)
        end
        RT.categories[#RT.categories + 1] = { dir = dir, label = label, songs = list, covers = covers }
        for _, s in ipairs(list) do
            RT.songs[#RT.songs + 1] = s
            s.idx = #RT.songs
        end
    end

    if depth < CFG.MAX_DEPTH then
        for _, d in ipairs(dirs) do
            scanDir(d, depth + 1)
        end
    end
end

scanDir((getgenv and getgenv().ScanWholeWorkspace) and "" or PATHS.BASE, 0)
log("SCAN", "Initial songs loaded:", #RT.songs)

for _, s in ipairs(RT.songs) do
    if s.path == State.lastSong then
        RT.lastSong = s
        break
    end
end

local function asset(p)
    local ok, r = pcall(getcustomasset, p)
    return (ok and type(r) == "string" and r ~= "") and r or ""
end

RT.defaultCover = isfile(PATHS.FALLBACK) and asset(PATHS.FALLBACK) or ""

local function audioOf(s)
    if s.audio and s.audio ~= "" then
        return s.audio
    end
    local res = asset(s.path)
    if res == "" and isfile(s.path) then
        local ext = (s.path:match("%.(%w+)$") or "mp3"):lower()
        local hash = 0
        for i = 1, #s.path do
            hash = (hash * 31 + s.path:byte(i)) % 2147483647
        end
        local safeCachePath = string.format("%s/cached_%d.%s", PATHS.CACHE, hash, ext)
        if not isfile(safeCachePath) then
            local okRead, bytes = pcall(readfile, s.path)
            if okRead and type(bytes) == "string" and #bytes > 1024 then
                pcall(writefile, safeCachePath, bytes)
            end
        end
        res = asset(safeCachePath)
        if res ~= "" then
            log("AUDIO_CACHE", "Normalized to ASCII:", s.path, "->", safeCachePath)
        end
    end
    log("AUDIO_ASSET", "getcustomasset:", s.path, "->", res ~= "" and res or "FAILED")
    s.audio = res
    return res
end

local function coverOf(s)
    if not s then return RT.defaultCover end
    if s.coverPath and isfile(s.coverPath) then
        local a = asset(s.coverPath)
        if a ~= "" then return a end
    end
    local baseName = s.path:match("([^/\\]+)%.%w+$")
    if baseName then
        for _, ext in ipairs({ "png", "jpg", "jpeg", "webp" }) do
            local centralCover = PATHS.COVERS .. "/" .. baseName .. "." .. ext
            if isfile(centralCover) then
                s.coverPath = centralCover
                local a = asset(centralCover)
                if a ~= "" then return a end
            end
            if s.ytId then
                local idCover = PATHS.COVERS .. "/yt_" .. s.ytId .. "." .. ext
                if isfile(idCover) then
                    s.coverPath = idCover
                    local a = asset(idCover)
                    if a ~= "" then return a end
                end
            end
            if s.dir then
                local localCover = s.dir .. "/" .. baseName .. "." .. ext
                if isfile(localCover) then
                    s.coverPath = localCover
                    local a = asset(localCover)
                    if a ~= "" then return a end
                end
            end
        end
    end
    return RT.defaultCover
end

local Sound = make("Sound", SRV.Sound, {
    Name = "xzypAudio",
    Looped = false,
    Volume = Opts.volume,
})

connect(Sound.Loaded, function()
    log("SOUND_LOADED", "TimeLength:", Sound.TimeLength)
end)

local function fmtTime(s)
    s = math.max(0, math.floor(s))
    return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

local function setTrackTitleText(str)
    UI.TrackTitle.Text = str
    UI.TrackTitle.Position = UDim2.fromOffset(0, 0)
    RT.titleSetTime = os.clock()
    local bounds = SRV.TXT:GetTextSize(str, 14, Enum.Font.BuilderSansBold, Vector2.new(4000, 19)).X
    if bounds > 198 then
        UI.TrackTitle.Size = UDim2.fromOffset(bounds + 16, 19)
        RT.titleOverflow = bounds - 198
    else
        UI.TrackTitle.Size = UDim2.fromOffset(198, 19)
        RT.titleOverflow = 0
    end
end

local function layoutSubPanels()
    local screenH = UI.Gui.AbsoluteSize.Y
    local rootY = UI.Root.AbsolutePosition.Y
    local openUpwards = (screenH > 0) and (rootY + CFG.FULL_H + 254 > screenH)

    local panels = {}
    if UI.ImportPanel.Visible then panels[#panels + 1] = UI.ImportPanel end
    if UI.DrawerPanel.Visible then panels[#panels + 1] = UI.DrawerPanel end
    if UI.SettingsPanel.Visible then panels[#panels + 1] = UI.SettingsPanel end

    if openUpwards then
        local y = -6
        for _, p in ipairs(panels) do
            local h = p.Size.Y.Offset
            y -= h
            p.Position = UDim2.fromOffset(0, y)
            y -= 6
        end
    else
        local y = CFG.FULL_H + 6
        for _, p in ipairs(panels) do
            p.Position = UDim2.fromOffset(0, y)
            y += p.Size.Y.Offset + 6
        end
    end
end

local function setSearchResultsExpanded(expanded)
    UI.SearchResultsScroll.Visible = expanded
    UI.ImportPanel.Size = UDim2.fromOffset(CFG.PLAYER_W, expanded and CFG.IMPORT_EXPANDED_H or CFG.IMPORT_COMPACT_H)
    layoutSubPanels()
end

local function syncFilterChips()
    local acc = getAccent()
    local accTxt = getAccentText()
    for key, btn in pairs(RT.filterButtons) do
        local on = (RT.activeFilter == key)
        btn.BackgroundColor3 = on and acc or CLR.BG_SURFACE
        btn.TextColor3 = on and accTxt or CLR.TEXT_SECONDARY
    end
end

local function syncModeButtons()
    UI.ShuffleBtn:SetAttribute("Active", Opts.shuffle)
    UI.ShuffleBtn.TextColor3 = Opts.shuffle and getAccent() or CLR.TEXT_SECONDARY
    UI.LoopBtn:SetAttribute("Active", Opts.loopOne)
    UI.LoopBtn.TextColor3 = Opts.loopOne and getAccent() or CLR.TEXT_SECONDARY
end

local function applyThemeAccent()
    local acc = getAccent()
    local accTxt = getAccentText()
    UI.AddBtn.BackgroundColor3 = acc
    UI.AddBtn.TextColor3 = accTxt
    UI.DownloadBtn.BackgroundColor3 = acc
    UI.DownloadBtn.TextColor3 = accTxt
    UI.setMainPlayColors(acc, accTxt)
    UI.setMiniPlayColors(acc, accTxt)
    UI.SeekFill.BackgroundColor3 = acc
    UI.VolFill.BackgroundColor3 = acc
    syncModeButtons()
    syncFilterChips()
end

local function refreshQueueVisuals()
    local query = UI.SearchBox.Text:lower()
    local shownCount = 0
    for i, sObj in ipairs(RT.songs) do
        sObj.idx = i
        local data = RT.songRows[sObj]
        if data then
            data.Row.LayoutOrder = i
            local isCur = (RT.cur == sObj)
            data.Row.BackgroundColor3 = isCur and CLR.BG_ACTIVE or CLR.BG_SURFACE
            data.Title.TextColor3 = isCur and getAccent() or CLR.TEXT_PRIMARY
            data.Index.Text = isCur and (RT.playing and "||" or "\u{25B6}") or tostring(i)
            data.Index.TextColor3 = isCur and getAccent() or CLR.TEXT_MUTED
            data.Source.Text = sObj.source or "LOCAL"

            local matchFilter = (RT.activeFilter == "ALL") or ((sObj.source or "LOCAL") == RT.activeFilter)
            local hay = (sObj.name .. " " .. (sObj.creator or "")):lower()
            local matchText = (query == "") or (hay:find(query, 1, true) ~= nil)
            local vis = matchFilter and matchText
            data.Row.Visible = vis
            if vis then
                shownCount += 1
            end
        end
    end
    UI.CountBadge.Text = shownCount .. "/" .. #RT.songs
end

local function refreshPlayStateUI()
    UI.setMainPlayVisual(RT.playing)
    UI.setMiniPlayVisual(RT.playing)
    UI.StatusDot.BackgroundColor3 = RT.playing and CLR.STATUS_OK or CLR.TEXT_MUTED
    refreshQueueVisuals()
end

local function playSong(s)
    if not s then return end
    log("PLAY_REQ", "Playing:", s.name, "| Creator:", s.creator, "| Path:", s.path)
    RT.cur = s
    RT.playing = true
    RT.startedAt = os.clock()
    RT.pausedAt = 0
    State.lastSong = s.path
    saveState()

    Sound:Stop()
    local assetId = audioOf(s)
    if assetId == "" then
        setTrackTitleText("Audio load error")
        UI.TrackSub.Text = "Invalid audio format on disk"
        RT.playing = false
        refreshPlayStateUI()
        return
    end

    Sound.SoundId = assetId
    Sound.TimePosition = 0
    Sound.Volume = Opts.volume

    local cov = coverOf(s)
    local creatorText = (s.creator and #s.creator > 0) and s.creator or "Unknown Creator"
    local isYt = (s.source == "Youtube")
    local noteText = isYt and "Youtube" or (s.note or "Local Playlist")

    setTrackTitleText(s.name)
    UI.MiniTitle.Text = s.name
    UI.TrackSub.Text = creatorText .. "  |  " .. noteText
    UI.TrackSub.TextColor3 = CLR.TEXT_SECONDARY
    UI.SourceTag.Text = s.source or "LOCAL"
    UI.CoverImg.Image = cov
    UI.MiniArt.Image = cov
    refreshPlayStateUI()

    task.spawn(function()
        local waited = 0
        while not Sound.IsLoaded and waited < 4 and RT.cur == s do
            waited += task.wait(0.05)
        end
        if RT.cur ~= s then return end
        Sound:Play()
        task.wait(0.08)
        if RT.cur == s and RT.playing and not Sound.IsPlaying then
            Sound:Play()
        end
        log("PLAY_STATE", "IsPlaying:", Sound.IsPlaying, "| TimeLength:", Sound.TimeLength)
    end)

    local nx = RT.songs[s.idx % #RT.songs + 1]
    if nx then
        task.spawn(function() pcall(audioOf, nx) end)
    end
end

local function step(d)
    local n = #RT.songs
    if n == 0 then return end
    if Opts.loopOne and RT.cur then
        playSong(RT.cur)
        return
    end
    if Opts.shuffle and n > 1 then
        local pick = RT.songs[math.random(n)]
        while pick == RT.cur do
            pick = RT.songs[math.random(n)]
        end
        playSong(pick)
        return
    end
    local i = RT.cur and RT.cur.idx or (d > 0 and 0 or 1)
    playSong(RT.songs[(i - 1 + d) % n + 1])
end

local function togglePlay()
    if #RT.songs == 0 then return end
    if not RT.cur then
        playSong(RT.lastSong or RT.songs[1])
        return
    end
    if RT.playing then
        RT.pausedAt = Sound.TimePosition
        RT.playing = false
        Sound:Pause()
    else
        Sound.TimePosition = RT.pausedAt
        Sound:Resume()
        if not Sound.IsPlaying then
            Sound:Play()
        end
        RT.playing = true
    end
    refreshPlayStateUI()
end

local function addPlaylistRow(sObj)
    if RT.songRows[sObj] then return end
    local row = make("TextButton", UI.QueueScroll, {
        Size = UDim2.new(1, -4, 0, 28),
        BackgroundColor3 = CLR.BG_SURFACE,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = sObj.idx,
    })
    make("UICorner", row, { CornerRadius = UDim.new(0, 6) })

    local idxLbl = make("TextLabel", row, {
        Position = UDim2.fromOffset(6, 0),
        Size = UDim2.fromOffset(20, 28),
        BackgroundTransparency = 1,
        Text = tostring(sObj.idx),
        TextColor3 = CLR.TEXT_MUTED,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 10,
    })

    local title = make("TextLabel", row, {
        Position = UDim2.fromOffset(28, 0),
        Size = UDim2.new(1, -112, 1, 0),
        BackgroundTransparency = 1,
        Text = sObj.name,
        TextColor3 = CLR.TEXT_PRIMARY,
        Font = Enum.Font.BuilderSans,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local srcBadge = make("TextLabel", row, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -28, 0.5, 0),
        Size = UDim2.fromOffset(50, 16),
        BackgroundColor3 = CLR.BG_WINDOW,
        BorderSizePixel = 0,
        Text = sObj.source or "LOCAL",
        TextColor3 = CLR.TEXT_MUTED,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 8,
    })
    make("UICorner", srcBadge, { CornerRadius = UDim.new(0, 4) })

    local delBtn = make("TextButton", row, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = CLR.BG_WINDOW,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "\u{00D7}",
        TextColor3 = CLR.TEXT_MUTED,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 10,
    })
    make("UICorner", delBtn, { CornerRadius = UDim.new(0, 4) })

    connect(delBtn.MouseEnter, function()
        delBtn.TextColor3 = CLR.STATUS_ERR
    end)
    connect(delBtn.MouseLeave, function()
        delBtn.TextColor3 = CLR.TEXT_MUTED
    end)
    connect(delBtn.Activated, function()
        if RT.cur == sObj then
            Sound:Stop()
            RT.playing = false
            RT.cur = nil
            setTrackTitleText("No track playing")
            UI.TrackSub.Text = "Track removed"
            UI.TrackSub.TextColor3 = CLR.TEXT_SECONDARY
            UI.SourceTag.Text = "IDLE"
            refreshPlayStateUI()
        end
        pcall(delfile, sObj.path)
        if sObj.coverPath then pcall(delfile, sObj.coverPath) end
        local idxPos = table.find(RT.songs, sObj)
        if idxPos then table.remove(RT.songs, idxPos) end
        RT.songRows[sObj] = nil
        row:Destroy()
        refreshPlayStateUI()
    end)

    connect(row.MouseEnter, function()
        if RT.cur ~= sObj then row.BackgroundColor3 = CLR.BG_ELEVATED end
    end)
    connect(row.MouseLeave, function()
        if RT.cur ~= sObj then row.BackgroundColor3 = CLR.BG_SURFACE end
    end)
    connect(row.Activated, function()
        playSong(sObj)
    end)

    RT.songRows[sObj] = {
        Row = row,
        Index = idxLbl,
        Title = title,
        Source = srcBadge,
    }
    refreshQueueVisuals()
end

do
    local Player = SRV.Players.LocalPlayer
    local guiParent = Player:WaitForChild("PlayerGui")
    if type(gethui) == "function" then
        local okH, hui = pcall(gethui)
        if okH and hui then
            guiParent = hui
        end
    end

    UI.Gui = make("ScreenGui", guiParent, {
        Name = "xzypMusicPlayer",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    UI.Root = make("Frame", UI.Gui, {
        Name = "xzypRoot",
        Size = UDim2.fromOffset(CFG.PLAYER_W, CFG.FULL_H),
        Position = UDim2.new(1, -(CFG.PLAYER_W + 24), 1, -(CFG.FULL_H + 24)),
        BackgroundTransparency = 1,
    })
    UI.RootScale = make("UIScale", UI.Root, { Scale = Opts.scale })

    UI.MainCard = make("Frame", UI.Root, {
        Name = "ClientPlayerCard",
        Size = UDim2.fromOffset(CFG.PLAYER_W, CFG.FULL_H),
        BackgroundColor3 = CLR.BG_WINDOW,
        BorderSizePixel = 0,
    })
    make("UICorner", UI.MainCard, { CornerRadius = UDim.new(0, CFG.CARD_R) })
    make("UIStroke", UI.MainCard, {
        Thickness = 1,
        Color = CLR.BORDER_LINE,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    UI.TopBar = make("Frame", UI.MainCard, {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, CFG.TOPBAR_H),
        BackgroundColor3 = CLR.BG_HEADER,
        BorderSizePixel = 0,
        ZIndex = 2,
    })
    make("UICorner", UI.TopBar, { CornerRadius = UDim.new(0, CFG.CARD_R) })

    make("Frame", UI.TopBar, {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, CFG.CARD_R),
        BackgroundColor3 = CLR.BG_HEADER,
        BorderSizePixel = 0,
        ZIndex = 2,
    })
    make("Frame", UI.TopBar, {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = CLR.BORDER_LINE,
        BorderSizePixel = 0,
        ZIndex = 3,
    })

    UI.StatusDot = make("Frame", UI.TopBar, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 11, 0.5, 0),
        Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = CLR.STATUS_OK,
        BorderSizePixel = 0,
        ZIndex = 4,
    })
    make("UICorner", UI.StatusDot, { CornerRadius = UDim.new(1, 0) })

    make("TextLabel", UI.TopBar, {
        Position = UDim2.fromOffset(23, 0),
        Size = UDim2.fromOffset(180, CFG.TOPBAR_H),
        BackgroundTransparency = 1,
        Text = "xzyp music player",
        TextColor3 = CLR.TEXT_SECONDARY,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    })

    local function makeHeaderPill(pos, size, text, isAccent, textSize)
        local b = make("TextButton", UI.TopBar, {
            Position = pos,
            Size = size,
            BackgroundColor3 = isAccent and getAccent() or CLR.BG_SURFACE,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = text,
            TextColor3 = isAccent and getAccentText() or CLR.TEXT_SECONDARY,
            Font = Enum.Font.BuilderSansBold,
            TextSize = textSize or 9,
            ZIndex = 4,
        })
        make("UICorner", b, { CornerRadius = UDim.new(0, 5) })
        if not isAccent then
            make("UIStroke", b, {
                Thickness = 1,
                Color = CLR.BORDER_LINE,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
        end
        connect(b.MouseEnter, function()
            if isAccent then
                tween(b, 0.12, { BackgroundTransparency = 0.15 })
            else
                tween(b, 0.12, { BackgroundColor3 = CLR.BG_ELEVATED, TextColor3 = CLR.TEXT_PRIMARY })
            end
        end)
        connect(b.MouseLeave, function()
            if isAccent then
                tween(b, 0.12, { BackgroundTransparency = 0 })
            else
                tween(b, 0.12, { BackgroundColor3 = CLR.BG_SURFACE, TextColor3 = CLR.TEXT_SECONDARY })
            end
        end)
        return b
    end

    UI.AddBtn = makeHeaderPill(UDim2.fromOffset(210, 4), UDim2.fromOffset(40, 20), "+ADD", true, 9)
    UI.QueueBtn = makeHeaderPill(UDim2.fromOffset(254, 4), UDim2.fromOffset(44, 20), "QUEUE", false, 9)
    UI.CfgBtn = makeHeaderPill(UDim2.fromOffset(302, 4), UDim2.fromOffset(22, 20), "\u{2699}", false, 11)
    UI.MiniBtn = makeHeaderPill(UDim2.fromOffset(327, 4), UDim2.fromOffset(20, 20), "\u{2014}", false, 10)
    UI.CloseBtn = makeHeaderPill(UDim2.fromOffset(350, 4), UDim2.fromOffset(20, 20), "\u{00D7}", false, 11)

    local Body = make("Frame", UI.MainCard, {
        Name = "PlayerBody",
        Position = UDim2.fromOffset(0, CFG.TOPBAR_H),
        Size = UDim2.new(1, 0, 0, CFG.BODY_H),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    local ArtFrame = make("Frame", Body, {
        Name = "Artwork",
        Position = UDim2.fromOffset(12, 13),
        Size = UDim2.fromOffset(88, 88),
        BackgroundColor3 = CLR.BG_SURFACE,
        BorderSizePixel = 0,
    })
    make("UICorner", ArtFrame, { CornerRadius = UDim.new(0, 8) })

    UI.CoverImg = make("ImageLabel", ArtFrame, {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = CLR.BG_SURFACE,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Image = RT.lastSong and coverOf(RT.lastSong) or RT.defaultCover,
        ScaleType = Enum.ScaleType.Crop,
    })
    make("UICorner", UI.CoverImg, { CornerRadius = UDim.new(0, 8) })

    local ArtBorder = make("Frame", ArtFrame, {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 4,
    })
    make("UICorner", ArtBorder, { CornerRadius = UDim.new(0, 8) })
    make("UIStroke", ArtBorder, {
        Thickness = 1,
        Color = CLR.BORDER_LINE,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    UI.SourceTag = make("TextLabel", ArtFrame, {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 6, 1, -6),
        Size = UDim2.fromOffset(50, 15),
        BackgroundColor3 = Color3.fromRGB(6, 6, 8),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Text = "IDLE",
        TextColor3 = CLR.TEXT_PRIMARY,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 8,
        ZIndex = 3,
    })
    make("UICorner", UI.SourceTag, { CornerRadius = UDim.new(0, 4) })

    local TitleViewport = make("Frame", Body, {
        Position = UDim2.fromOffset(112, 12),
        Size = UDim2.fromOffset(198, 19),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    })

    UI.TrackTitle = make("TextLabel", TitleViewport, {
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(198, 19),
        BackgroundTransparency = 1,
        Text = #RT.songs > 0 and "No track playing" or "Library is empty",
        TextColor3 = CLR.TEXT_PRIMARY,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    UI.TrackSub = make("TextLabel", Body, {
        Position = UDim2.fromOffset(112, 31),
        Size = UDim2.fromOffset(198, 14),
        BackgroundTransparency = 1,
        Text = #RT.songs .. (#RT.songs == 1 and " track available" or " tracks available"),
        TextColor3 = CLR.TEXT_SECONDARY,
        Font = Enum.Font.BuilderSans,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local EqWrap = make("Frame", Body, {
        Position = UDim2.fromOffset(320, 14),
        Size = UDim2.fromOffset(42, 24),
        BackgroundTransparency = 1,
    })
    for i = 1, CFG.EQ_COUNT do
        local bar = make("Frame", EqWrap, {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromOffset((i - 1) * 5, 24),
            Size = UDim2.fromOffset(3, 2),
            BackgroundColor3 = getAccent(),
            BorderSizePixel = 0,
        })
        make("UICorner", bar, { CornerRadius = UDim.new(1, 0) })
        RT.eqBars[i] = bar
    end

    UI.SeekHit = make("TextButton", Body, {
        Name = "SeekHit",
        Position = UDim2.fromOffset(112, 48),
        Size = UDim2.fromOffset(250, 14),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    })
    UI.SeekTrack = make("Frame", UI.SeekHit, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = CLR.BG_ELEVATED,
        BorderSizePixel = 0,
    })
    make("UICorner", UI.SeekTrack, { CornerRadius = UDim.new(1, 0) })

    UI.SeekFill = make("Frame", UI.SeekTrack, {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = getAccent(),
        BorderSizePixel = 0,
    })
    make("UICorner", UI.SeekFill, { CornerRadius = UDim.new(1, 0) })

    UI.SeekKnob = make("Frame", UI.SeekTrack, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(9, 9),
        BackgroundColor3 = CLR.TEXT_PRIMARY,
        BorderSizePixel = 0,
        Visible = false,
    })
    make("UICorner", UI.SeekKnob, { CornerRadius = UDim.new(1, 0) })

    UI.HoverTimeTip = make("TextLabel", Body, {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromOffset(112, 46),
        Size = UDim2.fromOffset(34, 14),
        BackgroundColor3 = CLR.BG_ELEVATED,
        BorderSizePixel = 0,
        Text = "0:00",
        TextColor3 = CLR.TEXT_PRIMARY,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 8,
        Visible = false,
        ZIndex = 8,
    })
    make("UICorner", UI.HoverTimeTip, { CornerRadius = UDim.new(0, 4) })
    make("UIStroke", UI.HoverTimeTip, {
        Thickness = 1,
        Color = CLR.BORDER_LINE,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    UI.TimeNow = make("TextLabel", Body, {
        Position = UDim2.fromOffset(112, 61),
        Size = UDim2.fromOffset(44, 11),
        BackgroundTransparency = 1,
        Text = "0:00",
        TextColor3 = CLR.TEXT_MUTED,
        Font = Enum.Font.BuilderSans,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    UI.TimeEnd = make("TextLabel", Body, {
        Position = UDim2.fromOffset(318, 61),
        Size = UDim2.fromOffset(44, 11),
        BackgroundTransparency = 1,
        Text = "0:00",
        TextColor3 = CLR.TEXT_MUTED,
        Font = Enum.Font.BuilderSans,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    local function makeTransportBtn(pos, size, glyph, textSize, withBox)
        local b = make("TextButton", Body, {
            Position = pos,
            Size = size,
            BackgroundColor3 = CLR.BG_SURFACE,
            BackgroundTransparency = withBox and 0 or 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = glyph,
            TextColor3 = CLR.TEXT_SECONDARY,
            Font = Enum.Font.BuilderSansBold,
            TextSize = textSize or 11,
        })
        if withBox then
            make("UICorner", b, { CornerRadius = UDim.new(0, 6) })
            make("UIStroke", b, {
                Thickness = 1,
                Color = CLR.BORDER_LINE,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
        end
        connect(b.MouseEnter, function()
            tween(b, 0.1, { TextColor3 = CLR.TEXT_PRIMARY })
            if withBox then tween(b, 0.1, { BackgroundColor3 = CLR.BG_ELEVATED }) end
        end)
        connect(b.MouseLeave, function()
            if not b:GetAttribute("Active") then
                tween(b, 0.1, { TextColor3 = CLR.TEXT_SECONDARY })
            end
            if withBox then tween(b, 0.1, { BackgroundColor3 = CLR.BG_SURFACE }) end
        end)
        return b
    end

    UI.ShuffleBtn = makeTransportBtn(UDim2.fromOffset(114, 77), UDim2.fromOffset(22, 22), "\u{21C4}", 13, false)
    UI.PrevBtn = makeTransportBtn(UDim2.fromOffset(142, 77), UDim2.fromOffset(22, 22), "<", 11, true)

    local function createCirclePlayButton(parent, pos, diameter, barW, barH, barGap)
        local btn = make("TextButton", parent, {
            Position = pos,
            Size = UDim2.fromOffset(diameter, diameter),
            BackgroundColor3 = getAccent(),
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
        })
        make("UICorner", btn, { CornerRadius = UDim.new(1, 0) })

        local playGlyph = make("TextLabel", btn, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 1, 0.5, 0),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "\u{25B6}",
            TextColor3 = getAccentText(),
            Font = Enum.Font.BuilderSansBold,
            TextSize = math.floor(diameter * 0.38),
            Visible = true,
        })

        local pauseWrap = make("Frame", btn, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(barW * 2 + barGap, barH),
            BackgroundTransparency = 1,
            Visible = false,
        })
        local barLeft = make("Frame", pauseWrap, {
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(barW, barH),
            BackgroundColor3 = getAccentText(),
            BorderSizePixel = 0,
        })
        make("UICorner", barLeft, { CornerRadius = UDim.new(0, 1) })

        local barRight = make("Frame", pauseWrap, {
            Position = UDim2.fromOffset(barW + barGap, 0),
            Size = UDim2.fromOffset(barW, barH),
            BackgroundColor3 = getAccentText(),
            BorderSizePixel = 0,
        })
        make("UICorner", barRight, { CornerRadius = UDim.new(0, 1) })

        local function setPlayingVisual(isPlaying)
            playGlyph.Visible = not isPlaying
            pauseWrap.Visible = isPlaying
        end

        local function setColors(bgCol, fgCol)
            btn.BackgroundColor3 = bgCol
            playGlyph.TextColor3 = fgCol
            barLeft.BackgroundColor3 = fgCol
            barRight.BackgroundColor3 = fgCol
        end

        return btn, setPlayingVisual, setColors
    end

    UI.PlayCircle, UI.setMainPlayVisual, UI.setMainPlayColors = createCirclePlayButton(
        Body,
        UDim2.fromOffset(169, 73),
        30,
        2,
        10,
        3
    )
    local PlayScale = make("UIScale", UI.PlayCircle, { Scale = 1 })
    connect(UI.PlayCircle.MouseEnter, function() tween(PlayScale, 0.12, { Scale = 1.07 }) end)
    connect(UI.PlayCircle.MouseLeave, function() tween(PlayScale, 0.12, { Scale = 1 }) end)

    UI.NextBtn = makeTransportBtn(UDim2.fromOffset(204, 77), UDim2.fromOffset(22, 22), ">", 11, true)
    UI.LoopBtn = makeTransportBtn(UDim2.fromOffset(230, 77), UDim2.fromOffset(24, 22), "REP", 8, false)
    syncModeButtons()

    local SpeakerHolder = make("Frame", Body, {
        Position = UDim2.fromOffset(260, 81),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
    })
    local SpkBox = make("Frame", SpeakerHolder, {
        Position = UDim2.fromOffset(1, 4),
        Size = UDim2.fromOffset(4, 6),
        BackgroundColor3 = Color3.fromRGB(175, 180, 192),
        BorderSizePixel = 0,
    })
    make("UICorner", SpkBox, { CornerRadius = UDim.new(0, 1) })
    local SpkCone = make("Frame", SpeakerHolder, {
        Position = UDim2.fromOffset(4, 2),
        Size = UDim2.fromOffset(4, 10),
        BackgroundColor3 = Color3.fromRGB(175, 180, 192),
        BorderSizePixel = 0,
    })
    make("UICorner", SpkCone, { CornerRadius = UDim.new(0, 2) })
    local SpkWave1 = make("Frame", SpeakerHolder, {
        Position = UDim2.fromOffset(10, 4),
        Size = UDim2.fromOffset(2, 6),
        BackgroundColor3 = Color3.fromRGB(140, 145, 160),
        BorderSizePixel = 0,
    })
    make("UICorner", SpkWave1, { CornerRadius = UDim.new(1, 0) })
    local SpkWave2 = make("Frame", SpeakerHolder, {
        Position = UDim2.fromOffset(13, 2),
        Size = UDim2.fromOffset(2, 10),
        BackgroundColor3 = Color3.fromRGB(115, 120, 135),
        BorderSizePixel = 0,
    })
    make("UICorner", SpkWave2, { CornerRadius = UDim.new(1, 0) })

    UI.updateSpeakerVisual = function(vol)
        local activeCol = vol == 0 and CLR.STATUS_ERR or Color3.fromRGB(175, 180, 192)
        SpkBox.BackgroundColor3 = activeCol
        SpkCone.BackgroundColor3 = activeCol
        SpkWave1.Visible = vol > 0.05
        SpkWave2.Visible = vol > 0.65
    end
    UI.updateSpeakerVisual(Opts.volume)

    UI.VolHit = make("TextButton", Body, {
        Position = UDim2.fromOffset(278, 81),
        Size = UDim2.fromOffset(56, 14),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    })
    UI.VolTrack = make("Frame", UI.VolHit, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = CLR.BG_ELEVATED,
        BorderSizePixel = 0,
    })
    make("UICorner", UI.VolTrack, { CornerRadius = UDim.new(1, 0) })
    UI.VolFill = make("Frame", UI.VolTrack, {
        Size = UDim2.fromScale(math.clamp(Opts.volume / 2, 0, 1), 1),
        BackgroundColor3 = getAccent(),
        BorderSizePixel = 0,
    })
    make("UICorner", UI.VolFill, { CornerRadius = UDim.new(1, 0) })

    UI.VolPct = make("TextLabel", Body, {
        Position = UDim2.fromOffset(336, 77),
        Size = UDim2.fromOffset(28, 22),
        BackgroundTransparency = 1,
        Text = math.floor(Opts.volume * 50 + 0.5) .. "%",
        TextColor3 = CLR.TEXT_MUTED,
        Font = Enum.Font.BuilderSans,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    UI.MiniPill = make("Frame", UI.Root, {
        Name = "MiniPill",
        Size = UDim2.fromOffset(278, 38),
        BackgroundColor3 = CLR.BG_WINDOW,
        BorderSizePixel = 0,
        Visible = false,
    })
    make("UICorner", UI.MiniPill, { CornerRadius = UDim.new(1, 0) })
    make("UIStroke", UI.MiniPill, {
        Thickness = 1,
        Color = CLR.BORDER_LINE,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    UI.MiniArt = make("ImageLabel", UI.MiniPill, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 5, 0.5, 0),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = CLR.BG_SURFACE,
        BorderSizePixel = 0,
        Image = RT.lastSong and coverOf(RT.lastSong) or RT.defaultCover,
        ScaleType = Enum.ScaleType.Crop,
    })
    make("UICorner", UI.MiniArt, { CornerRadius = UDim.new(1, 0) })

    UI.MiniTitle = make("TextLabel", UI.MiniPill, {
        Position = UDim2.fromOffset(40, 0),
        Size = UDim2.fromOffset(126, 38),
        BackgroundTransparency = 1,
        Text = "xzyp",
        TextColor3 = CLR.TEXT_PRIMARY,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local function makeMiniCtrl(xOff, txt)
        local b = make("TextButton", UI.MiniPill, {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, xOff, 0.5, 0),
            Size = UDim2.fromOffset(22, 22),
            BackgroundColor3 = CLR.BG_SURFACE,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = txt,
            TextColor3 = CLR.TEXT_PRIMARY,
            Font = Enum.Font.BuilderSansBold,
            TextSize = 10,
        })
        make("UICorner", b, { CornerRadius = UDim.new(1, 0) })
        make("UIStroke", b, {
            Thickness = 1,
            Color = CLR.BORDER_LINE,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
        return b
    end

    UI.MiniPrev = makeMiniCtrl(170, "<")
    UI.MiniPlay, UI.setMiniPlayVisual, UI.setMiniPlayColors = createCirclePlayButton(
        UI.MiniPill,
        UDim2.new(0, 195, 0.5, -11),
        22,
        2,
        8,
        2
    )
    UI.MiniNext = makeMiniCtrl(220, ">")
    UI.MiniExpand = makeMiniCtrl(246, "+")

    UI.ImportPanel = make("Frame", UI.Root, {
        Name = "ImportPanel",
        Position = UDim2.fromOffset(0, CFG.FULL_H + 6),
        Size = UDim2.fromOffset(CFG.PLAYER_W, CFG.IMPORT_COMPACT_H),
        BackgroundColor3 = CLR.BG_WINDOW,
        BorderSizePixel = 0,
        Visible = false,
    })
    make("UICorner", UI.ImportPanel, { CornerRadius = UDim.new(0, 9) })
    make("UIStroke", UI.ImportPanel, {
        Thickness = 1,
        Color = CLR.BORDER_LINE,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    UI.LinkInput = make("TextBox", UI.ImportPanel, {
        Position = UDim2.fromOffset(10, 8),
        Size = UDim2.fromOffset(282, 22),
        BackgroundColor3 = CLR.BG_SURFACE,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "Search song, or paste YT / Spotify link...",
        PlaceholderColor3 = CLR.TEXT_MUTED,
        TextColor3 = CLR.TEXT_PRIMARY,
        Font = Enum.Font.BuilderSans,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
    })
    make("UICorner", UI.LinkInput, { CornerRadius = UDim.new(0, 6) })
    make("UIStroke", UI.LinkInput, {
        Thickness = 1,
        Color = CLR.BORDER_LINE,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    make("UIPadding", UI.LinkInput, { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })

    UI.DownloadBtn = make("TextButton", UI.ImportPanel, {
        Position = UDim2.fromOffset(298, 8),
        Size = UDim2.fromOffset(68, 22),
        BackgroundColor3 = getAccent(),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "SEARCH",
        TextColor3 = getAccentText(),
        Font = Enum.Font.BuilderSansBold,
        TextSize = 9,
    })
    make("UICorner", UI.DownloadBtn, { CornerRadius = UDim.new(0, 6) })

    UI.ImportStatus = make("TextLabel", UI.ImportPanel, {
        Position = UDim2.fromOffset(12, 34),
        Size = UDim2.fromOffset(352, 18),
        BackgroundTransparency = 1,
        Text = "Type a song name to search, or paste a link",
        TextColor3 = CLR.TEXT_SECONDARY,
        Font = Enum.Font.BuilderSans,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    UI.SearchResultsScroll = make("ScrollingFrame", UI.ImportPanel, {
        Position = UDim2.fromOffset(10, 56),
        Size = UDim2.fromOffset(356, 182),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = CLR.TEXT_MUTED,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    })
    make("UIListLayout", UI.SearchResultsScroll, {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    UI.DrawerPanel = make("Frame", UI.Root, {
        Name = "DrawerPanel",
        Position = UDim2.fromOffset(0, CFG.FULL_H + 6),
        Size = UDim2.fromOffset(CFG.PLAYER_W, 240),
        BackgroundColor3 = CLR.BG_WINDOW,
        BorderSizePixel = 0,
        Visible = false,
    })
    make("UICorner", UI.DrawerPanel, { CornerRadius = UDim.new(0, 9) })
    make("UIStroke", UI.DrawerPanel, {
        Thickness = 1,
        Color = CLR.BORDER_LINE,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    UI.SearchBox = make("TextBox", UI.DrawerPanel, {
        Position = UDim2.fromOffset(10, 8),
        Size = UDim2.fromOffset(182, 22),
        BackgroundColor3 = CLR.BG_SURFACE,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "> Filter queue...",
        PlaceholderColor3 = CLR.TEXT_MUTED,
        TextColor3 = CLR.TEXT_PRIMARY,
        Font = Enum.Font.BuilderSans,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    })
    make("UICorner", UI.SearchBox, { CornerRadius = UDim.new(0, 6) })
    make("UIStroke", UI.SearchBox, {
        Thickness = 1,
        Color = CLR.BORDER_LINE,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    make("UIPadding", UI.SearchBox, { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })

    local function makeFilterChip(xOff, w, label, filterKey)
        local b = make("TextButton", UI.DrawerPanel, {
            Position = UDim2.fromOffset(xOff, 8),
            Size = UDim2.fromOffset(w, 22),
            BackgroundColor3 = (RT.activeFilter == filterKey) and getAccent() or CLR.BG_SURFACE,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = label,
            TextColor3 = (RT.activeFilter == filterKey) and getAccentText() or CLR.TEXT_SECONDARY,
            Font = Enum.Font.BuilderSansBold,
            TextSize = 8,
        })
        make("UICorner", b, { CornerRadius = UDim.new(0, 5) })
        RT.filterButtons[filterKey] = b
        return b
    end

    makeFilterChip(196, 30, "ALL", "ALL")
    makeFilterChip(229, 50, "Youtube", "Youtube")
    makeFilterChip(282, 40, "LOCAL", "LOCAL")

    UI.CountBadge = make("TextLabel", UI.DrawerPanel, {
        Position = UDim2.fromOffset(325, 8),
        Size = UDim2.fromOffset(41, 22),
        BackgroundColor3 = CLR.BG_SURFACE,
        BorderSizePixel = 0,
        Text = tostring(#RT.songs),
        TextColor3 = CLR.TEXT_SECONDARY,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 9,
    })
    make("UICorner", UI.CountBadge, { CornerRadius = UDim.new(0, 5) })

    UI.QueueScroll = make("ScrollingFrame", UI.DrawerPanel, {
        Position = UDim2.fromOffset(10, 36),
        Size = UDim2.fromOffset(356, 194),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = CLR.TEXT_MUTED,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    make("UIListLayout", UI.QueueScroll, {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    UI.SettingsPanel = make("Frame", UI.Root, {
        Name = "SettingsPanel",
        Position = UDim2.fromOffset(0, CFG.FULL_H + 6),
        Size = UDim2.fromOffset(CFG.PLAYER_W, 196),
        BackgroundColor3 = CLR.BG_WINDOW,
        BorderSizePixel = 0,
        Visible = false,
    })
    make("UICorner", UI.SettingsPanel, { CornerRadius = UDim.new(0, 9) })
    make("UIStroke", UI.SettingsPanel, {
        Thickness = 1,
        Color = CLR.BORDER_LINE,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

    UI.SettingsScroll = make("ScrollingFrame", UI.SettingsPanel, {
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.fromOffset(356, 176),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = CLR.TEXT_MUTED,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    make("UIListLayout", UI.SettingsScroll, {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
end

for _, s in ipairs(RT.songs) do
    addPlaylistRow(s)
end

do
    connect(UI.AddBtn.Activated, function()
        UI.ImportPanel.Visible = not UI.ImportPanel.Visible
        layoutSubPanels()
    end)

    connect(UI.QueueBtn.Activated, function()
        UI.DrawerPanel.Visible = not UI.DrawerPanel.Visible
        if UI.DrawerPanel.Visible then UI.SettingsPanel.Visible = false end
        layoutSubPanels()
    end)

    connect(UI.CfgBtn.Activated, function()
        UI.SettingsPanel.Visible = not UI.SettingsPanel.Visible
        if UI.SettingsPanel.Visible then UI.DrawerPanel.Visible = false end
        layoutSubPanels()
    end)

    local function setMinimized(state)
        UI.MainCard.Visible = not state
        UI.MiniPill.Visible = state
        if state then
            UI.ImportPanel.Visible = false
            UI.DrawerPanel.Visible = false
            UI.SettingsPanel.Visible = false
        end
    end

    connect(UI.MiniBtn.Activated, function() setMinimized(true) end)
    connect(UI.MiniExpand.Activated, function() setMinimized(false) end)

    local function makeDraggable(handle)
        local dragging, dragStart, startPos
        connect(handle.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = UI.Root.Position
            end
        end)
        connect(SRV.UIS.InputChanged, function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local d = input.Position - dragStart
                UI.Root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                layoutSubPanels()
            end
        end)
        connect(SRV.UIS.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    makeDraggable(UI.TopBar)
    makeDraggable(UI.MiniPill)

    for key, btn in pairs(RT.filterButtons) do
        connect(btn.Activated, function()
            RT.activeFilter = key
            syncFilterChips()
            refreshQueueVisuals()
        end)
    end

    connect(UI.SearchBox:GetPropertyChangedSignal("Text"), refreshQueueVisuals)

    connect(UI.PrevBtn.Activated, function() step(-1) end)
    connect(UI.PlayCircle.Activated, togglePlay)
    connect(UI.NextBtn.Activated, function() step(1) end)
    connect(UI.MiniPrev.Activated, function() step(-1) end)
    connect(UI.MiniPlay.Activated, togglePlay)
    connect(UI.MiniNext.Activated, function() step(1) end)

    connect(UI.ShuffleBtn.Activated, function()
        Opts.shuffle = not Opts.shuffle
        State.shuffle = Opts.shuffle
        syncModeButtons()
        saveState()
    end)

    connect(UI.LoopBtn.Activated, function()
        Opts.loopOne = not Opts.loopOne
        State.loopOne = Opts.loopOne
        syncModeButtons()
        saveState()
    end)

    connect(Sound.Ended, function()
        if RT.playing and os.clock() - RT.startedAt > 0.5 then
            step(1)
        end
    end)

    local function seekFracAt(x)
        return math.clamp((x - UI.SeekTrack.AbsolutePosition.X) / math.max(UI.SeekTrack.AbsoluteSize.X, 1), 0, 1)
    end

    connect(UI.SeekHit.MouseEnter, function()
        RT.seekHovering = true
        UI.SeekKnob.Visible = true
        UI.HoverTimeTip.Visible = true
        tween(UI.SeekTrack, 0.1, { Size = UDim2.new(1, 0, 0, 5) })
    end)
    connect(UI.SeekHit.MouseLeave, function()
        RT.seekHovering = false
        UI.SeekKnob.Visible = false
        UI.HoverTimeTip.Visible = false
        tween(UI.SeekTrack, 0.1, { Size = UDim2.new(1, 0, 0, 3) })
    end)
    connect(UI.SeekHit.InputBegan, function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and RT.cur then
            RT.seeking = true
            RT.seekFrac = seekFracAt(input.Position.X)
        end
    end)
    connect(SRV.UIS.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if RT.seeking then
                RT.seekFrac = seekFracAt(input.Position.X)
            end
            if RT.seekHovering or RT.seeking then
                local f = seekFracAt(input.Position.X)
                local len = RT.cur and Sound.TimeLength or 0
                UI.HoverTimeTip.Text = fmtTime(f * len)
                UI.HoverTimeTip.Position = UDim2.fromOffset(112 + f * 250, 46)
            end
        end
    end)
    connect(SRV.UIS.InputEnded, function(input)
        if RT.seeking and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            RT.seeking = false
            local len = Sound.TimeLength
            if RT.cur and len > 0 then
                local t = math.min(RT.seekFrac * len, math.max(0, len - 0.05))
                if RT.playing then
                    Sound.TimePosition = t
                else
                    RT.pausedAt = t
                end
            end
        end
    end)

    local function setVolumeFromX(x)
        local frac = math.clamp((x - UI.VolTrack.AbsolutePosition.X) / math.max(UI.VolTrack.AbsoluteSize.X, 1), 0, 1)
        UI.VolFill.Size = UDim2.fromScale(frac, 1)
        Opts.volume = math.floor(frac * 200 + 0.5) / 100
        Sound.Volume = Opts.volume
        UI.VolPct.Text = math.floor(frac * 100 + 0.5) .. "%"
        UI.updateSpeakerVisual(Opts.volume)
        State.volume = Opts.volume
        saveState()
    end

    connect(UI.VolHit.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            RT.volDragging = true
            setVolumeFromX(input.Position.X)
        end
    end)
    connect(SRV.UIS.InputChanged, function(input)
        if RT.volDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setVolumeFromX(input.Position.X)
        end
    end)
    connect(SRV.UIS.InputEnded, function(input)
        if RT.volDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            RT.volDragging = false
        end
    end)

    local eqSmooth = table.create(CFG.EQ_COUNT, 0)
    connect(SRV.RS.RenderStepped, function(dt)
        local len = RT.cur and Sound.TimeLength or 0
        local pos = RT.seeking and (RT.seekFrac * len) or (RT.cur and (RT.playing and Sound.TimePosition or RT.pausedAt) or 0)
        local ratio = len > 0 and math.clamp(pos / len, 0, 1) or 0
        UI.SeekFill.Size = UDim2.fromScale(ratio, 1)
        UI.SeekKnob.Position = UDim2.fromScale(ratio, 0.5)
        UI.TimeNow.Text = fmtTime(pos)
        UI.TimeEnd.Text = fmtTime(len)

        if RT.titleOverflow > 0 then
            local elapsed = os.clock() - RT.titleSetTime
            if elapsed > 1.5 then
                local cycle = (elapsed - 1.5) * 26
                local span = RT.titleOverflow + 24
                local phase = cycle % (span * 2)
                local offset = phase <= span and math.min(RT.titleOverflow, phase) or math.max(0, span * 2 - phase)
                UI.TrackTitle.Position = UDim2.fromOffset(-offset, 0)
            end
        end

        local t = os.clock()
        local loud = RT.playing and math.clamp(Sound.PlaybackLoudness / 300, 0, 1) or 0
        local acc = getAccent()
        for i = 1, CFG.EQ_COUNT do
            local wave = RT.playing and (0.4 + 0.6 * math.abs(math.sin(t * (5.5 + i * 0.7) + i * 1.1))) or 0
            local target = loud * wave
            eqSmooth[i] += (target - eqSmooth[i]) * math.min(1, dt * 16)
            local h = math.max(2, math.floor(2 + eqSmooth[i] * 22))
            RT.eqBars[i].Size = UDim2.fromOffset(3, h)
            if Opts.rainbow then
                RT.eqBars[i].BackgroundColor3 = Color3.fromHSV((t * 0.2 + i / CFG.EQ_COUNT) % 1, 0.75, 1)
            else
                RT.eqBars[i].BackgroundColor3 = acc
            end
        end
    end)
end

local function detectAudioFormat(buf)
    if type(buf) ~= "string" or #buf < 4096 then return nil end
    local head4 = buf:sub(1, 4)
    if head4 == "OggS" then return "ogg" end
    if head4 == "RIFF" and buf:sub(9, 12) == "WAVE" then return "wav" end
    if buf:sub(1, 3) == "ID3" then return "mp3" end
    local b1, b2 = buf:byte(1), buf:byte(2)
    if b1 == 0xFF and (b2 == 0xFB or b2 == 0xF3 or b2 == 0xF2 or b2 == 0xE3 or b2 == 0xE2) then
        return "mp3"
    end
    return nil
end

local function cleanFileName(str)
    if not str or #str == 0 then return nil end
    str = str:gsub("&amp;", "&"):gsub("&quot;", '"'):gsub("&#39;", "'"):gsub("&lt;", "<"):gsub("&gt;", ">")
    str = str:gsub('[\\/:%*%?"<>|%c]', "")
    str = str:gsub("^%s+", ""):gsub("%s+$", "")
    if #str > 64 then
        str = str:sub(1, 64):gsub("%s+$", "")
    end
    return #str > 0 and str or nil
end

local function extractSpotifyTrackId(raw)
    if not raw then return nil end
    return raw:match("open%.spotify%.com/[^%s]*/?track/([%w]+)")
        or raw:match("open%.spotify%.com/track/([%w]+)")
        or raw:match("spotify:track:([%w]+)")
end

local function extractVideoId(raw)
    if not raw then return nil end
    raw = raw:gsub("^%s+", ""):gsub("%s+$", "")
    local urlMatch = raw:match("[?&]v=([%w_%-]+)")
        or raw:match("youtu%.be/([%w_%-]+)")
        or raw:match("shorts/([%w_%-]+)")
        or raw:match("embed/([%w_%-]+)")
    if urlMatch and #urlMatch == 11 then
        return urlMatch
    end
    if #raw == 11 and raw:match("^[%w_%-]+$") then
        if raw:find("[A-Z0-9_%-]") ~= nil then
            return raw
        end
    end
    return nil
end

local function safeGet(url, extraHeaders)
    local headers = {
        ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        ["Accept"] = "*/*",
    }
    if extraHeaders then
        for k, v in pairs(extraHeaders) do
            headers[k] = v
        end
    end
    local ok, res = pcall(function()
        return httpRequest({
            Url = url,
            Method = "GET",
            Headers = headers,
        })
    end)
    return ok and res or nil
end

local function safePostJson(url, bodyTbl, extraHeaders)
    local headers = {
        ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        ["Accept"] = "application/json",
        ["Content-Type"] = "application/json",
    }
    if extraHeaders then
        for k, v in pairs(extraHeaders) do
            headers[k] = v
        end
    end
    local ok, res = pcall(function()
        return httpRequest({
            Url = url,
            Method = "POST",
            Headers = headers,
            Body = SRV.Http:JSONEncode(bodyTbl),
        })
    end)
    return ok and res or nil
end

local function saveImageFromUrl(imgUrl, fileBase)
    if type(imgUrl) ~= "string" or not imgUrl:match("^https?://") then return nil end
    local res = safeGet(imgUrl)
    if res and res.Body and #res.Body > 1024 then
        local b1, b2 = res.Body:byte(1), res.Body:byte(2)
        local isJpg = (b1 == 0xFF and b2 == 0xD8)
        local isPng = (res.Body:sub(2, 4) == "PNG")
        if isJpg or isPng then
            local ext = isPng and ".png" or ".jpg"
            local outPath = PATHS.COVERS .. "/" .. fileBase .. ext
            writefile(outPath, res.Body)
            return outPath
        end
    end
    return nil
end

local function downloadYoutubeThumbnail(cleanId, fileBase)
    local candidates = {
        "https://i.ytimg.com/vi/" .. cleanId .. "/maxresdefault.jpg",
        "https://i.ytimg.com/vi/" .. cleanId .. "/hqdefault.jpg",
        "https://i.ytimg.com/vi/" .. cleanId .. "/mqdefault.jpg",
    }
    for _, url in ipairs(candidates) do
        local p = saveImageFromUrl(url, fileBase)
        if p then return p end
    end
    return nil
end

local function fetchSpotifyTrackById(trackId)
    local trackUrl = "https://open.spotify.com/track/" .. trackId
    local oembed = safeGet("https://open.spotify.com/oembed?url=" .. SRV.Http:UrlEncode(trackUrl), { ["Accept"] = "application/json" })
    if not (oembed and oembed.Body) then return nil end

    local ok, data = pcall(function() return SRV.Http:JSONDecode(oembed.Body) end)
    if not (ok and type(data) == "table" and data.title) then return nil end

    local title = cleanFileName(data.title)
    local thumb = data.thumbnail_url
    local artist = nil

    local emb = safeGet("https://open.spotify.com/embed/track/" .. trackId)
    if emb and emb.Body then
        local aName = emb.Body:match('"artists"%s*:%s*%[%s*{[^}]-"name"%s*:%s*"([^"]+)"')
            or emb.Body:match('"subtitle"%s*:%s*"([^"]+)"')
        if aName and #aName > 0 and #aName < 60 then
            artist = cleanFileName(aName)
        end
    end

    return {
        title = title,
        creator = artist or "Spotify Artist",
        searchQuery = (artist and (artist .. " - " .. title) or title) .. " official audio",
        coverUrl = thumb,
    }
end

local function tryMatchOnSpotify(ytTitle)
    if not ytTitle or #ytTitle < 2 then return nil end
    local cleanQuery = ytTitle
        :gsub("%b()", "")
        :gsub("%b[]", "")
        :gsub("[Oo]fficial%s*[Vv]ideo", "")
        :gsub("[Cc]lipe%s*[Oo]ficial", "")
        :gsub("[Aa]udio%s*[Oo]ficial", "")
        :gsub("%s+", " ")
        :gsub("^%s+", "")
        :gsub("%s+$", "")

    if #cleanQuery < 3 then return nil end

    local tokRes = safeGet("https://open.spotify.com/get_access_token?reason=transport&productType=web_player", { ["Accept"] = "application/json" })
    if not (tokRes and tokRes.Body) then return nil end

    local okT, tokData = pcall(function() return SRV.Http:JSONDecode(tokRes.Body) end)
    local token = okT and type(tokData) == "table" and tokData.accessToken
    if type(token) ~= "string" or #token < 10 then return nil end

    local searchUrl = "https://api.spotify.com/v1/search?type=track&limit=3&q=" .. SRV.Http:UrlEncode(cleanQuery)
    local sRes = safeGet(searchUrl, {
        ["Authorization"] = "Bearer " .. token,
        ["Accept"] = "application/json",
    })
    if not (sRes and sRes.Body) then return nil end

    local okS, sData = pcall(function() return SRV.Http:JSONDecode(sRes.Body) end)
    local items = okS and sData and sData.tracks and sData.tracks.items
    if type(items) ~= "table" or #items == 0 then return nil end

    local normQuery = cleanQuery:lower():gsub("[^%w%s]", "")
    for _, item in ipairs(items) do
        if type(item) == "table" and item.name then
            local spName = tostring(item.name):lower():gsub("[^%w%s]", "")
            if #spName >= 3 and (normQuery:find(spName, 1, true) or spName:find(normQuery, 1, true)) then
                local images = item.album and item.album.images
                local bestImg = (type(images) == "table" and images[1] and images[1].url) or nil
                local artistName = (item.artists and item.artists[1] and item.artists[1].name) or nil
                return {
                    title = cleanFileName(item.name),
                    creator = artistName and cleanFileName(artistName) or nil,
                    coverUrl = bestImg,
                }
            end
        end
    end
    return nil
end

local function extractJsonObject(str, startPos)
    local openIdx = str:find("{", startPos, true)
    if not openIdx then return nil end
    local depth = 0
    local inStr = false
    local esc = false
    for i = openIdx, #str do
        local c = str:sub(i, i)
        if inStr then
            if esc then
                esc = false
            elseif c == "\\" then
                esc = true
            elseif c == '"' then
                inStr = false
            end
        else
            if c == '"' then
                inStr = true
            elseif c == "{" then
                depth += 1
            elseif c == "}" then
                depth -= 1
                if depth == 0 then
                    return str:sub(openIdx, i)
                end
            end
        end
    end
    return nil
end

local function collectVideoRenderers(node, outList, seenIds)
    if type(node) ~= "table" or #outList >= 8 then return end
    local vr = node.videoRenderer
    if type(vr) == "table" and type(vr.videoId) == "string" and #vr.videoId == 11 and not seenIds[vr.videoId] then
        local titleRuns = vr.title and vr.title.runs
        local titleStr = (type(titleRuns) == "table" and titleRuns[1] and titleRuns[1].text) or nil
        if titleStr then
            local ownerRuns = (vr.ownerText and vr.ownerText.runs) or (vr.longBylineText and vr.longBylineText.runs)
            local creatorStr = (type(ownerRuns) == "table" and ownerRuns[1] and ownerRuns[1].text) or "YouTube Creator"
            local durStr = (vr.lengthText and vr.lengthText.simpleText) or ""
            seenIds[vr.videoId] = true
            outList[#outList + 1] = {
                id = vr.videoId,
                title = cleanFileName(titleStr) or titleStr,
                creator = cleanFileName(creatorStr) or creatorStr,
                duration = durStr,
            }
        end
    end
    for _, v in pairs(node) do
        if type(v) == "table" then
            collectVideoRenderers(v, outList, seenIds)
            if #outList >= 8 then return end
        end
    end
end

local function searchYoutubeTracks(query)
    local encoded = SRV.Http:UrlEncode(query)
    local results = {}
    local seen = {}

    local ytApiRes = safePostJson("https://www.youtube.com/youtubei/v1/search?prettyPrint=false", {
        context = {
            client = {
                clientName = "WEB",
                clientVersion = "2.20260101.00.00",
                hl = "en",
                gl = "US",
            },
        },
        query = query,
    }, {
        ["Origin"] = "https://www.youtube.com",
        ["Referer"] = "https://www.youtube.com/",
    })
    if ytApiRes and ytApiRes.Body then
        local okJ, parsed = pcall(function() return SRV.Http:JSONDecode(ytApiRes.Body) end)
        if okJ and type(parsed) == "table" then
            collectVideoRenderers(parsed, results, seen)
        end
    end

    if #results == 0 then
        local ytHtml = safeGet("https://www.youtube.com/results?search_query=" .. encoded)
        if ytHtml and ytHtml.Body then
            local scanPos = 1
            while #results < 8 do
                local vrMarker = ytHtml.Body:find('"videoRenderer"', scanPos, true)
                if not vrMarker then break end
                local block = extractJsonObject(ytHtml.Body, vrMarker)
                if block then
                    local okB, vrObj = pcall(function() return SRV.Http:JSONDecode(block) end)
                    if okB and type(vrObj) == "table" then
                        collectVideoRenderers({ videoRenderer = vrObj }, results, seen)
                    end
                    scanPos = vrMarker + #block
                else
                    scanPos = vrMarker + 15
                end
            end
        end
    end

    if #results == 0 then
        local searchApis = {
            "https://pipedapi.kavin.rocks/search?q=" .. encoded .. "&filter=videos",
            "https://api.piped.private.coffee/search?q=" .. encoded .. "&filter=videos",
            "https://inv.nadeko.net/api/v1/search?q=" .. encoded .. "&type=video",
            "https://yewtu.be/api/v1/search?q=" .. encoded .. "&type=video",
        }
        for _, ep in ipairs(searchApis) do
            if #results > 0 then break end
            local res = safeGet(ep, { ["Accept"] = "application/json" })
            if res and res.Body then
                local ok, data = pcall(function() return SRV.Http:JSONDecode(res.Body) end)
                if ok and type(data) == "table" then
                    local list = data.items or data
                    if type(list) == "table" then
                        for _, item in ipairs(list) do
                            if type(item) == "table" then
                                local id = item.videoId or (item.url and item.url:match("v=([%w_%-]+)"))
                                local title = item.title
                                if id and #id == 11 and title and not seen[id] then
                                    seen[id] = true
                                    local dur = ""
                                    local sec = tonumber(item.duration or item.lengthSeconds)
                                    if sec and sec > 0 then
                                        dur = fmtTime(sec)
                                    end
                                    results[#results + 1] = {
                                        id = id,
                                        title = cleanFileName(title) or title,
                                        creator = cleanFileName(item.uploaderName or item.author or "YouTube Creator") or "YouTube Creator",
                                        duration = dur,
                                    }
                                    if #results >= 8 then break end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return results
end

local function fetchAndVerifyAudio(downloadUrl, referer)
    if type(downloadUrl) ~= "string" or not downloadUrl:match("^https?://") then
        return nil, nil
    end
    local res = safeGet(downloadUrl, referer and { ["Referer"] = referer } or nil)
    if res and res.Body then
        local fmt = detectAudioFormat(res.Body)
        if fmt then
            return res.Body, fmt
        end
    end
    return nil, nil
end

local function downloadYoutubeById(cleanId, presetTitle, presetCreator, spotifyMeta, fromSpotifyLink)
    if RT.downloading then return end

    for _, s in ipairs(RT.songs) do
        if s.ytId == cleanId or s.path:find(cleanId, 1, true) then
            setSearchResultsExpanded(false)
            UI.ImportStatus.Text = "Already in queue! Playing..."
            UI.ImportStatus.TextColor3 = CLR.STATUS_OK
            UI.DownloadBtn.Text = "SEARCH"
            playSong(s)
            return
        end
    end

    RT.downloading = true
    UI.DownloadBtn.Text = "..."
    setSearchResultsExpanded(false)

    local resolvedTitle = presetTitle
    local resolvedCreator = presetCreator

    local watchUrl = "https://www.youtube.com/watch?v=" .. cleanId
    if not resolvedTitle or not resolvedCreator then
        local metaRes = safeGet("https://www.youtube.com/oembed?url=" .. SRV.Http:UrlEncode(watchUrl) .. "&format=json")
        if metaRes and metaRes.Body then
            local okM, meta = pcall(function() return SRV.Http:JSONDecode(metaRes.Body) end)
            if okM and type(meta) == "table" then
                if not resolvedTitle and meta.title then
                    resolvedTitle = cleanFileName(meta.title)
                end
                if not resolvedCreator and meta.author_name then
                    resolvedCreator = cleanFileName(meta.author_name)
                end
            end
        end
    end

    if not fromSpotifyLink and not spotifyMeta and resolvedTitle then
        UI.ImportStatus.Text = "Checking track metadata..."
        UI.ImportStatus.TextColor3 = CLR.TEXT_PRIMARY
        spotifyMeta = tryMatchOnSpotify(resolvedTitle)
        if spotifyMeta then
            if spotifyMeta.title then resolvedTitle = spotifyMeta.title end
            if spotifyMeta.creator then resolvedCreator = spotifyMeta.creator end
        end
    end

    local encodedWatch = SRV.Http:UrlEncode(watchUrl)
    local audioPayload, audioExt = nil, nil

    local keyParam = (Opts.apiKey ~= "") and ("&apikey=" .. SRV.Http:UrlEncode(Opts.apiKey)) or ""
    local transcoders = {
        {
            name = "savenow.to",
            init = "https://p.savenow.to/ajax/download.php?format=mp3&audio_quality=128&url=" .. encodedWatch .. keyParam,
            prog = "https://p.savenow.to/ajax/progress.php?id=",
            ref = "https://p.savenow.to/",
        },
        {
            name = "oceansaver.in",
            init = "https://p.oceansaver.in/ajax/download.php?copyright=0&format=mp3&url=" .. encodedWatch .. keyParam,
            prog = "https://p.oceansaver.in/ajax/progress.php?id=",
            ref = "https://loader.to/",
        },
        {
            name = "loader.to",
            init = "https://loader.to/ajax/download.php?button=1&start=1&end=1&format=mp3&url=" .. encodedWatch .. keyParam,
            prog = "https://loader.to/ajax/progress.php?id=",
            ref = "https://loader.to/",
        },
    }

    for idx, tc in ipairs(transcoders) do
        if audioPayload then break end
        UI.ImportStatus.Text = string.format("Downloading from Youtube (%s %d/%d)...", tc.name, idx, #transcoders)
        log("YT_TRANSCODE", "Starting job on:", tc.name)

        local initRes = safeGet(tc.init, { ["Referer"] = tc.ref, ["Accept"] = "application/json, */*" })
        if initRes and initRes.Body then
            local okJ, initData = pcall(function() return SRV.Http:JSONDecode(initRes.Body) end)
            if okJ and type(initData) == "table" and initData.id then
                if not resolvedTitle and initData.title then
                    resolvedTitle = cleanFileName(initData.title)
                end
                local pollUrl = (type(initData.progress_url) == "string" and initData.progress_url:match("^https?://"))
                    and initData.progress_url
                    or (tc.prog .. tostring(initData.id))

                for attempt = 1, 26 do
                    task.wait(1.4)
                    local pct = math.min(99, math.floor((attempt / 26) * 100))
                    UI.ImportStatus.Text = string.format("Converting Youtube MP3 (%d%%)...", pct)

                    local pRes = safeGet(pollUrl, { ["Referer"] = tc.ref })
                    if pRes and pRes.Body then
                        local okP, pData = pcall(function() return SRV.Http:JSONDecode(pRes.Body) end)
                        if okP and type(pData) == "table" then
                            if type(pData.download_url) == "string" and #pData.download_url > 10 then
                                UI.ImportStatus.Text = "Saving MP3 to YouTube Downloads..."
                                local body, fmt = fetchAndVerifyAudio(pData.download_url, tc.ref)
                                if body then
                                    audioPayload, audioExt = body, fmt
                                    log("YT_HIT", "Transcoder succeeded on:", tc.name)
                                    break
                                end
                                break
                            elseif tonumber(pData.success) == 0 and tostring(pData.text or ""):lower():find("error") then
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    if not audioPayload then
        UI.ImportStatus.Text = "Trying fallback Youtube server..."
        local vJob = safePostJson("https://api.vevioz.com/api/v1/jobs", {
            url = watchUrl,
            format = "mp3",
            quality = "128",
        })
        if vJob and vJob.Body then
            local okV, vData = pcall(function() return SRV.Http:JSONDecode(vJob.Body) end)
            if okV and type(vData) == "table" then
                local direct = vData.download_url or vData.url
                if direct then
                    local body, fmt = fetchAndVerifyAudio(direct, "https://api.vevioz.com/")
                    if body then audioPayload, audioExt = body, fmt end
                elseif vData.job_id then
                    local tok = vData.token and ("?token=" .. tostring(vData.token)) or ""
                    for _ = 1, 15 do
                        task.wait(1.5)
                        local st = safeGet("https://api.vevioz.com/api/v1/jobs/" .. tostring(vData.job_id) .. tok)
                        if st and st.Body then
                            local okS, sData = pcall(function() return SRV.Http:JSONDecode(st.Body) end)
                            if okS and type(sData) == "table" and (sData.download_url or sData.url) then
                                local body, fmt = fetchAndVerifyAudio(sData.download_url or sData.url, "https://api.vevioz.com/")
                                if body then audioPayload, audioExt = body, fmt end
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    if not audioPayload or not audioExt then
        UI.ImportStatus.Text = "Failed to download audio from Youtube."
        UI.ImportStatus.TextColor3 = CLR.STATUS_ERR
        UI.DownloadBtn.Text = "SEARCH"
        RT.downloading = false
        return
    end

    local displayTitle = resolvedTitle or ("YouTube_" .. cleanId)
    local displayCreator = resolvedCreator or "YouTube Creator"
    local safeBase = cleanFileName(displayTitle) or ("yt_" .. cleanId)
    local savePath = PATHS.YT .. "/" .. safeBase .. "." .. audioExt

    writefile(savePath, audioPayload)

    local testAsset = asset(savePath)
    if testAsset == "" then
        pcall(delfile, savePath)
        safeBase = "yt_" .. cleanId
        savePath = PATHS.YT .. "/" .. safeBase .. "." .. audioExt
        writefile(savePath, audioPayload)
        testAsset = asset(savePath)
    end

    local thumbPath = nil
    if spotifyMeta and spotifyMeta.coverUrl then
        thumbPath = saveImageFromUrl(spotifyMeta.coverUrl, safeBase)
    end
    if not thumbPath then
        thumbPath = downloadYoutubeThumbnail(cleanId, safeBase)
    end

    local srcLabel = "Youtube"
    local transparencyNote = "Youtube"

    State.titles[safeBase] = displayTitle
    State.titles[cleanId] = displayTitle
    State.meta[safeBase] = {
        title = displayTitle,
        creator = displayCreator,
        source = srcLabel,
        note = transparencyNote,
    }
    State.meta[cleanId] = {
        title = displayTitle,
        creator = displayCreator,
        source = srcLabel,
        note = transparencyNote,
    }
    saveState()

    local songObj = {
        path = savePath,
        name = displayTitle,
        creator = displayCreator,
        dir = PATHS.YT,
        source = srcLabel,
        note = transparencyNote,
        ytId = cleanId,
        coverPath = thumbPath,
        audio = testAsset,
    }

    RT.songs[#RT.songs + 1] = songObj
    songObj.idx = #RT.songs
    addPlaylistRow(songObj)

    UI.LinkInput.Text = ""
    if fromSpotifyLink then
        UI.ImportStatus.Text = "No Spotify support - searched & downloaded from Youtube!"
        UI.ImportStatus.TextColor3 = CLR.STATUS_WARN
    else
        UI.ImportStatus.Text = "Downloaded from Youtube."
        UI.ImportStatus.TextColor3 = CLR.STATUS_OK
    end

    UI.DownloadBtn.Text = "SEARCH"
    RT.downloading = false

    playSong(songObj)
end

local function renderSearchResults(results)
    for _, child in ipairs(UI.SearchResultsScroll:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    if #results == 0 then
        setSearchResultsExpanded(false)
        UI.ImportStatus.Text = "No tracks found for that search."
        UI.ImportStatus.TextColor3 = CLR.STATUS_ERR
        return
    end

    for idx, item in ipairs(results) do
        local card = make("TextButton", UI.SearchResultsScroll, {
            Size = UDim2.new(1, -4, 0, 38),
            BackgroundColor3 = CLR.BG_SURFACE,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            LayoutOrder = idx,
        })
        make("UICorner", card, { CornerRadius = UDim.new(0, 6) })

        local thumbFrame = make("Frame", card, {
            Position = UDim2.fromOffset(5, 5),
            Size = UDim2.fromOffset(28, 28),
            BackgroundColor3 = CLR.BG_WINDOW,
            BorderSizePixel = 0,
        })
        make("UICorner", thumbFrame, { CornerRadius = UDim.new(0, 4) })

        local thumbImg = make("ImageLabel", thumbFrame, {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Image = RT.defaultCover,
            ScaleType = Enum.ScaleType.Crop,
        })
        make("UICorner", thumbImg, { CornerRadius = UDim.new(0, 4) })

        task.spawn(function()
            local cachedThumb = PATHS.CACHE .. "/thumb_" .. item.id .. ".jpg"
            if not isfile(cachedThumb) then
                local res = safeGet("https://i.ytimg.com/vi/" .. item.id .. "/default.jpg")
                if res and res.Body and #res.Body > 512 then
                    pcall(writefile, cachedThumb, res.Body)
                end
            end
            if isfile(cachedThumb) and thumbImg.Parent then
                local a = asset(cachedThumb)
                if a ~= "" then
                    thumbImg.Image = a
                end
            end
        end)

        make("TextLabel", card, {
            Position = UDim2.fromOffset(40, 4),
            Size = UDim2.new(1, -92, 0, 15),
            BackgroundTransparency = 1,
            Text = item.title,
            TextColor3 = CLR.TEXT_PRIMARY,
            Font = Enum.Font.BuilderSansBold,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })

        local subStr = item.creator
        if item.duration and #item.duration > 0 then
            subStr = subStr .. "  |  " .. item.duration
        end

        make("TextLabel", card, {
            Position = UDim2.fromOffset(40, 20),
            Size = UDim2.new(1, -92, 0, 13),
            BackgroundTransparency = 1,
            Text = subStr,
            TextColor3 = CLR.TEXT_SECONDARY,
            Font = Enum.Font.BuilderSans,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })

        local getPill = make("TextLabel", card, {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(38, 18),
            BackgroundColor3 = CLR.BG_ELEVATED,
            BorderSizePixel = 0,
            Text = "PLAY",
            TextColor3 = CLR.TEXT_PRIMARY,
            Font = Enum.Font.BuilderSansBold,
            TextSize = 8,
        })
        make("UICorner", getPill, { CornerRadius = UDim.new(0, 4) })

        connect(card.MouseEnter, function()
            card.BackgroundColor3 = CLR.BG_ELEVATED
            getPill.BackgroundColor3 = getAccent()
            getPill.TextColor3 = getAccentText()
        end)
        connect(card.MouseLeave, function()
            card.BackgroundColor3 = CLR.BG_SURFACE
            getPill.BackgroundColor3 = CLR.BG_ELEVATED
            getPill.TextColor3 = CLR.TEXT_PRIMARY
        end)
        connect(card.Activated, function()
            task.spawn(function()
                downloadYoutubeById(item.id, item.title, item.creator, nil, false)
            end)
        end)
    end

    setSearchResultsExpanded(true)
    UI.ImportStatus.Text = "Found " .. #results .. " tracks - click any result to download & play"
    UI.ImportStatus.TextColor3 = CLR.STATUS_OK
end

local function handleSearchOrImport(rawInput)
    if RT.downloading or RT.searching then return end
    if not httpRequest then
        UI.ImportStatus.Text = "Executor lacks http_request support!"
        UI.ImportStatus.TextColor3 = CLR.STATUS_ERR
        return
    end

    rawInput = (rawInput or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if #rawInput < 2 then
        UI.ImportStatus.Text = "Type a song name or paste a link."
        UI.ImportStatus.TextColor3 = CLR.STATUS_ERR
        return
    end

    local spTrackId = extractSpotifyTrackId(rawInput)
    if spTrackId then
        RT.searching = true
        UI.DownloadBtn.Text = "..."
        setSearchResultsExpanded(false)
        UI.ImportStatus.Text = "No Spotify support - searching on Youtube..."
        UI.ImportStatus.TextColor3 = CLR.STATUS_WARN

        local spotifyMeta = fetchSpotifyTrackById(spTrackId)
        if not spotifyMeta then
            UI.ImportStatus.Text = "Could not read Spotify track metadata."
            UI.ImportStatus.TextColor3 = CLR.STATUS_ERR
            UI.DownloadBtn.Text = "SEARCH"
            RT.searching = false
            return
        end

        local matches = searchYoutubeTracks(spotifyMeta.searchQuery)
        RT.searching = false
        if #matches == 0 then
            UI.ImportStatus.Text = "No Spotify support - track not found on Youtube."
            UI.ImportStatus.TextColor3 = CLR.STATUS_ERR
            UI.DownloadBtn.Text = "SEARCH"
            return
        end

        downloadYoutubeById(matches[1].id, spotifyMeta.title, spotifyMeta.creator, spotifyMeta, true)
        return
    end

    local directId = extractVideoId(rawInput)
    if directId then
        downloadYoutubeById(directId, nil, nil, nil, false)
        return
    end

    RT.searching = true
    UI.DownloadBtn.Text = "..."
    UI.ImportStatus.Text = "Searching Youtube for \"" .. rawInput .. "\"..."
    UI.ImportStatus.TextColor3 = CLR.TEXT_PRIMARY

    local results = searchYoutubeTracks(rawInput)
    RT.searching = false
    UI.DownloadBtn.Text = "SEARCH"
    renderSearchResults(results)
end

do
    connect(UI.DownloadBtn.Activated, function()
        task.spawn(function()
            handleSearchOrImport(UI.LinkInput.Text)
        end)
    end)

    connect(UI.LinkInput.FocusLost, function(enterPressed)
        if enterPressed and UI.LinkInput.Text ~= "" then
            task.spawn(function()
                handleSearchOrImport(UI.LinkInput.Text)
            end)
        end
    end)

    local function addSettingRow(labelText, btnText, onClick)
        local row = make("Frame", UI.SettingsScroll, {
            Size = UDim2.new(1, -4, 0, 26),
            BackgroundColor3 = CLR.BG_SURFACE,
            BorderSizePixel = 0,
        })
        make("UICorner", row, { CornerRadius = UDim.new(0, 6) })

        make("TextLabel", row, {
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -110, 1, 0),
            BackgroundTransparency = 1,
            Text = labelText,
            TextColor3 = CLR.TEXT_PRIMARY,
            Font = Enum.Font.BuilderSans,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        local btn = make("TextButton", row, {
            Position = UDim2.new(1, -96, 0.5, -9),
            Size = UDim2.fromOffset(88, 18),
            BackgroundColor3 = CLR.BG_ELEVATED,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = btnText,
            TextColor3 = CLR.TEXT_PRIMARY,
            Font = Enum.Font.BuilderSansBold,
            TextSize = 9,
        })
        make("UICorner", btn, { CornerRadius = UDim.new(0, 4) })
        connect(btn.Activated, function()
            onClick(btn)
        end)
        return btn
    end

    addSettingRow("Accent Theme", Opts.spotifyGreen and "Spotify Green" or "Client White", function(btn)
        Opts.spotifyGreen = not Opts.spotifyGreen
        State.spotifyGreen = Opts.spotifyGreen
        btn.Text = Opts.spotifyGreen and "Spotify Green" or "Client White"
        applyThemeAccent()
        refreshPlayStateUI()
        saveState()
    end)

    addSettingRow("Rainbow Visualizer", Opts.rainbow and "ON" or "OFF", function(btn)
        Opts.rainbow = not Opts.rainbow
        State.rainbow = Opts.rainbow
        btn.Text = Opts.rainbow and "ON" or "OFF"
        saveState()
    end)

    local scaleCycle = { 0.85, 1.0, 1.15, 1.3 }
    addSettingRow("Player Scale", math.floor(Opts.scale * 100 + 0.5) .. "%", function(btn)
        local nextS = scaleCycle[1]
        for i, v in ipairs(scaleCycle) do
            if math.abs(v - Opts.scale) < 0.05 then
                nextS = scaleCycle[(i % #scaleCycle) + 1]
                break
            end
        end
        Opts.scale = nextS
        State.scale = nextS
        btn.Text = math.floor(nextS * 100 + 0.5) .. "%"
        tween(UI.RootScale, 0.2, { Scale = nextS })
        saveState()
    end)

    addSettingRow("Toggle UI Keybind", RT.hideKey and RT.hideKey.Name or "None", function(btn)
        RT.listeningKey = true
        btn.Text = "Press key..."
        local conn
        conn = SRV.UIS.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                RT.listeningKey = false
                RT.hideKey = (input.KeyCode ~= Enum.KeyCode.Escape) and input.KeyCode or nil
                State.hideKey = RT.hideKey and RT.hideKey.Name or ""
                btn.Text = RT.hideKey and RT.hideKey.Name or "None"
                saveState()
                conn:Disconnect()
            end
        end)
    end)

    local keyRow = make("Frame", UI.SettingsScroll, {
        Size = UDim2.new(1, -4, 0, 26),
        BackgroundColor3 = CLR.BG_SURFACE,
        BorderSizePixel = 0,
    })
    make("UICorner", keyRow, { CornerRadius = UDim.new(0, 6) })

    make("TextLabel", keyRow, {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.fromOffset(92, 26),
        BackgroundTransparency = 1,
        Text = "API Key (Optional)",
        TextColor3 = CLR.TEXT_PRIMARY,
        Font = Enum.Font.BuilderSans,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local keyBox = make("TextBox", keyRow, {
        Position = UDim2.new(1, -226, 0.5, -9),
        Size = UDim2.fromOffset(218, 18),
        BackgroundColor3 = CLR.BG_WINDOW,
        BorderSizePixel = 0,
        Text = Opts.apiKey,
        PlaceholderText = "savenow.to key...",
        PlaceholderColor3 = CLR.TEXT_MUTED,
        TextColor3 = CLR.TEXT_PRIMARY,
        Font = Enum.Font.BuilderSans,
        TextSize = 10,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
    })
    make("UICorner", keyBox, { CornerRadius = UDim.new(0, 4) })
    connect(keyBox.FocusLost, function()
        Opts.apiKey = keyBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        State.apiKey = Opts.apiKey
        saveState()
    end)

    addSettingRow("Copy Debug Logs", "Copy", function(btn)
        local ok = copyLogsToClipboard()
        btn.Text = ok and "Copied!" or "Saved!"
        task.delay(1.5, function()
            if btn.Parent then btn.Text = "Copy" end
        end)
    end)

    addSettingRow("Unload Player", "Close", function()
        tween(Sound, 0.25, { Volume = 0 })
        task.wait(0.25)
        cleanup()
    end)

    connect(UI.CloseBtn.Activated, function()
        tween(Sound, 0.25, { Volume = 0 })
        task.wait(0.25)
        cleanup()
    end)

    connect(SRV.UIS.InputBegan, function(input, gp)
        if gp or RT.listeningKey or not RT.hideKey or SRV.UIS:GetFocusedTextBox() then return end
        if input.KeyCode == RT.hideKey then
            UI.Gui.Enabled = not UI.Gui.Enabled
        end
    end)
end

if type(getgenv) == "function" then
    getgenv().xzypPlayer = {
        Gui = UI.Gui,
        Sound = Sound,
        Songs = RT.songs,
        Play = playSong,
        Search = handleSearchOrImport,
    }
end

log("INIT", "xzyp music player ready.")
