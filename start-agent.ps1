$ErrorActionPreference='Stop'
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
$check=Join-Path $root 'scripts\preflight-v20.ps1'
if(Test-Path $check){$report=& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $check | ConvertFrom-Json; $report | ConvertTo-Json -Depth 4; if(-not $report.ready){Write-Error 'Preflight failed. Install/configure the reported prerequisite, then retry.'; exit 2}}
$chat=Join-Path $root 'chat'
$node=Join-Path $root 'runtime\node.exe'
if(-not (Test-Path $node)){$node=(Get-Command node.exe -ErrorAction SilentlyContinue).Source}
if(-not $node){Write-Error 'Node.js 18+ is required. Install Node.js, then retry.'; exit 2}
Push-Location $chat
try { $env:TIA_AGENT_PORT='8766'; & $node .\web-server.mjs } finally { Pop-Location }
exit $LASTEXITCODE
