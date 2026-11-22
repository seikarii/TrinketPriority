# Architecture audit

## Scope and runtime

The addon loads ten Lua files in the order declared by `TrinketPriority.toc`. The TOC targets interface `16001`; the code uses Lua 5.1-compatible syntax and both legacy and namespaced WoW item/container APIs. The README describes Retail 12.1+ compatibility. The repository has five standalone Lua test scripts and no external runtime dependency.

## Current modules and dependencies

| Module | Responsibility | Main dependencies |
| --- | --- | --- |
| `Core.lua` | Namespace, saved variables, character/profile migration, item and player helpers | WoW unit, inventory-link, cooldown APIs |
| `Inventory.lua` | Cached inventory snapshot, bag lookups, cooldown access and cursor-based equip transaction | `Core`, WoW bag/equipment/cursor APIs |
| `Config.lua` | Profile list and passive mutations | `Core`, `UI`, `Priority`, `Overlay` |
| `Priority.lua` | Candidate selection, request queue, combat/death deferral and delayed execution | `Core`, `Inventory`, `Overlay` |
| `Overlay.lua` | Movable visual frame, icons, equipped/next markers and native cooldown widgets | `Core`, `Priority` (click action only) |
| `UI.lua` | Options window, row callbacks and overlay settings | `Core`, `Config`, `Profiles`, `Overlay` |
| `Profiles.lua` | Profile tab widgets and profile-name resolution | `Core`, `UI` |
| `Commands.lua` | Slash command parsing and dispatch | `Config`, `Priority`, `UI`, `Profiles`, `Overlay`, `Minimap` |
| `Minimap.lua` | Saved minimap icon position and drag behavior | `Core`, WoW minimap/tooltip APIs |
| `Main.lua` | Addon event dispatch, initialization and command registration | All modules above |

The TOC order makes dependencies available before use. `UI.lua` and `Profiles.lua` create widgets while loading, before `ADDON_LOADED`; profile state is initialized in Core at file load and again during addon initialization.

## Existing execution flows

### Events and lifecycle

Before this change, `Main.lua` registered addon load, combat, death/alive, bag, equipment, inventory and cooldown events. It invalidated `Inventory` on bag/equipment changes and refreshed Priority. `Overlay.lua` independently registered several of the same bag/equipment/cooldown events and called `Overlay.Refresh()` itself. The overlay also installed a 0.5-second `OnUpdate` loop. This duplicated update ownership and made visual updates perform full state reads.

The Priority request timer is a separate `OnUpdate` used only for the intentional 0.1-second deferred equip request. The minimap icon uses `OnUpdate` only while the user drags it. Neither is overlay polling.

### Priority and equipment

`/trinket` marks an automatic request pending and schedules it outside combat/death. Processing checks whether the current slot-13 trinket was used (or is passive), selects the first available configured use item, or falls back to the configured passive. Manual requests replace automatic pending requests. Combat/death events cancel the request timer; alive/out-of-combat events reschedule pending work. `Inventory.EquipItem` preserves an occupied cursor, picks an item from bags or slot 14, equips it into slot 13 and clears a stuck cursor.

Before refactoring, candidate selection took a snapshot but called helper methods that re-read the cached snapshot for each item. `CurrentTrinketWasUsed` also fetched slot 13 separately. These calls did not all rebuild the snapshot because it was cached, but repeated method/API work obscured the single-snapshot contract. `EquipItem` invalidated at entry, after bag operations, and on a failed search.

### Overlay

Before refactoring, `Overlay.Refresh()` fetched active profile, snapshot, candidate, item icons, equipped cooldowns, and bag location/cooldown for each listed entry. It also updated the entire structure every half second. A cooldown text depended on those periodic refreshes. The cooldown frame itself already supports native cooldown display.

## Findings and changes

1. **General overlay polling existed.** Removed the overlay `OnUpdate` and its duplicate event registrations. Main is now the only owner of addon state events; Priority passes a prepared state into `Overlay.Render`.
2. **Rendering performed business/data reads.** `Overlay.Render(state)` consumes entries, equipped IDs, candidate and cooldown records. It no longer reads inventory, searches bags or calls priority selection. Native `Cooldown:SetCooldown` handles countdown visuals; the periodically refreshed numeric countdown text was removed.
3. **Candidate scans repeated snapshot helper lookups.** Priority scans now use one snapshot's `equipped` and `byItemID` tables directly. A Priority refresh also builds the cooldown records for the overlay and passes one state object.
4. **Lua 5.1 loop callback captures were unsafe.** UI row callbacks and profile tab callbacks capture a per-iteration local index.
5. **Inventory equipment invalidation remains conservative.** Inventory is invalidated at the beginning/end of equip attempts because protected equipment changes can be asynchronous and bag links may be stale until the equipment event. Failed searches may invalidate unnecessarily; removing that invalidation is a small possible follow-up after validating all client APIs.

## Event ownership and invalidation map

| Event | Receiver | Action |
| --- | --- | --- |
| `ADDON_LOADED` for this addon | `Main.lua` | Initialize saved variables and UI/overlay/minimap; compute initial overlay state |
| `BAG_UPDATE`, `BAG_UPDATE_DELAYED` | `Main.lua` | Invalidate inventory snapshot, recompute candidate and overlay state |
| `PLAYER_EQUIPMENT_CHANGED` | `Main.lua` | Invalidate inventory snapshot, recompute candidate and overlay state |
| `UNIT_INVENTORY_CHANGED` for player | `Main.lua` | Same as equipment change |
| `SPELL_UPDATE_COOLDOWN`, `BAG_UPDATE_COOLDOWN` | `Main.lua` | Recompute selection/cooldown display; cached inventory locations remain valid |
| `PLAYER_REGEN_DISABLED`, `PLAYER_DEAD` | `Main.lua` | Cancel pending equip timer |
| `PLAYER_REGEN_ENABLED`, `PLAYER_ALIVE`, `PLAYER_UNGHOST` | `Main.lua` | Schedule pending request if one exists |

There is one addon frame registering these events. The overlay is an event-free renderer. Bag update variants can both arrive and currently cause two refreshes; there is no event coalescing. This is a remaining optimization opportunity if profiling or a test shows it matters.

## Target flow after the change

1. `Main.lua` receives an invalidating event.
2. For inventory/equipment events, it invalidates the snapshot once per event.
3. `Priority.RefreshOverlayState()` gets the cached/rebuilt snapshot, selects at most one next candidate, collects relevant cooldown data, and assembles an overlay state.
4. `Overlay.Render(state)` updates layout, item icon textures, markers and native cooldown widgets without querying the inventory or selecting a candidate.

Explicit profile/config changes call the same Priority refresh path. Manual click requests and automatic requests still use the existing request flow.

## Compatibility and risks

- TOC interface is `16001`; no newer Lua syntax was introduced. The code retains namespaced and legacy API fallbacks.
- `Cooldown:SetCooldown` is the existing native cooldown mechanism. Numeric countdown text no longer updates because it previously required polling; the native cooldown swipe remains active.
- Bag/equipment API values may be stale during equip transactions. Existing event invalidation remains necessary.
- Calls to `GetInventoryItemCooldown` and bag cooldown APIs happen on Priority refresh, including cooldown events. They no longer occur from an overlay tick.
- Protected equipment operations are still deferred outside combat and cursor ownership is preserved.
- The repository cannot simulate the actual WoW protected-action environment; final in-client confirmation remains appropriate.

## Tests and evidence

Existing tests: profile migration/switching, minimap behavior, config argument validation, inventory snapshot/equip behavior and Priority selection. They were run with the installed Lua 5.1 executable and passed before final audit documentation. Static inspection confirms the overlay polling and duplicate overlay event registrations have been removed. No in-game CPU/FPS benchmark is available in this environment.

The existing tests do not cover Overlay render purity, event duplication, or the manual/deferred request matrix. Those remain test coverage gaps.
