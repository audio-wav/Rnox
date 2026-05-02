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
    local Watched: {any} = {}
    local RawCloneFunction: typeof(clonefunction) = Missing("function", clonefunction, function(...) return ... end)
    local RawCloneReference: typeof(cloneref) = Missing("function", cloneref, function(...) return ... end)
    local CloneFunction: typeof(clonefunction) = function(Function: any): any
        local Cloned = RawCloneFunction(Function)
        Watched[#Watched + 1] = Cloned
        return Cloned
    end
    local CloneReference: typeof(cloneref) = function(ref: any): any
        return RawCloneReference(ref)
    end
    local NewCClosure: typeof(newcclosure) = Missing("function", newcclosure, function(Function) return Function end)
    local IsFunctionHooked: ((Function: any) -> boolean)? = Missing("function", isfunctionhooked) and RawCloneFunction(isfunctionhooked)
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
            if GetMetatable(opts) then
                return
            end

            local url = RawGet(opts, "Url")
            if type(url) ~= "string" then 
                return 
            end

            return SafeRawRequest({
                Url = url,
                Method = RawGet(opts, "Method") or "GET",
                Headers = RawGet(opts, "Headers"),
                Body = RawGet(opts, "Body"),
            })
        end)
    end
    local RawEqual = CloneFunction(rawequal)
    local StringFind = CloneFunction(string.find)
    local StringRep = CloneFunction(string.rep)
    local StringMatch = CloneFunction(string.match)
    local StringSub = CloneFunction(string.sub)
    local StringUpper = CloneFunction(string.upper)
    local StringLower = CloneFunction(string.lower)
    local StringFormat = CloneFunction(string.format)
    local ToStr = CloneFunction(tostring)
    local TableInsert = CloneFunction(table.insert)
    local TableRemove = CloneFunction(table.remove)
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
    local RunService = CloneReference(Game:GetService("RunService"))
    local LocalPlayer = Players.LocalPlayer
    local Character: Model = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    local Rnox = {
        SetAll = function(_self: any, Value: boolean): ()
            for Key, Setting in next, Settings do
                if RawEqual(type(Setting), "table") then
                    for SubKey in next, Setting do
                        Settings[Key][SubKey] = Value
                    end
                elseif RawEqual(type(Setting), "boolean") then
                    Settings[Key] = Value
                end
            end
        end,
        Notify = function(_self: any, Title: string, Text: string): ()
            ProtectedCall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = Title,
                    Text = Text,
                    Button1 = "Okay!",
                    Duration = 8,
                })
            end)
        end,
    }

    for _, Arguments in next, {
        {RestoreFunction, NewCClosure(function(Copy: any, ...: any): ...any if not CheckCaller() then return nil end return (select(2, ...)) end)},
        {debug and debug.getupvalue},
        {debug and debug.info},
        {setreadonly},
        {RawRequest},
    } do
        local Function: any = Arguments[1]
        local Handler: any = Arguments[2]
        if Function and HookFunction then
            local Copy = CloneFunction(Function)
            ProtectedCall(function(): ()
                HookFunction(Function, NewCClosure(function(...): ...any
                    if not CheckCaller() then
                        return nil
                    end
                    if Handler then
                        return Handler(Copy, ...)
                    end
                    return Copy(...)
                end))
            end)
        end
    end

    table.freeze(Watched)

    local RawHookFunction: ((...any) -> ...any)?
    if HookFunction then
        RawHookFunction = HookFunction(hookfunction, NewCClosure(function(Target: any, Replacement: any): any
            for _, Function in next, Watched do
                if RawEqual(Function, Target) then
                    return Target -- heartbeat loop will notify the user so we can just return
                end
            end
            return RawHookFunction(Target, Replacement)
        end))
    end

    if GetGarbageCollection then
        local RawGetGC = RawCloneFunction(getgc)
        local RawFilterGC = RawCloneFunction(filtergc)
        HookFunction(getgc, NewCClosure(function(...): any
            local Results = RawGetGC(...)
            for i = #Results, 1, -1 do
                if RawEqual(Results[i], RawHookFunction) then
                    TableRemove(Results, i)
                end
            end
            return Results
        end))

        if filtergc then
            HookFunction(filtergc, NewCClosure(function(Type: string, Options: any, Single: boolean?): any
                local Results = RawFilterGC(Type, Options, Single)
                if Single then
                    if RawEqual(Results, RawHookFunction) then
                        return nil
                    end
                    return Results
                else
                    for i = #Results, 1, -1 do
                        if RawEqual(Results[i], RawHookFunction) then
                            TableRemove(Results, i)
                        end
                    end
                    return Results
                end
            end))
        end
    end

    task.spawn(function()
        local Warned = false
        while not Warned do
            RunService.Heartbeat:Wait()
            if not IsFunctionHooked then continue end
            for _, fn in next, Watched do
                if IsFunctionHooked(fn) then
                    Warned = true
                    ProtectedCall(function()
                        StarterGui:SetCore("SendNotification", {
                            Title = "Rnox Warning",
                            Text = "Rnox's Environment is being tampered with. You are at risk",
                            Button1 = "Leave the game",
                            Duration = math.huge,
                        })
                    end)
                    break
                end
            end
        end
    end)

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
        StringRep = StringRep,
        StringMatch = StringMatch,
        StringSub = StringSub,
        StringUpper = StringUpper,
        StringLower = StringLower,
        StringFormat = StringFormat,
        ToStr = ToStr,
        TableInsert = TableInsert,
        TableRemove = TableRemove,
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
        RunService = RunService,
        TextChatService = TextChatService,
        ReplicatedStorage = ReplicatedStorage,
        LocalPlayer = LocalPlayer,
        Character = Character,
        Settings = FrozenSettings,
        Rnox = Rnox
    }
end

return { Build = Build }
