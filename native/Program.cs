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
    readonly CheckBox[] choices = new CheckBox[6];
    readonly ComboBox mission = new() { DropDownStyle=ComboBoxStyle.DropDownList, Width=340, MaxDropDownItems=12, IntegralHeight=false, DropDownHeight=280 };
    readonly ComboBox mrpMode = new() { DropDownStyle=ComboBoxStyle.DropDownList, Width=320, Enabled=false };
    readonly NumericUpDown mrpAmount = new() { Minimum=1, Maximum=999999999, Value=1000000, ThousandsSeparator=true, Width=180, Enabled=false, AccessibleName="Custom MRP target" };
    readonly CheckBox noEac = new() { Text="No EAC launch", AutoSize=true };
    readonly Label status = new() { AutoSize=true, MaximumSize=new Size(710,0), Text="Ready. Close the game before applying changes." };
    bool busy;
    public LauncherForm()
    {
        Text="AC8 | MOD CONTROL - 1.4.0"; ClientSize=new Size(740,880); MinimumSize=new Size(700,650);
        using var iconStream=typeof(LauncherForm).Assembly.GetManifestResourceStream("AC8.ModIcon.ico")!; Icon=new Icon(iconStream); FormClosed+=(_,_)=>Icon?.Dispose(); StartPosition=FormStartPosition.CenterScreen; BackColor=panel; ForeColor=green;
        Font=new Font("Segoe UI",10); AutoScaleMode=AutoScaleMode.Dpi;
        content.BackColor=panel; Controls.Add(content);
        using var bannerStream=typeof(LauncherForm).Assembly.GetManifestResourceStream("AC8.BrandBanner.png")!;
        using var bannerSource=Image.FromStream(bannerStream);
        var banner=new PictureBox { Image=new Bitmap(bannerSource),SizeMode=PictureBoxSizeMode.Zoom,Size=new Size(660,189),Margin=new Padding(0,0,0,8),AccessibleName="CriminalGamer84 Mods banner",TabStop=false };
        content.Controls.Add(banner);
        FormClosed+=(_,_)=>banner.Image?.Dispose();
        AddLabel("AC8 / MOD CONTROL",14,true);
        AddLabel("Offline / single-player",10);
        Section("GAME FOLDER");
        game.Width=490; game.BackColor=Color.FromArgb(7,14,11); game.ForeColor=green;
        game.Text=FindGame();
        Row(game,Button("Browse",()=> { using var dialog=new FolderBrowserDialog { Description="Select the ACE COMBAT 8 installation folder", UseDescriptionForTitle=true }; if (dialog.ShowDialog(this)==DialogResult.OK) game.Text=dialog.SelectedPath; }));
        Section("CHOOSE MODS");
        string[] labels=["FOV / HUD overlay (F9)","Mission access", "MRP credits", "Aircraft Tree access", "Unlock All Skills and Weapons", "Skins Access"];
        for(int i=0;i<choices.Length;i++) choices[i]=new CheckBox { Text=labels[i],Checked=false,AutoSize=true,Margin=new Padding(0,8,12,8) };
        content.Controls.Add(choices[0]);content.Controls.Add(choices[5]);
        mission.Width=310;mission.Items.AddRange(ModService.Missions);mission.SelectedIndex=0;mission.Enabled=false;
        Row(choices[1],mission);
        choices[1].CheckedChanged+=(_,_)=>mission.Enabled=choices[1].Checked;
        mrpMode.Width=220;mrpAmount.Width=150;
        mrpMode.Items.AddRange(new object[]{"Custom amount", "Unlimited (999,999,999)"});mrpMode.SelectedIndex=0;
        Row(choices[2],mrpMode,mrpAmount);
        choices[2].CheckedChanged+=(_,_)=> { mrpMode.Enabled=choices[2].Checked; mrpAmount.Enabled=choices[2].Checked && mrpMode.SelectedIndex==0; };
        mrpMode.SelectedIndexChanged+=(_,_)=>mrpAmount.Enabled=choices[2].Checked && mrpMode.SelectedIndex==0;
        Row(choices[3],choices[4]);
        AddLabel("MRP sets a minimum balance. Purchases still spend credits.",9);
        Section("PLAY");content.Controls.Add(noEac);
        Row(Button("Apply Selected Mods",Apply),Button("Launch Game",Launch),Button("Help",ShowHelp));
        AddLabel("Use Apply Selected Mods and No EAC Launch when first applying your changes. Once the game saves, you can launch normally from your usual shortcut - no mod launcher needed.",9);
        AddLabel("Applying mods backs up your save automatically.",9);
        var advanced=new FlowLayoutPanel { AutoSize=true,AutoSizeMode=AutoSizeMode.GrowAndShrink,FlowDirection=FlowDirection.TopDown,WrapContents=false,Visible=false,Margin=new Padding(0) };
        advanced.Controls.Add(Button("Back Up Save",()=>RunWork(()=>"Backup verified: "+service.Backup())));
        advanced.Controls.Add(Button("Open Backups",()=> { Directory.CreateDirectory(service.Backups);Process.Start(new ProcessStartInfo(service.Backups){UseShellExecute=true}); }));
        advanced.Controls.Add(Button("Enable DLSS settings",()=>RunWork(()=>service.Dlss(true))));
        advanced.Controls.Add(Button("Restore DLSS settings",()=>RunWork(()=>service.Dlss(false))));
        var more=Button("More options",()=>advanced.Visible=!advanced.Visible);
        content.Controls.Add(more);content.Controls.Add(advanced);
        status.ForeColor=Color.FromArgb(213,232,207);status.Margin=new Padding(0,10,0,12);content.Controls.Add(status);
        content.SizeChanged+=(_,_)=> { int width=Math.Max(500,content.ClientSize.Width-60);banner.Size=new Size(width,(int)Math.Round(width*372.0/1300));foreach(Control c in content.Controls) { if(c is Label label)label.MaximumSize=new Size(width,0);if(c is FlowLayoutPanel row)row.MaximumSize=new Size(width,0); }game.Width=Math.Max(340,width-120); };
        FormClosing+=(_,e)=> { if(busy) { e.Cancel=true; MessageBox.Show(this,"Please wait for the current operation to finish before closing.","AC8 Mod Control"); } };
    }
    void ShowHelp()
    {
        using var help=new Form { Text="AC8 Mod Control - Help",ClientSize=new Size(660,560),StartPosition=FormStartPosition.CenterParent,BackColor=panel,ForeColor=green,Font=Font };
        var text=new TextBox { Multiline=true,ReadOnly=true,ScrollBars=ScrollBars.Vertical,Dock=DockStyle.Fill,BackColor=panel,ForeColor=Color.FromArgb(213,232,207),BorderStyle=BorderStyle.None,Text="""
QUICK START
1. Install the latest experimental UE4SS build in the game first (the stable release is not supported).
2. For a fresh game, start a campaign once and let it save, then close the game.
3. Select your game folder, choose your mods, and click Apply Selected Mods.
4. Check No EAC launch and click Launch Game for this first application.
5. Load your campaign and let the game save normally.

After the first application, launch normally from your usual shortcut. You do not need to open the mod launcher or select No EAC for every game launch. Return here only to apply new changes.

MOD OPTIONS
Skins Access: base-game skins for regular aircraft you own.
Mission access: all missions, or through the selected mission.
MRP credits: sets a minimum balance. Purchases spend credits normally.
Aircraft Tree access: opens the full regular tree for purchases and enables Aircraft Set and Parts for fresh campaigns.
Unlock All Skills and Weapons: grants tree parts and special weapons for owned aircraft. Equip parts through Aircraft Set.
FOV / HUD overlay: press F9 during flight.
Adjust score, radar, weapons and radio portrait positions with the arrows.
Use the sliders to resize each panel. The radar indicator and quick commands follow the radar.
Separate counterclockwise arrows reset position or size.
Drag the title bar to move the overlay. Ultrawide Preset moves the corner panels outward.
Positions and sizes save automatically. The center flight HUD stays unchanged.

Applying mods automatically backs up your save. Offline / single-player.

""".Replace("\n",Environment.NewLine) };
        help.Padding=new Padding(20);help.Controls.Add(text);help.ShowDialog(this);
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
        busy=true; content.Enabled=false; UseWaitCursor=true; status.Text="Working...";
        try { status.Text=await Task.Run(operation); }
        catch(Exception ex) { ShowError(ex); }
        finally { busy=false; content.Enabled=true; UseWaitCursor=false; }
    }
    void ShowError(Exception ex) { status.Text=ex.Message; MessageBox.Show(this,ex.Message,"AC8 Mod Control",MessageBoxButtons.OK,MessageBoxIcon.Warning); }
    void Apply()
    {
        string folder=game.Text; bool[] selected=choices.Select(c=>c.Checked).ToArray(); string mode=mission.SelectedItem!.ToString()!;
        uint target=mrpMode.SelectedIndex==1?999999999u:(uint)mrpAmount.Value;

        RunWork(()=>"Installed. Save backup verified: "+service.Install(folder,selected,mode,target)+"\nLaunch and load your campaign to apply.");
    }
    void Launch()
    {
        Process.Start(service.LaunchInfo(game.Text,noEac.Checked));
        status.Text=noEac.Checked?"Direct single-player launch requested without the EAC launcher.":"Launch requested through Steam.";
    }
}


