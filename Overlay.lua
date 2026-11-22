local TP = TrinketPriority
TP.Overlay = {}

local Overlay = TP.Overlay
local frame
local icons = {}
local statusText
local lastState
local layoutCount, layoutIconSize
local itemIconCache = {}
local itemIconAttempted = {}
local itemIconRequested = {}
local itemIconFailed = {}
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

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
  if _G and _G.GetItemIcon then
    return _G.GetItemIcon(id)
  end
  return nil
end

local function ApplyItemIcon(icon, itemID)
  local itemIcon = itemIconCache[itemID]
  if not itemIcon and not itemIconAttempted[itemID] then
    itemIconAttempted[itemID] = true
    itemIcon = GetItemIcon(itemID)
    if itemIcon then itemIconCache[itemID] = itemIcon end
  end
  if itemIcon then
    if icon.appliedIcon ~= itemIcon then
      icon.appliedIcon = itemIcon
      icon.texture:SetTexture(itemIcon)
    end
    return
  end

  if icon.appliedIcon ~= FALLBACK_ICON then
    icon.appliedIcon = FALLBACK_ICON
    icon.texture:SetTexture(FALLBACK_ICON)
  end
  local itemApi = _G and _G.C_Item
  if not itemIconRequested[itemID] and not itemIconFailed[itemID]
    and itemApi and itemApi.RequestLoadItemDataByID then
    itemIconRequested[itemID] = true
    itemApi.RequestLoadItemDataByID(itemID)
  end
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
  frame:ClearAllPoints()
  if type(pos) ~= "table" or not pos.point then
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    return
  end
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
    if cooldownFrame.SetHideCountdownNumbers then cooldownFrame:SetHideCountdownNumbers(false) end
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

  local candidateGlow = icon:CreateTexture(nil, "ARTWORK")
  candidateGlow:SetPoint("TOPLEFT", icon, "TOPLEFT", -5, 5)
  candidateGlow:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 5, -5)
  candidateGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
  candidateGlow:SetVertexColor(1, 0.82, 0.10, 0.28)
  candidateGlow:Hide()
  icon.candidateGlow = candidateGlow

  local candidateBorder = CreateFrame("Frame", nil, icon)
  candidateBorder:SetAllPoints()
  candidateBorder:SetFrameLevel(icon:GetFrameLevel() + 4)

  local borderTop = candidateBorder:CreateTexture(nil, "OVERLAY")
  borderTop:SetPoint("TOPLEFT", candidateBorder, "TOPLEFT", 0, 0)
  borderTop:SetPoint("TOPRIGHT", candidateBorder, "TOPRIGHT", 0, 0)
  borderTop:SetHeight(3)
  borderTop:SetTexture("Interface\\Buttons\\WHITE8X8")
  borderTop:SetVertexColor(1, 0.82, 0.10, 1)

  local borderBottom = candidateBorder:CreateTexture(nil, "OVERLAY")
  borderBottom:SetPoint("BOTTOMLEFT", candidateBorder, "BOTTOMLEFT", 0, 0)
  borderBottom:SetPoint("BOTTOMRIGHT", candidateBorder, "BOTTOMRIGHT", 0, 0)
  borderBottom:SetHeight(3)
  borderBottom:SetTexture("Interface\\Buttons\\WHITE8X8")
  borderBottom:SetVertexColor(1, 0.82, 0.10, 1)

  local borderLeft = candidateBorder:CreateTexture(nil, "OVERLAY")
  borderLeft:SetPoint("TOPLEFT", candidateBorder, "TOPLEFT", 0, 0)
  borderLeft:SetPoint("BOTTOMLEFT", candidateBorder, "BOTTOMLEFT", 0, 0)
  borderLeft:SetWidth(3)
  borderLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
  borderLeft:SetVertexColor(1, 0.82, 0.10, 1)

  local borderRight = candidateBorder:CreateTexture(nil, "OVERLAY")
  borderRight:SetPoint("TOPRIGHT", candidateBorder, "TOPRIGHT", 0, 0)
  borderRight:SetPoint("BOTTOMRIGHT", candidateBorder, "BOTTOMRIGHT", 0, 0)
  borderRight:SetWidth(3)
  borderRight:SetTexture("Interface\\Buttons\\WHITE8X8")
  borderRight:SetVertexColor(1, 0.82, 0.10, 1)

  candidateBorder:Hide()
  icon.candidateBorder = candidateBorder

  local candidateBadge = CreateFrame("Frame", nil, icon)
  candidateBadge:SetWidth(58)
  candidateBadge:SetHeight(18)
  candidateBadge:SetPoint("BOTTOM", icon, "TOP", 0, 4)
  candidateBadge:SetFrameLevel(icon:GetFrameLevel() + 5)

  local badgeBase = candidateBadge:CreateTexture(nil, "BACKGROUND")
  badgeBase:SetAllPoints()
  badgeBase:SetTexture("Interface\\Buttons\\WHITE8X8")
  badgeBase:SetVertexColor(0.12, 0.10, 0.03, 1)

  local badgeBorder = candidateBadge:CreateTexture(nil, "BORDER")
  badgeBorder:SetAllPoints()
  badgeBorder:SetTexture("Interface\\Buttons\\WHITE8X8")
  badgeBorder:SetVertexColor(1, 0.82, 0.10, 1)

  local badgeInset = candidateBadge:CreateTexture(nil, "ARTWORK")
  badgeInset:SetPoint("TOPLEFT", candidateBadge, "TOPLEFT", 2, -2)
  badgeInset:SetPoint("BOTTOMRIGHT", candidateBadge, "BOTTOMRIGHT", -2, 2)
  badgeInset:SetTexture("Interface\\Buttons\\WHITE8X8")
  badgeInset:SetVertexColor(0.08, 0.07, 0.02, 1)

  local badgeText = candidateBadge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  badgeText:SetPoint("CENTER", candidateBadge, "CENTER", 0, 0)
  badgeText:SetText("▲  NEXT")
  badgeText:SetTextColor(1, 0.95, 0.25, 1)

  candidateBadge:Hide()
  icon.candidateBadge = candidateBadge

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
  icon:SetScript("OnMouseUp", function(self, mouseButton)
    if mouseButton == "LeftButton" and self.entry and self.entry.id then
      TP.Priority.RequestManualEquip(self.entry.id, self.entry.name)
    end
  end)

  icons[index] = icon
  return icon
end

local function RefreshLayout(count)
  local iconSize = GetIconSize()
  if layoutCount == count and layoutIconSize == iconSize then return end
  layoutCount, layoutIconSize = count, iconSize
  if count < 1 then
    frame:SetWidth(220)
  else
    frame:SetWidth(count * iconSize + (count - 1) * ICON_GAP + 20)
  end
  frame:SetHeight(iconSize + 44)

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

function Overlay.Render(state)
  if type(state) ~= "table" or type(state.entries) ~= "table" or type(state.equipped) ~= "table"
    or type(state.cooldowns) ~= "table"
    or (state.candidate ~= nil and (type(state.candidate) ~= "table" or state.candidate.id == nil)) then
    return false
  end
  for i = 1, #state.entries do
    if type(state.entries[i]) ~= "table" or state.entries[i].id == nil then return false end
  end
  if not frame then return false end
  lastState = state
  local entries = state.entries or {}
  local count = #entries
  RefreshLayout(count)
  local equipped = state.equipped or {}
  local id13, id14 = equipped[13], equipped[14]
  local nextEntry = state.candidate

  for i = 1, TP.USE_MAX do
    local icon = icons[i] or CreateIcon(i)
    local entry = entries[i]

    if entry then
      icon.entry = entry
      icon:Show()

      if icon.itemID ~= entry.id then
        icon.itemID = entry.id
        ApplyItemIcon(icon, entry.id)
      end

      local isEquipped = (entry.id == id13 or entry.id == id14)
      if icon.isEquipped ~= isEquipped then
        icon.isEquipped = isEquipped
        if isEquipped then
          icon.equippedBorder:Show()
          icon.equippedMark:Show()
        else
          icon.equippedBorder:Hide()
          icon.equippedMark:Hide()
        end
      end

      local isCandidate = nextEntry and nextEntry.id == entry.id or false
      if icon.isCandidate ~= isCandidate then
        icon.isCandidate = isCandidate
        if isCandidate then icon.candidateGlow:Show() icon.candidateBorder:Show() icon.candidateBadge:Show()
        else icon.candidateGlow:Hide() icon.candidateBorder:Hide() icon.candidateBadge:Hide() end
      end

      local cooldown = state.cooldowns and state.cooldowns[entry.id]
      local startTime, duration = cooldown and cooldown.start or 0, cooldown and cooldown.duration or 0
      local remaining = TP.RemainingCooldown(startTime, duration)
      if icon.lastCooldownStart ~= startTime or icon.lastCooldownDuration ~= duration then
        icon.lastCooldownStart, icon.lastCooldownDuration = startTime, duration
        if icon.cooldownFrame and icon.cooldownFrame.SetCooldown then
          if remaining > 0 then
            icon.cooldownFrame:SetCooldown(startTime, duration)
          else
            icon.cooldownFrame:SetCooldown(0, 0)
          end
        end
      end

    else
      icon.entry = nil
      icon.itemID = nil
      icon:Hide()
    end
  end

  local text
  if count == 0 then text = "Sin trinkets de uso"
  elseif nextEntry then text = "Siguiente: " .. (nextEntry.name or tostring(nextEntry.id))
  else text = "" end
  if statusText.lastText ~= text then
    statusText.lastText = text
    statusText:SetText(text)
  end
  return true
end

-- Compatibility alias: a no-argument refresh reuses the last valid render state.
function Overlay.Refresh(state)
  if state then
    return Overlay.Render(state)
  elseif lastState then
    return Overlay.Render(lastState)
  elseif TP.Priority and TP.Priority.GetOverlayState then
    local current = TP.Priority.GetOverlayState()
    if current then return Overlay.Render(current) end
  end
  return false
end

function Overlay.OnItemDataLoadResult(itemID, success)
  itemID = tonumber(itemID)
  if not itemID or not itemIconRequested[itemID] then return false end
  itemIconRequested[itemID] = nil
  itemIconAttempted[itemID] = nil
  local itemIcon = success and GetItemIcon(itemID) or nil
  if itemIcon then
    itemIconCache[itemID] = itemIcon
    itemIconFailed[itemID] = nil
    for i = 1, TP.USE_MAX do
      local icon = icons[i]
      if icon and icon.entry and icon.entry.id == itemID and icon:IsShown() then
        if icon.appliedIcon ~= itemIcon then
          icon.appliedIcon = itemIcon
          icon.texture:SetTexture(itemIcon)
        end
      end
    end
    return true
  end
  itemIconFailed[itemID] = true
  return false
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
  if frame then
    local count = lastState and #lastState.entries or 0
    RefreshLayout(count)
  end
end

function Overlay.RestoreProfilePosition()
  if not frame then return end
  RestorePosition()
end

function Overlay.Initialize()
  if frame then
    frame:Show()
    return
  end

  local settings = GetProfileSettings()
  GetIconSize()

  frame = CreateFrame("Frame", "TrinketPriorityOverlay", UIParent)
  frame:SetHeight(GetIconSize() + 44)
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
  Overlay.Render({ entries = TP.GetActiveProfile().use, equipped = {}, cooldowns = {}, candidate = nil })
end

function Overlay.Show()
  if not frame then Overlay.Initialize() end
  Overlay.Render(TP.Priority and TP.Priority.GetOverlayState and TP.Priority.GetOverlayState() or {})
  frame:Show()
end

function Overlay.Hide()
  -- El overlay permanece visible permanentemente; Hide se conserva por compatibilidad.
  if not frame then Overlay.Initialize() end
  Overlay.Render(TP.Priority and TP.Priority.GetOverlayState and TP.Priority.GetOverlayState() or {})
  frame:Show()
end

function Overlay.Lock()
  GetProfileSettings().movable = false
  if frame then
    frame:EnableMouse(false)
    frame:SetMovable(false)
  end
end
