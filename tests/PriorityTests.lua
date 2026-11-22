-- Priority selection smoke test for equipped and bag candidates.
local equipped = { [13] = "item:100", [14] = nil }
local bagItems = { [0] = { [1] = "item:200", [2] = "item:201" } }
local inCombat = false
UnitName = function() return "Test" end
GetRealmName = function() return "Realm" end
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
GetTime = function() return 1 end
GetInventoryItemLink = function(_, slot) return equipped[slot] end
GetInventoryItemCooldown = function(_, slot) if slot == 13 then return 0, 60 end return 0, 0 end
GetContainerNumSlots = function(bag) return bag == 0 and 2 or 0 end
GetContainerItemLink = function(bag, slot) return bagItems[bag] and bagItems[bag][slot] end
GetContainerItemCooldown = function() return 0, 0 end
UnitAffectingCombat = function() return inCombat end
UnitIsDeadOrGhost = function() return false end
dofile("Core.lua")
dofile("Inventory.lua")
local f = { scripts = {} }
function f:SetScript(name, callback) self.scripts[name] = callback end
TrinketPriority.Priority = { frame = f }
dofile("Priority.lua")
local TP = TrinketPriority
TP.Priority.frame = f
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
local snapshotReads = 0
local getSnapshot = TP.Inventory.GetSnapshot
TP.Inventory.GetSnapshot = function() snapshotReads = snapshotReads + 1; return getSnapshot() end
local rendered
TP.Overlay = { Render = function(state) rendered = state end }
TP.Priority.RefreshOverlayState()
assert(snapshotReads == 1)
assert(rendered and rendered.entries == TP.GetActiveProfile().use)
TP.Inventory.GetSnapshot = getSnapshot

-- Manual intent replaces automatic and earlier manual requests while in combat.
local equippedRequests = {}
TP.Inventory.EquipItem = function(id) equippedRequests[#equippedRequests + 1] = id; return true end
inCombat = true
TP.Priority.Request()
assert(TP.Priority.HasPendingRequest())
assert(TP.Priority.RequestManualEquip(201, "Manual 201"))
assert(not TP.Priority.HasPendingRequest() and TP.Priority.HasPendingManualRequest())
assert(TP.Priority.RequestManualEquip(200, "Manual 200"))
inCombat = false
TP.Priority.ScheduleRequest()
local manualTimer = f.scripts.OnUpdate
assert(manualTimer)
manualTimer(f, 0.2)
assert(equippedRequests[1] == 200 and not TP.Priority.HasPendingManualRequest())

-- Automatic request deferred by combat is processed on leaving combat.
equipped[13] = "item:100"
TP.GetActiveProfile().use = { { id = 200, name = "Automatic" } }
TP.GetActiveProfile().passive = nil
TP.Inventory.InvalidateSnapshot()
inCombat = true
TP.Priority.Request()
inCombat = false
TP.Priority.ScheduleRequest()
local automaticTimer = f.scripts.OnUpdate
assert(automaticTimer)
automaticTimer(f, 0.2)
assert(equippedRequests[2] == 200 and not TP.Priority.HasPendingRequest())

-- Switching profiles replaces the overlay's complete logical state.
TP.GetProfile("Perfil 1").use = { { id = 200, name = "One" } }
TP.GetProfile("Perfil 2").use = { { id = 201, name = "Two" } }
assert(TP.SwitchProfile("Perfil 2"))
assert(rendered.entries == TP.GetActiveProfile().use)
assert(rendered.entries[1].id == 201)
print("Priority selection tests passed.")
