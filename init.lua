-- ElevateV4 GitHub bootstrap with key authentication.
if shared.elevatedeveloper ~= nil then
    shared.ElevateDeveloper = shared.elevatedeveloper
end

local Owner = "soryedforgive"
local Repository = "ElevateV4"
local Branch = "main"
local Directory = shared.ElevateDeveloper and "elevatev4private" or "elevatev4"
local RawBase = `https://raw.githubusercontent.com/{Owner}/{Repository}/{Branch}/`

-- Replace with your worker URL from: npx wrangler deploy
local AUTH_URL = "https://keyauth.weikauth.workers.dev/auth"

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local HttpService = game:GetService("HttpService")
local analyticsService = game:GetService("RbxAnalyticsService")
local localPlayer = game:GetService("Players").LocalPlayer

local isfile = isfile or function(Path)
    local Ok, Result = pcall(readfile, Path)
    return Ok and type(Result) == "string" and #Result > 0
end

local function EnsureFolder(Path)
    local Current = ""
    for Segment in string.gmatch(Path, "[^/]+") do
        Current = Current == "" and Segment or `{Current}/{Segment}`
        if not isfolder(Current) then
            makefolder(Current)
        end
    end
end

local function EnsureParent(Path)
    local Parent = Path:match("^(.*)/[^/]+$")
    if Parent then
        EnsureFolder(Parent)
    end
end

for _, Folder in {Directory, `{Directory}/games`, `{Directory}/profiles`, `{Directory}/assets`, `{Directory}/libraries`, `{Directory}/guis`} do
    EnsureFolder(Folder)
end

-- Resolve key: check License table (teleport re-exec), then all env sources, then saved file.
local License = ... or {}
local function resolveKey()
    local sources = {
        License.Key,
        getgenv().script_key,
        getgenv().ElevateKey,
        _G.script_key,
        shared.script_key,
        shared.ElevateV4Key,
    }
    for _, v in sources do
        if type(v) == "string" then
            local trimmed = v:match("^%s*(.-)%s*$")
            if trimmed and #trimmed > 0 then
                return trimmed
            end
        end
    end
    if isfile(`{Directory}/profiles/script_key.txt`) then
        local body = readfile(`{Directory}/profiles/script_key.txt`)
        local trimmed = body:match("^%s*(.-)%s*$")
        if trimmed and #trimmed > 0 then
            return trimmed
        end
    end
    return nil
end

local function getHwid()
    if gethwid then
        local ok, id = pcall(gethwid)
        if ok and id then return tostring(id) end
    end
    return analyticsService:GetClientId()
end

local scriptKey = resolveKey()

-- Skip auth if already authenticated this session (teleport re-exec sets this).
local alreadyAuthed = getgenv()._elevateAuthed == true and type(scriptKey) == "string" and #scriptKey > 0

if not alreadyAuthed then
    if not scriptKey then
        localPlayer:Kick("[Elevate] No key provided.")
        task.wait(9e9)
        return
    end

    local ok, response = pcall(request, {
        Url = AUTH_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({key = scriptKey, hwid = getHwid(), game = "bedwars"}),
    })

    if not ok or not response or not response.Body then
        localPlayer:Kick("[Elevate] Auth server unreachable.")
        task.wait(9e9)
        return
    end

    local decoded, data = pcall(HttpService.JSONDecode, HttpService, response.Body)
    if not decoded or type(data) ~= "table" then
        localPlayer:Kick("[Elevate] Auth error " .. tostring(response.StatusCode))
        task.wait(9e9)
        return
    end

    if not data.success then
        if response.StatusCode == 429 then
            warn("[Elevate] Too many attempts, wait a moment.")
            return
        end
        localPlayer:Kick("[Elevate] Invalid key: " .. tostring(data.message))
        task.wait(9e9)
        return
    end
end

-- Propagate key so teleport re-exec and main.lua both find it.
getgenv().script_key = scriptKey
getgenv().ElevateKey = scriptKey
_G.script_key = scriptKey
getgenv()._elevateAuthed = true
shared.ElevateV4Key = scriptKey
License.Key = scriptKey

pcall(function()
    EnsureFolder(`{Directory}/profiles`)
    writefile(`{Directory}/profiles/script_key.txt`, scriptKey)
end)

-- Original ElevateV4 bootstrap below (unmodified).
if not shared.ElevateDeveloper then
    local function Fetch(Path)
        return game:HttpGet(RawBase .. Path, true)
    end

    local ManifestOk, ManifestText = pcall(Fetch, "manifest.json")
    if not ManifestOk or type(ManifestText) ~= "string" then
        error("ElevateV4: unable to read manifest.json from GitHub.")
    end

    local DecodeOk, Manifest = pcall(HttpService.JSONDecode, HttpService, ManifestText)
    if not DecodeOk or typeof(Manifest) ~= "table" or typeof(Manifest.files) ~= "table" then
        error("ElevateV4: manifest.json is invalid.")
    end

    local VersionOk, Version = pcall(Fetch, "version.txt")
    if not VersionOk or type(Version) ~= "string" then
        error("ElevateV4: unable to read version.txt from GitHub.")
    end
    Version = Version:gsub("%s+$", "")

    local CommitPath = `{Directory}/profiles/commit.txt`
    local IsNewUser = not isfile(CommitPath)
    local CachedVersion = IsNewUser and "" or readfile(CommitPath)

    if IsNewUser or CachedVersion ~= Version then
        local Failed = {}
        for _, RelativePath in Manifest.files do
            if type(RelativePath) ~= "string" or RelativePath == "" then
                continue
            end
            if not IsNewUser and RelativePath:match("^profiles/") then
                continue
            end

            local Target = `{Directory}/{RelativePath}`
            EnsureParent(Target)
            local Ok, Contents = pcall(Fetch, RelativePath)
            if Ok and type(Contents) == "string" and Contents ~= "404: Not Found" then
                local WriteOk = pcall(writefile, Target, Contents)
                if not WriteOk then
                    table.insert(Failed, RelativePath)
                end
            else
                table.insert(Failed, RelativePath)
            end
        end

        if #Failed == 0 then
            EnsureParent(CommitPath)
            writefile(CommitPath, Version)
            shared.updated = CachedVersion ~= "" and CachedVersion or nil
        else
            warn(`ElevateV4 update incomplete ({#Failed} file(s)); the previous cached build was kept where possible.`)
            warn(table.concat(Failed, ", "))
        end
    end
end

local MainPath = `{Directory}/main.lua`
if not isfile(MainPath) then
    local Source = game:HttpGet(RawBase .. "main.lua", true)
    writefile(MainPath, Source)
end

return loadstring(readfile(MainPath), "ElevateV4-main")(License)
