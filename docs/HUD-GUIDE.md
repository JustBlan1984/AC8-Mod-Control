# HUD customization guide — 1.4.0

Open F9 during flight. HUD COLOR opens the color panel alongside the FOV/layout overlay. Both panels share the same height and visual theme. Twelve entries fit on each page; arrows change pages.

## Choosing a color

1. Select an element in the list; its name appears above the wheel.
2. Hold and drag inside the wheel to change hue and saturation. Dragging beyond the rim keeps full saturation.
3. Adjust brightness, or type whole numbers from 0 to 255 in the stacked R/G/B fields and click SET.
4. Wheel changes save after release; SET saves RGB input. Invalid values are rejected without applying a color.

## Shared color, overrides, and resets

- ALL HUD sets the shared color for supported elements and clears individual overrides.
- Selecting an individual entry changes only that group's choice.
- USE ALL HUD COLOR removes the selected group's override and follows the shared color again.
- The circular arrow beside an entry restores that group's original game color.
- The circular arrow beside the main HUD COLOR button resets all original colors.

Example: choose green for ALL HUD, then blue for RADAR GRID. USE ALL HUD COLOR on RADAR GRID makes it green again. Its circular reset restores native radar color instead.

## Saved settings

Settings live next to the installed AC8AdjustableFOV Lua scripts. `HUD-layout.ini` stores layout/sizing, `HUD-color-profiles.ini` stores colors, and `FOV-memory.ini` stores view FOV settings. The old global `HUD-colors.ini` is read when initializing profiles if no profile file exists. Personal settings are not included in release downloads.

## Scope

The README lists all fourteen entries. Enemy target boxes/names, lock-state indicators, radar contacts, and some other markers remain outside the supported list. Damage/warning colors remain separate from the normal silhouette control.

Individual paths need broader mission/localization testing. Report the selected group, RGB values, game view, and a screenshot when an item does not respond as expected.
