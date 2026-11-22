local TP = TrinketPriority
TP.Priority = {}

local Priority = TP.Priority
local Inventory = TP.Inventory
local pending = false
local elapsedPending = 0
local manualPending = false
local manualPendingId = nil
local manualPendingName = nil
Priority.TRINKET_COOLDOWN_THRESHOLD = 30 -- Conserva la ventana histórica de disponibilidad para swaps.

local function CancelPendingTimer()
  elapsedPending = 0
  Priority.frame:SetScript("OnUpdate", nil)
end

local function FindAvailableUseTrinket()
  local profile = TP.GetActiveProfile()
  local snapshot = Inventory.GetSnapshot()
  local equipped14 = snapshot.equipped[14]
  for i = 1, table.getn(profile.use) do
    local entry = profile.use[i]
    if entry and entry.id and not Inventory.IsEquippedInSlot13(entry.id) then
      if equipped14 == entry.id then
        if TP.InventoryCooldown(14) <= Priority.TRINKET_COOLDOWN_THRESHOLD then return entry end
      else
        local bag, bagSlot = Inventory.FindBagItem(entry.id)
        if bag then
          local cooldown = Inventory.BagCooldown(bag, bagSlot)
          if cooldown <= Priority.TRINKET_COOLDOWN_THRESHOLD then return entry end
        end
      end
    end
  end
  return nil
end

local function FindPassiveTrinket()
  local passive = TP.GetActiveProfile().passive
  if not passive or not passive.id then return nil end
  if Inventory.IsEquippedInSlot13(passive.id) then return nil end
  if Inventory.FindBagItem(passive.id) or TP.ItemID(TP.InventoryLink(14)) == passive.id then
    return passive
  end
  return nil
end

local function CurrentTrinketWasUsed()
  local id13 = TP.ItemID(TP.InventoryLink(13))
  if not id13 then return false end

  local profile = TP.GetActiveProfile()
  local passive = profile.passive
  if passive and passive.id == id13 then
    return true
  end

  for i = 1, table.getn(profile.use) do
    local entry = profile.use[i]
    if entry and entry.id == id13 then
      return TP.InventoryCooldown(13) > Priority.TRINKET_COOLDOWN_THRESHOLD
    end
  end

  -- A trinket outside the active lists has no usage condition: proceed to priority.
  return true
end

function Priority.ProcessRequest()
  if TP.IsPlayerInCombat() then
    if manualPending then
      pending = false
    else
      pending = true
    end
    return
  end
  if TP.IsPlayerDeadOrGhost() then
    if manualPending then
      pending = false
    else
      pending = true
    end
    return
  end

  if manualPending then
    local id = manualPendingId
    local name = manualPendingName
    manualPending = false
    manualPendingId = nil
    manualPendingName = nil
    pending = false

    if not id then
      Priority.RefreshOverlayState()
      return
    end

    local id13 = TP.ItemID(TP.InventoryLink(13))
    if id13 == id then
      TP.Print("Ya equipado: " .. (name or tostring(id)))
    elseif Inventory.EquipItem(id) then
      TP.Print("Equipado manualmente: " .. (name or tostring(id)))
    else
      TP.Print("No se encontró el trinket seleccionado en bolsas/huecos.")
    end

    Priority.RefreshOverlayState()
    return
  end

  if not CurrentTrinketWasUsed() then
    pending = false
    return
  end

  local candidate = FindAvailableUseTrinket()
  if candidate then
    if Inventory.EquipItem(candidate.id) then
      TP.Print("Equipado por priority: " .. (candidate.name or tostring(candidate.id)))
    else
      TP.Print("No se encontró el trinket en bolsas/huecos.")
    end
  else
    local passive = FindPassiveTrinket()
    if passive then
      if Inventory.EquipItem(passive.id) then
        TP.Print("Equipado pasivo: " .. (passive.name or tostring(passive.id)))
      else
        TP.Print("No se encontró el trinket pasivo.")
      end
    else
      TP.Print("Todos los trinkets disponibles están en cd y no hay pasivo disponible.")
    end
  end

  pending = false
  Priority.RefreshOverlayState() -- Refresh overlay state after processing priority
end

function Priority.CancelTimer()
  CancelPendingTimer()
end

function Priority.HasPendingRequest()
  return pending
end

function Priority.HasPendingManualRequest()
  return manualPending
end

function Priority.ScheduleRequest()
  if not pending and not manualPending then return end
  if TP.IsPlayerInCombat() or TP.IsPlayerDeadOrGhost() then
    CancelPendingTimer()
    return
  end

  elapsedPending = 0
  Priority.frame:SetScript("OnUpdate", function(self, elapsed)
    elapsedPending = elapsedPending + elapsed
    if elapsedPending >= TP.COMBAT_DELAY then
      CancelPendingTimer()
      Priority.ProcessRequest()
    end
  end)
end

function Priority.Request()
  if TP.IsPlayerDeadOrGhost() then
    pending = true
    CancelPendingTimer()
    TP.Print("Solicitud guardada. Se procesará al volver a estar vivo y fuera de combate.")
    return
  end
  if TP.IsPlayerInCombat() then
    pending = true
    CancelPendingTimer()
    TP.Print("Solicitud guardada. Cambio diferido hasta salir de combate.")
    return
  end

  pending = true
  Priority.ScheduleRequest()
end

function Priority.RequestManualEquip(id, name)
  id = tonumber(id)
  if not id then return false end

  pending = false
  CancelPendingTimer()

  if TP.IsPlayerInCombat() or TP.IsPlayerDeadOrGhost() then
    manualPending = true
    manualPendingId = id
    manualPendingName = name
    if TP.IsPlayerDeadOrGhost() then
      TP.Print("Solicitud manual guardada. Se equipará al volver a estar vivo y fuera de combate.")
    else
      TP.Print("Solicitud manual guardada. Se equipará al salir de combate.")
    end
    return true
  end

  manualPending = false
  manualPendingId = nil
  manualPendingName = nil

  local id13 = TP.ItemID(TP.InventoryLink(13))
  if id13 == id then
    TP.Print("Ya equipado: " .. (name or tostring(id)))
  elseif Inventory.EquipItem(id) then
    TP.Print("Equipado manualmente: " .. (name or tostring(id)))
  else
    TP.Print("No se encontró el trinket seleccionado en bolsas/huecos.")
  end

  Priority.RefreshOverlayState()
  return true
end

function Priority.GetNextUseCandidate()
  if not CurrentTrinketWasUsed() then return nil end
  return FindAvailableUseTrinket()
end

function Priority.RefreshOverlayState()
  Priority.cachedCandidate = Priority.GetNextUseCandidate()
  if TP.Overlay and TP.Overlay.Refresh then
    TP.Overlay.Refresh()
  end
end
