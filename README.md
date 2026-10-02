# CriminalGamer84's AC8 Mod Control

Windows launcher for selectable ACE COMBAT 8 mods: mission access, aircraft/skins/SP weapons, FOV overlay, save backups, optional DLSS configuration, and optional direct single-player launch.

## Version 1.1.0 — C#/.NET Windows launcher

[Download 1.1.0](https://github.com/JustBlan1984/AC8-Mod-Control/releases/tag/v1.1.0) · [Build instructions](native/BUILD.md) · [User guide](native/HOW%20TO%20USE.txt)

The launcher has been rewritten in C# using Windows Forms. Python and PyInstaller are no longer used in 1.1.0. The Windows x64 package includes the .NET runtime and supporting files; **extract the entire ZIP and keep the files together**. The EXE is not a standalone file. A separate .NET installation is not required.

All 15 bundled Lua files match the original 1.0.0 release. The original backup location and Python launcher's DLSS restore record remain supported.

### Validation and security status

- Thirty isolated checks passed, including save backups, mod installation/disable, DLSS restoration, legacy restore records, launch configuration and running-game guards.
- The published EXE initialized successfully and its UI was rendered and inspected.
- A local Microsoft Defender custom scan of the published folder reported no threats on October 1, 2026.
- **The author confirmed successful in-game testing on October 1, 2026. VirusTotal results and Nexus clearance for 1.1.0 remain pending.** A local scan is not proof of safety, and a rewrite does not establish that previous detections were false positives.

The old 1.0.0 binary download was withdrawn. Its source, build documentation, scan reports and verification tools remain available for review. Historical 1.0.0 VirusTotal results do not describe the new 1.1.0 files.

## Setup

1. Install a compatible UE4SS runtime separately. UE4SS and game files are not included.
2. If needed, start a campaign once and let the game save, then close it.
3. Extract the entire release ZIP and run **AC8 Mod Control.exe**.
4. Select the game installation folder. Use **Back Up Current Save** before applying changes; **Apply Selected Mods** also makes a verified backup.
5. Choose the mods and mission access, apply, then launch and load the campaign. Open the hangar normally and let the game save. F10 opens the FOV overlay in active unpaused flight.

Backups: **Open Backups**, or `%LOCALAPPDATA%\AC8 Mod Launcher\Backups`.

Use offline/single-player only. Online use is not recommended. Disabling scripts does not remove saved unlocks; completely removing the scripts has not been verified for every aircraft/loadout. Mission cutoffs after Mission 6 still need in-game verification.

## Source map

- [Current C# launcher and tests](native/)
- [Current build and review notes](native/BUILD.md)
- [Original Python launcher and Lua source](src/)
- [Original 1.0.0 build instructions](BUILD.md)
- [Original 1.0.0 security review](docs/SECURITY-REVIEW.md)
- [Original release manifest](release-manifest.json)

[Nexus Mods page](https://www.nexusmods.com/acecombat8wingsoftheve/mods/9)

Public source availability does not grant a blanket redistribution license. Third-party components retain their upstream licenses.
