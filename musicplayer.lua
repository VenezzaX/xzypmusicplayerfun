--!nocheck
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
    LYRICS_MAX_W = 660,
    LYRICS_FONT_SIZE = 33,
    LYRICS_LINE_H = 38,
    LYRIC_MAX_DUR_DIFF = 4.0,
    CONCISE_MAX_CHARS = 44,
}

local PATHS = {
    BASE = "xzyp",
    LOCAL = "xzyp/Local Playlist",
    YT = "xzyp/YouTube Downloads",
    COVERS = "xzyp/Covers",
    LYRICS = "xzyp/Lyrics",
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
    LYRIC_PURPLE = Color3.fromRGB(138, 102, 255),
    LYRIC_STROKE = Color3.fromRGB(14, 10, 28),
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

local UI: any = {
    AddBtn = nil,
    CfgBtn = nil,
    CloseBtn = nil,
    CountBadge = nil,
    CoverImg = nil,
    DownloadBtn = nil,
    DrawerPanel = nil,
    Gui = nil,
    HoverTimeTip = nil,
    ImportPanel = nil,
    ImportStatus = nil,
    LinkInput = nil,
    LoopBtn = nil,
    LyricsAnchor = nil,
    LyricsBtn = nil,
    LyricsCinemaBg = nil,
    LyricsLayer = nil,
    LyricsNextPreview = nil,
    MainCard = nil,
    MiniArt = nil,
    MiniBtn = nil,
    MiniExpand = nil,
    MiniNext = nil,
    MiniPill = nil,
    MiniPlay = nil,
    MiniPrev = nil,
    MiniTitle = nil,
    NextBtn = nil,
    PlayCircle = nil,
    PrevBtn = nil,
    QueueBtn = nil,
    QueueScroll = nil,
    Root = nil,
    RootScale = nil,
    SearchBox = nil,
    SearchResultsScroll = nil,
    SeekFill = nil,
    SeekHit = nil,
    SeekKnob = nil,
    SeekTrack = nil,
    SettingsPanel = nil,
    SettingsScroll = nil,
    ShuffleBtn = nil,
    SourceTag = nil,
    StatusDot = nil,
    SubtleLyricNotice = nil,
    SubtleNoticeStroke = nil,
    TimeEnd = nil,
    TimeNow = nil,
    TopBar = nil,
    TrackSub = nil,
    TrackTitle = nil,
    VolFill = nil,
    VolHit = nil,
    VolPct = nil,
    VolTrack = nil,
    setMainPlayColors = nil,
    setMainPlayVisual = nil,
    setMiniPlayColors = nil,
    setMiniPlayVisual = nil,
    updateSpeakerVisual = nil,
}
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
    lyricCues = {},
    lyricTrack = nil,
    lyricStateKey = "",
    lyricIsPauseCue = false,
    lyricStatus = "IDLE",
    lyricMatchLabel = "Idle",
    lyricSourceName = "",
    lyricStatusRowBtn = nil,
    subtleNoticeExpire = 0,
    lastSyncPos = 0,
    silenceTimer = 0,
    activeGlyphs = {},
    exitingGlyphs = {},
    activeLyricStyle = "kinetic",
    lyricLineProgress = 0,
    lyricNextPreviewText = "",
    lyricLineCounter = 0,
}

local httpRequest = nil
if type(syn) == "table" and type(syn.request) == "function" then
    httpRequest = syn.request
elseif type(request) == "function" then
    httpRequest = request
elseif type(http_request) == "function" then
    httpRequest = http_request
elseif type(http) == "table" and type(http.request) == "function" then
    httpRequest = http.request
end

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
    local setclip = nil
    if type(setclipboard) == "function" then
        setclip = setclipboard
    elseif type(toclipboard) == "function" then
        setclip = toclipboard
    elseif type(Clipboard) == "table" and type(Clipboard.set) == "function" then
        setclip = Clipboard.set
    end

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
    if src == dst or not isfile(src) then
        return false
    end
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
    if isfile(path) then
        return true
    end
    local ok = pcall(function()
        local data = game:HttpGet(url)
        if png then
            assert(data:sub(2, 4) == "PNG")
        else
            assert(#data > 4096)
        end
        writefile(path, data)
    end)
    return ok
end

local State = {
    titles = {},
    meta = {},
    noLyrics = {},
    rainbow = true,
    spotifyGreen = false,
    shuffle = false,
    loopOne = false,
    lyrics = true,
    lyricPurple = true,
    lyricPauseMode = "notes",
    lyricTranslate = "off",
    lyricFont = "modern",
    lyricStyle = "kinetic",
    lyricOffset = 0,
    scale = 1,
    volume = 1.14,
    apiKey = "",
    sttKey = "",
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
    mkdir(PATHS.LYRICS)
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
    if type(State.titles) ~= "table" then
        State.titles = {}
    end
    if type(State.meta) ~= "table" then
        State.meta = {}
    end
    if type(State.noLyrics) ~= "table" then
        State.noLyrics = {}
    end
    if type(State.lyricFont) ~= "string" or State.lyricFont == "" or State.lyricFont == "auto" then
        State.lyricFont = "modern"
    end
    if type(State.lyricStyle) ~= "string" or State.lyricStyle == "" then
        State.lyricStyle = "kinetic"
    end

    local legacyPlaylistDir = PATHS.BASE .. "/Your Playlist"
    if isfolder(legacyPlaylistDir) then
        local okList, oldFiles = pcall(listfiles, legacyPlaylistDir)
        if okList and type(oldFiles) == "table" then
            for _, oldPath in ipairs(oldFiles) do
                if not isfolder(oldPath) then
                    local fname = oldPath:match("([^/\\]+)$")
                    local ext = fname and fname:match("%.(%w+)$")
                    if ext then
                        ext = ext:lower()
                    end
                    if fname and ext then
                        local baseNoExt = fname:match("^(.+)%.%w+$") or fname
                        if CFG.IMAGE_EXTENSIONS[ext] then
                            moveFileSafe(oldPath, PATHS.COVERS .. "/" .. fname)
                        elseif CFG.EXTENSIONS[ext] then
                            local isYtFile = (baseNoExt:match("^yt_[%w_%-]+$") ~= nil)
                                or (State.titles[baseNoExt] ~= nil)
                                or (State.meta[baseNoExt] ~= nil)
                            local targetFolder = PATHS.LOCAL
                            if isYtFile then
                                targetFolder = PATHS.YT
                            end
                            moveFileSafe(oldPath, targetFolder .. "/" .. fname)
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

local savedPauseMode = "notes"
if State.lyricPauseMode == "note" or State.lyricPauseMode == "off" then
    savedPauseMode = State.lyricPauseMode
end

local savedTranslateMode = "off"
if State.lyricTranslate == "pt" or State.lyricTranslate == "en" or State.lyricTranslate == "es" then
    savedTranslateMode = State.lyricTranslate
end

local savedLyricFont = "modern"
if type(State.lyricFont) == "string" and State.lyricFont ~= "" and State.lyricFont ~= "auto" then
    savedLyricFont = State.lyricFont
end

local savedLyricStyle = "kinetic"
if type(State.lyricStyle) == "string" and State.lyricStyle ~= "" then
    savedLyricStyle = State.lyricStyle
end

local savedApiKey = ""
if type(State.apiKey) == "string" then
    savedApiKey = State.apiKey
end

local savedSttKey = ""
if type(State.sttKey) == "string" then
    savedSttKey = State.sttKey
end

local Opts = {
    rainbow = State.rainbow ~= false,
    spotifyGreen = State.spotifyGreen == true,
    shuffle = State.shuffle == true,
    loopOne = State.loopOne == true,
    lyrics = State.lyrics ~= false,
    lyricPurple = State.lyricPurple ~= false,
    lyricPauseMode = savedPauseMode,
    lyricTranslate = savedTranslateMode,
    lyricFont = savedLyricFont,
    lyricStyle = savedLyricStyle,
    lyricOffset = math.clamp(tonumber(State.lyricOffset) or 0, -5, 5),
    scale = math.clamp(tonumber(State.scale) or 1, 0.75, 1.35),
    volume = math.clamp(tonumber(State.volume) or 1.14, 0, 2),
    apiKey = savedApiKey,
    sttKey = savedSttKey,
}

if type(State.hideKey) == "string" and State.hideKey ~= "" then
    RT.hideKey = Enum.KeyCode[State.hideKey]
else
    RT.hideKey = nil
end

local function getAccent()
    if Opts.spotifyGreen then
        return CLR.SPOTIFY_GREEN
    end
    return CLR.CLIENT_WHITE
end

local function getAccentText()
    return Color3.fromRGB(6, 6, 8)
end

local function getLyricColor()
    if Opts.lyricPurple then
        return CLR.LYRIC_PURPLE
    end
    return getAccent()
end

local function getPauseIndicatorText()
    if Opts.lyricPauseMode == "note" then
        return "\u{266A}"
    elseif Opts.lyricPauseMode == "off" then
        return nil
    end
    return "\u{266A}  \u{2022} \u{2022} \u{2022}  \u{266A}"
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
        pcall(function()
            c:Disconnect()
        end)
    end
    for i = #RT.collection, 1, -1 do
        pcall(function()
            RT.collection[i]:Destroy()
        end)
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

local SKIP_DIRS = { icons = true, [".cache"] = true, system = true, covers = true, lyrics = true }

local function scanDir(dir, depth)
    local ok, files = pcall(listfiles, dir)
    if (not ok or type(files) ~= "table") and dir == "" then
        ok, files = pcall(listfiles, ".")
    end
    if not ok or type(files) ~= "table" then
        return
    end

    local list, dirs, covers = {}, {}, {}
    for _, path in ipairs(files) do
        if isfolder(path) then
            local last = norm(path):match("([^/]+)$")
            if not (last and SKIP_DIRS[last:lower()]) then
                dirs[#dirs + 1] = path
            end
        else
            local ext = path:match("%.(%w+)$")
            if ext then
                ext = ext:lower()
            end
            if ext and CFG.EXTENSIONS[ext] then
                local rawBase = path:match("([^/\\]+)%.%w+$") or "Unknown Track"
                local ytIdMatch = rawBase:match("^yt_([%w_%-]+)$")
                local savedMeta = State.meta[rawBase]
                if not savedMeta and ytIdMatch then
                    savedMeta = State.meta[ytIdMatch]
                end

                if not ytIdMatch and type(savedMeta) == "table" and type(savedMeta.ytId) == "string" and #savedMeta.ytId == 11 then
                    ytIdMatch = savedMeta.ytId
                end

                local savedTitle = nil
                if type(savedMeta) == "table" and savedMeta.title then
                    savedTitle = savedMeta.title
                elseif State.titles[rawBase] then
                    savedTitle = State.titles[rawBase]
                elseif ytIdMatch and State.titles[ytIdMatch] then
                    savedTitle = State.titles[ytIdMatch]
                end

                local displayName = savedTitle or rawBase
                local inYtDir = norm(dir):find("YouTube Downloads", 1, true) ~= nil
                local savedSrc = nil
                if type(savedMeta) == "table" then
                    savedSrc = savedMeta.source
                end
                local isYt = inYtDir or (ytIdMatch ~= nil) or (savedTitle ~= nil) or (savedSrc == "YT" or savedSrc == "SP+YT" or savedSrc == "Youtube")

                local creatorVal = "Local Audio"
                if type(savedMeta) == "table" and savedMeta.creator then
                    creatorVal = savedMeta.creator
                elseif isYt then
                    creatorVal = "YouTube Creator"
                end

                local sourceVal = "LOCAL"
                local noteVal = "Local Playlist"
                if isYt then
                    sourceVal = "Youtube"
                    noteVal = "Youtube"
                end

                list[#list + 1] = {
                    path = path,
                    name = displayName,
                    creator = creatorVal,
                    dir = dir,
                    source = sourceVal,
                    note = noteVal,
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

local scanRoot = PATHS.BASE
if type(getgenv) == "function" then
    local envTbl = getgenv()
    if type(envTbl) == "table" and envTbl.ScanWholeWorkspace then
        scanRoot = ""
    end
end
scanDir(scanRoot, 0)
log("SCAN", "Initial songs loaded:", #RT.songs)

for _, s in ipairs(RT.songs) do
    if s.path == State.lastSong then
        RT.lastSong = s
        break
    end
end

local function asset(p)
    local ok, r = pcall(getcustomasset, p)
    if ok and type(r) == "string" and r ~= "" then
        return r
    end
    return ""
end

if isfile(PATHS.FALLBACK) then
    RT.defaultCover = asset(PATHS.FALLBACK)
else
    RT.defaultCover = ""
end

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
    local stateStr = "FAILED"
    if res ~= "" then
        stateStr = res
    end
    log("AUDIO_ASSET", "getcustomasset:", s.path, "->", stateStr)
    s.audio = res
    return res
end

local function coverOf(s)
    if not s then
        return RT.defaultCover
    end
    if s.coverPath and isfile(s.coverPath) then
        local a = asset(s.coverPath)
        if a ~= "" then
            return a
        end
    end
    local baseName = s.path:match("([^/\\]+)%.%w+$")
    if baseName then
        for _, ext in ipairs({ "png", "jpg", "jpeg", "webp" }) do
            local centralCover = PATHS.COVERS .. "/" .. baseName .. "." .. ext
            if isfile(centralCover) then
                s.coverPath = centralCover
                local a = asset(centralCover)
                if a ~= "" then
                    return a
                end
            end
            if s.ytId then
                local idCover = PATHS.COVERS .. "/yt_" .. s.ytId .. "." .. ext
                if isfile(idCover) then
                    s.coverPath = idCover
                    local a = asset(idCover)
                    if a ~= "" then
                        return a
                    end
                end
            end
            if s.dir then
                local localCover = s.dir .. "/" .. baseName .. "." .. ext
                if isfile(localCover) then
                    s.coverPath = localCover
                    local a = asset(localCover)
                    if a ~= "" then
                        return a
                    end
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

local function cleanFileName(str)
    if not str or #str == 0 then
        return nil
    end
    str = str:gsub("&amp;", "&"):gsub("&quot;", '"'):gsub("&#39;", "'"):gsub("&lt;", "<"):gsub("&gt;", ">")
    str = str:gsub('[\\/:%*%?"<>|%c]', "")
    str = str:gsub("^%s+", ""):gsub("%s+$", "")
    if #str > 64 then
        str = str:sub(1, 64):gsub("%s+$", "")
    end
    if #str > 0 then
        return str
    end
    return nil
end

local function base64Decode(data)
    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = tostring(data or ""):gsub("[^" .. b .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then
            return ""
        end
        local r, f = "", (b:find(x, 1, true) - 1)
        for i = 6, 1, -1 do
            local bit = (f % 2 ^ i - f % 2 ^ (i - 1) > 0) and "1" or "0"
            r = r .. bit
        end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then
            return ""
        end
        local c = 0
        for i = 1, 8 do
            if x:sub(i, i) == "1" then
                c = c + 2 ^ (8 - i)
            end
        end
        return string.char(c)
    end))
end

local function safeGet(url, extraHeaders)
    if not httpRequest then
        return nil
    end
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
    if ok then
        return res
    end
    return nil
end

local function safePostJson(url, bodyTbl, extraHeaders)
    if not httpRequest then
        return nil
    end
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
    if ok then
        return res
    end
    return nil
end

local function extractJsonObject(str, startPos)
    local openIdx = str:find("{", startPos, true)
    if not openIdx then
        return nil
    end
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
    if type(node) ~= "table" or #outList >= 8 then
        return
    end
    local vr = node.videoRenderer
    if type(vr) == "table" and type(vr.videoId) == "string" and #vr.videoId == 11 and not seenIds[vr.videoId] then
        local titleRuns = vr.title and vr.title.runs
        local titleStr = nil
        if type(titleRuns) == "table" and titleRuns[1] then
            titleStr = titleRuns[1].text
        end
        if titleStr then
            local ownerRuns = nil
            if vr.ownerText and vr.ownerText.runs then
                ownerRuns = vr.ownerText.runs
            elseif vr.longBylineText and vr.longBylineText.runs then
                ownerRuns = vr.longBylineText.runs
            end
            local creatorStr = "YouTube Creator"
            if type(ownerRuns) == "table" and ownerRuns[1] and ownerRuns[1].text then
                creatorStr = ownerRuns[1].text
            end
            local durStr = ""
            local durSec = 0
            if vr.lengthText and vr.lengthText.simpleText then
                durStr = vr.lengthText.simpleText
                local mStr, sStr = durStr:match("^(%d+):(%d+)$")
                if mStr and sStr then
                    durSec = (tonumber(mStr) or 0) * 60 + (tonumber(sStr) or 0)
                end
            end
            seenIds[vr.videoId] = true
            outList[#outList + 1] = {
                id = vr.videoId,
                title = cleanFileName(titleStr) or titleStr,
                creator = cleanFileName(creatorStr) or creatorStr,
                duration = durStr,
                durationSec = durSec,
            }
        end
    end
    for _, v in pairs(node) do
        if type(v) == "table" then
            collectVideoRenderers(v, outList, seenIds)
            if #outList >= 8 then
                return
            end
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
        local okJ, parsed = pcall(function()
            return SRV.Http:JSONDecode(ytApiRes.Body)
        end)
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
                if not vrMarker then
                    break
                end
                local block = extractJsonObject(ytHtml.Body, vrMarker)
                if block then
                    local okB, vrObj = pcall(function()
                        return SRV.Http:JSONDecode(block)
                    end)
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
            if #results > 0 then
                break
            end
            local res = safeGet(ep, { ["Accept"] = "application/json" })
            if res and res.Body then
                local ok, data = pcall(function()
                    return SRV.Http:JSONDecode(res.Body)
                end)
                if ok and type(data) == "table" then
                    local list = data.items or data
                    if type(list) == "table" then
                        for _, item in ipairs(list) do
                            if type(item) == "table" then
                                local id = item.videoId
                                if not id and type(item.url) == "string" then
                                    id = item.url:match("v=([%w_%-]+)")
                                end
                                local title = item.title
                                if id and #id == 11 and title and not seen[id] then
                                    seen[id] = true
                                    local dur = ""
                                    local sec = tonumber(item.duration or item.lengthSeconds) or 0
                                    if sec > 0 then
                                        dur = fmtTime(sec)
                                    end
                                    local authorStr = item.uploaderName or item.author or "YouTube Creator"
                                    results[#results + 1] = {
                                        id = id,
                                        title = cleanFileName(title) or title,
                                        creator = cleanFileName(authorStr) or "YouTube Creator",
                                        duration = dur,
                                        durationSec = sec,
                                    }
                                    if #results >= 8 then
                                        break
                                    end
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

-- ============================================================================
-- MULTI-SOURCE LYRICS, CREATOR DESCRIPTION, TRANSLATION & STT ENGINE
-- ============================================================================

local Lyrics = {}

local ACCENT_FOLD = {
    ["á"] = "a", ["à"] = "a", ["â"] = "a", ["ã"] = "a", ["ä"] = "a", ["å"] = "a",
    ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e",
    ["í"] = "i", ["ì"] = "i", ["î"] = "i", ["ï"] = "i",
    ["ó"] = "o", ["ò"] = "o", ["ô"] = "o", ["õ"] = "o", ["ö"] = "o",
    ["ú"] = "u", ["ù"] = "u", ["û"] = "u", ["ü"] = "u",
    ["ç"] = "c", ["ñ"] = "n",
    ["Á"] = "a", ["À"] = "a", ["Â"] = "a", ["Ã"] = "a", ["Ä"] = "a", ["Å"] = "a",
    ["É"] = "e", ["È"] = "e", ["Ê"] = "e", ["Ë"] = "e",
    ["Í"] = "i", ["Ì"] = "i", ["Î"] = "i", ["Ï"] = "i",
    ["Ó"] = "o", ["Ò"] = "o", ["Ô"] = "o", ["Õ"] = "o", ["Ö"] = "o",
    ["Ú"] = "u", ["Ù"] = "u", ["Û"] = "u", ["Ü"] = "u",
    ["Ç"] = "c", ["Ñ"] = "n",
}

function Lyrics.normalizeText(str)
    local s = tostring(str or "")
    s = s:gsub("[\194-\244][\128-\191]*", function(ch)
        if ACCENT_FOLD[ch] then
            return ACCENT_FOLD[ch]
        end
        return ch
    end)
    s = s:lower()
    s = s:gsub("&", " and ")
    s = s:gsub("[%p%c]", " ")
    s = s:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

function Lyrics.exactMatchNormalized(a, b)
    local nA = Lyrics.normalizeText(a)
    local nB = Lyrics.normalizeText(b)
    if #nA > 0 and nA == nB then
        return true
    end
    local compactA = nA:gsub("%s+", "")
    local compactB = nB:gsub("%s+", "")
    return #compactA > 0 and compactA == compactB
end

function Lyrics.levenshteinRatio(a, b)
    local s1 = Lyrics.normalizeText(a):gsub("%s+", "")
    local s2 = Lyrics.normalizeText(b):gsub("%s+", "")
    local len1, len2 = #s1, #s2
    if len1 == 0 and len2 == 0 then
        return 1
    end
    if len1 == 0 or len2 == 0 then
        return 0
    end
    if s1 == s2 then
        return 1
    end
    if len1 > 80 then
        s1 = s1:sub(1, 80)
        len1 = 80
    end
    if len2 > 80 then
        s2 = s2:sub(1, 80)
        len2 = 80
    end

    local prev = {}
    for j = 0, len2 do
        prev[j] = j
    end
    for i = 1, len1 do
        local cur = { [0] = i }
        local b1 = s1:byte(i)
        for j = 1, len2 do
            local cost = 1
            if b1 == s2:byte(j) then
                cost = 0
            end
            local del = prev[j] + 1
            local ins = cur[j - 1] + 1
            local sub = prev[j - 1] + cost
            local m = del
            if ins < m then
                m = ins
            end
            if sub < m then
                m = sub
            end
            cur[j] = m
        end
        prev = cur
    end
    local maxLen = math.max(len1, len2)
    return 1 - (prev[len2] / maxLen)
end

local STOP_WORDS = {
    official = true, audio = true, video = true, lyrics = true, lyric = true,
    letra = true, letras = true, legendado = true, traducao = true, paroles = true,
    testo = true, songtext = true, lirik = true, sub = true, espanol = true,
    hd = true, hq = true, mv = true, visualizer = true, feat = true, ft = true,
    featuring = true, prod = true, by = true, topic = true, vevo = true,
    music = true, records = true, channel = true, tv = true, full = true,
    song = true, track = true, version = true, explicit = true, clean = true,
    pt = true, br = true,
}

function Lyrics.tokenize(str)
    local set = {}
    local list = {}
    local clean = Lyrics.normalizeText((tostring(str or ""):gsub("%b()", " "):gsub("%b[]", " ")))
    for w in clean:gmatch("%S+") do
        if not STOP_WORDS[w] and #w >= 2 and not set[w] then
            set[w] = true
            list[#list + 1] = w
        end
    end
    return set, list
end

function Lyrics.strictTokenCompare(strA, strB)
    if Lyrics.exactMatchNormalized(strA, strB) then
        return 1.0, 1.0, 1.0
    end
    local _setA, listA = Lyrics.tokenize(strA)
    local setB, listB = Lyrics.tokenize(strB)
    if #listA == 0 or #listB == 0 then
        return 0, 0, 0
    end

    local inter = 0
    for _, w in ipairs(listA) do
        if setB[w] then
            inter += 1
        end
    end

    if inter == 0 then
        return 0, 0, 0
    end

    local union = #listA + #listB - inter
    local jaccard = inter / math.max(1, union)
    local recallA = inter / #listA
    local recallB = inter / #listB
    local lev = Lyrics.levenshteinRatio(strA, strB)

    local score = (jaccard * 0.55) + (math.min(recallA, recallB) * 0.30) + (lev * 0.15)
    return score, jaccard, lev
end

function Lyrics.getVersionTags(str)
    local low = Lyrics.normalizeText(str)
    local tags = {}
    if low:find("slowed", 1, true) then
        tags.slowed = true
    end
    if low:find("sped up", 1, true) or low:find("speed up", 1, true) or low:find("nightcore", 1, true) then
        tags.spedup = true
    end
    if low:find("instrumental", 1, true) or low:find("karaoke", 1, true) or low:find("no vocals", 1, true) then
        tags.instrumental = true
    end
    if low:find("remix", 1, true) or low:find("bootleg", 1, true) or low:find("mashup", 1, true) or low:find("vip", 1, true) then
        tags.remix = true
    end
    if low:find("acoustic", 1, true) or low:find("acustico", 1, true) then
        tags.acoustic = true
    end
    if low:find("live", 1, true) or low:find("ao vivo", 1, true) then
        tags.live = true
    end
    if low:find("cover", 1, true) then
        tags.cover = true
    end
    if low:find("8d", 1, true) or low:find("bass boosted", 1, true) then
        tags.fx = true
    end
    return tags
end

function Lyrics.versionsConflict(tagsA, tagsB)
    local keys = { "slowed", "spedup", "instrumental", "remix", "acoustic", "live", "cover", "fx" }
    for _, k in ipairs(keys) do
        local a = tagsA[k] == true
        local b = tagsB[k] == true
        if a ~= b then
            return true
        end
    end
    return false
end

local GENERIC_UPLOADERS = {
    ["youtube creator"] = true,
    ["local audio"] = true,
    ["spotify artist"] = true,
    ["7clouds"] = true,
    ["trap nation"] = true,
    ["chill nation"] = true,
    ["bass nation"] = true,
    ["mrsuicidesheep"] = true,
    ["cloudkid"] = true,
    ["proximity"] = true,
    ["nocopyrightsounds"] = true,
    ["ncs"] = true,
    ["audio library"] = true,
    ["gr6 explode"] = true,
    ["kondzilla"] = true,
    ["love funk"] = true,
}

function Lyrics.isGenericChannel(creatorStr)
    local n = Lyrics.normalizeText(creatorStr)
    if n == "" or GENERIC_UPLOADERS[n] then
        return true
    end
    if n:find("lyrics", 1, true) or n:find("lyric", 1, true) or n:find("letra", 1, true) or n:find("vibes", 1, true) then
        return true
    end
    if n:find("slowed", 1, true) or n:find("nightcore", 1, true) or n:find("sped up", 1, true) then
        return true
    end
    return false
end

function Lyrics.stripTitleNoise(raw)
    local s = tostring(raw or "")
    s = s:gsub("%b()", " ")
    s = s:gsub("%b[]", " ")
    s = s:gsub("[Oo]fficial%s*[Vv]ideo", " ")
    s = s:gsub("[Oo]fficial%s*[Aa]udio", " ")
    s = s:gsub("[Ll]yric%s*[Vv]ideo", " ")
    s = s:gsub("[Ll]yrics?", " ")
    s = s:gsub("[Ll]etras?", " ")
    s = s:gsub("[Ll]egendado", " ")
    s = s:gsub("[Pp]aroles", " ")
    s = s:gsub("[Tt]esto", " ")
    s = s:gsub("[Ss]ongtext", " ")
    s = s:gsub("[Ll]irik", " ")
    s = s:gsub("歌詞", " ")
    s = s:gsub("가사", " ")
    s = s:gsub("歌词", " ")
    s = s:gsub("[Vv]isualizer", " ")
    s = s:gsub("[Pp]rod%.?%s+[%w%s,&%-]+$", " ")
    s = s:gsub("[Ff]t%.?%s+[%w%s,&%-]+$", " ")
    s = s:gsub("[Ff]eat%.?%s+[%w%s,&%-]+$", " ")
    s = s:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

-- ============================================================================
-- 1. EXTRACT METADATA & EMBEDDED LYRICS DIRECTLY FROM THE AUDIO FILE ITSELF
-- ============================================================================

function Lyrics.extractEmbeddedAudioMeta(filePath)
    if not filePath or not isfile(filePath) then
        return nil
    end
    local ok, bytes = pcall(readfile, filePath)
    if not ok or type(bytes) ~= "string" or #bytes < 128 then
        return nil
    end

    local result = {}
    local head = bytes:sub(1, math.min(#bytes, 65536))

    -- ID3v2 Tag Parser (MP3)
    if head:sub(1, 3) == "ID3" then
        local ver = head:byte(4) or 3
        local b6, b7, b8, b9 = head:byte(7) or 0, head:byte(8) or 0, head:byte(9) or 0, head:byte(10) or 0
        local tagSize = (b6 * 2097152) + (b7 * 16384) + (b8 * 128) + b9
        local limit = math.min(#head, 10 + tagSize)
        local pos = 11

        while pos + 10 <= limit do
            local frameId = head:sub(pos, pos + 3)
            if not frameId:match("^[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]$") then
                break
            end
            local s1, s2, s3, s4 = head:byte(pos + 4) or 0, head:byte(pos + 5) or 0, head:byte(pos + 6) or 0, head:byte(pos + 7) or 0
            local fSize = 0
            if ver == 4 then
                fSize = (s1 * 2097152) + (s2 * 16384) + (s3 * 128) + s4
            else
                fSize = (s1 * 16777216) + (s2 * 65536) + (s3 * 256) + s4
            end
            if fSize <= 0 or pos + 10 + fSize > limit + 1 then
                break
            end
            local payload = head:sub(pos + 10, pos + 9 + fSize)
            local _enc = payload:byte(1) or 0
            local textBody = payload:sub(2):gsub("%z+", " ")

            if frameId == "TIT2" and #textBody > 1 then
                result.title = Lyrics.stripTitleNoise(textBody)
            elseif frameId == "TPE1" and #textBody > 1 then
                result.artist = Lyrics.stripTitleNoise(textBody)
            elseif frameId == "USLT" and #textBody > 12 then
                -- Skip 3-byte language code + content descriptor
                local afterLang = textBody:sub(4):gsub("^%s+", "")
                if #afterLang > 15 then
                    result.embeddedLyrics = afterLang
                end
            end
            pos = pos + 10 + fSize
        end
    end

    -- ID3v1 Fallback (last 128 bytes of MP3)
    if not result.title and #bytes >= 128 then
        local tail = bytes:sub(-128)
        if tail:sub(1, 3) == "TAG" then
            local t1 = tail:sub(4, 33):gsub("%z+", ""):gsub("^%s+", ""):gsub("%s+$", "")
            local a1 = tail:sub(34, 63):gsub("%z+", ""):gsub("^%s+", ""):gsub("%s+$", "")
            if #t1 >= 2 then
                result.title = Lyrics.stripTitleNoise(t1)
            end
            if #a1 >= 2 then
                result.artist = Lyrics.stripTitleNoise(a1)
            end
        end
    end

    -- OGG Vorbis Comments Parser
    if head:sub(1, 4) == "OggS" then
        local lowHead = head:lower()
        local tStart = lowHead:find("title=", 1, true)
        if tStart then
            local rawT = head:sub(tStart + 6, tStart + 80):match("^([^\r\n%z]+)")
            if rawT and #rawT >= 2 then
                result.title = Lyrics.stripTitleNoise(rawT)
            end
        end
        local aStart = lowHead:find("artist=", 1, true)
        if aStart then
            local rawA = head:sub(aStart + 7, aStart + 80):match("^([^\r\n%z]+)")
            if rawA and #rawA >= 2 then
                result.artist = Lyrics.stripTitleNoise(rawA)
            end
        end
        local lStart = lowHead:find("lyrics=", 1, true)
        if lStart then
            local rawL = head:sub(lStart + 7, lStart + 4096):match("^([^%z]+)")
            if rawL and #rawL >= 15 then
                result.embeddedLyrics = rawL
            end
        end
    end

    if result.title or result.artist or result.embeddedLyrics then
        return result
    end
    return nil
end

function Lyrics.parseTrackIdentity(songObj)
    local rawTitle = tostring(songObj.name or "")
    local rawCreator = tostring(songObj.creator or "")
    local versionTags = Lyrics.getVersionTags(rawTitle)

    local stripped = Lyrics.stripTitleNoise(rawTitle)
    local dashArtist, dashTitle = stripped:match("^(.-)%s+[%-%–%—]%s+(.+)$")

    local title = stripped
    local artist = ""
    local artistReliable = false

    if dashArtist and dashTitle and #dashArtist >= 2 and #dashTitle >= 2 then
        artist = Lyrics.stripTitleNoise(dashArtist)
        title = Lyrics.stripTitleNoise(dashTitle)
        artistReliable = not Lyrics.isGenericChannel(artist)
    else
        local cleanCreator = rawCreator:gsub("%s*%-%s*Topic$", ""):gsub("VEVO$", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if not Lyrics.isGenericChannel(cleanCreator) then
            artist = cleanCreator
            artistReliable = true
        end
    end

    -- Enrich from embedded audio file tags (ID3 / Vorbis) if available
    local embedded = Lyrics.extractEmbeddedAudioMeta(songObj.path)
    if embedded then
        if embedded.title and #embedded.title >= 2 then
            title = embedded.title
        end
        if embedded.artist and #embedded.artist >= 2 and not Lyrics.isGenericChannel(embedded.artist) then
            artist = embedded.artist
            artistReliable = true
        end
    end

    if #title < 1 then
        title = rawTitle
    end

    local _, titleTokens = Lyrics.tokenize(title)
    return {
        rawTitle = rawTitle,
        title = title,
        artist = artist,
        artistReliable = artistReliable,
        titleWordCount = #titleTokens,
        versionTags = versionTags,
        embeddedLyrics = embedded and embedded.embeddedLyrics or nil,
    }
end

-- ============================================================================
-- CONCISE LINE SPLITTER & AUTO-TRANSLATION HELPER
-- ============================================================================

function Lyrics.makeConciseLines(cues)
    if type(cues) ~= "table" or #cues == 0 then
        return {}
    end
    local concise = {}
    for _, c in ipairs(cues) do
        local txt = tostring(c.text or ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        if #txt > 0 then
            if #txt <= CFG.CONCISE_MAX_CHARS then
                concise[#concise + 1] = {
                    time = c.time,
                    endTime = c.endTime,
                    text = txt,
                }
            else
                -- Split long sentences into 2 punchy, rhythmic phrases
                local words = {}
                for w in txt:gmatch("%S+") do
                    words[#words + 1] = w
                end
                if #words <= 2 then
                    concise[#concise + 1] = {
                        time = c.time,
                        endTime = c.endTime,
                        text = txt:sub(1, CFG.CONCISE_MAX_CHARS),
                    }
                else
                    local mid = math.ceil(#words * 0.5)
                    local part1 = table.concat(words, " ", 1, mid)
                    local part2 = table.concat(words, " ", mid + 1, #words)
                    local totalSpan = math.max(0.8, (c.endTime or (c.time + 2.5)) - c.time)
                    local ratio = #part1 / math.max(1, #part1 + #part2)
                    local splitTime = c.time + (totalSpan * ratio)

                    concise[#concise + 1] = {
                        time = c.time,
                        endTime = math.max(c.time + 0.35, splitTime - 0.06),
                        text = part1,
                    }
                    concise[#concise + 1] = {
                        time = splitTime,
                        endTime = math.max(splitTime + 0.35, c.time + totalSpan),
                        text = part2,
                    }
                end
            end
        end
    end
    return concise
end

function Lyrics.translateCues(cues, targetLang)
    if not httpRequest or type(cues) ~= "table" or #cues == 0 then
        return cues
    end
    if targetLang == "off" or targetLang == "" then
        return cues
    end

    local out = {}
    for i, c in ipairs(cues) do
        out[i] = { time = c.time, endTime = c.endTime, text = c.text }
    end

    local batchSize = 18
    for startIdx = 1, #out, batchSize do
        local endIdx = math.min(#out, startIdx + batchSize - 1)
        local lines = {}
        for i = startIdx, endIdx do
            lines[#lines + 1] = out[i].text
        end
        local joined = table.concat(lines, "\n")
        local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl="
            .. SRV.Http:UrlEncode(targetLang)
            .. "&dt=t&q="
            .. SRV.Http:UrlEncode(joined)

        local res = safeGet(url, { ["Accept"] = "application/json" })
        if res and res.Body then
            local okJ, parsed = pcall(function()
                return SRV.Http:JSONDecode(res.Body)
            end)
            if okJ and type(parsed) == "table" and type(parsed[1]) == "table" then
                local translatedBlob = {}
                for _, seg in ipairs(parsed[1]) do
                    if type(seg) == "table" and type(seg[1]) == "string" then
                        translatedBlob[#translatedBlob + 1] = seg[1]
                    end
                end
                local fullStr = table.concat(translatedBlob, "")
                local splitLines = {}
                for ln in (fullStr .. "\n"):gmatch("([^\n]*)\n") do
                    splitLines[#splitLines + 1] = ln:gsub("^%s+", ""):gsub("%s+$", "")
                end
                for offset = 0, (endIdx - startIdx) do
                    local tLine = splitLines[offset + 1]
                    if tLine and #tLine >= 1 then
                        out[startIdx + offset].text = tLine
                    end
                end
            end
        end
    end

    return Lyrics.makeConciseLines(out)
end

-- ============================================================================
-- VISUAL FEEDBACK & NON-DESTRUCTIVE BUTTON STATE
-- ============================================================================

function Lyrics.showSubtleNotice(msg)
    if not UI.SubtleLyricNotice or not msg or msg == "" then
        return
    end
    local bounds = SRV.TXT:GetTextSize(msg, 10, Enum.Font.BuilderSans, Vector2.new(1000, 20)).X
    UI.SubtleLyricNotice.Size = UDim2.fromOffset(math.clamp(bounds + 24, 150, CFG.PLAYER_W), 20)
    UI.SubtleLyricNotice.Text = msg
    UI.SubtleLyricNotice.TextTransparency = 1
    UI.SubtleLyricNotice.BackgroundTransparency = 1
    if UI.SubtleNoticeStroke then
        UI.SubtleNoticeStroke.Transparency = 1
    end
    UI.SubtleLyricNotice.Visible = true
    RT.subtleNoticeExpire = os.clock() + 3.0

    tween(UI.SubtleLyricNotice, 0.22, {
        TextTransparency = 0.08,
        BackgroundTransparency = 0.16,
    })
    if UI.SubtleNoticeStroke then
        tween(UI.SubtleNoticeStroke, 0.22, { Transparency = 0.2 })
    end
end

function Lyrics.syncButtonVisual()
    if not UI.LyricsBtn then
        return
    end
    local stroke = UI.LyricsBtn:FindFirstChildOfClass("UIStroke")

    if not Opts.lyrics then
        -- Explicitly turned OFF by user
        UI.LyricsBtn.BackgroundColor3 = CLR.BG_SURFACE
        UI.LyricsBtn.TextColor3 = CLR.TEXT_MUTED
        if stroke then
            stroke.Color = CLR.BORDER_LINE
            stroke.Transparency = 0
        end
        return
    end

    -- Opts.lyrics is ON (never auto-disabled!)
    if RT.cur == nil or #RT.lyricCues > 0 then
        UI.LyricsBtn.BackgroundColor3 = getAccent()
        UI.LyricsBtn.TextColor3 = getAccentText()
        if stroke then
            stroke.Color = getAccent()
            stroke.Transparency = 1
        end
    elseif RT.lyricStatus == "SEARCHING" then
        UI.LyricsBtn.BackgroundColor3 = CLR.BG_ELEVATED
        UI.LyricsBtn.TextColor3 = CLR.TEXT_PRIMARY
        if stroke then
            stroke.Color = getAccent()
            stroke.Transparency = 0.35
        end
    else
        -- Lyrics ON, but current song has no lyrics: dark gray pill with subtle accent border so user knows it's still ON
        UI.LyricsBtn.BackgroundColor3 = CLR.BG_SURFACE
        UI.LyricsBtn.TextColor3 = CLR.TEXT_SECONDARY
        if stroke then
            stroke.Color = getAccent()
            stroke.Transparency = 0.45
        end
    end
end

function Lyrics.setStatus(code, shortBadge, subtleMsg, col, showSubtleBanner)
    RT.lyricStatus = code
    RT.lyricMatchLabel = shortBadge
    if RT.lyricStatusRowBtn and RT.lyricStatusRowBtn.Parent then
        RT.lyricStatusRowBtn.Text = shortBadge
        RT.lyricStatusRowBtn.TextColor3 = col or CLR.TEXT_PRIMARY
    end
    Lyrics.syncButtonVisual()

    if showSubtleBanner and Opts.lyrics and subtleMsg and subtleMsg ~= "" then
        Lyrics.showSubtleNotice(subtleMsg)
    end
end

function Lyrics.clearGlyphs(immediate)
    if immediate then
        for i = #RT.activeGlyphs, 1, -1 do
            local g = RT.activeGlyphs[i]
            if g.label then
                pcall(function()
                    g.label:Destroy()
                end)
            end
            RT.activeGlyphs[i] = nil
        end
        for i = #RT.exitingGlyphs, 1, -1 do
            local g = RT.exitingGlyphs[i]
            if g.label then
                pcall(function()
                    g.label:Destroy()
                end)
            end
            RT.exitingGlyphs[i] = nil
        end
        return
    end

    local total = #RT.activeGlyphs
    for i = total, 1, -1 do
        local g = RT.activeGlyphs[i]
        RT.activeGlyphs[i] = nil

        local radialFactor = math.clamp(g.targetX / 160, -1.6, 1.6)
        local glyphNum = g.glyphIdx or i
        local spinDir = 1
        if glyphNum % 2 ~= 0 then
            spinDir = -1
        end
        local peelOrder = i - 1
        if g.isPause then
            peelOrder = math.abs(i - (total + 1) * 0.5)
        end

        g.vx = radialFactor * math.random(85, 140) + (math.random() - 0.5) * 48
        g.vy = -math.random(40, 100) - math.abs(radialFactor) * 18
        g.gravity = math.random(220, 320)
        g.vRot = spinDir * math.random(105, 225)
        g.breakDelay = math.min(0.11, peelOrder * 0.008)
        g.exitAge = 0
        g.exitLife = 0.42 + math.random() * 0.12
        g.startAlpha = g.alpha or 0
        g.startScale = g.scale or 1
        g.endScale = 0.42 + math.random() * 0.18
        RT.exitingGlyphs[#RT.exitingGlyphs + 1] = g
    end
end

-- ============================================================================
-- DYNAMIC & CUSTOMIZABLE LYRIC FONT STYLES
-- ============================================================================

Lyrics.FONT_ORDER = {
    "modern",
    "auto",
    "anime",
    "marker",
    "serif",
    "mono",
    "pixel",
    "handwritten",
    "heavy",
}

Lyrics.FONT_PRESETS = {
    auto = { label = "Auto Mix", font = Enum.Font.BuilderSansBold, scale = 1.0 },
    modern = { label = "Modern Bold", font = Enum.Font.BuilderSansBold, scale = 1.0 },
    anime = { label = "Anime Pop", font = Enum.Font.FredokaOne, scale = 1.04 },
    marker = { label = "Street Marker", font = Enum.Font.PermanentMarker, scale = 1.06 },
    serif = { label = "Poetic Serif", font = Enum.Font.Merriweather, scale = 0.94 },
    mono = { label = "Cyber Mono", font = Enum.Font.RobotoMono, scale = 0.92 },
    pixel = { label = "Retro Pixel", font = Enum.Font.Arcade, scale = 0.72 },
    handwritten = { label = "Handwritten", font = Enum.Font.IndieFlower, scale = 1.12 },
    heavy = { label = "Heavy Impact", font = Enum.Font.GothamBlack, scale = 0.96 },
}

RT.lyricLineCounter = RT.lyricLineCounter or 0

function Lyrics.resolveLineFont(text, isPauseCue)
    if isPauseCue then
        return Enum.Font.BuilderSansBold, 1.0
    end

    local mode = Opts.lyricFont or "modern"
    if mode ~= "auto" then
        local preset = Lyrics.FONT_PRESETS[mode]
        if not preset then
            preset = Lyrics.FONT_PRESETS.modern
        end
        return preset.font, preset.scale
    end

    -- Auto Mix: picks a fitting font style based on the line's expression & structure
    RT.lyricLineCounter = (RT.lyricLineCounter or 0) + 1
    local raw = tostring(text or "")

    -- Whispered / backing vocals inside parentheses -> Handwritten
    if raw:match("^%(.+%)$") then
        return Enum.Font.IndieFlower, 1.12
    end

    -- Intense / shout / exclamation lines -> Street Marker or Heavy Impact
    local lettersOnly = raw:gsub("[^%a]", "")
    local isShout = (#lettersOnly >= 4 and lettersOnly == lettersOnly:upper()) or raw:find("!", 1, true) ~= nil
    if isShout then
        if RT.lyricLineCounter % 2 == 0 then
            return Enum.Font.PermanentMarker, 1.06
        end
        return Enum.Font.GothamBlack, 0.96
    end

    -- Rotating curated mix for normal verses (Modern, Anime Pop, Poetic Serif, Cyber Mono)
    local autoPool = {
        { font = Enum.Font.BuilderSansBold, scale = 1.0 },
        { font = Enum.Font.FredokaOne, scale = 1.04 },
        { font = Enum.Font.Merriweather, scale = 0.94 },
        { font = Enum.Font.RobotoMono, scale = 0.92 },
    }
    local pick = autoPool[(RT.lyricLineCounter % #autoPool) + 1]
    return pick.font, pick.scale
end

-- ============================================================================
-- DYNAMIC LYRIC VISUAL & ANIMATION STYLES ENGINE
-- ============================================================================

Lyrics.STYLE_ORDER = {
    "kinetic",
    "auto",
    "karaoke",
    "preview",
    "wave",
    "neon",
    "typewriter",
    "subtitle",
}

Lyrics.STYLE_PRESETS = {
    kinetic = { label = "Kinetic Shatter" },
    auto = { label = "Auto Vibe" },
    karaoke = { label = "Karaoke Sweep" },
    preview = { label = "Dual-Line (Next)" },
    wave = { label = "Rhythm Wave" },
    neon = { label = "Neon Pulse" },
    typewriter = { label = "Cyber Typewriter" },
    subtitle = { label = "Clean Cinema" },
}

RT.activeLyricStyle = "kinetic"
RT.lyricLineProgress = 0
RT.lyricNextPreviewText = ""

function Lyrics.resolveLineStyle(text, isPauseCue)
    if isPauseCue then
        return "kinetic"
    end

    local selected = Opts.lyricStyle or "kinetic"
    if selected ~= "auto" then
        return selected
    end

    local raw = tostring(text or "")
    local loud = Sound.PlaybackLoudness

    if raw:match("^%(.+%)$") then
        return "typewriter"
    end
    if loud >= 150 then
        return "neon"
    end
    if loud >= 95 then
        return "wave"
    end
    if #raw <= 26 then
        return "karaoke"
    end
    return "preview"
end

function Lyrics.updateNextPreviewVisual(nextText, showPreview)
    if not UI.LyricsAnchor then
        return
    end

    if not UI.LyricsNextPreview then
        local prevLbl = Instance.new("TextLabel")
        prevLbl.Name = "LyricsNextPreview"
        prevLbl.AnchorPoint = Vector2.new(0.5, 0)
        prevLbl.Position = UDim2.fromOffset(0, 34)
        prevLbl.Size = UDim2.fromOffset(CFG.LYRICS_MAX_W, 24)
        prevLbl.BackgroundTransparency = 1
        prevLbl.Text = ""
        prevLbl.TextColor3 = CLR.TEXT_PRIMARY
        prevLbl.TextTransparency = 1
        prevLbl.Font = Enum.Font.BuilderSans
        prevLbl.TextSize = 16
        prevLbl.TextTruncate = Enum.TextTruncate.AtEnd
        prevLbl.ZIndex = 1
        prevLbl.Parent = UI.LyricsAnchor

        local prevStroke = Instance.new("UIStroke")
        prevStroke.Name = "PreviewStroke"
        prevStroke.Thickness = 1.4
        prevStroke.Color = CLR.LYRIC_STROKE
        prevStroke.Transparency = 1
        prevStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        prevStroke.Parent = prevLbl

        UI.LyricsNextPreview = prevLbl
    end

    local lbl = UI.LyricsNextPreview
    local st = lbl:FindFirstChild("PreviewStroke")
    if showPreview and Opts.lyrics and type(nextText) == "string" and #nextText > 0 then
        lbl.Text = nextText
        lbl.Visible = true
        tween(lbl, 0.22, { TextTransparency = 0.42 })
        if st then
            tween(st, 0.22, { Transparency = 0.55 })
        end
    else
        lbl.Text = ""
        lbl.TextTransparency = 1
        lbl.Visible = false
        if st then
            st.Transparency = 1
        end
    end
end

function Lyrics.updateCinemaBackdrop(showBackdrop, lineCount, maxLineWidth)
    if not UI.LyricsAnchor then
        return
    end

    if not UI.LyricsCinemaBg then
        local bg = Instance.new("Frame")
        bg.Name = "LyricsCinemaBg"
        bg.AnchorPoint = Vector2.new(0.5, 0.5)
        bg.Position = UDim2.fromOffset(0, 0)
        bg.Size = UDim2.fromOffset(220, 44)
        bg.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
        bg.BackgroundTransparency = 0.32
        bg.BorderSizePixel = 0
        bg.ZIndex = 0
        bg.Visible = false
        bg.Parent = UI.LyricsAnchor

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = bg

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1
        stroke.Color = CLR.BORDER_LINE
        stroke.Transparency = 0.35
        stroke.Parent = bg

        UI.LyricsCinemaBg = bg
    end

    local bg = UI.LyricsCinemaBg
    if showBackdrop and Opts.lyrics and lineCount > 0 then
        local baseW = maxLineWidth or 200
        local w = math.clamp(baseW + 38, 140, CFG.LYRICS_MAX_W + 44)
        local h = (lineCount * CFG.LYRICS_LINE_H) + 14
        bg.Size = UDim2.fromOffset(w, h)
        bg.Visible = true
    else
        bg.Visible = false
    end
end

function Lyrics.wrapLines(text, fontEnum, fontSize)
    local activeFont = fontEnum or Enum.Font.BuilderSansBold
    local activeSize = fontSize or CFG.LYRICS_FONT_SIZE
    local words = {}
    for w in text:gmatch("%S+") do
        words[#words + 1] = w
    end
    if #words == 0 then
        return {}
    end

    local lines = {}
    local curLine = ""
    for _, w in ipairs(words) do
        local candidate = w
        if curLine ~= "" then
            candidate = curLine .. " " .. w
        end
        local wPx = SRV.TXT:GetTextSize(candidate, activeSize, activeFont, Vector2.new(4000, 100)).X
        if curLine ~= "" and wPx > CFG.LYRICS_MAX_W then
            lines[#lines + 1] = curLine
            curLine = w
        else
            curLine = candidate
        end
    end
    if curLine ~= "" then
        lines[#lines + 1] = curLine
    end
    return lines
end

function Lyrics.spawnLine(text, isPauseCue, nextLineText)
    Lyrics.clearGlyphs(false)
    if not Opts.lyrics or not UI.LyricsAnchor or not text or text == "" then
        Lyrics.updateNextPreviewVisual("", false)
        Lyrics.updateCinemaBackdrop(false, 0, 0)
        return
    end

    local styleKey = Lyrics.resolveLineStyle(text, isPauseCue)
    RT.activeLyricStyle = styleKey
    RT.lyricNextPreviewText = tostring(nextLineText or "")

    local fontEnum = Enum.Font.BuilderSansBold
    local fontScale = 1.0
    if type(Lyrics.resolveLineFont) == "function" then
        fontEnum, fontScale = Lyrics.resolveLineFont(text, isPauseCue)
    end
    if styleKey == "typewriter" and not isPauseCue then
        fontEnum = Enum.Font.RobotoMono
        fontScale = 0.94
    elseif styleKey == "subtitle" and not isPauseCue then
        fontEnum = Enum.Font.BuilderSansBold
        fontScale = 0.92
    end

    local baseSize = CFG.LYRICS_FONT_SIZE
    if isPauseCue then
        baseSize = CFG.LYRICS_FONT_SIZE - 4
    end
    local fontSize = math.max(16, math.floor(baseSize * fontScale + 0.5))

    local lines = nil
    if isPauseCue then
        lines = { text }
    else
        lines = Lyrics.wrapLines(text, fontEnum, fontSize)
    end
    if #lines == 0 then
        Lyrics.updateNextPreviewVisual("", false)
        Lyrics.updateCinemaBackdrop(false, 0, 0)
        return
    end

    -- Count non-space glyphs first for exact Karaoke / Typewriter progress fractions
    local totalGlyphs = 0
    local maxLinePx = 0
    local lineWidths = {}
    for lineIdx, lineStr in ipairs(lines) do
        local lw = SRV.TXT:GetTextSize(lineStr, fontSize, fontEnum, Vector2.new(4000, 100)).X
        lineWidths[lineIdx] = lw
        if lw > maxLinePx then
            maxLinePx = lw
        end
        for _, codepoint in utf8.codes(lineStr) do
            if utf8.char(codepoint) ~= " " then
                totalGlyphs += 1
            end
        end
    end

    -- Configure style-specific backdrop & next-line preview
    if styleKey == "subtitle" and not isPauseCue then
        Lyrics.updateCinemaBackdrop(true, #lines, maxLinePx)
    else
        Lyrics.updateCinemaBackdrop(false, 0, 0)
    end

    if styleKey == "preview" and not isPauseCue then
        local bottomOffset = (#lines * CFG.LYRICS_LINE_H * 0.5) + 8
        Lyrics.updateNextPreviewVisual(nextLineText, true)
        if UI.LyricsNextPreview then
            UI.LyricsNextPreview.Position = UDim2.fromOffset(0, bottomOffset)
        end
    else
        Lyrics.updateNextPreviewVisual("", false)
    end

    local totalH = #lines * CFG.LYRICS_LINE_H
    local startY = -totalH * 0.5 + CFG.LYRICS_LINE_H * 0.5
    local lyricCol = getLyricColor()
    local unsungCol = Color3.fromRGB(165, 162, 185)
    local globalIdx = 0

    for lineIdx, lineStr in ipairs(lines) do
        local lineW = lineWidths[lineIdx]
        local cursorX = -lineW * 0.5
        local targetY = startY + (lineIdx - 1) * CFG.LYRICS_LINE_H

        for _, codepoint in utf8.codes(lineStr) do
            local ch = utf8.char(codepoint)
            local chW = SRV.TXT:GetTextSize(ch, fontSize, fontEnum, Vector2.new(400, 100)).X
            local targetX = cursorX + chW * 0.5
            cursorX += chW

            if ch ~= " " then
                globalIdx += 1
                local charFrac = (globalIdx - 1) / math.max(1, totalGlyphs)
                local dirSign = -1
                if globalIdx % 2 == 0 then
                    dirSign = 1
                end

                local startX = targetX
                local startYPos = targetY
                local initRot = 0
                local initScale = 0.72
                local entryDelay = 0

                if styleKey == "typewriter" or styleKey == "subtitle" then
                    startX = targetX
                    startYPos = targetY + 4
                    initRot = 0
                    initScale = 0.96
                    entryDelay = 0
                elseif styleKey == "karaoke" then
                    startX = targetX
                    startYPos = targetY + 10
                    initRot = 0
                    initScale = 0.90
                    entryDelay = math.min(0.16, (globalIdx - 1) * 0.008)
                else
                    startX = targetX + (targetX * 0.1 + (math.random() - 0.5) * 14)
                    local dropAmp = 14
                    if not isPauseCue then
                        dropAmp = math.random(18, 34) * dirSign
                        initRot = dirSign * math.random(10, 18)
                    end
                    startYPos = targetY + dropAmp
                    initScale = 0.72
                    local stagger = 0.022
                    if not isPauseCue then
                        stagger = 0.013
                    end
                    entryDelay = math.min(0.24, (globalIdx - 1) * stagger)
                end

                local initialColor = lyricCol
                if styleKey == "karaoke" and not isPauseCue then
                    initialColor = unsungCol
                end

                local lbl = Instance.new("TextLabel")
                lbl.Name = "Glyph"
                lbl.AnchorPoint = Vector2.new(0.5, 0.5)
                lbl.Position = UDim2.fromOffset(startX, startYPos)
                lbl.Size = UDim2.fromOffset(math.ceil(chW) + 14, CFG.LYRICS_LINE_H + 10)
                lbl.Rotation = initRot
                lbl.BackgroundTransparency = 1
                lbl.Text = ch
                lbl.TextColor3 = initialColor
                lbl.TextTransparency = 1
                lbl.Font = fontEnum
                lbl.TextSize = fontSize
                lbl.ZIndex = 2
                lbl.Parent = UI.LyricsAnchor

                local uiScale = Instance.new("UIScale")
                uiScale.Scale = initScale
                uiScale.Parent = lbl

                local stroke = Instance.new("UIStroke")
                stroke.Thickness = 2.2
                stroke.Color = CLR.LYRIC_STROKE
                stroke.Transparency = 1
                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                stroke.Parent = lbl

                RT.activeGlyphs[#RT.activeGlyphs + 1] = {
                    label = lbl,
                    uiScale = uiScale,
                    stroke = stroke,
                    glyphIdx = globalIdx,
                    charFrac = charFrac,
                    styleKey = styleKey,
                    isPause = isPauseCue == true,
                    targetX = targetX,
                    targetY = targetY,
                    curX = startX,
                    curY = startYPos,
                    rot = initRot,
                    scale = initScale,
                    alpha = 1,
                    delay = entryDelay,
                    age = 0,
                    phase = globalIdx * 0.65,
                }
            end
        end
    end
end

-- ============================================================================
-- TIMELINE BUILDER, LRC / SRT / VTT PARSERS & PLAIN-LYRIC ALIGNER
-- ============================================================================

function Lyrics.buildTimeline(rawCues, totalDuration)
    local timeline = {}
    if type(rawCues) ~= "table" or #rawCues == 0 then
        return timeline, "EMPTY"
    end

    local nonEmptyCount = 0
    local outOfBounds = 0
    local lastCueTime = 0

    for _, cue in ipairs(rawCues) do
        if type(cue.text) == "string" and #cue.text > 0 then
            nonEmptyCount += 1
            if cue.time > lastCueTime then
                lastCueTime = cue.time
            end
            if type(totalDuration) == "number" and totalDuration > 5 and cue.time > totalDuration + 2.0 then
                outOfBounds += 1
            end
        end
    end

    if nonEmptyCount < 3 then
        return {}, "TOO_FEW_LINES"
    end

    if type(totalDuration) == "number" and totalDuration > 10 then
        if (outOfBounds / nonEmptyCount) > 0.15 then
            return {}, "LENGTH_MISMATCH"
        end
        if lastCueTime < totalDuration * 0.22 then
            return {}, "BROKEN_TIMESTAMPS"
        end
    end

    local deduped = {}
    for _, cue in ipairs(rawCues) do
        local prev = deduped[#deduped]
        if prev and math.abs(cue.time - prev.time) < 0.15 then
            if #prev.text == 0 and #cue.text > 0 then
                prev.text = cue.text
            end
        else
            deduped[#deduped + 1] = {
                time = cue.time,
                endHint = cue.endHint,
                text = cue.text or "",
            }
        end
    end

    for i, cue in ipairs(deduped) do
        local txt = cue.text
        if txt ~= "" then
            local nextCue = deduped[i + 1]
            local naturalHold = math.clamp(1.65 + #txt * 0.058, 1.8, 5.5)
            if type(cue.endHint) == "number" and cue.endHint > cue.time + 0.3 then
                naturalHold = math.clamp(cue.endHint - cue.time, 0.8, 6.0)
            end
            local endTime = cue.time + naturalHold

            if nextCue then
                local hardCeiling = math.max(cue.time + 0.35, nextCue.time - 0.10)
                if nextCue.text == "" then
                    endTime = hardCeiling
                else
                    local gap = nextCue.time - cue.time
                    if gap > naturalHold + 1.4 then
                        endTime = math.min(cue.time + naturalHold, hardCeiling)
                    else
                        endTime = hardCeiling
                    end
                end
            else
                if type(totalDuration) == "number" and totalDuration > cue.time + 1.0 then
                    endTime = math.min(cue.time + naturalHold, totalDuration - 0.35)
                end
            end

            if endTime > cue.time + 0.25 then
                timeline[#timeline + 1] = {
                    time = cue.time,
                    endTime = endTime,
                    text = txt,
                }
            end
        end
    end

    if #timeline < 3 then
        return {}, "TOO_FEW_LINES"
    end

    return Lyrics.makeConciseLines(timeline), "OK"
end

function Lyrics.parseLrc(rawLrc, totalDuration)
    local rawCues = {}
    if type(rawLrc) ~= "string" or #rawLrc == 0 then
        return rawCues, "EMPTY"
    end
    for line in rawLrc:gmatch("[^\r\n]+") do
        if not line:match("^%[%a+:") then
            local textPart = line:gsub("%[%d+:%d+%.?%d*%]", ""):gsub("^%s+", ""):gsub("%s+$", "")
            if textPart:match("^[%s%p\u{266A}\u{266B}\u{266C}]+$") then
                textPart = ""
            end
            for minStr, secStr in line:gmatch("%[(%d+):(%d+%.?%d*)%]") do
                local m = tonumber(minStr)
                local s = tonumber(secStr)
                if m and s then
                    rawCues[#rawCues + 1] = {
                        time = m * 60 + s,
                        text = textPart,
                    }
                end
            end
        end
    end
    table.sort(rawCues, function(a, b)
        if a.time == b.time then
            return #a.text > #b.text
        end
        return a.time < b.time
    end)
    return Lyrics.buildTimeline(rawCues, totalDuration)
end

function Lyrics.parseSrtOrVtt(rawText, totalDuration)
    local rawCues = {}
    if type(rawText) ~= "string" or #rawText < 10 then
        return rawCues, "EMPTY"
    end
    local normalized = rawText:gsub("\r\n", "\n"):gsub("\r", "\n")
    for block in (normalized .. "\n\n"):gmatch("(.-)\n\n+") do
        local tLine = block:match("(%d+:%d+[:%.]%d+[,%.]%d+%s*%-%->%s*%d+:%d+[:%.]%d+[,%.]%d+)")
        if tLine then
            local s1, s2 = tLine:match("^(.-)%s*%-%->%s*(.-)$")
            local function parseTimestamp(ts)
                ts = ts:gsub(",", "."):gsub("^%s+", ""):gsub("%s+$", "")
                local h, m, s = ts:match("^(%d+):(%d+):([%d%.]+)$")
                if h and m and s then
                    return (tonumber(h) or 0) * 3600 + (tonumber(m) or 0) * 60 + (tonumber(s) or 0)
                end
                local m2, s2n = ts:match("^(%d+):([%d%.]+)$")
                if m2 and s2n then
                    return (tonumber(m2) or 0) * 60 + (tonumber(s2n) or 0)
                end
                return nil
            end
            local startSec = parseTimestamp(s1 or "")
            local endSec = parseTimestamp(s2 or "")
            local textBody = block:gsub("^.-%-%->[^\n]*\n?", ""):gsub("<[^>]+>", " "):gsub("\n", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            if startSec and #textBody >= 2 then
                rawCues[#rawCues + 1] = {
                    time = startSec,
                    endHint = endSec or (startSec + 2.5),
                    text = textBody,
                }
            end
        end
    end
    return Lyrics.buildTimeline(rawCues, totalDuration)
end

-- Align plain lyrics (from Creator Description / ID3 USLT / Lyrics.ovh) onto vocal windows
function Lyrics.alignPlainLyrics(rawPlain, totalDuration, vocalAnchorCues)
    local lines = {}
    for ln in tostring(rawPlain or ""):gmatch("[^\r\n]+") do
        local clean = ln:gsub("%b[]", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        if #clean >= 2 and not clean:match("^[%p%s\u{266A}\u{266B}]+$") then
            lines[#lines + 1] = clean
        end
    end
    if #lines < 3 then
        return {}, "TOO_FEW_LINES"
    end

    -- If we have real spoken/vocal anchor cues from the video's STT/captions, map plain lines onto those active windows
    if type(vocalAnchorCues) == "table" and #vocalAnchorCues >= 3 then
        local firstStart = vocalAnchorCues[1].time
        local lastEnd = vocalAnchorCues[#vocalAnchorCues].endTime or (vocalAnchorCues[#vocalAnchorCues].time + 2.5)
        local span = math.max(8, lastEnd - firstStart)
        local totalChars = 0
        for _, l in ipairs(lines) do
            totalChars += math.max(4, #l)
        end
        local rawCues = {}
        local cursor = firstStart
        for _, l in ipairs(lines) do
            local share = (math.max(4, #l) / totalChars) * span
            rawCues[#rawCues + 1] = {
                time = cursor,
                endHint = cursor + math.max(1.2, share * 0.92),
                text = l,
            }
            cursor += share
        end
        return Lyrics.buildTimeline(rawCues, totalDuration)
    end

    local dur = (type(totalDuration) == "number" and totalDuration > 12) and totalDuration or (#lines * 3.0)
    local introSkip = math.clamp(dur * 0.07, 2.0, 12.0)
    local outroTrim = math.clamp(dur * 0.08, 2.0, 12.0)
    local usable = math.max(10, dur - introSkip - outroTrim)

    local totalChars = 0
    for _, l in ipairs(lines) do
        totalChars += math.max(4, #l)
    end

    local rawCues = {}
    local cursor = introSkip
    for _, l in ipairs(lines) do
        local share = (math.max(4, #l) / totalChars) * usable
        rawCues[#rawCues + 1] = {
            time = cursor,
            endHint = cursor + math.max(1.3, share * 0.90),
            text = l,
        }
        cursor += share
    end

    return Lyrics.buildTimeline(rawCues, totalDuration)
end

function Lyrics.cuesToLrcString(cues, sourceTag)
    local out = { "[by:xzyp-" .. tostring(sourceTag or "sync") .. "]" }
    for _, c in ipairs(cues) do
        local m = math.floor(c.time / 60)
        local s = c.time - (m * 60)
        out[#out + 1] = string.format("[%02d:%05.2f]%s", m, s, c.text)
    end
    return table.concat(out, "\n")
end

-- ============================================================================
-- SOURCE 2 & 3: YOUTUBE PLAYER INFO, CREATOR DESCRIPTION LYRICS & CAPTIONS
-- ============================================================================

function Lyrics.extractDescriptionLyrics(desc)
    if type(desc) ~= "string" or #desc < 40 then
        return nil
    end
    if desc:find("Provided to YouTube by", 1, true) then
        return nil
    end

    local lines = {}
    for rawLn in desc:gmatch("[^\r\n]+") do
        local ln = rawLn:gsub("^%s+", ""):gsub("%s+$", "")
        lines[#lines + 1] = ln
    end

    local lyricStartIdx = nil
    for i, ln in ipairs(lines) do
        local low = ln:lower()
        if low:match("^letra%s*:?$") or low:match("^lyrics%s*:?$") or low:match("^%[verse") or low:match("^%[verso") or low:match("^%[chorus") or low:match("^%[refrao") then
            lyricStartIdx = i + 1
            break
        end
    end

    local collected = {}
    local startScan = lyricStartIdx or 1
    for i = startScan, #lines do
        local ln = lines[i]
        local low = ln:lower()
        local isSpam = low:find("http", 1, true)
            or low:find("instagram", 1, true)
            or low:find("spotify", 1, true)
            or low:find("tiktok", 1, true)
            or low:find("inscreva", 1, true)
            or low:find("subscribe", 1, true)
            or low:find("prod%.", 1, true)
            or low:find("mixagem", 1, true)
            or low:find("master", 1, true)
            or low:find("direção", 1, true)
            or low:find("ficha tecnica", 1, true)
            or low:match("^#")

        if isSpam then
            if #collected >= 6 then
                break
            end
            if not lyricStartIdx then
                collected = {}
            end
        elseif #ln >= 2 and #ln <= 72 then
            collected[#collected + 1] = ln
        elseif #ln == 0 and #collected >= 12 then
            -- Keep verse breaks inside lyric block
        end
    end

    if #collected >= 5 then
        return table.concat(collected, "\n")
    end
    return nil
end

function Lyrics.fetchYoutubePlayerInfo(videoId)
    if not videoId or #videoId ~= 11 or not httpRequest then
        return nil
    end

    local pRes = safePostJson("https://www.youtube.com/youtubei/v1/player?prettyPrint=false", {
        context = {
            client = {
                clientName = "ANDROID",
                clientVersion = "19.09.37",
                androidSdkVersion = 30,
                hl = "en",
                gl = "US",
            },
        },
        videoId = videoId,
    }, {
        ["Origin"] = "https://www.youtube.com",
        ["Referer"] = "https://www.youtube.com/watch?v=" .. videoId,
    })

    local pData = nil
    if pRes and pRes.Body then
        local okP, parsed = pcall(function()
            return SRV.Http:JSONDecode(pRes.Body)
        end)
        if okP and type(parsed) == "table" then
            pData = parsed
        end
    end

    if not pData then
        local wRes = safeGet("https://www.youtube.com/watch?v=" .. videoId)
        if wRes and wRes.Body then
            local marker = wRes.Body:find("ytInitialPlayerResponse", 1, true)
            if marker then
                local objStr = extractJsonObject(wRes.Body, marker)
                if objStr then
                    local okW, parsedW = pcall(function()
                        return SRV.Http:JSONDecode(objStr)
                    end)
                    if okW and type(parsedW) == "table" then
                        pData = parsedW
                    end
                end
            end
        end
    end

    if not pData then
        return nil
    end

    local vd = pData.videoDetails or {}
    local desc = tostring(vd.shortDescription or "")
    local officialTitle = nil
    local officialArtist = nil

    if desc:find("Provided to YouTube by", 1, true) then
        local lines = {}
        for ln in desc:gmatch("[^\r\n]+") do
            local trimmed = ln:gsub("^%s+", ""):gsub("%s+$", "")
            if #trimmed > 0 then
                lines[#lines + 1] = trimmed
            end
        end
        if lines[2] then
            local tPart, aPart = lines[2]:match("^(.-)%s+·%s+(.+)$")
            if tPart and aPart then
                officialTitle = Lyrics.stripTitleNoise(tPart)
                local firstArtist = aPart:match("^([^·,]+)") or aPart
                officialArtist = Lyrics.stripTitleNoise(firstArtist)
            end
        end
    end

    local creatorDescLyrics = Lyrics.extractDescriptionLyrics(desc)

    local captionTracks = nil
    local capRenderer = pData.captions and pData.captions.playerCaptionsTracklistRenderer
    if type(capRenderer) == "table" and type(capRenderer.captionTracks) == "table" then
        captionTracks = capRenderer.captionTracks
    end

    return {
        videoTitle = tostring(vd.title or ""),
        videoAuthor = tostring(vd.author or ""),
        officialTitle = officialTitle,
        officialArtist = officialArtist,
        creatorDescLyrics = creatorDescLyrics,
        captionTracks = captionTracks,
    }
end

function Lyrics.cleanCaptionSegment(raw)
    local s = tostring(raw or "")
    s = s:gsub("&#39;", "'")
        :gsub("&apos;", "'")
        :gsub("&quot;", '"')
        :gsub("&amp;", "&")
        :gsub("&lt;", "<")
        :gsub("&gt;", ">")
        :gsub("<[^>]+>", " ")
        :gsub("[\r\n]+", " ")
    s = s:gsub("%[[^%]]-%]", " ")
    s = s:gsub("%([^%)]-[Mm][Uu][Ss][Ii][Cc][^%)]-%)", " ")
    s = s:gsub("[\u{266A}\u{266B}\u{266C}]", " ")
    s = s:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

function Lyrics.parseJson3Transcript(bodyStr, totalDuration)
    local ok, data = pcall(function()
        return SRV.Http:JSONDecode(bodyStr)
    end)
    if not (ok and type(data) == "table" and type(data.events) == "table") then
        return {}, "PARSE_ERR"
    end

    local rawCues = {}
    for _, ev in ipairs(data.events) do
        if type(ev) == "table" and type(ev.segs) == "table" and ev.tStartMs then
            local parts = {}
            for _, seg in ipairs(ev.segs) do
                if type(seg) == "table" and type(seg.utf8) == "string" then
                    parts[#parts + 1] = seg.utf8
                end
            end
            local cleaned = Lyrics.cleanCaptionSegment(table.concat(parts, ""))
            if #cleaned >= 2 then
                local startSec = (tonumber(ev.tStartMs) or 0) / 1000
                local durSec = (tonumber(ev.dDurationMs) or 2500) / 1000
                rawCues[#rawCues + 1] = {
                    time = startSec,
                    endHint = startSec + durSec,
                    text = cleaned,
                }
            end
        end
    end

    return Lyrics.buildTimeline(rawCues, totalDuration)
end

function Lyrics.parseXmlTranscript(bodyStr, totalDuration)
    local rawCues = {}
    for startAttr, durAttr, inner in bodyStr:gmatch('<text[^>]-start="([%d%.]+)"[^>]-dur="([%d%.]+)"[^>]*>(.-)</text>') do
        local cleaned = Lyrics.cleanCaptionSegment(inner)
        local startSec = tonumber(startAttr)
        local durSec = tonumber(durAttr) or 2.5
        if startSec and #cleaned >= 2 then
            rawCues[#rawCues + 1] = {
                time = startSec,
                endHint = startSec + durSec,
                text = cleaned,
            }
        end
    end
    return Lyrics.buildTimeline(rawCues, totalDuration)
end

function Lyrics.fetchYoutubeCaptionTrack(videoId, totalDuration, preloadedInfo, allowAsr)
    local info = preloadedInfo or Lyrics.fetchYoutubePlayerInfo(videoId)
    if not (info and info.captionTracks) then
        return nil
    end

    local chosen = nil
    for _, tr in ipairs(info.captionTracks) do
        if type(tr) == "table" and type(tr.baseUrl) == "string" and #tr.baseUrl > 10 then
            local kind = tostring(tr.kind or "")
            local vssId = tostring(tr.vssId or "")
            local isAuto = (kind == "asr") or (vssId:sub(1, 2) == "a.")
            if not isAuto then
                chosen = {
                    url = tr.baseUrl,
                    lang = tostring(tr.languageCode or "cc"),
                    isAuto = false,
                }
                break
            elseif allowAsr and not chosen then
                chosen = {
                    url = tr.baseUrl,
                    lang = tostring(tr.languageCode or "asr"),
                    isAuto = true,
                }
            end
        end
    end

    if not chosen then
        return nil
    end

    local json3Url = chosen.url
    if not json3Url:find("fmt=", 1, true) then
        if json3Url:find("?", 1, true) then
            json3Url = json3Url .. "&fmt=json3"
        else
            json3Url = json3Url .. "?fmt=json3"
        end
    end

    local tRes = safeGet(json3Url, { ["Referer"] = "https://www.youtube.com/watch?v=" .. videoId })
    if not (tRes and tRes.Body and #tRes.Body > 20) then
        return nil
    end

    local cues, status = {}, "EMPTY"
    if tRes.Body:sub(1, 1) == "{" then
        cues, status = Lyrics.parseJson3Transcript(tRes.Body, totalDuration)
    else
        cues, status = Lyrics.parseXmlTranscript(tRes.Body, totalDuration)
    end

    if status == "OK" and #cues >= 3 then
        return {
            videoId = videoId,
            cues = cues,
            lang = chosen.lang,
            isAuto = chosen.isAuto,
        }
    end
    return nil
end

-- ============================================================================
-- SOURCE 4, 5 & 6: NETEASE CLOUD MUSIC + KUGOU + LYRICS.OVH
-- ============================================================================

function Lyrics.fetchFromNetEase(ident, audioDur)
    if not httpRequest or #ident.title < 2 then
        return nil
    end
    local q = ident.title
    if ident.artistReliable and #ident.artist > 0 then
        q = ident.artist .. " " .. ident.title
    end
    local url = "https://music.163.com/api/search/get?type=1&limit=5&s=" .. SRV.Http:UrlEncode(q)
    local res = safeGet(url, {
        ["Referer"] = "https://music.163.com/",
        ["Accept"] = "application/json",
    })
    if not (res and res.Body) then
        return nil
    end

    local ok, data = pcall(function()
        return SRV.Http:JSONDecode(res.Body)
    end)
    local songs = ok and data and data.result and data.result.songs
    if type(songs) ~= "table" then
        return nil
    end

    for _, item in ipairs(songs) do
        if type(item) == "table" and item.id and item.name then
            local candTitle = Lyrics.stripTitleNoise(tostring(item.name))
            local candArtist = ""
            if type(item.artists) == "table" and item.artists[1] and item.artists[1].name then
                candArtist = tostring(item.artists[1].name)
            end
            local durSec = (tonumber(item.duration) or 0) / 1000
            local durOk = (audioDur <= 0 or durSec <= 0 or math.abs(durSec - audioDur) <= CFG.LYRIC_MAX_DUR_DIFF)

            local tSim = Lyrics.strictTokenCompare(ident.title, candTitle)
            local aOk = true
            if ident.artistReliable and #ident.artist >= 2 then
                local aSim = Lyrics.strictTokenCompare(ident.artist, candArtist)
                aOk = (aSim >= 0.65)
            end

            if durOk and tSim >= 0.75 and aOk then
                local lUrl = "https://music.163.com/api/song/lyric?id=" .. tostring(item.id) .. "&lv=1&tv=1"
                local lRes = safeGet(lUrl, {
                    ["Referer"] = "https://music.163.com/",
                    ["Accept"] = "application/json",
                })
                if lRes and lRes.Body then
                    local okL, lData = pcall(function()
                        return SRV.Http:JSONDecode(lRes.Body)
                    end)
                    local rawLrc = okL and lData and lData.lrc and lData.lrc.lyric
                    if type(rawLrc) == "string" and #rawLrc > 20 then
                        local parsed, st = Lyrics.parseLrc(rawLrc, audioDur)
                        if st == "OK" and #parsed >= 4 then
                            return {
                                cues = parsed,
                                rawLrc = rawLrc,
                                label = candArtist .. " - " .. candTitle,
                            }
                        end
                    end
                end
            end
        end
    end
    return nil
end

function Lyrics.fetchFromKugou(ident, audioDur)
    if not httpRequest or #ident.title < 2 then
        return nil
    end
    local q = ident.title
    if ident.artistReliable and #ident.artist > 0 then
        q = ident.artist .. " - " .. ident.title
    end
    local durMs = math.max(0, math.floor((audioDur or 0) * 1000))
    local sUrl = "http://lyrics.kugou.com/search?ver=1&man=yes&client=pc&keyword="
        .. SRV.Http:UrlEncode(q)
        .. "&duration=" .. tostring(durMs)
    local res = safeGet(sUrl, { ["Accept"] = "application/json" })
    if not (res and res.Body) then
        return nil
    end

    local ok, data = pcall(function()
        return SRV.Http:JSONDecode(res.Body)
    end)
    local candidates = ok and data and data.candidates
    if type(candidates) ~= "table" then
        return nil
    end

    for _, cand in ipairs(candidates) do
        if type(cand) == "table" and cand.id and cand.accesskey then
            local cSong = Lyrics.stripTitleNoise(tostring(cand.song or ""))
            local cSinger = tostring(cand.singer or "")
            local cDur = (tonumber(cand.duration) or 0) / 1000
            local durOk = (audioDur <= 0 or cDur <= 0 or math.abs(cDur - audioDur) <= CFG.LYRIC_MAX_DUR_DIFF)
            local tSim = Lyrics.strictTokenCompare(ident.title, cSong)
            local aOk = true
            if ident.artistReliable and #ident.artist >= 2 then
                aOk = (Lyrics.strictTokenCompare(ident.artist, cSinger) >= 0.65)
            end

            if durOk and tSim >= 0.75 and aOk then
                local dUrl = "http://lyrics.kugou.com/download?ver=1&client=pc&id="
                    .. tostring(cand.id)
                    .. "&accesskey=" .. tostring(cand.accesskey)
                    .. "&fmt=lrc&charset=utf8"
                local dRes = safeGet(dUrl, { ["Accept"] = "application/json" })
                if dRes and dRes.Body then
                    local okD, dData = pcall(function()
                        return SRV.Http:JSONDecode(dRes.Body)
                    end)
                    if okD and type(dData) == "table" and type(dData.content) == "string" and #dData.content > 20 then
                        local decodedLrc = base64Decode(dData.content)
                        local parsed, st = Lyrics.parseLrc(decodedLrc, audioDur)
                        if st == "OK" and #parsed >= 4 then
                            return {
                                cues = parsed,
                                rawLrc = decodedLrc,
                                label = cSinger .. " - " .. cSong,
                            }
                        end
                    end
                end
            end
        end
    end
    return nil
end

function Lyrics.fetchFromLyricsOvh(ident)
    if not httpRequest or not ident.artistReliable or #ident.artist < 2 or #ident.title < 2 then
        return nil
    end
    local url = "https://api.lyrics.ovh/v1/"
        .. SRV.Http:UrlEncode(ident.artist)
        .. "/"
        .. SRV.Http:UrlEncode(ident.title)
    local res = safeGet(url, { ["Accept"] = "application/json" })
    if not (res and res.Body) then
        return nil
    end
    local ok, data = pcall(function()
        return SRV.Http:JSONDecode(res.Body)
    end)
    if ok and type(data) == "table" and type(data.lyrics) == "string" and #data.lyrics > 25 then
        return data.lyrics
    end
    return nil
end

-- ============================================================================
-- EXTRA LYRIC SOURCES EXPANSION (QQ MUSIC, MEGALOBIZ, VAGALUME, GENIUS, CHARTLYRICS)
-- ============================================================================

function Lyrics.decodeHtmlEntities(str)
    local s = tostring(str or "")
    s = s:gsub("<br%s*/?>", "\n")
        :gsub("</p>", "\n")
        :gsub("</div>", "\n")
        :gsub("<[^>]+>", "")
        :gsub("&amp;", "&")
        :gsub("&quot;", '"')
        :gsub("&#39;", "'")
        :gsub("&apos;", "'")
        :gsub("&lt;", "<")
        :gsub("&gt;", ">")
        :gsub("&nbsp;", " ")
        :gsub("&#x27;", "'")
        :gsub("&#(%d+);", function(n)
            local code = tonumber(n)
            if code and code > 0 and code < 1114111 then
                return utf8.char(code)
            end
            return ""
        end)
    return s
end

-- 1. QQ Music Synced LRC
function Lyrics.fetchFromQQMusic(ident, audioDur)
    if not httpRequest or #ident.title < 2 then
        return nil
    end
    local q = ident.title
    if ident.artistReliable and #ident.artist > 0 then
        q = ident.artist .. " " .. ident.title
    end
    local sUrl = "https://c.y.qq.com/soso/fcgi-bin/client_search_cp?p=1&n=5&w="
        .. SRV.Http:UrlEncode(q)
        .. "&format=json"
    local res = safeGet(sUrl, {
        ["Referer"] = "https://y.qq.com/",
        ["Accept"] = "application/json",
    })
    if not (res and res.Body) then
        return nil
    end

    local ok, data = pcall(function()
        return SRV.Http:JSONDecode(res.Body)
    end)
    local list = ok and data and data.data and data.data.song and data.data.song.list
    if type(list) ~= "table" then
        return nil
    end

    for _, item in ipairs(list) do
        if type(item) == "table" and item.songmid and item.songname then
            local cTitle = Lyrics.stripTitleNoise(tostring(item.songname))
            local cArtist = ""
            if type(item.singer) == "table" and item.singer[1] and item.singer[1].name then
                cArtist = tostring(item.singer[1].name)
            end
            local cDur = tonumber(item.interval) or 0
            local durOk = (audioDur <= 0 or cDur <= 0 or math.abs(cDur - audioDur) <= CFG.LYRIC_MAX_DUR_DIFF)
            local tSim = Lyrics.strictTokenCompare(ident.title, cTitle)
            local aOk = true
            if ident.artistReliable and #ident.artist >= 2 then
                aOk = (Lyrics.strictTokenCompare(ident.artist, cArtist) >= 0.65)
            end

            if durOk and tSim >= 0.75 and aOk then
                local lUrl = "https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg?songmid="
                    .. tostring(item.songmid)
                    .. "&format=json&nobase64=0"
                local lRes = safeGet(lUrl, {
                    ["Referer"] = "https://y.qq.com/",
                    ["Accept"] = "application/json",
                })
                if lRes and lRes.Body then
                    local okL, lData = pcall(function()
                        return SRV.Http:JSONDecode(lRes.Body)
                    end)
                    if okL and type(lData) == "table" and type(lData.lyric) == "string" and #lData.lyric > 20 then
                        local decoded = base64Decode(lData.lyric)
                        local parsed, st = Lyrics.parseLrc(decoded, audioDur)
                        if st == "OK" and #parsed >= 4 then
                            return {
                                cues = parsed,
                                rawLrc = decoded,
                                badge = "QQ Music",
                                tag = "qqmusic",
                            }
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- 2. Megalobiz Public Synced LRC Database
function Lyrics.fetchFromMegalobiz(ident, audioDur)
    if not httpRequest or #ident.title < 2 then
        return nil
    end
    local q = ident.title
    if ident.artistReliable and #ident.artist > 0 then
        q = ident.artist .. " " .. ident.title
    end
    local sUrl = "https://www.megalobiz.com/search/all?qry=" .. SRV.Http:UrlEncode(q) .. "&searchButton.x=0&searchButton.y=0"
    local res = safeGet(sUrl)
    if not (res and res.Body) then
        return nil
    end

    local checked = 0
    for href, linkTitle in res.Body:gmatch('<a[^>]-class="entity_name"[^>]-href="(/lrc/maker/[^"]+)"[^>]*>(.-)</a>') do
        checked += 1
        if checked > 3 then
            break
        end
        local cleanLinkTitle = Lyrics.stripTitleNoise(Lyrics.decodeHtmlEntities(linkTitle))
        local normLink = Lyrics.normalizeText(cleanLinkTitle)
        local normTitle = Lyrics.normalizeText(ident.title)
        local normArtist = Lyrics.normalizeText(ident.artist)

        local titleHit = (#normTitle >= 2 and normLink:find(normTitle, 1, true) ~= nil)
        local artistHit = true
        if ident.artistReliable and #normArtist >= 2 then
            artistHit = (normLink:find(normArtist, 1, true) ~= nil)
        end

        if titleHit and artistHit then
            local pageRes = safeGet("https://www.megalobiz.com" .. href)
            if pageRes and pageRes.Body then
                local lrcDiv = pageRes.Body:match('<div[^>]-class="lyrics_details[^"]*"[^>]*>(.-)</div>')
                    or pageRes.Body:match('<span[^>]-id="lrc_%d+_details"[^>]*>(.-)</span>')
                if lrcDiv then
                    local rawLrc = Lyrics.decodeHtmlEntities(lrcDiv)
                    local parsed, st = Lyrics.parseLrc(rawLrc, audioDur)
                    if st == "OK" and #parsed >= 4 then
                        return {
                            cues = parsed,
                            rawLrc = rawLrc,
                            badge = "Megalobiz LRC",
                            tag = "megalobiz",
                        }
                    end
                end
            end
        end
    end
    return nil
end

-- 3. Vagalume API (Brazilian Portuguese, Funk, MPB, Pop + Official PT-BR Translations)
function Lyrics.fetchFromVagalume(ident)
    if not httpRequest or #ident.title < 2 then
        return nil
    end
    local url = "https://api.vagalume.com.br/search.php?mus=" .. SRV.Http:UrlEncode(ident.title)
    if ident.artistReliable and #ident.artist >= 2 then
        url = url .. "&art=" .. SRV.Http:UrlEncode(ident.artist)
    end
    local res = safeGet(url, { ["Accept"] = "application/json" })
    if not (res and res.Body) then
        return nil
    end

    local ok, data = pcall(function()
        return SRV.Http:JSONDecode(res.Body)
    end)
    if not (ok and type(data) == "table" and type(data.mus) == "table" and #data.mus > 0) then
        return nil
    end

    local mus = data.mus[1]
    local artName = (type(data.art) == "table" and data.art.name) or ""
    local musName = tostring(mus.name or "")

    local tSim = Lyrics.strictTokenCompare(ident.title, Lyrics.stripTitleNoise(musName))
    local aOk = true
    if ident.artistReliable and #ident.artist >= 2 and #artName >= 2 then
        aOk = (Lyrics.strictTokenCompare(ident.artist, artName) >= 0.65)
    elseif ident.titleWordCount < 2 then
        aOk = false
    end

    if tSim >= 0.78 and aOk and type(mus.text) == "string" and #mus.text > 20 then
        if Opts.lyricTranslate == "pt" and type(mus.translate) == "table" and mus.translate[1] and type(mus.translate[1].text) == "string" then
            return mus.translate[1].text, "Vagalume [PT]"
        end
        return mus.text, "Vagalume"
    end
    return nil
end

-- 4. Genius Search + Lyric Container Scraper (Great for Rap, Trap, Phonk & Underground)
function Lyrics.fetchFromGenius(ident)
    if not httpRequest or #ident.title < 2 then
        return nil
    end
    local q = ident.title
    if ident.artistReliable and #ident.artist > 0 then
        q = ident.artist .. " " .. ident.title
    end
    local sUrl = "https://genius.com/api/search/multi?per_page=5&q=" .. SRV.Http:UrlEncode(q)
    local res = safeGet(sUrl, { ["Accept"] = "application/json" })
    if not (res and res.Body) then
        return nil
    end

    local ok, data = pcall(function()
        return SRV.Http:JSONDecode(res.Body)
    end)
    local sections = ok and data and data.response and data.response.sections
    if type(sections) ~= "table" then
        return nil
    end

    local targetUrl = nil
    for _, sec in ipairs(sections) do
        if type(sec) == "table" and (sec.type == "song" or sec.type == "top_hit") and type(sec.hits) == "table" then
            for _, h in ipairs(sec.hits) do
                local r = h.result
                if type(r) == "table" and r.type == "song" and type(r.url) == "string" and r.title then
                    local gTitle = Lyrics.stripTitleNoise(tostring(r.title))
                    local gArtist = (type(r.primary_artist) == "table" and tostring(r.primary_artist.name or "")) or ""
                    local tSim = Lyrics.strictTokenCompare(ident.title, gTitle)
                    local aOk = true
                    if ident.artistReliable and #ident.artist >= 2 then
                        aOk = (Lyrics.strictTokenCompare(ident.artist, gArtist) >= 0.65)
                    elseif ident.titleWordCount < 2 then
                        aOk = false
                    end
                    if tSim >= 0.78 and aOk then
                        targetUrl = r.url
                        break
                    end
                end
            end
        end
        if targetUrl then
            break
        end
    end

    if not targetUrl then
        return nil
    end

    local pageRes = safeGet(targetUrl)
    if not (pageRes and pageRes.Body) then
        return nil
    end

    local chunks = {}
    for container in pageRes.Body:gmatch('<div[^>]-data%-lyrics%-container="true"[^>]*>(.-)</div>') do
        local cleaned = Lyrics.decodeHtmlEntities(container)
        if #cleaned > 5 then
            chunks[#chunks + 1] = cleaned
        end
    end

    local fullLyrics = table.concat(chunks, "\n")
    if #fullLyrics > 25 then
        return fullLyrics, "Genius"
    end
    return nil
end

-- 5. ChartLyrics XML API
function Lyrics.fetchFromChartLyrics(ident)
    if not httpRequest or not ident.artistReliable or #ident.artist < 2 or #ident.title < 2 then
        return nil
    end
    local url = "http://api.chartlyrics.com/apiv1.asmx/SearchLyricDirect?artist="
        .. SRV.Http:UrlEncode(ident.artist)
        .. "&song="
        .. SRV.Http:UrlEncode(ident.title)
    local res = safeGet(url)
    if not (res and res.Body) then
        return nil
    end
    local xmlLyric = res.Body:match("<Lyric>(.-)</Lyric>")
    if xmlLyric then
        local decoded = Lyrics.decodeHtmlEntities(xmlLyric)
        if #decoded > 25 then
            return decoded, "ChartLyrics"
        end
    end
    return nil
end

-- Unified Dispatcher for All Extra Synced & Plain Sources
function Lyrics.fetchExtraSyncedSources(ident, audioDur)
    local qq = Lyrics.fetchFromQQMusic(ident, audioDur)
    if qq then
        return qq
    end
    local mega = Lyrics.fetchFromMegalobiz(ident, audioDur)
    if mega then
        return mega
    end
    return nil
end

function Lyrics.fetchExtraPlainSources(ident)
    local vagText, vagBadge = Lyrics.fetchFromVagalume(ident)
    if vagText then
        return vagText, vagBadge
    end
    local genText, genBadge = Lyrics.fetchFromGenius(ident)
    if genText then
        return genText, genBadge
    end
    local chartText, chartBadge = Lyrics.fetchFromChartLyrics(ident)
    if chartText then
        return chartText, chartBadge
    end
    return nil, nil
end

-- ============================================================================
-- SOURCE 7: MULTILINGUAL YOUTUBE LYRIC-VIDEO SEARCH (LYRICS / LETRA / ETC.)
-- ============================================================================

function Lyrics.detectNativeScriptTag(str)
    for _, cp in utf8.codes(tostring(str or "")) do
        if cp >= 0xAC00 and cp <= 0xD7AF then
            return "가사"
        elseif (cp >= 0x3040 and cp <= 0x30FF) or (cp >= 0x4E00 and cp <= 0x9FFF) then
            return "歌詞"
        elseif cp >= 0x0400 and cp <= 0x04FF then
            return "текст"
        elseif cp >= 0x0600 and cp <= 0x06FF then
            return "كلمات"
        end
    end
    return nil
end

function Lyrics.findMultilingualLyricVideos(ident, audioDur, skipVideoId)
    if not httpRequest or not audioDur or audioDur < 8 then
        return {}
    end

    local base = ident.title
    if ident.artistReliable and #ident.artist > 0 then
        base = ident.artist .. " " .. ident.title
    end

    local queries = {}
    local nativeTag = Lyrics.detectNativeScriptTag(ident.rawTitle)
    if nativeTag then
        queries[#queries + 1] = base .. " " .. nativeTag
    end
    queries[#queries + 1] = base .. " lyrics"
    queries[#queries + 1] = base .. " letra"
    queries[#queries + 1] = base .. " legendado"

    local rankedVideos = {}
    local seenVid = {}
    if skipVideoId then
        seenVid[skipVideoId] = true
    end

    for _, q in ipairs(queries) do
        if RT.cur == nil then
            return {}
        end
        local hits = searchYoutubeTracks(q)
        for _, hit in ipairs(hits) do
            if not seenVid[hit.id] then
                seenVid[hit.id] = true
                local durDiff = 999
                if hit.durationSec and hit.durationSec > 0 then
                    durDiff = math.abs(hit.durationSec - audioDur)
                end

                if durDiff <= 4 then
                    local hitVer = Lyrics.getVersionTags(hit.title)
                    if not Lyrics.versionsConflict(ident.versionTags, hitVer) then
                        local cleanHitTitle = Lyrics.stripTitleNoise(hit.title)
                        local titleSim, titleJac = Lyrics.strictTokenCompare(ident.title, cleanHitTitle)
                        local normHitFull = Lyrics.normalizeText(hit.title .. " " .. hit.creator)
                        local normArtist = Lyrics.normalizeText(ident.artist)
                        local artistOk = true
                        if ident.artistReliable and #normArtist >= 2 then
                            artistOk = (normHitFull:find(normArtist, 1, true) ~= nil)
                        elseif ident.titleWordCount < 2 then
                            artistOk = false
                        end

                        if artistOk and (titleSim >= 0.72 or titleJac >= 0.65) then
                            rankedVideos[#rankedVideos + 1] = {
                                id = hit.id,
                                score = (titleSim * 60) - (durDiff * 4),
                            }
                        end
                    end
                end
            end
        end
    end

    table.sort(rankedVideos, function(a, b)
        return a.score > b.score
    end)

    return rankedVideos
end

-- ============================================================================
-- SOURCE 8: DIRECT AUDIO-FILE SPEECH-TO-TEXT (WHISPER / GROQ / OPENAI STT)
-- ============================================================================

function Lyrics.transcribeAudioWithWhisper(songObj, totalDuration)
    if not httpRequest or Opts.sttKey == "" or not songObj or not isfile(songObj.path) then
        return nil
    end

    local okR, audioBytes = pcall(readfile, songObj.path)
    if not okR or type(audioBytes) ~= "string" or #audioBytes < 2048 or #audioBytes > 24000000 then
        return nil
    end

    -- Auto-detect Groq vs OpenAI endpoint based on key prefix
    local endpoint = "https://api.openai.com/v1/audio/transcriptions"
    local modelName = "whisper-1"
    if Opts.sttKey:sub(1, 4) == "gsk_" then
        endpoint = "https://api.groq.com/openai/v1/audio/transcriptions"
        modelName = "whisper-large-v3"
    end

    local ext = (songObj.path:match("%.(%w+)$") or "mp3"):lower()
    local mime = "audio/mpeg"
    if ext == "ogg" then
        mime = "audio/ogg"
    elseif ext == "wav" then
        mime = "audio/wav"
    end

    local boundary = "----xzypSttBoundary" .. tostring(math.floor(os.clock() * 100000))
    local bodyParts = {
        "--" .. boundary .. "\r\n",
        'Content-Disposition: form-data; name="file"; filename="audio.' .. ext .. '"\r\n',
        "Content-Type: " .. mime .. "\r\n\r\n",
        audioBytes,
        "\r\n--" .. boundary .. "\r\n",
        'Content-Disposition: form-data; name="model"\r\n\r\n',
        modelName,
        "\r\n--" .. boundary .. "\r\n",
        'Content-Disposition: form-data; name="response_format"\r\n\r\n',
        "verbose_json",
        "\r\n--" .. boundary .. "--\r\n",
    }

    local okReq, res = pcall(function()
        return httpRequest({
            Url = endpoint,
            Method = "POST",
            Headers = {
                ["Authorization"] = "Bearer " .. Opts.sttKey,
                ["Content-Type"] = "multipart/form-data; boundary=" .. boundary,
                ["Accept"] = "application/json",
            },
            Body = table.concat(bodyParts),
        })
    end)

    if not (okReq and res and res.Body) then
        return nil
    end

    local okJ, data = pcall(function()
        return SRV.Http:JSONDecode(res.Body)
    end)
    if not (okJ and type(data) == "table" and type(data.segments) == "table") then
        return nil
    end

    local rawCues = {}
    for _, seg in ipairs(data.segments) do
        if type(seg) == "table" and type(seg.text) == "string" then
            local cleaned = Lyrics.cleanCaptionSegment(seg.text)
            local sTime = tonumber(seg.start)
            local eTime = tonumber(seg["end"])
            if sTime and #cleaned >= 2 then
                rawCues[#rawCues + 1] = {
                    time = sTime,
                    endHint = eTime or (sTime + 2.5),
                    text = cleaned,
                }
            end
        end
    end

    local timeline, st = Lyrics.buildTimeline(rawCues, totalDuration)
    if st == "OK" and #timeline >= 3 then
        return timeline
    end
    return nil
end

-- ============================================================================
-- LRCLIB CANDIDATE SCORING & MAIN ORCHESTRATOR
-- ============================================================================

function Lyrics.getCacheKey(songObj)
    return songObj.path:match("([^/\\]+)%.%w+$") or cleanFileName(songObj.name) or "track"
end

function Lyrics.getCachePath(songObj)
    return PATHS.LYRICS .. "/" .. Lyrics.getCacheKey(songObj) .. ".lrc"
end

function Lyrics.findLocalSidecarLyrics(songObj, totalDuration)
    local baseName = Lyrics.getCacheKey(songObj)
    local dirPrefix = songObj.dir or PATHS.LOCAL
    local searchBases = {
        PATHS.LYRICS .. "/" .. baseName,
        dirPrefix .. "/" .. baseName,
    }

    for _, prefix in ipairs(searchBases) do
        if isfile(prefix .. ".lrc") then
            local okR, txt = pcall(readfile, prefix .. ".lrc")
            if okR and type(txt) == "string" then
                local parsed, st = Lyrics.parseLrc(txt, totalDuration)
                if st == "OK" and #parsed >= 3 then
                    return parsed, "Cached (.lrc)"
                end
            end
        end
        if isfile(prefix .. ".srt") then
            local okR, txt = pcall(readfile, prefix .. ".srt")
            if okR and type(txt) == "string" then
                local parsed, st = Lyrics.parseSrtOrVtt(txt, totalDuration)
                if st == "OK" and #parsed >= 3 then
                    return parsed, "Local (.srt)"
                end
            end
        end
        if isfile(prefix .. ".vtt") then
            local okR, txt = pcall(readfile, prefix .. ".vtt")
            if okR and type(txt) == "string" then
                local parsed, st = Lyrics.parseSrtOrVtt(txt, totalDuration)
                if st == "OK" and #parsed >= 3 then
                    return parsed, "Local (.vtt)"
                end
            end
        end
        if isfile(prefix .. ".txt") then
            local okR, txt = pcall(readfile, prefix .. ".txt")
            if okR and type(txt) == "string" then
                local parsed, st = Lyrics.alignPlainLyrics(txt, totalDuration, nil)
                if st == "OK" and #parsed >= 3 then
                    return parsed, "Local (.txt)"
                end
            end
        end
    end

    return nil, nil
end

function Lyrics.evaluateLrclibCandidate(ident, audioDur, item)
    local itemTrackRaw = tostring(item.trackName or item.name or "")
    local itemArtistRaw = tostring(item.artistName or "")
    local itemTrackClean = Lyrics.stripTitleNoise(itemTrackRaw)
    local candVer = Lyrics.getVersionTags(itemTrackRaw)

    if Lyrics.versionsConflict(ident.versionTags, candVer) then
        return nil, "MISMATCH"
    end

    local titleScore, titleJaccard = Lyrics.strictTokenCompare(ident.title, itemTrackClean)
    local exactTitle = Lyrics.exactMatchNormalized(ident.title, itemTrackClean)

    if not exactTitle and titleScore < 0.78 and titleJaccard < 0.72 then
        return nil, "REJECT"
    end

    local artistScore = 0
    local artistVerified = false
    local normRawTitle = Lyrics.normalizeText(ident.rawTitle)
    local normItemArtist = Lyrics.normalizeText(itemArtistRaw)

    if ident.artistReliable and #ident.artist >= 2 then
        local aComb, aJac = Lyrics.strictTokenCompare(ident.artist, itemArtistRaw)
        local exactArtist = Lyrics.exactMatchNormalized(ident.artist, itemArtistRaw)
        artistScore = aComb
        if exactArtist or aComb >= 0.72 or aJac >= 0.65 then
            artistVerified = true
        end
        if not artistVerified and #normItemArtist >= 3 and normRawTitle:find(normItemArtist, 1, true) then
            artistVerified = true
            artistScore = math.max(artistScore, 0.78)
        end
        if not artistVerified then
            return nil, "WRONG_ARTIST"
        end
    else
        if #normItemArtist >= 3 and normRawTitle:find(normItemArtist, 1, true) then
            artistVerified = true
            artistScore = 0.80
        else
            if ident.titleWordCount < 2 or not exactTitle then
                return nil, "AMBIGUOUS"
            end
            artistScore = 0.60
        end
    end

    if item.instrumental == true then
        return nil, "INSTRUMENTAL"
    end

    local hasSync = type(item.syncedLyrics) == "string" and #item.syncedLyrics > 15
    local hasPlain = type(item.plainLyrics) == "string" and #item.plainLyrics > 15
    local itemDur = tonumber(item.duration) or 0
    local durDiff = 0
    if audioDur > 0 and itemDur > 0 then
        durDiff = math.abs(itemDur - audioDur)
    end

    local maxAllowedDiff = CFG.LYRIC_MAX_DUR_DIFF
    if not artistVerified then
        maxAllowedDiff = 2.0
    end

    if durDiff > maxAllowedDiff then
        return { durDiff = durDiff }, "DUR_MISMATCH"
    end

    if not hasSync and not hasPlain then
        return nil, "REJECT"
    end

    local syncBonus = hasSync and 30 or 0
    local rankScore = (titleScore * 55) + (artistScore * 35) + syncBonus - (durDiff * 4.5)

    return {
        record = item,
        rankScore = rankScore,
        hasSync = hasSync,
        hasPlain = hasPlain,
        artistVerified = artistVerified,
        normArtist = normItemArtist,
        durDiff = durDiff,
    }, "VALID"
end

function Lyrics.loadForSong(songObj, forceRefresh)
    local syncHandle = { finished = false }
    RT.lyricCues = {}
    RT.lyricStateKey = ""
    RT.lyricIsPauseCue = false
    RT.lyricTrack = songObj
    RT.lyricSourceName = ""
    RT.lastSyncPos = 0
    RT.silenceTimer = 0
    Lyrics.clearGlyphs(false)

    if not songObj then
        Lyrics.setStatus("IDLE", "Idle", nil, CLR.TEXT_MUTED, false)
        syncHandle.finished = true
        return syncHandle
    end

    local cacheKey = Lyrics.getCacheKey(songObj)
    local cachePath = Lyrics.getCachePath(songObj)

    if forceRefresh then
        if isfile(cachePath) then
            pcall(delfile, cachePath)
        end
        if State.noLyrics[cacheKey] ~= nil then
            State.noLyrics[cacheKey] = nil
            saveState()
        end
    end

    -- 1. Check local sidecar files (.lrc, .srt, .vtt, .txt)
    local sidecarCues, sidecarBadge = Lyrics.findLocalSidecarLyrics(songObj, Sound.TimeLength)
    if sidecarCues and #sidecarCues >= 3 then
        if Opts.lyricTranslate ~= "off" then
            sidecarCues = Lyrics.translateCues(sidecarCues, Opts.lyricTranslate)
        end
        RT.lyricCues = sidecarCues
        RT.lyricSourceName = sidecarBadge or "Local"
        Lyrics.setStatus("CACHED", sidecarBadge or "Cached", nil, CLR.STATUS_OK, false)
        syncHandle.finished = true
        return syncHandle
    end

    -- 2. Check negative cache
    if State.noLyrics[cacheKey] then
        local cachedReason = tostring(State.noLyrics[cacheKey])
        local subtleMsg = "\u{266A}  No lyrics available for this track"
        local shortBadge = "No Lyrics"
        if cachedReason == "INSTRUMENTAL" then
            subtleMsg = "\u{266A}  Instrumental track — no lyrics"
            shortBadge = "Instrumental"
        end
        Lyrics.setStatus(cachedReason, shortBadge, subtleMsg, CLR.TEXT_SECONDARY, true)
        syncHandle.finished = true
        return syncHandle
    end

    local ident = Lyrics.parseTrackIdentity(songObj)
    if ident.versionTags.instrumental then
        State.noLyrics[cacheKey] = "INSTRUMENTAL"
        saveState()
        Lyrics.setStatus("INSTRUMENTAL", "Instrumental", "\u{266A}  Instrumental track — no lyrics", CLR.TEXT_SECONDARY, true)
        syncHandle.finished = true
        return syncHandle
    end

    Lyrics.setStatus("SEARCHING", "Searching...", nil, CLR.TEXT_SECONDARY, false)

    task.spawn(function()
        local waited = 0
        while Sound.TimeLength <= 0 and waited < 3.0 and RT.cur == songObj do
            waited += task.wait(0.05)
        end
        if RT.cur ~= songObj then
            syncHandle.finished = true
            return
        end

        local finalCues = nil
        local finalBadge = ""
        local finalTag = "sync"

        -- Enrich track identity using authoritative YouTube Topic / Creator metadata
        local ytPlayerInfo = nil
        if songObj.ytId and httpRequest then
            ytPlayerInfo = Lyrics.fetchYoutubePlayerInfo(songObj.ytId)
            if ytPlayerInfo and ytPlayerInfo.officialTitle and ytPlayerInfo.officialArtist then
                ident.title = ytPlayerInfo.officialTitle
                ident.artist = ytPlayerInfo.officialArtist
                ident.artistReliable = true
                local _, tToks = Lyrics.tokenize(ident.title)
                ident.titleWordCount = #tToks
            end
        end

        local dur = math.floor(Sound.TimeLength + 0.5)
        local plainLyricsBackup = ident.embeddedLyrics

        -- SOURCE A: LRCLIB (Synced + Plain)
        if httpRequest then
            local rawCandidates = {}
            local seenKeys = {}
            local function pushCandidates(list)
                if type(list) ~= "table" then
                    return
                end
                for _, item in ipairs(list) do
                    if type(item) == "table" and not item.statusCode then
                        local k = tostring(item.id or (tostring(item.trackName) .. "|" .. tostring(item.artistName) .. "|" .. tostring(item.duration)))
                        if not seenKeys[k] then
                            seenKeys[k] = true
                            rawCandidates[#rawCandidates + 1] = item
                        end
                    end
                end
            end

            if #ident.title > 0 and ident.artistReliable and #ident.artist > 0 then
                local getUrl = "https://lrclib.net/api/get?track_name=" .. SRV.Http:UrlEncode(ident.title)
                    .. "&artist_name=" .. SRV.Http:UrlEncode(ident.artist)
                if dur > 0 then
                    getUrl = getUrl .. "&duration=" .. tostring(dur)
                end
                local res = safeGet(getUrl, { ["Accept"] = "application/json" })
                if res and res.Body then
                    local okJ, data = pcall(function()
                        return SRV.Http:JSONDecode(res.Body)
                    end)
                    if okJ and type(data) == "table" then
                        pushCandidates({ data })
                    end
                end
            end

            local qPrimary = ident.title
            if ident.artistReliable and #ident.artist > 0 then
                qPrimary = ident.artist .. " " .. ident.title
            end
            if #qPrimary >= 2 then
                local sRes = safeGet("https://lrclib.net/api/search?q=" .. SRV.Http:UrlEncode(qPrimary), { ["Accept"] = "application/json" })
                if sRes and sRes.Body then
                    local okS, list = pcall(function()
                        return SRV.Http:JSONDecode(sRes.Body)
                    end)
                    if okS then
                        pushCandidates(list)
                    end
                end
            end

            local validMatches = {}
            for _, item in ipairs(rawCandidates) do
                local evalData, reason = Lyrics.evaluateLrclibCandidate(ident, Sound.TimeLength, item)
                if reason == "VALID" and evalData then
                    validMatches[#validMatches + 1] = evalData
                end
            end
            table.sort(validMatches, function(a, b)
                return a.rankScore > b.rankScore
            end)

            for _, cand in ipairs(validMatches) do
                local ambiguousArtist = false
                if #validMatches >= 2 and not cand.artistVerified then
                    local a1 = validMatches[1].normArtist
                    local a2 = validMatches[2].normArtist
                    if a1 ~= "" and a2 ~= "" and a1 ~= a2 then
                        ambiguousArtist = true
                    end
                end

                if not ambiguousArtist then
                    if cand.hasSync then
                        local parsed, st = Lyrics.parseLrc(cand.record.syncedLyrics, Sound.TimeLength)
                        if st == "OK" and #parsed >= 4 then
                            finalCues = parsed
                            finalBadge = "LRCLIB"
                            finalTag = "lrclib"
                            break
                        end
                    elseif cand.hasPlain and not plainLyricsBackup then
                        plainLyricsBackup = cand.record.plainLyrics
                    end
                end
            end
        end

        if RT.cur ~= songObj then
            syncHandle.finished = true
            return
        end

        -- SOURCE B: NetEase Cloud Music LRC
        if not finalCues and httpRequest then
            local neHit = Lyrics.fetchFromNetEase(ident, Sound.TimeLength)
            if neHit and #neHit.cues >= 4 then
                finalCues = neHit.cues
                finalBadge = "NetEase"
                finalTag = "netease"
            end
        end

        if RT.cur ~= songObj then
            syncHandle.finished = true
            return
        end

        -- SOURCE C: Kugou LRC
        if not finalCues and httpRequest then
            local kgHit = Lyrics.fetchFromKugou(ident, Sound.TimeLength)
            if kgHit and #kgHit.cues >= 4 then
                finalCues = kgHit.cues
                finalBadge = "Kugou"
                finalTag = "kugou"
            end
        end

        if RT.cur ~= songObj then
            syncHandle.finished = true
            return
        end

        -- SOURCE C2: Extra Synced LRC Databases (QQ Music + Megalobiz)
        if not finalCues and httpRequest then
            local extraSync = Lyrics.fetchExtraSyncedSources(ident, Sound.TimeLength)
            if extraSync and #extraSync.cues >= 4 then
                finalCues = extraSync.cues
                finalBadge = extraSync.badge
                finalTag = extraSync.tag
            end
        end

        if RT.cur ~= songObj then
            syncHandle.finished = true
            return
        end

        -- SOURCE D: Manual YouTube Closed Captions (on original video or multilingual LYRICS/letra videos)
        local ytAsrBackup = nil
        if not finalCues and httpRequest then
            if songObj.ytId then
                local cap = Lyrics.fetchYoutubeCaptionTrack(songObj.ytId, Sound.TimeLength, ytPlayerInfo, true)
                if cap then
                    if not cap.isAuto then
                        finalCues = cap.cues
                        finalBadge = "YT CC (" .. cap.lang:upper() .. ")"
                        finalTag = "yt-cc"
                    else
                        ytAsrBackup = cap
                    end
                end
            end

            if not finalCues then
                local lyricVids = Lyrics.findMultilingualLyricVideos(ident, Sound.TimeLength, songObj.ytId)
                local checks = math.min(3, #lyricVids)
                for i = 1, checks do
                    local cap = Lyrics.fetchYoutubeCaptionTrack(lyricVids[i].id, Sound.TimeLength, nil, true)
                    if cap then
                        if not cap.isAuto then
                            finalCues = cap.cues
                            finalBadge = "Lyric Vid (" .. cap.lang:upper() .. ")"
                            finalTag = "yt-lyricvid"
                            break
                        elseif not ytAsrBackup then
                            ytAsrBackup = cap
                        end
                    end
                end
            end
        end

        if RT.cur ~= songObj then
            syncHandle.finished = true
            return
        end

        -- SOURCE E: Creator Description + Vagalume + Genius + Lyrics.ovh + ChartLyrics (aligned to vocal windows)
        if not finalCues then
            local plainSourceBadge = "Creator Text"
            if ytPlayerInfo and ytPlayerInfo.creatorDescLyrics then
                plainLyricsBackup = ytPlayerInfo.creatorDescLyrics
                plainSourceBadge = "Creator Desc"
            end
            if not plainLyricsBackup and httpRequest then
                local extraPlain, extraBadge = Lyrics.fetchExtraPlainSources(ident)
                if extraPlain then
                    plainLyricsBackup = extraPlain
                    plainSourceBadge = extraBadge or "Online Text"
                end
            end
            if not plainLyricsBackup and httpRequest then
                plainLyricsBackup = Lyrics.fetchFromLyricsOvh(ident)
                if plainLyricsBackup then
                    plainSourceBadge = "Lyrics.ovh"
                end
            end

            if plainLyricsBackup and #plainLyricsBackup >= 15 then
                local anchorCues = ytAsrBackup and ytAsrBackup.cues or nil
                local aligned, st = Lyrics.alignPlainLyrics(plainLyricsBackup, Sound.TimeLength, anchorCues)
                if st == "OK" and #aligned >= 3 then
                    finalCues = aligned
                    finalBadge = plainSourceBadge
                    finalTag = "plain-aligned"
                end
            end
        end

        if RT.cur ~= songObj then
            syncHandle.finished = true
            return
        end

        -- SOURCE F: Speech-to-Text (STT) — 1) Direct Audio Whisper API, 2) Keyless YouTube Audio ASR
        if not finalCues then
            if Opts.sttKey ~= "" and httpRequest then
                Lyrics.setStatus("SEARCHING", "STT Transcribing...", nil, CLR.TEXT_SECONDARY, false)
                local whisperCues = Lyrics.transcribeAudioWithWhisper(songObj, Sound.TimeLength)
                if whisperCues and #whisperCues >= 3 then
                    finalCues = whisperCues
                    finalBadge = "Whisper STT"
                    finalTag = "whisper-stt"
                end
            end

            if not finalCues and ytAsrBackup and #ytAsrBackup.cues >= 3 then
                finalCues = ytAsrBackup.cues
                finalBadge = "Auto STT (" .. ytAsrBackup.lang:upper() .. ")"
                finalTag = "yt-stt"
            end
        end

        if RT.cur ~= songObj then
            syncHandle.finished = true
            return
        end

        -- Apply concise formatting + optional translation
        if finalCues and #finalCues >= 3 then
            finalCues = Lyrics.makeConciseLines(finalCues)
            if Opts.lyricTranslate ~= "off" and not finalBadge:find("%[" .. Opts.lyricTranslate:upper() .. "%]") then
                finalCues = Lyrics.translateCues(finalCues, Opts.lyricTranslate)
                finalBadge = finalBadge .. " [" .. Opts.lyricTranslate:upper() .. "]"
            end

            RT.lyricCues = finalCues
            RT.lyricSourceName = finalBadge
            pcall(writefile, cachePath, Lyrics.cuesToLrcString(finalCues, finalTag))
            local successNotice = "\u{266A} Lyrics: " .. finalBadge .. " (may not be 100% accurate)"
            Lyrics.setStatus("SYNCED", finalBadge, successNotice, CLR.STATUS_OK, true)
            log("LYRICS", "Loaded lyrics via:", finalBadge, "| lines:", #finalCues)
            syncHandle.finished = true
            return
        end

        -- Truly no lyrics or STT possible -> keep Opts.lyrics ON, keep button gray with accent border, and warn subtly
        State.noLyrics[cacheKey] = "UNKNOWN"
        saveState()
        Lyrics.setStatus("UNKNOWN", "No Lyrics", "\u{266A}  No lyrics available for this track", CLR.TEXT_SECONDARY, true)
        syncHandle.finished = true
    end)

    return syncHandle
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
    if UI.ImportPanel.Visible then
        panels[#panels + 1] = UI.ImportPanel
    end
    if UI.DrawerPanel.Visible then
        panels[#panels + 1] = UI.DrawerPanel
    end
    if UI.SettingsPanel.Visible then
        panels[#panels + 1] = UI.SettingsPanel
    end

    if openUpwards then
        local y = -6
        for _, p in ipairs(panels) do
            local h = p.Size.Y.Offset
            y -= h
            p.Position = UDim2.fromOffset(0, y)
            y -= 6
        end
        if UI.SubtleLyricNotice then
            UI.SubtleLyricNotice.Position = UDim2.new(0.5, 0, 0, y)
        end
    else
        local y = CFG.FULL_H + 6
        for _, p in ipairs(panels) do
            p.Position = UDim2.fromOffset(0, y)
            y += p.Size.Y.Offset + 6
        end
        if UI.SubtleLyricNotice then
            UI.SubtleLyricNotice.Position = UDim2.new(0.5, 0, 0, -6)
        end
    end
end

local function setSearchResultsExpanded(expanded)
    UI.SearchResultsScroll.Visible = expanded
    local panelH = CFG.IMPORT_COMPACT_H
    if expanded then
        panelH = CFG.IMPORT_EXPANDED_H
    end
    UI.ImportPanel.Size = UDim2.fromOffset(CFG.PLAYER_W, panelH)
    layoutSubPanels()
end

local function syncFilterChips()
    local acc = getAccent()
    local accTxt = getAccentText()
    for key, btn in pairs(RT.filterButtons) do
        local on = (RT.activeFilter == key)
        if on then
            btn.BackgroundColor3 = acc
            btn.TextColor3 = accTxt
        else
            btn.BackgroundColor3 = CLR.BG_SURFACE
            btn.TextColor3 = CLR.TEXT_SECONDARY
        end
    end
end

local function syncModeButtons()
    UI.ShuffleBtn:SetAttribute("Active", Opts.shuffle)
    if Opts.shuffle then
        UI.ShuffleBtn.TextColor3 = getAccent()
    else
        UI.ShuffleBtn.TextColor3 = CLR.TEXT_SECONDARY
    end

    UI.LoopBtn:SetAttribute("Active", Opts.loopOne)
    if Opts.loopOne then
        UI.LoopBtn.TextColor3 = getAccent()
    else
        UI.LoopBtn.TextColor3 = CLR.TEXT_SECONDARY
    end

    Lyrics.syncButtonVisual()
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
    local lCol = getLyricColor()
    for _, g in ipairs(RT.activeGlyphs) do
        if g.label then
            g.label.TextColor3 = lCol
        end
    end
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
            if isCur then
                data.Row.BackgroundColor3 = CLR.BG_ACTIVE
                data.Title.TextColor3 = getAccent()
                if RT.playing then
                    data.Index.Text = "||"
                else
                    data.Index.Text = "\u{25B6}"
                end
                data.Index.TextColor3 = getAccent()
            else
                data.Row.BackgroundColor3 = CLR.BG_SURFACE
                data.Title.TextColor3 = CLR.TEXT_PRIMARY
                data.Index.Text = tostring(i)
                data.Index.TextColor3 = CLR.TEXT_MUTED
            end
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
    if RT.playing then
        UI.StatusDot.BackgroundColor3 = CLR.STATUS_OK
    else
        UI.StatusDot.BackgroundColor3 = CLR.TEXT_MUTED
    end
    refreshQueueVisuals()
end

-- ============================================================================
-- SMOOTH UI ANIMATIONS & MICRO-INTERACTIONS MODULE
-- ============================================================================

local UIAnim = {}

function UIAnim.ensureScale(guiObj, initialScale)
    if not guiObj then
        return nil
    end
    local sc = guiObj:FindFirstChild("AnimScale")
    if not sc then
        sc = Instance.new("UIScale")
        sc.Name = "AnimScale"
        sc.Scale = initialScale or 1
        sc.Parent = guiObj
    end
    return sc
end

function UIAnim.attachButtonJuice(btn, hoverScale, pressScale)
    if not btn or not btn:IsA("GuiButton") then
        return
    end
    local hScale = hoverScale or 1.04
    local pScale = pressScale or 0.93
    local sc = UIAnim.ensureScale(btn, 1)

    connect(btn.MouseEnter, function()
        tween(sc, 0.14, { Scale = hScale }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
    connect(btn.MouseLeave, function()
        tween(sc, 0.14, { Scale = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)
    connect(btn.MouseButton1Down, function()
        tween(sc, 0.08, { Scale = pScale }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)
    connect(btn.MouseButton1Up, function()
        tween(sc, 0.16, { Scale = hScale }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
end

function UIAnim.setSubPanelAnimated(panel, shouldShow)
    if not panel then
        return
    end
    local sc = UIAnim.ensureScale(panel, shouldShow and 0.92 or 1)
    if shouldShow then
        panel.Visible = true
        sc.Scale = 0.92
        layoutSubPanels()
        tween(sc, 0.20, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    else
        if not panel.Visible then
            return
        end
        tween(sc, 0.12, { Scale = 0.93 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.12, function()
            if sc.Scale <= 0.94 then
                panel.Visible = false
                sc.Scale = 1
                layoutSubPanels()
            end
        end)
    end
end

function UIAnim.setMinimizedAnimated(minimize)
    if minimize then
        local mainSc = UIAnim.ensureScale(UI.MainCard, 1)
        tween(mainSc, 0.13, { Scale = 0.90 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.13, function()
            UI.MainCard.Visible = false
            mainSc.Scale = 1
            UI.ImportPanel.Visible = false
            UI.DrawerPanel.Visible = false
            UI.SettingsPanel.Visible = false

            UI.MiniPill.Visible = true
            local miniSc = UIAnim.ensureScale(UI.MiniPill, 0.86)
            miniSc.Scale = 0.86
            tween(miniSc, 0.22, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end)
    else
        local miniSc = UIAnim.ensureScale(UI.MiniPill, 1)
        tween(miniSc, 0.12, { Scale = 0.88 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.12, function()
            UI.MiniPill.Visible = false
            miniSc.Scale = 1

            UI.MainCard.Visible = true
            local mainSc = UIAnim.ensureScale(UI.MainCard, 0.92)
            mainSc.Scale = 0.92
            tween(mainSc, 0.22, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end)
    end
end

function UIAnim.pulseCoverOnTrackLoad()
    if not UI.CoverImg then
        return
    end
    local sc = UIAnim.ensureScale(UI.CoverImg, 1.09)
    sc.Scale = 1.09
    tween(sc, 0.32, { Scale = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
end

function UIAnim.setSeekKnobAnimated(show)
    if not UI.SeekKnob then
        return
    end
    if show then
        UI.SeekKnob.Visible = true
        tween(UI.SeekKnob, 0.14, { Size = UDim2.fromOffset(10, 10) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    else
        tween(UI.SeekKnob, 0.12, { Size = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.12, function()
            if not RT.seekHovering and not RT.seeking then
                UI.SeekKnob.Visible = false
            end
        end)
    end
end

function UIAnim.updateBeatVisuals(dt, rawLoud)
    local loudNorm = 0
    if RT.playing then
        loudNorm = math.clamp((rawLoud or 0) / 280, 0, 1)
    end

    if UI.CoverImg then
        local sc = UIAnim.ensureScale(UI.CoverImg, 1)
        local targetCoverScale = 1 + (loudNorm * 0.042)
        sc.Scale = sc.Scale + (targetCoverScale - sc.Scale) * math.min(1, dt * 14)
    end

    if UI.StatusDot and RT.playing then
        local dotSc = UIAnim.ensureScale(UI.StatusDot, 1)
        local targetDotScale = 1 + (loudNorm * 0.35)
        dotSc.Scale = dotSc.Scale + (targetDotScale - dotSc.Scale) * math.min(1, dt * 16)
    end
end

function UIAnim.initAll()
    -- Entrance animation for the main root card
    if UI.RootScale then
        local targetScale = Opts.scale
        UI.RootScale.Scale = targetScale * 0.88
        tween(UI.RootScale, 0.28, { Scale = targetScale }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end

    -- Attach tactile hover & click squish/bounce to all interactive controls
    local pills = { UI.LyricsBtn, UI.AddBtn, UI.QueueBtn, UI.CfgBtn, UI.MiniBtn, UI.CloseBtn, UI.DownloadBtn }
    for _, b in ipairs(pills) do
        UIAnim.attachButtonJuice(b, 1.05, 0.92)
    end

    local transport = { UI.ShuffleBtn, UI.PrevBtn, UI.NextBtn, UI.LoopBtn, UI.MiniPrev, UI.MiniNext, UI.MiniExpand }
    for _, b in ipairs(transport) do
        UIAnim.attachButtonJuice(b, 1.08, 0.90)
    end

    UIAnim.attachButtonJuice(UI.PlayCircle, 1.08, 0.91)
    UIAnim.attachButtonJuice(UI.MiniPlay, 1.08, 0.91)
end

local function playSong(s)
    if not s then
        return
    end
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
        Lyrics.clearGlyphs(false)
        Lyrics.setStatus("IDLE", "Audio Error", nil, CLR.STATUS_ERR, false)
        refreshPlayStateUI()
        return
    end

    Sound.SoundId = assetId
    Sound.TimePosition = 0
    Sound.Volume = Opts.volume

    local cov = coverOf(s)
    local creatorText = "Unknown Creator"
    if s.creator and #s.creator > 0 then
        creatorText = s.creator
    end
    local noteText = s.note or "Local Playlist"
    if s.source == "Youtube" then
        noteText = "Youtube"
    end

    setTrackTitleText(s.name)
    UI.MiniTitle.Text = s.name
    UI.TrackSub.Text = creatorText .. "  |  " .. noteText
    UI.TrackSub.TextColor3 = CLR.TEXT_SECONDARY
    UI.SourceTag.Text = s.source or "LOCAL"
    UI.CoverImg.Image = cov
    UI.MiniArt.Image = cov
    UIAnim.pulseCoverOnTrackLoad()
    refreshPlayStateUI()

    local lyricSyncHandle = Lyrics.loadForSong(s, false)

    task.spawn(function()
        local waited = 0
        while not Sound.IsLoaded and waited < 4 and RT.cur == s do
            waited += task.wait(0.05)
        end
        if RT.cur ~= s then
            return
        end

        if Opts.lyrics and lyricSyncHandle and not lyricSyncHandle.finished then
            local preWait = 0
            while not lyricSyncHandle.finished and preWait < 1.1 and RT.cur == s do
                preWait += task.wait(0.05)
            end
            if RT.cur ~= s then
                return
            end
            if not lyricSyncHandle.finished then
                task.wait(0.15)
            end
        end

        if RT.cur ~= s or not RT.playing then
            return
        end

        Sound:Play()
        task.wait(0.08)
        if RT.cur == s and RT.playing and not Sound.IsPlaying then
            Sound:Play()
        end
        log("PLAY_STATE", "IsPlaying:", Sound.IsPlaying, "| TimeLength:", Sound.TimeLength)
    end)

    local nx = RT.songs[s.idx % #RT.songs + 1]
    if nx then
        task.spawn(function()
            pcall(audioOf, nx)
        end)
    end
end

local function step(d)
    local n = #RT.songs
    if n == 0 then
        return
    end
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
    local i = 1
    if d > 0 then
        i = 0
    end
    if RT.cur then
        i = RT.cur.idx
    end
    playSong(RT.songs[(i - 1 + d) % n + 1])
end

local function togglePlay()
    if #RT.songs == 0 then
        return
    end
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
    if RT.songRows[sObj] then
        return
    end
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
            RT.lyricCues = {}
            RT.lyricStateKey = ""
            Lyrics.clearGlyphs(false)
            Lyrics.setStatus("IDLE", "Idle", nil, CLR.TEXT_MUTED, false)
            setTrackTitleText("No track playing")
            UI.TrackSub.Text = "Track removed"
            UI.TrackSub.TextColor3 = CLR.TEXT_SECONDARY
            UI.SourceTag.Text = "IDLE"
            refreshPlayStateUI()
        end
        pcall(delfile, sObj.path)
        if sObj.coverPath then
            pcall(delfile, sObj.coverPath)
        end
        local lrcCache = Lyrics.getCachePath(sObj)
        if isfile(lrcCache) then
            pcall(delfile, lrcCache)
        end
        local cKey = Lyrics.getCacheKey(sObj)
        if State.noLyrics[cKey] ~= nil then
            State.noLyrics[cKey] = nil
            saveState()
        end
        local idxPos = table.find(RT.songs, sObj)
        if idxPos then
            table.remove(RT.songs, idxPos)
        end
        RT.songRows[sObj] = nil
        row:Destroy()
        refreshPlayStateUI()
    end)

    connect(row.MouseEnter, function()
        if RT.cur ~= sObj then
            row.BackgroundColor3 = CLR.BG_ELEVATED
        end
    end)
    connect(row.MouseLeave, function()
        if RT.cur ~= sObj then
            row.BackgroundColor3 = CLR.BG_SURFACE
        end
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

    UI.LyricsLayer = make("Frame", UI.Gui, {
        Name = "xzypLyricsLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 1,
        Visible = Opts.lyrics,
    })

    UI.LyricsAnchor = make("Frame", UI.LyricsLayer, {
        Name = "LyricsAnchor",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.25),
        Size = UDim2.fromOffset(0, 0),
        Rotation = -3.5,
        BackgroundTransparency = 1,
        ZIndex = 1,
    })

    UI.Root = make("Frame", UI.Gui, {
        Name = "xzypRoot",
        Size = UDim2.fromOffset(CFG.PLAYER_W, CFG.FULL_H),
        Position = UDim2.new(1, -(CFG.PLAYER_W + 24), 1, -(CFG.FULL_H + 24)),
        BackgroundTransparency = 1,
        ZIndex = 5,
    })
    UI.RootScale = make("UIScale", UI.Root, { Scale = Opts.scale })

    UI.SubtleLyricNotice = make("TextLabel", UI.Root, {
        Name = "SubtleLyricNotice",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 0, -6),
        Size = UDim2.fromOffset(230, 20),
        BackgroundColor3 = CLR.BG_WINDOW,
        BackgroundTransparency = 0.16,
        BorderSizePixel = 0,
        Text = "",
        TextColor3 = Color3.fromRGB(165, 168, 182),
        Font = Enum.Font.BuilderSans,
        TextSize = 10,
        Visible = false,
        ZIndex = 6,
    })
    make("UICorner", UI.SubtleLyricNotice, { CornerRadius = UDim.new(1, 0) })
    UI.SubtleNoticeStroke = make("UIStroke", UI.SubtleLyricNotice, {
        Thickness = 1,
        Color = CLR.BORDER_LINE,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })

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
        Size = UDim2.fromOffset(132, CFG.TOPBAR_H),
        BackgroundTransparency = 1,
        Text = "xzyp music player",
        TextColor3 = CLR.TEXT_SECONDARY,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    })

    local function makeHeaderPill(pos, size, text, isAccent, textSize)
        local bgCol = CLR.BG_SURFACE
        local fgCol = CLR.TEXT_SECONDARY
        if isAccent then
            bgCol = getAccent()
            fgCol = getAccentText()
        end

        local b = make("TextButton", UI.TopBar, {
            Position = pos,
            Size = size,
            BackgroundColor3 = bgCol,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = text,
            TextColor3 = fgCol,
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
            elseif b == UI.LyricsBtn then
                if Opts.lyrics and (RT.cur == nil or #RT.lyricCues > 0) then
                    tween(b, 0.12, { BackgroundTransparency = 0.15 })
                else
                    tween(b, 0.12, { BackgroundColor3 = CLR.BG_ELEVATED })
                end
            else
                tween(b, 0.12, { BackgroundColor3 = CLR.BG_ELEVATED, TextColor3 = CLR.TEXT_PRIMARY })
            end
        end)
        connect(b.MouseLeave, function()
            if isAccent then
                tween(b, 0.12, { BackgroundTransparency = 0 })
            elseif b == UI.LyricsBtn then
                tween(b, 0.12, { BackgroundTransparency = 0 })
                Lyrics.syncButtonVisual()
            else
                tween(b, 0.12, { BackgroundColor3 = CLR.BG_SURFACE, TextColor3 = CLR.TEXT_SECONDARY })
            end
        end)
        return b
    end

    UI.LyricsBtn = makeHeaderPill(UDim2.fromOffset(160, 4), UDim2.fromOffset(46, 20), "LYRICS", false, 8)
    Lyrics.syncButtonVisual()

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

    local initialCover = RT.defaultCover
    if RT.lastSong then
        initialCover = coverOf(RT.lastSong)
    end

    UI.CoverImg = make("ImageLabel", ArtFrame, {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = CLR.BG_SURFACE,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Image = initialCover,
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

    local initialTitle = "Library is empty"
    if #RT.songs > 0 then
        initialTitle = "No track playing"
    end

    UI.TrackTitle = make("TextLabel", TitleViewport, {
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(198, 19),
        BackgroundTransparency = 1,
        Text = initialTitle,
        TextColor3 = CLR.TEXT_PRIMARY,
        Font = Enum.Font.BuilderSansBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local subSuffix = " tracks available"
    if #RT.songs == 1 then
        subSuffix = " track available"
    end

    UI.TrackSub = make("TextLabel", Body, {
        Position = UDim2.fromOffset(112, 31),
        Size = UDim2.fromOffset(198, 14),
        BackgroundTransparency = 1,
        Text = tostring(#RT.songs) .. subSuffix,
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
        local bgTrans = 1
        if withBox then
            bgTrans = 0
        end
        local b = make("TextButton", Body, {
            Position = pos,
            Size = size,
            BackgroundColor3 = CLR.BG_SURFACE,
            BackgroundTransparency = bgTrans,
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
            if withBox then
                tween(b, 0.1, { BackgroundColor3 = CLR.BG_ELEVATED })
            end
        end)
        connect(b.MouseLeave, function()
            if not b:GetAttribute("Active") then
                tween(b, 0.1, { TextColor3 = CLR.TEXT_SECONDARY })
            end
            if withBox then
                tween(b, 0.1, { BackgroundColor3 = CLR.BG_SURFACE })
            end
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
    connect(UI.PlayCircle.MouseEnter, function()
        tween(PlayScale, 0.12, { Scale = 1.07 })
    end)
    connect(UI.PlayCircle.MouseLeave, function()
        tween(PlayScale, 0.12, { Scale = 1 })
    end)

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
        local activeCol = Color3.fromRGB(175, 180, 192)
        if vol == 0 then
            activeCol = CLR.STATUS_ERR
        end
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
        Image = initialCover,
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
        local bgCol = CLR.BG_SURFACE
        local fgCol = CLR.TEXT_SECONDARY
        if RT.activeFilter == filterKey then
            bgCol = getAccent()
            fgCol = getAccentText()
        end

        local b = make("TextButton", UI.DrawerPanel, {
            Position = UDim2.fromOffset(xOff, 8),
            Size = UDim2.fromOffset(w, 22),
            BackgroundColor3 = bgCol,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = label,
            TextColor3 = fgCol,
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

UIAnim.initAll()

do
    connect(UI.LyricsBtn.Activated, function()
        Opts.lyrics = not Opts.lyrics
        State.lyrics = Opts.lyrics
        UI.LyricsLayer.Visible = Opts.lyrics
        if not Opts.lyrics then
            Lyrics.clearGlyphs(true)
            RT.lyricStateKey = ""
            Lyrics.showSubtleNotice("\u{266A}  Lyrics overlay turned OFF")
        else
            if RT.cur ~= nil and #RT.lyricCues == 0 and RT.lyricStatus ~= "SEARCHING" then
                Lyrics.showSubtleNotice("\u{266A}  Lyrics ON (No lyrics on this track)")
            else
                Lyrics.showSubtleNotice("\u{266A}  Lyrics overlay turned ON")
            end
        end
        syncModeButtons()
        saveState()
    end)

    connect(UI.AddBtn.Activated, function()
        UIAnim.setSubPanelAnimated(UI.ImportPanel, not UI.ImportPanel.Visible)
    end)

    connect(UI.QueueBtn.Activated, function()
        local willShow = not UI.DrawerPanel.Visible
        if willShow and UI.SettingsPanel.Visible then
            UIAnim.setSubPanelAnimated(UI.SettingsPanel, false)
        end
        UIAnim.setSubPanelAnimated(UI.DrawerPanel, willShow)
    end)

    connect(UI.CfgBtn.Activated, function()
        local willShow = not UI.SettingsPanel.Visible
        if willShow and UI.DrawerPanel.Visible then
            UIAnim.setSubPanelAnimated(UI.DrawerPanel, false)
        end
        UIAnim.setSubPanelAnimated(UI.SettingsPanel, willShow)
    end)

    local function setMinimized(state)
        UIAnim.setMinimizedAnimated(state)
    end

    connect(UI.MiniBtn.Activated, function()
        setMinimized(true)
    end)
    connect(UI.MiniExpand.Activated, function()
        setMinimized(false)
    end)

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
            if not dragging then
                return
            end
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

    connect(UI.PrevBtn.Activated, function()
        step(-1)
    end)
    connect(UI.PlayCircle.Activated, togglePlay)
    connect(UI.NextBtn.Activated, function()
        step(1)
    end)
    connect(UI.MiniPrev.Activated, function()
        step(-1)
    end)
    connect(UI.MiniPlay.Activated, togglePlay)
    connect(UI.MiniNext.Activated, function()
        step(1)
    end)

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
        UIAnim.setSeekKnobAnimated(true)
        UI.HoverTimeTip.Visible = true
        tween(UI.SeekTrack, 0.1, { Size = UDim2.new(1, 0, 0, 5) })
    end)
    connect(UI.SeekHit.MouseLeave, function()
        RT.seekHovering = false
        UIAnim.setSeekKnobAnimated(false)
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
                local len = 0
                if RT.cur then
                    len = Sound.TimeLength
                end
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
                RT.lyricStateKey = ""
                RT.lastSyncPos = t
                RT.silenceTimer = 0
                Lyrics.clearGlyphs(true)
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
        local len = 0
        if RT.cur then
            len = Sound.TimeLength
        end

        local pos = 0
        if RT.seeking then
            pos = RT.seekFrac * len
        elseif RT.cur then
            if RT.playing then
                pos = Sound.TimePosition
            else
                pos = RT.pausedAt
            end
        end

        local ratio = 0
        if len > 0 then
            ratio = math.clamp(pos / len, 0, 1)
        end
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
                local offset = 0
                if phase <= span then
                    offset = math.min(RT.titleOverflow, phase)
                else
                    offset = math.max(0, span * 2 - phase)
                end
                UI.TrackTitle.Position = UDim2.fromOffset(-offset, 0)
            end
        end

        local t = os.clock()
        local rawLoud = Sound.PlaybackLoudness
        local loud = 0
        if RT.playing then
            loud = math.clamp(rawLoud / 300, 0, 1)
        end

        UIAnim.updateBeatVisuals(dt, rawLoud)

        local acc = getAccent()
        for i = 1, CFG.EQ_COUNT do
            local wave = 0
            if RT.playing then
                wave = 0.4 + 0.6 * math.abs(math.sin(t * (5.5 + i * 0.7) + i * 1.1))
            end
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

        if UI.SubtleLyricNotice and UI.SubtleLyricNotice.Visible then
            local rem = RT.subtleNoticeExpire - t
            if rem <= 0 then
                UI.SubtleLyricNotice.Visible = false
            elseif rem < 0.45 then
                local fade = 1 - (rem / 0.45)
                UI.SubtleLyricNotice.TextTransparency = 0.08 + fade * 0.92
                UI.SubtleLyricNotice.BackgroundTransparency = 0.16 + fade * 0.84
                if UI.SubtleNoticeStroke then
                    UI.SubtleNoticeStroke.Transparency = 0.2 + fade * 0.8
                end
            end
        end

        if RT.playing and Sound.IsPlaying and rawLoud < 2.0 then
            RT.silenceTimer += dt
        else
            RT.silenceTimer = 0
        end

        if Opts.lyrics and RT.cur and #RT.lyricCues > 0 then
            local syncPos = pos + Opts.lyricOffset
            if math.abs(syncPos - RT.lastSyncPos) > 0.45 then
                RT.lyricStateKey = ""
                Lyrics.clearGlyphs(true)
            end
            RT.lastSyncPos = syncPos

            local foundIdx = 0
            local lo, hi = 1, #RT.lyricCues
            while lo <= hi do
                local mid = math.floor((lo + hi) * 0.5)
                if RT.lyricCues[mid].time <= syncPos then
                    foundIdx = mid
                    lo = mid + 1
                else
                    hi = mid - 1
                end
            end

            local activeCue = nil
            if foundIdx > 0 and RT.silenceTimer < 1.2 then
                local candidate = RT.lyricCues[foundIdx]
                if syncPos <= candidate.endTime then
                    activeCue = candidate
                end
            end

            if activeCue then
                local cueSpan = math.max(0.25, activeCue.endTime - activeCue.time)
                RT.lyricLineProgress = math.clamp((syncPos - activeCue.time) / cueSpan, 0, 1)

                local nextKey = "LINE_" .. tostring(foundIdx)
                if nextKey ~= RT.lyricStateKey then
                    RT.lyricStateKey = nextKey
                    RT.lyricIsPauseCue = false
                    local nextCueObj = RT.lyricCues[foundIdx + 1]
                    local nextTxt = ""
                    if nextCueObj and type(nextCueObj.text) == "string" then
                        nextTxt = nextCueObj.text
                    end
                    Lyrics.spawnLine(activeCue.text, false, nextTxt)
                end
            else
                RT.lyricLineProgress = 0
                local pauseTxt = getPauseIndicatorText()
                local nextKey = "PAUSE_NONE"
                if pauseTxt then
                    nextKey = "PAUSE_" .. Opts.lyricPauseMode
                end
                if nextKey ~= RT.lyricStateKey then
                    RT.lyricStateKey = nextKey
                    RT.lyricIsPauseCue = true
                    if pauseTxt then
                        Lyrics.spawnLine(pauseTxt, true, "")
                    else
                        Lyrics.clearGlyphs(false)
                    end
                end
            end
        end

        if UI.LyricsAnchor then
            if RT.activeLyricStyle == "subtitle" then
                UI.LyricsAnchor.Rotation = 0
                UI.LyricsAnchor.Position = UDim2.fromScale(0.5, 0.25)
            else
                UI.LyricsAnchor.Rotation = -3.5 + math.sin(t * 1.35) * 0.65
                UI.LyricsAnchor.Position = UDim2.new(0.5, 0, 0.25, math.cos(t * 1.7) * 3)
            end
        end

        local easeK = math.min(1, dt * 18)
        local lyricCol = getLyricColor()
        local unsungCol = Color3.fromRGB(165, 162, 185)
        local loudNorm = 0
        if RT.playing then
            loudNorm = math.clamp(rawLoud / 260, 0, 1)
        end

        for i = 1, #RT.activeGlyphs do
            local g = RT.activeGlyphs[i]
            g.age += dt
            if g.age >= g.delay then
                g.curX += (g.targetX - g.curX) * easeK
                g.curY += (g.targetY - g.curY) * easeK
                g.rot += (0 - g.rot) * easeK

                local targetScale = 1.0
                local targetAlpha = 0
                local extraY = 0
                local stKey = g.styleKey or "kinetic"

                if stKey == "karaoke" and not g.isPause then
                    local sung = (RT.lyricLineProgress >= g.charFrac)
                    if sung then
                        g.label.TextColor3 = lyricCol
                        targetScale = 1.06
                        extraY = -2.5
                        targetAlpha = 0
                    else
                        g.label.TextColor3 = unsungCol
                        targetScale = 0.96
                        targetAlpha = 0.28
                    end
                elseif stKey == "typewriter" and not g.isPause then
                    local revealPoint = g.charFrac * 0.55
                    if RT.lyricLineProgress >= revealPoint then
                        targetAlpha = 0
                        targetScale = 1.0
                    else
                        targetAlpha = 1
                    end
                    g.label.TextColor3 = lyricCol
                elseif stKey == "wave" and not g.isPause then
                    g.label.TextColor3 = lyricCol
                    local waveAmp = 2.4 + (loudNorm * 7.5)
                    if RT.playing then
                        extraY = math.sin(t * 6.5 - g.phase) * waveAmp
                    end
                    targetScale = 1.0 + (loudNorm * 0.08)
                elseif stKey == "neon" and not g.isPause then
                    g.label.TextColor3 = lyricCol
                    targetScale = 1.0 + (loudNorm * 0.12)
                    g.stroke.Color = CLR.LYRIC_STROKE:Lerp(lyricCol, 0.35 + loudNorm * 0.45)
                    g.stroke.Thickness = 2.4 + (loudNorm * 2.4)
                    if RT.playing then
                        extraY = math.sin(t * 4.5 - g.phase) * 1.4
                    end
                else
                    g.label.TextColor3 = lyricCol
                    local waveSpeed = 4.2
                    local waveAmp = 1.6
                    if g.isPause then
                        waveSpeed = 5.2
                        waveAmp = 3.0
                    end
                    if RT.playing then
                        extraY = math.sin(t * waveSpeed - g.phase) * waveAmp
                    end
                end

                g.scale += (targetScale - g.scale) * easeK
                g.alpha += (targetAlpha - g.alpha) * easeK

                g.label.Position = UDim2.fromOffset(g.curX, g.curY + extraY)
                g.label.Rotation = g.rot
                if g.uiScale then
                    g.uiScale.Scale = g.scale
                end
                g.label.TextTransparency = g.alpha
                g.stroke.Transparency = math.min(1, g.alpha + 0.12)
            end
        end

        for i = #RT.exitingGlyphs, 1, -1 do
            local g = RT.exitingGlyphs[i]
            g.exitAge += dt
            local bDelay = g.breakDelay or 0
            if g.exitAge >= bDelay then
                local activeExit = g.exitAge - bDelay
                local p = math.clamp(activeExit / g.exitLife, 0, 1)
                if p >= 1 then
                    if g.label then
                        g.label:Destroy()
                    end
                    table.remove(RT.exitingGlyphs, i)
                else
                    g.curX += g.vx * dt
                    g.curY += g.vy * dt
                    g.vy += (g.gravity or 240) * dt
                    g.vx *= (1 - math.min(0.5, dt * 1.6))

                    local curScale = g.startScale + (g.endScale - g.startScale) * p
                    local a = g.startAlpha + (1 - g.startAlpha) * (p * p)
                    g.label.Position = UDim2.fromOffset(g.curX, g.curY)
                    g.label.Rotation += g.vRot * dt
                    if g.uiScale then
                        g.uiScale.Scale = curScale
                    end
                    g.label.TextTransparency = a
                    g.stroke.Transparency = math.min(1, a + 0.1)
                end
            end
        end
    end)
end

local function detectAudioFormat(buf)
    if type(buf) ~= "string" or #buf < 4096 then
        return nil
    end
    local head4 = buf:sub(1, 4)
    if head4 == "OggS" then
        return "ogg"
    end
    if head4 == "RIFF" and buf:sub(9, 12) == "WAVE" then
        return "wav"
    end
    if buf:sub(1, 3) == "ID3" then
        return "mp3"
    end
    local b1, b2 = buf:byte(1), buf:byte(2)
    if b1 == 0xFF and (b2 == 0xFB or b2 == 0xF3 or b2 == 0xF2 or b2 == 0xE3 or b2 == 0xE2) then
        return "mp3"
    end
    return nil
end

local function extractSpotifyTrackId(raw)
    if not raw then
        return nil
    end
    return raw:match("open%.spotify%.com/[^%s]*/?track/([%w]+)")
        or raw:match("open%.spotify%.com/track/([%w]+)")
        or raw:match("spotify:track:([%w]+)")
end

local function extractVideoId(raw)
    if not raw then
        return nil
    end
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

local function saveImageFromUrl(imgUrl, fileBase)
    if type(imgUrl) ~= "string" or not imgUrl:match("^https?://") then
        return nil
    end
    local res = safeGet(imgUrl)
    if res and res.Body and #res.Body > 1024 then
        local b1, b2 = res.Body:byte(1), res.Body:byte(2)
        local isJpg = (b1 == 0xFF and b2 == 0xD8)
        local isPng = (res.Body:sub(2, 4) == "PNG")
        if isJpg or isPng then
            local ext = ".jpg"
            if isPng then
                ext = ".png"
            end
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
        if p then
            return p
        end
    end
    return nil
end

local function fetchSpotifyTrackById(trackId)
    local trackUrl = "https://open.spotify.com/track/" .. trackId
    local oembed = safeGet("https://open.spotify.com/oembed?url=" .. SRV.Http:UrlEncode(trackUrl), { ["Accept"] = "application/json" })
    if not (oembed and oembed.Body) then
        return nil
    end

    local ok, data = pcall(function()
        return SRV.Http:JSONDecode(oembed.Body)
    end)
    if not (ok and type(data) == "table" and data.title) then
        return nil
    end

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

    local qBase = title
    if artist then
        qBase = artist .. " - " .. title
    end

    return {
        title = title,
        creator = artist or "Spotify Artist",
        searchQuery = qBase .. " official audio",
        coverUrl = thumb,
    }
end

local function tryMatchOnSpotify(ytTitle)
    if not ytTitle or #ytTitle < 2 then
        return nil
    end

    local verTags = Lyrics.getVersionTags(ytTitle)
    if verTags.remix or verTags.slowed or verTags.spedup then
        return nil
    end

    local cleanQuery = Lyrics.stripTitleNoise(ytTitle)
    if #cleanQuery < 3 then
        return nil
    end

    local dashArtist, dashTitle = cleanQuery:match("^(.-)%s+[%-%–%—]%s+(.+)$")
    local expectedTitle = cleanQuery
    local expectedArtist = nil
    if dashArtist and dashTitle and #dashArtist >= 2 and #dashTitle >= 2 then
        expectedArtist = dashArtist
        expectedTitle = dashTitle
    end

    local tokRes = safeGet("https://open.spotify.com/get_access_token?reason=transport&productType=web_player", { ["Accept"] = "application/json" })
    if not (tokRes and tokRes.Body) then
        return nil
    end

    local okT, tokData = pcall(function()
        return SRV.Http:JSONDecode(tokRes.Body)
    end)
    local token = nil
    if okT and type(tokData) == "table" then
        token = tokData.accessToken
    end
    if type(token) ~= "string" or #token < 10 then
        return nil
    end

    local searchUrl = "https://api.spotify.com/v1/search?type=track&limit=5&q=" .. SRV.Http:UrlEncode(cleanQuery)
    local sRes = safeGet(searchUrl, {
        ["Authorization"] = "Bearer " .. token,
        ["Accept"] = "application/json",
    })
    if not (sRes and sRes.Body) then
        return nil
    end

    local okS, sData = pcall(function()
        return SRV.Http:JSONDecode(sRes.Body)
    end)
    local items = nil
    if okS and type(sData) == "table" and type(sData.tracks) == "table" then
        items = sData.tracks.items
    end
    if type(items) ~= "table" or #items == 0 then
        return nil
    end

    local normFullQuery = Lyrics.normalizeText(cleanQuery)
    for _, item in ipairs(items) do
        if type(item) == "table" and item.name then
            local spTitle = tostring(item.name)
            local spArtist = nil
            if type(item.artists) == "table" and item.artists[1] and item.artists[1].name then
                spArtist = tostring(item.artists[1].name)
            end

            local titleSim = Lyrics.strictTokenCompare(expectedTitle, spTitle)
            local artistOk = false
            if spArtist then
                if expectedArtist then
                    local aSim = Lyrics.strictTokenCompare(expectedArtist, spArtist)
                    artistOk = (aSim >= 0.72)
                else
                    local normSpArtist = Lyrics.normalizeText(spArtist)
                    artistOk = (#normSpArtist >= 3 and normFullQuery:find(normSpArtist, 1, true) ~= nil)
                end
            end

            if titleSim >= 0.80 and artistOk then
                local images = item.album and item.album.images
                local bestImg = nil
                if type(images) == "table" and images[1] then
                    bestImg = images[1].url
                end
                return {
                    title = cleanFileName(spTitle),
                    creator = spArtist and cleanFileName(spArtist) or nil,
                    coverUrl = bestImg,
                }
            end
        end
    end
    return nil
end

local function fetchAndVerifyAudio(downloadUrl, referer)
    if type(downloadUrl) ~= "string" or not downloadUrl:match("^https?://") then
        return nil, nil
    end
    local extra = nil
    if referer then
        extra = { ["Referer"] = referer }
    end
    local res = safeGet(downloadUrl, extra)
    if res and res.Body then
        local fmt = detectAudioFormat(res.Body)
        if fmt then
            return res.Body, fmt
        end
    end
    return nil, nil
end

local function downloadYoutubeById(cleanId, presetTitle, presetCreator, spotifyMeta, fromSpotifyLink)
    if RT.downloading then
        return
    end

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
            local okM, meta = pcall(function()
                return SRV.Http:JSONDecode(metaRes.Body)
            end)
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
            if spotifyMeta.title then
                resolvedTitle = spotifyMeta.title
            end
            if spotifyMeta.creator then
                resolvedCreator = spotifyMeta.creator
            end
        end
    end

    local encodedWatch = SRV.Http:UrlEncode(watchUrl)
    local audioPayload, audioExt = nil, nil

    local keyParam = ""
    if Opts.apiKey ~= "" then
        keyParam = "&apikey=" .. SRV.Http:UrlEncode(Opts.apiKey)
    end

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
        if audioPayload then
            break
        end
        UI.ImportStatus.Text = string.format("Downloading from Youtube (%s %d/%d)...", tc.name, idx, #transcoders)
        log("YT_TRANSCODE", "Starting job on:", tc.name)

        local initRes = safeGet(tc.init, { ["Referer"] = tc.ref, ["Accept"] = "application/json, */*" })
        if initRes and initRes.Body then
            local okJ, initData = pcall(function()
                return SRV.Http:JSONDecode(initRes.Body)
            end)
            if okJ and type(initData) == "table" and initData.id then
                if not resolvedTitle and initData.title then
                    resolvedTitle = cleanFileName(initData.title)
                end
                local pollUrl = tc.prog .. tostring(initData.id)
                if type(initData.progress_url) == "string" and initData.progress_url:match("^https?://") then
                    pollUrl = initData.progress_url
                end

                for attempt = 1, 26 do
                    task.wait(1.4)
                    local pct = math.min(99, math.floor((attempt / 26) * 100))
                    UI.ImportStatus.Text = string.format("Converting Youtube MP3 (%d%%)...", pct)

                    local pRes = safeGet(pollUrl, { ["Referer"] = tc.ref })
                    if pRes and pRes.Body then
                        local okP, pData = pcall(function()
                            return SRV.Http:JSONDecode(pRes.Body)
                        end)
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
            local okV, vData = pcall(function()
                return SRV.Http:JSONDecode(vJob.Body)
            end)
            if okV and type(vData) == "table" then
                local direct = vData.download_url or vData.url
                if direct then
                    local body, fmt = fetchAndVerifyAudio(direct, "https://api.vevioz.com/")
                    if body then
                        audioPayload, audioExt = body, fmt
                    end
                elseif vData.job_id then
                    local tok = ""
                    if vData.token then
                        tok = "?token=" .. tostring(vData.token)
                    end
                    for _ = 1, 15 do
                        task.wait(1.5)
                        local st = safeGet("https://api.vevioz.com/api/v1/jobs/" .. tostring(vData.job_id) .. tok)
                        if st and st.Body then
                            local okS, sData = pcall(function()
                                return SRV.Http:JSONDecode(st.Body)
                            end)
                            if okS and type(sData) == "table" and (sData.download_url or sData.url) then
                                local body, fmt = fetchAndVerifyAudio(sData.download_url or sData.url, "https://api.vevioz.com/")
                                if body then
                                    audioPayload, audioExt = body, fmt
                                end
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
        ytId = cleanId,
    }
    State.meta[cleanId] = {
        title = displayTitle,
        creator = displayCreator,
        source = srcLabel,
        note = transparencyNote,
        ytId = cleanId,
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
    if RT.downloading or RT.searching then
        return
    end
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

    local themeLabel = "Client White"
    if Opts.spotifyGreen then
        themeLabel = "Spotify Green"
    end
    addSettingRow("Accent Theme", themeLabel, function(btn)
        Opts.spotifyGreen = not Opts.spotifyGreen
        State.spotifyGreen = Opts.spotifyGreen
        if Opts.spotifyGreen then
            btn.Text = "Spotify Green"
        else
            btn.Text = "Client White"
        end
        applyThemeAccent()
        refreshPlayStateUI()
        saveState()
    end)

    local lyricsToggleLabel = "OFF"
    if Opts.lyrics then
        lyricsToggleLabel = "ON"
    end
    addSettingRow("Lyrics Overlay", lyricsToggleLabel, function(btn)
        Opts.lyrics = not Opts.lyrics
        State.lyrics = Opts.lyrics
        UI.LyricsLayer.Visible = Opts.lyrics
        if Opts.lyrics then
            btn.Text = "ON"
        else
            btn.Text = "OFF"
            Lyrics.clearGlyphs(true)
            RT.lyricStateKey = ""
        end
        syncModeButtons()
        saveState()
    end)

    local curStylePreset = Lyrics.STYLE_PRESETS[Opts.lyricStyle] or Lyrics.STYLE_PRESETS.kinetic
    addSettingRow("Lyrics Style", curStylePreset.label, function(btn)
        local nextKey = Lyrics.STYLE_ORDER[1]
        for i, k in ipairs(Lyrics.STYLE_ORDER) do
            if k == Opts.lyricStyle then
                nextKey = Lyrics.STYLE_ORDER[(i % #Lyrics.STYLE_ORDER) + 1]
                break
            end
        end
        Opts.lyricStyle = nextKey
        State.lyricStyle = nextKey
        local chosen = Lyrics.STYLE_PRESETS[nextKey] or Lyrics.STYLE_PRESETS.kinetic
        btn.Text = chosen.label
        RT.lyricStateKey = ""
        saveState()
    end)

    local curFontPreset = Lyrics.FONT_PRESETS[Opts.lyricFont] or Lyrics.FONT_PRESETS.modern
    addSettingRow("Lyrics Font Style", curFontPreset.label, function(btn)
        local nextKey = Lyrics.FONT_ORDER[1]
        for i, k in ipairs(Lyrics.FONT_ORDER) do
            if k == Opts.lyricFont then
                nextKey = Lyrics.FONT_ORDER[(i % #Lyrics.FONT_ORDER) + 1]
                break
            end
        end
        Opts.lyricFont = nextKey
        State.lyricFont = nextKey
        local chosen = Lyrics.FONT_PRESETS[nextKey] or Lyrics.FONT_PRESETS.modern
        btn.Text = chosen.label
        RT.lyricStateKey = ""
        saveState()
    end)

    RT.lyricStatusRowBtn = addSettingRow("Lyric Source / Sync", RT.lyricMatchLabel, function()
        if RT.cur then
            Lyrics.loadForSong(RT.cur, true)
        end
    end)

    local transLabels = {
        off = "Original",
        pt = "PT-BR",
        en = "English",
        es = "Español",
    }
    local transOrder = { "off", "pt", "en", "es" }
    addSettingRow("Translate Lyrics", transLabels[Opts.lyricTranslate] or "Original", function(btn)
        local nextLang = transOrder[1]
        for i, l in ipairs(transOrder) do
            if l == Opts.lyricTranslate then
                nextLang = transOrder[(i % #transOrder) + 1]
                break
            end
        end
        Opts.lyricTranslate = nextLang
        State.lyricTranslate = nextLang
        btn.Text = transLabels[nextLang]
        saveState()
        if RT.cur then
            Lyrics.loadForSong(RT.cur, true)
        end
    end)

    addSettingRow("Clear Lyric Cache", "Clear", function(btn)
        local okList, files = pcall(listfiles, PATHS.LYRICS)
        if okList and type(files) == "table" then
            for _, f in ipairs(files) do
                if not isfolder(f) then
                    pcall(delfile, f)
                end
            end
        end
        State.noLyrics = {}
        saveState()
        btn.Text = "Cleared!"
        if RT.cur then
            Lyrics.loadForSong(RT.cur, true)
        end
        task.delay(1.5, function()
            if btn.Parent then
                btn.Text = "Clear"
            end
        end)
    end)

    local lyricColorLabel = "Accent"
    if Opts.lyricPurple then
        lyricColorLabel = "Violet"
    end
    addSettingRow("Lyrics Color", lyricColorLabel, function(btn)
        Opts.lyricPurple = not Opts.lyricPurple
        State.lyricPurple = Opts.lyricPurple
        if Opts.lyricPurple then
            btn.Text = "Violet"
        else
            btn.Text = "Accent"
        end
        applyThemeAccent()
        saveState()
    end)

    local pauseLabels = {
        notes = "\u{266A} \u{2022}\u{2022}\u{2022} \u{266A}",
        note = "\u{266A} Note",
        off = "Hidden",
    }
    local pauseOrder = { "notes", "note", "off" }
    addSettingRow("Pause Break Icon", pauseLabels[Opts.lyricPauseMode] or pauseLabels.notes, function(btn)
        local nextMode = pauseOrder[1]
        for i, m in ipairs(pauseOrder) do
            if m == Opts.lyricPauseMode then
                nextMode = pauseOrder[(i % #pauseOrder) + 1]
                break
            end
        end
        Opts.lyricPauseMode = nextMode
        State.lyricPauseMode = nextMode
        RT.lyricStateKey = ""
        btn.Text = pauseLabels[nextMode]
        saveState()
    end)

    local offsetSteps = { -1.0, -0.5, -0.2, 0.0, 0.2, 0.5, 1.0 }
    addSettingRow("Lyrics Sync Offset", string.format("%+.1fs", Opts.lyricOffset), function(btn)
        local nextOff = offsetSteps[4]
        for i, v in ipairs(offsetSteps) do
            if math.abs(v - Opts.lyricOffset) < 0.05 then
                nextOff = offsetSteps[(i % #offsetSteps) + 1]
                break
            end
        end
        Opts.lyricOffset = nextOff
        State.lyricOffset = nextOff
        btn.Text = string.format("%+.1fs", nextOff)
        saveState()
    end)

    local disclaimerRow = make("Frame", UI.SettingsScroll, {
        Size = UDim2.new(1, -4, 0, 20),
        BackgroundColor3 = CLR.BG_WINDOW,
        BorderSizePixel = 0,
    })
    make("UICorner", disclaimerRow, { CornerRadius = UDim.new(0, 5) })
    make("TextLabel", disclaimerRow, {
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -16, 1, 0),
        BackgroundTransparency = 1,
        Text = "Note: Lyrics & STT may not be 100% accurate sometimes.",
        TextColor3 = CLR.TEXT_MUTED,
        Font = Enum.Font.BuilderSans,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local rainbowLabel = "OFF"
    if Opts.rainbow then
        rainbowLabel = "ON"
    end
    addSettingRow("Rainbow Visualizer", rainbowLabel, function(btn)
        Opts.rainbow = not Opts.rainbow
        State.rainbow = Opts.rainbow
        if Opts.rainbow then
            btn.Text = "ON"
        else
            btn.Text = "OFF"
        end
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

    local keyLabel = "None"
    if RT.hideKey then
        keyLabel = RT.hideKey.Name
    end
    addSettingRow("Toggle UI Keybind", keyLabel, function(btn)
        RT.listeningKey = true
        btn.Text = "Press key..."
        local conn
        conn = SRV.UIS.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                RT.listeningKey = false
                if input.KeyCode ~= Enum.KeyCode.Escape then
                    RT.hideKey = input.KeyCode
                    State.hideKey = input.KeyCode.Name
                    btn.Text = input.KeyCode.Name
                else
                    RT.hideKey = nil
                    State.hideKey = ""
                    btn.Text = "None"
                end
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

    local sttRow = make("Frame", UI.SettingsScroll, {
        Size = UDim2.new(1, -4, 0, 26),
        BackgroundColor3 = CLR.BG_SURFACE,
        BorderSizePixel = 0,
    })
    make("UICorner", sttRow, { CornerRadius = UDim.new(0, 6) })

    make("TextLabel", sttRow, {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.fromOffset(92, 26),
        BackgroundTransparency = 1,
        Text = "STT Key (Whisper)",
        TextColor3 = CLR.TEXT_PRIMARY,
        Font = Enum.Font.BuilderSans,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local sttBox = make("TextBox", sttRow, {
        Position = UDim2.new(1, -226, 0.5, -9),
        Size = UDim2.fromOffset(218, 18),
        BackgroundColor3 = CLR.BG_WINDOW,
        BorderSizePixel = 0,
        Text = Opts.sttKey,
        PlaceholderText = "gsk_... or sk-... (optional)",
        PlaceholderColor3 = CLR.TEXT_MUTED,
        TextColor3 = CLR.TEXT_PRIMARY,
        Font = Enum.Font.BuilderSans,
        TextSize = 10,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
    })
    make("UICorner", sttBox, { CornerRadius = UDim.new(0, 4) })
    connect(sttBox.FocusLost, function()
        Opts.sttKey = sttBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        State.sttKey = Opts.sttKey
        saveState()
    end)

    addSettingRow("Copy Debug Logs", "Copy", function(btn)
        local ok = copyLogsToClipboard()
        if ok then
            btn.Text = "Copied!"
        else
            btn.Text = "Saved!"
        end
        task.delay(1.5, function()
            if btn.Parent then
                btn.Text = "Copy"
            end
        end)
    end)

    addSettingRow("Unload Player", "Close", function()
        Lyrics.clearGlyphs(true)
        tween(Sound, 0.25, { Volume = 0 })
        task.wait(0.25)
        cleanup()
    end)

    connect(UI.CloseBtn.Activated, function()
        Lyrics.clearGlyphs(true)
        tween(Sound, 0.25, { Volume = 0 })
        task.wait(0.25)
        cleanup()
    end)

    connect(SRV.UIS.InputBegan, function(input, gp)
        if gp or RT.listeningKey or not RT.hideKey or SRV.UIS:GetFocusedTextBox() then
            return
        end
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
        ShowLyric = Lyrics.spawnLine,
        ReverifyLyrics = function()
            if RT.cur then
                Lyrics.loadForSong(RT.cur, true)
            end
        end,
        GetLyricStatus = function()
            return RT.lyricStatus, RT.lyricMatchLabel, RT.lyricSourceName
        end,
    }
end

log("INIT", "xzyp music player ready.")
