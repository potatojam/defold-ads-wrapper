local M = {NAME = "applovin_max"}
-- Extention: https://github.com/alexeyfeskov/defold-maxsdk

local ads = require("ads_wrapper.ads_wrapper")
local helper = require("ads_wrapper.ads_networks.helper")

M.POS_BOTTOM_CENTER = "POS_BOTTOM_CENTER"
M.POS_BOTTOM_LEFT = "POS_BOTTOM_LEFT"
M.POS_BOTTOM_RIGHT = "POS_BOTTOM_RIGHT"
M.POS_NONE = "POS_NONE"
M.POS_TOP_LEFT = "POS_TOP_LEFT"
M.POS_TOP_CENTER = "POS_TOP_CENTER"
M.POS_TOP_RIGHT = "POS_TOP_RIGHT"
M.POS_CENTER = "POS_CENTER"

M.SIZE_BANNER = "SIZE_BANNER"
M.SIZE_LEADER = "SIZE_LEADER"
M.SIZE_MREC = "SIZE_MREC"

local parameters
local module_callback
local banner_showed = false
local is_applovin_initialized = false
local reward = {value = false, amount = nil, type = nil}
local banner_configs
if maxsdk then
    banner_configs = {size = M.SIZE_BANNER, position = M.POS_NONE}
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

local function maxsdk_callback(self, message_id, message)
    if message_id == maxsdk.MSG_INITIALIZATION then
        ---TODO: check error
        is_applovin_initialized = true
        callback_once(helper.success())
    elseif message_id == maxsdk.MSG_INTERSTITIAL then
        if message.event == maxsdk.EVENT_CLOSED then
            callback_once(helper.success())
        elseif message.event == maxsdk.EVENT_CLICKED then
            -- print("EVENT_CLICKED: Interstitial AD clicked")
        elseif message.event == maxsdk.EVENT_FAILED_TO_SHOW then
            callback_once(helper.error("APPLOVIN MAX: EVENT_FAILED_TO_SHOW: Interstitial AD failed to show\nCode: " .. tostring(message.code) ..
                                           "\nError: " .. tostring(message.error)))
        elseif message.event == maxsdk.EVENT_OPENING then
            -- print("EVENT_OPENING: Interstitial AD is opening")
        elseif message.event == maxsdk.EVENT_FAILED_TO_LOAD then
            callback_once(helper.error("APPLOVIN MAX: EVENT_FAILED_TO_LOAD: Interstitial AD failed to load\nCode: " .. tostring(message.code) ..
                                           "\nError: " .. tostring(message.error)))
        elseif message.event == maxsdk.EVENT_LOADED then
            callback_once(helper.success())
        elseif message.event == maxsdk.EVENT_NOT_LOADED then
            callback_once(helper.error("APPLOVIN MAX: EVENT_NOT_LOADED: can't call show_interstitial() before EVENT_LOADED\nCode: " ..
                                           tostring(message.code) .. "\nError: " .. tostring(message.error)))
        elseif message.event == maxsdk.EVENT_REVENUE_PAID then
            -- print("EVENT_REVENUE_PAID: Interstitial AD revenue: ", message.revenue, message.network)
        end
    elseif message_id == maxsdk.MSG_REWARDED then
        if message.event == maxsdk.EVENT_CLOSED then
            if reward.value then
                callback_once(helper.success())
            else
                callback_once(helper.skipped())
            end
            reward.value = false
            reward.amount = nil
            reward.type = nil
        elseif message.event == maxsdk.EVENT_FAILED_TO_SHOW then
            callback_once(helper.error("APPLOVIN MAX: EVENT_FAILED_TO_SHOW: Rewarded AD failed to show\nCode: " .. tostring(message.code) ..
                                           "\nError: " .. tostring(message.error)))
        elseif message.event == maxsdk.EVENT_OPENING then
            -- print("EVENT_OPENING: Rewarded AD is opening")
        elseif message.event == maxsdk.EVENT_FAILED_TO_LOAD then
            callback_once(helper.error("APPLOVIN MAX: EVENT_FAILED_TO_LOAD: Rewarded AD failed to load\nCode: " .. tostring(message.code) ..
                                           "\nError: " .. tostring(message.error)))
        elseif message.event == maxsdk.EVENT_LOADED then
            callback_once(helper.success(nil, {network = message.network}))
        elseif message.event == maxsdk.EVENT_NOT_LOADED then
            callback_once(helper.error("APPLOVIN MAX: EVENT_NOT_LOADED: can't call show_rewarded() before EVENT_LOADED\nError: " ..
                                           tostring(message.error)))
        elseif message.event == maxsdk.EVENT_EARNED_REWARD then
            reward.value = true
            reward.amount = message.amount
            reward.type = message.type
        elseif message.event == maxsdk.EVENT_REVENUE_PAID then
            -- print("EVENT_REVENUE_PAID: Rewarded AD revenue: ", message.revenue, message.network)
        end
    elseif message_id == maxsdk.MSG_BANNER then
        if message.event == maxsdk.EVENT_LOADED then
            callback_once(helper.success(nil, {network = message.network}))
        elseif message.event == maxsdk.EVENT_OPENING then
            ---Works very bad
        elseif message.event == maxsdk.EVENT_FAILED_TO_LOAD then
            callback_once(helper.error(
                              "APPLOVIN MAX: EVENT_FAILED_TO_LOAD: Banner AD failed to load\nCode: " .. tostring(message.code) .. "\nError: " ..
                                  tostring(message.error)))
        elseif message.event == maxsdk.EVENT_FAILED_TO_SHOW then
            callback_once(helper.error(
                              "APPLOVIN MAX: EVENT_FAILED_TO_LOAD: Banner AD failed to show\nCode: " .. tostring(message.code) .. "\nError: " ..
                                  tostring(message.error)))
        elseif message.event == maxsdk.EVENT_EXPANDED then
            -- print("EVENT_EXPANDED: Banner AD expanded")
        elseif message.event == maxsdk.EVENT_COLLAPSED then
            -- print("EVENT_COLLAPSED: Banner AD coppalsed")
        elseif message.event == maxsdk.EVENT_CLICKED then
            -- print("EVENT_CLICKED: Banner AD clicked")
        elseif message.event == maxsdk.EVENT_CLOSED then
            -- print("EVENT_CLOSED: Banner AD closed")
        elseif message.event == maxsdk.EVENT_DESTROYED then
            callback_once(helper.success())
        elseif message.event == maxsdk.EVENT_NOT_LOADED then
            callback_once(helper.error("APPLOVIN MAX: EVENT_JSON_ERROR: can't call show_banner() before EVENT_LOADED: " .. tostring(message.error)))
        elseif message.event == maxsdk.EVENT_REVENUE_PAID then
            -- print("EVENT_REVENUE_PAID: Banner AD revenue: ", message.revenue, message.network)
        end
    end
end

---Api setup
---@param params table
function M.setup(params)
    parameters = params or {}
    local banner_settings = parameters[ads.T_BANNER] or {}
    if banner_settings then
        if banner_settings.size then
            banner_configs.size = banner_settings.size
        end
        if banner_settings.position then
            banner_configs.position = banner_settings.position
        end
    end

    if parameters.LDU then
        maxsdk.set_fb_data_processing_options(parameters.LDU.name or "LDU", parameters.LDU.country or 0, parameters.LDU.state or 0)
    else
        maxsdk.set_fb_data_processing_options(nil)
    end
    if parameters.has_user_consent ~= nil then
        maxsdk.set_has_user_consent(parameters.has_user_consent)
    end
    if parameters.is_age_restricted_user ~= nil then
        maxsdk.set_is_age_restricted_user(parameters.is_age_restricted_user)
    end
    if parameters.do_not_sell ~= nil then
        maxsdk.set_do_not_sell(parameters.do_not_sell)
    end
    if parameters.muted ~= nil then
        maxsdk.set_muted(parameters.muted)
    end
    if parameters.verbose_logging ~= nil then
        maxsdk.set_verbose_logging(parameters.verbose_logging)
    end
end

---Initializes `applovin_max` sdk.
---@param callback function the function is called after execution.
function M.init(callback)
    module_callback = callback
    maxsdk.set_callback(maxsdk_callback)
    maxsdk.initialize()
end

---Check if the environment supports applovin_max api
---@return bool
function M.is_supported()
    return maxsdk ~= nil
end

---Check if the applovin max is initialized
---@return bool
function M.is_initialized()
    return is_applovin_initialized
end

---Shows rewarded ads.
---@param callback function the function is called after execution.
function M.show_rewarded(callback)
    module_callback = callback
    maxsdk.set_callback(maxsdk_callback)
    maxsdk.show_rewarded()
end

---Loads rewarded ads
---@param callback function the function is called after execution.
function M.load_rewarded(callback)
    module_callback = callback
    maxsdk.set_callback(maxsdk_callback)
    maxsdk.load_rewarded(parameters[ads.T_REWARDED])
end

---Check if the rewarded ads is loaded
---@return boolean
function M.is_rewarded_loaded()
    return maxsdk.is_rewarded_loaded()
end

---Shows interstitial ads.
---@param callback function the function is called after execution.
function M.show_interstitial(callback)
    module_callback = callback
    maxsdk.set_callback(maxsdk_callback)
    maxsdk.show_interstitial()
end

---Loads interstitial ads
---@param callback function the function is called after execution.
function M.load_interstitial(callback)
    module_callback = callback
    maxsdk.set_callback(maxsdk_callback)
    maxsdk.load_interstitial(parameters[ads.T_INTERSTITIAL])
end

---Check if the interstitial ads is loaded
---@return boolean
function M.is_interstitial_loaded()
    return maxsdk.is_interstitial_loaded()
end

---Check if the banner is set up
---@return boolean
function M.is_banner_setup()
    return parameters[ads.T_BANNER] and (parameters[ads.T_BANNER].id or parameters[ads.T_BANNER].mrec_id)
end

---Loads banner. Use `ads.T_BANNER` parameter.
---@param callback function the function is called after execution.
function M.load_banner(callback)
    if not M.is_banner_setup() then
        callback_delay(callback, helper.error("APPLOVIN MAX: Banner not setup"))
        return
    end
    module_callback = callback
    maxsdk.set_callback(maxsdk_callback)
    local is_mrec = (banner_configs.size == M.SIZE_MREC)
    local banner_id = is_mrec and parameters[ads.T_BANNER].mrec_id or parameters[ads.T_BANNER].id
    maxsdk.load_banner(banner_id, maxsdk[banner_configs.size])
end

---Unloads active banner.
---@param callback function the function is called after execution.
function M.unload_banner(callback)
    if M.is_banner_loaded() then
        module_callback = callback
        maxsdk.set_callback(maxsdk_callback)
        banner_showed = false
        maxsdk.destroy_banner()
    else
        callback_delay(callback, helper.error("APPLOVIN MAX: Banner not loaded"))
    end
end

---Check if the banner is loaded
---@return boolean
function M.is_banner_loaded()
    return maxsdk.is_banner_loaded()
end

---Shows loaded banner.
---@param callback function the function is called after execution.
function M.show_banner(callback)
    if M.is_banner_loaded() then
        module_callback = callback
        maxsdk.set_callback(maxsdk_callback)
        maxsdk.show_banner(maxsdk[banner_configs.position])
        banner_showed = true
        ---Wait until some error happens
        timer.delay(0.1, false, function ()
            if module_callback then
                callback_once(helper.success())
            end
        end)
    else
        callback_delay(callback, helper.error("APPLOVIN MAX: Banner not loaded"))
    end
end

---Hides loaded banner.
---@param callback function the function is called after execution.
function M.hide_banner(callback)
    if M.is_banner_loaded() then
        maxsdk.hide_banner()
        banner_showed = false
        callback_delay(callback, helper.success())
    else
        callback_delay(callback, helper.error("APPLOVIN MAX: Banner not loaded"))
    end
end

---Sets banner position. It is imperative to hide and show the banner again after this function.
---Possible positions:
--- `applovin_max.POS_TOP_CENTER`(default)
--- `applovin_max.POS_BOTTOM_CENTER`
--- `applovin_max.POS_BOTTOM_LEFT`
--- `applovin_max.POS_BOTTOM_RIGHT`
--- `applovin_max.POS_NONE`
--- `applovin_max.POS_TOP_LEFT`
--- `applovin_max.POS_TOP_RIGHT`
--- `applovin_max.POS_CENTER`
---@param position number banner position
---@return hash
function M.set_banner_position(position)
    if position or position == 0 then
        banner_configs.position = position
        return helper.success()
    end
    return helper.error("APPLOVIN MAX: Position must be given")
end

---Sets banner size. It is imperative to reload the banner again after this function.
---Possible sizes:
--- `applovin_max.SIZE_BANNER`(default)
--- `applovin_max.SIZE_LEADER`
--- `applovin_max.SIZE_MREC`
---@param size number
---@return hash
function M.set_banner_size(size)
    if not size then
        return helper.error("APPLOVIN MAX: Size must be given")
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
