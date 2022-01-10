local events = require("ads_wrapper.events")

local M = {}

---Creates response `{result = events.SUCCESS, message = message, data = data}`
---@param message string help info
---@param data any
---@return table
function M.success(message, data)
    local response = {}
    response.result = events.SUCCESS
    if message ~= nil then
        response.message = message
    end
    if data ~= nil then
        response.data = data
    end
    return response
end

---Creates response `{result = events.ABORT, message = message}`
---@param message string help info
---@return table
function M.abort(message)
    local response = {}
    response.result = events.ABORT
    if message ~= nil then
        response.message = message
    end
    return response
end

---Creates response `{result = events.SUCCESS, code = events.C_SKIPPED, message = message}`
---@param message string help info
---@return table
function M.skipped(message)
    local response = {}
    response.result = events.SUCCESS
    response.code = events.C_SKIPPED
    if message ~= nil then
        response.message = message
    end
    return response
end

---Creates response `{result = events.ERROR, code = code, message = message}`
---@param message string error message
---@param code any error code. Default `events.C_ERROR_UNKNOWN`
---@return table
function M.error(message, code)
    local response = {}
    response.result = events.ERROR
    response.code = code or events.C_ERROR_UNKNOWN
    if message ~= nil then
        response.message = message
    end
    return response
end

return M
