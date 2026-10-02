using AC8ModControl;
var root=Path.Combine(Path.GetTempPath(),"AC8ProgressionTests-"+Guid.NewGuid().ToString("N"));
var game=Path.Combine(root,"game");var loader=Path.Combine(game,"Game","Binaries","Win64","ue4ss");
Directory.CreateDirectory(loader);File.WriteAllText(Path.Combine(loader,"UE4SS.dll"),"fixture");File.WriteAllText(Path.Combine(loader,"..","AceCombat8.exe"),"fixture");
var saves=Path.Combine(root,"saves");Directory.CreateDirectory(saves);File.WriteAllText(Path.Combine(saves,"Campaign.sav"),"fixture campaign");
var bundle=Path.GetFullPath(args[0]);var service=new ModService(Path.Combine(root,"home"),saves,bundle,()=>false);
void Assert(bool value,string text){if(!value)throw new Exception(text);}
service.Install(game,[false,false,false,true,false],ModService.Missions[0]);
var mods=Path.Combine(loader,"Mods");var config=File.ReadAllText(Path.Combine(mods,"mods.txt"));
Assert(config.Contains("AC8CampaignCredits : 1")&&config.Contains("AC8MissionUnlock : 0")&&config.Contains("AC8CampaignTree : 0"),"Credit selection isolation");
Assert(File.Exists(Path.Combine(mods,"AC8CampaignCredits","Scripts","request.txt")),"Credit request");
service.Install(game,[false,false,false,false,true],ModService.Missions[0]);config=File.ReadAllText(Path.Combine(mods,"mods.txt"));
Assert(config.Contains("AC8CampaignCredits : 0")&&config.Contains("AC8MissionUnlock : 0")&&config.Contains("AC8CampaignTree : 1"),"Tree selection isolation");
Assert(File.Exists(Path.Combine(mods,"AC8CampaignTree","Scripts","Tree.lua")),"Tree adapter");
Assert(File.ReadAllText(Path.Combine(saves,"Campaign.sav"))=="fixture campaign","Installer changed save");
Assert(Directory.GetFiles(service.Backups,"*.zip").Length==2,"Save backups");
Console.WriteLine("PASS: separate selections, bundled requests, unchanged save and automatic backups. Fixtures: "+root);

service.Install(game,[false,false,false,true,false],ModService.Missions[0],1234567);
Assert(File.ReadAllText(Path.Combine(mods,"AC8CampaignCredits","Scripts","Credits-config.lua"))=="return {Target=1234567}\n","Custom target not serialized");
service.Install(game,[false,false,false,true,false],ModService.Missions[0],999999999);
Assert(File.ReadAllText(Path.Combine(mods,"AC8CampaignCredits","Scripts","Credits-config.lua")).Contains("999999999"),"Unlimited preset");
var before=File.ReadAllText(Path.Combine(mods,"mods.txt"));
foreach(var invalid in new uint[]{0,1000000000}) {
 bool rejected=false;try{service.Install(game,[false,false,false,true,false],ModService.Missions[0],invalid);}catch(ArgumentOutOfRangeException){rejected=true;}
 Assert(rejected,"Invalid target accepted");
 Assert(File.ReadAllText(Path.Combine(mods,"mods.txt"))==before,"Invalid target mutated install");
}
Console.WriteLine("PASS: custom/preset config and invalid target rejection before mutation");
