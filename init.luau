--!strict
--[[
    Rnox/init.luau
    An all-in-one tool for protecting users from malicious code
    Originally based on Guardian V2 by galactichypernova

    https://github.com/audio-wav/Rnox
    https://github.com/audio-wav/Rnox/wiki
    https://discord.gg/Q2sd6YEUZc

    https://github.com/GalacticHypernova/Guardian

    Core.Rnox:SetAll(true) to enable all protections
    Settings.Output can be set to a custom function 
    to change how notifications are outputted
]]

if not game:IsLoaded() then game.Loaded:Wait() end
local getgenv: typeof(getgenv) = getgenv or getfenv :: any
if getgenv().RnoxLoaded then return end
getgenv().RnoxLoaded = true

local Settings = {
    Output = warn :: (...any) -> (),
    MaliciousNamecalls = {
        Enabled = true,
        ShowNamecall = true,
    },
    ChatBan = {
        Enabled = true,
        Slash = true,
        NewChat = true,
    },
    AntiLog = {
        Enabled = true,
        ShowInfo = true,
        ShowDestination = true,
        Payback = true,
    },
    AutoJoin = {
        Enabled = true,
        ShowServer = true,
    },
    AntiApi = {
        Enabled = true,
        ShowEndpoint = true,
    },
    PetSim = {
        Enabled = true,
        ShowUser = true,
        Bank = true,
        Mail = true,
    },
    PetSim99 = true,
    MiningSim = true,
    BeeSwarm = true,
    AntiKick = true,
    MemoryDetections = true,
    GUIDetection = true,
    GroupBypass = true,
    ClearTrace = true,
    AntiError = true,
    AntiMessage = false,
    AntiIdle = true,
}

local RnoxBase = "https://raw.githubusercontent.com/audio-wav/Rnox/main/"
local Loaded = {}

local function Import(Path: string): any
    if Loaded[Path] then return Loaded[Path] end
    local Result = loadstring(game:HttpGet(RnoxBase .. Path))()
    Loaded[Path] = Result
    return Result
end

local Core = Import("core.luau").Build(Settings)
local Modules = {
    Import("modules/chat.luau"),
    Import("modules/namecalls.luau"),
    Import("modules/remotes.luau"),
    Import("modules/memory.luau"),
    Import("modules/network.luau"),
    Import("modules/cleanup.luau"),
}

for _, Module in next, Modules do
    task.spawn(function()
        Module:Init(Core)
    end)
end

Core.Rnox:Notify("Rnox Activated", "Rnox is now protecting you in the background.")