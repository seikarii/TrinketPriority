-- Main dispatch test: BAG_UPDATE bursts are ignored; settled update rebuilds once.
local registered, invalidations, refreshes = {}, 0, 0
local frame = { scripts = {} }
function frame:RegisterEvent(event) registered[event] = true end
function frame:SetScript(name, callback) self.scripts[name] = callback end
CreateFrame = function() return frame end
TrinketPriority = {
  ADDON_NAME = "TrinketPriority",
  Priority = { frame = {}, RefreshOverlayState = function() refreshes = refreshes + 1 end,
    HasPendingRequest = function() return false end, HasPendingManualRequest = function() return false end,
    CancelTimer = function() end, ScheduleRequest = function() end },
  Inventory = { InvalidateSnapshot = function() invalidations = invalidations + 1 end },
  Commands = { Register = function() end },
}
dofile("Main.lua")
assert(not registered.BAG_UPDATE and registered.BAG_UPDATE_DELAYED)
local onEvent = frame.scripts.OnEvent
-- BAG_UPDATE may fire once per source/destination bag. It is not our settled update point.
for i = 1, 6 do onEvent(frame, "BAG_UPDATE", i) end
assert(invalidations == 0 and refreshes == 0)
onEvent(frame, "BAG_UPDATE_DELAYED")
assert(invalidations == 1 and refreshes == 1)
print("Settled inventory event tests passed.")
