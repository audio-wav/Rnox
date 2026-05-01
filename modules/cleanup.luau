--!strict
--[[
    Rnox/modules/cleanup.luau
    - https://github.com/audio-wav/Rnox/wiki
    - https://discord.gg/Q2sd6YEUZc
]]

local Cleanup = {}
function Cleanup:Init(Core: any): ()
    local Settings = Core.Settings
    local GetGarbageCollection = Core.GetGarbageCollection
    local GetConnections = Core.GetConnections
    local IsExecutorClosure = Core.IsExecutorClosure
    local ProtectedCall = Core.ProtectedCall
    local ScriptContext = Core.ScriptContext
    local LogService = Core.LogService
    local LocalPlayer = Core.LocalPlayer
    if Settings.ClearTrace and GetGarbageCollection then
        ProtectedCall(function(): ()
            for _, Value: any in next, GetGarbageCollection() do
                if typeof(Value) == "function" and IsExecutorClosure(Value) then
                    Value = nil :: any
                end
            end
        end)
    end
    if Settings.AntiError and GetConnections then
        ProtectedCall(function(): ()
            for _, Connection: RBXScriptConnection in
                next, GetConnections(ScriptContext.Error) do
                Connection:Disable()
            end
        end)
    end
    if Settings.AntiMessage and GetConnections then
        ProtectedCall(function(): ()
            for _, Connection: RBXScriptConnection in
                next, GetConnections(LogService.MessageOut) do
                Connection:Disable()
            end
        end)
    end
    if Settings.AntiIdle and GetConnections then
        ProtectedCall(function(): ()
            for _, Connection: RBXScriptConnection in
                next, GetConnections(LocalPlayer.Idled) do
                Connection:Disable()
            end
        end)
    end
end

return Cleanup