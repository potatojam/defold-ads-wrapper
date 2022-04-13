---@class ads_wrapper
local ads_wrapper = {}

ads_wrapper.T_REWARDED = hash("T_REWARDED")
ads_wrapper.T_INTERSTITIAL = hash("T_INTERSTITIAL")
ads_wrapper.T_BANNER = hash("T_BANNER")

---Registers network. Returns id
---@param network network
---@param params any parameters to be passed to the network.setup function
---@return number|nil
function ads_wrapper.register_network(network, params)
end

---Setups interstitial and reward mediator
---@param order table
---@param repeat_count number
function ads_wrapper.setup_video(order, repeat_count)
end

---Setups banner mediator
---@param order table
---@param repeat_count number
function ads_wrapper.setup_banner(order, repeat_count)
end

---Checks for internet connection
---@return boolean
function ads_wrapper.is_internet_connected()
end

---Initializes all networks.
---@param initilize_video boolean
---@param initilize_banner boolean
---@param callback function the function is called after execution.
function ads_wrapper.init(initilize_video, initilize_banner, callback)
end

---Initialize video networks
---@param callback function the function is called after execution.
function ads_wrapper.init_video_networks(callback)
end

---Initialize banner networks
---@param callback function the function is called after execution.
function ads_wrapper.init_banner_networks(callback)
end

---Loads rewarded ads for next network
---@param callback function the function is called after execution.
function ads_wrapper.load_rewarded(callback)
end

---Shows rewarded ads for next network
---@param callback function the function is called after execution.
function ads_wrapper.show_rewarded(callback)
end

---Loads interstitial ads for next network
---@param callback function the function is called after execution.
function ads_wrapper.load_interstitial(callback)
end

---Shows interstitial ads for next network
---@param callback function the function is called after execution.
function ads_wrapper.show_interstitial(callback)
end

---Loads banner for all setup networks.
---@param callback function the function is called after execution.
function ads_wrapper.load_banner(callback)
end

---Shows setup banner for next network. Hides the previous banner if it was displayed.
---@param callback function the function is called after execution.
function ads_wrapper.show_banner(callback)
end

---Hides setup banner for current network
---@param callback function the function is called after execution.
function ads_wrapper.hide_banner(callback)
end

---Unloads banner for current networks.
---@param callback function the function is called after execution.
function ads_wrapper.unload_banner(callback)
end

---Check if the banner mediator is set up
---@return boolean
function ads_wrapper.is_banner_setup()
end

---Check if the interstitial and rewarded video mediator is set up
---@return boolean
function ads_wrapper.is_video_setup()
end

---Check if ads wrapper is initiailzed
---@return boolean
function ads_wrapper.is_initialized()
end

return ads_wrapper
