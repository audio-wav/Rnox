--!strict
--[[
    Rnox/modules/network.luau
    - https://github.com/audio-wav/Rnox/wiki
    - https://discord.gg/Q2sd6YEUZc
]]
local Network = {}

local function SerializeTable(
    Table: {[any]: any},
    Depth: number
): string
    local Indent: string = string.rep("\t", Depth)
    local Result: string = "{\n" .. Indent
    local Separator: string = ",\n" .. Indent
    for Key: any, Value: any in next, Table do
        if type(Value) == "table" then
            Result ..= tostring(Key) .. " = "
                .. SerializeTable(Value, Depth + 1)
        else
            Result ..= tostring(Key)
                .. " = "
                .. tostring(Value):gsub("\n", "")
                .. Separator
        end
    end
    return Result .. "\n" .. string.rep("\t", Depth - 1) .. "}"
end

function Network:Init(Core: any): ()
    local Settings = Core.Settings
    local HookFunction = Core.HookFunction
    local NewCClosure = Core.NewCClosure
    local ProtectedCall = Core.ProtectedCall
    local HttpRequest = Core.HttpRequest
    local StringFind = Core.StringFind
    local StringMatch = Core.StringMatch
    local HttpService = Core.HttpService
    if not HookFunction or not HttpRequest then
        return
    end
    local RequestFunctions: {(...any) -> any} = {}
    for _, Candidate: any in next, {
        request,
        http_request,
        HttpPost,
        typeof(syn) == "table" and syn.request or nil,
        typeof(http) == "table" and http.request or nil,
        typeof(fluxus) == "table" and fluxus.request or nil,
        typeof(syn_backup) == "table" and syn_backup.request or nil,
    } do
        if Candidate and type(Candidate) == "function" then
            table.insert(RequestFunctions, Candidate)
        end
    end

    for _, RequestFunction: (...any) -> any in next, RequestFunctions do
        local OriginalRequest: (...any) -> any
        OriginalRequest = HookFunction(
            RequestFunction,
            NewCClosure(function(...: any)
                local Arguments: {any} = { ... }
                local Options: any = Arguments[1]
                if type(Options) ~= "table" or type(Options.Url) ~= "string" then
                    return OriginalRequest(...)
                end
                local Url: string = Options.Url
                if (StringFind(Url, "webhook") or StringFind(Url, "websec"))
                    and Settings.AntiLog.Enabled then
                    local InfoText: string = ""
                    if Settings.AntiLog.ShowInfo and Options.Body then
                        ProtectedCall(function(): ()
                            local Decoded: any =
                                HttpService:JSONDecode(Options.Body)

                            InfoText = "\nLogged info:\n"
                                .. SerializeTable(Decoded, 1)
                        end)
                    end
                    task.spawn(function(): ()
                        Settings.Output(
                            "Script attempted to log info"
                                .. (Settings.AntiLog.ShowDestination
                                    and " at " .. Url
                                    or "")
                                .. ". Attempt denied."
                                .. InfoText
                        )
                    end)
                    if Settings.AntiLog.Payback then
                        Arguments[1].Method = "DELETE"
                    else
                        Arguments[1].Url = "https://google.com"
                    end
                    return OriginalRequest(table.unpack(Arguments))
                end

                if StringFind(Url, "rpc")
                    and Settings.AutoJoin.Enabled then
                    local ServerCode: string = ""
                    if Settings.AutoJoin.ShowServer and Options.Body then
                        ProtectedCall(function(): ()
                            local Body: any =
                                HttpService:JSONDecode(Options.Body)

                            if Body and Body.args and Body.args.code then
                                ServerCode =
                                    "https://discord.gg/" .. Body.args.code
                            end
                        end)
                    end
                    task.spawn(function(): ()
                        Settings.Output(
                            "Script attempted to auto-join"
                                .. (Settings.AutoJoin.ShowServer
                                    and " " .. ServerCode
                                    or " a Discord server")
                                .. ". Attempt denied."
                        )
                    end)
                    return
                end
                if StringMatch(Url, "%l+%.roblox%.com/v%d/")
                    and Settings.AntiApi.Enabled then
                    task.spawn(function(): ()
                        Settings.Output(
                            "Script attempted to access the Roblox API"
                                .. (Settings.AntiApi.ShowEndpoint
                                    and " at " .. Url
                                    or "")
                                .. ". Attempt denied."
                        )
                    end)
                    return
                end
                return OriginalRequest(...)
            end)
        )
    end
    ProtectedCall(function(): ()
        local OriginalHttpPost: (...any) -> any
        OriginalHttpPost = HookFunction(
            game.HttpPost,
            NewCClosure(function(...: any)
                task.spawn(function(): ()
                    Settings.Output(
                        "HttpPost request attempted. Attempt denied."
                    )
                end)

                return
            end)
        )
    end)
end

return Network