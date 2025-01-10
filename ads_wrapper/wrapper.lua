local events = require("ads_wrapper.events")
local helper = require("ads_wrapper.ads_networks.helper")

local M = {}

local idfa_result = nil
local banner_network = nil

---Call callback in the second frame. Send result.
---It is necessary to use timer for the coroutine to continue.
---@param callback ads_callback|nil
---@param result ads_response
local function handle(callback, result)
    if callback then
        timer.delay(0, false, function()
            callback(result)
        end)
    end
end

---Checks for internet connection
---@return boolean
function M.is_internet_connected()
    return sys.get_connectivity() ~= sys.NETWORK_DISCONNECTED
end

---Returns idfa result
---@return any
function M.get_idfa_result()
    return idfa_result
end

---Checks for internet connection
---@param network ads_network current network
---@param callback ads_callback|nil callback accepting the response result
function M.check_connection(network, callback)
    if M.is_internet_connected() then
        handle(callback, helper.success())
        return
    else
        handle(callback, helper.error("No internet connection", events.C_ERROR_NO_CONNECTION))
        return
    end
end

---Requests IDFA
---@param network ads_network current network
---@param callback ads_callback|nil callback accepting the response result
---@param params table|nil
function M.request_idfa(network, callback, params)
    if idfa_result ~= nil then
        handle(callback, helper.success("IDFA already received"))
        return
    end
    if network.request_idfa then
        network.request_idfa(function(response)
            if response.result ~= events.ERROR then
                idfa_result = response.data
            end
            handle(callback, helper.success())
        end, params)
    else
        handle(callback, helper.success("IDFA not supported"))
    end
end

---Initializes network
---@param network ads_network current network
---@param callback ads_callback|nil callback accepting the response result
---@param params table|nil
function M.init(network, callback, params)
    if network.is_initialized() then
        handle(callback, helper.success("Network already initialized"))
        return
    end
    network.init(callback, params)
end

---Loads interstitial ads
---@param network ads_network current network
---@param callback ads_callback|nil callback accepting the response result
---@param params table|nil
function M.load_interstitial(network, callback, params)
    if network.is_interstitial_loaded(params) then
        handle(callback, helper.success("Interstitial ads already loaded"))
        return
    end
    network.load_interstitial(callback, params)
end

---Shows interstitial ads
---@param network ads_network current network
---@param callback ads_callback|nil callback accepting the response result
---@param params table|nil
function M.show_interstitial(network, callback, params)
    network.show_interstitial(callback, params)
end

---Loads rewarded ads
---@param network ads_network current network
---@param callback ads_callback|nil callback accepting the response result
---@param params table|nil
function M.load_rewarded(network, callback, params)
    if network.is_rewarded_loaded(params) then
        handle(callback, helper.success("Rewarded ads already loaded"))
        return
    end
    network.load_rewarded(callback, params)
end

---Shows rewarded ads
---@param network ads_network current network
---@param callback ads_callback|nil callback accepting the response result
---@param params table|nil
function M.show_rewarded(network, callback, params)
    network.show_rewarded(callback, params)
end

---Loads banner
---@param network ads_network current network
---@param callback ads_callback|nil callback accepting the response result
---@param params table|nil
function M.load_banner(network, callback, params)
    if network.is_banner_loaded(params) then
        handle(callback, helper.success("Banner already loaded"))
        return
    end
    network.load_banner(callback, params)
end

---Unloads banner
---@param network ads_network current network
---@param callback ads_callback|nil callback accepting the response result
---@param params table|nil
function M.unload_banner(network, callback, params)
    if not network.is_banner_loaded(params) then
        handle(callback, helper.success("Banner already unloaded"))
        return
    end
    network.unload_banner(callback, params)
end

---Checks if the required banner is shown and interrupts the queue if it shown.
---@param network ads_network current network
---@param callback ads_callback|nil callback accepting the response result
---@param params table|nil
function M.is_banner_showed(network, callback, params)
    if banner_network and banner_network == network and banner_network.is_banner_showed(params) then
        handle(callback, helper.abort("The required banner has already been shown"))
    else
        handle(callback, helper.success())
    end
end

---Hides banner
---@param network ads_network|nil banner network
---@param callback ads_callback|nil callback accepting the response result
---@param params table|nil
function M.hide_network_banner(network, callback, params)
    if network and network.is_banner_showed(params) then
        network.hide_banner(callback, params)
        ---TODO QUESTION: need to clean the network in case of failure
        M.clear_banner_network()
    else
        handle(callback, helper.success("Banner already hidden"))
    end
end

---Show network banner
---@param network ads_network
---@param callback ads_callback|nil
---@param params table|nil
function M.show_network_banner(network, callback, params)
    network.show_banner(function(response)
        if response.result == events.SUCCESS then
            banner_network = network
        end
        handle(callback, response)
    end, params)
end

---Shows banner
---@param network ads_network current network
---@param callback ads_callback|nil callback accepting the response result
---@param params table|nil
function M.show_banner(network, callback, params)
    if banner_network then
        M.hide_network_banner(banner_network, function(response)
            --TODO: if error occured
            M.show_network_banner(network, callback, params)
        end)
    else
        M.show_network_banner(network, callback, params)
    end
end

---Hides banner
---@param network ads_network current network
---@param callback ads_callback|nil callback accepting the response result
---@param params table|nil
function M.hide_banner(network, callback, params)
    M.hide_network_banner(banner_network, callback, params)
end

---Returns banners network
---@return ads_network|nil
function M.get_banner_network()
    return banner_network
end

---Cleans banner_network variable
function M.clear_banner_network()
    banner_network = nil
end

return M
