local TP = TrinketPriority

local frame = CreateFrame("Frame", "TrinketPriorityFrame")
TP.Priority.frame = frame

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("PLAYER_ALIVE")
frame:RegisterEvent("PLAYER_UNGHOST")

frame:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == TP.ADDON_NAME then
    TrinketPriorityDB.use = TrinketPriorityDB.use or {}
    if TP.UI and TP.UI.Refresh then TP.UI.Refresh() end
  elseif event == "PLAYER_REGEN_DISABLED" then
    if TP.Priority.HasPendingRequest() then TP.Priority.CancelTimer() end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if TP.Priority.HasPendingRequest() then TP.Priority.ScheduleRequest() end
  elseif event == "PLAYER_DEAD" then
    if TP.Priority.HasPendingRequest() then TP.Priority.CancelTimer() end
  elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
    if TP.Priority.HasPendingRequest() then TP.Priority.ScheduleRequest() end
  end
end)

TP.Commands.Register()
