# CriminalGamer84's AC8 Mod Control

## Version 1.1.1 — Single EXE Windows launcher

[Download 1.1.1](https://github.com/JustBlan1984/AC8-Mod-Control/releases/tag/v1.1.1) · [Build instructions](native/BUILD.md) · [User guide](native/HOW%20TO%20USE.txt)

Download the EXE from the release assets and run it. The launcher, Microsoft .NET runtime and all 15 Lua scripts are included. No surrounding runtime folder or separate Python/.NET installation is required. Supporting files extract automatically on startup. UE4SS must still be installed separately.

### Setup

1. Install compatible UE4SS separately. Start a campaign once if needed, let it save, then close the game.
2. Run the downloaded EXE and choose your game folder.
3. Use **Back Up Current Save**, select your mods, then **Apply Selected Mods**.
4. Launch using a route compatible with your mods. Load the campaign and let the game save. F10 opens the FOV overlay during active, unpaused flight.

Features include mission access, aircraft/skin/SP weapon unlocks, FOV overlay, verified save backups, optional DLSS settings, and optional direct single-player launch. Existing backups and older DLSS restore records remain supported.

**Open Backups** opens `%LOCALAPPDATA%\AC8 Mod Launcher\Backups`. Use offline/single-player only. Disabling scripts does not reverse changes already saved to a campaign.

### Verification and scan status

The author confirmed successful in-game testing of this single EXE on October 1, 2026. All 30 isolated checks passed. Standalone startup and all 15 extracted Lua files were verified. This does not establish exhaustive testing of every feature or aircraft.

Nexus displayed scanning in progress when 1.1.1 was uploaded. No antivirus clearance is claimed for this EXE. Earlier scan reports concern different files; changing packaging does not prove previous detections were false positives.

### Source and credits

[Current C# source and tests](native/) include build instructions. The release source ZIP is for building/review, not running. Original Python source and review records remain in `src/`, `docs/`, and the root `BUILD.md` for historical review.

Created by CriminalGamer84 with AI assistance. Thanks to UE4SS contributors for the separately required framework and Microsoft/.NET contributors for the included runtime. Runtime licenses and third-party notices are bundled and extracted with the application; their respective licenses apply.

[Nexus Mods page](https://www.nexusmods.com/acecombat8wingsoftheve/mods/9)

Version 1.1.0 is the older folder-based package. The 1.0.0 binary was withdrawn. Use 1.1.1 for the single EXE.
