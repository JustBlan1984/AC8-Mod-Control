# AC8 Mod Control 1.1.0 — C#/.NET launcher

Windows x64, .NET 10 WinForms. This is a native Windows UI backed by managed C#; it is not a NativeAOT build. No Python, PyInstaller, packer, self-extracting application bundle, telemetry, or updater is included. The existing 15 Lua files are unchanged from 1.0.0.

## Build

Install Microsoft's .NET SDK 10.0.401. The SDK used here resolves Microsoft runtime 10.0.12. No third-party NuGet packages are used.

From this source folder:

```powershell
dotnet run --project tests/CoreTests.csproj -- bundled
dotnet publish AC8ModControl.csproj -c Release -r win-x64 --self-contained true -o publish --source https://api.nuget.org/v3/index.json
```

Distribute the entire publish folder, including bundled/, runtime DLLs, runtime notices, and the user guide. Do not distribute the EXE alone. PublishSingleFile and PublishTrimmed are false. The included runtime means users do not need to separately install .NET.

The optional UiSmoke project renders the actual form without touching the game or save:

```powershell
dotnet run --project tests/UiSmoke/UiSmoke.csproj -- C:/Temp/ac8-preview.png
```

## Validation and limits

Thirty isolated checks passed: exact backup contents, nested saves, unchanged save file, unrelated mod preservation, marker handling, mission mappings, enabling/disabling, four INI encodings and byte-exact restoration, later-edit protection, legacy Python DLSS record restoration, launch arguments, missing-save and running-game guards.

The rendered form was inspected. A local Microsoft Defender custom scan with remediation disabled reported no threats in the published folder on October 1, 2026. This does not establish VirusTotal or Nexus clearance. The author confirmed successful in-game testing on October 1, 2026. The exact coverage of that test was not enumerated; no claim is made that every feature/aircraft combination was retested or that previous antivirus detections have been resolved.

## Behavior

Backups remain under %LOCALAPPDATA%/AC8 Mod Launcher/Backups. The previous launcher's dlss-state.json is supported. The installer backs up the current campaign and existing mod directories before updating its three mod entries. It attempts rollback if installation fails. It rejects linked/reparse paths for modified or backed-up files. Saved unlocks are not reversed when disabling scripts.

DLSS configuration uses the same three settings as 1.0.0, preserving unrelated INI values and refusing restoration if the file changed after enabling. Launch uses either the existing Steam game URI or the game EXE with -SaveToUserDir and Steam application ID 2288340. It does not change EAC services or Steam settings.

The source is supplied for review. Microsoft runtime components retain their upstream licenses. UE4SS and game files are not included.
