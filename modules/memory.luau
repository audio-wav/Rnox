--!strict
--[[
    Rnox/modules/memory.luau
    - https://github.com/audio-wav/Rnox/wiki
    - https://discord.gg/Q2sd6YEUZc
]]

local Memory = {}
function Memory:Init(Core: any): ()
    local Settings = Core.Settings
    local HookMetamethod = Core.HookMetamethod
    local HookFunction = Core.HookFunction
    local NewCClosure = Core.NewCClosure
    local CheckCaller = Core.CheckCaller
    local GetProperties = Core.GetProperties
    local ProtectedCall = Core.ProtectedCall
    local Game = Core.Game
    local Stats = Core.Stats
    local ContentProvider = Core.ContentProvider
    local Character = Core.Character
    local GetNamecallMethod = Core.GetNamecallMethod
    local MathRandom = Core.MathRandom
    local SavedProperties: {[Instance]: {[string]: any}} = {}
    if GetProperties then
        ProtectedCall(function(): ()
            local Root: Instance? = Character:FindFirstChild("HumanoidRootPart")
            if not Root then
                repeat task.wait() until #Character:GetChildren() > 0
            end
            for _, Part: Instance in next, Character:GetChildren() do
                SavedProperties[Part] = {}
                for PropertyName: string, PropertyValue: any in
                    next, GetProperties(Part) do

                    if typeof(PropertyValue) ~= "Vector3"
                        and typeof(PropertyValue) ~= "CFrame" then
                        SavedProperties[Part][PropertyName] = PropertyValue
                    end
                end
            end
        end)
    end
    if HookMetamethod then
        local OriginalNamecall: (any, ...any) -> any
        OriginalNamecall = HookMetamethod(
            game,
            "__namecall",
            NewCClosure(function(Self: any, ...: any)
                local Method: string =
                    GetNamecallMethod and GetNamecallMethod() or ""
                local Arguments: {any} = { ... }
                if Self == Stats
                    and Method == "GetTotalMemoryUsageMb"
                    and Settings.MemoryDetections then
                    return MathRandom(400, 550)
                end
                if Self == ContentProvider
                    and Method == "PreloadAsync"
                    and typeof(Arguments[1]) == "table"
                    and Settings.GUIDetection then
                    Settings.Output(
                        "GUI detection via PreloadAsync attempted. Attempt denied."
                    )
                    return
                end
                return OriginalNamecall(Self, ...)
            end)
        )

        if GetProperties then
            local OriginalIndex: (any, any, ...any) -> any
            OriginalIndex = HookMetamethod(
                game,
                "__index",
                NewCClosure(function(Self: any, Key: any, ...: any)
                    local PartProperties: {[string]: any}? =
                        SavedProperties[Self]
                    if not CheckCaller()
                        and PartProperties
                        and PartProperties[Key] then
                        return PartProperties[Key]
                    end
                    return OriginalIndex(Self, Key, ...)
                end)
            )
        end
    elseif HookFunction then
        local OriginalGetTotalMemory: (any, ...any) -> any
        OriginalGetTotalMemory = HookFunction(
            Stats.GetTotalMemoryUsageMb,
            NewCClosure(function(Self: any, ...: any)
                if Settings.MemoryDetections and Self == Stats then
                    return MathRandom(400, 550)
                end
                return OriginalGetTotalMemory(Self, ...)
            end)
        )
        local OriginalPreloadAsync: (any, ...any) -> any
        OriginalPreloadAsync = HookFunction(
            ContentProvider.PreloadAsync,
            NewCClosure(function(Self: any, ...: any)
                local Arguments: {any} = { ... }
                if Settings.GUIDetection
                    and Self == ContentProvider
                    and typeof(Arguments[1]) == "table" then
                    Settings.Output(
                        "GUI detection via PreloadAsync attempted. Attempt denied."
                    )
                    return
                end
                return OriginalPreloadAsync(Self, ...)
            end)
        )
        local OriginalGcInfo: (...any) -> any
        OriginalGcInfo = HookFunction(
            gcinfo,
            NewCClosure(function(...: any)
                return Settings.MemoryDetections
                    and MathRandom(1500, 2500)
                    or OriginalGcInfo(...)
            end)
        )
    end
end

return Memory