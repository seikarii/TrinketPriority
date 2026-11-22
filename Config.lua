local TP = TrinketPriority
TP.Config = {}

local Config = TP.Config

function Config.RefreshUI()
  if TP.UI and TP.UI.Refresh then TP.UI.Refresh() end
  if TP.Priority and TP.Priority.RefreshOverlayState then TP.Priority.RefreshOverlayState()
  elseif TP.Overlay and TP.Overlay.Refresh then TP.Overlay.Refresh() end
end

local function ActiveProfile()
  return TP.GetActiveProfile()
end

local function AddEntry(list, id, name)
  for i = 1, #list do
    if list[i].id == id then return false end
  end
  table.insert(list, { id = id, name = name })
  return true
end

function Config.AddUseFromSlot(slot)
  local profile = ActiveProfile()
  if #profile.use >= TP.USE_MAX then
    TP.Print("La lista de uso ya tiene " .. TP.USE_MAX .. " trinkets.")
    return
  end

  local id, name = TP.InventoryInfo(slot)
  if not id then
    TP.Print("No hay trinket equipado en el hueco " .. slot .. ".")
    return
  end

  if AddEntry(profile.use, id, name) then
    TP.Print("Añadido a uso: " .. name)
  else
    TP.Print(name .. " ya está en la lista de uso.")
  end
  Config.RefreshUI()
end

function Config.SetPassiveFromSlot(slot)
  local profile = ActiveProfile()
  local id, name = TP.InventoryInfo(slot)
  if not id then
    TP.Print("No hay trinket equipado en el hueco " .. slot .. ".")
    return
  end

  profile.passive = { id = id, name = name }
  TP.Print("Pasivo establecido: " .. name)
  Config.RefreshUI()
end

function Config.RemoveUse(index)
  if type(index) ~= "number" or index ~= math.floor(index) or index < 1 then return false end
  local profile = ActiveProfile()
  if profile.use[index] then
    table.remove(profile.use, index)
    Config.RefreshUI()
    return true
  end
  return false
end

function Config.MoveUse(index, delta)
  if type(index) ~= "number" or index ~= math.floor(index) or type(delta) ~= "number" or delta ~= math.floor(delta) then return false end
  local profile = ActiveProfile()
  local target = index + delta
  if index < 1 or index > #profile.use then return false end
  if target < 1 or target > #profile.use then return false end

  profile.use[index], profile.use[target] = profile.use[target], profile.use[index]
  Config.RefreshUI()
  return true
end

function Config.RemovePassive()
  ActiveProfile().passive = nil
  TP.Print("Pasivo eliminado.")
  Config.RefreshUI()
end

function Config.Clear()
  local profile = ActiveProfile()
  profile.use = {}
  profile.passive = nil
  TP.Print("Listas eliminadas en " .. TP.GetActiveProfileName() .. ".")
  Config.RefreshUI()
end

function Config.List()
  local profile = ActiveProfile()
  TP.Print("Perfil activo: " .. TP.GetActiveProfileName())
  TP.Print("Trinkets de uso:")
  for i = 1, #profile.use do
    local entry = profile.use[i]
    TP.Print(i .. ". " .. (entry.name or tostring(entry.id)))
  end

  if profile.passive then
    TP.Print("Pasivo: " .. (profile.passive.name or tostring(profile.passive.id)))
  else
    TP.Print("Pasivo: ninguno")
  end
end
