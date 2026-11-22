local TP = TrinketPriority

local frame = CreateFrame("Frame", "TrinketPriorityFrame")
TP.Priority.frame = frame

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("PLAYER_ALIVE")
frame:RegisterEvent("PLAYER_UNGHOST")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterEvent("BAG_UPDATE_COOLDOWN")

frame:SetScript("OnEvent", function(self, event, arg1)
  if event == "BAG_UPDATE" or event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED" or (event == "UNIT_INVENTORY_CHANGED" and arg1 == "player") then
    if TP.Inventory then TP.Inventory.InvalidateSnapshot() end
    if TP.Priority then TP.Priority.RefreshOverlayState() end
  elseif event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN" then
    if TP.Priority then TP.Priority.RefreshOverlayState() end
  elseif event == "ADDON_LOADED" and arg1 == TP.ADDON_NAME then
    TP.InitDatabase()
    if TP.Profiles and TP.Profiles.Refresh then TP.Profiles.Refresh() end
    if TP.Overlay and TP.Overlay.Initialize then TP.Overlay.Initialize() end
    if TP.UI and TP.UI.Refresh then TP.UI.Refresh() end
    if TP.Minimap and TP.Minimap.Initialize then TP.Minimap.Initialize() end
    TP.Priority.RefreshOverlayState()
  elseif event == "PLAYER_REGEN_DISABLED" then
    if TP.Priority.HasPendingRequest() or TP.Priority.HasPendingManualRequest() then TP.Priority.CancelTimer() end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if TP.Priority.HasPendingRequest() or TP.Priority.HasPendingManualRequest() then TP.Priority.ScheduleRequest() end
  elseif event == "PLAYER_DEAD" then
    if TP.Priority.HasPendingRequest() or TP.Priority.HasPendingManualRequest() then TP.Priority.CancelTimer() end
  elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
    if TP.Priority.HasPendingRequest() or TP.Priority.HasPendingManualRequest() then TP.Priority.ScheduleRequest() end
  end
end)

TP.Commands.Register()
