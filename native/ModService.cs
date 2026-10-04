using System.Diagnostics;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace AC8ModControl;

public sealed class ModService
{
    public static readonly string[] Mods = ["AC8AdjustableFOV", "AC8MissionUnlock", "AC8CampaignCredits", "AC8CampaignTree", "AC8CampaignSkills", "AC8SkinsAccess"];
    public static readonly string[] Missions = ["Unlock ALL Missions", "Prologue", .. Enumerable.Range(1, 30).Select(n => $"Mission {n}")];
    public string Home { get; }
    public string Saves { get; }
    public string Bundle { get; }
    public string Backups => Path.Combine(Home, "Backups");
    public string Ini => Path.Combine(Directory.GetParent(Saves)!.FullName, "Config", "Windows", "Engine.ini");
    readonly Func<bool> isRunning;
    static readonly UTF8Encoding Utf8 = new(false, true);
    static string Stamp() => DateTime.Now.ToString("yyyyMMdd-HHmmss-fffffff") + "-" + Guid.NewGuid().ToString("N")[..6];
    public ModService(string home, string saves, string bundle, Func<bool>? running = null)
    {
        Home = Path.GetFullPath(home); Saves = Path.GetFullPath(saves); Bundle = Path.GetFullPath(bundle);
        isRunning = running ?? GameRunning;
    }
    public static ModService Current() => new(
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "AC8 Mod Launcher"),
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "BANDAI NAMCO Entertainment", "ACE COMBAT 8", "Saved", "SaveGames"),
        Path.Combine(AppContext.BaseDirectory, "bundled"));
    public static bool GameRunning()
    {
        var processes = Process.GetProcessesByName("AceCombat8");
        try { return processes.Length != 0; }
        finally { foreach (var p in processes) p.Dispose(); }
    }
    public void EnsureClosed()
    {
        if (isRunning()) throw new InvalidOperationException("Close ACE COMBAT 8 before changing mods, graphics settings, or backing up your save.");
    }
    public static string MissionConfig(string mode)
    {
        if (mode == Missions[0]) return "return {Mode=\"all\",CampaignAccess=true,FreeMissionAccess=true,AutoApply=true}\n";
        int last = mode == "Prologue" ? 1 : Array.IndexOf(Missions, mode);
        if (last < 1) throw new ArgumentException("Choose a mission from the list.");
        return $"return {{Mode=\"internal_through\",ThroughID={last},EnforceLimit=true,CampaignAccess=true,FreeMissionAccess=true,AutoApply=true}}\n";
    }
    static void RejectLink(string path)
    {
        for (var p = Path.GetFullPath(path); p != null; p = Directory.GetParent(p)?.FullName)
            if ((File.Exists(p) || Directory.Exists(p)) && (File.GetAttributes(p) & FileAttributes.ReparsePoint) != 0)
                throw new IOException("Linked folders or files are not supported for this operation: " + p);
    }
    static IEnumerable<string> Files(string directory)
    {
        RejectLink(directory);
        foreach (var f in Directory.EnumerateFiles(directory)) { RejectLink(f); yield return f; }
        foreach (var d in Directory.EnumerateDirectories(directory))
            foreach (var f in Files(d)) yield return f;
    }
    public static string Hash(string file) { using var stream = File.OpenRead(file); return Convert.ToHexString(SHA256.HashData(stream)).ToLowerInvariant(); }
    static void AtomicWrite(string file, byte[] bytes)
    {
        RejectLink(file); Directory.CreateDirectory(Path.GetDirectoryName(file)!);
        string temporary = file + ".ac8-" + Guid.NewGuid().ToString("N") + ".tmp";
        try { File.WriteAllBytes(temporary, bytes); File.Move(temporary, file, true); }
        finally { if (File.Exists(temporary)) File.Delete(temporary); }
    }
    public string Backup()
    {
        EnsureClosed();
        if (!File.Exists(Path.Combine(Saves, "Campaign.sav"))) throw new IOException("Current Campaign.sav was not found. Start a campaign once and allow it to save, then close the game.");
        var files = Files(Saves).ToArray();
        RejectLink(Backups); Directory.CreateDirectory(Backups);
        var path = Path.Combine(Backups, "Save-" + Stamp() + ".zip");
        using (var zip = ZipFile.Open(path, ZipArchiveMode.Create))
            foreach (var file in files) zip.CreateEntryFromFile(file, Path.GetRelativePath(Saves, file), CompressionLevel.Optimal);
        using (var zip = ZipFile.OpenRead(path))
        {
            if (zip.Entries.Count != files.Length) throw new IOException("Backup verification failed: file count mismatch.");
            foreach (var file in files)
            {
                var entry = zip.GetEntry(Path.GetRelativePath(Saves, file)) ?? throw new IOException("Backup file missing.");
                using var stream = entry.Open();
                if (Convert.ToHexString(SHA256.HashData(stream)).ToLowerInvariant() != Hash(file))
                    throw new IOException("Save changed during backup or verification failed. No mods were installed.");
            }
        }
        return path;
    }
    static void CopyTree(string source, string target)
    {
        foreach (var file in Files(source))
        {
            var dest = Path.Combine(target, Path.GetRelativePath(source, file)); RejectLink(dest);
            Directory.CreateDirectory(Path.GetDirectoryName(dest)!); File.Copy(file, dest, true);
        }
    }
    public string Install(string game, bool[] choices, string mode, uint mrpTarget = 999999999)
    {
        EnsureClosed();
        if (choices.Length != Mods.Length) throw new ArgumentException("Invalid mod selection.");
        if (choices[2] && (mrpTarget < 1 || mrpTarget > 999999999)) throw new ArgumentOutOfRangeException(nameof(mrpTarget), "MRP must be between 1 and 999,999,999.");
        var mission = choices[1] ? MissionConfig(mode) : "";
        var binary = Path.Combine(Path.GetFullPath(game), "Game", "Binaries", "Win64");
        RejectLink(binary);
        if (!File.Exists(Path.Combine(binary, "AceCombat8.exe"))) throw new IOException("Select the ACE COMBAT 8 installation folder.");
        var loader = Path.Combine(binary, "ue4ss");
        if (!File.Exists(Path.Combine(loader, "UE4SS.dll")) && !File.Exists(Path.Combine(loader, "UE4SS-settings.ini")))
            throw new IOException("A working UE4SS installation is required. The launcher does not install UE4SS.");
        var target = Path.Combine(loader, "Mods"); RejectLink(target);
        for (int i = 0; i < Mods.Length; i++)
        {
            if (choices[i] && !File.Exists(Path.Combine(Bundle, Mods[i], "Scripts", "main.lua"))) throw new IOException("Bundled mod files are missing. Extract the entire download before running the launcher.");
            if (choices[i]) _ = Files(Path.Combine(Bundle, Mods[i])).ToArray();
            var dest = Path.Combine(target, Mods[i]); RejectLink(dest);
            if (Directory.Exists(dest)) _ = Files(dest).ToArray();
        }
        var config = Path.Combine(target, "mods.txt"); RejectLink(config);
        string text = File.Exists(config) ? File.ReadAllText(config, Utf8) : "";
        var saved = Backup();
        var stamp = Path.Combine(Home, "Install-backup-" + Stamp()); Directory.CreateDirectory(stamp);
        bool hadConfig = File.Exists(config);
        bool[] existed = Mods.Select(n => Directory.Exists(Path.Combine(target, n))).ToArray();
        if (hadConfig) File.Copy(config, Path.Combine(stamp, "mods.txt"));
        for (int i = 0; i < Mods.Length; i++) if (existed[i]) CopyTree(Path.Combine(target, Mods[i]), Path.Combine(stamp, Mods[i]));
        try
        {
            for (int i = 0; i < Mods.Length; i++)
            {
                var dest = Path.Combine(target, Mods[i]);
                if (choices[i]) CopyTree(Path.Combine(Bundle, Mods[i]), dest);
                var marker = Path.Combine(dest, "enabled.txt");
                if (File.Exists(marker)) File.Move(marker, Path.Combine(dest, "enabled.saved-" + Stamp()));
                text = Regex.Replace(text, @"^\s*" + Regex.Escape(Mods[i]) + @"\s*:[^\r\n]*\r?\n?", "", RegexOptions.Multiline);
                text += "\n" + Mods[i] + " : " + (choices[i] ? "1" : "0") + "\n";
            }
            text = Regex.Replace(text, @"^\s*AC8AircraftUnlock\s*:[^\r\n]*\r?\n?", "", RegexOptions.Multiline);
            text += "\nAC8AircraftUnlock : 0\n";
            foreach(var retired in new[]{"AC8ExtraAircraft", "AC8ExtraAircraftPurchaseTest", "AC8ProgressionDiagnostic", "AC8CompatibilityDiagnostic", "AC8ExtraAircraftInspector"}) {
                text = Regex.Replace(text, @"^\s*" + Regex.Escape(retired) + @"\s*:[^\r\n]*\r?\n?", "", RegexOptions.Multiline);
                text += "\n" + retired + " : 0\n";
            }
            if (choices[1]) AtomicWrite(Path.Combine(target, Mods[1], "Scripts", "Mission-config.lua"), Utf8.GetBytes(mission));
            if (choices[2]) AtomicWrite(Path.Combine(target, Mods[2], "Scripts", "Credits-config.lua"), Utf8.GetBytes("return {Target=" + mrpTarget.ToString(System.Globalization.CultureInfo.InvariantCulture) + "}\n"));
            AtomicWrite(config, Utf8.GetBytes(text));
        }
        catch (Exception failure)
        {
            try
            {
                for (int i = 0; i < Mods.Length; i++)
                {
                    var dest = Path.Combine(target, Mods[i]); RejectLink(dest);
                    if (Directory.Exists(dest)) Directory.Delete(dest, true);
                    if (existed[i]) CopyTree(Path.Combine(stamp, Mods[i]), dest);
                }
                if (hadConfig) File.Copy(Path.Combine(stamp, "mods.txt"), config, true);
                else if (File.Exists(config)) File.Delete(config);
            }
            catch (Exception rollback) { throw new IOException($"Install failed: {failure.Message}\nAutomatic rollback also failed: {rollback.Message}\nOriginal files are backed up at {stamp}"); }
            throw new IOException("Install failed; original mod files were restored. " + failure.Message, failure);
        }
        return saved;
    }
    sealed record DlssState(string path, bool existed, string backup, string after);
    public string Dlss(bool enable)
    {
        EnsureClosed(); RejectLink(Home); RejectLink(Ini); Directory.CreateDirectory(Home);
        var stateFile = Path.Combine(Home, "dlss-state.json"); RejectLink(stateFile);
        if (!enable)
        {
            if (!File.Exists(stateFile)) throw new IOException("No DLSS tweak from this launcher is recorded. Nothing changed.");
            var state = JsonSerializer.Deserialize<DlssState>(File.ReadAllText(stateFile)) ?? throw new IOException("Invalid DLSS restore record.");
            if (!string.Equals(Path.GetFullPath(state.path), Ini, StringComparison.OrdinalIgnoreCase)) throw new IOException("Saved configuration location does not match.");
            if (!File.Exists(Ini) || Hash(Ini) != state.after) throw new IOException("Engine.ini changed since enabling. Restore stopped to preserve newer changes. The original is in Open Backups.");
            if (state.existed) { RejectLink(state.backup); AtomicWrite(Ini, File.ReadAllBytes(state.backup)); }
            else File.Delete(Ini);
            File.Delete(stateFile); return "DLSS tweak removed; previous Engine.ini restored.";
        }
        if (File.Exists(stateFile)) return "DLSS tweak is already recorded as enabled. Disable it before reapplying.";
        bool existed = File.Exists(Ini); byte[] original = existed ? File.ReadAllBytes(Ini) : [];
        Encoding encoding = Utf8; int skip = 0;
        if (original.AsSpan().StartsWith(new byte[] {255,254})) { encoding = new UnicodeEncoding(false, true, true); skip = 2; }
        else if (original.AsSpan().StartsWith(new byte[] {254,255})) { encoding = new UnicodeEncoding(true, true, true); skip = 2; }
        else if (original.AsSpan().StartsWith(new byte[] {239,187,191})) { encoding = new UTF8Encoding(true, true); skip = 3; }
        var keys = new Dictionary<string,string>(StringComparer.OrdinalIgnoreCase) { ["r.Streamline.InitializePlugin"]="1", ["r.Streamline.DLSSG.Enable"]="1", ["t.Streamline.Reflex.Mode"]="1" };
        var lines = new List<string>(); bool inside = false;
        using (var reader = new StringReader(encoding.GetString(original, skip, original.Length - skip)))
        {
            string? line;
            while ((line = reader.ReadLine()) != null)
            {
                var match = Regex.Match(line, @"^\s*\[([^]]+)\]");
                if (match.Success) inside = match.Groups[1].Value.Equals("ConsoleVariables", StringComparison.OrdinalIgnoreCase);
                if (!inside || !keys.ContainsKey(line.Split('=',2)[0].Trim())) lines.Add(line);
            }
        }
        lines.Add(""); lines.Add("[ConsoleVariables]"); lines.AddRange(keys.Select(k => k.Key + " = " + k.Value));
        byte[] updated = [.. encoding.GetPreamble(), .. encoding.GetBytes(string.Join("\r\n", lines) + "\r\n")];
        RejectLink(Backups); Directory.CreateDirectory(Backups);
        var prior = Path.Combine(Backups, "Engine-before-DLSS-" + Stamp() + ".ini"); File.WriteAllBytes(prior, original);
        AtomicWrite(Ini, updated);
        try { AtomicWrite(stateFile, Utf8.GetBytes(JsonSerializer.Serialize(new DlssState(Ini, existed, prior, Hash(Ini))))); }
        catch { if (existed) AtomicWrite(Ini, original); else File.Delete(Ini); throw; }
        return "DLSS configuration enabled. Original settings backed up; restart and verify in game.";
    }
    public ProcessStartInfo LaunchInfo(string game, bool noEac)
    {
        EnsureClosed();
        if (!noEac) return new ProcessStartInfo("steam://rungameid/2288340") { UseShellExecute = true };
        var exe = Path.Combine(Path.GetFullPath(game), "Game", "Binaries", "Win64", "AceCombat8.exe");
        if (!File.Exists(exe)) throw new IOException("Game executable not found.");
        var info = new ProcessStartInfo(exe) { WorkingDirectory = Path.GetDirectoryName(exe)!, UseShellExecute = false };
        info.ArgumentList.Add("-SaveToUserDir"); info.Environment["SteamAppId"] = "2288340"; info.Environment["SteamGameId"] = "2288340";
        foreach (var key in info.Environment.Keys.ToArray()) if (key.StartsWith("_PYI_") || key == "_MEIPASS2") info.Environment.Remove(key);
        return info;
    }
}

