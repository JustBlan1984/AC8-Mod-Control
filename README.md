# CriminalGamer84's AC8 Mod Control

## Version 1.1.2 - Single EXE Windows launcher

[Download 1.1.2](https://github.com/JustBlan1984/AC8-Mod-Control/releases/tag/v1.1.2)  /  [Build instructions](native/BUILD.md)  /  [User guide](native/HOW%20TO%20USE.txt)

Download the EXE from the release assets and run it. The launcher, Microsoft .NET runtime and all 15 Lua scripts are included. No surrounding runtime folder or separate Python/.NET installation is required. Supporting files extract automatically on startup. UE4SS must still be installed separately.

### Setup

1. Install compatible UE4SS separately. Start a campaign once if needed, let it save, then close the game.
2. Run the downloaded EXE and choose your game folder.
3. Use **Back Up Current Save**, select your mods, then **Apply Selected Mods**.
4. Launch using a route compatible with your mods. Load the campaign and let the game save. F10 opens the FOV overlay during active, unpaused flight.

Features include mission access, aircraft/skin/SP weapon unlocks, FOV overlay, verified save backups, optional DLSS settings, and optional direct single-player launch. Existing backups and older DLSS restore records remain supported.

**Open Backups** opens `%LOCALAPPDATA%\AC8 Mod Launcher\Backups`. Use offline/single-player only. Disabling scripts does not reverse changes already saved to a campaign.

### Automatic unlocks and choosing mods

All mod checkboxes start unchecked. Select only the features you want; leave Mission access unchecked to retain normal mission progression. Aircraft and mission scripts are separate, although aircraft-only fresh-campaign gameplay has not yet been verified. Applying unchecked options disables those scripts; it does not reverse unlocks already saved.

Enter the campaign hangar and wait about 5–10 seconds before selecting an aircraft. If SP weapons or skins remain locked, select the aircraft, wait another 5–10 seconds, then back out and reopen its weapon/skin selection. The game must create loadout records before they can be updated. F7 is a manual fallback, normally unnecessary.

Version 1.1.2 fixes fresh-campaign automatic triggers and retries failed aircraft repairs. When upgrading, close the game and use Apply Selected Mods in the new launcher once. The EXE can stay on your Desktop; it does not belong in the game folder.

### Verification and scan status

The author confirmed automatic aircraft, SP weapon and skin unlocks with the updated scripts on October 1, 2026. Mission application was verified in the game log. All 30 isolated checks passed. Standalone startup and all 15 extracted Lua files were verified. This does not establish exhaustive testing of every feature or aircraft.

**Version 1.1.2 is a new binary; no scan result or Nexus approval has been verified for it.** The following report is historical and applies only to 1.1.1. Nexus quarantined the 1.1.1 EXE. On October 1, 2026, [VirusTotal reported 1/70 detections](https://www.virustotal.com/gui/file/056b53e8b2d5d1ef3997c045809b9ac6e0828e4d0bd87597a591fc930555faa1): **Bkav Pro - W32.Malware.B0B0BDAF**. Microsoft reported **Undetected**. The cause remains unresolved; no false positive or security clearance has been confirmed. Earlier reports concern different files. Keep antivirus protection enabled.

### Source and credits

[Current C# source and tests](native/) include build instructions. The release source ZIP is for building/review, not running. Original Python source and review records remain in `src/`, `docs/`, and the root `BUILD.md` for historical review.

Created by CriminalGamer84 with AI assistance. Thanks to UE4SS contributors for the separately required framework and Microsoft/.NET contributors for the included runtime. Runtime licenses and third-party notices are bundled and extracted with the application; their respective licenses apply.

[Nexus Mods page](https://www.nexusmods.com/acecombat8wingsoftheve/mods/9)

Version 1.1.0 is the older folder-based package. The 1.0.0 binary was withdrawn. Use 1.1.2 for the updated single EXE.
