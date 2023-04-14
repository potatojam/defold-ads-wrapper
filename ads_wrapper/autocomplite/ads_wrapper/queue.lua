---@meta
---@class queue
local queue = {}

---Sets vebose mode. Allows to display all messages.
---@param mode hash
function queue.set_verbose_mode(mode)
end

---Creates new queue
---@return ads_queue
function queue.create()
end

---Runs queue
---@param queue ads_queue
---@param network ads_network
---@param callback ads_callback callback accepting the response result
---@return integer
function queue.run(queue, network, callback)
end

---Adds function to queue. Function must be like `func(network: network, callback: function)`
---@param queue ads_queue
---@param fn ads_callback
function queue.add(queue, fn)
end

---Cancel queue execution
---@param id integer
function queue.cancel(id)
end

return queue
