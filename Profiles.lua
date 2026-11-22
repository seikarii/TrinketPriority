local TP = TrinketPriority
TP.Profiles = {}

local Profiles = TP.Profiles
local tabButtons = {}
local activeText

local function ResolveProfileName(value)
  value = string.lower(string.gsub(tostring(value or ""), "%s+", ""))
  if value == "1" or value == "perfil1" or value == "profile1" then
    return TP.PROFILE_NAMES[1]
  elseif value == "2" or value == "perfil2" or value == "profile2" then
    return TP.PROFILE_NAMES[2]
  elseif value == "3" or value == "perfil3" or value == "profile3" then
    return TP.PROFILE_NAMES[3]
  end
  for i = 1, #TP.PROFILE_NAMES do
    if string.lower(TP.PROFILE_NAMES[i]) == value then
      return TP.PROFILE_NAMES[i]
    end
  end
  return nil
end

function Profiles.ResolveName(value)
  return ResolveProfileName(value)
end

function Profiles.Switch(profileName)
  profileName = ResolveProfileName(profileName)
  if not profileName then
    TP.Print("Uso: /trinket profile 1|2|3")
    return false
  end
  return TP.SwitchProfile(profileName)
end

function Profiles.Refresh()
  local activeName = TP.GetActiveProfileName()
  if activeText then activeText:SetText("Perfil activo: " .. activeName) end
  for i = 1, #TP.PROFILE_NAMES do
    local button = tabButtons[i]
    if button then
      if TP.PROFILE_NAMES[i] == activeName then
        button:Disable()
        button:SetText(TP.PROFILE_NAMES[i] .. " *")
      else
        button:Enable()
        button:SetText(TP.PROFILE_NAMES[i])
      end
    end
  end
end

function Profiles.Initialize()
  if not TP.UI or not TP.UI.panel then return end
  local panel = TP.UI.panel

  local tabWidth = 110
  for i = 1, #TP.PROFILE_NAMES do
    local index = i
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetWidth(tabWidth)
    button:SetHeight(24)
    button:SetPoint("TOPLEFT", panel, "TOPLEFT", 25 + (i - 1) * (tabWidth + 6), -42)
    button:SetScript("OnClick", function()
      TP.SwitchProfile(TP.PROFILE_NAMES[index])
    end)
    tabButtons[i] = button
  end

  activeText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  activeText:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -20, -66)
  Profiles.Refresh()
end

Profiles.Initialize()
