---@meta

---@alias ads_queue function[]

---@class ads_order
---@field id integer
---@field count integer|nil

---@class ads_mediator
---@field order ads_network[]
---@field networks table<integer, ads_network>
---@field current_network_num number
---@field repeater number
---@field repeat_num number

---@class ads_response
---@field result hash
---@field message string|nil
---@field data any|nil
---@field code hash|nil

---@alias ads_callback fun(response: ads_response)

local M = {}
return M
