-- Overlay lifecycle, purity and incremental render tests with minimal frame stubs.
local createdFrames, textureWrites, pointWrites, cooldownWrites, iconLookups = 0, 0, 0, 0, 0
local function Object(kind)
  local o = { kind = kind, shown = false, scripts = {} }
  function o:SetWidth() end
  function o:SetHeight() end
  function o:SetFrameLevel() return 1 end
  function o:GetFrameLevel() return 1 end
  function o:SetFrameStrata() end
  function o:SetMovable() end
  function o:EnableMouse() end
  function o:RegisterForDrag() end
  function o:SetScript(k, v) self.scripts[k] = v end
  function o:CreateTexture() return Object("Texture") end
  function o:CreateFontString() return Object("FontString") end
  function o:SetAllPoints() end
  function o:SetTexture() textureWrites = textureWrites + 1 end
  function o:SetVertexColor() end
  function o:SetPoint() pointWrites = pointWrites + 1 end
  function o:ClearAllPoints() pointWrites = pointWrites + 1 end
  function o:SetTexCoord() end
  function o:SetText(value) self.text = value end
  function o:SetTextColor() end
  function o:Hide() self.shown = false end
  function o:Show() self.shown = true end
  function o:IsShown() return self.shown end
  function o:SetCooldown() cooldownWrites = cooldownWrites + 1 end
  function o:SetHideCountdownNumbers() end
  function o:StartMoving() end
  function o:StopMovingOrSizing() end
  function o:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
  function o:SetFrameLevel() end
  function o:RegisterEvent() error("Overlay must not register events") end
  return o
end

CreateFrame = function(kind)
  createdFrames = createdFrames + 1
  return Object(kind)
end
UIParent = Object("Parent")
C_Item = { GetItemIconByID = function(id) iconLookups = iconLookups + 1; return "icon:" .. id end }
TrinketPriority = {
  USE_MAX = 7,
  GetActiveProfile = function() return { use = { { id = 10, name = "A" } }, overlay = {} } end,
  RemainingCooldown = function(start, duration) return duration - start end,
  Inventory = { GetSnapshot = function() error("Render queried inventory") end, FindBagItem = function() error("Render searched bags") end },
  Priority = { GetNextUseCandidate = function() error("Render selected priority") end },
}
dofile("Overlay.lua")
local O = TrinketPriority.Overlay
O.Initialize()
local state = {
  entries = { { id = 10, name = "A" } },
  equipped = { [13] = 99 },
  candidate = { id = 10, name = "A" },
  cooldowns = { [10] = { start = 0, duration = 20 } },
}
O.Render(state)
assert(iconLookups == 1)
local framesAfterFirstInit = createdFrames
O.Initialize()
assert(createdFrames == framesAfterFirstInit)
local forwarded
local render = O.Render
O.Render = function(s) forwarded = s; return render(s) end
O.Refresh()
assert(forwarded == state and forwarded.candidate.id == 10 and forwarded.entries[1].id == 10)
assert(iconLookups == 1)

local oldTextureWrites, oldPointWrites, oldCooldownWrites = textureWrites, pointWrites, cooldownWrites
local cooldownState = {
  entries = state.entries,
  equipped = state.equipped,
  candidate = state.candidate,
  cooldowns = { [10] = { start = 0, duration = 30 } },
}
O.Render(cooldownState)
assert(textureWrites == oldTextureWrites)
assert(pointWrites == oldPointWrites)
assert(cooldownWrites == oldCooldownWrites + 1)
assert(iconLookups == 1)
print("Overlay lifecycle and incremental render tests passed.")
