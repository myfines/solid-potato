param([string]$TargetRoot='')
$ErrorActionPreference='Stop'
$source=Split-Path -Parent $MyInvocation.MyCommand.Path
$appRoot=if($TargetRoot){[IO.Path]::GetFullPath($TargetRoot)}else{Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'TiaV20Agent'}
if($TargetRoot){$sourceFull=([IO.Path]::GetFullPath($source)).TrimEnd([char[]]'\\/'); $targetFull=([IO.Path]::GetFullPath($appRoot)).TrimEnd([char[]]'\\/'); if($targetFull.StartsWith($sourceFull+'\',[StringComparison]::OrdinalIgnoreCase) -or $targetFull -eq $sourceFull){throw 'TargetRoot must not be inside the package source directory.'}}
$target=Join-Path $appRoot 'current'
New-Item -ItemType Directory -Force -Path $target | Out-Null
$allow=@('chat','runtime','docs','scripts','start-agent.ps1','start-agent.cmd','install-agent.ps1','install-agent.cmd','mcp.example.json','THIRD-PARTY-SOURCES.txt','MANIFEST.sha256.json','README.md','TiaV20Agent.exe')
foreach($name in $allow){$item=Join-Path $source $name; if(Test-Path $item){Copy-Item -LiteralPath $item -Destination $target -Recurse -Force}}
Write-Output "Installed proxy agent: $target"
Write-Output "Start with: $(Join-Path $target 'start-agent.cmd')"
$firewall=Join-Path $target 'scripts\setup-openness-firewall.ps1'
if(Test-Path -LiteralPath $firewall){
  $mcp=Join-Path $target 'runtime\TiaPortalMcpServer.exe'
  $needs=$true
  if(Test-Path -LiteralPath $mcp){
    $info=Get-Item -LiteralPath $mcp
    $hash=[Convert]::ToBase64String([System.Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($info.FullName)))
    $entry=Get-ItemProperty 'HKLM:\SOFTWARE\Siemens\Automation\Openness\20.0\Whitelist\TiaPortalMcpServer.exe\Entry' -ErrorAction SilentlyContinue
    $needs=(-not $entry -or $entry.Path -ne $info.FullName -or $entry.FileHash -ne $hash)
  }
  if($needs){
    Write-Output '首次运行需要为 TIA Openness 正式程序登记一次白名单，随后会显示一个 UAC 确认。'
    $arg="-NoProfile -ExecutionPolicy Bypass -File `"$firewall`" -AppRoot `"$target`" -Apply"
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arg -Wait
  } else { Write-Output 'TIA Openness 白名单已是最新，无需再次授权。' }
}
