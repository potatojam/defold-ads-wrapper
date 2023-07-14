local helper = require("ads_wrapper.ads_networks.helper")
local platform = require("ads_wrapper.platform")

local M = { NAME = "ironsource" }
-- Extention: https://github.com/defold/extension-ironsource

---@class ironsource_params
---@field user_id string|nil
---@field consent_GDPR boolean|nil
---@field adapters_debug boolean|nil
---@field metadata table<string, any>|nil
---@field app_key table<userdata, string>
---@field rew_placement_name string|nil
---@field int_placement_name string|nil

local CONSENT_PRE = "pre"

---@type ironsource_params
local parameters
---@type ads_callback|nil
local module_callback
local banner_showed = false
local is_ironsource_initialized = false
local is_reward_get = false
local banner_configs
if ironsource then --TODO: add later
    banner_configs = {}
end

---Call saved `module_callback` only once.
---@param response ads_response
local function callback_once(response)
    if module_callback then
        local callback = module_callback
        module_callback = nil
        callback(response)
    end
end

---Call saved `module_callback` only once.
---@param response ads_response
local function callback_once_delay(response)
    timer.delay(0, false, function()
        if module_callback then
            local callback = module_callback
            module_callback = nil
            callback(response)
        end
    end)
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

---Invoke callback with error data
---@param message table
---@param event string
local function callback_error(message, event)
    callback_once(helper.error(string.format("IRONSOURCE: %s: Code: %s Error: %s",
        event, tostring(message.error_code), tostring(message.error_message))
    , nil, message))
end

local function on_init_complete(self, message_id, message)
    if ironsource.MSG_IDFA and (ironsource.get_idfa_status() == ironsource.EVENT_STATUS_NOT_DETERMINED) then
        ironsource.load_consent_view(CONSENT_PRE)
    else
        callback_once(helper.success())
    end
end

local function ironsource_callback(self, message_id, message)
    pprint("ironsource_callback", message_id, message)
    if message_id == ironsource.MSG_INIT then
        is_ironsource_initialized = true
        if message.event == ironsource.EVENT_INIT_COMPLETE then
            on_init_complete(self, message_id, message)
        end
    elseif message_id == ironsource.MSG_REWARDED then
        if message.event == ironsource.EVENT_AD_AVAILABLE then
            ---Loaded--Called after init
            -- callback_once(helper.success(nil, message))
        elseif message.event == ironsource.EVENT_AD_UNAVAILABLE then
            ---Not loaded--Called before close
            -- callback_once(helper.error("IRONSOURCE: EVENT_AD_UNAVAILABLE", nil, message))
        elseif message.event == ironsource.EVENT_AD_OPENED then
            -- The Rewarded Video ad view has opened. Your activity will loose focus
            -- message{AdInfo}
        elseif message.event == ironsource.EVENT_AD_CLOSED then
            if is_reward_get then
                callback_once(helper.success(nil, message))
            else
                callback_once(helper.skipped(nil, message))
            end
            is_reward_get = false
        elseif message.event == ironsource.EVENT_AD_REWARDED then
            is_reward_get = true
        elseif message.event == ironsource.EVENT_AD_SHOW_FAILED then
            callback_error(message, "EVENT_AD_SHOW_FAILED")
        elseif message.event == ironsource.EVENT_AD_CLICKED then
            -- Invoked when the video ad was clicked.
            -- This callback is not supported by all networks, and we recommend using it
            -- only if it's supported by all networks you included in your build
            -- message{AdInfo, Placement}
        end
    elseif message_id == ironsource.MSG_INTERSTITIAL then
        if message.event == ironsource.EVENT_AD_READY then
            ---Loaded
            callback_once_delay(helper.success(nil, message))
        elseif message.event == ironsource.EVENT_AD_LOAD_FAILED then
            ---Not loaded
            callback_error(message, "EVENT_AD_LOAD_FAILED")
        elseif message.event == ironsource.EVENT_AD_OPENED then
            -- Invoked when the Interstitial Ad Unit has opened, and user left the application screen.
            -- This is the impression indication.
            -- message{AdInfo}
        elseif message.event == ironsource.EVENT_AD_CLOSED then
            callback_once(helper.success(nil, message))
        elseif message.event == ironsource.EVENT_AD_SHOW_FAILED then
            callback_error(message, "EVENT_AD_SHOW_FAILED")
        elseif message.event == ironsource.EVENT_AD_CLICKED then
            -- Invoked when end user clicked on the interstitial ad
            -- message{AdInfo}
        elseif message.event == ironsource.EVENT_AD_SHOW_SUCCEEDED then
            -- Invoked before the interstitial ad was opened, and before the InterstitialOnAdOpenedEvent is reported.
            -- This callback is not supported by all networks, and we recommend using it only if
            -- it's supported by all networks you included in your build.
            -- message{AdInfo}
        end
    elseif message_id == ironsource.MSG_CONSENT then
        if message.event == ironsource.EVENT_CONSENT_LOADED then
            ironsource.show_consent_view(CONSENT_PRE)
        elseif message.event == ironsource.EVENT_CONSENT_SHOWN then
            -- Consent view was displayed successfully
            -- message.consent_view_type
        elseif message.event == ironsource.EVENT_CONSENT_LOAD_FAILED then
            -- Consent view was failed to load
            -- message.consent_view_type, message.error_code, message.error_message
            ironsource.request_idfa()
        elseif message.event == ironsource.EVENT_CONSENT_SHOW_FAILED then
            -- Consent view was not displayed, due to error
            -- message.consent_view_type, message.error_code, message.error_message
            ironsource.request_idfa()
        elseif message.event == ironsource.EVENT_CONSENT_ACCEPTED then
            -- The user pressed the Settings or Next buttons
            -- message.consent_view_type
            ironsource.request_idfa()
        elseif message.event == ironsource.EVENT_CONSENT_DISMISSED then
            -- The user dismiss consent
            -- message.consent_view_type
            ironsource.request_idfa()
        end
    elseif message_id == ironsource.MSG_IDFA then
        local message_text = "IDFA event"
        if message.event == ironsource.EVENT_STATUS_AUTHORIZED then
            message_text = "ATTrackingManagerAuthorizationStatusAuthorized"
        elseif message.event == ironsource.EVENT_STATUS_DENIED then
            message_text = "ATTrackingManagerAuthorizationStatusDenied"
        elseif message.event == ironsource.EVENT_STATUS_NOT_DETERMINED then
            message_text = "ATTrackingManagerAuthorizationStatusNotDetermined"
        elseif message.event == ironsource.EVENT_STATUS_RESTRICTED then
            message_text = "ATTrackingManagerAuthorizationStatusRestricted"
        end
        callback_once(helper.success(message_text, message.event))
    end
end

---Api setup
---@param params ironsource_params
function M.setup(params)
    parameters = params
    if parameters.user_id ~= nil then
        ironsource.set_user_id(parameters.user_id)
    end
    if parameters.consent_GDPR ~= nil then
        ironsource.set_consent(parameters.consent_GDPR)
    end
    if parameters.adapters_debug ~= nil then
        ironsource.set_adapters_debug(parameters.adapters_debug)
    end
    if parameters.metadata then
        for key, value in pairs(parameters.metadata) do
            -- pprint(key, value)
            ironsource.set_metadata(key, value)
        end
    end
end

---Initializes `ironsource` sdk.
---@param callback ads_callback|nil the function is called after execution.
function M.init(callback)
    module_callback = callback
    ironsource.set_callback(ironsource_callback)
    ironsource.init(parameters.app_key[platform.get()])
end

---Check if the environment supports ironsource api
---@return bool
function M.is_supported()
    return ironsource ~= nil
end

---Check if the ironsource is initialized
---@return bool
function M.is_initialized()
    return is_ironsource_initialized
end

---Shows rewarded ads.
---@param callback ads_callback|nil the function is called after execution.
function M.show_rewarded(callback)
    module_callback = callback
    ironsource.set_callback(ironsource_callback)
    ironsource.show_rewarded_video(parameters.rew_placement_name)
end

---Loads rewarded ads
---@param callback ads_callback|nil the function is called after execution.
function M.load_rewarded(callback)
    callback_delay(callback, helper.success())
end

---Check if the rewarded ads is loaded
---@return boolean
function M.is_rewarded_loaded()
    return ironsource.is_rewarded_video_available()
end

---Shows interstitial ads.
---@param callback ads_callback|nil the function is called after execution.
function M.show_interstitial(callback)
    module_callback = callback
    ironsource.set_callback(ironsource_callback)
    ironsource.show_interstitial(parameters.rew_placement_name)
end

---Loads interstitial ads
---@param callback ads_callback|nil the function is called after execution.
function M.load_interstitial(callback)
    module_callback = callback
    ironsource.set_callback(ironsource_callback)
    ironsource.load_interstitial()
end

---Check if the interstitial ads is loaded
---@return boolean
function M.is_interstitial_loaded()
    return ironsource.is_interstitial_ready()
end

---Check if the banner is set up
---@return boolean
function M.is_banner_setup()
    return false ---TODO: add banner
end

---Loads banner. Use `ads.T_BANNER` parameter.
---@param callback ads_callback|nil the function is called after execution.
function M.load_banner(callback)
    ---TODO: add banner
    callback_delay(callback, helper.error("IRONSOURCE: Banners not supported"))
end

---Unloads active banner.
---@param callback ads_callback|nil the function is called after execution.
function M.unload_banner(callback)
    ---TODO: add banner
    callback_delay(callback, helper.error("IRONSOURCE: Banners not supported"))
end

---Check if the banner is loaded
---@return boolean
function M.is_banner_loaded()
    return false ---TODO: add banner
end

---Shows loaded banner.
---@param callback ads_callback|nil the function is called after execution.
function M.show_banner(callback)
    ---TODO: add banner
    callback_delay(callback, helper.error("IRONSOURCE: Banners not supported"))
end

---Hides loaded banner.
---@param callback ads_callback|nil the function is called after execution.
function M.hide_banner(callback)
    ---TODO: add banner
    callback_delay(callback, helper.error("IRONSOURCE: Banners not supported"))
end

---Check if the banner is showed
---@return boolean
function M.is_banner_showed()
    return banner_showed
end

return M
