local events = require("ads_wrapper.events")

local M = {}

local is_verbose = false
local verbose_mode = events.V_NONE

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

---Put coroutine to the table
---@param co thread
---@return integer
local function save_coroutine(co)
    local id = get_id()
    coroutines[id] = co
    return id
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

---Call function from queue
---@param fn function
---@param network ads_network
---@param params table|nil additional parameters
---@return ads_response
local function call(fn, network, params)
    local co = coroutine.running()
    assert(co, "You must call this from inside a coroutine")
    local response
    fn(network, function(fn_response)
        response = fn_response
        resume(co)
    end, params)
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
---@return ads_queue
function M.create()
    local queue = {}
    return queue
end

---Runs queue
---@param queue ads_queue
---@param network ads_network
---@param callback ads_callback callback accepting the response result
---@param params table|nil additional parameters
---@return integer
function M.run(queue, network, callback, params)
    local length = #queue
    local id
    local co = coroutine.create(function()
        local response
        for i, fn in ipairs(queue) do
            local fn_response = call(fn, network, params)
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
            if not coroutines[id] then
                fn_response.cancelled = true
                response = fn_response
                break
            end
        end
        coroutines[id] = nil
        callback(response)
    end)
    id = save_coroutine(co)
    resume(co)
    return id
end

---Adds function to queue. Function must be like `func(network: network, callback: function)`
---@param queue ads_queue
---@param fn ads_callback
function M.add(queue, fn)
    table.insert(queue, fn)
end

---Cancel queue execution
---@param id integer
function M.cancel(id)
    coroutines[id] = nil
end

return M
