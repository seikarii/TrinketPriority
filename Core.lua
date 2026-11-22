TrinketPriority = TrinketPriority or {}

local TP = TrinketPriority

TP.ADDON_NAME = "TrinketPriority"
TP.USE_MAX = 7
TP.COMBAT_DELAY = 0.1

TrinketPriorityDB = TrinketPriorityDB or {}
if type(TrinketPriorityDB.use) ~= "table" then TrinketPriorityDB.use = {} end

function TP.Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99TrinketPriority|r: " .. tostring(msg))
end

function TP.ItemID(link)
  if not link then return nil end
  local id = tonumber(string.match(link, "item:(%d+)"))
  if not id then id = tonumber(string.match(link, "Hitem:(%d+)")) end
  return id
end

function TP.ItemName(link, id)
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

function TP.InventoryLink(slot)
  return GetInventoryItemLink("player", slot)
end

function TP.InventoryInfo(slot)
  local link = TP.InventoryLink(slot)
  local id = TP.ItemID(link)
  if not id then return nil end
  return id, TP.ItemName(link, id), link
end

function TP.RemainingCooldown(startTime, duration)
  if not startTime or not duration or duration <= 0 then return 0 end
  local remaining = duration - (GetTime() - startTime)
  if remaining < 0 then return 0 end
  return remaining
end

function TP.InventoryCooldown(slot)
  local startTime, duration = GetInventoryItemCooldown("player", slot)
  return TP.RemainingCooldown(startTime, duration)
end

function TP.IsPlayerInCombat()
  if UnitAffectingCombat then
    return UnitAffectingCombat("player")
  end
  return false
end

function TP.IsPlayerDeadOrGhost()
  if UnitIsDeadOrGhost then
    return UnitIsDeadOrGhost("player")
  end
  return false
end
