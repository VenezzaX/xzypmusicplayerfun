local MAX_DEPTH = 2
local EXTENSIONS = { mp3 = true, ogg = true, wav = true }
local IMAGE_EXTENSIONS = { png = true, jpg = true, jpeg = true, webp = true }

local BASE         = "xzyp"
local DIR_LOCAL    = BASE .. "/Local Playlist"
local DIR_YT       = BASE .. "/YouTube Downloads"
local DIR_COVERS   = BASE .. "/Covers"
local DIR_SYS      = BASE .. "/System"
local ICONS        = DIR_SYS .. "/icons"
local CACHE_DIR    = DIR_SYS .. "/.cache"
local STATE_FILE   = DIR_SYS .. "/state.json"
local FALLBACK     = DIR_SYS .. "/fallback.png"
local LOG_FILE     = DIR_SYS .. "/debug_log.txt"
local SAMPLE_SONG  = DIR_LOCAL .. "/JojiHypergamy.ogg"

local FALLBACK_URL = "https://media.discordapp.net/stickers/1499067663496777729.png" -- thanks weao for bao
local SAMPLE_URL   = "https://raw.githubusercontent.com/eliassixseven09-web/slap-battless/main/Joji_-_Worldstar_Money_TRASH_remix_%28mp3.pm%29.mp3" -- thanks to hypergamy vw6222

local DEBUG_LOGS = {}
local function log(tag, ...)
    local args = { ... }
    local strArr = {}
    for i = 1, #args do
        strArr[i] = tostring(args[i])
    end
    local msg = string.format("[%s] [%.3f] %s", tag, os.clock(), table.concat(strArr, " "))
    DEBUG_LOGS[#DEBUG_LOGS + 1] = msg
    print(msg)
end

local function copyLogsToClipboard()
    local dump = table.concat(DEBUG_LOGS, "\n")
    local setclip = setclipboard or toclipboard or (Clipboard and Clipboard.set)
    if setclip then
        setclip(dump)
        log("DEBUG", "Copied logs to clipboard.")
        return true
    else
        pcall(writefile, LOG_FILE, dump)
        log("DEBUG", "Saved logs to " .. LOG_FILE)
        return false
    end
end

log("INIT", "xzyp music player starting up...")

local httpRequest = (syn and syn.request) or request or http_request or (http and http.request)
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

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local TXT = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Player = Players.LocalPlayer

local firstRun = not isfolder(BASE)
mkdir(BASE)
mkdir(DIR_LOCAL)
mkdir(DIR_YT)
mkdir(DIR_COVERS)
mkdir(DIR_SYS)
mkdir(ICONS)
mkdir(CACHE_DIR)

local legacyState = BASE .. "/Last State.txt"
if isfile(legacyState) then
    if not isfile(STATE_FILE) then
        moveFileSafe(legacyState, STATE_FILE)
    else
        pcall(delfile, legacyState)
    end
end
if isfile(BASE .. "/fallback.png") then
    moveFileSafe(BASE .. "/fallback.png", FALLBACK)
end
if isfile(BASE .. "/debug_log.txt") then
    moveFileSafe(BASE .. "/debug_log.txt", LOG_FILE)
end

if not isfile(STATE_FILE) then
    pcall(writefile, STATE_FILE, "{}")
end

local State = {}
pcall(function()
    State = HttpService:JSONDecode(readfile(STATE_FILE))
end)
if type(State) ~= "table" then
    State = {}
end
if type(State.titles) ~= "table" then
    State.titles = {}
end
if type(State.meta) ~= "table" then
    State.meta = {}
end

local function saveState()
    pcall(function()
        writefile(STATE_FILE, HttpService:JSONEncode(State))
    end)
end

local legacyPlaylistDir = BASE .. "/Your Playlist"
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
                    if IMAGE_EXTENSIONS[ext] then
                        moveFileSafe(oldPath, DIR_COVERS .. "/" .. fname)
                    elseif EXTENSIONS[ext] then
                        local isYtFile = baseNoExt:match("^yt_[%w_%-]+$") ~= nil
                            or State.titles[baseNoExt] ~= nil
                            or State.meta[baseNoExt] ~= nil
                        local targetDir = isYtFile and DIR_YT or DIR_LOCAL
                        moveFileSafe(oldPath, targetDir .. "/" .. fname)
                    end
                end
            end
        end
    end
    pcall(delfolder, legacyPlaylistDir)
end

fetch(FALLBACK, FALLBACK_URL, true)
if firstRun then
    fetch(SAMPLE_SONG, SAMPLE_URL)
end

local collection, connections = {}, {}

local Cfg = {
    rainbow = State.rainbow ~= false,
    spotifyGreen = State.spotifyGreen == true,
    shuffle = State.shuffle == true,
    loopOne = State.loopOne == true,
    scale = math.clamp(tonumber(State.scale) or 1, 0.75, 1.35),
    volume = math.clamp(tonumber(State.volume) or 1.14, 0, 2),
    apiKey = type(State.apiKey) == "string" and State.apiKey or "",
}

local function make(class, parent, props)
    local o = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            o[k] = v
        end
    end
    o.Parent = parent
    collection[#collection + 1] = o
    return o
end

local function connect(signal, fn)
    local c = signal:Connect(fn)
    connections[#connections + 1] = c
    return c
end

local function cleanup()
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    for i = #collection, 1, -1 do
        pcall(function() collection[i]:Destroy() end)
        collection[i] = nil
    end
end

local function tween(o, t, props, style, dir)
    local tw = TS:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function norm(p)
    return (p:gsub("\\", "/"):gsub("/+$", ""))
end

local categories, songs = {}, {}
local SKIP = { icons = true, [".cache"] = true, system = true, covers = true }

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
            if not (last and SKIP[last:lower()]) then
                dirs[#dirs + 1] = path
            end
        else
            local ext = path:match("%.(%w+)$")
            ext = ext and ext:lower()
            if ext and EXTENSIONS[ext] then
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

                local srcTag = isYt and "Youtube" or "LOCAL"
                local creatorName = (type(savedMeta) == "table" and savedMeta.creator)
                    or (isYt and "YouTube Creator" or "Local Audio")
                local subNote = isYt and "Youtube" or "Local Playlist"

                list[#list + 1] = {
                    path = path,
                    name = displayName,
                    creator = creatorName,
                    dir = dir,
                    source = srcTag,
                    note = subNote,
                    ytId = ytIdMatch,
                }
            elseif dir ~= "" and ext and IMAGE_EXTENSIONS[ext] then
                covers[#covers + 1] = path
            end
        end
    end

    if #list > 0 then
        local label = norm(dir)
        if label == "" then
            label = "Workspace"
        elseif label:sub(1, #BASE + 1) == BASE .. "/" then
            label = label:sub(#BASE + 2)
        end
        categories[#categories + 1] = { dir = dir, label = label, songs = list, covers = covers }
        for _, s in ipairs(list) do
            songs[#songs + 1] = s
            s.idx = #songs
        end
    end

    if depth < MAX_DEPTH then
        for _, d in ipairs(dirs) do
            scanDir(d, depth + 1)
        end
    end
end

scanDir((getgenv and getgenv().ScanWholeWorkspace) and "" or BASE, 0)
log("SCAN", "Initial songs loaded:", #songs)

local lastSong
for _, s in ipairs(songs) do
    if s.path == State.lastSong then
        lastSong = s
        break
    end
end

local function asset(p)
    local ok, r = pcall(getcustomasset, p)
    return (ok and type(r) == "string" and r ~= "") and r or ""
end

local defaultCover = isfile(FALLBACK) and asset(FALLBACK) or ""

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
        local safeCachePath = string.format("%s/cached_%d.%s", CACHE_DIR, hash, ext)
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
    if not s then return defaultCover end
    if s.coverPath and isfile(s.coverPath) then
        local a = asset(s.coverPath)
        if a ~= "" then return a end
    end
    local baseName = s.path:match("([^/\\]+)%.%w+$")
    if baseName then
        for _, ext in ipairs({ "png", "jpg", "jpeg", "webp" }) do
            local centralCover = DIR_COVERS .. "/" .. baseName .. "." .. ext
            if isfile(centralCover) then
                s.coverPath = centralCover
                local a = asset(centralCover)
                if a ~= "" then return a end
            end
            if s.ytId then
                local idCover = DIR_COVERS .. "/yt_" .. s.ytId .. "." .. ext
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
    return defaultCover
end

local Sound = make("Sound", SoundService, {
    Name = "xzypAudio",
    Looped = false,
    Volume = Cfg.volume,
})

connect(Sound.Loaded, function()
    log("SOUND_LOADED", "TimeLength:", Sound.TimeLength)
end)

local BG_WINDOW   = Color3.fromRGB(5, 5, 7)
local BG_HEADER   = Color3.fromRGB(8, 8, 11)
local BG_SURFACE  = Color3.fromRGB(12, 12, 16)
local BG_ELEVATED = Color3.fromRGB(19, 20, 25)
local BG_ACTIVE   = Color3.fromRGB(25, 26, 33)
local BORDER_LINE = Color3.fromRGB(24, 25, 32)

local TEXT_PRIMARY   = Color3.fromRGB(238, 238, 242)
local TEXT_SECONDARY = Color3.fromRGB(125, 128, 140)
local TEXT_MUTED     = Color3.fromRGB(76, 79, 90)

local CLIENT_WHITE  = Color3.fromRGB(238, 238, 242)
local SPOTIFY_GREEN = Color3.fromRGB(30, 215, 96)
local STATUS_OK     = Color3.fromRGB(64, 214, 114)
local STATUS_WARN   = Color3.fromRGB(245, 185, 75)
local STATUS_ERR    = Color3.fromRGB(245, 95, 105)

local function getAccent()
    return Cfg.spotifyGreen and SPOTIFY_GREEN or CLIENT_WHITE
end

local function getAccentText()
    return Color3.fromRGB(6, 6, 8)
end

local Gui = make("ScreenGui", Player:WaitForChild("PlayerGui"), {
    Name = "xzypMusicPlayer",
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local PLAYER_W = 376
local TOPBAR_H = 28
local BODY_H   = 114
local FULL_H   = TOPBAR_H + BODY_H
local CARD_R   = 10

local Root = make("Frame", Gui, {
    Name = "xzypRoot",
    Size = UDim2.fromOffset(PLAYER_W, FULL_H),
    Position = UDim2.new(1, -(PLAYER_W + 24), 1, -(FULL_H + 24)),
    BackgroundTransparency = 1,
})
local RootScale = make("UIScale", Root, { Scale = Cfg.scale })

local MainCard = make("Frame", Root, {
    Name = "ClientPlayerCard",
    Size = UDim2.fromOffset(PLAYER_W, FULL_H),
    BackgroundColor3 = BG_WINDOW,
    BorderSizePixel = 0,
})
make("UICorner", MainCard, { CornerRadius = UDim.new(0, CARD_R) })
make("UIStroke", MainCard, {
    Thickness = 1,
    Color = BORDER_LINE,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})

local TopBar = make("Frame", MainCard, {
    Name = "TopBar",
    Size = UDim2.new(1, 0, 0, TOPBAR_H),
    BackgroundColor3 = BG_HEADER,
    BorderSizePixel = 0,
    ZIndex = 2,
})
make("UICorner", TopBar, { CornerRadius = UDim.new(0, CARD_R) })

make("Frame", TopBar, {
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.fromScale(0, 1),
    Size = UDim2.new(1, 0, 0, CARD_R),
    BackgroundColor3 = BG_HEADER,
    BorderSizePixel = 0,
    ZIndex = 2,
})
make("Frame", TopBar, {
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.fromScale(0, 1),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = BORDER_LINE,
    BorderSizePixel = 0,
    ZIndex = 3,
})

local StatusDot = make("Frame", TopBar, {
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 11, 0.5, 0),
    Size = UDim2.fromOffset(6, 6),
    BackgroundColor3 = STATUS_OK,
    BorderSizePixel = 0,
    ZIndex = 4,
})
make("UICorner", StatusDot, { CornerRadius = UDim.new(1, 0) })

local HeaderTitle = make("TextLabel", TopBar, {
    Position = UDim2.fromOffset(23, 0),
    Size = UDim2.fromOffset(180, TOPBAR_H),
    BackgroundTransparency = 1,
    Text = "xzyp music player",
    TextColor3 = TEXT_SECONDARY,
    Font = Enum.Font.BuilderSansBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
})

local function makeHeaderPill(pos, size, text, isAccent, textSize)
    local b = make("TextButton", TopBar, {
        Position = pos,
        Size = size,
        BackgroundColor3 = isAccent and getAccent() or BG_SURFACE,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = text,
        TextColor3 = isAccent and getAccentText() or TEXT_SECONDARY,
        Font = Enum.Font.BuilderSansBold,
        TextSize = textSize or 9,
        ZIndex = 4,
    })
    make("UICorner", b, { CornerRadius = UDim.new(0, 5) })
    if not isAccent then
        make("UIStroke", b, {
            Thickness = 1,
            Color = BORDER_LINE,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
    end
    connect(b.MouseEnter, function()
        if isAccent then
            tween(b, 0.12, { BackgroundTransparency = 0.15 })
        else
            tween(b, 0.12, { BackgroundColor3 = BG_ELEVATED, TextColor3 = TEXT_PRIMARY })
        end
    end)
    connect(b.MouseLeave, function()
        if isAccent then
            tween(b, 0.12, { BackgroundTransparency = 0 })
        else
            tween(b, 0.12, { BackgroundColor3 = BG_SURFACE, TextColor3 = TEXT_SECONDARY })
        end
    end)
    return b
end

local AddBtn   = makeHeaderPill(UDim2.fromOffset(210, 4), UDim2.fromOffset(40, 20), "+ADD", true, 9)
local QueueBtn = makeHeaderPill(UDim2.fromOffset(254, 4), UDim2.fromOffset(44, 20), "QUEUE", false, 9)
local CfgBtn   = makeHeaderPill(UDim2.fromOffset(302, 4), UDim2.fromOffset(22, 20), "\u{2699}", false, 11)
local MiniBtn  = makeHeaderPill(UDim2.fromOffset(327, 4), UDim2.fromOffset(20, 20), "\u{2014}", false, 10)
local CloseBtn = makeHeaderPill(UDim2.fromOffset(350, 4), UDim2.fromOffset(20, 20), "\u{00D7}", false, 11)

local Body = make("Frame", MainCard, {
    Name = "PlayerBody",
    Position = UDim2.fromOffset(0, TOPBAR_H),
    Size = UDim2.new(1, 0, 0, BODY_H),
    BackgroundTransparency = 1,
    ZIndex = 2,
})

local ArtFrame = make("Frame", Body, {
    Name = "Artwork",
    Position = UDim2.fromOffset(12, 13),
    Size = UDim2.fromOffset(88, 88),
    BackgroundColor3 = BG_SURFACE,
    BorderSizePixel = 0,
})
make("UICorner", ArtFrame, { CornerRadius = UDim.new(0, 8) })

local CoverImg = make("ImageLabel", ArtFrame, {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = BG_SURFACE,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    Image = lastSong and coverOf(lastSong) or defaultCover,
    ScaleType = Enum.ScaleType.Crop,
})
make("UICorner", CoverImg, { CornerRadius = UDim.new(0, 8) })

local ArtBorder = make("Frame", ArtFrame, {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex = 4,
})
make("UICorner", ArtBorder, { CornerRadius = UDim.new(0, 8) })
make("UIStroke", ArtBorder, {
    Thickness = 1,
    Color = BORDER_LINE,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})

local SourceTag = make("TextLabel", ArtFrame, {
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 6, 1, -6),
    Size = UDim2.fromOffset(50, 15),
    BackgroundColor3 = Color3.fromRGB(6, 6, 8),
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    Text = "IDLE",
    TextColor3 = TEXT_PRIMARY,
    Font = Enum.Font.BuilderSansBold,
    TextSize = 8,
    ZIndex = 3,
})
make("UICorner", SourceTag, { CornerRadius = UDim.new(0, 4) })

local TitleViewport = make("Frame", Body, {
    Position = UDim2.fromOffset(112, 12),
    Size = UDim2.fromOffset(198, 19),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
})

local TrackTitle = make("TextLabel", TitleViewport, {
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromOffset(198, 19),
    BackgroundTransparency = 1,
    Text = #songs > 0 and "No track playing" or "Library is empty",
    TextColor3 = TEXT_PRIMARY,
    Font = Enum.Font.BuilderSansBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local titleScrollOverflow = 0
local titleSetTime = 0
local function setTrackTitleText(str)
    TrackTitle.Text = str
    TrackTitle.Position = UDim2.fromOffset(0, 0)
    titleSetTime = os.clock()
    local bounds = TXT:GetTextSize(str, 14, Enum.Font.BuilderSansBold, Vector2.new(4000, 19)).X
    if bounds > 198 then
        TrackTitle.Size = UDim2.fromOffset(bounds + 16, 19)
        titleScrollOverflow = bounds - 198
    else
        TrackTitle.Size = UDim2.fromOffset(198, 19)
        titleScrollOverflow = 0
    end
end

local TrackSub = make("TextLabel", Body, {
    Position = UDim2.fromOffset(112, 31),
    Size = UDim2.fromOffset(198, 14),
    BackgroundTransparency = 1,
    Text = #songs .. (#songs == 1 and " track available" or " tracks available"),
    TextColor3 = TEXT_SECONDARY,
    Font = Enum.Font.BuilderSans,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
})

local EQ_COUNT = 8
local eqBars = {}
local EqWrap = make("Frame", Body, {
    Position = UDim2.fromOffset(320, 14),
    Size = UDim2.fromOffset(42, 24),
    BackgroundTransparency = 1,
})
for i = 1, EQ_COUNT do
    local bar = make("Frame", EqWrap, {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromOffset((i - 1) * 5, 24),
        Size = UDim2.fromOffset(3, 2),
        BackgroundColor3 = getAccent(),
        BorderSizePixel = 0,
    })
    make("UICorner", bar, { CornerRadius = UDim.new(1, 0) })
    eqBars[i] = bar
end

local SeekHit = make("TextButton", Body, {
    Name = "SeekHit",
    Position = UDim2.fromOffset(112, 48),
    Size = UDim2.fromOffset(250, 14),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
})
local SeekTrack = make("Frame", SeekHit, {
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.fromScale(0, 0.5),
    Size = UDim2.new(1, 0, 0, 3),
    BackgroundColor3 = BG_ELEVATED,
    BorderSizePixel = 0,
})
make("UICorner", SeekTrack, { CornerRadius = UDim.new(1, 0) })

local SeekFill = make("Frame", SeekTrack, {
    Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = getAccent(),
    BorderSizePixel = 0,
})
make("UICorner", SeekFill, { CornerRadius = UDim.new(1, 0) })

local SeekKnob = make("Frame", SeekTrack, {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0, 0.5),
    Size = UDim2.fromOffset(9, 9),
    BackgroundColor3 = TEXT_PRIMARY,
    BorderSizePixel = 0,
    Visible = false,
})
make("UICorner", SeekKnob, { CornerRadius = UDim.new(1, 0) })

local HoverTimeTip = make("TextLabel", Body, {
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.fromOffset(112, 46),
    Size = UDim2.fromOffset(34, 14),
    BackgroundColor3 = BG_ELEVATED,
    BorderSizePixel = 0,
    Text = "0:00",
    TextColor3 = TEXT_PRIMARY,
    Font = Enum.Font.BuilderSansBold,
    TextSize = 8,
    Visible = false,
    ZIndex = 8,
})
make("UICorner", HoverTimeTip, { CornerRadius = UDim.new(0, 4) })
make("UIStroke", HoverTimeTip, {
    Thickness = 1,
    Color = BORDER_LINE,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})

local seekHovering = false
connect(SeekHit.MouseEnter, function()
    seekHovering = true
    SeekKnob.Visible = true
    HoverTimeTip.Visible = true
    tween(SeekTrack, 0.1, { Size = UDim2.new(1, 0, 0, 5) })
end)
connect(SeekHit.MouseLeave, function()
    seekHovering = false
    SeekKnob.Visible = false
    HoverTimeTip.Visible = false
    tween(SeekTrack, 0.1, { Size = UDim2.new(1, 0, 0, 3) })
end)

local TimeNow = make("TextLabel", Body, {
    Position = UDim2.fromOffset(112, 61),
    Size = UDim2.fromOffset(44, 11),
    BackgroundTransparency = 1,
    Text = "0:00",
    TextColor3 = TEXT_MUTED,
    Font = Enum.Font.BuilderSans,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
})
local TimeEnd = make("TextLabel", Body, {
    Position = UDim2.fromOffset(318, 61),
    Size = UDim2.fromOffset(44, 11),
    BackgroundTransparency = 1,
    Text = "0:00",
    TextColor3 = TEXT_MUTED,
    Font = Enum.Font.BuilderSans,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Right,
})

local function makeTransportBtn(pos, size, glyph, textSize, withBox)
    local b = make("TextButton", Body, {
        Position = pos,
        Size = size,
        BackgroundColor3 = BG_SURFACE,
        BackgroundTransparency = withBox and 0 or 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = glyph,
        TextColor3 = TEXT_SECONDARY,
        Font = Enum.Font.BuilderSansBold,
        TextSize = textSize or 11,
    })
    if withBox then
        make("UICorner", b, { CornerRadius = UDim.new(0, 6) })
        make("UIStroke", b, {
            Thickness = 1,
            Color = BORDER_LINE,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
    end
    connect(b.MouseEnter, function()
        tween(b, 0.1, { TextColor3 = TEXT_PRIMARY })
        if withBox then tween(b, 0.1, { BackgroundColor3 = BG_ELEVATED }) end
    end)
    connect(b.MouseLeave, function()
        if not b:GetAttribute("Active") then
            tween(b, 0.1, { TextColor3 = TEXT_SECONDARY })
        end
        if withBox then tween(b, 0.1, { BackgroundColor3 = BG_SURFACE }) end
    end)
    return b
end

local ShuffleBtn = makeTransportBtn(UDim2.fromOffset(114, 77), UDim2.fromOffset(22, 22), "\u{21C4}", 13, false)
local PrevBtn    = makeTransportBtn(UDim2.fromOffset(142, 77), UDim2.fromOffset(22, 22), "<", 11, true)

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

local PlayCircle, setMainPlayVisual, setMainPlayColors = createCirclePlayButton(
    Body,
    UDim2.fromOffset(169, 73),
    30,
    2,
    10,
    3
)
local PlayScale = make("UIScale", PlayCircle, { Scale = 1 })

connect(PlayCircle.MouseEnter, function()
    tween(PlayScale, 0.12, { Scale = 1.07 })
end)
connect(PlayCircle.MouseLeave, function()
    tween(PlayScale, 0.12, { Scale = 1 })
end)

local NextBtn = makeTransportBtn(UDim2.fromOffset(204, 77), UDim2.fromOffset(22, 22), ">", 11, true)
local LoopBtn = makeTransportBtn(UDim2.fromOffset(230, 77), UDim2.fromOffset(24, 22), "REP", 8, false)

local function syncModeButtons()
    ShuffleBtn:SetAttribute("Active", Cfg.shuffle)
    ShuffleBtn.TextColor3 = Cfg.shuffle and getAccent() or TEXT_SECONDARY
    LoopBtn:SetAttribute("Active", Cfg.loopOne)
    LoopBtn.TextColor3 = Cfg.loopOne and getAccent() or TEXT_SECONDARY
end
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

local function updateSpeakerVisual(vol)
    local activeCol = vol == 0 and STATUS_ERR or Color3.fromRGB(175, 180, 192)
    SpkBox.BackgroundColor3 = activeCol
    SpkCone.BackgroundColor3 = activeCol
    SpkWave1.Visible = vol > 0.05
    SpkWave2.Visible = vol > 0.65
end
updateSpeakerVisual(Cfg.volume)

local VolHit = make("TextButton", Body, {
    Position = UDim2.fromOffset(278, 81),
    Size = UDim2.fromOffset(56, 14),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
})
local VolTrack = make("Frame", VolHit, {
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.fromScale(0, 0.5),
    Size = UDim2.new(1, 0, 0, 3),
    BackgroundColor3 = BG_ELEVATED,
    BorderSizePixel = 0,
})
make("UICorner", VolTrack, { CornerRadius = UDim.new(1, 0) })
local VolFill = make("Frame", VolTrack, {
    Size = UDim2.fromScale(math.clamp(Cfg.volume / 2, 0, 1), 1),
    BackgroundColor3 = getAccent(),
    BorderSizePixel = 0,
})
make("UICorner", VolFill, { CornerRadius = UDim.new(1, 0) })

local VolPct = make("TextLabel", Body, {
    Position = UDim2.fromOffset(336, 77),
    Size = UDim2.fromOffset(28, 22),
    BackgroundTransparency = 1,
    Text = math.floor(Cfg.volume * 50 + 0.5) .. "%",
    TextColor3 = TEXT_MUTED,
    Font = Enum.Font.BuilderSans,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Right,
})

local MiniPill = make("Frame", Root, {
    Name = "MiniPill",
    Size = UDim2.fromOffset(278, 38),
    BackgroundColor3 = BG_WINDOW,
    BorderSizePixel = 0,
    Visible = false,
})
make("UICorner", MiniPill, { CornerRadius = UDim.new(1, 0) })
make("UIStroke", MiniPill, {
    Thickness = 1,
    Color = BORDER_LINE,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})

local MiniArt = make("ImageLabel", MiniPill, {
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 5, 0.5, 0),
    Size = UDim2.fromOffset(28, 28),
    BackgroundColor3 = BG_SURFACE,
    BorderSizePixel = 0,
    Image = lastSong and coverOf(lastSong) or defaultCover,
    ScaleType = Enum.ScaleType.Crop,
})
make("UICorner", MiniArt, { CornerRadius = UDim.new(1, 0) })

local MiniTitle = make("TextLabel", MiniPill, {
    Position = UDim2.fromOffset(40, 0),
    Size = UDim2.fromOffset(126, 38),
    BackgroundTransparency = 1,
    Text = "xzyp",
    TextColor3 = TEXT_PRIMARY,
    Font = Enum.Font.BuilderSansBold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
})

local function makeMiniCtrl(xOff, txt)
    local b = make("TextButton", MiniPill, {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, xOff, 0.5, 0),
        Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = BG_SURFACE,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = txt,
        TextColor3 = TEXT_PRIMARY,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 10,
    })
    make("UICorner", b, { CornerRadius = UDim.new(1, 0) })
    make("UIStroke", b, {
        Thickness = 1,
        Color = BORDER_LINE,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    return b
end

local MiniPrev = makeMiniCtrl(170, "<")
local MiniPlay, setMiniPlayVisual, setMiniPlayColors = createCirclePlayButton(
    MiniPill,
    UDim2.new(0, 195, 0.5, -11),
    22,
    2,
    8,
    2
)
local MiniNext   = makeMiniCtrl(220, ">")
local MiniExpand = makeMiniCtrl(246, "+")

local ImportPanel = make("Frame", Root, {
    Name = "ImportPanel",
    Position = UDim2.fromOffset(0, FULL_H + 6),
    Size = UDim2.fromOffset(PLAYER_W, 58),
    BackgroundColor3 = BG_WINDOW,
    BorderSizePixel = 0,
    Visible = false,
})
make("UICorner", ImportPanel, { CornerRadius = UDim.new(0, 9) })
make("UIStroke", ImportPanel, {
    Thickness = 1,
    Color = BORDER_LINE,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})

local LinkInput = make("TextBox", ImportPanel, {
    Position = UDim2.fromOffset(10, 8),
    Size = UDim2.fromOffset(282, 22),
    BackgroundColor3 = BG_SURFACE,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Paste Spotify link, YouTube link, or ID...",
    PlaceholderColor3 = TEXT_MUTED,
    TextColor3 = TEXT_PRIMARY,
    Font = Enum.Font.BuilderSans,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    ClipsDescendants = true,
})
make("UICorner", LinkInput, { CornerRadius = UDim.new(0, 6) })
make("UIStroke", LinkInput, {
    Thickness = 1,
    Color = BORDER_LINE,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})
make("UIPadding", LinkInput, { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })

local DownloadBtn = make("TextButton", ImportPanel, {
    Position = UDim2.fromOffset(298, 8),
    Size = UDim2.fromOffset(68, 22),
    BackgroundColor3 = getAccent(),
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "DOWNLOAD",
    TextColor3 = getAccentText(),
    Font = Enum.Font.BuilderSansBold,
    TextSize = 9,
})
make("UICorner", DownloadBtn, { CornerRadius = UDim.new(0, 6) })

local ImportStatus = make("TextLabel", ImportPanel, {
    Position = UDim2.fromOffset(12, 34),
    Size = UDim2.fromOffset(352, 18),
    BackgroundTransparency = 1,
    Text = "Spotify links auto-search on YouTube (no direct Spotify audio support)",
    TextColor3 = TEXT_SECONDARY,
    Font = Enum.Font.BuilderSans,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
})

local DrawerPanel = make("Frame", Root, {
    Name = "DrawerPanel",
    Position = UDim2.fromOffset(0, FULL_H + 6),
    Size = UDim2.fromOffset(PLAYER_W, 240),
    BackgroundColor3 = BG_WINDOW,
    BorderSizePixel = 0,
    Visible = false,
})
make("UICorner", DrawerPanel, { CornerRadius = UDim.new(0, 9) })
make("UIStroke", DrawerPanel, {
    Thickness = 1,
    Color = BORDER_LINE,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})

local SearchBox = make("TextBox", DrawerPanel, {
    Position = UDim2.fromOffset(10, 8),
    Size = UDim2.fromOffset(182, 22),
    BackgroundColor3 = BG_SURFACE,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "> Filter tracks or creators...",
    PlaceholderColor3 = TEXT_MUTED,
    TextColor3 = TEXT_PRIMARY,
    Font = Enum.Font.BuilderSans,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
})
make("UICorner", SearchBox, { CornerRadius = UDim.new(0, 6) })
make("UIStroke", SearchBox, {
    Thickness = 1,
    Color = BORDER_LINE,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})
make("UIPadding", SearchBox, { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })

local activeSourceFilter = "ALL"
local filterButtons = {}
local function makeFilterChip(xOff, w, label, filterKey)
    local b = make("TextButton", DrawerPanel, {
        Position = UDim2.fromOffset(xOff, 8),
        Size = UDim2.fromOffset(w, 22),
        BackgroundColor3 = (activeSourceFilter == filterKey) and getAccent() or BG_SURFACE,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = label,
        TextColor3 = (activeSourceFilter == filterKey) and getAccentText() or TEXT_SECONDARY,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 8,
    })
    make("UICorner", b, { CornerRadius = UDim.new(0, 5) })
    filterButtons[filterKey] = b
    return b
end

makeFilterChip(196, 30, "ALL", "ALL")
makeFilterChip(229, 50, "Youtube", "Youtube")
makeFilterChip(282, 40, "LOCAL", "LOCAL")

local CountBadge = make("TextLabel", DrawerPanel, {
    Position = UDim2.fromOffset(325, 8),
    Size = UDim2.fromOffset(41, 22),
    BackgroundColor3 = BG_SURFACE,
    BorderSizePixel = 0,
    Text = tostring(#songs),
    TextColor3 = TEXT_SECONDARY,
    Font = Enum.Font.BuilderSansBold,
    TextSize = 9,
})
make("UICorner", CountBadge, { CornerRadius = UDim.new(0, 5) })

local QueueScroll = make("ScrollingFrame", DrawerPanel, {
    Position = UDim2.fromOffset(10, 36),
    Size = UDim2.fromOffset(356, 194),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = TEXT_MUTED,
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
})
make("UIListLayout", QueueScroll, {
    Padding = UDim.new(0, 3),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

local SettingsPanel = make("Frame", Root, {
    Name = "SettingsPanel",
    Position = UDim2.fromOffset(0, FULL_H + 6),
    Size = UDim2.fromOffset(PLAYER_W, 196),
    BackgroundColor3 = BG_WINDOW,
    BorderSizePixel = 0,
    Visible = false,
})
make("UICorner", SettingsPanel, { CornerRadius = UDim.new(0, 9) })
make("UIStroke", SettingsPanel, {
    Thickness = 1,
    Color = BORDER_LINE,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})

local SettingsScroll = make("ScrollingFrame", SettingsPanel, {
    Position = UDim2.fromOffset(10, 10),
    Size = UDim2.fromOffset(356, 176),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = TEXT_MUTED,
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
})
make("UIListLayout", SettingsScroll, {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

local function layoutSubPanels()
    local y = FULL_H + 6
    if ImportPanel.Visible then
        ImportPanel.Position = UDim2.fromOffset(0, y)
        y += 58 + 6
    end
    if DrawerPanel.Visible then
        DrawerPanel.Position = UDim2.fromOffset(0, y)
        y += 240 + 6
    end
    if SettingsPanel.Visible then
        SettingsPanel.Position = UDim2.fromOffset(0, y)
    end
end

connect(AddBtn.Activated, function()
    ImportPanel.Visible = not ImportPanel.Visible
    layoutSubPanels()
end)

connect(QueueBtn.Activated, function()
    DrawerPanel.Visible = not DrawerPanel.Visible
    if DrawerPanel.Visible then SettingsPanel.Visible = false end
    layoutSubPanels()
end)

connect(CfgBtn.Activated, function()
    SettingsPanel.Visible = not SettingsPanel.Visible
    if SettingsPanel.Visible then DrawerPanel.Visible = false end
    layoutSubPanels()
end)

local function setMinimized(state)
    MainCard.Visible = not state
    MiniPill.Visible = state
    if state then
        ImportPanel.Visible = false
        DrawerPanel.Visible = false
        SettingsPanel.Visible = false
    end
end

connect(MiniBtn.Activated, function() setMinimized(true) end)
connect(MiniExpand.Activated, function() setMinimized(false) end)

local function makeDraggable(handle)
    local dragging, dragStart, startPos
    connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Root.Position
        end
    end)
    connect(UIS.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            Root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    connect(UIS.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

makeDraggable(TopBar)
makeDraggable(MiniPill)

local cur, playing, startedAt, pausedAt = nil, false, 0, 0
local songRows = {}

local function syncFilterChips()
    local acc = getAccent()
    local accTxt = getAccentText()
    for key, btn in pairs(filterButtons) do
        local on = (activeSourceFilter == key)
        btn.BackgroundColor3 = on and acc or BG_SURFACE
        btn.TextColor3 = on and accTxt or TEXT_SECONDARY
    end
end

local function applyThemeAccent()
    local acc = getAccent()
    local accTxt = getAccentText()
    AddBtn.BackgroundColor3 = acc
    AddBtn.TextColor3 = accTxt
    DownloadBtn.BackgroundColor3 = acc
    DownloadBtn.TextColor3 = accTxt
    setMainPlayColors(acc, accTxt)
    setMiniPlayColors(acc, accTxt)
    SeekFill.BackgroundColor3 = acc
    VolFill.BackgroundColor3 = acc
    syncModeButtons()
    syncFilterChips()
end

local function refreshQueueVisuals()
    local query = SearchBox.Text:lower()
    local shownCount = 0
    for i, sObj in ipairs(songs) do
        sObj.idx = i
        local data = songRows[sObj]
        if data then
            data.Row.LayoutOrder = i
            local isCur = (cur == sObj)
            data.Row.BackgroundColor3 = isCur and BG_ACTIVE or BG_SURFACE
            data.Title.TextColor3 = isCur and getAccent() or TEXT_PRIMARY
            data.Index.Text = isCur and (playing and "||" or "\u{25B6}") or tostring(i)
            data.Index.TextColor3 = isCur and getAccent() or TEXT_MUTED
            data.Source.Text = sObj.source or "LOCAL"

            local matchFilter = (activeSourceFilter == "ALL") or ((sObj.source or "LOCAL") == activeSourceFilter)
            local hay = (sObj.name .. " " .. (sObj.creator or "")):lower()
            local matchText = (query == "") or (hay:find(query, 1, true) ~= nil)
            local vis = matchFilter and matchText
            data.Row.Visible = vis
            if vis then
                shownCount += 1
            end
        end
    end
    CountBadge.Text = shownCount .. "/" .. #songs
end

for key, btn in pairs(filterButtons) do
    connect(btn.Activated, function()
        activeSourceFilter = key
        syncFilterChips()
        refreshQueueVisuals()
    end)
end

connect(SearchBox:GetPropertyChangedSignal("Text"), refreshQueueVisuals)

local function refreshPlayStateUI()
    setMainPlayVisual(playing)
    setMiniPlayVisual(playing)
    StatusDot.BackgroundColor3 = playing and STATUS_OK or TEXT_MUTED
    refreshQueueVisuals()
end

local playSong
playSong = function(s)
    if not s then return end
    log("PLAY_REQ", "Playing:", s.name, "| Creator:", s.creator, "| Path:", s.path)
    cur = s
    playing = true
    startedAt = os.clock()
    pausedAt = 0
    State.lastSong = s.path
    saveState()

    Sound:Stop()
    local assetId = audioOf(s)
    if assetId == "" then
        setTrackTitleText("Audio load error")
        TrackSub.Text = "Invalid audio format on disk"
        playing = false
        refreshPlayStateUI()
        return
    end

    Sound.SoundId = assetId
    Sound.TimePosition = 0
    Sound.Volume = Cfg.volume

    local cov = coverOf(s)
    local creatorText = (s.creator and #s.creator > 0) and s.creator or "Unknown Creator"
    local isYt = (s.source == "Youtube")
    local noteText = isYt and "Youtube" or (s.note or "Local Playlist")

    setTrackTitleText(s.name)
    MiniTitle.Text = s.name
    TrackSub.Text = creatorText .. "  |  " .. noteText
    TrackSub.TextColor3 = TEXT_SECONDARY
    SourceTag.Text = s.source or "LOCAL"
    CoverImg.Image = cov
    MiniArt.Image = cov
    refreshPlayStateUI()

    task.spawn(function()
        local waited = 0
        while not Sound.IsLoaded and waited < 4 and cur == s do
            waited += task.wait(0.05)
        end
        if cur ~= s then return end
        Sound:Play()
        task.wait(0.08)
        if cur == s and playing and not Sound.IsPlaying then
            Sound:Play()
        end
        log("PLAY_STATE", "IsPlaying:", Sound.IsPlaying, "| TimeLength:", Sound.TimeLength)
    end)

    local nx = songs[s.idx % #songs + 1]
    if nx then
        task.spawn(function() pcall(audioOf, nx) end)
    end
end

local function step(d)
    local n = #songs
    if n == 0 then return end
    if Cfg.loopOne and cur then
        playSong(cur)
        return
    end
    if Cfg.shuffle and n > 1 then
        local pick = songs[math.random(n)]
        while pick == cur do
            pick = songs[math.random(n)]
        end
        playSong(pick)
        return
    end
    local i = cur and cur.idx or (d > 0 and 0 or 1)
    playSong(songs[(i - 1 + d) % n + 1])
end

local function togglePlay()
    if #songs == 0 then return end
    if not cur then
        return playSong(lastSong or songs[1])
    end
    if playing then
        pausedAt = Sound.TimePosition
        playing = false
        Sound:Pause()
    else
        Sound.TimePosition = pausedAt
        Sound:Resume()
        if not Sound.IsPlaying then
            Sound:Play()
        end
        playing = true
    end
    refreshPlayStateUI()
end

connect(PrevBtn.Activated, function() step(-1) end)
connect(PlayCircle.Activated, togglePlay)
connect(NextBtn.Activated, function() step(1) end)
connect(MiniPrev.Activated, function() step(-1) end)
connect(MiniPlay.Activated, togglePlay)
connect(MiniNext.Activated, function() step(1) end)

connect(ShuffleBtn.Activated, function()
    Cfg.shuffle = not Cfg.shuffle
    State.shuffle = Cfg.shuffle
    syncModeButtons()
    saveState()
end)

connect(LoopBtn.Activated, function()
    Cfg.loopOne = not Cfg.loopOne
    State.loopOne = Cfg.loopOne
    syncModeButtons()
    saveState()
end)

connect(Sound.Ended, function()
    if playing and os.clock() - startedAt > 0.5 then
        step(1)
    end
end)

local seeking, seekFrac = false, 0
local function seekFracAt(x)
    return math.clamp((x - SeekTrack.AbsolutePosition.X) / math.max(SeekTrack.AbsoluteSize.X, 1), 0, 1)
end

local function fmtTime(s)
    s = math.max(0, math.floor(s))
    return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

connect(SeekHit.InputBegan, function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and cur then
        seeking = true
        seekFrac = seekFracAt(input.Position.X)
    end
end)
connect(UIS.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if seeking then
            seekFrac = seekFracAt(input.Position.X)
        end
        if seekHovering or seeking then
            local f = seekFracAt(input.Position.X)
            local len = cur and Sound.TimeLength or 0
            HoverTimeTip.Text = fmtTime(f * len)
            HoverTimeTip.Position = UDim2.fromOffset(112 + f * 250, 46)
        end
    end
end)
connect(UIS.InputEnded, function(input)
    if seeking and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        seeking = false
        local len = Sound.TimeLength
        if cur and len > 0 then
            local t = math.min(seekFrac * len, math.max(0, len - 0.05))
            if playing then
                Sound.TimePosition = t
            else
                pausedAt = t
            end
        end
    end
end)

local volDragging = false
local function setVolumeFromX(x)
    local frac = math.clamp((x - VolTrack.AbsolutePosition.X) / math.max(VolTrack.AbsoluteSize.X, 1), 0, 1)
    VolFill.Size = UDim2.fromScale(frac, 1)
    Cfg.volume = math.floor(frac * 200 + 0.5) / 100
    Sound.Volume = Cfg.volume
    VolPct.Text = math.floor(frac * 100 + 0.5) .. "%"
    updateSpeakerVisual(Cfg.volume)
    State.volume = Cfg.volume
    saveState()
end

connect(VolHit.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        volDragging = true
        setVolumeFromX(input.Position.X)
    end
end)
connect(UIS.InputChanged, function(input)
    if volDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        setVolumeFromX(input.Position.X)
    end
end)
connect(UIS.InputEnded, function(input)
    if volDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        volDragging = false
    end
end)

local eqSmooth = table.create(EQ_COUNT, 0)
connect(RS.RenderStepped, function(dt)
    local len = cur and Sound.TimeLength or 0
    local pos = seeking and (seekFrac * len) or (cur and (playing and Sound.TimePosition or pausedAt) or 0)
    local ratio = len > 0 and math.clamp(pos / len, 0, 1) or 0
    SeekFill.Size = UDim2.fromScale(ratio, 1)
    SeekKnob.Position = UDim2.fromScale(ratio, 0.5)
    TimeNow.Text = fmtTime(pos)
    TimeEnd.Text = fmtTime(len)

    if titleScrollOverflow > 0 then
        local elapsed = os.clock() - titleSetTime
        if elapsed > 1.5 then
            local cycle = (elapsed - 1.5) * 26
            local span = titleScrollOverflow + 24
            local phase = cycle % (span * 2)
            local offset = phase <= span and math.min(titleScrollOverflow, phase) or math.max(0, span * 2 - phase)
            TrackTitle.Position = UDim2.fromOffset(-offset, 0)
        end
    end

    local t = os.clock()
    local loud = playing and math.clamp(Sound.PlaybackLoudness / 300, 0, 1) or 0
    local acc = getAccent()
    for i = 1, EQ_COUNT do
        local wave = playing and (0.4 + 0.6 * math.abs(math.sin(t * (5.5 + i * 0.7) + i * 1.1))) or 0
        local target = loud * wave
        eqSmooth[i] += (target - eqSmooth[i]) * math.min(1, dt * 16)
        local h = math.max(2, math.floor(2 + eqSmooth[i] * 22))
        eqBars[i].Size = UDim2.fromOffset(3, h)
        if Cfg.rainbow then
            eqBars[i].BackgroundColor3 = Color3.fromHSV((t * 0.2 + i / EQ_COUNT) % 1, 0.75, 1)
        else
            eqBars[i].BackgroundColor3 = acc
        end
    end
end)

local function addPlaylistRow(sObj)
    if songRows[sObj] then return end
    local row = make("TextButton", QueueScroll, {
        Size = UDim2.new(1, -4, 0, 28),
        BackgroundColor3 = BG_SURFACE,
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
        TextColor3 = TEXT_MUTED,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 10,
    })

    local title = make("TextLabel", row, {
        Position = UDim2.fromOffset(28, 0),
        Size = UDim2.new(1, -112, 1, 0),
        BackgroundTransparency = 1,
        Text = sObj.name,
        TextColor3 = TEXT_PRIMARY,
        Font = Enum.Font.BuilderSans,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local srcBadge = make("TextLabel", row, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -28, 0.5, 0),
        Size = UDim2.fromOffset(50, 16),
        BackgroundColor3 = BG_WINDOW,
        BorderSizePixel = 0,
        Text = sObj.source or "LOCAL",
        TextColor3 = TEXT_MUTED,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 8,
    })
    make("UICorner", srcBadge, { CornerRadius = UDim.new(0, 4) })

    local delBtn = make("TextButton", row, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = BG_WINDOW,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "\u{00D7}",
        TextColor3 = TEXT_MUTED,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 10,
    })
    make("UICorner", delBtn, { CornerRadius = UDim.new(0, 4) })

    connect(delBtn.MouseEnter, function()
        delBtn.TextColor3 = STATUS_ERR
    end)
    connect(delBtn.MouseLeave, function()
        delBtn.TextColor3 = TEXT_MUTED
    end)
    connect(delBtn.Activated, function()
        if cur == sObj then
            Sound:Stop()
            playing = false
            cur = nil
            setTrackTitleText("No track playing")
            TrackSub.Text = "Track removed"
            TrackSub.TextColor3 = TEXT_SECONDARY
            SourceTag.Text = "IDLE"
            refreshPlayStateUI()
        end
        pcall(delfile, sObj.path)
        if sObj.coverPath then pcall(delfile, sObj.coverPath) end
        local idxPos = table.find(songs, sObj)
        if idxPos then table.remove(songs, idxPos) end
        songRows[sObj] = nil
        row:Destroy()
        refreshPlayStateUI()
    end)

    connect(row.MouseEnter, function()
        if cur ~= sObj then row.BackgroundColor3 = BG_ELEVATED end
    end)
    connect(row.MouseLeave, function()
        if cur ~= sObj then row.BackgroundColor3 = BG_SURFACE end
    end)
    connect(row.Activated, function()
        playSong(sObj)
    end)

    songRows[sObj] = {
        Row = row,
        Index = idxLbl,
        Title = title,
        Source = srcBadge,
    }
    refreshQueueVisuals()
end

for _, s in ipairs(songs) do
    addPlaylistRow(s)
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
    return raw:match("[?&]v=([%w_%-]+)")
        or raw:match("youtu%.be/([%w_%-]+)")
        or raw:match("shorts/([%w_%-]+)")
        or raw:match("embed/([%w_%-]+)")
        or raw:match("^([%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-])$")
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
            Body = HttpService:JSONEncode(bodyTbl),
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
            local outPath = DIR_COVERS .. "/" .. fileBase .. ext
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
    local oembed = safeGet("https://open.spotify.com/oembed?url=" .. HttpService:UrlEncode(trackUrl), { ["Accept"] = "application/json" })
    if not (oembed and oembed.Body) then return nil end

    local ok, data = pcall(function() return HttpService:JSONDecode(oembed.Body) end)
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

    local okT, tokData = pcall(function() return HttpService:JSONDecode(tokRes.Body) end)
    local token = okT and type(tokData) == "table" and tokData.accessToken
    if type(token) ~= "string" or #token < 10 then return nil end

    local searchUrl = "https://api.spotify.com/v1/search?type=track&limit=3&q=" .. HttpService:UrlEncode(cleanQuery)
    local sRes = safeGet(searchUrl, {
        ["Authorization"] = "Bearer " .. token,
        ["Accept"] = "application/json",
    })
    if not (sRes and sRes.Body) then return nil end

    local okS, sData = pcall(function() return HttpService:JSONDecode(sRes.Body) end)
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

local function searchYoutubeVideoId(query)
    local encoded = HttpService:UrlEncode(query)

    local ytHtml = safeGet("https://www.youtube.com/results?search_query=" .. encoded)
    if ytHtml and ytHtml.Body then
        local vid = ytHtml.Body:match('"videoRenderer"%s*:%s*{%s*"videoId"%s*:%s*"([%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-])"')
            or ytHtml.Body:match('"videoId"%s*:%s*"([%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-][%w_%-])"')
        if vid then
            return vid
        end
    end

    local searchApis = {
        "https://pipedapi.kavin.rocks/search?q=" .. encoded .. "&filter=videos",
        "https://inv.nadeko.net/api/v1/search?q=" .. encoded .. "&type=video",
    }
    for _, ep in ipairs(searchApis) do
        local res = safeGet(ep, { ["Accept"] = "application/json" })
        if res and res.Body then
            local ok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if ok and type(data) == "table" then
                local list = data.items or data
                if type(list) == "table" and list[1] then
                    local id = list[1].videoId or (list[1].url and list[1].url:match("v=([%w_%-]+)"))
                    if id and #id == 11 then
                        return id
                    end
                end
            end
        end
    end
    return nil
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

local downloadingTrack = false
local function importTrackFromInput(rawInput)
    if downloadingTrack then return end
    if not httpRequest then
        ImportStatus.Text = "Executor lacks http_request support!"
        ImportStatus.TextColor3 = STATUS_ERR
        return
    end

    rawInput = (rawInput or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if #rawInput < 4 then
        ImportStatus.Text = "Paste a valid Spotify or YouTube link."
        ImportStatus.TextColor3 = STATUS_ERR
        return
    end

    downloadingTrack = true
    DownloadBtn.Text = "..."

    local cleanId = nil
    local spotifyMeta = nil
    local fromSpotifyLink = false
    local resolvedTitle = nil
    local resolvedCreator = nil

    local spTrackId = extractSpotifyTrackId(rawInput)
    if spTrackId then
        fromSpotifyLink = true
        ImportStatus.Text = "No Spotify support - searching on YouTube..."
        ImportStatus.TextColor3 = STATUS_WARN
        spotifyMeta = fetchSpotifyTrackById(spTrackId)

        if not spotifyMeta then
            ImportStatus.Text = "Could not read Spotify track metadata."
            ImportStatus.TextColor3 = STATUS_ERR
            DownloadBtn.Text = "DOWNLOAD"
            downloadingTrack = false
            return
        end

        resolvedTitle = spotifyMeta.title
        resolvedCreator = spotifyMeta.creator
        ImportStatus.Text = "No Spotify support - searching YouTube for: " .. resolvedTitle
        ImportStatus.TextColor3 = STATUS_WARN
        cleanId = searchYoutubeVideoId(spotifyMeta.searchQuery)

        if not cleanId then
            ImportStatus.Text = "No Spotify support - track not found on YouTube."
            ImportStatus.TextColor3 = STATUS_ERR
            DownloadBtn.Text = "DOWNLOAD"
            downloadingTrack = false
            return
        end
    else
        cleanId = extractVideoId(rawInput)
        if not cleanId then
            ImportStatus.Text = "Invalid link or ID! Use Spotify or YouTube."
            ImportStatus.TextColor3 = STATUS_ERR
            DownloadBtn.Text = "DOWNLOAD"
            downloadingTrack = false
            return
        end
    end

    for _, s in ipairs(songs) do
        if s.ytId == cleanId or s.path:find(cleanId, 1, true) then
            ImportStatus.Text = "Already in queue! Playing..."
            ImportStatus.TextColor3 = STATUS_OK
            DownloadBtn.Text = "DOWNLOAD"
            downloadingTrack = false
            playSong(s)
            return
        end
    end

    local watchUrl = "https://www.youtube.com/watch?v=" .. cleanId
    local metaRes = safeGet("https://www.youtube.com/oembed?url=" .. HttpService:UrlEncode(watchUrl) .. "&format=json")
    if metaRes and metaRes.Body then
        local okM, meta = pcall(function() return HttpService:JSONDecode(metaRes.Body) end)
        if okM and type(meta) == "table" then
            if not resolvedTitle and meta.title then
                resolvedTitle = cleanFileName(meta.title)
            end
            if not resolvedCreator and meta.author_name then
                resolvedCreator = cleanFileName(meta.author_name)
            end
        end
    end

    if not fromSpotifyLink and resolvedTitle then
        ImportStatus.Text = "Checking track metadata..."
        ImportStatus.TextColor3 = TEXT_PRIMARY
        spotifyMeta = tryMatchOnSpotify(resolvedTitle)
        if spotifyMeta then
            if spotifyMeta.title then resolvedTitle = spotifyMeta.title end
            if spotifyMeta.creator then resolvedCreator = spotifyMeta.creator end
        end
    end

    local encodedWatch = HttpService:UrlEncode(watchUrl)
    local audioPayload, audioExt = nil, nil

    local keyParam = (Cfg.apiKey ~= "") and ("&apikey=" .. HttpService:UrlEncode(Cfg.apiKey)) or ""
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
        ImportStatus.Text = string.format("Downloading from Youtube (%s %d/%d)...", tc.name, idx, #transcoders)
        log("YT_TRANSCODE", "Starting job on:", tc.name)

        local initRes = safeGet(tc.init, { ["Referer"] = tc.ref, ["Accept"] = "application/json, */*" })
        if initRes and initRes.Body then
            local okJ, initData = pcall(function() return HttpService:JSONDecode(initRes.Body) end)
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
                    ImportStatus.Text = string.format("Converting Youtube MP3 (%d%%)...", pct)

                    local pRes = safeGet(pollUrl, { ["Referer"] = tc.ref })
                    if pRes and pRes.Body then
                        local okP, pData = pcall(function() return HttpService:JSONDecode(pRes.Body) end)
                        if okP and type(pData) == "table" then
                            if type(pData.download_url) == "string" and #pData.download_url > 10 then
                                ImportStatus.Text = "Saving MP3 to YouTube Downloads..."
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
        ImportStatus.Text = "Trying fallback Youtube server..."
        local vJob = safePostJson("https://api.vevioz.com/api/v1/jobs", {
            url = watchUrl,
            format = "mp3",
            quality = "128",
        })
        if vJob and vJob.Body then
            local okV, vData = pcall(function() return HttpService:JSONDecode(vJob.Body) end)
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
                            local okS, sData = pcall(function() return HttpService:JSONDecode(st.Body) end)
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
        ImportStatus.Text = "Failed to download audio from Youtube."
        ImportStatus.TextColor3 = STATUS_ERR
        DownloadBtn.Text = "DOWNLOAD"
        downloadingTrack = false
        return
    end

    local displayTitle = resolvedTitle or ("YouTube_" .. cleanId)
    local displayCreator = resolvedCreator or "YouTube Creator"
    local safeBase = cleanFileName(displayTitle) or ("yt_" .. cleanId)
    local savePath = DIR_YT .. "/" .. safeBase .. "." .. audioExt

    writefile(savePath, audioPayload)

    local testAsset = asset(savePath)
    if testAsset == "" then
        pcall(delfile, savePath)
        safeBase = "yt_" .. cleanId
        savePath = DIR_YT .. "/" .. safeBase .. "." .. audioExt
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
        dir = DIR_YT,
        source = srcLabel,
        note = transparencyNote,
        ytId = cleanId,
        coverPath = thumbPath,
        audio = testAsset,
    }

    songs[#songs + 1] = songObj
    songObj.idx = #songs
    addPlaylistRow(songObj)

    LinkInput.Text = ""
    if fromSpotifyLink then
        ImportStatus.Text = "No Spotify support - searched & downloaded from Youtube!"
        ImportStatus.TextColor3 = STATUS_WARN
    else
        ImportStatus.Text = "Downloaded from Youtube."
        ImportStatus.TextColor3 = STATUS_OK
    end

    DownloadBtn.Text = "DOWNLOAD"
    downloadingTrack = false

    playSong(songObj)
end

connect(DownloadBtn.Activated, function()
    task.spawn(function()
        importTrackFromInput(LinkInput.Text)
    end)
end)

connect(LinkInput.FocusLost, function(enterPressed)
    if enterPressed and LinkInput.Text ~= "" then
        task.spawn(function()
            importTrackFromInput(LinkInput.Text)
        end)
    end
end)

local hideKey = State.hideKey and Enum.KeyCode[State.hideKey] or nil
local listeningKey = false

local function addSettingRow(labelText, btnText, onClick)
    local row = make("Frame", SettingsScroll, {
        Size = UDim2.new(1, -4, 0, 26),
        BackgroundColor3 = BG_SURFACE,
        BorderSizePixel = 0,
    })
    make("UICorner", row, { CornerRadius = UDim.new(0, 6) })

    make("TextLabel", row, {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -110, 1, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = TEXT_PRIMARY,
        Font = Enum.Font.BuilderSans,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local btn = make("TextButton", row, {
        Position = UDim2.new(1, -96, 0.5, -9),
        Size = UDim2.fromOffset(88, 18),
        BackgroundColor3 = BG_ELEVATED,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = btnText,
        TextColor3 = TEXT_PRIMARY,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 9,
    })
    make("UICorner", btn, { CornerRadius = UDim.new(0, 4) })
    connect(btn.Activated, function()
        onClick(btn)
    end)
    return btn
end

addSettingRow("Accent Theme", Cfg.spotifyGreen and "Spotify Green" or "Client White", function(btn)
    Cfg.spotifyGreen = not Cfg.spotifyGreen
    State.spotifyGreen = Cfg.spotifyGreen
    btn.Text = Cfg.spotifyGreen and "Spotify Green" or "Client White"
    applyThemeAccent()
    refreshPlayStateUI()
    saveState()
end)

addSettingRow("Rainbow Visualizer", Cfg.rainbow and "ON" or "OFF", function(btn)
    Cfg.rainbow = not Cfg.rainbow
    State.rainbow = Cfg.rainbow
    btn.Text = Cfg.rainbow and "ON" or "OFF"
    saveState()
end)

local scaleCycle = { 0.85, 1.0, 1.15, 1.3 }
addSettingRow("Player Scale", math.floor(Cfg.scale * 100 + 0.5) .. "%", function(btn)
    local nextS = scaleCycle[1]
    for i, v in ipairs(scaleCycle) do
        if math.abs(v - Cfg.scale) < 0.05 then
            nextS = scaleCycle[(i % #scaleCycle) + 1]
            break
        end
    end
    Cfg.scale = nextS
    State.scale = nextS
    btn.Text = math.floor(nextS * 100 + 0.5) .. "%"
    tween(RootScale, 0.2, { Scale = nextS })
    saveState()
end)

addSettingRow("Toggle UI Keybind", hideKey and hideKey.Name or "None", function(btn)
    listeningKey = true
    btn.Text = "Press key..."
    local conn
    conn = UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            listeningKey = false
            hideKey = (input.KeyCode ~= Enum.KeyCode.Escape) and input.KeyCode or nil
            State.hideKey = hideKey and hideKey.Name or nil
            btn.Text = hideKey and hideKey.Name or "None"
            saveState()
            conn:Disconnect()
        end
    end)
end)

do
    local row = make("Frame", SettingsScroll, {
        Size = UDim2.new(1, -4, 0, 26),
        BackgroundColor3 = BG_SURFACE,
        BorderSizePixel = 0,
    })
    make("UICorner", row, { CornerRadius = UDim.new(0, 6) })

    make("TextLabel", row, {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.fromOffset(92, 26),
        BackgroundTransparency = 1,
        Text = "API Key (Optional)",
        TextColor3 = TEXT_PRIMARY,
        Font = Enum.Font.BuilderSans,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local keyBox = make("TextBox", row, {
        Position = UDim2.new(1, -226, 0.5, -9),
        Size = UDim2.fromOffset(218, 18),
        BackgroundColor3 = BG_WINDOW,
        BorderSizePixel = 0,
        Text = Cfg.apiKey,
        PlaceholderText = "savenow.to key...",
        PlaceholderColor3 = TEXT_MUTED,
        TextColor3 = TEXT_PRIMARY,
        Font = Enum.Font.BuilderSans,
        TextSize = 10,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
    })
    make("UICorner", keyBox, { CornerRadius = UDim.new(0, 4) })
    connect(keyBox.FocusLost, function()
        Cfg.apiKey = keyBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        State.apiKey = Cfg.apiKey
        saveState()
    end)
end

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

connect(CloseBtn.Activated, function()
    tween(Sound, 0.25, { Volume = 0 })
    task.wait(0.25)
    cleanup()
end)

connect(UIS.InputBegan, function(input, gp)
    if gp or listeningKey or not hideKey or UIS:GetFocusedTextBox() then return end
    if input.KeyCode == hideKey then
        Gui.Enabled = not Gui.Enabled
    end
end)

log("INIT", "xzyp music player ready.")
