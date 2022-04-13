local M = {NAME = "unity"}
-- Extention: https://github.com/AGulev/DefVideoAds

local ads = require("ads_wrapper.ads_wrapper")
local platform = require("ads_wrapper.platform")
local helper = require("ads_wrapper.ads_networks.helper")
local events = require("ads_wrapper.events")

local parameters
local module_callback
local is_ready = {}
local banner_loaded = false
local banner_showed = false
local banner_configs 
if unityads then
    banner_configs = {size = {width = 320, height = 50}, position = unityads.BANNER_POSITION_TOP_CENTER}
end

-- Call saved `module_callback` only once. Send result.
---@param result hash
local function callback_once(result)
    if module_callback then
        local callback = module_callback
        module_callback = nil
        callback(result)
    end
end

---Call callback in the second frame. Send result.
---It is necessary to use timer for the coroutine to continue.
---@param result hash
local function callback_delay(callback, result)
    if callback then
        timer.delay(0, false, function()
            callback(result)
        end)
    end
end

---Called when banner loaded
local function on_banner_loaded()
    banner_loaded = true
    unityads.set_banner_position(banner_configs.position)
    callback_once(helper.success())
end

local function unity_ads_callback(self, message_id, message)
    if message_id == unityads.MSG_INIT then
        if message.event == unityads.EVENT_COMPLETED then
            callback_once(helper.success())
        elseif message.event == unityads.EVENT_SDK_ERROR then
            if message.code == unityads.ERROR_INTERNAL then
                callback_once(helper.error(message.error))
            elseif message.code == unityads.ERROR_INVALID_ARGUMENT then
                callback_once(helper.error(message.error))
            elseif message.code == unityads.ERROR_AD_BLOCKER_DETECTED then
                callback_once(helper.error(message.error, events.C_ERROR_AD_BLOCK))
            end
        elseif message.event == unityads.EVENT_JSON_ERROR then
            callback_once(helper.error(message.error))
        end
    elseif message_id == unityads.MSG_SHOW then
        if message.event == unityads.EVENT_COMPLETED then
            callback_once(helper.success())
        elseif message.event == unityads.EVENT_SKIPPED then
            callback_once(helper.skipped())
        elseif message.event == unityads.EVENT_START then
            is_ready[message.placement_id] = false
            -- message = {placement_id = "string"}
            -- UnityAds has started to show ad with a specific placement.
        elseif message.event == unityads.EVENT_CLICKED then
            -- message = {placement_id = "string"}
            -- UnityAds has received a click while showing ad with a specific placement.
        elseif message.event == unityads.EVENT_SDK_ERROR then
            -- message = {code = int, error = "error message string"}
            if message.code == unityads.ERROR_NOT_INITIALIZED then
                callback_once(helper.error(message.error))
            elseif message.code == unityads.ERROR_NOT_READY then
                callback_once(helper.error(message.error))
            elseif message.code == unityads.ERROR_VIDEO_PLAYER then
                callback_once(helper.error(message.error))
            elseif message.code == unityads.ERROR_INVALID_ARGUMENT then
                callback_once(helper.error(message.error))
            elseif message.code == unityads.ERROR_NO_CONNECTION then
                callback_once(helper.error(message.error, events.C_ERROR_NO_CONNECTION))
            elseif message.code == unityads.ERROR_ALREADY_SHOWING then
            elseif message.code == unityads.ERROR_INTERNAL then
                callback_once(helper.error(message.error))
            end
        elseif message.event == unityads.EVENT_JSON_ERROR then
            callback_once(helper.error(message.error))
        end
    elseif message_id == unityads.MSG_LOAD then
        if message.event == unityads.EVENT_LOADED then
            is_ready[message.placement_id] = true
            callback_once(helper.success(message.placement_id))
        elseif message.event == unityads.EVENT_SDK_ERROR then
            if message.code == unityads.ERROR_NOT_INITIALIZED then
                callback_once(helper.error(message.error))
            elseif message.code == unityads.ERROR_INTERNAL then
                callback_once(helper.error(message.error))
            elseif message.code == unityads.ERROR_INVALID_ARGUMENT then
                callback_once(helper.error(message.error))
            elseif message.code == unityads.ERROR_NO_FILL then
                callback_once(helper.error(message.error))
            elseif message.code == unityads.ERROR_TIMEOUT then
                callback_once(helper.error(message.error))
            end
        elseif message.event == unityads.EVENT_JSON_ERROR then
            callback_once(helper.error(message.error))
        end
    elseif message_id == unityads.MSG_BANNER then
        if message.event == unityads.EVENT_LOADED then
            on_banner_loaded()
            print("UNITYADS: EVENT_LOADED: Banner is loaded and ready to be placed in the view hierarchy.")
        elseif message.event == unityads.EVENT_LEFT_APPLICATION then
            -- print("UNITYADS: EVENT_LEFT_APPLICATION: Banner links outside the application.")
        elseif message.event == unityads.EVENT_CLICKED then
            -- print("UNITYADS: EVENT_CLICKED: Banner is clicked")
        elseif message.event == unityads.EVENT_SDK_ERROR then
            callback_once(helper.error(message.error))
            -- if message.code == unityads.ERROR_UNKNOWN then
            --     print("UNITYADS: ERROR_UNKNOWN: Unknown error")
            -- elseif message.code == unityads.ERROR_NATIVE then
            --     print("UNITYADS: ERROR_NATIVE: Error related to native")
            -- elseif message.code == unityads.ERROR_WEBVIEW then
            --     print("UNITYADS: ERROR_WEBVIEW: Error related to webview")
            -- elseif message.code == unityads.ERROR_NO_FILL then
            --     print("UNITYADS: ERROR_NO_FILL: Error related to there being no ads available")
            -- end
        elseif message.event == unityads.EVENT_JSON_ERROR then
            callback_once(helper.error(message.error))
        end
    elseif message_id == unityads.MSG_IDFA then
        if message.event == unityads.EVENT_JSON_ERROR then
            callback_once(helper.error(message.error))
        else
            local message_text = "IDFA event"
            if message.event == unityads.EVENT_STATUS_AUTORIZED then
                message_text = "UNITYADS: EVENT_STATUS_AUTORIZED: ATTrackingManagerAuthorizationStatusAuthorized"
            elseif message.event == unityads.EVENT_STATUS_DENIED then
                message_text = "UNITYADS: EVENT_STATUS_DENIED: ATTrackingManagerAuthorizationStatusDenied"
            elseif message.event == unityads.EVENT_STATUS_NOT_DETERMINED then
                message_text = "UNITYADS: EVENT_STATUS_NOT_DETERMINED: ATTrackingManagerAuthorizationStatusNotDetermined"
            elseif message.event == unityads.EVENT_STATUS_RESTRICTED then
                message_text = "UNITYADS: EVENT_STATUS_RESTRICTED: ATTrackingManagerAuthorizationStatusRestricted"
            elseif message.event == unityads.EVENT_NOT_SUPPORTED then
                message_text = "UNITYADS: EVENT_NOT_SUPPORTED: IDFA request not supported on this platform or OS version"
            end
            callback_once(helper.success(message_text, message.event))
        end
    end
end

---Api setup
---@param params table
function M.setup(params)
    parameters = params
    local banner_settings = parameters[ads.T_BANNER]
    if banner_settings then
        if banner_settings.size then
            if banner_settings.size.width then
                banner_configs.size.width = banner_settings.size.width
            end
            if banner_settings.size.height then
                banner_configs.size.height = banner_settings.size.height
            end
        end
        if banner_settings.position or banner_settings.position == 0 then
            banner_configs.position = banner_settings.position
        end
    end
    if ads.is_debug then
        if platform.is_same(platform.PL_IOS) or platform.is_same(platform.PL_ANDROID) then
            parameters.ids = {[platform.PL_ANDROID] = "1401815", [platform.PL_IOS] = "1425385"}
            parameters[ads.T_BANNER] = {id = "banner"} -- test unit for banners
            parameters[ads.T_INTERSTITIAL] = "video" -- test unit for interstitial
            parameters[ads.T_REWARDED] = "rewardedVideo" -- test unit for rewarded
        end
    end
end

---Initializes `unityads` sdk.
---@param callback function the function is called after execution.
function M.init(callback)
    module_callback = callback
    unityads.set_callback(unity_ads_callback)
    unityads.initialize(parameters.ids[platform.get()], unity_ads_callback, ads.is_debug, true)
end

---Requests IDFA
---@param callback function the function is called after execution.
function M.request_idfa(callback)
    module_callback = callback
    unityads.set_callback(unity_ads_callback)
    unityads.request_idfa()
end

---Check if the environment supports unity ads api
---@return bool
function M.is_supported()
    return (unityads ~= nil) and unityads.is_supported()
end

---Check if the unity ads is initialized
---@return bool
function M.is_initialized()
    return unityads.is_initialized()
end

---Shows rewarded ads.
---@param callback function the function is called after execution.
function M.show_rewarded(callback)
    module_callback = callback
    unityads.set_callback(unity_ads_callback)
    unityads.show(parameters[ads.T_REWARDED])
end

---Loads rewarded ads
---@param callback function the function is called after execution.
function M.load_rewarded(callback)
    module_callback = callback
    unityads.set_callback(unity_ads_callback)
    unityads.load(parameters[ads.T_REWARDED])
end

---Check if the rewarded ads is loaded
---@return boolean
function M.is_rewarded_loaded()
    return is_ready[ads.T_REWARDED]
end

---Shows interstitial ads.
---@param callback function the function is called after execution.
function M.show_interstitial(callback)
    module_callback = callback
    unityads.set_callback(unity_ads_callback)
    unityads.show(parameters[ads.T_INTERSTITIAL])
end

---Loads interstitial ads
---@param callback function the function is called after execution.
function M.load_interstitial(callback)
    module_callback = callback
    unityads.set_callback(unity_ads_callback)
    unityads.load(parameters[ads.T_INTERSTITIAL])
end

---Check if the interstitial ads is loaded
---@return boolean
function M.is_interstitial_loaded()
    return is_ready[ads.T_INTERSTITIAL]
end

---Check if the banner is set up
---@return boolean
function M.is_banner_setup()
    return parameters[ads.T_BANNER] and parameters[ads.T_BANNER].id
end

---Loads banner. Use `ads.T_BANNER` parameter.
---@param callback function the function is called after execution.
function M.load_banner(callback)
    if not M.is_banner_setup() then
        callback_delay(callback, helper.error("UNITYADS: Banner not setup"))
        return
    end
    module_callback = callback
    unityads.set_callback(unity_ads_callback)
    unityads.load_banner(parameters[ads.T_BANNER].id, banner_configs.size.width, banner_configs.size.height)
end

---Unloads active banner.
---@param callback function the function is called after execution.
function M.unload_banner(callback)
    if M.is_banner_loaded() then
        banner_loaded = false
        banner_showed = false
        unityads.unload_banner()
        callback_delay(callback, helper.success())
    else
        callback_delay(callback, helper.error("UNITYADS: Banner not loaded"))
    end
end

---Check if the banner is loaded
---@return boolean
function M.is_banner_loaded()
    return banner_loaded
end

---Shows loaded banner.
---@return table
function M.show_banner()
    if M.is_banner_loaded() then
        banner_showed = true
        unityads.show_banner()
        return helper.success()
    end
    return helper.error("UNITYADS: Banner not loaded")
end

---Hides loaded banner.
---@return table
function M.hide_banner()
    if M.is_banner_loaded() then
        banner_showed = false
        unityads.hide_banner()
        return helper.success()
    end
    return helper.error("UNITYADS: Banner not loaded")
end

---Sets banner position.
---Possible positions:
--- `unityads.BANNER_POSITION_TOP_LEFT`
--- `unityads.BANNER_POSITION_TOP_CENTER`
--- `unityads.BANNER_POSITION_TOP_RIGHT`
--- `unityads.BANNER_POSITION_BOTTOM_LEFT`
--- `unityads.BANNER_POSITION_BOTTOM_CENTER`
--- `unityads.BANNER_POSITION_BOTTOM_RIGHT`
--- `unityads.BANNER_POSITION_CENTER`
---@param position number banner position
---@return table
function M.set_banner_position(position)
    if position or position == 0 then
        banner_configs.position = position
        if M.is_banner_loaded() then
            unityads.set_banner_position(banner_configs.position)
        end
        return helper.success()
    end
    return helper.error("UNITYADS: Position must be given")
end

---Sets banner size. It is imperative to reload the banner again after this function.
---@param size table table `{width = number, height = number}`
---@return table
function M.set_banner_size(size)
    if not size then
        return helper.error("UNITYADS: Size must be given")
    end
    if size.width then
        banner_configs.size.width = size.width
    end
    if size.height then
        banner_configs.size.height = size.height
    end
    return helper.success()
end

---Check if the banner is showed
---@return boolean
function M.is_banner_showed()
    return banner_showed
end

return M
