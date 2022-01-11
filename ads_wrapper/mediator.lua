local queue = require("ads_wrapper.queue")
local events = require("ads_wrapper.events")
local helper = require("ads_wrapper.ads_networks.helper")

local M = {}

---@class mediator
---@field order table 
---@field networks table 
---@field current_network_num number
---@field repeater number
---@field repeat_num number

-- Checks callback available and calls it passing the result
---@param callback function function
local function handle(callback, ...)
    if callback then
        callback(...)
    end
end

---Resumes coroutine. Throws an error on exception
---@param co thread coroutine thread
---@param ... any
local function resume(co, ...)
    local ok, err = coroutine.resume(co, ...)
    if not ok then
        print(err)
    end
end

---Creates mediator.
---@return mediator
function M.create_mediator()
    local mediator = {}
    mediator.order = {}
    mediator.current_network_num = 0
    mediator.repeater = 0
    mediator.repeat_num = false
    return mediator
end

---Setups mediator
---@param mediator mediator
---@param networks table array with all available networks
---@param order table order of show ad. Array with objects like `{id = net_id, count = 2}`
---@param repeat_count number count for repeat
function M.setup(mediator, networks, order, repeat_count)
    mediator.repeater = repeat_count
    mediator.networks = networks
    for _, network in ipairs(order) do
        local id = network.id
        if id then
            local count = network.count
            for i = 1, count do
                mediator.order[#mediator.order + 1] = networks[id]
            end
        end
    end
    mediator.repeat_num = #mediator.order
end

---Returns the next network in the queue
---@param mediator mediator
---@param is_load bool used for load
---@return table
function M.get_next_network(mediator, is_load)
    local network_num = mediator.current_network_num + 1
    if #mediator.order < network_num then
        network_num = network_num - mediator.repeater
        if network_num < 1 then
            network_num = 1
        end
    end
    if not is_load then
        mediator.current_network_num = network_num
        mediator.repeat_num = (#mediator.order - mediator.repeater) < network_num and mediator.repeater or (#mediator.order - network_num)
    end
    return mediator.order[network_num]
end

---Returns current nerwork in the queue
---@param mediator mediator
---@return table
function M.get_current_network(mediator)
    if mediator.current_network_num == 0 then
        return mediator.order[1]
    end
    return mediator.order[mediator.current_network_num]
end

---Tries to complete queue for first networks in mediator. If not completed, then the next one starts.
---@param mediator mediator
---@param q queue queue object
---@param callback function callback accepting the response result
function M.call(mediator, q, callback)
    local co
    co = coroutine.create(function()
        local checked = {}
        local response
        for i = 1, mediator.repeat_num do
            local network = M.get_next_network(mediator)
            if not checked[network.NAME] then
                queue.run(q, network, function(fn_response)
                    if fn_response.result ~= events.SUCCESS then
                        checked[network.NAME] = true
                    end
                    response = fn_response
                    resume(co)
                end)
                coroutine.yield(co)
            end
            if response.result == events.SUCCESS then
                break
            end
        end
        handle(callback, response)
    end)
    resume(co)
end

---Tries to complete queue for current network in mediator
---@param mediator mediator
---@param q queue queue object
---@param callback function callback accepting the response result
function M.call_current(mediator, q, callback)
    local co
    co = coroutine.create(function()
        local response
        local network = M.get_current_network(mediator)
        queue.run(q, network, function(fn_response)
            response = fn_response
            resume(co)
        end)
        coroutine.yield(co)
        handle(callback, response)
    end)
    resume(co)
end

---Tries to complete queue for all networks in mediator
---@param mediator mediator
---@param q queue queue object
---@param callback function callback accepting the response result
function M.call_all(mediator, q, callback)
    local count = #mediator.networks
    local response = helper.success()
    response.responses = {}
    if not mediator.networks or #mediator.networks == 0 then
        response.message = "Networks are missing."
        callback(response)
    else
        for i, network in pairs(mediator.networks) do
            queue.run(q, network, function(fn_response)
                count = count - 1
                if fn_response.result == events.ERROR then
                    response.result = events.ERROR
                end
                table.insert(response.responses, fn_response)
                if count == 0 then
                    callback(response)
                end
            end)
        end
    end
end

return M
