using System;
using Siemens.Engineering;

namespace TiaV20.Core;

public sealed class TiaSession : IDisposable
{
    private TiaPortal? _portal;
    private Project? _project;

    public bool IsConnected => _portal != null;
    public bool HasProject => _project != null;

    public void Connect(bool withUserInterface = false)
    {
        if (_portal != null) return;
        var mode = withUserInterface ? TiaPortalMode.WithUserInterface : TiaPortalMode.WithoutUserInterface;
        _portal = new TiaPortal(mode);
    }

    public void OpenProject(string path)
    {
        if (_portal == null) throw new InvalidOperationException("TIA Portal is not connected.");
        if (string.IsNullOrWhiteSpace(path)) throw new ArgumentException("Project path is required.", nameof(path));
        _project = _portal.Projects.Open(new System.IO.FileInfo(path));
    }

    public string ProjectSummary() => _project == null
        ? throw new InvalidOperationException("No project is open.")
        : $"{_project.Name} | {_project.Path}";

    public void Save() => (_project ?? throw new InvalidOperationException("No project is open.")).Save();

    public void CloseProject() { _project?.Close(); _project = null; }

    public void Dispose()
    {
        CloseProject();
        _portal?.Dispose();
        _portal = null;
    }
}

