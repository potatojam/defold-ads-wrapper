local helper = require("ads_wrapper.ads_networks.helper")

local M = {NAME = "portalsdk"}

---@class rewarded_params
---@field size string
---@field start_callback function

local parameters
---@type rewarded_params|nil
local rewarded_params = nil

local is_portalsdk_initialized = false
local is_rewarded_loaded = false
local is_interstitial_loaded = false

---Create an asynchronous callback that can be completed only once.
---@param callback ads_callback|nil
---@return fun(response: ads_response)
local function make_callback_once(callback)
    local is_completed = false
    return function(response)
        if callback and not is_completed then
            is_completed = true
            local completed_callback = callback
            callback = nil
            timer.delay(0, false, function()
                completed_callback(response)
            end)
        end
    end
end

---Complete a callback in the second frame.
---It is necessary to use timer for the coroutine to continue.
---@param callback fun(response: ads_response)
---@param response ads_response
local function callback_once_delay(callback, response)
    timer.delay(0, false, function()
        callback(response)
    end)
end

---Run a PortalSDK request and complete its callback if the SDK throws.
---@param callback fun(response: ads_response)
---@param error_message string
---@param request function
local function call_portalsdk(callback, error_message, request)
    local is_success, request_error = pcall(request)
    if not is_success then
        callback(helper.error(error_message .. ": " .. tostring(request_error)))
    end
end

-- Api setup
---@param params table
function M.setup(params)
    parameters = params
end

-- Initializes `portalsdk` sdk.
---@param callback ads_callback|nil the function is called after execution.
function M.init(callback)
    local callback_once = make_callback_once(callback)
    if M.is_supported() then
        is_portalsdk_initialized = true
        callback_once(helper.success())
    else
        is_portalsdk_initialized = false
        callback_once(helper.error("portalsdk SDK not supported"))
    end
end

---Check if the environment supports portalsdk sdk
---@return bool
function M.is_supported()
    return not not (html5 and portalsdk)
end

---Check if the portalsdk is initialized
---@return bool
function M.is_initialized()
    return is_portalsdk_initialized
end

-- Shows rewarded popup.
---@param callback ads_callback|nil the function is called after execution.
---@param params rewarded_params|nil
function M.show_rewarded(callback, params)
    local callback_once = make_callback_once(callback)
    is_rewarded_loaded = false
    call_portalsdk(callback_once, "portalsdk rewarded request failed", function()
        portalsdk.request_reward_ad(function(self, success)
            if success then
                callback_once(helper.success())
            else
                callback_once(helper.skipped())
            end
        end)
    end)
end

-- Not used.
---@param callback ads_callback|nil the function is called after execution.
function M.load_rewarded(callback)
    local callback_once = make_callback_once(callback)
    is_rewarded_loaded = false
    call_portalsdk(callback_once, "portalsdk rewarded availability request failed", function()
        portalsdk.is_ad_enabled(function(self, data)
            if data then
                is_rewarded_loaded = true
                callback_once_delay(callback_once, helper.success())
            else
                callback_once_delay(callback_once, helper.error("portalsdk ads isn't enabled"))
            end
        end)
    end)
end

-- Not used. Always `true`.
---@return bool true
function M.is_rewarded_loaded()
    return is_rewarded_loaded
end

-- Shows interstitial popup.
---@param callback ads_callback|nil the function is called after execution.
function M.show_interstitial(callback)
    local callback_once = make_callback_once(callback)
    is_interstitial_loaded = false
    call_portalsdk(callback_once, "portalsdk interstitial request failed", function()
        portalsdk.request_ad(function(self)
            callback_once(helper.success())
        end)
    end)
end

-- Not used.
---@param callback ads_callback|nil the function is called after execution.
function M.load_interstitial(callback)
    local callback_once = make_callback_once(callback)
    is_interstitial_loaded = false
    call_portalsdk(callback_once, "portalsdk interstitial availability request failed", function()
        portalsdk.is_ad_enabled(function(self, data)
            if data then
                is_interstitial_loaded = true
                callback_once_delay(callback_once, helper.success())
            else
                callback_once_delay(callback_once, helper.error("portalsdk ads isn't enabled"))
            end
        end)
    end)
end

-- Not used. Always `true`.
---@return bool true
function M.is_interstitial_loaded()
    return is_interstitial_loaded
end

---Not supported. Always `false`
---@return boolean
function M.is_banner_setup()
    return false
end

---Not supported.
---@param callback ads_callback|nil the function is called after execution.
function M.load_banner(callback)
    local callback_once = make_callback_once(callback)
    callback_once_delay(callback_once, helper.error("Banner not supported"))
end

---Not supported.
---@param callback ads_callback|nil the function is called after execution.
function M.unload_banner(callback)
    local callback_once = make_callback_once(callback)
    callback_once_delay(callback_once, helper.error("Banner not supported"))
end

---Not supported. Always `false`
---@return boolean
function M.is_banner_loaded()
    return false
end

---Not supported.
---@param callback ads_callback|nil the function is called after execution.
function M.show_banner(callback)
    local callback_once = make_callback_once(callback)
    callback_once_delay(callback_once, helper.error("Banner not supported"))
end

---Not supported.
---@param callback ads_callback|nil the function is called after execution.
function M.hide_banner(callback)
    local callback_once = make_callback_once(callback)
    callback_once_delay(callback_once, helper.error("Banner not supported"))
end

---Not supported.
---@param position any
---@return ads_response
function M.set_banner_position(position)
    return helper.error("Banner not supported")
end

---Not supported.
---@param size any
---@return ads_response
function M.set_banner_size(size)
    return helper.error("Banner not supported")
end

---Not supported. Always `false`
---@return boolean false
function M.is_banner_showed()
    return false
end

return M
