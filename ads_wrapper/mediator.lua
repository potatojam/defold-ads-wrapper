local queue = require("ads_wrapper.queue")
local events = require("ads_wrapper.events")
local helper = require("ads_wrapper.ads_networks.helper")

local M = {}

local MAX_ID = 99999999
local ID = 0

local coroutines = {}

---Return new id
---@return integer
local function get_id()
    ID = ID + 1
    if ID > MAX_ID then
        ID = 0
    end
    return ID
end

---Put coroutines to the table
---@param co thread
---@return integer
local function save_coroutine(co)
    local id = get_id()
    coroutines[id] = {
        co = co,
        others = {}
    }
    return id
end

---Put others coroutines to the table
---@param id integer
---@param other_id integer
local function save_other(id, other_id)
    if not coroutines[id] then
        error("Coroutine does not exist")
    end
    local others = coroutines[id].others
    others[#others + 1] = other_id
end

-- Checks callback available and calls it passing the result
---@param callback function|nil function
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
---@return ads_mediator
function M.create_mediator()
    local mediator = {}
    mediator.order = {}
    mediator.networks = {}
    mediator.current_network_num = 0
    mediator.repeater = 0
    mediator.repeat_num = false
    return mediator
end

---Setups mediator
---@param mediator ads_mediator
---@param networks table<integer, ads_network> array with all available networks
---@param order ads_order[] order of show ad. Array with objects like `{id = net_id, count = 2}`
---@param repeat_count number|nil count of ads that will loop. From the end
function M.setup(mediator, networks, order, repeat_count)
    local is_auto_repeat = false
    if not repeat_count then
        is_auto_repeat = true
    else
        mediator.repeater = repeat_count
    end
    for _, network_data in ipairs(order) do
        local id = network_data.id
        if id then
            local count = network_data.count or 1
            if is_auto_repeat then
                mediator.repeater = mediator.repeater + count
            end
            for i = 1, count do
                mediator.networks[id] = networks[id]
                mediator.order[#mediator.order + 1] = networks[id]
            end
        end
    end
    mediator.repeat_num = #mediator.order
end

---Returns the next network in the queue
---@param mediator ads_mediator
---@param leave_pointer bool|nil leaves the pointer on the same network. Default `false`
---@return ads_network
function M.get_next_network(mediator, leave_pointer)
    local network_num = mediator.current_network_num + 1
    if #mediator.order < network_num then
        network_num = network_num - mediator.repeater
        if network_num < 1 then
            network_num = 1
        end
    end
    if not leave_pointer then
        mediator.current_network_num = network_num
        mediator.repeat_num = (#mediator.order - mediator.repeater) < network_num and mediator.repeater or (#mediator.order - network_num)
    end
    return mediator.order[network_num]
end

---Returns current nerwork in the queue
---@param mediator ads_mediator
---@return ads_network
function M.get_current_network(mediator)
    if mediator.current_network_num == 0 then
        return mediator.order[1]
    end
    return mediator.order[mediator.current_network_num]
end

---Tries to complete queue for first networks in mediator. If not completed, then the next one starts.
---@param mediator ads_mediator
---@param q ads_queue queue object
---@param callback ads_callback|nil callback accepting the response result
---@return integer
function M.call(mediator, q, callback)
    local co
    local id
    co = coroutine.create(function()
        local checked = {}
        local response = helper.error("Something bad happened")
        for i = 1, mediator.repeat_num do
            local network = M.get_next_network(mediator)
            if not checked[network.NAME] then
                local queue_id = queue.run(q, network, function(fn_response)
                    if fn_response.result ~= events.SUCCESS then
                        checked[network.NAME] = true
                    end
                    fn_response.name = network.NAME
                    response = fn_response
                    resume(co)
                end)
                save_other(id, queue_id)
                coroutine.yield(co)
            end
            if response.result == events.SUCCESS then
                break
            end
            if not coroutines[id] then
                break
            end
        end
        coroutines[id] = nil
        handle(callback, response)
    end)
    id = save_coroutine(co)
    resume(co)
    return id
end

---Tries to complete queue for current network in mediator
---@param mediator ads_mediator
---@param q ads_queue queue object
---@param callback ads_callback|nil callback accepting the response result
---@return integer
function M.call_current(mediator, q, callback)
    local co
    local id
    co = coroutine.create(function()
        local response = helper.error("Something bad happened")
        local network = M.get_current_network(mediator)
        local queue_id = queue.run(q, network, function(fn_response)
            fn_response.name = network.NAME
            response = fn_response
            resume(co)
        end)
        save_other(id, queue_id)
        coroutine.yield(co)
        coroutines[id] = nil
        handle(callback, response)
    end)
    id = save_coroutine(co)
    resume(co)
    return id
end

---Tries to complete queue for next network in mediator. Pointer does not switch
---@param mediator ads_mediator
---@param q ads_queue queue object
---@param callback ads_callback|nil callback accepting the response result
---@return integer
function M.call_next(mediator, q, callback)
    local co
    local id
    co = coroutine.create(function()
        local response = helper.error("Something bad happened")
        local network = M.get_next_network(mediator, true)
        local queue_id = queue.run(q, network, function(fn_response)
            fn_response.name = network.NAME
            response = fn_response
            resume(co)
        end)
        save_other(id, queue_id)
        coroutine.yield(co)
        coroutines[id] = nil
        handle(callback, response)
    end)
    id = save_coroutine(co)
    resume(co)
    return id
end

---Tries to complete queue for all networks in mediator
---@param mediator ads_mediator
---@param q ads_queue queue object
---@param callback ads_callback|nil callback accepting the response result
function M.call_all(mediator, q, callback)
    local count = 0
    local response = helper.success()
    response.responses = {}
    if not mediator.networks or #mediator.networks == 0 then
        response.message = "Networks are missing."
        handle(callback, response)
    else
        for id, network in pairs(mediator.networks) do
            count = count + 1
            queue.run(q, network, function(fn_response)
                count = count - 1
                fn_response.network_name = network.NAME
                if fn_response.result == events.ERROR then
                    response.result = events.ERROR
                end
                table.insert(response.responses, fn_response)
                if count == 0 then
                    handle(callback, response)
                end
            end)
        end
    end
end

---Add networks from another mediator
---@param to ads_mediator
---@param from ads_mediator
function M.add_networks(to, from)
    if from and from.networks then
        for id, network in pairs(from.networks) do
            to.networks[id] = network
        end
    end
end

---Cancel queue execution
---@param id integer
function M.cancel(id)
    local object = coroutines[id]
    if object then
        for key, other_id in pairs(object.others) do
            queue.cancel(other_id)
        end
        coroutines[id] = nil
    end
end

return M
