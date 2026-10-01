# Build validation — 2026-10-01

A fresh Python virtual environment was created on Windows 11 x64 with CPython 3.14.7. All seven pinned packages in requirements-build.txt installed successfully. The commands in BUILD.md were run using that environment.

Results:

- Isolated filesystem tests: PASS (backup contents, save preservation, mod install/disable, DLSS merge and exact restore, absent-INI restore, running-game guard).
- PyInstaller one-file GUI build: PASS.
- Authored source manifest verification: PASS.
- Original Nexus EXE embedded launcher and all 15 Lua files against repository source: PASS.
- Rebuilt EXE embedded launcher and all 15 Lua files against repository source: PASS.

Original EXE SHA-256: `65cc6c8b43790a9c334b4fc11cc732d1058747b6aa3f965353fdaf99ecd79e16`

Verification rebuild SHA-256: `69c623f5e01cb3fe2c1fc9f2ea0b1dc5862db2f3ac46aa85b1e310dc76f3029c`

The rebuild was not uploaded as a replacement release or used to change game/save files. The differing executable hash is expected to be possible because build paths and bundled metadata differ. No claim of bit-for-bit reproducibility or antivirus clearance is made. No new in-game testing was performed for this documentation-only review package.
