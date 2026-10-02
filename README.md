# CriminalGamer84's AC8 Mod Control

## 1.2.0 Experimental 4 — Custom MRP and Aircraft Tree

**[Download the current build and matching source](https://github.com/JustBlan1984/AC8-Mod-Control/releases/tag/v1.2.0-experimental.4)** · [Nexus Mods](https://www.nexusmods.com/acecombat8wingsoftheve/mods/9)

Download **AC8-Mod-Control-1.2.0-experimental.4.zip**, extract it, and run **AC8 Mod Control.exe**. This single Windows EXE includes its .NET runtime and mod scripts. No separate Python or .NET installation is needed. UE4SS must be installed separately.

### Required UE4SS version

Use **UE4SS Experimental v3.0.1-1152-ge3ba1016**, the exact build used for testing. Stable 3.0.1 and other builds are unverified.

- [Download the tested UE4SS build](https://github.com/UE4SS-RE/RE-UE4SS/releases/download/experimental-latest/UE4SS_v3.0.1-1152-ge3ba1016.zip)
- [Official UE4SS installation guide](https://docs.ue4ss.com/installation-guide.html)

UE4SS goes alongside Game/Binaries/Win64/AceCombat8.exe. **The mod launcher can stay on your Desktop or another folder; it does not belong in the game folder.** The upstream Experimental download can change; retain the exact tested archive when available.

### Setup — apply once, then play

1. If you have no campaign save, start a campaign once, let it save, then close the game.
2. Open the launcher and verify the detected game folder, or use **Browse**.
3. Use **Back Up Current Save**. All mod options initially start unchecked. Select **every option you want enabled**; applying with an option unchecked disables its script.
4. Set your MRP target and mission option if applicable, then click **Apply Selected Mods**. Apply also creates a verified save backup.
5. Launch using your working mod-compatible offline/single-player route, enter the campaign hangar, and let the game save normally.

**You do not need to keep the launcher open or Apply every session.** UE4SS loads the installed scripts on game startup. Keep UE4SS and the scripts installed for ongoing features such as FOV and loadout repair. Reapply when updating, changing selections, or changing your MRP target. The launcher's optional No EAC launch does not uninstall EAC or change Steam settings.

### Custom MRP / Unlimited

Enable **MRP credits**, then choose **Custom amount** (1–999,999,999) or **Unlimited (999,999,999)**.

This is a **minimum target balance, not an amount added on top**. Higher existing balances are preserved. **Unlimited sets a large balance once; purchases still deduct MRP. It is not an infinite balance or spending freeze.**

Credits apply once per Apply after a stable campaign hangar is available. Allow about 10–15 seconds after the hangar is ready, then back out and reopen the tree if its display is stale. **F6** retries/reapplies the installed target in the hangar. Reapplying can top the balance back up after spending.

### Aircraft Tree and other features

- **Aircraft Tree access:** separate option that opens campaign tree nodes. Purchases remain separate and spend MRP; it does not grant purchased parts or enable Mission Access. A story milestone may still affect menu availability; its exact mission requirement is unconfirmed.
- **Aircraft, skins and SP weapons:** enter the hangar and wait about 5–10 seconds. If a loadout is incomplete, select that aircraft, wait another 5–10 seconds, then reopen its loadout. **F7** is the manual fallback.
- **Mission access:** independent of MRP/tree options. Leave it unchecked to retain normal mission progression. Existing saved unlocks remain. Individual mission cutoffs after Mission 6 have not all been verified in game.
- **FOV overlay:** **F10 during active, unpaused flight**. Installed UE4SS scripts provide it; the launcher can be closed.
- **DLSS settings:** optional INI changes, not a DLSS installer. Verify support in your setup.

### Backups

**Open Backups** opens %LOCALAPPDATA%\AC8 Mod Launcher\Backups. Disabling scripts does not undo changes already saved to your campaign. Preserve a pre-mod backup if you may want to revert.

### Testing — October 2, 2026

The author confirmed MRP and Aircraft Tree functionality, successful purchases, and that purchases remain after saving. Desktop testing visibly confirmed a custom **999,980,000 MRP** balance and preservation of a higher balance when a lower target was chosen. Installer checks passed for independent options, backups, custom/preset configuration and invalid target rejection.

This remains experimental; every node, campaign stage and feature combination has not been tested. The exact tested EXE is published unchanged. Its embedded guide/footer predates the latest confirmation and still describes some tests as pending; these notes contain the current status.

### Source and build instructions

Use **AC8-Mod-Control-1.2.0-experimental.4-source.zip** attached to the [current release](https://github.com/JustBlan1984/AC8-Mod-Control/releases/tag/v1.2.0-experimental.4) for the complete matching C#/Lua source, tests, licenses and **BUILD.md**. Use .NET SDK 10.0.401. Source archives are for building/review, not the playable download.

The repository's native/ directory and automatically generated tag source archives currently retain the earlier launcher source. The explicitly named Experimental 4 source ZIP is the authoritative source package for this release. Historical Python code and review records remain in src/, docs/ and the root build/manifest files.

### Scan disclosure

**No VirusTotal result or Nexus approval has been verified for this exact Experimental 4 binary.** Earlier versions had unresolved detections and Nexus quarantine; those reports do not describe this file. No false-positive clearance is claimed. Keep antivirus enabled. SHA256SUMS.txt identifies the release files; checksums do not certify safety.

### Credits

Created by **CriminalGamer84 with AI assistance**. Thanks to UE4SS contributors for the separately required framework and Microsoft/.NET contributors for the included runtime. Third-party notices are bundled with the EXE and source. No game binaries, UE4SS runtime, personal saves or private logs are distributed.

**Offline/single-player only. Use at your own risk.** Online use may result in account restrictions or bans.
