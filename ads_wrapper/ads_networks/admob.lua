local ads = require("ads_wrapper.ads_wrapper")
local events = require("ads_wrapper.events")
local helper = require("ads_wrapper.ads_networks.helper")
local platform = require("ads_wrapper.platform")

local M = { NAME = "admob" }
-- Extention: https://github.com/defold/extension-admob

local TEST_IDS = {
    [platform.PL_ANDROID] = {
        rewarded = "ca-app-pub-3940256099942544/5224354917",
        interstitial = "ca-app-pub-3940256099942544/1033173712",
        banner = "ca-app-pub-3940256099942544/9214589741",
    },
    [platform.PL_IOS] = {
        rewarded = "ca-app-pub-3940256099942544/1712485313",
        interstitial = "ca-app-pub-3940256099942544/4411468910",
        banner = "ca-app-pub-3940256099942544/2435281174",
    },
}

local parameters = {}
local pending = {}
local idfa_response
local listener

local state = {
    initialized = false,
    rewarded_loaded = false,
    rewarded_showing = false,
    interstitial_loaded = false,
    interstitial_showing = false,
    banner_loaded = false,
    banner_showed = false,
    reward_earned = false,
    reward_data = nil,
}

local banner_config = {
    size = nil,
    position = nil,
}

local function copy_table(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local result = {}
    seen[value] = result
    for key, item in pairs(value) do
        result[copy_table(key, seen)] = copy_table(item, seen)
    end
    return result
end

local function current_platform()
    if platform.is_same(platform.PL_ANDROID) then
        return platform.PL_ANDROID
    elseif platform.is_same(platform.PL_IOS) then
        return platform.PL_IOS
    end
    return nil
end

local function response_data(params, extra)
    local data = extra or {}
    data.networkName = M.NAME
    if params then
        data.place = params.place
        data.size = params.size
    end
    return data
end

local function success(message, params, extra)
    return helper.success(message, response_data(params, extra))
end

local function skipped(message, params, extra)
    return helper.skipped(message, response_data(params, extra))
end

local function sdk_error(message, sdk_message, params)
    local code = events.C_ERROR_UNKNOWN
    if sdk_message and tonumber(sdk_message.code) == 2 then
        code = events.C_ERROR_NO_CONNECTION
    end
    return helper.error(message, code, response_data(params, {
        sdkCode = sdk_message and sdk_message.code or nil,
        sdkError = sdk_message and sdk_message.error or nil,
    }))
end

local function async_callback(callback, response)
    if callback then
        timer.delay(0, false, function()
            callback(response)
        end)
    end
end

local function complete(name, response)
    local operation = pending[name]
    if not operation then
        return false
    end
    pending[name] = nil
    local callbacks = operation.callbacks
    operation.callbacks = {}
    for _, callback in ipairs(callbacks) do
        async_callback(callback, response)
    end
    return true
end

local function reset_operation_state(name)
    if name == "init" then
        state.initialized = false
    elseif name == "rewarded_load" then
        state.rewarded_loaded = false
    elseif name == "rewarded_show" then
        state.rewarded_showing = false
        state.reward_earned = false
        state.reward_data = nil
    elseif name == "interstitial_load" then
        state.interstitial_loaded = false
    elseif name == "interstitial_show" then
        state.interstitial_showing = false
    elseif name == "banner_load" then
        state.banner_loaded = false
    elseif name == "banner_unload" then
        state.banner_showed = false
    end
end

local function begin_operation(name, callback, params, coalesce)
    local operation = pending[name]
    if operation then
        if coalesce then
            if callback then
                operation.callbacks[#operation.callbacks + 1] = callback
            end
        else
            async_callback(callback, sdk_error("ADMOB: " .. name .. " is already pending", nil, params))
        end
        return nil
    end

    operation = {
        callbacks = {},
        params = params,
    }
    if callback then
        operation.callbacks[1] = callback
    end
    pending[name] = operation
    return operation
end

local function ensure_sdk_callback()
    local ok, err = pcall(admob.set_callback, function(self, message_id, message)
        M._on_event(self, message_id, message)
    end)
    return ok, err
end

local function call_sdk(operation_name, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        local operation = pending[operation_name]
        reset_operation_state(operation_name)
        complete(operation_name, sdk_error("ADMOB: " .. operation_name .. " failed: " .. tostring(err), nil,
            operation and operation.params or nil))
    end
    return ok
end

local function notify(format, event_name, message, params)
    if listener then
        local ok, err = pcall(listener, format, event_name, message, response_data(params))
        if not ok then
            print("ADMOB: listener failed: " .. tostring(err))
        end
    end
end

local function operation_params(primary, secondary)
    local operation = pending[primary] or (secondary and pending[secondary])
    return operation and operation.params or nil
end

local function unit_config(ad_type)
    local config = parameters[ad_type]
    if type(config) == "string" then
        return config, nil
    elseif type(config) == "table" then
        if type(config.id) == "string" then
            return config.id, config
        end
        local platform_name = current_platform()
        local platform_config = platform_name and config[platform_name] or nil
        if type(platform_config) == "string" then
            return platform_config, config
        elseif type(platform_config) == "table" then
            return platform_config.id, platform_config
        end
    end
    return nil, type(config) == "table" and config or nil
end

local function valid_unit_id(ad_type)
    local id = unit_config(ad_type)
    return type(id) == "string" and id ~= ""
end

local function native_loaded(function_name)
    if not M.is_supported() or type(admob[function_name]) ~= "function" then
        return false
    end
    local ok, loaded = pcall(admob[function_name])
    return ok and loaded == true
end

local function apply_debug_ids()
    if not ads.is_debug then
        return
    end
    local ids = TEST_IDS[current_platform()]
    if not ids then
        return
    end
    parameters[ads.T_REWARDED] = ids.rewarded
    parameters[ads.T_INTERSTITIAL] = ids.interstitial
    local existing_banner = parameters[ads.T_BANNER]
    if type(existing_banner) ~= "table" then
        existing_banner = {}
    end
    existing_banner.id = ids.banner
    parameters[ads.T_BANNER] = existing_banner
end

local function configure_banner()
    local _, config = unit_config(ads.T_BANNER)
    banner_config.size = admob and admob.SIZE_ADAPTIVE_BANNER or nil
    banner_config.position = admob and admob.POS_TOP_CENTER or nil
    if config then
        if config.size ~= nil then
            banner_config.size = config.size
        end
        if config.position ~= nil then
            banner_config.position = config.position
        end
    end
end

local function idfa_status_message(event)
    if event == admob.EVENT_STATUS_AUTHORIZED then
        return "authorized"
    elseif event == admob.EVENT_STATUS_DENIED then
        return "denied"
    elseif event == admob.EVENT_STATUS_NOT_DETERMINED then
        return "not_determined"
    elseif event == admob.EVENT_STATUS_RESTRICTED then
        return "restricted"
    elseif event == admob.EVENT_NOT_SUPPORTED then
        return "not_supported"
    end
    return "unknown"
end

local function handle_initialization(message)
    if not pending.init then
        return
    end
    if message.event == admob.EVENT_COMPLETE then
        state.initialized = true
        complete("init", success("ADMOB: initialization complete", operation_params("init")))
    elseif message.event == admob.EVENT_JSON_ERROR then
        state.initialized = false
        complete("init", sdk_error("ADMOB: initialization failed", message, operation_params("init")))
    end
end

local function handle_idfa(message)
    if not pending.idfa then
        return
    end
    if message.event == admob.EVENT_JSON_ERROR then
        idfa_response = sdk_error("ADMOB: IDFA request failed", message, operation_params("idfa"))
    else
        local status = idfa_status_message(message.event)
        idfa_response = success("ADMOB: IDFA status " .. status, operation_params("idfa"), {
            idfaStatus = status,
            idfaEvent = message.event,
        })
    end
    complete("idfa", idfa_response)
end

local function handle_interstitial(message)
    local event = message.event
    local params = operation_params("interstitial_show", "interstitial_load")
    if event == admob.EVENT_LOADED then
        if pending.interstitial_load then
            state.interstitial_loaded = true
            complete("interstitial_load", success("ADMOB: interstitial loaded", params))
        end
    elseif event == admob.EVENT_FAILED_TO_LOAD then
        if pending.interstitial_load then
            state.interstitial_loaded = false
            complete("interstitial_load", sdk_error("ADMOB: interstitial failed to load", message, params))
        end
    elseif event == admob.EVENT_CLOSED then
        if pending.interstitial_show then
            state.interstitial_showing = false
            state.interstitial_loaded = false
            complete("interstitial_show", success("ADMOB: interstitial closed", params))
        end
    elseif event == admob.EVENT_FAILED_TO_SHOW or event == admob.EVENT_NOT_LOADED then
        if pending.interstitial_show then
            state.interstitial_showing = false
            state.interstitial_loaded = false
            complete("interstitial_show", sdk_error("ADMOB: interstitial failed to show", message, params))
        end
    elseif event == admob.EVENT_JSON_ERROR then
        local name = pending.interstitial_show and "interstitial_show" or
            (pending.interstitial_load and "interstitial_load" or nil)
        if name then
            state.interstitial_showing = false
            state.interstitial_loaded = false
            complete(name, sdk_error("ADMOB: interstitial JSON error", message, params))
        end
    elseif event == admob.EVENT_OPENING then
        notify("interstitial", "opened", message, params)
    elseif event == admob.EVENT_IMPRESSION_RECORDED then
        notify("interstitial", "impression", message, params)
    elseif event == admob.EVENT_CLICKED then
        notify("interstitial", "clicked", message, params)
    end
end

local function handle_rewarded(message)
    local event = message.event
    local params = operation_params("rewarded_show", "rewarded_load")
    if event == admob.EVENT_LOADED then
        if pending.rewarded_load then
            state.rewarded_loaded = true
            complete("rewarded_load", success("ADMOB: rewarded loaded", params))
        end
    elseif event == admob.EVENT_FAILED_TO_LOAD then
        if pending.rewarded_load then
            state.rewarded_loaded = false
            complete("rewarded_load", sdk_error("ADMOB: rewarded failed to load", message, params))
        end
    elseif event == admob.EVENT_EARNED_REWARD then
        if pending.rewarded_show then
            state.reward_earned = true
            state.reward_data = {
                amount = message.amount,
                rewardType = message.type,
            }
            notify("rewarded", "rewarded", message, params)
        end
    elseif event == admob.EVENT_CLOSED then
        if pending.rewarded_show then
            state.rewarded_showing = false
            state.rewarded_loaded = false
            local response
            if state.reward_earned then
                response = success("ADMOB: rewarded closed after reward", params, state.reward_data)
            else
                response = skipped("ADMOB: rewarded closed without reward", params)
            end
            state.reward_earned = false
            state.reward_data = nil
            complete("rewarded_show", response)
        end
    elseif event == admob.EVENT_FAILED_TO_SHOW or event == admob.EVENT_NOT_LOADED then
        if pending.rewarded_show then
            state.rewarded_showing = false
            state.rewarded_loaded = false
            state.reward_earned = false
            state.reward_data = nil
            complete("rewarded_show", sdk_error("ADMOB: rewarded failed to show", message, params))
        end
    elseif event == admob.EVENT_JSON_ERROR then
        local name = pending.rewarded_show and "rewarded_show" or (pending.rewarded_load and "rewarded_load" or nil)
        if name then
            state.rewarded_showing = false
            state.rewarded_loaded = false
            state.reward_earned = false
            state.reward_data = nil
            complete(name, sdk_error("ADMOB: rewarded JSON error", message, params))
        end
    elseif event == admob.EVENT_OPENING then
        notify("rewarded", "opened", message, params)
    elseif event == admob.EVENT_IMPRESSION_RECORDED then
        notify("rewarded", "impression", message, params)
    elseif event == admob.EVENT_CLICKED then
        notify("rewarded", "clicked", message, params)
    end
end

local function handle_banner(message)
    local event = message.event
    local params = operation_params("banner_unload", "banner_load")
    if event == admob.EVENT_LOADED then
        if pending.banner_load then
            state.banner_loaded = true
            complete("banner_load", success("ADMOB: banner loaded", params, {
                width = message.width,
                height = message.height,
            }))
        end
    elseif event == admob.EVENT_FAILED_TO_LOAD then
        if pending.banner_load then
            state.banner_loaded = false
            state.banner_showed = false
            complete("banner_load", sdk_error("ADMOB: banner failed to load", message, params))
        end
    elseif event == admob.EVENT_DESTROYED then
        if pending.banner_unload then
            state.banner_loaded = false
            state.banner_showed = false
            complete("banner_unload", success("ADMOB: banner destroyed", params))
        end
    elseif event == admob.EVENT_JSON_ERROR then
        local name = pending.banner_unload and "banner_unload" or (pending.banner_load and "banner_load" or nil)
        if name then
            state.banner_showed = false
            if name == "banner_load" then
                state.banner_loaded = false
            end
            complete(name, sdk_error("ADMOB: banner JSON error", message, params))
        end
    elseif event == admob.EVENT_CLOSED then
        state.banner_showed = false
        notify("banner", "closed", message, params)
    elseif event == admob.EVENT_OPENING then
        notify("banner", "opened", message, params)
    elseif event == admob.EVENT_IMPRESSION_RECORDED then
        notify("banner", "impression", message, params)
    elseif event == admob.EVENT_CLICKED then
        notify("banner", "clicked", message, params)
    end
end

function M._on_event(self, message_id, message)
    if not M.is_supported() then
        return
    end
    message = message or {}
    if message_id == admob.MSG_INITIALIZATION then
        handle_initialization(message)
    elseif message_id == admob.MSG_IDFA then
        handle_idfa(message)
    elseif message_id == admob.MSG_INTERSTITIAL then
        handle_interstitial(message)
    elseif message_id == admob.MSG_REWARDED then
        handle_rewarded(message)
    elseif message_id == admob.MSG_BANNER then
        handle_banner(message)
    end
end

function M.setup(params)
    local stale = {}
    for name, operation in pairs(pending) do
        if name ~= "idfa" then
            stale[#stale + 1] = { name = name, params = operation.params }
        end
    end
    for _, operation in ipairs(stale) do
        complete(operation.name, sdk_error("ADMOB: operation cancelled by setup", nil, operation.params))
    end
    parameters = copy_table(params or {})
    listener = parameters.listener
    state.rewarded_loaded = false
    state.rewarded_showing = false
    state.interstitial_loaded = false
    state.interstitial_showing = false
    state.banner_loaded = false
    state.banner_showed = false
    state.reward_earned = false
    state.reward_data = nil
    apply_debug_ids()
    configure_banner()
end

function M.is_supported()
    local ok, supported = pcall(function()
        local mobile = platform.is_same(platform.PL_ANDROID) or platform.is_same(platform.PL_IOS)
        return mobile and admob ~= nil and type(admob.set_callback) == "function" and
            type(admob.initialize) == "function"
    end)
    return ok and supported == true
end

function M.init(callback, params)
    if not M.is_supported() then
        async_callback(callback, sdk_error("ADMOB: SDK is not supported", nil, params))
        return
    end
    if state.initialized then
        async_callback(callback, success("ADMOB: already initialized", params))
        return
    end
    local operation = begin_operation("init", callback, params, true)
    if not operation then
        return
    end
    local ok, err = ensure_sdk_callback()
    if not ok then
        complete("init", sdk_error("ADMOB: unable to set callback: " .. tostring(err), nil, params))
        return
    end
    if type(parameters.privacy_settings) == "boolean" and type(admob.set_privacy_settings) == "function" then
        if not call_sdk("init", admob.set_privacy_settings, parameters.privacy_settings) then
            return
        end
    end
    call_sdk("init", admob.initialize)
end

function M.is_initialized()
    return state.initialized == true
end

function M.request_idfa(callback, params)
    if idfa_response then
        async_callback(callback, idfa_response)
        return
    end
    if not M.is_supported() then
        async_callback(callback, sdk_error("ADMOB: IDFA is not supported", nil, params))
        return
    end
    if not platform.is_same(platform.PL_IOS) then
        idfa_response = success("ADMOB: IDFA is not required on this platform", params, { idfaStatus = "not_supported" })
        async_callback(callback, idfa_response)
        return
    end
    local operation = begin_operation("idfa", callback, params, true)
    if not operation then
        return
    end
    local ok, err = ensure_sdk_callback()
    if not ok then
        complete("idfa", sdk_error("ADMOB: unable to set IDFA callback: " .. tostring(err), nil, params))
        return
    end
    call_sdk("idfa", admob.request_idfa)
end

function M.load_rewarded(callback, params)
    if not M.is_initialized() then
        async_callback(callback, sdk_error("ADMOB: rewarded load requested before initialization", nil, params))
        return
    end
    if M.is_rewarded_loaded(params) then
        async_callback(callback, success("ADMOB: rewarded already loaded", params))
        return
    end
    local id, config = unit_config(ads.T_REWARDED)
    if not valid_unit_id(ads.T_REWARDED) then
        async_callback(callback, sdk_error("ADMOB: rewarded unit ID is missing", nil, params))
        return
    end
    local operation = begin_operation("rewarded_load", callback, params, true)
    if not operation then
        return
    end
    state.rewarded_loaded = false
    local options = params and params.options or (config and config.options)
    if options then
        call_sdk("rewarded_load", admob.load_rewarded, id, options)
    else
        call_sdk("rewarded_load", admob.load_rewarded, id)
    end
end

function M.is_rewarded_loaded(params)
    if state.rewarded_showing then
        return false
    end
    state.rewarded_loaded = native_loaded("is_rewarded_loaded")
    return state.rewarded_loaded
end

function M.show_rewarded(callback, params)
    if not M.is_rewarded_loaded(params) then
        async_callback(callback, sdk_error("ADMOB: rewarded ad is not loaded", nil, params))
        return
    end
    local operation = begin_operation("rewarded_show", callback, params, false)
    if not operation then
        return
    end
    state.rewarded_loaded = false
    state.rewarded_showing = true
    state.reward_earned = false
    state.reward_data = nil
    call_sdk("rewarded_show", admob.show_rewarded)
end

function M.load_interstitial(callback, params)
    if not M.is_initialized() then
        async_callback(callback, sdk_error("ADMOB: interstitial load requested before initialization", nil, params))
        return
    end
    if M.is_interstitial_loaded(params) then
        async_callback(callback, success("ADMOB: interstitial already loaded", params))
        return
    end
    local id = unit_config(ads.T_INTERSTITIAL)
    if not valid_unit_id(ads.T_INTERSTITIAL) then
        async_callback(callback, sdk_error("ADMOB: interstitial unit ID is missing", nil, params))
        return
    end
    local operation = begin_operation("interstitial_load", callback, params, true)
    if not operation then
        return
    end
    state.interstitial_loaded = false
    call_sdk("interstitial_load", admob.load_interstitial, id)
end

function M.is_interstitial_loaded(params)
    if state.interstitial_showing then
        return false
    end
    state.interstitial_loaded = native_loaded("is_interstitial_loaded")
    return state.interstitial_loaded
end

function M.show_interstitial(callback, params)
    if not M.is_interstitial_loaded(params) then
        async_callback(callback, sdk_error("ADMOB: interstitial ad is not loaded", nil, params))
        return
    end
    local operation = begin_operation("interstitial_show", callback, params, false)
    if not operation then
        return
    end
    state.interstitial_loaded = false
    state.interstitial_showing = true
    call_sdk("interstitial_show", admob.show_interstitial)
end

function M.is_banner_setup()
    return valid_unit_id(ads.T_BANNER)
end

function M.load_banner(callback, params)
    if not M.is_initialized() then
        async_callback(callback, sdk_error("ADMOB: banner load requested before initialization", nil, params))
        return
    end
    if not M.is_banner_setup() then
        async_callback(callback, sdk_error("ADMOB: banner unit ID is missing", nil, params))
        return
    end
    if M.is_banner_loaded(params) then
        async_callback(callback, success("ADMOB: banner already loaded", params))
        return
    end
    local operation = begin_operation("banner_load", callback, params, true)
    if not operation then
        return
    end
    local id = unit_config(ads.T_BANNER)
    state.banner_loaded = false
    call_sdk("banner_load", admob.load_banner, id, banner_config.size)
end

function M.unload_banner(callback, params)
    if not M.is_banner_loaded(params) then
        state.banner_showed = false
        async_callback(callback, success("ADMOB: banner already unloaded", params))
        return
    end
    local operation = begin_operation("banner_unload", callback, params, true)
    if not operation then
        return
    end
    state.banner_showed = false
    call_sdk("banner_unload", admob.destroy_banner)
end

function M.is_banner_loaded(params)
    state.banner_loaded = native_loaded("is_banner_loaded")
    if not state.banner_loaded then
        state.banner_showed = false
    end
    return state.banner_loaded
end

function M.show_banner(callback, params)
    if not M.is_banner_loaded(params) then
        async_callback(callback, sdk_error("ADMOB: banner is not loaded", nil, params))
        return
    end
    local ok, err = pcall(admob.show_banner, banner_config.position)
    if ok then
        state.banner_showed = true
        async_callback(callback, success("ADMOB: banner shown", params))
    else
        state.banner_showed = false
        async_callback(callback, sdk_error("ADMOB: banner show failed: " .. tostring(err), nil, params))
    end
end

function M.hide_banner(callback, params)
    if not M.is_banner_loaded(params) then
        state.banner_showed = false
        async_callback(callback, success("ADMOB: banner already hidden and unloaded", params))
        return
    end
    local ok, err = pcall(admob.hide_banner)
    if ok then
        state.banner_showed = false
        async_callback(callback, success("ADMOB: banner hidden", params))
    else
        async_callback(callback, sdk_error("ADMOB: banner hide failed: " .. tostring(err), nil, params))
    end
end

function M.is_banner_showed(params)
    return state.banner_showed == true and M.is_banner_loaded(params)
end

function M.set_banner_position(position)
    if position == nil then
        return sdk_error("ADMOB: banner position is required")
    end
    banner_config.position = position
    return success("ADMOB: banner position updated")
end

function M.set_banner_size(size)
    if size == nil then
        return sdk_error("ADMOB: banner size is required")
    end
    banner_config.size = size
    return success("ADMOB: banner size updated")
end

local function cancel_operation(name, reason)
    local operation = pending[name]
    if operation then
        reset_operation_state(name)
        complete(name, sdk_error(reason or ("ADMOB: " .. name .. " cancelled"), nil, operation.params))
    end
end

function M.cancel_rewarded(operation, reason)
    cancel_operation(operation == "load" and "rewarded_load" or "rewarded_show", reason)
end

function M.cancel_interstitial(operation, reason)
    cancel_operation(operation == "load" and "interstitial_load" or "interstitial_show", reason)
end

function M.cancel_banner(operation, reason)
    cancel_operation(operation == "load" and "banner_load" or "banner_unload", reason)
end

return M
