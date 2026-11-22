local TP = TrinketPriority
TP.Config = {}

local Config = TP.Config

function Config.RefreshUI()
  if TP.UI and TP.UI.Refresh then TP.UI.Refresh() end
end

local function AddEntry(list, id, name)
  for i = 1, table.getn(list) do
    if list[i].id == id then return false end
  end
  table.insert(list, { id = id, name = name })
  return true
end

function Config.AddUseFromSlot(slot)
  if table.getn(TrinketPriorityDB.use) >= TP.USE_MAX then
    TP.Print("La lista de uso ya tiene " .. TP.USE_MAX .. " trinkets.")
    return
  end

  local id, name = TP.InventoryInfo(slot)
  if not id then
    TP.Print("No hay trinket equipado en el hueco " .. slot .. ".")
    return
  end

  if AddEntry(TrinketPriorityDB.use, id, name) then
    TP.Print("Añadido a uso: " .. name)
  else
    TP.Print(name .. " ya está en la lista de uso.")
  end
  Config.RefreshUI()
end

function Config.SetPassiveFromSlot(slot)
  local id, name = TP.InventoryInfo(slot)
  if not id then
    TP.Print("No hay trinket equipado en el hueco " .. slot .. ".")
    return
  end

  TrinketPriorityDB.passive = { id = id, name = name }
  TP.Print("Pasivo establecido: " .. name)
  Config.RefreshUI()
end

function Config.RemoveUse(index)
  if TrinketPriorityDB.use[index] then
    table.remove(TrinketPriorityDB.use, index)
    Config.RefreshUI()
  end
end

function Config.MoveUse(index, delta)
  local target = index + delta
  if index < 1 or index > table.getn(TrinketPriorityDB.use) then return end
  if target < 1 or target > table.getn(TrinketPriorityDB.use) then return end

  TrinketPriorityDB.use[index], TrinketPriorityDB.use[target] =
    TrinketPriorityDB.use[target], TrinketPriorityDB.use[index]
  Config.RefreshUI()
end

function Config.RemovePassive()
  TrinketPriorityDB.passive = nil
  TP.Print("Pasivo eliminado.")
  Config.RefreshUI()
end

function Config.Clear()
  TrinketPriorityDB.use = {}
  TrinketPriorityDB.passive = nil
  TP.Print("Listas eliminadas.")
  Config.RefreshUI()
end

function Config.List()
  TP.Print("Trinkets de uso:")
  for i = 1, table.getn(TrinketPriorityDB.use) do
    local entry = TrinketPriorityDB.use[i]
    TP.Print(i .. ". " .. (entry.name or tostring(entry.id)))
  end

  if TrinketPriorityDB.passive then
    TP.Print("Pasivo: " .. (TrinketPriorityDB.passive.name or tostring(TrinketPriorityDB.passive.id)))
  else
    TP.Print("Pasivo: ninguno")
  end
end
