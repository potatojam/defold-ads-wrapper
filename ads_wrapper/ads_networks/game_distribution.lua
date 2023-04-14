local ads               = require("ads_wrapper.ads_wrapper")
local platform          = require("ads_wrapper.platform")
local helper            = require("ads_wrapper.ads_networks.helper")

local M                 = { NAME = "game_distribution" }
-- Extention: https://github.com/GameDistribution/gd-defold

M.SIZE_336x280          = 1
M.SIZE_300x250          = 2
M.SIZE_970x250          = 3
M.SIZE_728x90           = 4
M.SIZE_120x600          = 5
M.SIZE_160x600          = 6

local parameters
---@type ads_callback|nil
local module_callback
local banner_showed     = false
local rewarded_showed   = false
local is_gd_initialized = false
local is_reward_get     = false
local banner_configs    = {
    size = M.SIZE_336x280,
    parent_id = "canvas-container",
    wrapper_style = "position: absolute; bottom: 0px; left: 50%;",
    ad_style = "margin-left: -50%; display: none;",
    banner_id = "canvas-ad"
}

local function get_size_string(size)
    local w = 336
    local h = 280
    if size == M.SIZE_300x250 then
        w = 300
        h = 250
    elseif size == M.SIZE_970x250 then
        w = 970
        h = 250
    elseif size == M.SIZE_728x90 then
        w = 728
        h = 90
    elseif size == M.SIZE_120x600 then
        w = 120
        h = 600
    elseif size == M.SIZE_160x600 then
        w = 160
        h = 600
    end
    return string.format("width: %0dpx; height: %0dpx;", w, h)
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

local function gdsdk_listener(self, message_id, message)
    if message_id == gdsdk.SDK_GAME_PAUSE then
    elseif message_id == gdsdk.SDK_GAME_START then
        if rewarded_showed then
            rewarded_showed = false
            if is_reward_get then
                is_reward_get = false
                callback_once(helper.success())
            else
                callback_once(helper.skipped())
            end
        else
            callback_once(helper.success())
        end
    elseif message_id == gdsdk.SDK_REWARDED_WATCH_COMPLETE then
        is_reward_get = true
    end
end

---Api setup
---@param params table
function M.setup(params)
    parameters = params
    local banner_settings = parameters[ads.T_BANNER]
    if banner_settings then
        if banner_settings.banner_id then
            banner_configs.banner_id = banner_settings.banner_id
        end
        if banner_settings.auto_create then
            if banner_settings.size then
                banner_configs.size = banner_settings.size
            end
            if banner_settings.parent_id then
                banner_configs.parent_id = banner_settings.parent_id
            end
            if banner_settings.wrapper_style then
                banner_configs.wrapper_style = banner_settings.wrapper_style
            end
            if banner_settings.ad_style then
                banner_configs.ad_style = banner_settings.ad_style
            end
            html5.run(
                string.format("var canvasContainer = document.getElementById('%s');", banner_configs.parent_id) ..
                "var div = document.createElement('div');" ..
                "canvasContainer.appendChild(div);" ..
                string.format("div.style = '%s';", banner_configs.wrapper_style) ..
                "var ads_div = document.createElement('div');" ..
                "div.appendChild(ads_div);" ..
                string.format("ads_div.style = '%s %s';", banner_configs.ad_style, get_size_string(banner_settings.size)) ..
                string.format("ads_div.id = '%s';", banner_configs.banner_id)
            )
        end
    end
end

---Initializes `GameDistribution` sdk.
---@param callback ads_callback|nil the function is called after execution.
function M.init(callback)
    module_callback = callback
    callback_once_delay(helper.success())
end

---Check if the environment supports GameDistribution api
---@return bool
function M.is_supported()
    return gdsdk ~= nil
end

---Check if the GameDistribution is initialized
---@return bool
function M.is_initialized()
    return is_gd_initialized
end

---Shows rewarded ads.
---@param callback ads_callback|nil the function is called after execution.
function M.show_rewarded(callback)
    module_callback = callback
    is_reward_get = false
    rewarded_showed = true
    gdsdk.set_listener(gdsdk_listener)
    gdsdk.show_rewarded_ad()
end

---Loads rewarded ads
---@param callback ads_callback|nil the function is called after execution.
function M.load_rewarded(callback)
    module_callback = callback
    callback_once_delay(helper.success())
end

---Check if the rewarded ads is loaded
---@return boolean
function M.is_rewarded_loaded()
    return true
end

---Shows interstitial ads.
---@param callback ads_callback|nil the function is called after execution.
function M.show_interstitial(callback)
    module_callback = callback
    rewarded_showed = false
    gdsdk.set_listener(gdsdk_listener)
    gdsdk.show_interstitial_ad()
end

---Loads interstitial ads
---@param callback ads_callback|nil the function is called after execution.
function M.load_interstitial(callback)
    module_callback = callback
    callback_once_delay(helper.success())
end

---Check if the interstitial ads is loaded
---@return boolean
function M.is_interstitial_loaded()
    return true
end

---Check if the banner is set up
---@return boolean
function M.is_banner_setup()
    return banner_configs.banner_id ~= nil
end

---Loads banner
---@param callback ads_callback|nil the function is called after execution.
function M.load_banner(callback)
    if not M.is_banner_setup() then
        callback_delay(callback, helper.error("GameDistribution: Banner not setup"))
        return
    end
    module_callback = callback
    callback_once_delay(helper.success())
end

---Unloads active banner.
---@param callback ads_callback|nil the function is called after execution.
function M.unload_banner(callback)
    if not M.is_banner_setup() then
        callback_delay(callback, helper.error("GameDistribution: Banner not setup"))
        return
    end
    module_callback = callback
    callback_once_delay(helper.success())
end

---Check if the banner is loaded
---@return boolean
function M.is_banner_loaded()
    return true
end

---Shows loaded banner.
---@param callback ads_callback|nil the function is called after execution.
function M.show_banner(callback)
    if M.is_banner_loaded() then
        gdsdk.show_display_ad(banner_configs.banner_id)
        banner_showed = true
        callback_delay(callback, helper.success())
    else
        callback_delay(callback, helper.error("GameDistribution: Banner not loaded"))
    end
end

---Hides loaded banner.
---@param callback ads_callback|nil the function is called after execution.
function M.hide_banner(callback)
    if M.is_banner_loaded() then
        gdsdk.hide_display_ad(banner_configs.banner_id)
        banner_showed = false
        callback_delay(callback, helper.success())
    else
        callback_delay(callback, helper.error("GameDistribution: Banner not loaded"))
    end
end

---Check if the banner is showed
---@return boolean
function M.is_banner_showed()
    return banner_showed
end

return M
