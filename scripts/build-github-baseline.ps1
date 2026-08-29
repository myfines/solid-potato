$ErrorActionPreference='Stop'
$repo=Join-Path (Split-Path -Parent $PSScriptRoot) 'vendor\chewcw-tia-mcp'
if(-not (Test-Path (Join-Path $repo 'TiaPortalMcpServer\TiaPortalMcpServer.csproj'))){throw "GitHub baseline not found: $repo"}
Push-Location $repo
try {
  dotnet restore .\TiaPortalMcpServer\TiaPortalMcpServer.csproj --ignore-failed-sources
  if($LASTEXITCODE -ne 0){throw 'restore failed'}
  dotnet build .\TiaPortalMcpServer\TiaPortalMcpServer.csproj --no-restore -c Release
  if($LASTEXITCODE -ne 0){throw 'build failed'}
  Write-Output (Join-Path $repo 'TiaPortalMcpServer\bin\Release\net48\TiaPortalMcpServer.exe')
} finally { Pop-Location }
