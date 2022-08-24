local M = {NAME = "admob"}
-- Extention: https://github.com/defold/extension-admob

local ads = require("ads_wrapper.ads_wrapper")
local platform = require("ads_wrapper.platform")
local helper = require("ads_wrapper.ads_networks.helper")

local parameters
local module_callback
local banner_showed = false
local is_admob_initialized = false
local is_reward_get = false
local banner_configs
if admob then
    banner_configs = {size = admob.SIZE_ADAPTIVE_BANNER, position = admob.POS_TOP_CENTER}
end

---Call saved `module_callback` only once.
---@param response any
local function callback_once(response)
    if module_callback then
        local callback = module_callback
        module_callback = nil
        callback(response)
    end
end

---Call callback in the second frame.
---It is necessary to use timer for the coroutine to continue.
---@param response hash
local function callback_delay(callback, response)
    if callback then
        timer.delay(0, false, function()
            callback(response)
        end)
    end
end

local function admob_callback(self, message_id, message)
    if message_id == admob.MSG_INITIALIZATION then
        is_admob_initialized = true
        if message.event == admob.EVENT_COMPLETE then
            callback_once(helper.success())
        elseif message.event == admob.EVENT_JSON_ERROR then
            callback_once(helper.error("ADMOB: EVENT_JSON_ERROR: Internal NE json error: " .. tostring(message.error)))
        end
    elseif message_id == admob.MSG_IDFA then
        if message.event == admob.EVENT_JSON_ERROR then
            callback_once(helper.error("ADMOB: EVENT_JSON_ERROR: Internal NE json error: " .. tostring(message.error)))
        else
            local message_text = "IDFA event"
            if message.event == admob.EVENT_STATUS_AUTORIZED then
                message_text = "ADMOB: EVENT_STATUS_AUTORIZED: ATTrackingManagerAuthorizationStatusAuthorized"
            elseif message.event == admob.EVENT_STATUS_DENIED then
                message_text = "ADMOB: EVENT_STATUS_DENIED: ATTrackingManagerAuthorizationStatusDenied"
            elseif message.event == admob.EVENT_STATUS_NOT_DETERMINED then
                message_text = "ADMOB: EVENT_STATUS_NOT_DETERMINED: ATTrackingManagerAuthorizationStatusNotDetermined"
            elseif message.event == admob.EVENT_STATUS_RESTRICTED then
                message_text = "ADMOB: EVENT_STATUS_RESTRICTED: ATTrackingManagerAuthorizationStatusRestricted"
            elseif message.event == admob.EVENT_NOT_SUPPORTED then
                message_text = "ADMOB: EVENT_NOT_SUPPORTED: IDFA request not supported on this platform or OS version"
            end
            callback_once(helper.success(message_text, message.event))
        end
    elseif message_id == admob.MSG_INTERSTITIAL then
        if message.event == admob.EVENT_CLOSED then
            callback_once(helper.success())
        elseif message.event == admob.EVENT_FAILED_TO_SHOW then
            callback_once(helper.error(
                              "ADMOB: EVENT_FAILED_TO_SHOW: Interstitial AD failed to show\nCode: " .. tostring(message.code) .. "\nError: " ..
                                  tostring(message.error)))
        elseif message.event == admob.EVENT_OPENING then
            -- on android this event fire only when ADS activity closed =(
            -- print("EVENT_OPENING: Interstitial AD is opening")
        elseif message.event == admob.EVENT_FAILED_TO_LOAD then
            callback_once(helper.error(
                              "ADMOB: EVENT_FAILED_TO_LOAD: Interstitial AD failed to load\nCode: " .. tostring(message.code) .. "\nError: " ..
                                  tostring(message.error)))
        elseif message.event == admob.EVENT_LOADED then
            callback_once(helper.success())
        elseif message.event == admob.EVENT_NOT_LOADED then
            callback_once(helper.error(
                              "ADMOB: EVENT_NOT_LOADED: can't call show_interstitial() before EVENT_LOADED\nCode: " .. tostring(message.code) .. "\nError: " ..
                                  tostring(message.error)))
        elseif message.event == admob.EVENT_IMPRESSION_RECORDED then
            -- print("EVENT_IMPRESSION_RECORDED: Interstitial did record impression")
        elseif message.event == admob.EVENT_JSON_ERROR then
            callback_once(helper.error("ADMOB: EVENT_JSON_ERROR: Internal NE json error: " .. tostring(message.error)))
        end
    elseif message_id == admob.MSG_REWARDED then
        if message.event == admob.EVENT_CLOSED then
            if is_reward_get then
                callback_once(helper.success())
            else
                callback_once(helper.skipped())
            end
            is_reward_get = false
        elseif message.event == admob.EVENT_FAILED_TO_SHOW then
            callback_once(helper.error("ADMOB: EVENT_FAILED_TO_SHOW: Rewarded AD failed to show\nCode: " .. tostring(message.code) .. "\nError: " ..
                                           tostring(message.error)))
        elseif message.event == admob.EVENT_OPENING then
            -- on android this event fire only when ADS activity closed =(
            -- print("EVENT_OPENING: Rewarded AD is opening")
        elseif message.event == admob.EVENT_FAILED_TO_LOAD then
            callback_once(helper.error("ADMOB: EVENT_FAILED_TO_LOAD: Rewarded AD failed to load\nCode: " .. tostring(message.code) .. "\nError: " ..
                                           tostring(message.error)))
        elseif message.event == admob.EVENT_LOADED then
            callback_once(helper.success())
        elseif message.event == admob.EVENT_NOT_LOADED then
            callback_once(helper.error("ADMOB: EVENT_NOT_LOADED: can't call show_rewarded() before EVENT_LOADED\nError: " .. tostring(message.error)))
        elseif message.event == admob.EVENT_EARNED_REWARD then
            is_reward_get = true
        elseif message.event == admob.EVENT_IMPRESSION_RECORDED then
            -- print("EVENT_IMPRESSION_RECORDED: Rewarded did record impression")
        elseif message.event == admob.EVENT_JSON_ERROR then
            callback_once(helper.error("ADMOB: EVENT_JSON_ERROR: Internal NE json error: " .. tostring(message.error)))
        end
    elseif message_id == admob.MSG_BANNER then
        if message.event == admob.EVENT_LOADED then
            callback_once(helper.success("ADMOB: EVENT_LOADED: Banner AD loaded. Height: " .. tostring(message.height) .. "px Width: " ..
                                             tostring(message.width) .. "px"))
        elseif message.event == admob.EVENT_OPENING then
            -- print("ADMOB: EVENT_OPENING: Banner AD is opening")
        elseif message.event == admob.EVENT_FAILED_TO_LOAD then
            callback_once(helper.error("ADMOB: EVENT_FAILED_TO_LOAD: Banner AD failed to load\nCode: " .. tostring(message.code) .. "\nError: " ..
                                           tostring(message.error)))
        elseif message.event == admob.EVENT_CLICKED then
            -- print("ADMOB: EVENT_CLICKED: Banner AD loaded")
        elseif message.event == admob.EVENT_CLOSED then
            -- print("ADMOB: EVENT_CLOSED: Banner AD closed")
        elseif message.event == admob.EVENT_DESTROYED then
            callback_once(helper.success("ADMOB: EVENT_DESTROYED: Banner AD destroyed"))
        elseif message.event == admob.EVENT_IMPRESSION_RECORDED then
            -- print("ADMOB: EVENT_IMPRESSION_RECORDED: Banner did record impression")
        elseif message.event == admob.EVENT_JSON_ERROR then
            callback_once(helper.error("ADMOB: EVENT_JSON_ERROR: Internal NE json error: " .. tostring(message.error)))
        end
    end
end

---Api setup
---@param params table
function M.setup(params)
    parameters = params
    local banner_settings = parameters[ads.T_BANNER]
    if banner_settings then
        if banner_settings.size or banner_settings.size == 0 then
            banner_configs.size = banner_settings.size
        end
        if banner_settings.position or banner_settings.position == 0 then
            banner_configs.position = banner_settings.position
        end
    end
end

---Initializes `admob` sdk.
---@param callback function the function is called after execution.
function M.init(callback)
    module_callback = callback
    if ads.is_debug then
        if platform.is_same(platform.PL_IOS) then
            -- https://developers.google.com/admob/ios/test-ads
            parameters[ads.T_BANNER] = {id = "ca-app-pub-3940256099942544/2934735716"} -- test unit for banners
            parameters[ads.T_INTERSTITIAL] = "ca-app-pub-3940256099942544/4411468910" -- test unit for interstitial
            parameters[ads.T_REWARDED] = "ca-app-pub-3940256099942544/1712485313" -- test unit for rewarded
        elseif platform.is_same(platform.PL_ANDROID) then
            -- From https://developers.google.com/admob/android/test-ads
            parameters[ads.T_BANNER] = {id = "ca-app-pub-3940256099942544/6300978111"} -- test unit for banners
            parameters[ads.T_INTERSTITIAL] = "ca-app-pub-3940256099942544/1033173712" -- test unit for interstitial
            parameters[ads.T_REWARDED] = "ca-app-pub-3940256099942544/5224354917" -- test unit for rewarded
        end
    end
    admob.set_callback(admob_callback)
    admob.initialize()
end

---Requests IDFA
---@param callback function the function is called after execution.
function M.request_idfa(callback)
    module_callback = callback
    admob.set_callback(admob_callback)
    admob.request_idfa()
end

---Check if the environment supports admob api
---@return bool
function M.is_supported()
    return admob ~= nil
end

---Check if the admob is initialized
---@return bool
function M.is_initialized()
    return is_admob_initialized
end

---Shows rewarded ads.
---@param callback function the function is called after execution.
function M.show_rewarded(callback)
    module_callback = callback
    admob.set_callback(admob_callback)
    admob.show_rewarded()
end

---Loads rewarded ads
---@param callback function the function is called after execution.
function M.load_rewarded(callback)
    module_callback = callback
    admob.set_callback(admob_callback)
    admob.load_rewarded(parameters[ads.T_REWARDED])
end

---Check if the rewarded ads is loaded
---@return boolean
function M.is_rewarded_loaded()
    return admob.is_rewarded_loaded()
end

---Shows interstitial ads.
---@param callback function the function is called after execution.
function M.show_interstitial(callback)
    module_callback = callback
    admob.set_callback(admob_callback)
    admob.show_interstitial()
end

---Loads interstitial ads
---@param callback function the function is called after execution.
function M.load_interstitial(callback)
    module_callback = callback
    admob.set_callback(admob_callback)
    admob.load_interstitial(parameters[ads.T_INTERSTITIAL])
end

---Check if the interstitial ads is loaded
---@return boolean
function M.is_interstitial_loaded()
    return admob.is_interstitial_loaded()
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
        callback_delay(callback, helper.error("ADMOB: Banner not setup"))
        return
    end
    module_callback = callback
    admob.set_callback(admob_callback)
    admob.load_banner(parameters[ads.T_BANNER].id, banner_configs.size)
end

---Unloads active banner.
---@param callback function the function is called after execution.
function M.unload_banner(callback)
    if M.is_banner_loaded() then
        module_callback = callback
        admob.set_callback(admob_callback)
        banner_showed = false
        admob.destroy_banner()
    else
        callback_delay(callback, helper.error("ADMOB: Banner not loaded"))
    end
end

---Check if the banner is loaded
---@return boolean
function M.is_banner_loaded()
    return admob.is_banner_loaded()
end

---Shows loaded banner.
---@param callback function the function is called after execution.
function M.show_banner(callback)
    if M.is_banner_loaded() then
        admob.show_banner(banner_configs.position)
        banner_showed = true
        callback_delay(callback, helper.success())
    else
        callback_delay(callback, helper.error("ADMOB: Banner not loaded"))
    end
end

---Hides loaded banner.
---@param callback function the function is called after execution.
function M.hide_banner(callback)
    if M.is_banner_loaded() then
        admob.hide_banner()
        banner_showed = false
        callback_delay(callback, helper.success())
    else
        callback_delay(callback, helper.error("ADMOB: Banner not loaded"))
    end
end

---Sets banner position. It is imperative to hide and show the banner again after this function.
---Possible positions:
--- `admob.POS_NONE`(default)
--- `admob.POS_TOP_LEFT`
--- `admob.POS_TOP_CENTER`
--- `admob.POS_TOP_RIGHT`
--- `admob.POS_BOTTOM_LEFT`
--- `admob.POS_BOTTOM_CENTER`
--- `admob.POS_BOTTOM_RIGHT`
--- `admob.POS_CENTER`
---@param position number banner position
---@return hash
function M.set_banner_position(position)
    if position or position == 0 then
        banner_configs.position = position
        return helper.success()
    end
    return helper.error("ADMOB: Position must be given")
end

---Sets banner size. It is imperative to reload the banner again after this function.
---Possible sizes:
--- `admob.SIZE_ADAPTIVE_BANNER`(default)
--- `admob.SIZE_BANNER`
--- `admob.SIZE_FLUID`
--- `admob.SIZE_FULL_BANNER`
--- `admob.SIZE_LARGE_BANNER`
--- `admob.SIZE_LEADEARBOARD`
--- `admob.SIZE_MEDIUM_RECTANGLE`
--- `admob.SIZE_SEARH`
--- `admob.SIZE_SKYSCRAPER`
--- `admob.SIZE_SMART_BANNER`
---@param size number
---@return hash
function M.set_banner_size(size)
    if not size then
        return helper.error("ADMOB: Size must be given")
    end
    if size then
        banner_configs.size = size
    end
    return helper.success()
end

---Check if the banner is showed
---@return boolean
function M.is_banner_showed()
    return banner_showed
end

return M
