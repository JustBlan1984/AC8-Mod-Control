"""Read a PyInstaller EXE without executing it; compare authored source only."""
from pathlib import Path
import hashlib, json, marshal, sys, types
from PyInstaller.archive.readers import CArchiveReader
ROOT = Path(__file__).resolve().parents[1]
def same(a, b):
    if isinstance(a, types.CodeType) and isinstance(b, types.CodeType):
        fields = ('co_code','co_names','co_varnames','co_freevars','co_cellvars',
                  'co_argcount','co_kwonlyargcount','co_posonlyargcount','co_flags','co_exceptiontable')
        return all(getattr(a,k)==getattr(b,k) for k in fields) and len(a.co_consts)==len(b.co_consts) and all(same(x,y) for x,y in zip(a.co_consts,b.co_consts))
    return type(a) is type(b) and a == b
if len(sys.argv) != 2:
    raise SystemExit('Usage: python tools/verify_release.py path/to/launcher.exe')
p = Path(sys.argv[1]).resolve()
a = CArchiveReader(str(p))
source = ROOT/'src'
manifest = json.loads((ROOT/'release-manifest.json').read_text())
for name, expected in manifest['source_sha256'].items():
    assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest() == expected, 'Source manifest mismatch: '+name
assert same(marshal.loads(a.extract('launcher')), compile((source/'launcher.py').read_bytes(), '<source>', 'exec')), 'Embedded launcher differs or incompatible Python version'
embedded = {n.replace('\\','/'):n for n in a.toc if n.replace('\\','/').startswith('bundled/')}
expected = {p.relative_to(source).as_posix() for p in (source/'bundled').rglob('*') if p.is_file()}
assert set(embedded) == expected, 'Bundled file inventory differs'
for name, archive_name in embedded.items():
    assert a.extract(archive_name) == (source/name).read_bytes(), 'Bundled file differs: '+name
print('PASS: source manifest, embedded launcher code and all',len(expected),'bundled files match.')
print('EXE SHA256:',hashlib.sha256(p.read_bytes()).hexdigest())
print('This checks authored source only; it is not a malware clearance or full dependency audit.')
