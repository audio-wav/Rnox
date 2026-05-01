--!strict
--[[
    Rnox/modules/remotes.luau
    - https://github.com/audio-wav/Rnox/wiki
]]

local Remotes = {}
function Remotes:Init(Core): ()
    local Settings = Core.Settings
    local HookMetamethod = Core.HookMetamethod
    local HookFunction = Core.HookFunction
    local NewCClosure = Core.NewCClosure
    local CheckCaller = Core.CheckCaller
    local ProtectedCall = Core.ProtectedCall
    local Game = Core.Game
    local Players = Core.Players
    local LocalPlayer = Core.LocalPlayer
    local GetNamecallMethod = Core.GetNamecallMethod
    local MiningSimTradeRemote: RemoteEvent? = nil
    local BeeSwarmEggRemote: RemoteFunction? = nil
    local PetSim99BankRemote: RemoteFunction? = nil
    local PlaceId = Game.PlaceId
    if PlaceId == 9551640993 then
        ProtectedCall(function()
            MiningSimTradeRemote = Game:GetService("ReplicatedStorage")
                :WaitForChild("Events"):WaitForChild("ConfirmTrade") :: RemoteEvent
        end)
    end
    if PlaceId == 1537690962 then
        ProtectedCall(function()
            BeeSwarmEggRemote = Game:GetService("ReplicatedStorage")
                :WaitForChild("Events"):WaitForChild("ConstructHiveCellFromEgg") :: RemoteFunction
        end)
    end
    if PlaceId == 8737899170 then
        ProtectedCall(function()
            PetSim99BankRemote = Game:GetService("ReplicatedStorage")
                .Network["Mailbox: Send"] :: RemoteFunction
        end)
    end
    if Game.GameId == 2316994223 and Settings.PetSim.Enabled then
        ProtectedCall(function()
            local NetworkModule = require(
                Game:GetService("ReplicatedStorage").Library.Client.Network
            )
            local OriginalInvoke
            OriginalInvoke = HookFunction(NetworkModule.Invoke, NewCClosure(function(Self, ...)
                if Settings.PetSim.Enabled and CheckCaller() then
                    local Arguments = { ... }

                    if Self == "Invite To Bank" and Settings.PetSim.Bank then
                        task.spawn(function()
                            local UserName = Players:GetNameFromUserIdAsync(Arguments[2])
                            Settings.Output(
                                "Script attempted to give user"
                                .. (Settings.PetSim.ShowUser
                                    and (' named "' .. UserName .. '" (ID: ' .. tostring(Arguments[2]) .. ")")
                                    or "")
                                .. " access to your bank. Attempt denied."
                            )
                        end)
                        return
                    end
                    if Self == "Send Mail" and Settings.PetSim.Mail then
                        task.spawn(function()
                            local Recipient = Arguments[1]["Recipient"]
                            local UserId = Players:GetUserIdFromNameAsync(Recipient)
                            Settings.Output(
                                "Script attempted to send mail to user"
                                .. (Settings.PetSim.ShowUser
                                    and (' named "' .. Recipient .. '" (ID: ' .. tostring(UserId) .. ")")
                                    or "")
                                .. ". Attempt denied."
                            )
                        end)
                        return
                    end
                end
                return OriginalInvoke(Self, ...)
            end))
        end)
    end
    if HookMetamethod then
        local OriginalNamecall
        OriginalNamecall = HookMetamethod(game, "__namecall", NewCClosure(function(Self, ...)
            local Method = GetNamecallMethod and GetNamecallMethod() or ""
            local Arguments = { ... }
            if Self == LocalPlayer and Method == "Kick" and Settings.AntiKick then
                Settings.Output("Attempt to kick local player denied.")
                return
            end
            if Self == LocalPlayer and Method == "IsInGroup"
                and typeof(Arguments[1]) == "number" and Arguments[1] > 0
                and Settings.GroupBypass then
                return true
            end
            if CheckCaller() then
                if Settings.MiningSim and Self == MiningSimTradeRemote and Method == "FireServer" then
                    Settings.Output("Script attempted to confirm a potentially rigged trade. Attempt denied.")
                    return
                end
                if Settings.BeeSwarm and Self == BeeSwarmEggRemote and Method == "InvokeServer" then
                    Settings.Output("Script attempted to place a basic bee egg (fake dupe). Attempt denied.")
                    return
                end
                if Settings.PetSim99 and Self == PetSim99BankRemote and Method == "InvokeServer" then
                    Settings.Output("Script attempted to access the PetSim99 bank. Attempt denied.")
                    return
                end
            end
            return OriginalNamecall(Self, ...)
        end))
    elseif HookFunction then
        local OriginalKick
        OriginalKick = HookFunction(LocalPlayer.Kick, NewCClosure(function(Self, ...)
            if Settings.AntiKick and Self == LocalPlayer then
                Settings.Output("Attempt to kick local player denied.")
                return
            end
            return OriginalKick(Self, ...)
        end))
        local OriginalIsInGroup
        OriginalIsInGroup = HookFunction(LocalPlayer.IsInGroup, NewCClosure(function(Self, ...)
            local Arguments = { ... }
            if Settings.GroupBypass and Self == LocalPlayer
                and typeof(Arguments[1]) == "number" and Arguments[1] > 0 then
                return true
            end
            return OriginalIsInGroup(Self, ...)
        end))
        local OriginalFireServer
        OriginalFireServer = HookFunction(Instance.new("RemoteEvent").FireServer,
            NewCClosure(function(Self, ...)
                if CheckCaller() and Settings.MiningSim and Self == MiningSimTradeRemote then
                    Settings.Output("Script attempted to confirm a potentially rigged trade. Attempt denied.")
                    return
                end
                return OriginalFireServer(Self, ...)
            end)
        )
        local OriginalInvokeServer
        OriginalInvokeServer = HookFunction(Instance.new("RemoteFunction").InvokeServer,
            NewCClosure(function(Self, ...)
                if CheckCaller() then
                    if Settings.BeeSwarm and Self == BeeSwarmEggRemote then
                        Settings.Output("Script attempted to place a basic bee egg (fake dupe). Attempt denied.")
                        return
                    end
                    if Settings.PetSim99 and Self == PetSim99BankRemote then
                        Settings.Output("Script attempted to access the PetSim99 bank. Attempt denied.")
                        return
                    end
                end
                return OriginalInvokeServer(Self, ...)
            end)
        )
    end
end

return Remotes