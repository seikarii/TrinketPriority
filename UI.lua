local TP = TrinketPriority
TP.UI = {}

local UI = TP.UI

local function GetItemIcon(id)
  if id then
    local itemApi = _G and _G.C_Item
    if itemApi and itemApi.GetItemIconByID then
      local icon = itemApi.GetItemIconByID(id)
      if icon then return icon end
    end
    if _G and _G.GetItemIcon then
      local icon = _G.GetItemIcon(id)
      if icon then return icon end
    end
  end
  return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function CreateButton(parent, text, width, height)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetWidth(width)
  button:SetHeight(height)
  button:SetText(text)
  return button
end

local panel = CreateFrame("Frame", "TrinketPriorityOptions", UIParent)
panel:SetWidth(420)
panel:SetHeight(500)
panel:SetPoint("CENTER")
panel:SetMovable(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", function() panel:StartMoving() end)
panel:SetScript("OnDragStop", function() panel:StopMovingOrSizing() end)
panel:Hide()

panel:SetScript("OnHide", function()
  if TP.Overlay and TP.Overlay.Lock then
    TP.Overlay.Lock()
  end
end)

UI.panel = panel

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -18)
title:SetText("Trinket Priority")

local add13 = CreateButton(panel, "Añadir hueco 13", 125, 24)
add13:SetPoint("TOPLEFT", 25, -78)
add13:SetScript("OnClick", function() TP.Config.AddUseFromSlot(13) end)

local add14 = CreateButton(panel, "Añadir hueco 14", 125, 24)
add14:SetPoint("LEFT", add13, "RIGHT", 8, 0)
add14:SetScript("OnClick", function() TP.Config.AddUseFromSlot(14) end)

local close = CreateButton(panel, "Cerrar", 70, 24)
close:SetPoint("TOPRIGHT", -20, -18)
close:SetScript("OnClick", function() panel:Hide() end)

local useTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
useTitle:SetPoint("TOPLEFT", 25, -110)
useTitle:SetText("Prioridad de uso (1 = mayor)")

local rows = {}
for i = 1, TP.USE_MAX do
  local index = i
  local row = CreateFrame("Frame", nil, panel)
  row:SetWidth(370)
  row:SetHeight(24)
  row:SetPoint("TOPLEFT", 25, -132 - (i - 1) * 27)

  row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.text:SetPoint("LEFT", 52, 0)
  row.text:SetWidth(178)
  row.text:SetJustifyH("LEFT")

  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetPoint("LEFT", 24, 0)
  row.icon:SetWidth(22)
  row.icon:SetHeight(22)
  row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  row.number = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.number:SetPoint("LEFT", 0, 0)
  row.number:SetText(i .. ".")

  row.up = CreateButton(row, "^", 24, 20)
  row.up:SetPoint("RIGHT", -56, 0)
  row.up:SetScript("OnClick", function() TP.Config.MoveUse(index, -1) end)

  row.down = CreateButton(row, "v", 24, 20)
  row.down:SetPoint("LEFT", row.up, "RIGHT", 2, 0)
  row.down:SetScript("OnClick", function() TP.Config.MoveUse(index, 1) end)

  row.remove = CreateButton(row, "X", 24, 20)
  row.remove:SetPoint("LEFT", row.down, "RIGHT", 2, 0)
  row.remove:SetScript("OnClick", function() TP.Config.RemoveUse(index) end)

  rows[i] = row
end

local passiveTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
passiveTitle:SetPoint("TOPLEFT", 25, -330)
passiveTitle:SetText("Fallback pasivo")

local passiveIcon = panel:CreateTexture(nil, "ARTWORK")
passiveIcon:SetPoint("TOPLEFT", 25, -351)
passiveIcon:SetWidth(22)
passiveIcon:SetHeight(22)
passiveIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local passiveText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
passiveText:SetPoint("TOPLEFT", 51, -353)
passiveText:SetWidth(224)
passiveText:SetJustifyH("LEFT")

local passive13 = CreateButton(panel, "13", 55, 22)
passive13:SetPoint("TOPRIGHT", -78, -346)
passive13:SetScript("OnClick", function() TP.Config.SetPassiveFromSlot(13) end)

local passive14 = CreateButton(panel, "14", 55, 22)
passive14:SetPoint("LEFT", passive13, "RIGHT", 4, 0)
passive14:SetScript("OnClick", function() TP.Config.SetPassiveFromSlot(14) end)

local removePassive = CreateButton(panel, "Eliminar pasivo", 115, 22)
removePassive:SetPoint("TOPLEFT", 25, -384)
removePassive:SetScript("OnClick", function() TP.Config.RemovePassive() end)

local clear = CreateButton(panel, "Limpiar todo", 115, 22)
clear:SetPoint("LEFT", removePassive, "RIGHT", 8, 0)
clear:SetScript("OnClick", function() TP.Config.Clear() end)

local overlaySizeTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
overlaySizeTitle:SetPoint("TOPLEFT", 25, -418)
overlaySizeTitle:SetText("Tamaño del overlay")

local overlaySizeText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
overlaySizeText:SetPoint("LEFT", overlaySizeTitle, "RIGHT", 12, 0)

local overlaySizeMinus = CreateButton(panel, "-", 28, 22)
overlaySizeMinus:SetPoint("TOPRIGHT", -62, -412)

local overlaySizePlus = CreateButton(panel, "+", 28, 22)
overlaySizePlus:SetPoint("LEFT", overlaySizeMinus, "RIGHT", 4, 0)

local function ChangeOverlaySize(delta)
  local profile = TP.GetActiveProfile()
  profile.overlay = type(profile.overlay) == "table" and profile.overlay or { iconSize = 48, movable = false }
  local size = tonumber(profile.overlay.iconSize) or 48
  size = size + delta
  if size < 24 then size = 24 end
  if size > 96 then size = 96 end
  if TP.Overlay and TP.Overlay.SetIconSize then
    TP.Overlay.SetIconSize(size)
  end
  UI.Refresh()
end

overlaySizeMinus:SetScript("OnClick", function() ChangeOverlaySize(-4) end)
overlaySizePlus:SetScript("OnClick", function() ChangeOverlaySize(4) end)

local overlayMoveButton = CreateButton(panel, "Mover overlay", 115, 22)
overlayMoveButton:SetPoint("TOPLEFT", 25, -448)

local overlayMoveStatus = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
overlayMoveStatus:SetPoint("LEFT", overlayMoveButton, "RIGHT", 12, 0)

overlayMoveButton:SetScript("OnClick", function()
  if TP.Overlay and TP.Overlay.Toggle then
    TP.Overlay.Toggle()
  end
  UI.Refresh()
end)

function UI.Refresh()
  local profile = TP.GetActiveProfile()
  profile.use = type(profile.use) == "table" and profile.use or {}
  profile.overlay = type(profile.overlay) == "table" and profile.overlay or { iconSize = 48, movable = false }

  for i = 1, TP.USE_MAX do
    local entry = profile.use[i]
    if entry then
      rows[i].text:SetText(entry.name or tostring(entry.id))
      rows[i].icon:SetTexture(GetItemIcon(entry.id))
      rows[i].icon:Show()
      rows[i].up:Show()
      rows[i].down:Show()
      rows[i].remove:Show()
    else
      rows[i].text:SetText("Vacío")
      rows[i].icon:SetTexture(nil)
      rows[i].icon:Hide()
      rows[i].up:Hide()
      rows[i].down:Hide()
      rows[i].remove:Hide()
    end
  end

  if profile.passive then
    passiveText:SetText(profile.passive.name or tostring(profile.passive.id))
    passiveIcon:SetTexture(GetItemIcon(profile.passive.id))
    passiveIcon:Show()
  else
    passiveText:SetText("Ninguno")
    passiveIcon:SetTexture(nil)
    passiveIcon:Hide()
  end

  local overlaySize = tonumber(profile.overlay.iconSize) or 48
  if overlaySizeText then overlaySizeText:SetText(overlaySize .. " px") end

  local movable = profile.overlay.movable == true
  if movable then
    if overlayMoveStatus then overlayMoveStatus:SetText("Movible: arrastra") end
  else
    if overlayMoveStatus then overlayMoveStatus:SetText("Posición bloqueada") end
  end

  if TP.Profiles and TP.Profiles.Refresh then TP.Profiles.Refresh() end
end

function UI.Toggle()
  if panel:IsShown() then
    panel:Hide()
  else
    UI.Refresh()
    panel:Show()
  end
end
