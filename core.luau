--!strict
--[[
    Rnox/core.luau
    - https://github.com/audio-wav/Rnox/wiki
    - https://discord.gg/Q2sd6YEUZc
]]

local function Build(Settings)
    table.freeze(Settings)
    local FrozenSettings = table.freeze(table.clone(Settings))
    local Missing = function(ValueType, Value, Fallback)
        return type(Value) == ValueType and Value or Fallback
    end :: (<T>(ValueType: string, Value: T?, Fallback: T) -> T)
         & (<T>(ValueType: string, Value: T?) -> T?)

    local CloneReference: typeof(cloneref) = Missing("function", cloneref, function(...) return ... end)
    local CloneFunction: typeof(clonefunction) = Missing("function", clonefunction, function(...) return ... end)
    local NewCClosure: typeof(newcclosure) = Missing("function", newcclosure, function(Function) return Function end)
    local HookMetamethod = Missing("function", hookmetamethod)
    local HookFunction = Missing("function", hookfunction)
    local CheckCaller = Missing("function", checkcaller, function() return true end)
    local GetNamecallMethod = Missing("function", getnamecallmethod)
    local GetConnections = Missing("function", getconnections)
    local GetProperties = Missing("function", getproperties)
    local RestoreFunction = Missing("function", restorefunction)
    local GetCallingScript = Missing("function", getcallingscript)
    local GetGarbageCollection = Missing("function", getgc)
    local GetMetatable = CloneFunction(getmetatable)
    local IsExecutorClosure =
        Missing("function", isexecutorclosure)
        or Missing("function", is_synapse_function)
        or Missing("function", iskrnlclosure)
        or Missing("function", issentinelclosure)
        or Missing("function", is_protosmasher_closure)
        or function() return false end
    local RawGet = CloneFunction(rawget)
    local RawRequest =
        Missing("function", request)
        or Missing("function", http_request)
        or (typeof(syn) == "table" and Missing("function", syn.request))
        or (typeof(http) == "table" and Missing("function", http.request))
        or (typeof(fluxus) == "table" and Missing("function", fluxus.request))
        or nil

    type RequestOptions = {
        Url: string,
        Method: string?,
        Headers: {[string]: string}?,
        Body: string?,
    }

    local HttpRequest: ((opts: RequestOptions) -> any)?
    if RawRequest then
        local SafeRawRequest = CloneFunction(RawRequest)
        HttpRequest = NewCClosure(function(opts: RequestOptions): any?
            if GetMetatable(opts) ~= nil then
                Settings.Output("Fuck you")
                return
            end
            local url = RawGet(opts, "Url")
            if type(url) ~= "string" then return end
            return SafeRawRequest({
                Url = url,
                Method = RawGet(opts, "Method") or "GET",
                Headers = RawGet(opts, "Headers"),
                Body = RawGet(opts, "Body"),
            })
        end)
    end
    local StringFind = CloneFunction(string.find)
    local StringMatch = CloneFunction(string.match)
    local StringSub = CloneFunction(string.sub)
    local StringUpper = CloneFunction(string.upper)
    local StringLower = CloneFunction(string.lower)
    local StringFormat = CloneFunction(string.format)
    local TableInsert = CloneFunction(table.insert)
    local MathRandom = CloneFunction(math.random)
    local ProtectedCall = CloneFunction(pcall)
    local Game = CloneReference(game)
    local Players = CloneReference(Game:GetService("Players"))
    local StarterGui = CloneReference(Game:GetService("StarterGui"))
    local HttpService = CloneReference(Game:GetService("HttpService"))
    local Stats = CloneReference(Game:GetService("Stats"))
    local ContentProvider = CloneReference(Game:GetService("ContentProvider"))
    local ScriptContext = CloneReference(Game:GetService("ScriptContext"))
    local LogService = CloneReference(Game:GetService("LogService"))
    local TextChatService = CloneReference(Game:GetService("TextChatService"))
    local ReplicatedStorage = CloneReference(Game:GetService("ReplicatedStorage"))
    local LocalPlayer = Players.LocalPlayer
    local Character: Model = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    local Rnox = {}

    function Rnox:SetAll(Value: boolean): ()
        for Key, Setting in next, Settings do
            if type(Setting) == "table" then
                for SubKey in next, Setting do
                    Settings[Key][SubKey] = Value
                end
            elseif type(Setting) == "boolean" then
                Settings[Key] = Value
            end
        end
    end

    function Rnox:Notify(Title: string, Text: string): ()
        ProtectedCall(function()
            StarterGui:SetCore("SendNotification", {
                Title = Title,
                Text = Text,
                Button1 = "Okay!",
                Duration = 8,
            })
        end)
    end

    local function Block(fn: ((...any) -> ...any)?, Handler: ((...any) -> ...any)?): ()
        if not fn or not HookFunction then return end
        local Copy = CloneFunction(fn)
        ProtectedCall(function(): ()
            HookFunction(fn, NewCClosure(function(...): ...any
                if not CheckCaller() then return nil end
                if Handler then return Handler(Copy, ...) end
                return Copy(...)
            end))
        end)
    end
    
    Block(RestoreFunction, function(_, fn) return fn end)
    Block(debug and debug.getupvalue)
    Block(debug and debug.info)
    Block(setreadonly)
    Block(RawRequest)

    return {
        Missing = Missing,
        CloneReference = CloneReference,
        CloneFunction = CloneFunction,
        NewCClosure = NewCClosure,
        HookMetamethod = HookMetamethod,
        HookFunction = HookFunction,
        CheckCaller = CheckCaller,
        GetNamecallMethod = GetNamecallMethod,
        GetConnections = GetConnections,
        GetProperties = GetProperties,
        GetCallingScript = GetCallingScript,
        GetGarbageCollection = GetGarbageCollection,
        IsExecutorClosure = IsExecutorClosure,
        HttpRequest = HttpRequest,
        RawGet = RawGet,
        StringFind = StringFind,
        StringMatch = StringMatch,
        StringSub = StringSub,
        StringUpper = StringUpper,
        StringLower = StringLower,
        StringFormat = StringFormat,
        TableInsert = TableInsert,
        MathRandom = MathRandom,
        ProtectedCall = ProtectedCall,
        Game = Game,
        Players = Players,
        StarterGui = StarterGui,
        HttpService = HttpService,
        Stats = Stats,
        ContentProvider = ContentProvider,
        ScriptContext = ScriptContext,
        LogService = LogService,
        TextChatService = TextChatService,
        ReplicatedStorage = ReplicatedStorage,
        LocalPlayer = LocalPlayer,
        Character = Character,
        Settings = FrozenSettings,
        Rnox = Rnox
    }
end

return { Build = Build }
