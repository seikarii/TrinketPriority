-- Priority selection smoke test for equipped and bag candidates.
local equipped = { [13] = "item:100", [14] = nil }
local bagItems = { [0] = { [1] = "item:200", [2] = "item:201" } }
UnitName = function() return "Test" end
GetRealmName = function() return "Realm" end
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
GetTime = function() return 1 end
GetInventoryItemLink = function(_, slot) return equipped[slot] end
GetInventoryItemCooldown = function(_, slot) if slot == 13 then return 0, 60 end return 0, 0 end
GetContainerNumSlots = function(bag) return bag == 0 and 2 or 0 end
GetContainerItemLink = function(bag, slot) return bagItems[bag] and bagItems[bag][slot] end
GetContainerItemCooldown = function() return 0, 0 end
UnitAffectingCombat = function() return false end
UnitIsDeadOrGhost = function() return false end
dofile("Core.lua")
dofile("Inventory.lua")
local f = { SetScript = function() end }
TrinketPriority.Priority = { frame = f }
dofile("Priority.lua")
local TP = TrinketPriority
TP.GetActiveProfile().use = { { id = 200 }, { id = 201 } }
assert(TP.Priority.GetNextUseCandidate().id == 200)
TP.GetActiveProfile().use = { { id = 100 }, { id = 201 } }
assert(TP.Priority.GetNextUseCandidate().id == 201)
GetInventoryItemCooldown = function(_, slot) if slot == 13 then return 0, 10 end return 0, 0 end
TP.Inventory.InvalidateSnapshot()
assert(TP.Priority.GetNextUseCandidate() == nil)
equipped[13] = "item:300"
TP.GetActiveProfile().use = { { id = 999 } }
TP.GetActiveProfile().passive = { id = 300, name = "Pasivo de prueba" }
local messages = {}
TP.Print = function(message) messages[#messages + 1] = message end
local equipCalls = 0
local equipItem = TP.Inventory.EquipItem
TP.Inventory.EquipItem = function() equipCalls = equipCalls + 1; return true end
TP.Priority.ProcessRequest()
assert(equipCalls == 0)
assert(messages[#messages] == "Pasivo ya equipado: Pasivo de prueba")
for i = 1, #messages do assert(not string.find(messages[i], "no hay pasivo disponible", 1, true)) end
TP.Inventory.EquipItem = equipItem
print("Priority selection tests passed.")
