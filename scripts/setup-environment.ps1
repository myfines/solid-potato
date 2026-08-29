param([switch]$RepairUserGroup)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
function IsAdmin { $id=[Security.Principal.WindowsIdentity]::GetCurrent(); $p=New-Object Security.Principal.WindowsPrincipal($id); return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
Write-Host '[1/5] Checking .NET and TIA prerequisites...'
$pre=& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'preflight-v20.ps1') | ConvertFrom-Json
if($RepairUserGroup -and $pre.opennessGroup -and -not $pre.opennessMember){
  if(-not (IsAdmin)){Write-Warning 'Administrator rights are required to repair the Openness user group.'}
  else { Add-LocalGroupMember -Group $pre.opennessGroup -Member "$env:USERDOMAIN\$env:USERNAME"; Write-Host '[OK] Current user added; sign out/in before using Openness.' }
}
Write-Host '[2/5] Installing Node dependencies...'
Push-Location (Join-Path $root 'chat'); try { if(-not (Test-Path '.\node_modules\@modelcontextprotocol\sdk')){ npm install --omit=dev }; if($LASTEXITCODE -ne 0){throw 'npm install failed'} } finally { Pop-Location }
Write-Host '[3/5] Building GitHub MCP...'
& (Join-Path $PSScriptRoot 'build-github-baseline.ps1') | Out-Host
Write-Host '[4/5] Building Online helper...'
& (Join-Path $PSScriptRoot 'build-online-helper.ps1') | Out-Host
Write-Host '[5/5] Running final preflight...'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'preflight-v20.ps1')

