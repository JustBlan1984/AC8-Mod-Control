# Build AC8 Mod Control 1.2.0 Experimental 5

Windows x64; .NET SDK 10.0.401 (global.json), .NET runtime 10.0.12 included by the tested self-contained build.

From this native source directory:

```powershell
dotnet publish AC8ModControl.csproj -c Release -r win-x64 --self-contained true -o publish --source https://api.nuget.org/v3/index.json
dotnet run --project tests/ProgressionTests.csproj -- bundled
```

Distribute publish/AC8 Mod Control.exe. The Microsoft .NET host extracts the bundled runtime, Lua scripts, guide and licenses at startup. No separate Python/.NET installation is required for players. UE4SS Experimental v3.0.1-1152-ge3ba1016 must be installed separately.

Experimental 5 refreshes version labels and embedded documentation. Gameplay scripts are unchanged from Experimental 4. The author confirmed purchases work and persist after saving; custom MRP was tested in game.

Tests cover selection isolation, save backups, custom/preset serialization, and invalid-target rejection. Successful unit tests do not establish in-game behavior or malware clearance. Rebuilt binaries may differ; the release SHA256SUMS.txt identifies the distributed artifacts.
