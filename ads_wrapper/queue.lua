local events = require("ads_wrapper.events")

local M = {}

local is_verbose = false
local verbose_mode = events.V_NONE

---Resumes coroutine. Throws an error on exception
---@param co thread coroutine thread
---@param ... any
local function resume(co, ...)
    local ok, err = coroutine.resume(co, ...)
    if not ok then
        print(err)
    end
end

---Call function from queue
---@param fn function
---@param network network
---@return table
local function call(fn, network)
    local co = coroutine.running()
    assert(co, "You must call this from inside a coroutine")
    local response
    fn(network, function(fn_response)
        response = fn_response
        resume(co)
    end)
    coroutine.yield(co)
    return response
end

---Sets vebose mode. Allows to display all messages.
---@param mode hash
function M.set_verbose_mode(mode)
    if mode == events.V_NONE then
        is_verbose = false
    else
        verbose_mode = mode
        is_verbose = true
    end
end

---Creates new queue
---@return table
function M.create()
    local queue = {}
    return queue
end

---Runs queue
---@param queue table
---@param network network
---@param callback function callback accepting the response result
function M.run(queue, network, callback)
    local length = #queue
    local co = coroutine.create(function()
        local response
        for i, fn in ipairs(queue) do
            local fn_response = call(fn, network)
            if is_verbose then
                if fn_response.result == events.ERROR and fn_response.message and (verbose_mode == events.V_ALL or verbose_mode == events.V_ERROR) then
                    print("Error: " .. fn_response.message)
                elseif (fn_response.result == events.SUCCESS or fn_response.result == events.ABORT) and fn_response.message and
                    (verbose_mode == events.V_ALL or verbose_mode == events.V_SUCCESS) then
                    print("Success: " .. fn_response.message)
                end
            end

            if fn_response.result == events.ERROR or i == length then
                response = fn_response
                break
            end
            if fn_response.result == events.ABORT then
                fn_response.result = events.SUCCESS
                response = fn_response
                break
            end
        end
        callback(response)
    end)
    resume(co)
end

---Adds function to queue. Function must be like `func(network: network, callback: function)`
---@param queue table
---@param fn function
function M.add(queue, fn)
    table.insert(queue, fn)
end

return M
