using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net.NetworkInformation;

internal static class Launcher
{
    private static int Main()
    {
        string root=AppDomain.CurrentDomain.BaseDirectory;
        string node=Path.Combine(root,"runtime","node.exe");
        string chat=Path.Combine(root,"chat","web-server.mjs");
        if(!File.Exists(node)||!File.Exists(chat)){Console.Error.WriteLine("代理文件不完整，请重新解压或运行安装器。");return 2;}
        var port=8766;
        if(IPGlobalProperties.GetIPGlobalProperties().GetActiveTcpListeners().Any(x=>x.Port==port))
        {
            Console.Error.WriteLine(string.Format("端口 {0} 已被其他实例占用，请先关闭旧的 TIA V20 AI 助手实例。", port));
            return 4;
        }
        var info=new ProcessStartInfo(node,"\""+chat+"\""){WorkingDirectory=root,UseShellExecute=false,CreateNoWindow=false};
        info.EnvironmentVariables["TIA_AGENT_PORT"]="8766";
        using(var p=Process.Start(info)){if(p==null)return 3; System.Threading.Thread.Sleep(1800); Process.Start(new ProcessStartInfo("http://127.0.0.1:8766/"){UseShellExecute=true}); p.WaitForExit(); return p.ExitCode;}
    }
}
