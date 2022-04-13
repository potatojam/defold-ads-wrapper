---@class mediator
local mediator = {}

---Creates mediator.
---@return mediator
function mediator.create_mediator()
end

---Setups mediator
---@param mediator mediator
---@param networks table array with all available networks
---@param order table order of show ad. Array with objects like `{id = net_id, count = 2}`
---@param repeat_count number count for repeat
function mediator.setup(mediator, networks, order, repeat_count)
end

---Returns the next network in the queue
---@param mediator mediator
---@param is_load bool used for load
---@return table
function mediator.get_next_network(mediator, is_load)
end

---Returns current nerwork in the queue
---@param mediator mediator
---@return table
function mediator.get_current_network(mediator)
end

---Tries to complete queue for first networks in mediator. If not completed, then the next one starts.
---@param mediator mediator
---@param q queue queue object
---@param callback function callback accepting the response result
function mediator.call(mediator, q, callback)
end

---Tries to complete queue for current network in mediator
---@param mediator mediator
---@param q queue queue object
---@param callback function callback accepting the response result
function mediator.call_current(mediator, q, callback)
end

---Tries to complete queue for all networks in mediator
---@param mediator mediator
---@param q queue queue object
---@param callback function callback accepting the response result
function mediator.call_all(mediator, q, callback)
end

---Add networks from another mediator 
---@param to mediator
---@param from mediator
function mediator.add_networks(to, from)
end

return mediator
