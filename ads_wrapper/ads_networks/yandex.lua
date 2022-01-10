local M = {NAME = "yandex"}
--- TODO: check working
local ads = require("ads_wrapper.ads_wrapper")
local helper = require("ads_wrapper.ads_networks.helper")
local events = require("ads_wrapper.events")

local parameters
local module_callback

local yagames
local sitelock
local is_yandex_initialized = false
local is_player_initialized = false
local is_storage_active = false
local is_reward_get = false
local is_load_started = false
local banner_loaded = false
local banner_initialized = false
local banner_id = nil
local banner_showed = false
local banner_settings = nil
local banner_configs = {size = {width = "100vw", height = "56vh"}, position = {x = "0px", y = "0px"}}

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

---Call saved `module_callback` in the second frame. Send result.
---It is necessary to use timer for the coroutine to continue.
---@param result hash
local function callback_once_delay(result)
    if module_callback then
        timer.delay(0, false, function()
            callback_once(result)
        end)
    end
end

-- Called when api ready to use.
local function init_complete()
    is_yandex_initialized = true
    callback_once(helper.success())
end

-- Called when player is initialized.
---@param self userdata script data
---@param err string|nil error message. `nil` if everything is ok.
local function get_player_init_handler(self, err)
    if err then
        is_player_initialized = false
        callback_once(helper.error("YANDEX: Player not authorized. " .. err))
    else
        print("YANDEX: player is authorized.")
        is_player_initialized = true
        callback_once(helper.success())
    end
end

-- Called when player is initialized.
---@param self userdata script data
---@param err string|nil error message. `nil` if everything is ok.
local function player_init_handler(self, err)
    if err then
        print("YANDEX: Player not authorized.", err)
        is_player_initialized = false
    else
        print("YANDEX: player is authorized.")
        is_player_initialized = true
    end
    init_complete()
end

-- Called when storage is initialized.
---@param self userdata script data
---@param err string|nil error message. `nil` if everything is ok.
local function storage_init_handler(self, err)
    if err then
        print("YANDEX: Storage not received.", err)
        is_storage_active = false
    else
        print("YANDEX: Safe storage is received.")
        is_storage_active = true
    end
    yagames.player_init({scopes = false}, player_init_handler)
end

-- Called when an api is initialized.
---@param self userdata script data
---@param err string|nil error message. `nil` if everything is ok.
local function yandex_init_handler(self, err)
    if err then
        callback_once(helper.error("YANDEX: init error: " .. err))
        is_yandex_initialized = false
    else
        yagames.storage_init(storage_init_handler)
    end
end

-- Called when a interstitial is opened.
---@param self userdata script data
local function adv_open(self)
    print("YANDEX: Interstitial AD is opening")
end

-- Called when a interstitial is closed.
---@param self userdata script data
---@param was_shown boolean Has an ad been shown?
local function adv_close(self, was_shown)
    callback_once(helper.success())
end

-- Called when internet is offline.
---@param self userdata script data
local function adv_offline(self)
    callback_once(helper.error("YANDEX: No internet connection.", events.C_ERROR_NO_CONNECTION))
end

-- Called when an error occurs.
---@param self userdata script data
---@param err string|nil error message. `nil` if everything is ok.
local function adv_error(self, err)
    callback_once(helper.error("YANDEX: ads error: " .. err))
end

-- Called when a rewarded video is opened.
---@param self userdata script data
local function rewarded_open(self)
    print("YANDEX: Interstitial AD is opening")
end

-- Called when a user receives a reward.
---@param self userdata script data
local function rewarded_rewarded(self)
    is_reward_get = true
end

-- Called when a rewarded video is closed.
---@param self userdata script data
local function rewarded_close(self)
    if is_reward_get then
        is_reward_get = false
        callback_once(helper.success())
    else
        callback_once(helper.skipped())
    end
end

---Called when banner is created.
---@param self userdata script data
---@param err string|nil error message. `nil` if everything is ok.
---@param data any The function obtains the data.product parameter with one of two values: direct - Yandex.Direct ads were shown in an RTB ad block, rtb - A media ad was shown in an RTB ad block.
local function banner_create_handler(self, err, data)
    is_load_started = false
    if not err then
        banner_loaded = true
        yagames.is_banners_on = true
        callback_once_delay(helper.success())
    else
        callback_once_delay(helper.error("YANDEX: banner create error: " .. err))
    end
end

---Creates css. Use `banner_configs`.
---@return string
local function create_css_style()
    return
        "width: " .. banner_configs.size.width .. ";height: " .. banner_configs.size.height .. ";top: " .. banner_configs.position.y .. ";left: " ..
            banner_configs.position.x .. ";" .. (banner_settings.css_styles or "align-items: center;justify-content: center;overflow: hidden;")
end

---Creates a banner according to the specified parameters
local function create_banner()
    yagames.banner_create(banner_id, {
        stat_id = banner_settings.stat_id,
        css_styles = create_css_style(),
        css_class = banner_settings.css_class,
        display = "none"
    }, banner_create_handler)
end

---Updates css style for loaded banner
local function update_css()
    if M.is_banner_loaded() then
        yagames.banner_set(banner_id, "css_styles", create_css_style())
    end
end

---Called when banner is initialized.
---@param self userdata script data
---@param err string|nil error message. `nil` if everything is ok.
local function banner_init_handler(self, err)
    if not err then
        banner_initialized = true
        create_banner()
    else
        is_load_started = false
        callback_once(helper.error("YANDEX: banner init error: " .. err))
    end
end

---Sets yandex extention
---@param ex_yagames any
---@param ex_sitelock any
function M.set_yandex_extention(ex_yagames, ex_sitelock)
    yagames = ex_yagames
    sitelock = ex_sitelock
end

---Asks the `player` sdk to save data
---@param callback function the function is called after execution.
function M.get_player(callback)
    if not is_player_initialized then
        module_callback = callback
        yagames.player_init({scopes = false}, get_player_init_handler)
    else
        callback_delay(callback, helper.success())
    end
end

-- Api setup
---@param params table
function M.setup(params)
    parameters = params
    banner_id = parameters[ads.T_BANNER].id
    banner_settings = parameters[ads.T_BANNER]
    if banner_settings then
        M.set_banner_size(banner_settings.size)
        M.set_banner_position(banner_settings.position)
    end
end

-- Initializes `yandex` sdk.
---@param callback function the function is called after execution.
function M.init(callback)
    module_callback = callback
    yagames.init(yandex_init_handler)
end

---Check if the environment supports yandex api
---@return bool
function M.is_supported()
    return html5 and yagames and sitelock.verify_domain()
end

---Returns Yandex.Games interface language in ISO 639-1 format.
---@return string
function M.get_lang()
    if not M.is_initialized() then
        return nil
    end
    local environment = yagames.environment()
    if environment and environment.i18n then
        return environment.i18n.lang
    end
    return nil
end

---Check if the yandex is initialized
---@return bool
function M.is_initialized()
    return is_yandex_initialized
end

-- Shows rewarded popup.
---@param callback function the function is called after execution.
function M.show_rewarded(callback)
    is_reward_get = false
    module_callback = callback
    yagames.adv_show_rewarded_video({open = rewarded_open, rewarded = rewarded_rewarded, close = rewarded_close, error = adv_error})
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
    yagames.adv_show_fullscreen_adv({open = adv_open, close = adv_close, offline = adv_offline, error = adv_error})
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

---Check if the yandex supports safe storage
---@return bool
function M.is_storage_supported()
    return is_storage_active
end

---Check if the yandex player is authorized
---@return bool
function M.is_player_authorized()
    return is_player_initialized
end

---Check if the banner is set up
---@return boolean
function M.is_banner_setup()
    return banner_settings and banner_id
end

---Loads banner. Use `ads.T_BANNER` parameter.
---@param callback function the function is called after execution.
function M.load_banner(callback)
    if is_load_started or not M.is_banner_setup() then
        callback_delay(callback, helper.error("YANDEX: Banner not setup"))
        return
    end
    is_load_started = true
    module_callback = callback
    if not banner_initialized then
        yagames.banner_init(banner_init_handler)
    else
        create_banner()
    end
end

---Unloads active banner.
---@param callback function the function is called after execution.
function M.unload_banner(callback)
    if M.is_banner_loaded() then
        banner_loaded = false
        banner_showed = false
        yagames.banner_destroy(banner_id)
        callback_delay(callback, helper.success())
    else
        callback_delay(callback, helper.error("YANDEX: Banner not loaded"))
    end
end

---Check if the banner is loaded
---@return boolean
function M.is_banner_loaded()
    return banner_loaded
end

---Shows loaded banner.
---@return hash
function M.show_banner()
    if M.is_banner_loaded() then
        banner_showed = true
        yagames.banner_set(banner_id, "display", "flex")
        return helper.success()
    end
    return helper.error("YANDEX: Banner not loaded")
end

---Hides loaded banner.
---@return hash
function M.hide_banner()
    if M.is_banner_loaded() then
        banner_showed = false
        yagames.banner_set(banner_id, "display", "none")
        return helper.success()
    end
    return helper.error("YANDEX: Banner not loaded")
end

---Sets banner position.
---@param position table table `{x = string, y = string}`
---@return hash
function M.set_banner_position(position)
    if not position then
        return helper.error("YANDEX: Position must be given")
    end
    if position.x then
        banner_configs.position.x = position.x
    end
    if position.y then
        banner_configs.position.y = position.y
    end
    update_css()
    return helper.success()
end

---Sets banner size.
---@param size table table `{width = string, height = string}`
---@return userdata
function M.set_banner_size(size)
    if not size then
        return helper.error("YANDEX: Size must be given")
    end
    if size.width then
        banner_configs.size.width = size.width
    end
    if size.height then
        banner_configs.size.height = size.height
    end
    update_css()
    return helper.success()
end

---Check if the banner is showed
---@return boolean
function M.is_banner_showed()
    return banner_showed
end

return M
