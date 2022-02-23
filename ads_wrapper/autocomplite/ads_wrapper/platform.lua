---@class platform
local platform = {}

platform.PL_ANDROID = hash("PL_ANDROID")
platform.PL_IOS = hash("PL_IOS")
platform.PL_HTML5 = hash("PL_HTML5")
platform.PL_OTHER = hash("PL_OTHER")

---Сheck if the platform is correct
---@param value hash
---@return boolean
function platform.is_same(value)
end

---Returns current hash platform
---@return number|userdata
function platform.get()
end

return platform
