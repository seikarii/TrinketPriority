TrinketPriority = TrinketPriority or {}

local TP = TrinketPriority

TP.ADDON_NAME = "TrinketPriority"
TP.USE_MAX = 7
TP.COMBAT_DELAY = 0.1
TP.DB_SCHEMA = 2
TP.PROFILE_NAMES = { "Perfil 1", "Perfil 2", "Perfil 3" }

TrinketPriorityDB = TrinketPriorityDB or {}

---@return string
local function GetCharacterKey()
  local name = UnitName and UnitName("player") or nil
  local realm = GetRealmName and GetRealmName() or nil
  if not name or name == "" then name = "Unknown" end
  if not realm or realm == "" then realm = "UnknownRealm" end
  realm = string.gsub(realm, "%s+", "")
  return name .. "-" .. realm
end

local initializedCharacter

---@param value any
---@return table
local function CopyEntryList(value)
  local copy = {}
  if type(value) ~= "table" then return copy end
  for i = 1, #value do
    local entry = value[i]
    if type(entry) == "table" and entry.id then
      copy[i] = { id = entry.id, name = entry.name }
    end
  end
  return copy
end

---@param value any
---@return table|nil
local function CopyPassive(value)
  if type(value) ~= "table" or not value.id then return nil end
  return { id = value.id, name = value.name }
end

---@param value any
---@return table
local function CopyOverlay(value)
  local copy = {}
  if type(value) ~= "table" then return copy end
  copy.iconSize = tonumber(value.iconSize) or 48
  copy.movable = value.movable == true
  copy.point = value.point
  copy.relativePoint = value.relativePoint
  copy.x = value.x
  copy.y = value.y
  return copy
end

---@param name string
---@return table
local function CreateProfile(name)
  return {
    name = name,
    use = {},
    passive = nil,
    overlay = { iconSize = 48, movable = false },
  }
end

---@return string
function TP.GetCharacterKey()
  return GetCharacterKey()
end

---@return table
function TP.InitDatabase()
  local db = TrinketPriorityDB
  if type(db) ~= "table" then
    db = {}
    TrinketPriorityDB = db
  end

  db.schema = tonumber(db.schema) or TP.DB_SCHEMA
  db.characters = type(db.characters) == "table" and db.characters or {}
  local key = GetCharacterKey()
  if initializedCharacter == key then return db.characters[key] end

  -- Migration: copy the former account-wide use/passive/overlay data into one
  -- character's first profile. Existing characters created afterwards start empty.
  if db.schema < TP.DB_SCHEMA or db.legacyMigrated ~= true then
    if type(db.use) == "table" or db.passive ~= nil or type(db.overlay) == "table" then
      local key = GetCharacterKey()
      local character = db.characters[key]
      if type(character) ~= "table" then
        character = { activeProfile = TP.PROFILE_NAMES[1], profiles = {} }
        db.characters[key] = character
      end
      character.profiles = type(character.profiles) == "table" and character.profiles or {}
      local first = character.profiles[TP.PROFILE_NAMES[1]]
      if type(first) ~= "table" then
        first = CreateProfile(TP.PROFILE_NAMES[1])
        character.profiles[TP.PROFILE_NAMES[1]] = first
      end
      first.use = CopyEntryList(db.use)
      first.passive = CopyPassive(db.passive)
      first.overlay = CopyOverlay(db.overlay)
      character.activeProfile = TP.PROFILE_NAMES[1]
    end
    db.legacyMigrated = true
  end

  db.schema = TP.DB_SCHEMA
  key = GetCharacterKey()
  local character = db.characters[key]
  if type(character) ~= "table" then
    character = { activeProfile = TP.PROFILE_NAMES[1], profiles = {} }
    db.characters[key] = character
  end
  character.profiles = type(character.profiles) == "table" and character.profiles or {}

  if type(character.minimapAngle) ~= "number" then character.minimapAngle = 225 end
  if type(character.automatic) ~= "boolean" then character.automatic = false end

  for i = 1, #TP.PROFILE_NAMES do
    local profileName = TP.PROFILE_NAMES[i]
    local profile = character.profiles[profileName]
    if type(profile) ~= "table" then
      profile = CreateProfile(profileName)
      character.profiles[profileName] = profile
    end
    profile.name = profileName
    if type(profile.use) ~= "table" then profile.use = {} end
    if type(profile.overlay) ~= "table" then profile.overlay = { iconSize = 48, movable = false } end
  end

  if character.profiles[character.activeProfile] == nil then
    character.activeProfile = TP.PROFILE_NAMES[1]
  end

  -- Remove legacy account-wide fields after migration.
  db.use = nil
  db.passive = nil
  db.overlay = nil
  initializedCharacter = key
  return character
end

---@param profileName string|nil
---@return table
function TP.GetProfile(profileName)
  local character = TP.InitDatabase()
  local db = TrinketPriorityDB
  profileName = profileName or character.activeProfile
  local profile = character.profiles[profileName]
  if type(profile) ~= "table" then
    profile = character.profiles[TP.PROFILE_NAMES[1]]
  end
  return profile
end

---@return table
function TP.GetActiveProfile()
  return TP.GetProfile()
end

---@return string
function TP.GetActiveProfileName()
  local character = TP.InitDatabase()
  return character.activeProfile
end

---@return boolean
function TP.IsAutomaticEnabled()
  local character = TP.InitDatabase()
  return character.automatic == true
end

---@param enabled boolean
---@return boolean
function TP.SetAutomaticEnabled(enabled)
  local character = TP.InitDatabase()
  character.automatic = enabled == true
  if TP.UI and TP.UI.Refresh then TP.UI.Refresh() end
  return character.automatic
end

---@param profileName string
---@return boolean
function TP.SwitchProfile(profileName)
  TP.InitDatabase()
  if not profileName then return false end
  local character = TrinketPriorityDB.characters[TP.GetCharacterKey()]
  if character.profiles[profileName] == nil then return false end
  character.activeProfile = profileName
  TP.Print("Perfil activo: " .. profileName)
  if TP.UI and TP.UI.Refresh then TP.UI.Refresh() end
  if TP.Overlay and TP.Overlay.RestoreProfilePosition then TP.Overlay.RestoreProfilePosition() end
  if TP.Priority and TP.Priority.RefreshOverlayState then TP.Priority.RefreshOverlayState()
  elseif TP.Overlay and TP.Overlay.Refresh then TP.Overlay.Refresh() end
  return true
end

function TP.Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99TrinketPriority|r: " .. tostring(msg))
end

TP.InitDatabase()

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
