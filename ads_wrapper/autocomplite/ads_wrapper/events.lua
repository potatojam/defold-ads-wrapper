---@class events
local events = {}

events.ABORT = hash("ABORT")
events.SUCCESS = hash("SUCCESS")
events.ERROR = hash("ERROR")

events.C_SKIPPED = hash("R_SKIPPED")
events.C_ERROR_UNKNOWN = hash("C_ERROR_UNKNOWN")
events.C_ERROR_AD_BLOCK = hash("C_ERROR_AD_BLOCK")
events.C_ERROR_NO_CONNECTION = hash("C_ERROR_NO_CONNECTION")

events.V_NONE = hash("V_NONE")
events.V_ERROR = hash("V_ERRORS")
events.V_SUCCESS = hash("V_SUCCESS")
events.V_ALL = hash("V_ALL")

return events
