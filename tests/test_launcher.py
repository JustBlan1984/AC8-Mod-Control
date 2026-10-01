import importlib.util,tempfile,zipfile
from pathlib import Path
spec=importlib.util.spec_from_file_location('launcher',Path(__file__).resolve().parents[1]/'src/launcher.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
with tempfile.TemporaryDirectory() as d:
 p=Path(d);m.HOME=p/'app';m.BACKUPS=m.HOME/'Backups';m.SAVE=p/'SaveGames';m.SAVE.mkdir();(m.SAVE/'Campaign.sav').write_bytes(b'test-existing-save');m.running=lambda:False
 g=p/'game';b=g/'Game/Binaries/Win64';(b/'ue4ss/Mods').mkdir(parents=True);(b/'AceCombat8.exe').touch();(b/'ue4ss/UE4SS-settings.ini').touch()
 saved=m.install(g,[True,True,True],'All missions')
 with zipfile.ZipFile(saved) as z:assert z.read('Campaign.sav')==b'test-existing-save'
 assert (m.SAVE/'Campaign.sav').read_bytes()==b'test-existing-save'
 assert 'AutoApply=true' in (b/'ue4ss/Mods/AC8MissionUnlock/Scripts/Mission-config.lua').read_text()
 m.install(g,[False,False,False],'All missions')
 cfg=(b/'ue4ss/Mods/mods.txt').read_text();assert all(name+' : 0' in cfg for name in m.MODS)
 ini=m.SAVE.parent/'Config/Windows/Engine.ini';ini.parent.mkdir(parents=True);original=b'[Other]\r\nKeep=42\r\n[ConsoleVariables]\r\nr.Streamline.DLSSG.Enable=0\r\n';ini.write_bytes(original)
 m.dlss_toggle(True);assert 'Keep=42' in ini.read_text();assert 'r.Streamline.DLSSG.Enable = 1' in ini.read_text()
 m.dlss_toggle(False);assert ini.read_bytes()==original
 ini.unlink();m.dlss_toggle(True);m.dlss_toggle(False);assert not ini.exists()
 m.running=lambda:True
 try:m.backup();raise AssertionError('Running game not blocked')
 except RuntimeError:pass
print('Passed: backup contents, save preservation, install, disable, DLSS merge and exact restore, absent INI restore, running-game guard.')
