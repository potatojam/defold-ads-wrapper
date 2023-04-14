local M = {}

-- constants
M.PL_ANDROID = hash("PL_ANDROID")
M.PL_IOS = hash("PL_IOS")
M.PL_HTML5 = hash("PL_HTML5")
M.PL_OTHER = hash("PL_OTHER")

local platform = nil

local text_platform = sys.get_sys_info().system_name
if text_platform == "Android" then
    sys.set_connectivity_host("www.google.com")
    platform = M.PL_ANDROID
elseif text_platform == "iPhone OS" then
    sys.set_connectivity_host("www.apple.com")
    platform = M.PL_IOS
elseif text_platform == "HTML5" then
    platform = M.PL_HTML5
else
    platform = M.PL_OTHER
end

---Check if the platform is correct
---@param value hash
---@return boolean
function M.is_same(value)
    return platform == value
end

---Returns current hash platform
---@return hash
function M.get()
    return platform
end

return M
