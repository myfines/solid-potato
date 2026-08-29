using System;
using System.IO;
using System.Reflection;
using System.Linq;
using Siemens.Engineering;
using Siemens.Engineering.HW;
using Siemens.Engineering.Download;
using Siemens.Engineering.Online;

internal static class TiaV20OnlineHelper
{
    static TiaV20OnlineHelper()
    {
        AppDomain.CurrentDomain.AssemblyResolve += ResolveSiemensAssembly;
    }

    private static Assembly ResolveSiemensAssembly(object sender, ResolveEventArgs args)
    {
        string file = new AssemblyName(args.Name).Name + ".dll";
        string[] roots = { Environment.GetEnvironmentVariable("TiaPortalLocation"), @"C:\Program Files\Siemens\Automation\Portal V20", @"E:\simense\Portal V20" };
        foreach (string root in roots)
        {
            if (String.IsNullOrWhiteSpace(root)) continue;
            string path = Path.Combine(root, "PublicAPI", "V20", file);
            if (File.Exists(path)) return Assembly.LoadFrom(path);
        }
        return null;
    }

    private static DeviceItem FindPlcItem(Device device)
    {
        foreach (DeviceItem root in device.DeviceItems)
        {
            DeviceItem found = FindPlcItemRecursive(root);
            if (found != null) return found;
        }
        return null;
    }

    private static DeviceItem FindPlcItemRecursive(DeviceItem item)
    {
        try { if (item.GetService<DownloadProvider>() != null) return item; } catch { }
        foreach (DeviceItem child in item.DeviceItems)
        {
            DeviceItem found = FindPlcItemRecursive(child);
            if (found != null) return found;
        }
        return null;
    }

    private static void WithProject(string path, Action<Project, Device> action)
    {
        using (TiaPortal portal = new TiaPortal(TiaPortalMode.WithoutUserInterface))
        {
            Project project = portal.Projects.Open(new FileInfo(path));
            try
            {
                Device device = project.Devices.FirstOrDefault();
                if (device == null) throw new InvalidOperationException("No device in project.");
                action(project, device);
            }
            finally { project.Close(); }
        }
    }

    private static int Main(string[] args)
    {
        try
        {
            if (args.Length < 2) throw new ArgumentException("Usage: status|configure|online|offline|download <project.ap20> [interface] [targetIp] [--confirm]");
            string command = args[0].ToLowerInvariant();
            string project = Path.GetFullPath(args[1]);
            if (!File.Exists(project)) throw new FileNotFoundException("Project not found", project);
            if ((command == "configure" || command == "online" || command == "offline" || command == "download") && !args.Contains("--confirm"))
                throw new InvalidOperationException("This operation changes device state; add --confirm explicitly.");

            WithProject(project, (p, device) =>
            {
                DeviceItem item = FindPlcItem(device);
                if (item == null) throw new InvalidOperationException("No PLC online/download item found.");
                if (command == "status")
                {
                    OnlineProvider op = item.GetService<OnlineProvider>();
                    DownloadProvider dp = item.GetService<DownloadProvider>();
                    object onlineState = null; if (op != null) { var property = op.GetType().GetProperty("OnlineState"); if (property != null) onlineState = property.GetValue(op, null); }
                    Console.WriteLine("{\"ok\":true,\"device\":\"" + Escape(device.Name) + "\",\"item\":\"" + Escape(item.Name) + "\",\"onlineProvider\":" + (op != null ? "true" : "false") + ",\"downloadProvider\":" + (dp != null ? "true" : "false") + ",\"state\":\"" + Escape(onlineState == null ? "" : onlineState.ToString()) + "\"}");
                }
                else if (command == "configure")
                {
                    if (args.Length < 4) throw new ArgumentException("configure requires <interfaceName> <targetIp>.");
                    OnlineProvider op = item.GetService<OnlineProvider>();
                    var mode = op.Configuration.Modes.Find("PN/IE");
                    if (mode == null) throw new InvalidOperationException("PN/IE configuration mode not found.");
                    var pc = mode.PcInterfaces.Find(args[2], 1);
                    if (pc == null) throw new InvalidOperationException("PC interface not found: " + args[2]);
                    var target = pc.TargetInterfaces.Count > 0 ? pc.TargetInterfaces[0] : null;
                    if (target == null) throw new InvalidOperationException("No target interface under PC interface: " + args[2]);
                    var address = target.Addresses.Find(args[3]) ?? target.Addresses.Create(args[3]);
                    bool applied = op.Configuration.ApplyConfiguration(address);
                    Console.WriteLine("{\"ok\":true,\"applied\":" + (applied ? "true" : "false") + ",\"interface\":\"" + Escape(args[2]) + "\",\"targetIp\":\"" + Escape(args[3]) + "\"}");
                }
                else if (command == "online") { item.GetService<OnlineProvider>().GoOnline(); Console.WriteLine("{\"ok\":true,\"state\":\"online\"}"); }
                else if (command == "offline") { item.GetService<OnlineProvider>().GoOffline(); Console.WriteLine("{\"ok\":true,\"state\":\"offline\"}"); }
                else if (command == "download")
                {
                    DownloadProvider dp = item.GetService<DownloadProvider>();
                    DownloadResult result = dp.Download(new DirectoryInfo(Path.GetTempPath()), null);
                    Console.WriteLine("{\"ok\":true,\"state\":\"" + Escape(result.State.ToString()) + "\"}");
                }
                else throw new ArgumentException("Unknown command: " + command);
            });
            return 0;
        }
        catch (Exception ex) { Console.WriteLine("{\"ok\":false,\"error\":\"" + Escape(ex.Message) + "\"}"); return 1; }
    }

    private static string Escape(string value) { return (value ?? "").Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "\\r").Replace("\n", "\\n"); }
}
