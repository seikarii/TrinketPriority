UnitName = function() return "TestChar" end
GetRealmName = function() return "Test Realm" end
DEFAULT_CHAT_FRAME = {
  AddMessage = function() end,
}

TrinketPriorityDB = {
  use = { { id = 123, name = "Legacy use" } },
  passive = { id = 456, name = "Legacy passive" },
  overlay = { iconSize = 64, movable = true },
}

dofile("Core.lua")

local TP = TrinketPriority
assert(TP.GetCharacterKey() == "TestChar-TestRealm")
assert(TP.GetActiveProfileName() == "Perfil 1")
assert(TP.GetActiveProfile().use[1].id == 123)
assert(TP.GetActiveProfile().passive.id == 456)
assert(TP.GetActiveProfile().overlay.iconSize == 64)

assert(TP.SwitchProfile("Perfil 2") == true)
assert(TP.GetActiveProfileName() == "Perfil 2")
assert(#TP.GetActiveProfile().use == 0)
TP.GetActiveProfile().use[1] = { id = 789, name = "Profile two use" }

assert(TP.SwitchProfile("Perfil 1") == true)
assert(TP.GetActiveProfile().use[1].id == 123)
assert(TP.SwitchProfile("Perfil 2") == true)
assert(TP.GetActiveProfile().use[1].id == 789)

local character = TrinketPriorityDB.characters["TestChar-TestRealm"]
assert(character and character.profiles["Perfil 1"])
assert(character.profiles["Perfil 2"])
assert(character.profiles["Perfil 3"])
assert(TrinketPriorityDB.use == nil)
assert(TrinketPriorityDB.passive == nil)
assert(TrinketPriorityDB.overlay == nil)

print("Smoke/unit profile test passed.")
