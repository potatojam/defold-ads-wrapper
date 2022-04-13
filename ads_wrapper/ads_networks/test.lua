local M = {}

local helper = require("ads_wrapper.ads_networks.helper")

M.is_debug = sys.get_engine_info().is_debug

local function dprint(name, func)
    if M.is_debug then
        print(tostring(name) .. ": " .. tostring(func))
    end
end

M.network1 = {
    _is_initialized = false,
    _is_reward_loaded = false,
    _is_banner_loaded = false,
    _is_banner_showed = false,
    parameters = nil,
    NAME = "Test Network 1",

    init = function(callback)
        dprint(M.network1.NAME, "ads.init()")
        timer.delay(0, false, function()
            M.network1._is_initialized = true
            callback(helper.success())
        end)
    end,

    setup = function(params)
        dprint(M.network1.NAME, "ads.setup()")
        M.network1.parameters = params
    end,

    is_supported = function()
        dprint(M.network1.NAME, "ads.is_supported()")
        return true
    end,

    is_initialized = function()
        dprint(M.network1.NAME, "ads.is_initialized()")
        return M.network1._is_initialized
    end,

    show_rewarded = function(callback)
        dprint(M.network1.NAME, "ads.show_rewarded()")
        timer.delay(0, false, function()
            M.network1._is_reward_loaded = false
            callback(helper.success())
        end)
    end,

    load_rewarded = function(callback)
        dprint(M.network1.NAME, "ads.load_rewarded()")
        timer.delay(0, false, function()
            M.network1._is_reward_loaded = true
            callback(helper.success())
        end)
    end,

    is_rewarded_loaded = function()
        dprint(M.network1.NAME, "ads.is_rewarded_loaded()")
        return M.network1._is_reward_loaded
    end,

    request_idfa = function(callback)
        dprint(M.network1.NAME, "ads.request_idfa()")
        timer.delay(0, false, function()
            callback(helper.success())
        end)
    end,

    is_interstitial_loaded = function()
        dprint(M.network1.NAME, "ads.is_interstitial_loaded()")
        return false
    end,

    load_interstitial = function(callback)
        dprint(M.network1.NAME, "ads.load_interstitial()")
        timer.delay(0, false, function()
            callback(helper.success())
        end)
    end,

    show_interstitial = function(callback)
        dprint(M.network1.NAME, "ads.show_interstitial()")
        timer.delay(0, false, function()
            callback(helper.success())
        end)
    end,

    is_banner_setup = function()
        dprint(M.network1.NAME, "ads.is_banner_setup()")
        return true
    end,

    load_banner = function(callback)
        dprint(M.network1.NAME, "ads.load_banner()")
        M.network1._is_banner_loaded = true
        timer.delay(0, false, function()
            callback(helper.success())
        end)
    end,

    unload_banner = function(callback)
        dprint(M.network1.NAME, "ads.unload_banner()")
        M.network1._is_banner_loaded = false
        M.network1._is_banner_showed = false
        timer.delay(0, false, function()
            callback(helper.success())
        end)
    end,

    is_banner_loaded = function()
        dprint(M.network1.NAME, "ads.is_banner_loaded()")
        return M.network1._is_banner_loaded
    end,

    show_banner = function()
        dprint(M.network1.NAME, "ads.show_banner()")
        M.network1._is_banner_showed = true
        return helper.success()
    end,

    hide_banner = function()
        dprint(M.network1.NAME, "ads.hide_banner()")
        M.network1._is_banner_showed = false
        return helper.success()
    end,

    set_banner_position = function(position)
        dprint(M.network1.NAME, "ads.set_banner_position()")
        return helper.success()
    end,

    set_banner_size = function(size)
        dprint(M.network1.NAME, "ads.set_banner_size()")
        return helper.success()
    end,

    is_banner_showed = function()
        dprint(M.network1.NAME, "ads.is_banner_showed()")
        return M.network1._is_banner_showed
    end
}

M.network2 = {
    _is_initialized = false,
    __is_reward_loaded = false,
    _is_banner_loaded = false,
    _is_banner_showed = false,
    parameters = nil,
    NAME = "Test Network 2",

    init = function(callback)
        dprint(M.network2.NAME, "ads.init()")
        timer.delay(0, false, function()
            M.network2._is_initialized = true
            callback(helper.success())
        end)
    end,

    is_supported = function()
        dprint(M.network2.NAME, "ads.is_supported()")
        return true
    end,

    setup = function(params)
        dprint(M.network2.NAME, "ads.setup()")
        M.network2.parameters = params
    end,

    is_initialized = function()
        dprint(M.network2.NAME, "ads.is_initialized()")
        return M.network2._is_initialized
    end,

    show_rewarded = function(callback)
        dprint(M.network2.NAME, "ads.show_rewarded()")
        timer.delay(0, false, function()
            M.network2._is_reward_loaded = false
            callback(helper.error("Some error message"))
        end)
    end,

    load_rewarded = function(callback)
        dprint(M.network2.NAME, "ads.load_rewarded()")
        timer.delay(0, false, function()
            M.network2._is_reward_loaded = false
            callback(helper.success())
        end)
    end,

    is_rewarded_loaded = function()
        dprint(M.network2.NAME, "ads.is_rewarded_loaded()")
        return M.network2._is_reward_loaded
    end,

    is_interstitial_loaded = function()
        dprint(M.network2.NAME, "ads.is_interstitial_loaded()")
        return true
    end,

    load_interstitial = function(callback)
        dprint(M.network2.NAME, "ads.load_interstitial()")
        timer.delay(0, false, function()
            callback(helper.success())
        end)
    end,

    show_interstitial = function(callback)
        dprint(M.network2.NAME, "ads.show_interstitial()")
        timer.delay(0, false, function()
            callback(helper.success())
        end)
    end,

    is_banner_setup = function()
        dprint(M.network2.NAME, "ads.is_banner_setup()")
        return true
    end,

    load_banner = function(callback)
        dprint(M.network2.NAME, "ads.load_banner()")
        M.network2._is_banner_loaded = true
        timer.delay(0, false, function()
            callback(helper.success())
        end)
    end,

    unload_banner = function(callback)
        dprint(M.network2.NAME, "ads.unload_banner()")
        M.network2._is_banner_loaded = false
        M.network2._is_banner_showed = false
        timer.delay(0, false, function()
            callback(helper.success())
        end)
    end,

    is_banner_loaded = function()
        dprint(M.network2.NAME, "ads.is_banner_loaded()")
        return M.network2._is_banner_loaded
    end,

    show_banner = function()
        dprint(M.network2.NAME, "ads.show_banner()")
        M.network2._is_banner_showed = true
        return helper.success()
    end,

    hide_banner = function()
        dprint(M.network2.NAME, "ads.hide_banner()")
        M.network2._is_banner_showed = false
        return helper.success()
    end,

    set_banner_position = function(position)
        dprint(M.network2.NAME, "ads.set_banner_position()")
        return helper.success()
    end,

    set_banner_size = function(size)
        dprint(M.network2.NAME, "ads.set_banner_size()")
        return helper.success()
    end,

    is_banner_showed = function()
        dprint(M.network2.NAME, "ads.is_banner_showed()")
        return M.network2._is_banner_showed
    end
}

return M
