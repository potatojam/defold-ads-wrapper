---@meta

---@class helper
local helper = {}

---Creates response `{result = events.SUCCESS, message = message, data = data}`
---@param message string help info
---@param data any
---@return table
function helper.success(message, data)
end

---Creates response `{result = events.ABORT, message = message}`
---@param message string help info
---@return table
function helper.abort(message)
end

---Creates response `{result = events.SUCCESS, code = events.C_SKIPPED, message = message}`
---@param message string help info
---@return table
function helper.skipped(message)
end

---Creates response `{result = events.ERROR, code = code, message = message}`
---@param message string error message
---@param code any error code. Default `events.C_ERROR_UNKNOWN`
---@return table
function helper.error(message, code)
end

return helper
