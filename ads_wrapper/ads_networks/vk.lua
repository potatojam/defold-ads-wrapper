local M = {NAME = "vk"}
-- Extention: https://github.com/potatojam/defold-vkbridge

local ads = require("ads_wrapper.ads_wrapper")
local helper = require("ads_wrapper.ads_networks.helper")

local vkbridge
local parameters
local module_callback

local is_vk_initialized = false
local is_reward_available = false
local is_interstitial_available = false
local is_load_started = false
local is_fresh_banner = false
local banner_loaded = false
local banner_showed = false
local banner_configs = {count = 1, position = "top"}

-- Call saved `module_callback` only once. Send result.
---@param result any
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

-- Called when an api is initialized.
---@param self userdata script data
---@param err table|nil error message. `nil` if everything is ok.
local function vk_init_handler(self, err)
    if err then
        is_vk_initialized = false
        callback_once(helper.error("VK: init error: " .. err.error_data.error_reason))
    else
        is_vk_initialized = true
        callback_once(helper.success())
    end
end

-- Called when a rewarded video is closed.
---@param self userdata script data
---@param err table|nil error message. `nil` if everything is ok.
---@param data table|nil `{result = boolean}`
local function on_show_rewarded(self, err, data)
    if err then
        callback_once(helper.error("VK: on_show_rewarded error: " .. err.error_data.error_reason))
    else
        if data.result then
            callback_once(helper.success())
        else
            callback_once(helper.skipped())
        end
    end
end

-- Called when a rewarded video is checked.
---@param self userdata script data
---@param err table|nil error message. `nil` if everything is ok.
---@param data table|nil `{result = boolean}`
local function on_check_rewarded(self, err, data)
    if err then
        is_reward_available = false
        callback_once(helper.error("VK: on_check_rewarded error: " .. err.error_data.error_reason))
    else
        if data.result then
            is_reward_available = true
            callback_once(helper.success())
        else
            is_reward_available = false
            callback_once(helper.error("VK: on_check_rewarded: Video unavailable"))
        end
    end
end

-- Called when a rewarded video is checked.
---@param self userdata script data
---@param err table|nil error message. `nil` if everything is ok.
---@param data table|nil `{result = boolean}`
local function on_check_interstitial(self, err, data)
    if err then
        is_interstitial_available = false
        callback_once(helper.error("VK: on_check_interstitial error: " .. err.error_data.error_reason))
    else
        if data.result then
            is_interstitial_available = true
            callback_once(helper.success())
        else
            is_interstitial_available = false
            callback_once(helper.error("VK: on_check_interstitial: Ads unavailable"))
        end
    end
end

-- Called when a intersitial video is closed.
---@param self userdata script data
---@param err table|nil error message. `nil` if everything is ok.
---@param data table|nil `{result = boolean}`
local function on_interstitial_showed(self, err, data)
    if err then
        callback_once(helper.error("VK: on_interstitial_showed error: " .. err.error_data.error_reason))
    else
        if data.result then
            local response = helper.success()
            response.was_open = not data.exceeded
            response.delay_exceeded = data.delay_exceeded
            response.hour_limit_exceeded = data.hour_limit_exceeded
            response.day_limit_exceeded = data.day_limit_exceeded
            callback_once(response)
        else
            callback_once(helper.error("VK: on_interstitial_showed: Ads unavailable"))
        end
    end
end

-- Called when a banner is loaded.
---@param self userdata script data
---@param err table|nil error message. `nil` if everything is ok.
---@param data table|nil `{result = boolean}`
local function on_load_banner(self, err, data)
    is_load_started = false
    if err then
        callback_once(helper.error("VK: on_load_banner error: " .. err.error_data.error_reason))
    else
        if data.result then
            banner_loaded = true
            is_fresh_banner = true
            callback_once(helper.success())
        else
            callback_once(helper.error("VK: on_load_banner: Banner not loaded"))
        end
    end
end

---Sets vkbridge extention
---@param _vkbridge any
function M.set_vkbridge_extention(_vkbridge)
    vkbridge = _vkbridge
end

-- Api setup
---@param params table
function M.setup(params)
    parameters = params
    local banner_settings = parameters[ads.T_BANNER]
    if banner_settings then
        if banner_settings.count then
            M.set_banner_count(banner_settings.count)
        end
        if banner_settings.position then
            M.set_banner_position(banner_settings.position)
        end
    end
end

-- Initializes `vk` sdk.
---@param callback function the function is called after execution.
function M.init(callback)
    module_callback = callback
    vkbridge.init(vk_init_handler)
end

---Check if the environment supports vk api
---@return bool
function M.is_supported()
    return vkbridge_private
end

---Check if the vk is initialized
---@return bool
function M.is_initialized()
    return is_vk_initialized
end

-- Shows rewarded popup.
---@param callback function the function is called after execution.
function M.show_rewarded(callback)
    module_callback = callback
    vkbridge.show_rewarded(true, on_show_rewarded)
end

-- Check if rewarded video is available
---@param callback function the function is called after execution.
function M.load_rewarded(callback)
    module_callback = callback
    vkbridge.check_rewarded(true, on_check_rewarded)
end

-- Not used. Always `true`.
---@return bool true
function M.is_rewarded_loaded()
    return is_reward_available
end

-- Shows interstitial popup.
---@param callback function the function is called after execution.
function M.show_interstitial(callback)
    module_callback = callback
    vkbridge.show_interstitial(on_interstitial_showed)
end

-- Check if interstitial is available
---@param callback function the function is called after execution.
function M.load_interstitial(callback)
    module_callback = callback
    vkbridge.check_interstitial(on_check_interstitial)
end

-- Not used. Always `true`.
---@return bool true
function M.is_interstitial_loaded()
    return is_interstitial_available
end

---Check if the banner is set up
---@return boolean
function M.is_banner_setup()
    return banner_configs ~= nil
end

---Loads banner. Use `ads.T_BANNER` parameter.
---@param callback function the function is called after execution.
function M.load_banner(callback)
    if not vkbridge.is_webview() then
        callback_delay(callback, helper.error("Only works for webview"))
        return
    end
    if is_load_started or not M.is_banner_setup() then
        callback_delay(callback, helper.error("VK: Banner not setup or loading now"))
        return
    end
    if is_fresh_banner then
        callback_delay(callback, helper.success("VK: The banner was not displayed after the last load."))
        return
    end
    is_load_started = true
    module_callback = callback
    ---TODO: maybe wait some time before refreshing banner?
    vkbridge.refresh_wv_banner(on_load_banner)
end

---Unloads active banner.
---@param callback function the function is called after execution.
function M.unload_banner(callback)
    if not vkbridge.is_webview() then
        callback_delay(callback, helper.error("Only works for webview"))
        return
    end
    if M.is_banner_loaded() then
        banner_loaded = false
        banner_showed = false
        vkbridge.unload_wv_banner()
        callback_delay(callback, helper.success())
    else
        callback_delay(callback, helper.error("VK: Banner not loaded"))
    end
end

---Check if the banner is loaded
---@return boolean
function M.is_banner_loaded()
    return banner_loaded
end

---Shows loaded banner.
---@param callback function the function is called after execution.
function M.show_banner(callback)
    if not vkbridge.is_webview() then
        callback_delay(callback, helper.error("VK: Only works for webview"))
        return
    end
    if M.is_banner_loaded() then
        banner_showed = true
        is_fresh_banner = false
        local result = vkbridge.show_wv_banner()
        if result then
            callback_delay(callback, helper.success())
        else
            callback_delay(callback, helper.error("VK: Undefined error"))
        end
    else
        callback_delay(callback, helper.error("VK: Banner not loaded"))
    end
end

---Hides loaded banner.
---@param callback function the function is called after execution.
function M.hide_banner(callback)
    if not vkbridge.is_webview() then
        callback_delay(callback, helper.error("VK: Only works for webview"))
        return
    end
    if M.is_banner_loaded() then
        banner_showed = false
        ---For refresh banner
        banner_loaded = false
        vkbridge.hide_wv_banner()
        callback_delay(callback, helper.success())
    else
        callback_delay(callback, helper.error("VK: Banner not loaded"))
    end
end

---Sets banner count.
---@param count number Default `1`
---@return hash
function M.set_banner_count(count)
    if not count then
        return helper.error("VK: Count must be given")
    end
    banner_configs.count = count
    if vkbridge.is_webview() then
        vkbridge.set_wv_banner_configs(banner_configs.position, banner_configs.count)
    end
    return helper.success()
end

---Sets banner position.
---@param position string Can be `top` or `bottom`
---@return hash
function M.set_banner_position(position)
    if not position then
        return helper.error("VK: Position must be given")
    end
    banner_configs.position = position
    if vkbridge.is_webview() then
        vkbridge.set_wv_banner_configs(banner_configs.position, banner_configs.count)
    end
    return helper.success()
end

---Check if the banner is showed
---@return boolean
function M.is_banner_showed()
    return banner_showed
end

return M
