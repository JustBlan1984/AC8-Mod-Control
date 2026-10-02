# AC8 Mod Control 1.1.1 - Single EXE
Requires .NET SDK 10.0.401 to build; runtime 10.0.12 is included in the output.
Build: dotnet publish AC8ModControl.csproj -c Release -r win-x64 --self-contained true -o publish --source https://api.nuget.org/v3/index.json
Test: dotnet run --project tests/CoreTests.csproj -- bundled
Distribute only publish/AC8 Mod Control.exe. All Lua files, runtime files, user guide and license notices are bundled and extracted by the Microsoft .NET host on startup. IncludeAllContentForSelfExtract uses the .NET compatibility extraction mode. No obfuscation or third-party packer is used.
This changes distribution, not game logic. The 1.1.0 folder build was user-tested in game; the author also confirmed successful in-game testing of this single EXE on October 1, 2026. Thirty isolated checks passed and all 15 extracted Lua files matched the source. No Nexus or VirusTotal clearance is claimed.

