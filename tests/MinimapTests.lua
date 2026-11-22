-- Self-contained minimap smoke/unit/benchmark harness.
-- Run from the addon root with: lua tests/MinimapTests.lua (from this addon directory)

local function Frame()
  local frame = { scripts = {}, points = {}, shown = false }
  function frame:SetSize() end
  function frame:SetFrameStrata() end
  function frame:SetFrameLevel() return 0 end
  function frame:RegisterForClicks() end
  function frame:RegisterForDrag() end
  function frame:CreateTexture() return Frame() end
  function frame:SetTexture() end
  function frame:SetHighlightTexture() end
  function frame:SetAllPoints() end
  function frame:SetPoint(point, relative, relativePoint, x, y)
    self.points[#self.points + 1] = { point, relative, relativePoint, x, y }
  end
  function frame:ClearAllPoints() self.points = {} end
  function frame:SetScript(name, callback) self.scripts[name] = callback end
  function frame:GetScript(name) return self.scripts[name] end
  function frame:Show() self.shown = true end
  function frame:GetEffectiveScale() return 1 end
  function frame:GetFrameLevel() return 0 end
  function frame:IsOwned() return false end
  return frame
end

CreateFrame = function(_, name, parent)
  local frame = Frame()
  frame.name = name
  frame.parent = parent
  return frame
end

local cursorX, cursorY = 100, 100
GetCursorPosition = function() return cursorX, cursorY end
IsShiftKeyDown = function() return shiftDown end
shiftDown = false

Minimap = Frame()
GetMinimapShape = function() return "ROUND" end
Minimap.GetWidth = function() return 140 end
Minimap.GetHeight = function() return 140 end
Minimap.GetCenter = function() return 100, 100 end
Minimap.GetEffectiveScale = function() return 0.8 end

UIParent = Frame()
GameTooltip = Frame()
GameTooltip.SetOwner = function() end
GameTooltip.SetText = function() end
GameTooltip.AddLine = function() end
GameTooltip.Show = function() end
GameTooltip.Hide = function() end
GameTooltip.IsOwned = function() return false end

TrinketPriority = {
  InitDatabase = function() end,
  GetCharacterKey = function() return "TestChar-TestRealm" end,
  UI = { Toggle = function() toggled = (toggled or 0) + 1 end },
}
TrinketPriorityDB = { characters = { ["TestChar-TestRealm"] = { minimapAngle = 225 } } }
toggled = 0

assert(loadfile("Minimap.lua") or loadfile("C:\\Program Files (x86)\\World of Warcraft\\_forever_\\Interface\\AddOns\\TrinketPriority\\Minimap.lua"))
dofile("Minimap.lua")

local TP = TrinketPriority
local icon = TP.Minimap.Initialize()
assert(icon and icon.shown)

TP.Minimap.SetAngle(0)
local east = icon.points[#icon.points]
assert(math.abs(east[4] - 75) < 0.0001 and math.abs(east[5]) < 0.0001)

TP.Minimap.SetAngle(90)
local north = icon.points[#icon.points]
assert(math.abs(north[4]) < 0.0001 and math.abs(north[5] - 75) < 0.0001)

TP.Minimap.SetAngle(405)
assert(math.abs(TP.Minimap.GetAngle() - 45) < 0.0001)

shiftDown = true
icon:GetScript("OnDragStart")(icon)
assert(icon:GetScript("OnUpdate") ~= nil)

cursorX, cursorY = 80, 144
icon:GetScript("OnUpdate")()
assert(math.abs(TP.Minimap.GetAngle() - 90) < 0.0001)

icon:GetScript("OnDragStop")(icon)
assert(TrinketPriorityDB.characters["TestChar-TestRealm"].minimapAngle == 90)
assert(icon:GetScript("OnUpdate") == nil)

shiftDown = false
icon:GetScript("OnClick")(icon, "LeftButton")
assert(toggled == 1)
shiftDown = true
icon:GetScript("OnClick")(icon, "LeftButton")
assert(toggled == 1)

local iterations = 100000
local start = os.clock()
for i = 1, iterations do
  TP.Minimap.SetAngle(i)
end
print(string.format("Smoke/unit passed. Benchmark: %d SetAngle calls in %.6fs", iterations, os.clock() - start))
