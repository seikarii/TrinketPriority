-- Main dispatch test: BAG_UPDATE bursts are ignored; settled update rebuilds once.
local registered, invalidations, refreshes, itemResults = {}, 0, 0, 0
local timers = {}
local frame = { scripts = {} }
function frame:RegisterEvent(event) registered[event] = true end
function frame:SetScript(name, callback) self.scripts[name] = callback end
CreateFrame = function() return frame end
_G.C_Timer = { After = function(_, callback) timers[#timers + 1] = callback end }
TrinketPriority = {
  ADDON_NAME = "TrinketPriority",
  Priority = { frame = {}, RefreshOverlayState = function() refreshes = refreshes + 1 end,
    HasPendingRequest = function() return false end, HasPendingManualRequest = function() return false end,
    CancelTimer = function() end, ScheduleRequest = function() end },
  Inventory = { InvalidateSnapshot = function() invalidations = invalidations + 1 end },
  Overlay = { OnItemDataLoadResult = function(id, success) itemResults = itemResults + 1 end },
  Commands = { Register = function() end },
}
dofile("Main.lua")
assert(not registered.BAG_UPDATE and registered.BAG_UPDATE_DELAYED)
assert(registered.PLAYER_EQUIPMENT_CHANGED and registered.UNIT_INVENTORY_CHANGED)
assert(registered.ITEM_DATA_LOAD_RESULT)
local onEvent = frame.scripts.OnEvent
-- BAG_UPDATE may fire once per source/destination bag. It is not our settled update point.
for i = 1, 6 do onEvent(frame, "BAG_UPDATE", i) end
assert(invalidations == 0 and refreshes == 0)
onEvent(frame, "BAG_UPDATE_DELAYED")
onEvent(frame, "PLAYER_EQUIPMENT_CHANGED", 13)
onEvent(frame, "UNIT_INVENTORY_CHANGED", "player")
assert(invalidations == 0 and refreshes == 0 and #timers == 1)
timers[1]()
assert(invalidations == 1 and refreshes == 1)
onEvent(frame, "ITEM_DATA_LOAD_RESULT", 123, true)
assert(itemResults == 1 and invalidations == 1 and refreshes == 1)
onEvent(frame, "SPELL_UPDATE_COOLDOWN")
assert(invalidations == 1 and refreshes == 2)
onEvent(frame, "BAG_UPDATE_COOLDOWN")
assert(invalidations == 1 and refreshes == 3)
print("Settled inventory event tests passed.")
