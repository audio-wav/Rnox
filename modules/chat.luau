--!strict
--[[
    Rnox/modules/chat.luau
    - https://github.com/audio-wav/Rnox/wiki
    - https://discord.gg/Q2sd6YEUZc
]]

local Chat = {}
function Chat:Init(Core: any): ()
    local Settings = Core.Settings
    local HookMetamethod = Core.HookMetamethod
    local HookFunction = Core.HookFunction
    local NewCClosure = Core.NewCClosure
    local CheckCaller = Core.CheckCaller
    local GetCallingScript = Core.GetCallingScript
    local ProtectedCall = Core.ProtectedCall
    local StarterGui = Core.StarterGui
    local TextChatService = Core.TextChatService
    local Game = Core.Game
    local ChatBar: TextBox? = nil
    local ChatScript: ModuleScript? = nil
    local SayMessageRequest: RemoteEvent? = nil
    local ChatMain: ModuleScript? = nil
    local MessagePostedEvent: BindableEvent? = nil
    local IsLegacyChat: boolean =
        TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService
    local LocalPlayer = Core.LocalPlayer
    if IsLegacyChat then
        ProtectedCall(function(): ()
            ChatBar = LocalPlayer.PlayerGui
                :WaitForChild("Chat")
                :WaitForChild("Frame")
                .ChatBarParentFrame.Frame.BoxFrame.Frame.ChatBar :: TextBox
            ChatScript = LocalPlayer.PlayerScripts
                :WaitForChild("ChatScript") :: ModuleScript
            SayMessageRequest = Game:GetService("ReplicatedStorage")
                .DefaultChatSystemChatEvents.SayMessageRequest :: RemoteEvent
            ChatMain = ChatScript:WaitForChild("ChatMain") :: ModuleScript
            for _, Value: any in next,
                debug.getupvalues(require(ChatMain).MessagePosted.fire) do
                if typeof(Value) == "Instance" then
                    MessagePostedEvent = Value :: BindableEvent
                end
            end
        end)
    else
        ProtectedCall(function(): ()
            ChatScript =
                Game.CoreGui.RobloxGui.Modules.Server.ClientChat.ChatScript :: ModuleScript
        end)
    end
    local AlreadyWarned: boolean = false
    local function WarnForcedChat(CallingScript: Instance?): ()
        Settings.Output(
            "Chat focus capture as local player was attempted. Attempt denied."
        )
        if CallingScript and CallingScript ~= ChatScript and not AlreadyWarned then
            AlreadyWarned = true
            local Path: string = CallingScript:GetFullName()
            ProtectedCall(setclipboard, Path)
            Core.Rnox:Notify(
                "WARNING — Forced Chat Detected",
                "A script is trying to force you to chat: " .. Path
            )
            Core.Rnox:Notify(
                "What to do",
                "Rejoin and remove the scirpt. The path was copied to clipboard."
            )
        end
    end
    if HookMetamethod then
        local OriginalNamecall: (any, ...any) -> any
        OriginalNamecall = HookMetamethod(
            game,
            "__namecall",
            NewCClosure(function(Self: any, ...: any)
                if not Settings.ChatBan.Enabled then
                    return OriginalNamecall(Self, ...)
                end
                local Method: string =
                    GetNamecallMethod and GetNamecallMethod() or ""
                if Method == "FireServer"
                    and Self == SayMessageRequest
                    and GetCallingScript
                    and GetCallingScript() ~= ChatMain then
                    Settings.Output(
                        "SayMessageRequest FireServer attempted by non-chat script. Attempt denied."
                    )
                    return
                end
                if Method == "SendAsync"
                    and Self.ClassName == "TextChannel"
                    and Settings.ChatBan.NewChat then
                    Settings.Output("TextChannel:SendAsync attempted. Attempt denied.")
                    return
                end
                if Method == "CaptureFocus"
                    and Self == ChatBar
                    and Settings.ChatBan.Slash then
                    WarnForcedChat(GetCallingScript and GetCallingScript())
                    return
                end
                if Method == "Fire" and Self == MessagePostedEvent then
                    Settings.Output(
                        "MessagePosted BindableEvent fire attempted. Attempt denied."
                    )
                    return
                end
                return OriginalNamecall(Self, ...)
            end)
        )
    elseif HookFunction then
        if SayMessageRequest then
            local OriginalFireServer: (any, ...any) -> any
            OriginalFireServer = HookFunction(
                Instance.new("RemoteEvent").FireServer,
                NewCClosure(function(Self: any, ...: any)
                    if Settings.ChatBan.Enabled
                        and Self == SayMessageRequest
                        and GetCallingScript
                        and GetCallingScript() ~= ChatMain then
                        Settings.Output(
                            "SayMessageRequest FireServer attempted. Attempt denied."
                        )
                        return
                    end
                    return OriginalFireServer(Self, ...)
                end)
            )
        end
        if ChatBar then
            local OriginalCaptureFocus: (any, ...any) -> any
            OriginalCaptureFocus = HookFunction(
                ChatBar.CaptureFocus,
                NewCClosure(function(Self: any, ...: any)
                    if Settings.ChatBan.Enabled and Settings.ChatBan.Slash then
                        WarnForcedChat(GetCallingScript and GetCallingScript())
                        return
                    end
                    return OriginalCaptureFocus(Self, ...)
                end)
            )
        end
        if MessagePostedEvent then
            local OriginalFire: (any, ...any) -> any
            OriginalFire = HookFunction(
                Instance.new("BindableEvent").Fire,
                NewCClosure(function(Self: any, ...: any)
                    if Settings.ChatBan.Enabled and Self == MessagePostedEvent then
                        Settings.Output(
                            "MessagePosted BindableEvent fire attempted. Attempt denied."
                        )
                        return
                    end
                    return OriginalFire(Self, ...)
                end)
            )
        end
        do
            local OriginalSendAsync: (any, ...any) -> any
            OriginalSendAsync = HookFunction(
                Instance.new("TextChannel").SendAsync,
                NewCClosure(function(Self: any, ...: any)
                    if Settings.ChatBan.Enabled and Settings.ChatBan.NewChat then
                        Settings.Output(
                            "TextChannel:SendAsync attempted. Attempt denied."
                        )
                        return
                    end
                    return OriginalSendAsync(Self, ...)
                end)
            )
        end
    end
end

return Chat