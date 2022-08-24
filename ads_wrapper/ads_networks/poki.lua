local M = {NAME = "poki"}
-- Extention: https://github.com/AGulev/defold-poki-sdk

local ads = require("ads_wrapper.ads_wrapper")
local helper = require("ads_wrapper.ads_networks.helper")
local events = require("ads_wrapper.events")

local parameters
local module_callback

local is_poki_initialized = false

-- Call saved `module_callback` only once.
---@param response any
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
---@param response hash
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
    if poki_sdk.is_ad_blocked() then
        callback_once(helper.error("Adblock detected", events.C_ERROR_AD_BLOCK))
    else
        callback_once(helper.success())
    end
end

-- Called when a rewarded video is closed.
---@param self userdata script data
local function rewarded_close(self, success)
    if poki_sdk.is_ad_blocked() then
        callback_once(helper.error("Adblock detected", events.C_ERROR_AD_BLOCK))
    else
        if success then
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
---@param callback function the function is called after execution.
function M.init(callback)
    module_callback = callback
    if M.is_supported() then
        is_poki_initialized = true
        if ads.is_debug then
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
---@param callback function the function is called after execution.
function M.show_rewarded(callback)
    module_callback = callback
    if poki_sdk.is_ad_blocked() then
        callback_once(helper.error("Adblock detected", events.C_ERROR_AD_BLOCK))
    else
        poki_sdk.rewarded_break(rewarded_close)
    end
end

-- Not used.
---@param callback function the function is called after execution.
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
---@param callback function the function is called after execution.
function M.show_interstitial(callback)
    module_callback = callback
    if poki_sdk.is_ad_blocked() then
        callback_once(helper.error("Adblock detected", events.C_ERROR_AD_BLOCK))
    else
        poki_sdk.commercial_break(adv_close)
    end
end

-- Not used.
---@param callback function the function is called after execution.
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
---@param callback function the function is called after execution.
function M.load_banner(callback)
    module_callback = callback
    callback_once_delay(helper.error("Banner not supported"))
end

---Not supported.
---@param callback function the function is called after execution.
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
---@param callback function the function is called after execution.
function M.show_banner(callback)
    module_callback = callback
    callback_once_delay(helper.error("Banner not supported"))
end

---Not supported.
---@param callback function the function is called after execution.
function M.hide_banner(callback)
    module_callback = callback
    callback_once_delay(helper.error("Banner not supported"))
end

---Not supported.
---@param position any
---@return table
function M.set_banner_position(position)
    return helper.error("Banner not supported")
end

---Not supported.
---@param size any
---@return table
function M.set_banner_size(size)
    return helper.error("Banner not supported")
end

---Not supported. Always `false`
---@return boolean false
function M.is_banner_showed()
    return false
end

return M
