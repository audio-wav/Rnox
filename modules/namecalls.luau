--!strict
--[[
    Rnox/modules/namecalls.luau
    All it does is block malicious namecalls lol
    Most executors already disables it by default
    But I'm including it because some don't and well
    It's guardian bro
]]

local Namecalls = {}
local MaliciousNamecalls: {[string]: {[string]: any}} = {
    BrowserService = {
        OpenBrowserWindow = true,
        ExecuteJavaScript = true,
        SendCommand = true,
        OpenNativeOverlay = true,
        CloseBrowserWindow = true,
        OpenWeChatAuthWindow = true,
    },
    MarketplaceService = {
        GetRobuxBalance = true,
        PromptGamePassPurchase = true,
        PromptPurchase = true,
        PromptBundlePurchase = true,
        PromptProductPurchase = true,
        PromptSubscriptionPurchase = true,
        PromptThirdPartyPurchase = true,
        PromptRobloxPurchase = true,
        PromptNativePurchaseWithLocalPlayer = true,
        PromptNativePurchase = true,
        PromptCollectiblesPurchase = true,
        PrepareCollectiblesPurchase = true,
        ReportAssetSale = true,
    },
    MessageBusService = {
        Publish = true,
        GetMessageId = true,
        Call = true,
    },
    HttpService = {
        RequestInternal = true,
        GetSecret = true,
    },
    GuiService = {
        OpenBrowserWindow = true,
        OpenNativeOverlay = true,
        SetPurchasePromptIsShown = true,
    },
    DataModel = {
        OpenVideosFolder = true,
        OpenScreenshotsFolder = true,
        HttpGetAsync = true,
        HttpPostAsync = true,
    },
    RbxAnalyticsService = {
        GetClientId = true,
    },
    Players = {
        ReportAbuse = true,
    },
    HttpRbxApiService = {
        GetAsync = true,
        GetAsyncFullUrl = true,
        GetDocumentationUrl = true,
        PostAsync = true,
        PostAsyncFullUrl = true,
        RequestAsync = true,
        RequestLimitedAsync = true,
    },
    OpenCloudService = {
        HttpRequestAsync = true,
        InvokeAsync = true,
    },
    ScriptContext = {
        AddCoreScriptLocal = true,
        SaveScriptProfilingData = true,
    },
    ScriptProfilerService = {
        SaveScriptProfilingData = true,
    },
    VideoCaptureService = {
        GetCameraDevices = true,
    },
    CaptureService = {
        DeleteCapture = true,
        PromptSaveCapturesToGallery = true,
        PromptShareCapture = true,
        RetrieveCaptures = true,
        SaveCaptureToExternalStorage = true,
        SaveScreenshotCapture = true,
    },
    SafetyService = {
        TakeScreenshot = true,
    },
    LoginService = {
        PromptLogin = true,
        Logout = true,
    },
    PermissionsService = {
        SetPermissions = true,
    },
    LinkingService = {
        OpenUrl = true,
    },
}

function Namecalls:Init(Core): ()
    local Settings = Core.Settings
    local HookMetamethod = Core.HookMetamethod
    local HookFunction = Core.HookFunction
    local NewCClosure = Core.NewCClosure
    local CheckCaller = Core.CheckCaller
    local GetNamecallMethod = Core.GetNamecallMethod
    local ProtectedCall = Core.ProtectedCall
    local Game = Core.Game
    local function BuildLabel(ClassName: string, MethodName: string): string
        if Settings.MaliciousNamecalls.ShowNamecall then
            return " game." .. ClassName .. ":" .. MethodName
        end
        return ""
    end
    if HookMetamethod then
        local OriginalNamecall
        OriginalNamecall = HookMetamethod(game, "__namecall", NewCClosure(function(Self, ...)
            if not Settings.MaliciousNamecalls.Enabled then
                return OriginalNamecall(Self, ...)
            end
            local MethodName = GetNamecallMethod and GetNamecallMethod() or ""
            local ClassName = Self.ClassName
            local ServiceEntry = MaliciousNamecalls[ClassName]
            if ServiceEntry and ServiceEntry[MethodName] then
                Settings.Output(
                    "Malicious namecall" .. BuildLabel(ClassName, MethodName) ..
                    " attempted execution. Attempt denied."
                )
                if not CheckCaller() then
                    return OriginalNamecall(Self, ...)
                end
                return nil
            end
            return OriginalNamecall(Self, ...)
        end))
    elseif HookFunction then
        for ClassName, Methods in next, MaliciousNamecalls do
            for MethodName in next, Methods do
                ProtectedCall(function()
                    local ServiceObject = ClassName == "DataModel"
                        and Game
                        or Game:GetService(ClassName)
                    local OriginalMethod
                    OriginalMethod = HookFunction(
                        ServiceObject[MethodName],
                        NewCClosure(function(...)
                            if Settings.MaliciousNamecalls.Enabled then
                                Settings.Output(
                                    "Malicious function" .. BuildLabel(ClassName, MethodName) ..
                                    " attempted execution. Attempt denied."
                                )
                                if not CheckCaller() then
                                    return OriginalMethod(...)
                                end
                                return nil
                            end
                            return OriginalMethod(...)
                        end)
                    )
                end)
            end
        end
    end
end

return Namecalls