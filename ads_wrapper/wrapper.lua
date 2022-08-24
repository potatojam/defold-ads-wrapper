local events = require("ads_wrapper.events")
local helper = require("ads_wrapper.ads_networks.helper")

local M = {}

local idfa_result = nil
local banner_network = nil

---Call callback in the second frame. Send result.
---It is necessary to use timer for the coroutine to continue.
---@param result hash
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
---@param network network current network
---@param callback function callback accepting the response result
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
---@param network network current network
---@param callback function callback accepting the response result
function M.request_idfa(network, callback)
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
        end)
    else
        handle(callback, helper.success("IDFA not supported"))
    end
end

---Initializes network
---@param network network current network
---@param callback function callback accepting the response result
function M.init(network, callback)
    if network.is_initialized() then
        handle(callback, helper.success("Network already initialized"))
        return
    end
    network.init(callback)
end

---Loads interstitial ads
---@param network network current network
---@param callback function callback accepting the response result
function M.load_interstitial(network, callback)
    if network.is_interstitial_loaded() then
        handle(callback, helper.success("Interstitial ads already loaded"))
        return
    end
    network.load_interstitial(callback)
end

---Shows interstitial ads
---@param network network current network
---@param callback function callback accepting the response result
function M.show_interstitial(network, callback)
    network.show_interstitial(callback)
end

---Loads rewarded ads
---@param network network current network
---@param callback function callback accepting the response result
function M.load_rewarded(network, callback)
    if network.is_rewarded_loaded() then
        handle(callback, helper.success("Rewarded ads already loaded"))
        return
    end
    network.load_rewarded(callback)
end

---Shows rewarded ads
---@param network network current network
---@param callback function callback accepting the response result
function M.show_rewarded(network, callback)
    network.show_rewarded(callback)
end

---Loads banner
---@param network network current network
---@param callback function callback accepting the response result
function M.load_banner(network, callback)
    if network.is_banner_loaded() then
        handle(callback, helper.success("Banner already loaded"))
        return
    end
    network.load_banner(callback)
end

---Unloads banner
---@param network network current network
---@param callback function callback accepting the response result
function M.unload_banner(network, callback)
    if not network.is_banner_loaded() then
        handle(callback, helper.success("Banner already unloaded"))
        return
    end
    network.unload_banner(callback)
end

---Checks if the required banner is shown and interrupts the queue if it shown.
---@param network network current network
---@param callback function callback accepting the response result
function M.is_banner_showed(network, callback)
    if banner_network and banner_network == network and banner_network.is_banner_showed() then
        handle(callback, helper.abort("The required banner has already been shown"))
    else
        handle(callback, helper.success())
    end
end

---Hides banner
---@param network network banner network
---@param callback function callback accepting the response result
function M.hide_network_banner(network, callback)
    if network and network.is_banner_showed() then
        network.hide_banner(callback)
        ---TODO QUESTION: need to clean the network in case of failure
        M.clear_banner_network()
    else
        handle(callback, helper.success("Banner already hided"))
    end
end

function M.show_network_banner(network, callback)
    network.show_banner(function(response)
        if response.result == events.SUCCESS then
            banner_network = network
        end
        handle(callback, response)
    end)
end

---Shows banner
---@param network network current network
---@param callback function callback accepting the response result
function M.show_banner(network, callback)
    if banner_network then
        M.hide_network_banner(banner_network, function(response)
            --TODO ERROR
            M.show_network_banner(network, callback)
        end)
    else
        M.show_network_banner(network, callback)
    end
end

---Hides banner
---@param network network current network
---@param callback function callback accepting the response result
function M.hide_banner(network, callback)
    M.hide_network_banner(banner_network, callback)
end

---Returns banners network
---@return network
function M.get_banner_network()
    return banner_network
end

---Cleans banner_network variable
function M.clear_banner_network()
    banner_network = nil
end

return M
