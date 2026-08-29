param(
  [string]$AppRoot = '',
  [switch]$Apply
)
$ErrorActionPreference='Stop'
$packageRoot=Split-Path -Parent $PSScriptRoot
if([string]::IsNullOrWhiteSpace($AppRoot)){$AppRoot=$packageRoot}
$files=@(
  (Join-Path $AppRoot 'runtime\TiaPortalMcpServer.exe'),
  (Join-Path $AppRoot 'bin\tia-agent-bridge.exe')
) | Where-Object { Test-Path -LiteralPath $_ }
if($files.Count -eq 0){throw "未找到 TIA Openness 调用程序：$AppRoot。请先运行安装器。"}
$version='20.0'
$base='HKLM:\SOFTWARE\Siemens\Automation\Openness\'+$version+'\Whitelist'
if(-not $Apply){
  Write-Output '预览模式：以下程序需要首次加入 TIA Openness 白名单。重新编译或更换路径后需要重新登记。'
}
foreach($file in $files){
  $info=Get-Item -LiteralPath $file
  $hash=[Convert]::ToBase64String([System.Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($info.FullName)))
  $name=$info.Name
  $key=Join-Path $base $name
  if($Apply){
    New-Item -Path $key -Force | Out-Null
    New-Item -Path (Join-Path $key 'Entry') -Force | Out-Null
    Set-ItemProperty -Path (Join-Path $key 'Entry') -Name Path -Value $info.FullName
    Set-ItemProperty -Path (Join-Path $key 'Entry') -Name DateModified -Value $info.LastWriteTimeUtc.ToString('yyyy/MM/dd HH:mm:ss.fff')
    Set-ItemProperty -Path (Join-Path $key 'Entry') -Name FileHash -Value $hash
    Write-Output "已登记：$($info.FullName)"
  } else {
    Write-Output "$($info.FullName) | $($info.LastWriteTimeUtc.ToString('yyyy/MM/dd HH:mm:ss.fff')) | $hash"
  }
}
if($Apply){Write-Output '完成。请关闭并重新打开 TIA Portal；以后同一版本程序不会重复询问。'}
