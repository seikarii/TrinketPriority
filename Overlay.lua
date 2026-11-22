local TP = TrinketPriority
TP.Overlay = {}

local Overlay = TP.Overlay
local frame
local icons = {}
local statusText

local ICON_GAP = 8

local function GetProfileSettings()
  local profile = TP.GetActiveProfile()
  profile.overlay = type(profile.overlay) == "table" and profile.overlay or { iconSize = 48, movable = false }
  return profile.overlay
end

local function GetIconSize()
  local settings = GetProfileSettings()
  local size = tonumber(settings.iconSize)
  if not size then size = 48 end
  if size < 24 then size = 24 end
  if size > 96 then size = 96 end
  settings.iconSize = size
  return size
end

local function GetItemIcon(id)
  if C_Item and C_Item.GetItemIconByID then
    local icon = C_Item.GetItemIconByID(id)
    if icon then return icon end
  end
  if GetItemIcon then
    return GetItemIcon(id)
  end
  return nil
end

local function SavePosition()
  if not frame then return end
  local point, _, relativePoint, x, y = frame:GetPoint()
  local settings = GetProfileSettings()
  settings.point = point or "CENTER"
  settings.relativePoint = relativePoint or "CENTER"
  settings.x = x or 0
  settings.y = y or 0
end

local function RestorePosition()
  local pos = GetProfileSettings()
  if type(pos) ~= "table" or not pos.point then
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    return
  end
  frame:ClearAllPoints()
  frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
end

local function CreateIcon(index)
  local icon = CreateFrame("Frame", nil, frame)
  local iconSize = GetIconSize()
  icon:SetWidth(iconSize)
  icon:SetHeight(iconSize)
  icon:SetFrameLevel(frame:GetFrameLevel() + 3)

  local base = icon:CreateTexture(nil, "BACKGROUND")
  base:SetAllPoints()
  base:SetTexture("Interface\\Buttons\\WHITE8X8")
  base:SetVertexColor(0.05, 0.05, 0.05, 1)

  local texture = icon:CreateTexture(nil, "ARTWORK")
  texture:SetPoint("TOPLEFT", icon, "TOPLEFT", 3, -3)
  texture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -3, 3)
  texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  icon.texture = texture

  local cooldownFrame
  if CreateFrame then
    local template = nil
    if _G and _G["CooldownFrameTemplate"] then template = "CooldownFrameTemplate" end
    cooldownFrame = CreateFrame("Cooldown", nil, icon, template)
    if cooldownFrame.SetAllPoints then cooldownFrame:SetAllPoints(texture) end
    if cooldownFrame.SetFrameLevel then cooldownFrame:SetFrameLevel(icon:GetFrameLevel() + 2) end
  end
  icon.cooldownFrame = cooldownFrame

  local equippedBorder = icon:CreateTexture(nil, "OVERLAY")
  equippedBorder:SetAllPoints()
  equippedBorder:SetTexture("Interface\\Buttons\\WHITE8X8")
  equippedBorder:SetVertexColor(1, 0.82, 0.10, 0.45)
  equippedBorder:Hide()
  icon.equippedBorder = equippedBorder

  local equippedMark = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  equippedMark:SetPoint("BOTTOM", icon, "BOTTOM", 0, 4)
  equippedMark:SetText("E")
  equippedMark:SetTextColor(1, 0.82, 0.10, 1)
  equippedMark:Hide()
  icon.equippedMark = equippedMark

  local arrow = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  arrow:SetPoint("BOTTOM", icon, "TOP", 0, 5)
  arrow:SetText("▼")
  arrow:SetTextColor(1, 0.95, 0.25, 1)
  arrow:Hide()
  icon.arrow = arrow

  icon:EnableMouse(true)
  icon:RegisterForDrag("LeftButton")
  icon:SetScript("OnDragStart", function()
    if GetProfileSettings().movable then
      frame:StartMoving()
    end
  end)
  icon:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    SavePosition()
  end)

  icon:SetScript("OnEnter", function(self)
    if not self.entry then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    if self.entry.id and GameTooltip.SetItemByID then
      GameTooltip:SetItemByID(self.entry.id)
    else
      GameTooltip:SetText(self.entry.name or tostring(self.entry.id))
    end
    GameTooltip:Show()
  end)
  icon:SetScript("OnLeave", function() GameTooltip:Hide() end)

  icons[index] = icon
  return icon
end

local function RefreshLayout(count)
  local iconSize = GetIconSize()
  if count < 1 then
    frame:SetWidth(220)
  else
    frame:SetWidth(count * iconSize + (count - 1) * ICON_GAP + 20)
  end
  frame:SetHeight(iconSize + 34)

  for i = 1, TP.USE_MAX do
    local icon = icons[i]
    if icon then
      icon:SetWidth(iconSize)
      icon:SetHeight(iconSize)
      if i <= count then
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", frame, "LEFT", 10 + (i - 1) * (iconSize + ICON_GAP), 0)
      else
        icon:Hide()
      end
    end
  end
end

local function GetCooldownInfo(entry, id13, id14)
  if not entry or not entry.id then return 0, 0 end

  if entry.id == id13 then
    local startTime, duration = GetInventoryItemCooldown("player", 13)
    return startTime or 0, duration or 0
  end

  if entry.id == id14 then
    local startTime, duration = GetInventoryItemCooldown("player", 14)
    return startTime or 0, duration or 0
  end

  local bag, slot = TP.Inventory.FindBagItem(entry.id)
  if bag and TP.Inventory.GetBagCooldownInfo then
    local startTime, duration = TP.Inventory.GetBagCooldownInfo(bag, slot)
    return startTime or 0, duration or 0
  end

  return 0, 0
end

function Overlay.Refresh()
  if not frame then return end

  local profile = TP.GetActiveProfile()
  profile.use = type(profile.use) == "table" and profile.use or {}
  local count = table.getn(profile.use)
  RefreshLayout(count)

  local id13 = TP.ItemID(TP.InventoryLink(13))
  local id14 = TP.ItemID(TP.InventoryLink(14))
  local nextEntry = TP.Priority and TP.Priority.GetNextUseCandidate and TP.Priority.GetNextUseCandidate() or nil

  for i = 1, TP.USE_MAX do
    local icon = icons[i] or CreateIcon(i)
    local entry = profile.use[i]

    if entry then
      icon.entry = entry
      icon:Show()

      local itemIcon = GetItemIcon(entry.id)
      if itemIcon then
        icon.texture:SetTexture(itemIcon)
      else
        icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
      end

      local isEquipped = (entry.id == id13 or entry.id == id14)
      if isEquipped then
        icon.equippedBorder:Show()
        icon.equippedMark:Show()
      else
        icon.equippedBorder:Hide()
        icon.equippedMark:Hide()
      end

      if nextEntry and nextEntry.id == entry.id then
        icon.arrow:Show()
      else
        icon.arrow:Hide()
      end

      local startTime, duration = GetCooldownInfo(entry, id13, id14)
      local remaining = TP.RemainingCooldown(startTime, duration)
      if remaining > 0 and icon.cooldownFrame and icon.cooldownFrame.SetCooldown then
        icon.cooldownFrame:SetCooldown(startTime, duration)
      elseif icon.cooldownFrame and icon.cooldownFrame.SetCooldown then
        icon.cooldownFrame:SetCooldown(0, 0)
      end
    else
      icon.entry = nil
      icon:Hide()
    end
  end

  if count == 0 then
    statusText:SetText("Sin trinkets de uso")
  elseif nextEntry then
    statusText:SetText("Siguiente: " .. (nextEntry.name or tostring(nextEntry.id)))
  else
    statusText:SetText("")
  end
end

function Overlay.Toggle()
  if not frame then Overlay.Initialize() end
  local settings = GetProfileSettings()
  settings.movable = not (settings.movable == true)
  frame:EnableMouse(settings.movable)
  frame:SetMovable(settings.movable)

  if settings.movable then
    TP.Print("Overlay desbloqueado: arrastra con el botón izquierdo.")
  else
    TP.Print("Overlay bloqueado en su posición.")
  end
end

function Overlay.SetIconSize(size)
  size = tonumber(size)
  if not size then return end
  if size < 24 then size = 24 end
  if size > 96 then size = 96 end
  GetProfileSettings().iconSize = size
  if frame then Overlay.Refresh() end
end

function Overlay.RestoreProfilePosition()
  if not frame then return end
  RestorePosition()
end

function Overlay.Initialize()
  if frame then
    Overlay.Refresh()
    frame:Show()
    return
  end

  local settings = GetProfileSettings()
  GetIconSize()

  frame = CreateFrame("Frame", "TrinketPriorityOverlay", UIParent)
  frame:SetHeight(GetIconSize() + 34)
  frame:SetMovable(settings.movable == true)
  frame:EnableMouse(settings.movable == true)
  frame:RegisterForDrag("LeftButton")
  frame:SetFrameStrata("MEDIUM")
  frame:SetScript("OnDragStart", function(self)
    if not GetProfileSettings().movable then return end
    self:StartMoving()
  end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SavePosition()
  end)

  statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  statusText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 8)

  RestorePosition()

  frame:RegisterEvent("BAG_UPDATE")
  frame:RegisterEvent("BAG_UPDATE_DELAYED")
  frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
  frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
  frame:SetScript("OnEvent", function()
    Overlay.Refresh()
  end)

  local updateElapsed = 0
  frame:SetScript("OnUpdate", function(self, elapsed)
    if not self:IsShown() then return end
    updateElapsed = updateElapsed + elapsed
    if updateElapsed >= 0.5 then
      updateElapsed = 0
      Overlay.Refresh()
    end
  end)

  for i = 1, TP.USE_MAX do
    CreateIcon(i)
  end

  local dragArea = CreateFrame("Frame", nil, frame)
  dragArea:SetAllPoints(frame)
  dragArea:SetFrameLevel(frame:GetFrameLevel() + 1)
  dragArea:EnableMouse(true)
  dragArea:RegisterForDrag("LeftButton")
  dragArea:SetScript("OnDragStart", function()
    if GetProfileSettings().movable then
      frame:StartMoving()
    end
  end)
  dragArea:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    SavePosition()
  end)

  frame:Show()
  Overlay.Refresh()
end

function Overlay.Show()
  if not frame then Overlay.Initialize() end
  Overlay.Refresh()
  frame:Show()
end

function Overlay.Hide()
  -- El overlay permanece visible permanentemente; Hide se conserva por compatibilidad.
  if not frame then Overlay.Initialize() end
  Overlay.Refresh()
  frame:Show()
end

function Overlay.Lock()
  GetProfileSettings().movable = false
  if frame then
    frame:EnableMouse(false)
    frame:SetMovable(false)
  end
end
