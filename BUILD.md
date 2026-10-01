# Build AC8 Mod Control 1.0.0 on Windows

## Prerequisites

Use Windows x64 and CPython **3.14.7 x64**, including Tcl/Tk, tkinter and pip. The original executable was built with PyInstaller **6.22.3** and pyinstaller-hooks-contrib **2026.8**. All recorded build dependencies are pinned in `requirements-build.txt`.

Obtain Python from https://www.python.org/downloads/windows/ and packages from the official Python Package Index. If these exact versions are unavailable in your environment, do not silently substitute another version when comparing the release: report the difference. Python and PyInstaller are build dependencies; end users do not need Python for the packaged executable.

## Setup

Extract/clone this repository and open PowerShell in its root. `python` below must refer to the intended x64 Python installation:

```powershell
python --version
python -c "import struct, tkinter; print(struct.calcsize('P') * 8); print(tkinter.TclVersion, tkinter.TkVersion)"
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-build.txt
```

The first two commands should show Python 3.14.7 and 64-bit. Virtual environment activation is unnecessary.

## Test and build

```powershell
.\.venv\Scripts\python.exe tests\test_launcher.py
.\.venv\Scripts\python.exe tools\build.py
```

Output: `dist/AC8 Mod Launcher.exe`. The build uses `--onefile --windowed`, includes the complete `src/bundled` directory under `bundled`, and uses PyInstaller's default optimization level 0. It does not download or install a game, UE4SS or mods, or change saves. `tools/build.py` is a short, inspectable wrapper around PyInstaller.

To inspect the output without running it:

```powershell
.\.venv\Scripts\python.exe tools\verify_release.py 'dist\AC8 Mod Launcher.exe'
Get-FileHash -Algorithm SHA256 'dist\AC8 Mod Launcher.exe'
```

To inspect the original Nexus executable instead, pass its location to `verify_release.py`. With the same Python minor version, this checks the embedded launcher code against `src/launcher.py` and compares every bundled Lua file byte-for-byte. It does not execute the target executable or the embedded code.

## Original build command and reproducibility

The original build used the same options, with absolute local paths for `--add-data` and the launcher source, a separate work directory and release output directory. Those personal path names are deliberately omitted. PyInstaller embeds build/runtime metadata and collects native libraries from the build environment; an identical output hash is not promised even with matching package versions. Compare the embedded source and dependencies, not only the rebuilt executable hash.

Original artifact hashes are recorded in `release-manifest.json`. They identify the submitted release; do not replace them with rebuild hashes.

## Running from source (optional)

```powershell
.\.venv\Scripts\python.exe src\launcher.py
```

This opens the launcher. Installing mods or changing graphics settings requires user actions in that UI. Tests use temporary directories and a mocked running-game check; they do not prove in-game compatibility or that antivirus detections are false positives.
