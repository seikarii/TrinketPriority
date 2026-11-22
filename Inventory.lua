local TP = TrinketPriority
TP.Inventory = {}

local Inventory = TP.Inventory
local snapshot

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

function Inventory.InvalidateSnapshot() snapshot = nil end

function Inventory.GetSnapshot()
  if snapshot then return snapshot end
  local data = { equipped = {}, byItemID = {} }
  for _, slot in ipairs({ 13, 14 }) do data.equipped[slot] = TP.ItemID(TP.InventoryLink(slot)) end
  for bag = 0, 4 do
    local count = ContainerNumSlots(bag) or 0
    for slot = 1, count do
      local id = TP.ItemID(ContainerItemLink(bag, slot))
      if id and not data.byItemID[id] then data.byItemID[id] = { bag = bag, slot = slot } end
    end
  end
  snapshot = data
  return snapshot
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

function Inventory.BagInfo(bag, slot)
  local link = ContainerItemLink(bag, slot)
  local id = TP.ItemID(link)
  if not id then return nil end
  return id, TP.ItemName(link, id), link
end

function Inventory.FindBagItem(id)
  local item = Inventory.GetSnapshot().byItemID[id]
  if item then return item.bag, item.slot end
  return nil
end

function Inventory.BagCooldown(bag, slot)
  local startTime, duration = ContainerItemCooldown(bag, slot)
  return TP.RemainingCooldown(startTime, duration)
end

function Inventory.IsEquippedInSlot13(id)
  return Inventory.GetSnapshot().equipped[13] == id
end

function Inventory.EquipItem(id)
  id = tonumber(id)
  if not id then return false end
  Inventory.InvalidateSnapshot()
  local bag, slot = Inventory.FindBagItem(id)
  if bag then
    if not CursorHasItemCompat() then
      ClearCursorCompat()
      PickupContainerItemCompat(bag, slot)
      if CursorHasItemCompat() then EquipCursorAtSlot(13) end
      if CursorHasItemCompat() then ClearCursorCompat() end
    end
    Inventory.InvalidateSnapshot()
    return not CursorHasItemCompat() and TP.ItemID(TP.InventoryLink(13)) == id
  end

  local id14 = TP.ItemID(TP.InventoryLink(14))
  if id14 == id then
    ClearCursorCompat()
    if PickupInventoryItem then PickupInventoryItem(14) end
    if CursorHasItemCompat() then EquipCursorAtSlot(13) end
    if CursorHasItemCompat() then ClearCursorCompat() end
    Inventory.InvalidateSnapshot()
    return not CursorHasItemCompat() and TP.ItemID(TP.InventoryLink(13)) == id
  end

  Inventory.InvalidateSnapshot()
  return false
end

function Inventory.GetBagCooldownInfo(bag, slot)
  return ContainerItemCooldown(bag, slot)
end
