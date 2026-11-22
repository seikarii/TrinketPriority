local TP = TrinketPriority
TP.Minimap = {}

local MinimapModule = TP.Minimap

local CreateFrame = CreateFrame
local GetCursorPosition = GetCursorPosition
local IsShiftKeyDown = IsShiftKeyDown

local cos = math.cos
local sin = math.sin
local rad = math.rad
local deg = math.deg
local sqrt = math.sqrt
local max = math.max
local min = math.min
local atan2 = math.atan2 or function(y, x)
  if x > 0 then return math.atan(y / x) end
  if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
  if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
  if x == 0 and y > 0 then return math.pi / 2 end
  if x == 0 and y < 0 then return -math.pi / 2 end
  return 0
end

local icon
local angle = 225
local dragging = false

---@return table
local function GetCharacter()
  TP.InitDatabase()
  return TrinketPriorityDB.characters[TP.GetCharacterKey()]
end

---@param degrees number
function MinimapModule.SetAngle(degrees)
  if type(degrees) ~= "number" then return end

  angle = degrees % 360
  if angle < 0 then angle = angle + 360 end

  if not icon or not Minimap then return end

  local minimapShapes = {
    ["ROUND"] = {true, true, true, true},
    ["SQUARE"] = {false, false, false, false},
    ["CORNER-TOPLEFT"] = {false, false, false, true},
    ["CORNER-TOPRIGHT"] = {false, false, true, false},
    ["CORNER-BOTTOMLEFT"] = {false, true, false, false},
    ["CORNER-BOTTOMRIGHT"] = {true, false, false, false},
    ["SIDE-LEFT"] = {false, true, false, true},
    ["SIDE-RIGHT"] = {true, false, true, false},
    ["SIDE-TOP"] = {false, false, true, true},
    ["SIDE-BOTTOM"] = {true, true, false, false},
    ["TRICORNER-TOPLEFT"] = {false, true, true, true},
    ["TRICORNER-TOPRIGHT"] = {true, false, true, true},
    ["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
    ["TRICORNER-BOTTOMRIGHT"] = {true, true, true, false},
  }

  local radians = rad(angle)
  local x, y, q = cos(radians), sin(radians), 1
  if x < 0 then q = q + 1 end
  if y > 0 then q = q + 2 end

  local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
  local quadTable = minimapShapes[shape] or minimapShapes["ROUND"]
  local radius = 5
  local w = (Minimap:GetWidth() / 2) + radius
  local h = (Minimap:GetHeight() / 2) + radius

  if quadTable[q] then
    x, y = x * w, y * h
  else
    local diagRadiusW = sqrt(2 * w * w) - 10
    local diagRadiusH = sqrt(2 * h * h) - 10
    x = max(-w, min(x * diagRadiusW, w))
    y = max(-h, min(y * diagRadiusH, h))
  end

  icon:ClearAllPoints()
  icon:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function MinimapModule.SavePosition()
  GetCharacter().minimapAngle = angle
end

function MinimapModule.ResetPosition()
  MinimapModule.SetAngle(225)
  MinimapModule.SavePosition()
end

local function UpdateFromCursor()
  if not Minimap or not icon then return end

  local cursorX, cursorY = GetCursorPosition()
  local minimapX, minimapY = Minimap:GetCenter()
  local scale = Minimap:GetEffectiveScale()
  if not cursorX or not cursorY or not minimapX or not minimapY or not scale or scale <= 0 then
    return
  end

  cursorX = cursorX / scale
  cursorY = cursorY / scale

  local radians = atan2(cursorY - minimapY, cursorX - minimapX)
  MinimapModule.SetAngle(deg(radians) % 360)
end

local function OnDragUpdate()
  if dragging then UpdateFromCursor() end
end

---@return table
function MinimapModule.Initialize()
  if icon then
    MinimapModule.SetAngle(GetCharacter().minimapAngle or 225)
    return icon
  end

  icon = CreateFrame("Button", "TrinketPriorityMinimapButton", Minimap)
  icon:SetSize(31, 31)
  icon:SetFrameStrata("MEDIUM")
  icon:SetFrameLevel(Minimap:GetFrameLevel() + 10)
  icon:RegisterForClicks("AnyUp")
  icon:RegisterForDrag("LeftButton")

  icon.icon = icon:CreateTexture(nil, "BACKGROUND")
  icon.icon:SetSize(20, 20)
  icon.icon:SetPoint("CENTER")
  icon.icon:SetTexture(130000)

  icon.border = icon:CreateTexture(nil, "OVERLAY")
  icon.border:SetAllPoints()
  icon.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

  icon:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  icon:SetScript("OnClick", function(self, mouseButton)
    if mouseButton == "LeftButton" and not IsShiftKeyDown() then
      if TP.UI and TP.UI.Toggle then TP.UI.Toggle() end
    end
  end)

  icon:SetScript("OnDragStart", function(self)
    if not IsShiftKeyDown() then return end
    dragging = true
    icon:SetScript("OnUpdate", OnDragUpdate)
    if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
  end)

  icon:SetScript("OnDragStop", function(self)
    if not dragging then return end
    dragging = false
    icon:SetScript("OnUpdate", nil)
    UpdateFromCursor()
    MinimapModule.SavePosition()
  end)

  icon:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Trinket Priority")
    GameTooltip:AddLine("Clic izquierdo: abrir opciones", 1, 1, 1)
    GameTooltip:AddLine("Mayús-clic izquierdo: arrastrar", 1, 1, 1)
    GameTooltip:Show()
  end)

  icon:SetScript("OnLeave", function()
    if not dragging then GameTooltip:Hide() end
  end)

  MinimapModule.SetAngle(tonumber(GetCharacter().minimapAngle) or 225)
  icon:Show()
  return icon
end

---@return number
function MinimapModule.GetAngle()
  return angle
end
