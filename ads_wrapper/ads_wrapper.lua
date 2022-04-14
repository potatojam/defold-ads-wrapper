local M = {}

local mediator = require("ads_wrapper.mediator")
local queue = require("ads_wrapper.queue")
local wrapper = require("ads_wrapper.wrapper")
local helper = require("ads_wrapper.ads_networks.helper")

-- constants
M.T_REWARDED = hash("T_REWARDED")
M.T_INTERSTITIAL = hash("T_INTERSTITIAL")
M.T_BANNER = hash("T_BANNER")

local BANNER = "Banner"
local VIDEO = "Video"
-- constants

M.is_debug = sys.get_engine_info().is_debug

local video_mediator
local banner_mediator
local networks = {}
local queues = {}
local initialized = false

---Handler for error when mediator isn't setup
---@param name string mediator name
---@param callback function
local function mediator_error(name, callback)
    if callback then
        timer.delay(0, false, function()
            callback(helper.error(name .. " mediator not setup"))
        end)
    end
end

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

---Creates queue for initialization
---@return table
local function create_init()
    local q = queue.create()
    queue.add(q, wrapper.check_connection)
    queue.add(q, wrapper.request_idfa)
    queue.add(q, wrapper.init)
    return q
end

---Creates queue for load_interstitial function
---@return table
local function create_load_interstitial()
    local q = create_init()
    queue.add(q, wrapper.load_interstitial)
    return q
end

---Creates queue for show_interstitial function
---@return table
local function create_show_interstitial()
    local q = create_load_interstitial()
    queue.add(q, wrapper.show_interstitial)
    return q
end

---Creates queue for load_rewarded function
---@return table
local function create_load_rewarded()
    local q = create_init()
    queue.add(q, wrapper.load_rewarded)
    return q
end

---Creates queue for show_rewarded function
---@return table
local function create_show_rewarded()
    local q = create_load_rewarded()
    queue.add(q, wrapper.show_rewarded)
    return q
end

---Creates queue for load_banner function
---@return table
local function create_load_banner()
    local q = create_init()
    queue.add(q, wrapper.load_banner)
    return q
end

---Creates queue for show_banner function
---@return table
local function create_show_banner()
    local q = queue.create()
    queue.add(q, wrapper.check_connection)
    queue.add(q, wrapper.is_banner_showed)
    queue.add(q, wrapper.request_idfa)
    queue.add(q, wrapper.init)
    queue.add(q, wrapper.load_banner)
    queue.add(q, wrapper.show_banner)
    return q
end

---Creates queue for unload_banner function
---@return table
local function create_unload_banner()
    local q = queue.create()
    queue.add(q, wrapper.unload_banner)
    return q
end

---Creates queue for hide_banner function
---@return table
local function create_hide_banner()
    local q = queue.create()
    queue.add(q, wrapper.hide_banner)
    return q
end

---Remove all registered networks
function M.clear_networks()
    networks = {}
end

---Registers network. Returns id
---@param network network
---@param params any parameters to be passed to the network.setup function
---@return number|nil
function M.register_network(network, params)
    if network.is_supported() then
        local id = #networks + 1
        networks[id] = network
        network.setup(params)
        return id
    else
        pprint(network.NAME .. " Network is not supported for this platform. Network not registered")
        return nil
    end
end

---Setups interstitial and reward mediator
---@param order table
---@param repeat_count number
function M.setup_video(order, repeat_count)
    video_mediator = mediator.create_mediator()
    mediator.setup(video_mediator, networks, order, repeat_count)
end

---Setups banner mediator
---@param order table
---@param repeat_count number
function M.setup_banner(order, repeat_count)
    banner_mediator = mediator.create_mediator()
    mediator.setup(banner_mediator, networks, order, repeat_count)
end

---Initializes all networks.
---@param initilize_video boolean
---@param initilize_banner boolean
---@param callback function the function is called after execution.
function M.init(initilize_video, initilize_banner, callback)
    if M.is_initialized() then
        handle(callback, helper.success("Ads Wrapper already initialized"))
        return
    end
    initialized = true
    queues.init = create_init()
    queues.show_interstitial = create_show_interstitial()
    queues.load_interstitial = create_load_interstitial()
    queues.show_rewarded = create_show_rewarded()
    queues.load_rewarded = create_load_rewarded()
    queues.load_banner = create_load_banner()
    queues.unload_banner = create_unload_banner()
    queues.hide_banner = create_hide_banner()
    queues.show_banner = create_show_banner()

    if initilize_video or initilize_banner then
        local init_mediator = mediator.create_mediator()
        if initilize_video then
            mediator.add_networks(init_mediator, video_mediator)
        end
        if initilize_banner then
            mediator.add_networks(init_mediator, banner_mediator)
        end
        mediator.call_all(init_mediator, queues.init, function(resonse)
            handle(callback, helper.success("Tryed to initialize networks", resonse))
        end)
    else
        handle(callback, helper.success("Ads Wrapper initialized without networks"))
    end
end

---Initialize video networks
---@param callback function the function is called after execution.
function M.init_video_networks(callback)
    if video_mediator then
        mediator.call_all(video_mediator, queues.init, callback)
    else
        mediator_error(VIDEO, callback)
    end
end

---Initialize banner networks
---@param callback function the function is called after execution.
function M.init_banner_networks(callback)
    if banner_mediator then
        mediator.call_all(banner_mediator, queues.init, callback)
    else
        mediator_error(BANNER, callback)
    end
end

---Loads rewarded ads for next network
---@param callback function the function is called after execution.
function M.load_rewarded(callback)
    if M.is_video_setup() then
        mediator.call(video_mediator, queues.load_rewarded, callback)
    else
        mediator_error(VIDEO, callback)
    end
end

---Shows rewarded ads for next network
---@param callback function the function is called after execution.
function M.show_rewarded(callback)
    if M.is_video_setup() then
        mediator.call(video_mediator, queues.show_rewarded, callback)
    else
        mediator_error(VIDEO, callback)
    end
end

---Loads interstitial ads for next network
---@param callback function the function is called after execution.
function M.load_interstitial(callback)
    if M.is_video_setup() then
        mediator.call(video_mediator, queues.load_interstitial, callback)
    else
        mediator_error(VIDEO, callback)
    end
end

---Shows interstitial ads for next network
---@param callback function the function is called after execution.
function M.show_interstitial(callback)
    if M.is_video_setup() then
        mediator.call(video_mediator, queues.show_interstitial, callback)
    else
        mediator_error(VIDEO, callback)
    end
end

---Loads banner for for next network.
---@param callback function the function is called after execution.
function M.load_banner(callback)
    if M.is_banner_setup() then
        mediator.call(banner_mediator, queues.load_banner, callback)
    else
        mediator_error(BANNER, callback)
    end
end

---Shows setup banner for next network. Hides the previous banner if it was displayed.
---@param callback function the function is called after execution.
function M.show_banner(callback)
    if M.is_banner_setup() then
        mediator.call(banner_mediator, queues.show_banner, callback)
    else
        mediator_error(BANNER, callback)
    end
end

---Hides setup banner for current network
---@param callback function the function is called after execution.
function M.hide_banner(callback)
    if M.is_banner_setup() then
        mediator.call_current(banner_mediator, queues.hide_banner, callback)
    else
        mediator_error(BANNER, callback)
    end
end

---Unloads banner for current networks.
---@param callback function the function is called after execution.
function M.unload_banner(callback)
    if M.is_banner_setup() then
        mediator.call_current(banner_mediator, queues.unload_banner, callback)
    else
        mediator_error(BANNER, callback)
    end
end

---Check if the banner mediator is set up
---@return boolean
function M.is_banner_setup()
    return banner_mediator ~= nil
end

---Check if the interstitial and rewarded video mediator is set up
---@return boolean
function M.is_video_setup()
    return video_mediator ~= nil
end

---Check if wrapper is initiailzed
---@return boolean
function M.is_initialized()
    return initialized
end

return M
