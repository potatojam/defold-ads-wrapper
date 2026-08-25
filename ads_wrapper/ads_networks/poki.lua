local helper = require("ads_wrapper.ads_networks.helper")

local M = {NAME = "poki"}
-- Extention: https://github.com/defold/extension-poki-sdk

---@class poki_rewarded_params
---@field size string|nil
---@field start_callback function|nil

---@class poki_interstitial_params
---@field start_callback function|nil

---@class poki_operation
---@field callback ads_callback|nil
---@field params table

local parameters = {}
local is_poki_initialized = false
---@type "rewarded"|"interstitial"|nil
local fullscreen_owner = nil
---@type table<string, poki_operation|nil>
local pending = {
    rewarded = nil,
    interstitial = nil,
}

---@param extra table|nil
---@return table
local function response_data(extra)
    local data = extra or {}
    data.networkName = M.NAME
    return data
end

---@param message string|nil
---@return ads_response
local function success_response(message)
    return helper.success(message, response_data())
end

---@param message string
---@return ads_response
local function error_response(message)
    local response = helper.error(message)
    response.data = response_data(response.data)
    return response
end

---@param message string
---@return ads_response
local function skipped_response(message)
    local response = helper.skipped(message)
    response.data = response_data(response.data)
    return response
end

---@param callback ads_callback|nil
---@param response ads_response
local function defer(callback, response)
    if callback then
        timer.delay(0, false, function()
            callback(response)
        end)
    end
end

---@param format "rewarded"|"interstitial"
---@param operation poki_operation
---@param response ads_response
local function finish(format, operation, response)
    -- The identity check prevents a late SDK event from completing a newer request
    -- after ads_controller has timed out and cancelled the old one.
    if pending[format] ~= operation then
        return
    end

    pending[format] = nil
    if fullscreen_owner == format then
        fullscreen_owner = nil
    end

    -- Clear adapter state before any downstream wrapper/controller code runs.
    defer(operation.callback, response)
end

---@param callback function|nil
local function invoke_start_callback(callback)
    if not callback then
        return
    end
    local ok, err = pcall(callback)
    if not ok then
        print("POKI: start callback failed: " .. tostring(err))
    end
end

---@return boolean
function M.is_supported()
    local ok, supported = pcall(function()
        return html5 ~= nil and poki_sdk ~= nil
    end)
    return ok and supported == true
end

---@param params table|nil
function M.setup(params)
    if pending.rewarded then
        finish("rewarded", pending.rewarded, error_response("Poki adapter was reset"))
    end
    if pending.interstitial then
        finish("interstitial", pending.interstitial, error_response("Poki adapter was reset"))
    end
    parameters = params or {}
    is_poki_initialized = false
    fullscreen_owner = nil
end

---@param callback ads_callback|nil
function M.init(callback)
    if is_poki_initialized then
        defer(callback, success_response("Poki SDK already initialized"))
        return
    end
    if not M.is_supported() then
        defer(callback, error_response("Poki SDK not supported"))
        return
    end

    if parameters.is_debug then
        local ok, err = pcall(poki_sdk.set_debug, true)
        if not ok then
            defer(callback, error_response("Unable to enable Poki debug mode: " .. tostring(err)))
            return
        end
    end

    -- The Poki HTML template initializes the JavaScript SDK before Defold starts.
    is_poki_initialized = true
    defer(callback, success_response("Poki SDK initialized"))
end

---@return boolean
function M.is_initialized()
    return is_poki_initialized
end

---@param format "rewarded"|"interstitial"
---@param callback ads_callback|nil
---@param params table|nil
---@return poki_operation|nil
local function begin_show(format, callback, params)
    if not M.is_supported() then
        defer(callback, error_response("Poki SDK not supported"))
        return nil
    end
    if not is_poki_initialized then
        defer(callback, error_response("Poki SDK not initialized"))
        return nil
    end
    if fullscreen_owner or pending[format] then
        defer(callback, error_response("Poki fullscreen break already in progress"))
        return nil
    end

    local operation = {
        callback = callback,
        params = params or {},
    }
    pending[format] = operation
    fullscreen_owner = format
    return operation
end

---@param callback ads_callback|nil
---@param params poki_rewarded_params|nil
function M.show_rewarded(callback, params)
    local operation = begin_show("rewarded", callback, params)
    if not operation then
        return
    end

    local function on_event(self, status)
        if pending.rewarded ~= operation then
            return
        end
        if status == poki_sdk.REWARDED_BREAK_START then
            invoke_start_callback(operation.params.start_callback)
        elseif status == poki_sdk.REWARDED_BREAK_SUCCESS or status == true then
            finish("rewarded", operation, success_response("Poki rewarded break completed"))
        elseif status == poki_sdk.REWARDED_BREAK_ERROR then
            finish("rewarded", operation, error_response("Poki rewarded break failed"))
        elseif status == false then
            -- Compatibility with Poki extension versions that returned a reward boolean.
            finish("rewarded", operation, skipped_response("Poki rewarded break skipped"))
        else
            finish("rewarded", operation,
                error_response("Unhandled Poki rewarded status: " .. tostring(status)))
        end
    end

    local ok, err
    if operation.params.size then
        ok, err = pcall(poki_sdk.rewarded_break, operation.params.size, on_event)
    else
        ok, err = pcall(poki_sdk.rewarded_break, on_event)
    end
    if not ok then
        finish("rewarded", operation, error_response("Unable to request Poki rewarded break: " .. tostring(err)))
    end
end

---@param callback ads_callback|nil
function M.load_rewarded(callback)
    if M.is_rewarded_loaded() then
        defer(callback, success_response("Poki rewarded break ready"))
    else
        defer(callback, error_response("Poki rewarded break unavailable"))
    end
end

---@return boolean
function M.is_rewarded_loaded()
    return is_poki_initialized and M.is_supported()
end

---@param operation string|nil
---@param reason string|nil
function M.cancel_rewarded(operation, reason)
    if operation ~= nil and operation ~= "show" then
        return
    end
    local active = pending.rewarded
    if active then
        pending.rewarded = nil
        if fullscreen_owner == "rewarded" then
            fullscreen_owner = nil
        end
    end
end

---@param callback ads_callback|nil
---@param params poki_interstitial_params|nil
function M.show_interstitial(callback, params)
    local operation = begin_show("interstitial", callback, params)
    if not operation then
        return
    end

    local function on_event(self, status)
        if pending.interstitial ~= operation then
            return
        end
        if status == poki_sdk.COMMERCIAL_BREAK_START then
            invoke_start_callback(operation.params.start_callback)
        elseif status == poki_sdk.COMMERCIAL_BREAK_SUCCESS or status == nil then
            -- Success means the break opportunity completed; Poki may choose not to show an ad.
            finish("interstitial", operation, success_response("Poki commercial break completed"))
        else
            finish("interstitial", operation,
                error_response("Unhandled Poki commercial status: " .. tostring(status)))
        end
    end

    local ok, err = pcall(poki_sdk.commercial_break, on_event)
    if not ok then
        finish("interstitial", operation,
            error_response("Unable to request Poki commercial break: " .. tostring(err)))
    end
end

---@param callback ads_callback|nil
function M.load_interstitial(callback)
    if M.is_interstitial_loaded() then
        defer(callback, success_response("Poki commercial break ready"))
    else
        defer(callback, error_response("Poki commercial break unavailable"))
    end
end

---@return boolean
function M.is_interstitial_loaded()
    return is_poki_initialized and M.is_supported()
end

---@param operation string|nil
---@param reason string|nil
function M.cancel_interstitial(operation, reason)
    if operation ~= nil and operation ~= "show" then
        return
    end
    local active = pending.interstitial
    if active then
        pending.interstitial = nil
        if fullscreen_owner == "interstitial" then
            fullscreen_owner = nil
        end
    end
end

---@return boolean
function M.is_banner_setup()
    return false
end

---@param callback ads_callback|nil
function M.load_banner(callback)
    defer(callback, error_response("Poki banner not supported"))
end

---@param callback ads_callback|nil
function M.unload_banner(callback)
    defer(callback, error_response("Poki banner not supported"))
end

---@return boolean
function M.is_banner_loaded()
    return false
end

---@param callback ads_callback|nil
function M.show_banner(callback)
    defer(callback, error_response("Poki banner not supported"))
end

---@param callback ads_callback|nil
function M.hide_banner(callback)
    defer(callback, error_response("Poki banner not supported"))
end

---@return boolean
function M.is_banner_showed()
    return false
end

return M

