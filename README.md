# CriminalGamer84's AC8 Mod Control

**[Download AC8 Mod Control 1.4.0](https://github.com/JustBlan1984/AC8-Mod-Control/releases/tag/v1.4.0)** · [HUD guide](docs/HUD-GUIDE.md) · [Build from source](BUILD.md) · [Changelog](CHANGELOG.md)

A Windows launcher for ACE COMBAT 8 mods, with an in-game FOV overlay, HUD positioning and sizing, and custom HUD colors. Offline / single-player only.

## New in 1.4.0

- Center HUD scaling around its center, alongside the corner-panel controls.
- Wingman W-box size and hide controls that keep names and callsigns visible.
- A HUD Color list with **14 entries**, **12 per page**, and separate resets.
- A smooth draggable wheel, brightness slider, and **0–255 RGB fields** with a Set button.
- Independent colors, including timer digits and separate wingman arrows, names, callsigns, and boxes.
- A full-height color panel matching the main overlay's borders and transparency, with stacked green RGB inputs.
- A unified frame update path. The user confirmed the overlay and offscreen names working smoothly after the earlier callback failures.

## Requirements and setup

Install **[experimental UE4SS](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest)** separately first. This configuration was tested with experimental UE4SS; stable has not been validated.

Extract UE4SS into `ACE COMBAT 8/Game/Binaries/Win64`, next to `AceCombat8.exe`, keeping its `ue4ss` subfolder intact.

1. Extract **AC8-Mod-Control-1.4.0.zip** and run **AC8 Mod Control.exe**. No separate Python or .NET installation is needed.
2. For a fresh game, start a campaign once, let it save, then close the game.
3. Select your game folder, keep the mod selections you want, and click **Apply Selected Mods**.
4. Check **No EAC launch** and use **Launch Game** for the first application.
5. Load your campaign and let the game save normally.

After that, launch normally from your usual shortcut. Return to the launcher to apply changes. Close the game before updating. The launcher makes backups during application; keep your intended mod selections when updating.

## FOV and HUD layout

Press **F9 during flight** to open or close the overlay. Drag its title bar to move the menu.

- Set cockpit, HUD-view, and chase FOV independently.
- Move and resize score/time, radar, weapons, and radio portrait panels.
- Radar views, backgrounds, D-pad indicator, and quick commands follow their layout group.
- Center HUD scaling keeps instruments centered and has no position controls.
- Resize or hide wingman W boxes while keeping their text visible.
- Separate circular-arrow buttons reset position and size. The ultrawide preset moves corner panels outward.

Layout and colors save automatically. See the [HUD guide](docs/HUD-GUIDE.md) for detailed controls.

## HUD color list

Select an entry, then drag the wheel, adjust brightness, or enter RGB values and press **Set**.

| Entry | Scope |
| --- | --- |
| All HUD | Shared color for supported groups |
| Score / Target | Score-panel text, not floating enemy aircraft labels |
| Timer | Clock digits |
| Center HUD | Supported center instruments |
| Radar Grid | Radar frame/grid, not every contact symbol |
| Weapon Counts | Weapon readouts |
| Aircraft Icon | Aircraft silhouette; damage colors remain separate |
| Portrait Border | Radio portrait border |
| D-pad | Wingman-command indicator color path |
| Wingman Arrows | Offscreen direction arrows |
| Edge Names | Names beside offscreen arrows |
| Wingman Boxes | Onscreen W boxes |
| Callsigns | Onscreen JOKER labels |
| Wingman Names | Onscreen personal names |

**All HUD** changes the shared color and clears individual overrides. **Use All HUD Color** removes only the selected group's override. A group's **↺** restores its original game color; the reset beside HUD COLOR restores all original colors.

## Other launcher options

- Skins Access for base-game skins on regular aircraft you own.
- Mission access: all missions or through the selected mission.
- MRP credits: chosen minimum balance; purchases still spend credits.
- Aircraft Tree access: regular aircraft purchases and Aircraft Set / Parts access.
- Unlock All Skills and Weapons: tree parts and special weapons for owned aircraft.

F-14A and ADFX-02 grants are not included.

## Current limits

Enemy boxes, the selected enemy aircraft name, active-target arrows, missile-lock indicators, and other remaining markers are still being investigated. They are not individual color controls in this release. Some stores symbols and separate instrument lines may retain native colors.

Wingman detection has been tested with JOKER 2/3/4 (Professor, Tasha, and Noise); other missions/localizations are not fully validated. User flight checks and local regression tests passed, but extended-session and every mission-transition stability are not established.

## Source and verification

The current launcher and scripts are in **[native/](native/)**. Download **AC8-Mod-Control-1.4.0-source.zip** for matching build source. Older Python implementation files remain for history and are not the 1.4.0 build target.

See [validation notes](docs/BUILD-VALIDATION.md), [release hashes](release-manifest.json), and [security-review information](docs/SECURITY-REVIEW.md). Hashes and tests do not constitute antivirus clearance.

Created by **CriminalGamer84 with AI assistance**. Thanks to UE4SS and .NET contributors. Third-party notices are included.
