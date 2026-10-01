# Security review notes — version 1.0.0

## Scope

This repository supplies the entire authored Python launcher and all 15 bundled Lua scripts from the submitted release. Dependencies are identified in `requirements-build.txt`; Python and PyInstaller supply the runtime and bootloader. No game binaries, UE4SS runtime, saves, credentials or private gameplay logs are included.

## Launcher behavior

- Uses Python standard-library modules and tkinter; no application telemetry, updater or authored HTTP client is present in `src/launcher.py`.
- Checks whether AceCombat8.exe is running using Windows `tasklist`.
- Backs up the current Windows user's standard AC8 SaveGames directory into `%LOCALAPPDATA%/AC8 Mod Launcher/Backups` before installation.
- Copies selected Lua scripts to the selected game's `Game/Binaries/Win64/ue4ss/Mods` directory, backs up existing mod folders and updates its own entries in `mods.txt`.
- Optionally changes three Streamline console variables in `Saved/Config/Windows/Engine.ini`. Saves the original and refuses automatic restore when subsequent edits are detected.
- Starts the Steam game URI, or, when selected by the user, launches `AceCombat8.exe -SaveToUserDir` directly with SteamAppId/SteamGameId 2288340. The direct route avoids starting the EAC launcher; it does not uninstall EAC or change its service, Steam launch options, firewall or antivirus settings.
- Clears inherited PyInstaller child-process environment markers and temporarily resets the inherited DLL search directory when starting the game. This prevents the child holding the launcher's extracted runtime directory open.
- No registry persistence, scheduled task, credential collection or privilege elevation is implemented by the launcher.

## Embedded runtime

The executable is a PyInstaller one-file Windows GUI application. Its bootloader extracts Python/Tcl/Tk and bundled files to a temporary directory at runtime. Bundled standard-library dependencies include socket/SSL modules; their presence is not evidence of an authored network client. This repository does not claim to audit all upstream runtime code.

## Lua behavior

The Lua scripts run inside the game via the separately installed UE4SS framework. They inspect and change game objects for mission access, ownership, loadouts, skins and camera/UI controls. They write local rollback snapshots and FOV preferences under their script directories. The FOV overlay reads a small signature from the game executable to gate a build-specific camera property offset. This is game-process modification, not merely a passive settings editor. Review each script for implementation details.

## Original scan findings (2026-09-30)

The release ZIP matched its Nexus-linked VirusTotal SHA-256 exactly. The original EXE's embedded launcher code matched source, and all 15 embedded Lua files matched byte-for-byte. Local Microsoft Defender custom scans with remediation disabled reported no threats for the ZIP and EXE; installed signatures were dated 2026-09-30 02:18 local time.

VirusTotal reported 3/67 detections for the ZIP and 7/71 for the EXE, including Microsoft's `Trojan:Win32/Wacatac.B!ml`. These are different artifacts/reports. Local clean scans do not invalidate the VirusTotal detections. A false positive is suspected but NOT confirmed. Nexus requested source and build instructions for further review; no clearance is claimed.

- ZIP report: https://www.virustotal.com/gui/file/920b762f86084f1b2b1d46a8c53cc2abacd45ee7e9254b0a58f5b260c5324e30
- EXE report: https://www.virustotal.com/gui/file/65cc6c8b43790a9c334b4fc11cc732d1058747b6aa3f965353fdaf99ecd79e16

## Limits

The verification tool checks embedded authored code, not the entire dependency supply chain or every possible runtime behavior. Rebuilding or changing packaging is not evidence that a detection has been resolved. This repository is provided to support independent review of the existing release.
