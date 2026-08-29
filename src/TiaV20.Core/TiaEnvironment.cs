using System;
using System.IO;

namespace TiaV20.Core;

public sealed record TiaEnvironment(string ApiDirectory, string ApiAssembly, bool HasPlcsim, bool HasOpennessGroup);

public static class TiaEnvironmentDetector
{
    public static TiaEnvironment Detect()
    {
        var candidates = new[]
        {
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "Siemens", "Automation", "Portal V20", "PublicAPI", "V20"),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "Siemens", "Automation", "Portal V20_0", "PublicAPI", "V20"),
            @"E:\simense\Portal V20\PublicAPI\V20"
        };
        var dir = Array.Find(candidates, Directory.Exists) ?? string.Empty;
        var api = Path.Combine(dir, "Siemens.Engineering.dll");
        var plcsim = Directory.Exists(@"E:\simense\PLCSIM_V20");
        return new TiaEnvironment(dir, api, plcsim, false);
    }
}

