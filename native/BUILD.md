# AC8 Mod Control 1.1.2 - Single EXE
Requires .NET SDK 10.0.401 to build; runtime 10.0.12 is included in the output.
Build: dotnet publish AC8ModControl.csproj -c Release -r win-x64 --self-contained true -o publish --source https://api.nuget.org/v3/index.json
Test: dotnet run --project tests/CoreTests.csproj -- bundled
Distribute only publish/AC8 Mod Control.exe. All Lua files, runtime files, user guide and license notices are bundled and extracted by the Microsoft .NET host on startup. IncludeAllContentForSelfExtract uses the .NET compatibility extraction mode. No obfuscation or third-party packer is used.
Version 1.1.2 fixes automatic mission and aircraft application on fresh campaigns, retries unsuccessful aircraft repairs, and watches for game-created loadout records. The author confirmed aircraft, special weapons and skins appeared automatically during local testing on October 1, 2026. Menu refresh can require waiting and reopening the loadout. No Nexus or VirusTotal clearance is claimed for this build.

