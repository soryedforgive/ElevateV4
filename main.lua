local License = ... or {}
if shared.elevatedeveloper ~= nil then
    shared.ElevateDeveloper = shared.elevatedeveloper
end
local Directory: string = shared.ElevateDeveloper and "elevatev4private" or "elevatev4"
if not game:IsLoaded() then
    game.Loaded:Wait()
end
if shared.elevateloading and coroutine.status(shared.elevateloading) ~= "dead" then
    return
end
shared.elevateloading = coroutine.running()
if shared.vape then
    shared.vape:Uninject()
end
License.Key = License.Key or ""
local Executor: string = identifyexecutor ~= nil and ({identifyexecutor()})[1] or ""
local IsMadium: boolean = Executor == "Madium"
local CanHook: boolean = not table.find({"Madium", "Solara", "Xeno"}, Executor)

for _, Folder: string in {Directory, `{Directory}/games`, `{Directory}/profiles`, `{Directory}/assets`, `{Directory}/libraries`, `{Directory}/guis`} do
    if not isfolder(Folder) then
        makefolder(Folder)
    end
end

if not shared.ElevateDeveloper and isfolder("elevaterewrite") and isfolder("elevaterewrite/profiles") then
    for _, v: string in listfiles("elevaterewrite/profiles") do
        if not v:find("commit.txt") then
            local OldPath: string = v
            v = v:gsub("elevaterewrite", Directory)
            writefile(v, readfile(OldPath))
        end
    end
    delfolder("elevaterewrite/profiles")
end

getgenv().matchDodgeActive = false
for _, Flag: string in {"matchdodge", "regionlock"} do
    if isfile(`{Directory}/profiles/{Flag}.txt`) and readfile(`{Directory}/profiles/{Flag}.txt`) == "true" then
        getgenv().matchDodgeActive = true
    end
end
if getgenv().matchDodgeActive and not getgenv().runv2 and hookmetamethod and CanHook then
    getgenv().runv2 = true
    getgenv().matchDodgeHold = {Held = true, Started = os.clock()}
    getgenv().matchDodgeHold.Release = function()
        local Hold = getgenv().matchDodgeHold
        if not Hold.Held then
            return
        end
        Hold.Held = false
        Hold.Block = nil
        getgenv().dodged = false
        getgenv().Dodged = false
        if Hold.Connect then
            local Connect = Hold.Connect
            Hold.Connect = nil
            Connect.Remote:FireServer(table.unpack(Connect.Args, 1, Connect.Args.n))
        end
        if Hold.Remote then
            Hold.Remote:FireServer()
            Hold.Remote = nil
        end
    end
    local Old
    Old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local Hold = getgenv().matchDodgeHold
        if Hold.Held and not checkcaller() and getnamecallmethod() == "FireServer" then
            local Name: string = tostring(self)
            if Name == "PlayerConnect" then
                Hold.Connect = {Remote = self, Args = table.pack(...)}
                getgenv().Dodged = true
                return
            elseif Name == "PlayerReady" then
                Hold.Remote = self
                getgenv().dodged = true
                return
            end
        end
        return Old(self, ...)
    end))
    task.delay(45, function()
        if not getgenv().matchDodgeHold.Claimed then
            getgenv().matchDodgeHold.Release()
        end
    end)
end

local vape, RunPremium
local loadstring = function(...)
    local Chunk, Error = loadstring(...)
    if Error and vape then
        vape:CreateNotification("Elevate", `Failed to load : {Error}`, 30, "alert")
    end
    return Chunk
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(FilePath: string)
    local Success, Contents = pcall(function()
        return readfile(FilePath)
    end)
    return Success and Contents ~= nil and Contents ~= ""
end
local cloneref = cloneref or function(Reference: Instance)
    return Reference
end
local Players: Players = cloneref(game:GetService("Players"))
local HttpService: HttpService = cloneref(game:GetService("HttpService"))

if IsMadium and game.GameId == 2619619496 and not Players.LocalPlayer:GetAttribute("PlayerConnected") then
    local LogService: LogService = cloneref(game:GetService("LogService"))
    local SetupLine: string = "[SETUP] Set up Flamework Client"
    local SetupDone: boolean = false
    local SetupConnection = LogService.MessageOut:Connect(function(Message: string)
        if string.find(Message, SetupLine, 1, true) then
            SetupDone = true
        end
    end)

    for _, Entry: any in LogService:GetLogHistory() do
        if string.find(Entry.message, SetupLine, 1, true) then
            SetupDone = true
            break
        end
    end

    local WaitStarted: number = os.clock()
    repeat
        task.wait(0.25)
    until SetupDone or os.clock() - WaitStarted > 20
    SetupConnection:Disconnect()
end

local function DownloadFile(FilePath: string, Reader)
    if not isfile(FilePath) then
        local Success, Response = pcall(function()
            return game:HttpGet(`https://raw.githubusercontent.com/soryedforgive/ElevateV4/main/{select(1, FilePath:gsub(`^{Directory}/`, ""))}`, true)
        end)
        if not Success or Response == "404: Not Found" then
            error(Response)
        end
        if FilePath:find(".lua") then
            Response = `--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n{Response}`
        end
        writefile(FilePath, Response)
    end
    return (Reader or readfile)(FilePath)
end

local function FinishLoading()
    vape.Init = nil
    vape:Load()
    shared.elevateloading = nil

    local TeleportedServers: boolean?
    vape:Clean(Players.LocalPlayer.OnTeleport:Connect(function()
        if (not TeleportedServers) and (not shared.ElevateIndependent) then
            TeleportedServers = true
            local TeleportScript: string = [[
				shared.elevatereload = true
				if shared.ElevateDeveloper then
					loadstring(readfile('elevatev4private/main.lua'), 'main')(_scriptconfig)
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/soryedforgive/ElevateV4/main/init.lua', true), 'init')(_scriptconfig)
				end
			]]
            local TeleportConfig: string = HttpService:JSONEncode(License)
            TeleportConfig = TeleportConfig:gsub('":true', "=true"):gsub('{"', "{")
            TeleportConfig = TeleportConfig:gsub(',"', ","):gsub('":', "=")
            TeleportConfig = TeleportConfig:gsub("%[", "{"):gsub("%]", "}")
            TeleportScript = TeleportScript:gsub("_key", tostring(License.Key or "_key"))
            TeleportScript = TeleportScript:gsub("_scriptconfig", TeleportConfig)
            if shared.ElevateDeveloper then
                TeleportScript = `shared.ElevateDeveloper = true\n{TeleportScript}`
            end
            if shared.ElevateCustomProfile then
                TeleportScript = `shared.ElevateCustomProfile = "{shared.ElevateCustomProfile}"\n{TeleportScript}`
            end
            vape:Save()
            queue_on_teleport(TeleportScript)
        end
    end))

    if not shared.elevatereload then
        vape:CreateNotification("Finished Loading", (vape.VapeButton and "Press the button in the top right" or `Press {table.concat(vape.GUIBind and vape.GUIBind.Keys or {"RightShift"}, " + "):upper()}`) .. " to open GUI", 5)
        task.delay(0.05, function()
            if shared.updated then
                vape:CreateNotification("Elevate", `Script has updated from {(shared.updated or ""):sub(1, 8)} to {(readfile(`{Directory}/profiles/commit.txt`) or ""):sub(1, 8)}`, 10, "info")
            end
        end)
    end
end

if not isfile(`{Directory}/profiles/gui.txt`) then
    writefile(`{Directory}/profiles/gui.txt`, "new")
end
local Gui: string = "new"

if not isfolder(`{Directory}/assets/{Gui}`) then
    makefolder(`{Directory}/assets/{Gui}`)
end
vape, RunPremium = loadstring(DownloadFile(`{Directory}/guis/{Gui}.lua`), "gui")(License)
shared.vape = vape
shared.elevatesmooth = false
_G.vape = vape
getgenv().used_init = true

if not shared.ElevateIndependent then
    loadstring(DownloadFile(`{Directory}/games/universal.lua`), "universal")(License)
    if isfile(`{Directory}/games/{game.PlaceId}.lua`) then
        loadstring(readfile(`{Directory}/games/{game.PlaceId}.lua`), tostring(game.PlaceId))(License)
    end
    loadstring(DownloadFile(`{Directory}/libraries/main.lua`), "main")(License)
    FinishLoading()
else
    vape.Init = FinishLoading
    return vape
end