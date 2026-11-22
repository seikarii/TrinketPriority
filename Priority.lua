local TP = TrinketPriority
TP.Priority = {}

local Priority = TP.Priority
local Inventory = TP.Inventory
local pending = false
local elapsedPending = 0

local function CancelPendingTimer()
  elapsedPending = 0
  Priority.frame:SetScript("OnUpdate", nil)
end

local function FindAvailableUseTrinket()
  local equipped14 = TP.ItemID(TP.InventoryLink(14))
  for i = 1, table.getn(TrinketPriorityDB.use) do
    local entry = TrinketPriorityDB.use[i]
    if entry and entry.id and not Inventory.IsEquippedInSlot13(entry.id) then
      if equipped14 == entry.id then
        if TP.InventoryCooldown(14) <= 30 then return entry end
      else
        local bag, bagSlot = Inventory.FindBagItem(entry.id)
        if bag then
          local cooldown = Inventory.BagCooldown(bag, bagSlot)
          if cooldown <= 30 then return entry end
        end
      end
    end
  end
  return nil
end

local function FindPassiveTrinket()
  local passive = TrinketPriorityDB.passive
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

  for i = 1, table.getn(TrinketPriorityDB.use) do
    local entry = TrinketPriorityDB.use[i]
    if entry and entry.id == id13 then
      return TP.InventoryCooldown(13) > 30
    end
  end
  return false
end

function Priority.ProcessRequest()
  if TP.IsPlayerInCombat() then
    pending = true
    return
  end
  if TP.IsPlayerDeadOrGhost() then
    pending = true
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
end

function Priority.CancelTimer()
  CancelPendingTimer()
end

function Priority.HasPendingRequest()
  return pending
end

function Priority.ScheduleRequest()
  if not pending then return end
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
