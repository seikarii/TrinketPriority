-- Inventory snapshot and lookup regression tests using minimal WoW API stubs.
local equipped = { [13] = "item:100", [14] = "item:101" }
local bags = { [0] = { "item:200", nil, "item:201" } }
local slotReads, bagReads = 0, 0
GetInventoryItemLink = function(_, slot) slotReads = slotReads + 1; return equipped[slot] end
GetContainerNumSlots = function(bag) return bag == 0 and 3 or 0 end
GetContainerItemLink = function(bag, slot) bagReads = bagReads + 1; return bags[bag] and bags[bag][slot] end
UnitName = function() return "Test" end
GetRealmName = function() return "Realm" end
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
dofile("Core.lua")
dofile("Inventory.lua")
local I = TrinketPriority.Inventory
local first = I.GetSnapshot()
assert(first.equipped[13] == 100 and first.equipped[14] == 101)
local reads = bagReads
assert(I.GetSnapshot() == first and bagReads == reads)
assert(I.FindBagItem(200) == 0)
assert(I.FindBagItem(999) == nil)
assert(bagReads == reads)
I.InvalidateSnapshot()
local second = I.GetSnapshot()
assert(second ~= first and bagReads > reads)
assert(slotReads == 4)
print("Inventory snapshot tests passed.")
