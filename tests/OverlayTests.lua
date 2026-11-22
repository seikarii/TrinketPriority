-- Overlay lifecycle, purity and incremental render tests with minimal frame stubs.
local createdFrames, textureWrites, pointWrites, cooldownWrites, iconLookups = 0, 0, 0, 0, 0
local iconAvailable, loadRequests = { [10] = true }, {}
local profile = { use = { { id = 10, name = "A" } }, overlay = {} }
local overlayFrame
local function Object(kind)
  local o = { kind = kind, shown = false, scripts = {} }
  function o:SetWidth(value) self.width = value end
  function o:SetHeight(value) self.height = value end
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
  function o:SetTexture(value) textureWrites = textureWrites + 1; self.texture = value end
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
  local object = Object(kind)
  if not overlayFrame and kind == "Frame" then overlayFrame = object end
  return object
end
UIParent = Object("Parent")
_G.C_Item = {
  GetItemIconByID = function(id)
    iconLookups = iconLookups + 1
    if iconAvailable[id] then return "icon:" .. id end
  end,
  RequestLoadItemDataByID = function(id) loadRequests[id] = (loadRequests[id] or 0) + 1 end,
}
TrinketPriority = {
  USE_MAX = 7,
  GetActiveProfile = function() return profile end,
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
assert(O.Render(nil) == false and O.Render({}) == false)
assert(O.Render({ entries = { {} }, equipped = {}, cooldowns = {} }) == false)
O.Refresh()
assert(forwarded == state)

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

-- Missing item icons request data once and update only the currently displayed ID.
local lazyState = { entries = { { id = 20, name = "Lazy" } }, equipped = {}, cooldowns = {}, candidate = nil }
O.Render(lazyState)
assert(loadRequests[20] == 1)
O.Render(lazyState)
assert(loadRequests[20] == 1)
local beforeArrival = textureWrites
iconAvailable[20] = true
assert(O.OnItemDataLoadResult(20, true))
assert(textureWrites == beforeArrival + 1)

-- A failed load is remembered rather than requested on every subsequent render.
local failedState = { entries = { { id = 23, name = "Failed" } }, equipped = {}, cooldowns = {}, candidate = nil }
O.Render(failedState)
assert(loadRequests[23] == 1)
assert(not O.OnItemDataLoadResult(23, false))
O.Render(failedState)
assert(loadRequests[23] == 1)

-- A late result for a removed item does not change the new item's texture.
local oldRequestState = { entries = { { id = 24, name = "Old" } }, equipped = {}, cooldowns = {}, candidate = nil }
O.Render(oldRequestState)
assert(loadRequests[24] == 1)
iconAvailable[25] = true
local newState = { entries = { { id = 25, name = "New" } }, equipped = {}, cooldowns = {}, candidate = nil }
O.Render(newState)
local beforeOldResult = textureWrites
iconAvailable[24] = true
assert(O.OnItemDataLoadResult(24, true))
assert(textureWrites == beforeOldResult)

-- Empty state is explicit and sizing uses its entry count without priority calls.
local emptyState = { entries = {}, equipped = {}, cooldowns = {}, candidate = nil }
assert(O.Render(emptyState))
-- An icon loaded while hidden must reuse the cache when it reappears, without another request or hidden texture write.
local hiddenState = { entries = { { id = 26, name = "Hidden" } }, equipped = {}, cooldowns = {}, candidate = nil }
O.Render(hiddenState)
assert(loadRequests[26] == 1)
assert(O.Render(emptyState))
local beforeHiddenArrival = textureWrites
iconAvailable[26] = true
assert(O.OnItemDataLoadResult(26, true))
assert(textureWrites == beforeHiddenArrival)
assert(O.Render(hiddenState))
assert(loadRequests[26] == 1)
local textureAfterReappearance = textureWrites
assert(O.Render(hiddenState))
assert(textureWrites == textureAfterReappearance)

-- A late successful result for a substituted item remains in cache only and never writes to the replacement slot.
local replacedState = { entries = { { id = 27, name = "Replaced request" } }, equipped = {}, cooldowns = {}, candidate = nil }
O.Render(replacedState)
assert(loadRequests[27] == 1)
local replacementState = { entries = { { id = 28, name = "Replacement" } }, equipped = {}, cooldowns = {}, candidate = nil }
iconAvailable[28] = true
O.Render(replacementState)
local beforeLateResult = textureWrites
iconAvailable[27] = true
assert(O.OnItemDataLoadResult(27, true))
assert(textureWrites == beforeLateResult)
assert(loadRequests[27] == 1)
assert(O.Render(replacementState))
assert(textureWrites == beforeLateResult)
assert(O.Render(emptyState))

local latest
O.Render = function(s) latest = s; return render(s) end
O.Refresh()
assert(latest == emptyState)
O.SetIconSize(60)
assert(overlayFrame.height == 94)
O.SetIconSize(64)
O.SetIconSize(64)
assert(O.Render({ entries = { { id = 10 } }, equipped = {}, cooldowns = {}, candidate = nil }))
O.SetIconSize(68)
assert(O.Render({ entries = { { id = 10 }, { id = 20 } }, equipped = {}, cooldowns = {}, candidate = nil }))
O.SetIconSize(72)

print("Overlay lifecycle and incremental render tests passed.")
