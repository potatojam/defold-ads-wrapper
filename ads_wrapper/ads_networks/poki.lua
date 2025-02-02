local helper = require("ads_wrapper.ads_networks.helper")

local M = { NAME = "poki" }
-- Extention: https://github.com/AGulev/defold-poki-sdk

---@class rewarded_params
---@field size string
---@field start_callback function

local parameters
---@type ads_callback|nil
local module_callback
---@type rewarded_params|nil
local rewarded_params = nil

local is_poki_initialized = false

-- Call saved `module_callback` only once.
---@param response ads_response
local function callback_once(response)
    if module_callback then
        local callback = module_callback
        module_callback = nil
        timer.delay(0, false, function()
            callback(response)
        end)
    end
end

---Call saved `module_callback` in the second frame.
---It is necessary to use timer for the coroutine to continue.
---@param response ads_response
local function callback_once_delay(response)
    if module_callback then
        timer.delay(0, false, function()
            callback_once(response)
        end)
    end
end

-- Called when a interstitial is closed.
---@param self userdata script data
local function adv_close(self)
    callback_once(helper.success())
end

-- Called when a rewarded video is closed.
---@param self userdata script data
---@param event boolean|hash
local function rewarded_close(self, event)
    if rewarded_params then
        if event == poki_sdk.REWARDED_BREAK_START then
            if rewarded_params.start_callback then
                rewarded_params.start_callback()
            end
        elseif event == poki_sdk.REWARDED_BREAK_SUCCESS then
            rewarded_params = nil
            callback_once(helper.success())
        elseif event == poki_sdk.REWARDED_BREAK_ERROR then
            rewarded_params = nil
            callback_once(helper.error("Something bad happened"))
        else
            rewarded_params = nil
            callback_once(helper.error("Unhandled event " .. tostring(event)))
        end
    else
        if event then
            callback_once(helper.success())
        else
            callback_once(helper.skipped())
        end
    end
end

-- Api setup
---@param params table
function M.setup(params)
    parameters = params
end

-- Initializes `poki` sdk.
---@param callback ads_callback|nil the function is called after execution.
function M.init(callback)
    module_callback = callback
    if M.is_supported() then
        is_poki_initialized = true
        if parameters and parameters.is_debug then
            poki_sdk.set_debug(true)
        end
        callback_once(helper.success())
    else
        is_poki_initialized = false
        callback_once(helper.error("Poki SDK not supported"))
    end
end

---Check if the environment supports poki sdk
---@return bool
function M.is_supported()
    return html5 and poki_sdk
end

---Check if the poki is initialized
---@return bool
function M.is_initialized()
    return is_poki_initialized
end

-- Shows rewarded popup.
---@param callback ads_callback|nil the function is called after execution.
---@param params rewarded_params|nil
function M.show_rewarded(callback, params)
    module_callback = callback
    if params then
        rewarded_params = params
        poki_sdk.rewarded_break(rewarded_params.size or "small", rewarded_close)
    else
        poki_sdk.rewarded_break(rewarded_close)
    end
end

-- Not used.
---@param callback ads_callback|nil the function is called after execution.
function M.load_rewarded(callback)
    module_callback = callback
    callback_once_delay(helper.success())
end

-- Not used. Always `true`.
---@return bool true
function M.is_rewarded_loaded()
    return true
end

-- Shows interstitial popup.
---@param callback ads_callback|nil the function is called after execution.
function M.show_interstitial(callback)
    module_callback = callback
    poki_sdk.commercial_break(adv_close)
end

-- Not used.
---@param callback ads_callback|nil the function is called after execution.
function M.load_interstitial(callback)
    module_callback = callback
    callback_once_delay(helper.success())
end

-- Not used. Always `true`.
---@return bool true
function M.is_interstitial_loaded()
    return true
end

---Not supported. Always `false`
---@return boolean
function M.is_banner_setup()
    return false
end

---Not supported.
---@param callback ads_callback|nil the function is called after execution.
function M.load_banner(callback)
    module_callback = callback
    callback_once_delay(helper.error("Banner not supported"))
end

---Not supported.
---@param callback ads_callback|nil the function is called after execution.
function M.unload_banner(callback)
    module_callback = callback
    callback_once_delay(helper.error("Banner not supported"))
end

---Not supported. Always `false`
---@return boolean
function M.is_banner_loaded()
    return false
end

---Not supported.
---@param callback ads_callback|nil the function is called after execution.
function M.show_banner(callback)
    module_callback = callback
    callback_once_delay(helper.error("Banner not supported"))
end

---Not supported.
---@param callback ads_callback|nil the function is called after execution.
function M.hide_banner(callback)
    module_callback = callback
    callback_once_delay(helper.error("Banner not supported"))
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
