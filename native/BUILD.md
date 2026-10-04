# Build AC8 Mod Control

Requires Windows x64 and .NET SDK 10.0.401.

```powershell
dotnet run --project tests/ProgressionTests.csproj -- bundled
dotnet publish AC8ModControl.csproj -c Release -r win-x64 --self-contained true -o publish
```

The release executable embeds the Lua modules, runtime, guide and notices. UE4SS is installed separately.
