---@class queue
local queue = {}

---Sets vebose mode. Allows to display all messages.
---@param mode hash
function queue.set_verbose_mode(mode)
end

---Creates new queue
---@return table
function queue.create()
end

---Runs queue
---@param queue table
---@param network network
---@param callback function callback accepting the response result
function queue.run(queue, network, callback)
end

---Adds function to queue. Function must be like `func(network: network, callback: function)`
---@param queue table
---@param fn function
function queue.add(queue, fn)
end

return queue
