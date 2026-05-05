--!strict
--[[
    Rnox/core.luau
    - https://github.com/audio-wav/Rnox/wiki
    - https://discord.gg/Q2sd6YEUZc
]]

local function Build(Settings)
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
    local IsFunctionHooked: ((Function: any) -> boolean)? = Missing("function", isfunctionhooked) and CloneFunction(isfunctionhooked)
    local HookMetamethod: typeof(hookmetamethod)? = Missing("function", hookmetamethod)
    local HookFunction: typeof(hookfunction)? = Missing("function", hookfunction)
    local CheckCaller: () -> boolean = CloneFunction(
        Missing("function", checkcaller, function() return true end)
    )
    local GetNamecallMethod: (() -> string)? = Missing("function", getnamecallmethod) and CloneFunction(getnamecallmethod)
    local GetConnections: ((Signal: RBXScriptSignal) -> {RBXScriptConnection})? = Missing("function", getconnections) and CloneFunction(getconnections)
    local GetProperties: ((Instance: Instance) -> {[string]: any})? = Missing("function", getproperties) and CloneFunction(getproperties)
    local RestoreFunction: typeof(restorefunction)? = Missing("function", restorefunction) and CloneFunction(restorefunction)
    local GetCallingScript: (() -> Instance?)? = Missing("function", getcallingscript) and CloneFunction(getcallingscript)
    local GetGarbageCollection: ((...any) -> {any})? = Missing("function", getgc) and CloneFunction(getgc)
    local GetMetatable: typeof(getmetatable) = CloneFunction(getmetatable)
    local IsExecutorClosure: ((Function: any) -> boolean) =
        (Missing("function", isexecutorclosure) and CloneFunction(isexecutorclosure))
        or (Missing("function", is_synapse_function) and CloneFunction(is_synapse_function))
        or (Missing("function", iskrnlclosure) and CloneFunction(iskrnlclosure))
        or (Missing("function", issentinelclosure) and CloneFunction(issentinelclosure))
        or (Missing("function", is_protosmasher_closure) and CloneFunction(is_protosmasher_closure))
        or function() return false end
    local RawGet: typeof(rawget) = CloneFunction(rawget)
    local RawSet: typeof(rawset) = CloneFunction(rawset)
    local RawEqual: typeof(rawequal) = CloneFunction(rawequal)
    local RawRequest: ((...any) -> any)? =
        (Missing("function", request) and CloneFunction(request))
        or (Missing("function", http_request) and CloneFunction(http_request))
        or (typeof(syn) == "table" and Missing("function", syn.request) and CloneFunction(syn.request))
        or (typeof(http) == "table" and Missing("function", http.request) and CloneFunction(http.request))
        or (typeof(fluxus) == "table" and Missing("function", fluxus.request) and CloneFunction(fluxus.request))
        or nil
    local StringFind: typeof(string.find) = CloneFunction(string.find)
    local StringRep: typeof(string.rep) = CloneFunction(string.rep)
    local StringMatch: typeof(string.match) = CloneFunction(string.match)
    local StringSub: typeof(string.sub) = CloneFunction(string.sub)
    local StringUpper: typeof(string.upper) = CloneFunction(string.upper)
    local StringLower: typeof(string.lower) = CloneFunction(string.lower)
    local StringFormat: typeof(string.format) = CloneFunction(string.format)
    local TaskSpawn: typeof(task.spawn) = CloneFunction(task.spawn)
    local ToStr: typeof(tostring) = CloneFunction(tostring)
    local TableInsert: typeof(table.insert) = CloneFunction(table.insert)
    local TableRemove: typeof(table.remove) = CloneFunction(table.remove)
    local MathRandom: typeof(math.random) = CloneFunction(math.random)
    local ProtectedCall: typeof(pcall) = CloneFunction(pcall)
    local SetMetatable: typeof(setmetatable) = CloneFunction(setmetatable)
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

    type RequestOptions = {
        Url: string,
        Method: string?,
        Headers: {[string]: string}?,
        Body: string?,
    }

    local HttpRequest: ((opts: RequestOptions) -> any)?
    if RawRequest then
        HttpRequest = NewCClosure(function(opts: RequestOptions): any?
            if GetMetatable(opts) then
                return
            end
            local url: any = RawGet(opts, "Url")
            if type(url) ~= "string" then
                return
            end
            return RawRequest({
                Url = url,
                Method = RawGet(opts, "Method") or "GET",
                Headers = RawGet(opts, "Headers"),
                Body = RawGet(opts, "Body"),
            })
        end)
    end


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
            local Success: boolean = ProtectedCall(function(): ()
                StarterGui:SetCore("SendNotification", {
                    Title = Title,
                    Text = Text,
                    Button1 = "Okay!",
                    Duration = 8,
                })
            end)
            if not Success then
                FrozenSettings.Output(StringFormat("[Rnox Info] %s - %s", Title, Text))
            end
        end,
    }

    for _, Arguments in next, {
        {RestoreFunction, NewCClosure(function(Copy: any, ...: any): ...any 
            if not CheckCaller() then 
                return nil 
            end 
            return (select(2, ...)) 
        end)},
        {debug and debug.getupvalue},
        {debug and debug.info},
        {setreadonly},
        {RawRequest},
        {getupvalues},
        {setupvalue},
        {debug and debug.getupvalues},
        {setmetatable, NewCClosure(function(Copy: any, Object: any, Mt: any, ...: any): any 
            if not CheckCaller() and (RawEqual(Object, game) or RawEqual(Object, Game)) then 
                return nil 
            end 
            return Copy(Object, Mt, ...) 
        end)},
        {queueonteleport, NewCClosure(function(Copy: any, ...: any): any
            Copy()
            return nil
        end)},
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
                    return Target
                end
            end
            return RawHookFunction(Target, Replacement)
        end))
    end

    if GetGarbageCollection then
        local RawGetGC: (...any) -> {any} = CloneFunction(getgc)
        local RawFilterGC: ((...any) -> any)? = filtergc and CloneFunction(filtergc) or nil
        local ProtectedFunctions: {[any]: boolean} = {}
        ProtectedFunctions[RawHookFunction] = true
        ProtectedFunctions[RawGetGC] = true
        if RawFilterGC then
            ProtectedFunctions[RawFilterGC] = true
        end
        for _, Function: any in next, Watched do
            ProtectedFunctions[Function] = true
        end
        table.freeze(ProtectedFunctions)

        ProtectedCall(function(): ()
            HookFunction(getgc, NewCClosure(function(...: any): {any}
                local Results: {any} = RawGetGC(...)
                for i: number = #Results, 1, -1 do
                    if ProtectedFunctions[Results[i]] then
                        TableRemove(Results, i)
                    end
                end
                return Results
            end))
        end)

        if filtergc and RawFilterGC then
            ProtectedCall(function(): ()
                HookFunction(filtergc, NewCClosure(function(Type: string, Options: any, Single: boolean?): any
                    local Results: any = RawFilterGC(Type, Options, Single)
                    if Single then
                        return ProtectedFunctions[Results] and nil or Results
                    end
                    for i: number = #Results, 1, -1 do
                        if ProtectedFunctions[Results[i]] then
                            TableRemove(Results, i)
                        end
                    end
                    return Results
                end))
            end)
        end
    end

    TaskSpawn(function()
        local Warned: boolean = false
        while not Warned do
            RunService.Heartbeat:Wait()
            if not IsFunctionHooked then continue end
            for _, Function: any in next, Watched do
                if IsFunctionHooked(Function) then
                    Warned = true
                    local Success: boolean = ProtectedCall(function()
                        StarterGui:SetCore("SendNotification", {
                            Title = "Rnox Warning",
                            Text = "Rnox's Environment is being tampered with. You are at risk",
                            Button1 = "Leave the game",
                            Duration = math.huge,
                        })
                    end)
                    if not Success then
                        FrozenSettings.Output("[Rnox Warning] Rnox's Environment is being tampered with. You are at risk and should leave the game")
                    end
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
        RawSet = RawSet,
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
        SetMetatable = SetMetatable,
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
