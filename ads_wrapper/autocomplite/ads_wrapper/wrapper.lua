---@class wrapper
local wrapper = {}

---Checks for internet connection
---@return boolean
function wrapper.is_internet_connected()
end

---Returns idfa result
---@return any
function wrapper.get_idfa_result()
end

---Checks for internet connection
---@param network network current network
---@param callback function callback accepting the response result
function wrapper.check_connection(network, callback)
end

---Requests IDFA
---@param network network current network
---@param callback function callback accepting the response result
function wrapper.request_idfa(network, callback)
end

---Initializes network
---@param network network current network
---@param callback function callback accepting the response result
function wrapper.init(network, callback)
end

---Loads interstitial ads
---@param network network current network
---@param callback function callback accepting the response result
function wrapper.load_interstitial(network, callback)
end

---Shows interstitial ads
---@param network network current network
---@param callback function callback accepting the response result
function wrapper.show_interstitial(network, callback)
end

---Loads rewarded ads
---@param network network current network
---@param callback function callback accepting the response result
function wrapper.load_rewarded(network, callback)
end

---Shows rewarded ads
---@param network network current network
---@param callback function callback accepting the response result
function wrapper.show_rewarded(network, callback)
end

---Loads banner
---@param network network current network
---@param callback function callback accepting the response result
function wrapper.load_banner(network, callback)
end

---Unloads banner
---@param network network current network
---@param callback function callback accepting the response result
function wrapper.unload_banner(network, callback)
end

---Checks if the required banner is shown and interrupts the queue if it shown.
---@param network network current network
---@param callback function callback accepting the response result
function wrapper.is_banner_showed(network, callback)
end

---Hides banner
---@param network network banner network
function wrapper.hide_network_banner(network)
end

---Shows banner
---@param network network current network
---@param callback function callback accepting the response result
function wrapper.show_banner(network, callback)
end

---Hides banner
---@param network network current network
---@param callback function callback accepting the response result
function wrapper.hide_banner(network, callback)
end

---Returns banners network
---@return network
function wrapper.get_banner_network()
end

---Cleans banner_network variable
function wrapper.clear_banner_network()
end

return wrapper
