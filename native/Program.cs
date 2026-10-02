using System.Diagnostics;
namespace AC8ModControl;

internal static class Program
{
    [STAThread]
    static void Main(string[] args)
    {
        ApplicationConfiguration.Initialize();
        using var form = new LauncherForm();
        Application.Run(form);
    }
}

public sealed class LauncherForm : Form
{
    readonly ModService service = ModService.Current();
    readonly Color green = Color.FromArgb(136,216,107);
    readonly Color panel = Color.FromArgb(11,23,16);
    readonly FlowLayoutPanel content = new() { Dock=DockStyle.Fill, FlowDirection=FlowDirection.TopDown, WrapContents=false, AutoScroll=true, Padding=new Padding(24) };
    readonly TextBox game = new();
    readonly CheckBox[] choices = new CheckBox[3];
    readonly ComboBox mission = new() { DropDownStyle=ComboBoxStyle.DropDownList, Width=340, MaxDropDownItems=12, IntegralHeight=false, DropDownHeight=280 };
    readonly CheckBox noEac = new() { Text="No EAC launch — offline / single-player mods", AutoSize=true };
    readonly Label status = new() { AutoSize=true, MaximumSize=new Size(710,0), Text="Ready. Close the game before applying changes." };
    bool busy;
    public LauncherForm()
    {
        Text="AC8 | MOD CONTROL — 1.1.1"; ClientSize=new Size(840,920); MinimumSize=new Size(700,650);
        StartPosition=FormStartPosition.CenterScreen; BackColor=panel; ForeColor=green;
        Font=new Font("Segoe UI",10); AutoScaleMode=AutoScaleMode.Dpi;
        content.BackColor=panel; Controls.Add(content);
        AddLabel("AC8 / MOD CONTROL",24,true);
        AddLabel("CRIMINALGAMER84 MODS   /   1.1.1   /   WINDOWS",10,true);
        AddLabel("Configure once. Load your campaign, then let the game save normally.");
        var warning=AddLabel("USE AT YOUR OWN RISK\nFor offline / single-player use. Online use is not recommended and may result in account restrictions or bans."); warning.ForeColor=Color.FromArgb(227,187,112);
        Section("INSTALLATION");
        AddLabel("ACE COMBAT 8 installation folder");
        game.Width=570; game.BackColor=Color.FromArgb(7,14,11); game.ForeColor=green;
        game.Text=FindGame();
        Row(game,Button("Browse",()=> { using var dialog=new FolderBrowserDialog { Description="Select the ACE COMBAT 8 installation folder", UseDescriptionForTitle=true }; if (dialog.ShowDialog(this)==DialogResult.OK) game.Text=dialog.SelectedPath; }));
        Section("MOD SELECTION");
        string[] labels=["FOV overlay — F10 in flight","Aircraft, skins and SP weapons — automatic repair","Mission access"];
        for(int i=0;i<3;i++) { choices[i]=new CheckBox { Text=labels[i],Checked=true,AutoSize=true,Margin=new Padding(0,7,0,7) }; content.Controls.Add(choices[i]); }
        mission.Items.AddRange(ModService.Missions); mission.SelectedIndex=0; content.Controls.Add(mission);
        choices[2].CheckedChanged+=(_,_)=>mission.Enabled=choices[2].Checked;
        AddLabel("Also enables campaign features including Free Mission, Free Flight and Data Viewer. Existing later unlocks remain. Cutoffs after Mission 6 still need in-game verification.");
        Section("LAUNCH MODE"); content.Controls.Add(noEac);
        AddLabel("Unchecked: Steam launch using your existing settings. This option does not remove EAC or change Steam settings.");
        Section("DLSS / GRAPHICS");
        Row(Button("Enable DLSS",()=>RunWork(()=>service.Dlss(true))),Button("Disable DLSS tweak",()=>RunWork(()=>service.Dlss(false))));
        AddLabel("For use without a DLSS swapper. Applies Streamline / Frame Generation / Reflex INI settings. Does not install DLSS; verify availability in game.");
        Section("SAVE BACKUP / APPLY");
        Row(Button("Back Up Current Save",()=>RunWork(()=>"Backup verified: "+service.Backup())),Button("Open Backups",()=> { Directory.CreateDirectory(service.Backups); Process.Start(new ProcessStartInfo(service.Backups){UseShellExecute=true}); }));
        Row(Button("Apply Selected Mods",Apply),Button("Launch Game",Launch));
        AddLabel("Requires a working UE4SS installation and a campaign save. Unchecking a mod disables its script; it does not reverse saved unlocks. Open the hangar normally after applying.");
        status.ForeColor=Color.FromArgb(213,232,207); status.Margin=new Padding(0,16,0,20); content.Controls.Add(status);
        content.SizeChanged+=(_,_)=> { int width=Math.Max(500,content.ClientSize.Width-70); foreach(Control c in content.Controls) if(c is Label label) label.MaximumSize=new Size(width,0); game.Width=Math.Max(340,width-115); };
        FormClosing+=(_,e)=> { if(busy) { e.Cancel=true; MessageBox.Show(this,"Please wait for the current operation to finish before closing.","AC8 Mod Control"); } };
    }
    static string FindGame()
    {
        foreach(var drive in DriveInfo.GetDrives())
        {
            if(!drive.IsReady || drive.DriveType!=DriveType.Fixed) continue;
            foreach(var relative in new[]{"SteamLibrary/steamapps/common/ACE COMBAT 8","Program Files (x86)/Steam/steamapps/common/ACE COMBAT 8"})
            {
                var path=Path.Combine(drive.RootDirectory.FullName,relative);
                if(File.Exists(Path.Combine(path,"Game/Binaries/Win64/AceCombat8.exe"))) return path;
            }
        }
        return "";
    }
    Label AddLabel(string text,int size=10,bool bold=false)
    {
        var label=new Label { Text=text,AutoSize=true,MaximumSize=new Size(730,0),Font=new Font("Segoe UI",size,bold?FontStyle.Bold:FontStyle.Regular),Margin=new Padding(0,5,0,9),ForeColor=bold?green:Color.FromArgb(173,196,174) };
        content.Controls.Add(label); return label;
    }
    void Section(string title) { var label=AddLabel("[ "+title+" ]",11,true); label.Margin=new Padding(0,19,0,10); }
    Button Button(string text,Action action)
    {
        var button=new Button { Text=text,AutoSize=true,AutoSizeMode=AutoSizeMode.GrowAndShrink,Padding=new Padding(12,8,12,8),FlatStyle=FlatStyle.Flat,BackColor=Color.FromArgb(17,37,26),ForeColor=green,Margin=new Padding(0,3,10,5) };
        button.FlatAppearance.BorderColor=Color.FromArgb(49,84,58);
        button.Click+=(_,_)=> { try { action(); } catch(Exception ex) { ShowError(ex); } }; return button;
    }
    void Row(params Control[] controls)
    {
        var row=new FlowLayoutPanel { AutoSize=true,AutoSizeMode=AutoSizeMode.GrowAndShrink,WrapContents=true,MaximumSize=new Size(740,0),Margin=new Padding(0) }; row.Controls.AddRange(controls); content.Controls.Add(row);
    }
    async void RunWork(Func<string> operation)
    {
        busy=true; content.Enabled=false; UseWaitCursor=true; status.Text="Working…";
        try { status.Text=await Task.Run(operation); }
        catch(Exception ex) { ShowError(ex); }
        finally { busy=false; content.Enabled=true; UseWaitCursor=false; }
    }
    void ShowError(Exception ex) { status.Text=ex.Message; MessageBox.Show(this,ex.Message,"AC8 Mod Control",MessageBoxButtons.OK,MessageBoxIcon.Warning); }
    void Apply()
    {
        string folder=game.Text; bool[] selected=choices.Select(c=>c.Checked).ToArray(); string mode=mission.SelectedItem!.ToString()!;
        RunWork(()=>"Installed. Save backup verified: "+service.Install(folder,selected,mode)+"\nLaunch and load your campaign to apply.");
    }
    void Launch()
    {
        Process.Start(service.LaunchInfo(game.Text,noEac.Checked));
        status.Text=noEac.Checked?"Direct single-player launch requested without the EAC launcher.":"Launch requested through Steam.";
    }
}

