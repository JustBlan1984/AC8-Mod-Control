using AC8ModControl;
using System.IO.Compression;
using System.Text;
using System.Text.Json;

string root=Path.Combine(Path.GetTempPath(),"AC8-native-tests-"+Guid.NewGuid());
Directory.CreateDirectory(root);
int checks=0;
void Check(bool value,string name) { if(!value) throw new Exception(name); checks++; Console.WriteLine("PASS: "+name); }
void Fails(Action action,string name) { bool failed=false; try {action();} catch {failed=true;} Check(failed,name); }
try
{
 var saves=Path.Combine(root,"Saved/SaveGames"); Directory.CreateDirectory(saves);
 var save=Path.Combine(saves,"Campaign.sav"); File.WriteAllText(save,"existing-save-content");
 Directory.CreateDirectory(Path.Combine(saves,"nested")); File.WriteAllText(Path.Combine(saves,"nested/profile.sav"),"nested-profile");
 var bundle=Path.GetFullPath(args[0]); bool running=false;
 var s=new ModService(Path.Combine(root,"app"),saves,bundle,()=>running);
 var game=Path.Combine(root,"game"); var mods=Path.Combine(game,"Game/Binaries/Win64/ue4ss/Mods"); Directory.CreateDirectory(mods);
 File.WriteAllText(Path.Combine(game,"Game/Binaries/Win64/AceCombat8.exe"),"");
 File.WriteAllText(Path.Combine(game,"Game/Binaries/Win64/ue4ss/UE4SS-settings.ini"),"");
 File.WriteAllText(Path.Combine(mods,"mods.txt"),"OtherMod : 1\nAC8AircraftUnlock : 0\n");
 Directory.CreateDirectory(Path.Combine(mods,"AC8AircraftUnlock")); File.WriteAllText(Path.Combine(mods,"AC8AircraftUnlock/enabled.txt"),"");
 string archive=s.Install(game,[true,true,true],"Mission 6");
 using(var zip=ZipFile.OpenRead(archive)) { using var reader=new StreamReader(zip.GetEntry("Campaign.sav")!.Open()); Check(reader.ReadToEnd()=="existing-save-content","backup contains exact current campaign"); Check(zip.Entries.Count==2,"nested saves included"); }
 Check(File.ReadAllText(save)=="existing-save-content","installation leaves save unchanged");
 Check(File.ReadAllText(Path.Combine(mods,"mods.txt")).Contains("OtherMod : 1"),"other mods preserved");
 Check(!File.Exists(Path.Combine(mods,"AC8AircraftUnlock/enabled.txt")),"enabled marker moved");
 Check(File.ReadAllText(Path.Combine(mods,"AC8MissionUnlock/Scripts/Mission-config.lua")).Contains("ThroughID=7"),"mission 6 maps to internal 7");
 Check(ModService.MissionConfig("Prologue").Contains("ThroughID=1"),"prologue cutoff");
 Check(ModService.MissionConfig("Mission 30").Contains("ThroughID=31"),"mission 30 cutoff");
 Check(ModService.MissionConfig("Unlock ALL Missions").Contains("Mode=\"all\""),"all catalog mode");
 Fails(()=>s.Install(game,[true,true,true],"invalid"),"invalid mission rejected");
 s.Install(game,[false,false,false],"invalid");
 Check(ModService.Mods.All(n=>File.ReadAllText(Path.Combine(mods,"mods.txt")).Contains(n+" : 0")),"all scripts disabled");
 foreach(var encoding in new Encoding[]{new UTF8Encoding(false),new UTF8Encoding(true),new UnicodeEncoding(false,true),new UnicodeEncoding(true,true)})
 {
   Directory.CreateDirectory(Path.GetDirectoryName(s.Ini)!);
   byte[] original=[..encoding.GetPreamble(),..encoding.GetBytes("[Other]\r\nKeep=42\r\n[ConsoleVariables]\r\nr.Streamline.DLSSG.Enable=0\r\n")];
   File.WriteAllBytes(s.Ini,original); s.Dlss(true);
   Check(File.ReadAllText(s.Ini).Contains("Keep=42")&&File.ReadAllText(s.Ini).Contains("r.Streamline.DLSSG.Enable = 1"),"DLSS merge "+encoding.WebName);
   s.Dlss(false); Check(File.ReadAllBytes(s.Ini).SequenceEqual(original),"exact byte restore "+encoding.WebName);
 }
 File.Delete(s.Ini); s.Dlss(true); s.Dlss(false); Check(!File.Exists(s.Ini),"absent INI restored");
 s.Dlss(true); File.AppendAllText(s.Ini,"\nLaterChange=1"); Fails(()=>s.Dlss(false),"newer INI edits protected");
 Check(File.ReadAllText(s.Ini).Contains("LaterChange=1"),"newer INI preserved");
 // Simulate a restore record from the original Python launcher.
 string prior=Path.Combine(s.Backups,"legacy.ini"); File.WriteAllText(prior,"legacy-settings");
 File.WriteAllText(Path.Combine(s.Home,"dlss-state.json"),JsonSerializer.Serialize(new {path=s.Ini,existed=true,backup=prior,after=ModService.Hash(s.Ini)}));
 s.Dlss(false); Check(File.ReadAllText(s.Ini)=="legacy-settings","Python launcher restore record supported");
 var launch=s.LaunchInfo(game,true); Check(launch.ArgumentList.SequenceEqual(new[]{"-SaveToUserDir"})&&launch.Environment["SteamAppId"]=="2288340"&&!launch.UseShellExecute,"direct launch command and environment");
 Check(s.LaunchInfo(game,false).FileName=="steam://rungameid/2288340","Steam launch route");
 running=true; Fails(()=>s.Backup(),"running game blocks backup"); Fails(()=>s.Dlss(true),"running game blocks graphics changes"); Fails(()=>s.Install(game,[true,true,true],"Unlock ALL Missions"),"running game blocks install"); Fails(()=>s.LaunchInfo(game,true),"duplicate launch blocked"); running=false;
 File.Delete(save); Fails(()=>s.Install(game,[true,true,true],"Unlock ALL Missions"),"missing campaign blocks install");
 Console.WriteLine($"All {checks} checks passed. No real game or save paths touched.");
}
finally { Directory.Delete(root,true); }
