local ADDON_NAME = "Trinket Priority"
local USE_MAX = 7
local COMBAT_DELAY = 0.8

TrinketPriorityDB = TrinketPriorityDB or {}
if type(TrinketPriorityDB.use) ~= "table" then TrinketPriorityDB.use = {} end
TrinketPriorityDB.passive = TrinketPriorityDB.passive

local frame = CreateFrame("Frame", "TrinketPriorityFrame")
local pending = false
local elapsedPending = 0

local ui = CreateFrame("Frame", "TrinketPriorityOptions", UIParent)
ui:SetWidth(420)
ui:SetHeight(430)
ui:SetPoint("CENTER")
ui:SetMovable(true)
ui:EnableMouse(true)
ui:RegisterForDrag("LeftButton")
ui:SetScript("OnDragStart", function() ui:StartMoving() end)
ui:SetScript("OnDragStop", function() ui:StopMovingOrSizing() end)
ui:Hide()

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99TrinketPriority|r: " .. tostring(msg))
end

local function ItemID(link)
  if not link then return nil end
  local id = tonumber(string.match(link, "item:(%d+)"))
  if not id then id = tonumber(string.match(link, "Hitem:(%d+)")) end
  return id
end

local function ItemName(link, id)
  if link then
    local name
    if C_Item and C_Item.GetItemInfo then
      name = C_Item.GetItemInfo(id)
    elseif GetItemInfo then
      name = GetItemInfo(id)
    end
    if name then return name end
    local coloredName = string.match(link, "%[(.-)%]")
    if coloredName then return coloredName end
  end
  return tostring(id or "Unknown")
end

local function InventoryLink(slot)
  return GetInventoryItemLink("player", slot)
end

local function InventoryInfo(slot)
  local link = InventoryLink(slot)
  local id = ItemID(link)
  if not id then return nil end
  return id, ItemName(link, id), link
end

local function ContainerNumSlots(bag)
  if C_Container and C_Container.GetContainerNumSlots then
    return C_Container.GetContainerNumSlots(bag)
  elseif GetContainerNumSlots then
    return GetContainerNumSlots(bag)
  end
  return 0
end

local function ContainerItemLink(bag, slot)
  if C_Container and C_Container.GetContainerItemLink then
    return C_Container.GetContainerItemLink(bag, slot)
  elseif GetContainerItemLink then
    return GetContainerItemLink(bag, slot)
  end
  return nil
end

local function ContainerItemCooldown(bag, slot)
  if C_Container and C_Container.GetContainerItemCooldown then
    return C_Container.GetContainerItemCooldown(bag, slot)
  elseif GetContainerItemCooldown then
    return GetContainerItemCooldown(bag, slot)
  end
  return 0, 0
end

local function PickupContainerItemCompat(bag, slot)
  if C_Container and C_Container.PickupContainerItem then
    C_Container.PickupContainerItem(bag, slot)
  elseif PickupContainerItem then
    PickupContainerItem(bag, slot)
  end
end

local function BagInfo(bag, slot)
  local link = ContainerItemLink(bag, slot)
  local id = ItemID(link)
  if not id then return nil end
  return id, ItemName(link, id), link
end

local function FindBagItem(id)
  for bag = 0, 4 do
    local numSlots = ContainerNumSlots(bag)
    if numSlots then
      for slot = 1, numSlots do
        local bagId = BagInfo(bag, slot)
        if bagId == id then return bag, slot end
      end
    end
  end
  return nil
end

local function RemainingCooldown(startTime, duration)
  if not startTime or not duration or duration <= 0 then return 0 end
  local remaining = duration - (GetTime() - startTime)
  if remaining < 0 then return 0 end
  return remaining
end

local function InventoryCooldown(slot)
  local startTime, duration = GetInventoryItemCooldown("player", slot)
  return RemainingCooldown(startTime, duration)
end

local function BagCooldown(bag, slot)
  local startTime, duration = ContainerItemCooldown(bag, slot)
  return RemainingCooldown(startTime, duration)
end

local function AddEntry(list, id, name)
  for i = 1, table.getn(list) do
    if list[i].id == id then return false end
  end
  table.insert(list, { id = id, name = name })
  return true
end

local function AddUseFromSlot(slot)
  if table.getn(TrinketPriorityDB.use) >= USE_MAX then
    Print("La lista de uso ya tiene " .. USE_MAX .. " trinkets.")
    return
  end
  local id, name = InventoryInfo(slot)
  if not id then
    Print("No hay trinket equipado en el hueco " .. slot .. ".")
    return
  end
  if AddEntry(TrinketPriorityDB.use, id, name) then
    Print("Añadido a uso: " .. name)
  else
    Print(name .. " ya está en la lista de uso.")
  end
  RefreshUI()
end

local function SetPassiveFromSlot(slot)
  local id, name = InventoryInfo(slot)
  if not id then
    Print("No hay trinket equipado en el hueco " .. slot .. ".")
    return
  end
  TrinketPriorityDB.passive = { id = id, name = name }
  Print("Pasivo establecido: " .. name)
  RefreshUI()
end

local function RemoveUse(index)
  if TrinketPriorityDB.use[index] then
    table.remove(TrinketPriorityDB.use, index)
    RefreshUI()
  end
end

local function MoveUse(index, delta)
  local target = index + delta
  if index < 1 or index > table.getn(TrinketPriorityDB.use) then return end
  if target < 1 or target > table.getn(TrinketPriorityDB.use) then return end
  TrinketPriorityDB.use[index], TrinketPriorityDB.use[target] = TrinketPriorityDB.use[target], TrinketPriorityDB.use[index]
  RefreshUI()
end

local function EquipInventorySlot(slot)
  if slot == 13 or slot == 14 then
    local id = ItemID(GetInventoryItemLink("player", slot))
    if id then
      return slot, id
    end
  end
  return nil
end

local function ClearCursorCompat()
  if ClearCursor then ClearCursor() end
end

local function CursorHasItemCompat()
  if CursorHasItem then return CursorHasItem() end
  return false
end

local function EquipCursorAtSlot(slot)
  if C_PaperDollInfo and C_PaperDollInfo.EquipCursorItem then
    C_PaperDollInfo.EquipCursorItem(slot)
  elseif EquipCursorItem then
    EquipCursorItem(slot)
  elseif PickupInventoryItem then
    PickupInventoryItem(slot)
  end
end

local function EquipItem(id)
  local bag, slot = FindBagItem(id)
  if bag then
    ClearCursorCompat()
    PickupContainerItemCompat(bag, slot)
    if CursorHasItemCompat() then EquipCursorAtSlot(13) end
    if CursorHasItemCompat() then ClearCursorCompat() end
    return true
  end

  local id14 = ItemID(InventoryLink(14))
  if id14 == id then
    ClearCursorCompat()
    if PickupInventoryItem then PickupInventoryItem(14) end
    if CursorHasItemCompat() then EquipCursorAtSlot(13) end
    if CursorHasItemCompat() then ClearCursorCompat() end
    return true
  end

  return false
end

local function IsInInventory13(id)
  local id13 = ItemID(InventoryLink(13))
  return id13 == id
end

local function FindAvailableUseTrinket()
  local equipped14 = ItemID(InventoryLink(14))
  for i = 1, table.getn(TrinketPriorityDB.use) do
    local entry = TrinketPriorityDB.use[i]
    if not entry or not entry.id then
      -- skip malformed entries
    elseif not IsInInventory13(entry.id) then
      local in14 = (equipped14 == entry.id)
      if in14 then
        if InventoryCooldown(14) <= 30 then return entry end
      else
        local bag, bagSlot = FindBagItem(entry.id)
        if bag then
          local cooldown = BagCooldown(bag, bagSlot)
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
  if IsInInventory13(passive.id) then return nil end
  if FindBagItem(passive.id) or ItemID(InventoryLink(14)) == passive.id then
    return passive
  end
  return nil
end

local function CurrentTrinketWasUsed()
  local id13 = ItemID(InventoryLink(13))
  if not id13 then return false end
  for i = 1, table.getn(TrinketPriorityDB.use) do
    local entry = TrinketPriorityDB.use[i]
    if entry and entry.id == id13 then
      local cooldown = InventoryCooldown(13)
      if cooldown > 0 then return true end
    end
  end
  return false
end

local function ProcessTrinketRequest()
  if UnitAffectingCombat and UnitAffectingCombat("player") then
    pending = true
    return
  end
  if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
    Print("No se puede cambiar trinkets mientras estás muerto.")
    pending = false
    return
  end

  if not CurrentTrinketWasUsed() then
    pending = false
    return
  end

  local candidate = FindAvailableUseTrinket()
  if candidate then
    if EquipItem(candidate.id) then
      Print("Equipado por priority: " .. (candidate.name or tostring(candidate.id)))
    else
      Print("No se encontró el trinket en bolsas/huecos.")
    end
  else
    local passive = FindPassiveTrinket()
    if passive then
      if EquipItem(passive.id) then
        Print("Equipado pasivo: " .. (passive.name or tostring(passive.id)))
      else
        Print("No se encontró el trinket pasivo.")
      end
    else
      Print("Todos los trinkets disponibles están en cd y no hay pasivo disponible.")
    end
  end

  pending = false
end

local function RequestTrinket()
  if UnitAffectingCombat and UnitAffectingCombat("player") then
    pending = true
    Print("Cambio diferido hasta salir de combate.")
    return
  end
  if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
    Print("No se puede cambiar trinkets mientras estás muerto.")
    return
  end

  elapsedPending = 0
  pending = true
  frame:SetScript("OnUpdate", function(self, elapsed)
    elapsedPending = elapsedPending + elapsed
    if elapsedPending >= COMBAT_DELAY then
      frame:SetScript("OnUpdate", nil)
      ProcessTrinketRequest()
    end
  end)
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "TrinketPriority" then
    TrinketPriorityDB.use = TrinketPriorityDB.use or {}
  elseif event == "PLAYER_REGEN_ENABLED" and pending then
    elapsedPending = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
      elapsedPending = elapsedPending + elapsed
      if elapsedPending >= COMBAT_DELAY then
        frame:SetScript("OnUpdate", nil)
        ProcessTrinketRequest()
      end
    end)
  end
end)

SLASH_TRINKET1 = "/trinket"
SLASH_TRINKET2 = "/trinkets"
SlashCmdList["TRINKET"] = function(msg)
  local command, rest = string.match(msg or "", "^(%S*)%s*(.*)$")
  command = string.lower(command or "")
  rest = string.lower(rest or "")

  if command == "" or command == "go" then
    RequestTrinket()
  elseif command == "adduse" then
    local slot = tonumber(rest)
    if slot ~= 13 and slot ~= 14 then Print("Uso: /trinket adduse 13|14") else AddUseFromSlot(slot) end
  elseif command == "passive" then
    local slot = tonumber(rest)
    if slot ~= 13 and slot ~= 14 then Print("Uso: /trinket passive 13|14") else SetPassiveFromSlot(slot) end
  elseif command == "removeuse" then
    RemoveUse(tonumber(rest))
  elseif command == "removepassive" then
    TrinketPriorityDB.passive = nil
    Print("Pasivo eliminado.")
    RefreshUI()
  elseif command == "up" then
    MoveUse(tonumber(rest), -1)
  elseif command == "down" then
    MoveUse(tonumber(rest), 1)
  elseif command == "clear" then
    TrinketPriorityDB.use = {}
    TrinketPriorityDB.passive = nil
    Print("Listas eliminadas.")
    RefreshUI()
  elseif command == "list" or command == "status" then
    Print("Trinkets de uso:")
    for i = 1, table.getn(TrinketPriorityDB.use) do
      local entry = TrinketPriorityDB.use[i]
      Print(i .. ". " .. (entry.name or tostring(entry.id)))
    end
    if TrinketPriorityDB.passive then
      Print("Pasivo: " .. (TrinketPriorityDB.passive.name or tostring(TrinketPriorityDB.passive.id)))
    else
      Print("Pasivo: ninguno")
    end
  elseif command == "options" or command == "ui" then
    ToggleUI()
  elseif command == "help" then
    Print("/trinket - ejecuta priority")
    Print("/trinket adduse 13|14 - añade equipado")
    Print("/trinket passive 13|14 - establece pasivo")
    Print("/trinket removeuse N - elimina prioridad N")
    Print("/trinket removepassive - elimina pasivo")
    Print("/trinket up|down N - mueve una prioridad")
    Print("/trinket list - muestra listas")
  else
    ToggleUI()
  end
end

local function CreateButton(parent, text, width, height)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetWidth(width)
  button:SetHeight(height)
  button:SetText(text)
  return button
end

local title = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -18)
title:SetText("Trinket Priority")

local add13 = CreateButton(ui, "Añadir hueco 13", 125, 24)
add13:SetPoint("TOPLEFT", 25, -50)
add13:SetScript("OnClick", function() AddUseFromSlot(13) end)

local add14 = CreateButton(ui, "Añadir hueco 14", 125, 24)
add14:SetPoint("LEFT", add13, "RIGHT", 8, 0)
add14:SetScript("OnClick", function() AddUseFromSlot(14) end)

local close = CreateButton(ui, "Cerrar", 70, 24)
close:SetPoint("TOPRIGHT", -20, -18)
close:SetScript("OnClick", function() ui:Hide() end)

local useTitle = ui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
useTitle:SetPoint("TOPLEFT", 25, -82)
useTitle:SetText("Prioridad de uso (1 = mayor)")

local rows = {}
for i = 1, USE_MAX do
  local row = CreateFrame("Frame", nil, ui)
  row:SetWidth(370)
  row:SetHeight(24)
  row:SetPoint("TOPLEFT", 25, -104 - (i - 1) * 27)

  row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.text:SetPoint("LEFT", 20, 0)
  row.text:SetWidth(210)
  row.text:SetJustifyH("LEFT")

  row.number = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.number:SetPoint("LEFT", 0, 0)
  row.number:SetText(i .. ".")

  row.up = CreateButton(row, "^", 24, 20)
  row.up:SetPoint("RIGHT", -56, 0)
  row.up:SetScript("OnClick", function() MoveUse(i, -1) end)

  row.down = CreateButton(row, "v", 24, 20)
  row.down:SetPoint("LEFT", row.up, "RIGHT", 2, 0)
  row.down:SetScript("OnClick", function() MoveUse(i, 1) end)

  row.remove = CreateButton(row, "X", 24, 20)
  row.remove:SetPoint("LEFT", row.down, "RIGHT", 2, 0)
  row.remove:SetScript("OnClick", function() RemoveUse(i) end)

  rows[i] = row
end

local passiveTitle = ui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
passiveTitle:SetPoint("TOPLEFT", 25, -302)
passiveTitle:SetText("Fallback pasivo")

local passiveText = ui:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
passiveText:SetPoint("TOPLEFT", 25, -325)
passiveText:SetWidth(250)
passiveText:SetJustifyH("LEFT")

local passive13 = CreateButton(ui, "13", 55, 22)
passive13:SetPoint("TOPRIGHT", -78, -318)
passive13:SetScript("OnClick", function() SetPassiveFromSlot(13) end)

local passive14 = CreateButton(ui, "14", 55, 22)
passive14:SetPoint("LEFT", passive13, "RIGHT", 4, 0)
passive14:SetScript("OnClick", function() SetPassiveFromSlot(14) end)

local removePassive = CreateButton(ui, "Eliminar pasivo", 115, 22)
removePassive:SetPoint("TOPLEFT", 25, -356)
removePassive:SetScript("OnClick", function()
  TrinketPriorityDB.passive = nil
  Print("Pasivo eliminado.")
  RefreshUI()
end)

local clear = CreateButton(ui, "Limpiar todo", 115, 22)
clear:SetPoint("LEFT", removePassive, "RIGHT", 8, 0)
clear:SetScript("OnClick", function()
  TrinketPriorityDB.use = {}
  TrinketPriorityDB.passive = nil
  Print("Listas eliminadas.")
  RefreshUI()
end)

function RefreshUI()
  for i = 1, USE_MAX do
    local entry = TrinketPriorityDB.use[i]
    if entry then
      rows[i].text:SetText(entry.name or tostring(entry.id))
      rows[i].up:Show()
      rows[i].down:Show()
      rows[i].remove:Show()
    else
      rows[i].text:SetText("Vacío")
      rows[i].up:Hide()
      rows[i].down:Hide()
      rows[i].remove:Hide()
    end
  end
  if TrinketPriorityDB.passive then
    passiveText:SetText(TrinketPriorityDB.passive.name or tostring(TrinketPriorityDB.passive.id))
  else
    passiveText:SetText("Ninguno")
  end
end

function ToggleUI()
  if not ui then
    Print("La interfaz no se pudo cargar. Comprueba los errores Lua.")
    return
  end
  if ui:IsShown() then
    ui:Hide()
  else
    RefreshUI()
    ui:Show()
  end
end
