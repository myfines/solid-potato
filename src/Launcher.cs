using System;
using System.Diagnostics;
using System.IO;

internal static class Launcher
{
    private static int Main()
    {
        string root=AppDomain.CurrentDomain.BaseDirectory;
        string node=Path.Combine(root,"runtime","node.exe");
        string chat=Path.Combine(root,"chat","web-server.mjs");
        if(!File.Exists(node)||!File.Exists(chat)){Console.Error.WriteLine("代理文件不完整，请重新解压或运行安装器。");return 2;}
        var info=new ProcessStartInfo(node,"\""+chat+"\""){WorkingDirectory=root,UseShellExecute=false,CreateNoWindow=false};
        using(var p=Process.Start(info)){if(p==null)return 3; System.Threading.Thread.Sleep(1800); Process.Start(new ProcessStartInfo("http://127.0.0.1:8765/"){UseShellExecute=true}); p.WaitForExit(); return p.ExitCode;}
    }
}
