# CriminalGamer84's AC8 Mod Control

Complete source for the AC8 Mod Control 1.0.0 launcher and its bundled UE4SS Lua mods, supplied for independent security review.

**Nexus page:** https://www.nexusmods.com/acecombat8wingsoftheve/mods/9

## Review entry points

- [Build instructions](BUILD.md) — exact tool versions, setup, build and verification commands.
- [Security review notes](docs/SECURITY-REVIEW.md) — file operations, launch behavior, scan results and limitations.
- [Launcher source](src/launcher.py) — Python/Tkinter UI, backups, installation, graphics configuration and launch.
- [Bundled mod source](src/bundled) — all 15 Lua files shipped inside the executable.
- [Release manifest](release-manifest.json) — original ZIP/EXE hashes and per-source-file SHA-256 hashes.
- [User guide](docs/HOW%20TO%20USE.txt).

## Features

Selectable cumulative mission access, campaign feature flags, aircraft/skin/SP weapon unlocks, in-game FOV controls, save backups, optional native DLSS configuration and optional direct game launch without the EAC launcher for single-player use.

The game and a compatible UE4SS installation are separately required to use the mods. Neither is needed to build the launcher or run the isolated filesystem tests. UE4SS and game files are not redistributed here.

## Release snapshot

The files under `src/` are unchanged copies of the 1.0.0 source. Build/review documentation and verification tools were added afterward. This is a source review repository, not a new release or a claim that antivirus detections have been cleared. A rebuild is not guaranteed to be byte-identical to the original executable.

Use offline/single-player only and back up saves. Online use is not recommended. See the user guide for tested behavior and limitations. Public availability of source does not grant a general redistribution license; third-party components retain their own licenses.
