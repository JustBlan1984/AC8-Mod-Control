# Build AC8 Mod Control 1.4.0

Use Windows x64 and .NET SDK **10.0.401** (see native/global.json).

```powershell
cd native
dotnet run --project tests/ProgressionTests.csproj -- bundled
dotnet publish AC8ModControl.csproj -c Release -r win-x64 --self-contained true -o publish
```

The output is `native/publish/AC8 Mod Control.exe`, a self-contained launcher with bundled Lua scripts and notices. UE4SS is separate.

`native/` is the current build target. Root `src/`, `tests/`, and `tools/build.py` describe the older Python launcher. The old PyInstaller verifier does not validate this .NET executable. Use release-manifest.json to check downloaded artifact hashes.
