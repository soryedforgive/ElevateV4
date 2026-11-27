-- ElevateV4 GitHub bootstrap
-- Public raw GitHub access is required for the in-game loader.
if shared.elevatedeveloper ~= nil then
    shared.ElevateDeveloper = shared.elevatedeveloper
end
local Owner = "soryedforgive"
local Repository = "ElevateV4"
local Branch = "main"
local Directory = shared.ElevateDeveloper and "elevatev4private" or "elevatev4"
local RawBase = `https://raw.githubusercontent.com/{Owner}/{Repository}/{Branch}/`

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local HttpService = game:GetService("HttpService")
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

if not shared.ElevateDeveloper then
    local function Fetch(Path)
        return game:HttpGet(RawBase .. Path, true)
    end

    local ManifestOk, ManifestText = pcall(Fetch, "manifest.json")
    if not ManifestOk or type(ManifestText) ~= "string" then
        error("ElevateV4: unable to read manifest.json from GitHub. Check that the repository is public and the main branch exists.")
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

return loadstring(readfile(MainPath), "ElevateV4-main")({})
