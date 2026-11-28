-- Configuration argument validation regression tests.
TrinketPriority = { USE_MAX = 10, GetActiveProfile = function() return profile end, GetActiveProfileName = function() return "Test" end, Print = function() end }
profile = { use = { { id = 1 }, { id = 2 } }, passive = nil }
TrinketPriority.UI = { Refresh = function() end }
TrinketPriority.Overlay = { Refresh = function() end }
dofile("Config.lua")
local C = TrinketPriority.Config
assert(C.MoveUse(nil, 1) == false)
assert(C.MoveUse("1", 1) == false)
assert(C.MoveUse(1, nil) == false)
assert(C.MoveUse(1, "1") == false)
assert(C.MoveUse(0, 1) == false)
assert(C.MoveUse(1, -1) == false)
assert(profile.use[1].id == 1)
assert(C.MoveUse(1, 1) == true and profile.use[2].id == 1)
assert(C.RemoveUse(nil) == false)
assert(C.RemoveUse(99) == false and #profile.use == 2)
assert(C.RemoveUse(1) == true and #profile.use == 1)
print("Configuration validation tests passed.")
