---@meta
---@class ads_wrapper
local ads_wrapper = {}

ads_wrapper.T_REWARDED = hash("T_REWARDED")
ads_wrapper.T_INTERSTITIAL = hash("T_INTERSTITIAL")
ads_wrapper.T_BANNER = hash("T_BANNER")

---Registers network. Returns id
---@param network ads_network
---@param params any|nil parameters to be passed to the network.setup function
---@return integer|nil
function ads_wrapper.register_network(network, params)
end

---Setups interstitial and reward mediator
---@param order ads_order[]
---@param repeat_count number|nil Specified if after the first cycle in queue it is necessary to cut off a part of the order. Default: the total number of all networks.
function ads_wrapper.setup_video(order, repeat_count)
end

---Setups banner mediator
---@param order ads_order[]
---@param repeat_count number|nil Specified if after the first cycle in queue it is necessary to cut off a part of the order. Default: the total number of all networks.
---@param _banner_auto_hide boolean|nil The banner will be automatically hidden if hide_banner was called after show_banner, but the banner did not have time to load. Default: `false`
function ads_wrapper.setup_banner(order, repeat_count, _banner_auto_hide)
end

---Checks for internet connection
---@return boolean
function ads_wrapper.is_internet_connected()
end

---Initializes all networks.
---@param initilize_video boolean|nil check if need to initialize video networks
---@param initilize_banner boolean|nil check if need to initialize banner networks
---@param callback ads_callback|nil the function is called after execution.
function ads_wrapper.init(initilize_video, initilize_banner, callback)
end

---Initialize video networks
---@param callback ads_callback|nil the function is called after execution.
function ads_wrapper.init_video_networks(callback)
end

---Initialize banner networks
---@param callback ads_callback|nil the function is called after execution.
function ads_wrapper.init_banner_networks(callback)
end

---Loads rewarded ads for next network
---@param callback ads_callback|nil the function is called after execution.
---@return integer|nil
function ads_wrapper.load_rewarded(callback)
end

---Shows rewarded ads for next network
---@param callback ads_callback|nil the function is called after execution.
---@return integer|nil
function ads_wrapper.show_rewarded(callback)
end

---Loads interstitial ads for next network
---@param callback ads_callback|nil the function is called after execution.
---@return integer|nil
function ads_wrapper.load_interstitial(callback)
end

---Shows interstitial ads for next network
---@param callback ads_callback|nil the function is called after execution.
---@return integer|nil
function ads_wrapper.show_interstitial(callback)
end

---Loads banner for all setup networks.
---@param callback ads_callback|nil the function is called after execution.
---@return integer|nil
function ads_wrapper.load_banner(callback)
end

---Shows setup banner for next network. Hides the previous banner if it was displayed.
---@param callback ads_callback|nil the function is called after execution.
---@return integer|nil
function ads_wrapper.show_banner(callback)
end

---Hides setup banner for current network
---@param callback ads_callback|nil the function is called after execution.
function ads_wrapper.hide_banner(callback)
end

---Unloads banner for current networks.
---@param callback ads_callback|nil the function is called after execution.
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

---Remove all registered networks
function ads_wrapper.clear_networks()
end

---Check if the interstitial video is loaded.
---Default checks the `next` network in mediator.
---@param check_current boolean|nil `Optional` if need check current network. Default `false`
---@return boolean
function ads_wrapper.is_interstitial_loaded(check_current)
end

---Check if the rewarded video is loaded.
---Default checks the `next` network in mediator.
---@param check_current boolean|nil `Optional` if need check current network. Default `false`
---@return boolean
function ads_wrapper.is_rewarded_loaded(check_current)
end

---Check if the banner is loaded.
---Default checks the `next` network in mediator.
---@param check_current boolean|nil `Optional` if need check current network. Default `false`
---@return boolean
function ads_wrapper.is_banner_loaded(check_current)
end

---Returns the current network pointed to by mediator
---Default returns for the video mediator
---@param check_banner boolean|nil `Optional` need to return mediator for banners. Default `false`
---@return ads_network|nil
function ads_wrapper.get_current_network(check_banner)
end

---Returns the next network pointed to by mediator
---Default returns for the video mediator
---@param check_banner boolean|nil `Optional` need to return mediator for banners. Default `false`
---@return ads_network|nil
function ads_wrapper.get_next_network(check_banner)
end

---Cancel execution
---@param id integer
function ads_wrapper.cancel(id)
end

return ads_wrapper
