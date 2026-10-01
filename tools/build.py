"""Build only; does not launch the result or change game files."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
if sys.platform != "win32":
    raise SystemExit("Build this Windows release on Windows x64.")
subprocess.run([
    sys.executable, "-m", "PyInstaller", "--noconfirm", "--clean",
    "--onefile", "--windowed", "--name", "AC8 Mod Launcher",
    "--add-data", str(ROOT / "src" / "bundled") + ";bundled",
    "--distpath", str(ROOT / "dist"), "--workpath", str(ROOT / "build"),
    "--specpath", str(ROOT / "build"), str(ROOT / "src" / "launcher.py")
], check=True, cwd=ROOT)
