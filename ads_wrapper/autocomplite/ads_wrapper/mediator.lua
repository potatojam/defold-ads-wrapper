---@meta
---@class ads_mediator
local mediator = {}

---Creates mediator.
---@return ads_mediator
function mediator.create_mediator()
end

---Setups mediator
---@param mediator ads_mediator
---@param networks table<integer, ads_network> array with all available networks
---@param order ads_order[] order of show ad. Array with objects like `{id = net_id, count = 2}`
---@param repeat_count number|nil count of ads that will loop. From the end
function mediator.setup(mediator, networks, order, repeat_count)
end

---Returns the next network in the queue
---@param mediator ads_mediator
---@param leave_pointer bool|nil leaves the pointer on the same network. Default `false`
---@return ads_network
function mediator.get_next_network(mediator, leave_pointer)
end

---Returns current nerwork in the queue
---@param mediator ads_mediator
---@return ads_network
function mediator.get_current_network(mediator)
end

---Tries to complete queue for first networks in mediator. If not completed, then the next one starts.
---@param mediator ads_mediator
---@param q ads_queue queue object
---@param callback ads_callback|nil callback accepting the response result
---@return integer
function mediator.call(mediator, q, callback)
end

---Tries to complete queue for current network in mediator
---@param mediator ads_mediator
---@param q ads_queue queue object
---@param callback ads_callback|nil callback accepting the response result
---@return integer
function mediator.call_current(mediator, q, callback)
end

---Tries to complete queue for next network in mediator. Pointer does not switch
---@param mediator ads_mediator
---@param q ads_queue queue object
---@param callback ads_callback|nil callback accepting the response result
---@return integer
function mediator.call_next(mediator, q, callback)
end

---Tries to complete queue for all networks in mediator
---@param mediator ads_mediator
---@param q ads_queue queue object
---@param callback ads_callback|nil callback accepting the response result
function mediator.call_all(mediator, q, callback)
end

---Add networks from another mediator
---@param to ads_mediator
---@param from ads_mediator
function mediator.add_networks(to, from)
end

---Cancel execution
---@param id integer
function mediator.cancel(id)
end

return mediator
