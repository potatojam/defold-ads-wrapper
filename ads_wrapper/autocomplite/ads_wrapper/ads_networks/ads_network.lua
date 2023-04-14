---@meta

---@class ads_network
local ads_network = { NAME = "admob" }

---Api setup
---@param params any|nil
function ads_network.setup(params)
end

---Initializes `admob` sdk.
---@param callback ads_callback|nil the function is called after execution.
function ads_network.init(callback)
end

---Requests IDFA
---@param callback ads_callback|nil the function is called after execution.
function ads_network.request_idfa(callback)
end

---Check if the environment supports admob api
---@return bool
function ads_network.is_supported()
end

---Check if the admob is initialized
---@return bool
function ads_network.is_initialized()
end

---Shows rewarded ads.
---@param callback ads_callback|nil the function is called after execution.
function ads_network.show_rewarded(callback)
end

---Loads rewarded ads
---@param callback ads_callback|nil the function is called after execution.
function ads_network.load_rewarded(callback)
end

---Check if the rewarded ads is loaded
---@return boolean
function ads_network.is_rewarded_loaded()
end

---Shows interstitial ads.
---@param callback ads_callback|nil the function is called after execution.
function ads_network.show_interstitial(callback)
end

---Loads interstitial ads
---@param callback ads_callback|nil the function is called after execution.
function ads_network.load_interstitial(callback)
end

---Check if the interstitial ads is loaded
---@return boolean
function ads_network.is_interstitial_loaded()
end

---Check if the banner is set up
---@return boolean
function ads_network.is_banner_setup()
end

---Loads banner. Use `ads.T_BANNER` parameter.
---@param callback ads_callback|nil the function is called after execution.
function ads_network.load_banner(callback)
end

---Unloads active banner.
---@param callback ads_callback|nil the function is called after execution.
function ads_network.unload_banner(callback)
end

---Check if the banner is loaded
---@return boolean
function ads_network.is_banner_loaded()
end

---Shows loaded banner.
---@param callback ads_callback|nil the function is called after execution.
function ads_network.show_banner(callback)
end

---Hides loaded banner.
---@param callback ads_callback|nil the function is called after execution.
function ads_network.hide_banner(callback)
end

---Check if the banner is showed
---@return boolean
function ads_network.is_banner_showed()
end

return ads_network
