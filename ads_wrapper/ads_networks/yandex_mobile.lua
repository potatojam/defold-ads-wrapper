local ads = require("ads_wrapper.ads_wrapper")
local helper = require("ads_wrapper.ads_networks.helper")

local M = { NAME = "yandex_mobile" }
-- Extention: https://github.com/osov/defold-yandex-sdk-ads

local parameters
---@type ads_callback|nil
local module_callback
local banner_showed = false
local is_yandexads_initialized = false
local is_reward_get = false

---Call saved `module_callback` only once.
---@param response ads_response
local function callback_once(response)
    if module_callback then
        local callback = module_callback
        module_callback = nil
        callback(response)
    end
end

---Call callback in the second frame.
---It is necessary to use timer for the coroutine to continue.
---@param response ads_response
local function callback_delay(callback, response)
    if callback then
        timer.delay(0, false, function()
            callback(response)
        end)
    end
end

local function yandexads_callback(self, message_id, message)
    if message_id == yandexads.MSG_ADS_INITED then
        is_yandexads_initialized = true
        if message.event == yandexads.EVENT_LOADED then
            callback_once(helper.success())
        end
    elseif message_id == yandexads.MSG_INTERSTITIAL then
        if message.event == yandexads.EVENT_SHOWN then
            -- print("yandexads: EVENT_SHOWN: Interstitial AD is showed")
        elseif message.event == yandexads.EVENT_DISMISSED then
            callback_once(helper.success())
            -- print("yandexads: EVENT_DISMISSED: Interstitial AD is dismissed")
        elseif message.event == yandexads.EVENT_CLICKED then
            -- print("yandexads: EVENT_CLICKED: Interstitial AD is clicked")
        elseif message.event == yandexads.EVENT_NOT_LOADED then
            callback_once(helper.error("yandexads: EVENT_NOT_LOADED: Interstitial AD not loaded\nError: " .. tostring(message.error)))
        elseif message.event == yandexads.EVENT_LOADED then
            callback_once(helper.success())
        elseif message.event == yandexads.EVENT_ERROR_LOAD then
            callback_once(helper.error("yandexads: EVENT_ERROR_LOAD: Interstitial Error load: " .. tostring(message.error)))
        elseif message.event == yandexads.EVENT_IMPRESSION then
            -- print("yandexads: EVENT_IMPRESSION: Interstitial did record impression")
        end
    elseif message_id == yandexads.MSG_REWARDED then
        if message.event == yandexads.EVENT_SHOWN then
            -- print("yandexads: EVENT_SHOWN: Rewarded AD is showed")
        elseif message.event == yandexads.EVENT_DISMISSED then
            -- print("yandexads: EVENT_DISMISSED: Rewarded AD is dismissed")
            if is_reward_get then
                callback_once(helper.success())
            else
                callback_once(helper.skipped())
            end
            is_reward_get = false
        elseif message.event == yandexads.EVENT_NOT_LOADED then
            callback_once(helper.error("yandexads: EVENT_NOT_LOADED: Rewarded AD not loaded \nError: " .. tostring(message.error)))
        elseif message.event == yandexads.EVENT_CLICKED then
            -- print("yandexads: EVENT_CLICKED: Rewarded AD is clicked")
        elseif message.event == yandexads.EVENT_ERROR_LOAD then
            callback_once(helper.error("yandexads: EVENT_ERROR_LOAD: Rewarded AD failed to load\nError: " .. tostring(message.error)))
        elseif message.event == yandexads.EVENT_LOADED then
            callback_once(helper.success())
        elseif message.event == yandexads.EVENT_REWARDED then
            is_reward_get = true
        elseif message.event == yandexads.EVENT_IMPRESSION then
            -- print("yandexads: EVENT_IMPRESSION: Rewarded did record impression")
        end
    elseif message_id == yandexads.MSG_BANNER then
        if message.event == yandexads.EVENT_LOADED then
            callback_once(helper.success("yandexads: EVENT_LOADED: Banner AD loaded"))
        elseif message.event == yandexads.EVENT_ERROR_LOAD then
            callback_once(helper.error("yandexads: EVENT_ERROR_LOAD: Banner AD failed to load\nError: " .. tostring(message.error)))
        elseif message.event == yandexads.EVENT_CLICKED then
            -- print("yandexads: EVENT_CLICKED: Banner AD loaded")
        elseif message.event == yandexads.EVENT_DESTROYED then
            callback_once(helper.success("yandexads: EVENT_DESTROYED: Banner AD destroyed"))
        elseif message.event == yandexads.EVENT_IMPRESSION then
            -- print("yandexads: EVENT_IMPRESSION: Banner did record impression")
        end
    end
end

---Api setup
---@param params table
function M.setup(params)
    parameters = params
end

---Initializes `yandexads` sdk.
---@param callback ads_callback|nil the function is called after execution.
function M.init(callback)
    module_callback = callback
    if ads.is_debug then
        parameters[ads.T_BANNER] = "R-M-DEMO-300x250" -- test unit for banners
        parameters[ads.T_INTERSTITIAL] = "R-M-DEMO-interstitial" -- test unit for interstitial
        parameters[ads.T_REWARDED] = "R-M-DEMO-rewarded-client-side-rtb" -- test unit for rewarded
    end
    yandexads.set_callback(yandexads_callback)
    yandexads.initialize()
end

---Check if the environment supports yandexads api
---@return bool
function M.is_supported()
    return yandexads ~= nil
end

---Check if the yandexads is initialized
---@return bool
function M.is_initialized()
    return is_yandexads_initialized
end

---Shows rewarded ads.
---@param callback ads_callback|nil the function is called after execution.
function M.show_rewarded(callback)
    module_callback = callback
    yandexads.set_callback(yandexads_callback)
    yandexads.show_rewarded()
end

---Loads rewarded ads
---@param callback ads_callback|nil the function is called after execution.
function M.load_rewarded(callback)
    module_callback = callback
    yandexads.set_callback(yandexads_callback)
    yandexads.load_rewarded(parameters[ads.T_REWARDED])
end

---Check if the rewarded ads is loaded
---@return boolean
function M.is_rewarded_loaded()
    return yandexads.is_rewarded_loaded()
end

---Shows interstitial ads.
---@param callback ads_callback|nil the function is called after execution.
function M.show_interstitial(callback)
    module_callback = callback
    yandexads.set_callback(yandexads_callback)
    yandexads.show_interstitial()
end

---Loads interstitial ads
---@param callback ads_callback|nil the function is called after execution.
function M.load_interstitial(callback)
    module_callback = callback
    yandexads.set_callback(yandexads_callback)
    yandexads.load_interstitial(parameters[ads.T_INTERSTITIAL])
end

---Check if the interstitial ads is loaded
---@return boolean
function M.is_interstitial_loaded()
    return yandexads.is_interstitial_loaded()
end

---Check if the banner is set up
---@return boolean
function M.is_banner_setup()
    return parameters[ads.T_BANNER]
end

---Loads banner. Use `ads.T_BANNER` parameter.
---@param callback ads_callback|nil the function is called after execution.
function M.load_banner(callback)
    if not M.is_banner_setup() then
        callback_delay(callback, helper.error("yandexads: Banner not setup"))
        return
    end
    module_callback = callback
    yandexads.set_callback(yandexads_callback)
    yandexads.load_banner(parameters[ads.T_BANNER])
end

---Unloads active banner.
---@param callback ads_callback|nil the function is called after execution.
function M.unload_banner(callback)
    if M.is_banner_loaded() then
        module_callback = callback
        yandexads.set_callback(yandexads_callback)
        banner_showed = false
        yandexads.destroy_banner()
    else
        callback_delay(callback, helper.error("yandexads: Banner not loaded"))
    end
end

---Check if the banner is loaded
---@return boolean
function M.is_banner_loaded()
    return yandexads.is_banner_loaded()
end

---Shows loaded banner.
---@param callback ads_callback|nil the function is called after execution.
function M.show_banner(callback)
    if M.is_banner_loaded() then
        yandexads.show_banner()
        banner_showed = true
        callback_delay(callback, helper.success())
    else
        callback_delay(callback, helper.error("yandexads: Banner not loaded"))
    end
end

---Hides loaded banner.
---@param callback ads_callback|nil the function is called after execution.
function M.hide_banner(callback)
    if M.is_banner_loaded() then
        yandexads.hide_banner()
        banner_showed = false
        callback_delay(callback, helper.success())
    else
        callback_delay(callback, helper.error("yandexads: Banner not loaded"))
    end
end

---Check if the banner is showed
---@return boolean
function M.is_banner_showed()
    return banner_showed
end

return M
