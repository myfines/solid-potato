$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$runtimeSource=Join-Path $root 'vendor\chewcw-tia-mcp\TiaPortalMcpServer\bin\Release\net48'
$exe=Join-Path $runtimeSource 'TiaPortalMcpServer.exe'
if(-not (Test-Path $exe)){throw 'Build the GitHub V20 baseline first.'}
$onlineHelper=Join-Path $root 'bin\tia-v20-online-helper.exe'
if(-not (Test-Path $onlineHelper)){& (Join-Path $root 'scripts\build-online-helper.ps1') | Out-Null}
if(-not (Test-Path (Join-Path $root 'chat\node_modules\@modelcontextprotocol\sdk'))){throw 'Run npm install in chat first.'}
$stamp=Get-Date -Format yyyyMMdd-HHmmss
$dist=Join-Path $root "dist\tia-v20-agent-$stamp"
New-Item -ItemType Directory -Force -Path (Join-Path $dist 'runtime'),(Join-Path $dist 'chat'),(Join-Path $dist 'docs'),(Join-Path $dist 'scripts') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $dist 'skills') | Out-Null
Get-ChildItem -LiteralPath $runtimeSource -File | Where-Object { $_.Name -notmatch '^Siemens\.Engineering' } | Copy-Item -Destination (Join-Path $dist 'runtime') -Force
Copy-Item -LiteralPath $onlineHelper -Destination (Join-Path $dist 'runtime') -Force
$portableNode='E:\simense\SiemensChatAgent\runtime\node.exe'
if(Test-Path $portableNode){Copy-Item -LiteralPath $portableNode -Destination (Join-Path $dist 'runtime') -Force}
Copy-Item -LiteralPath (Join-Path $root 'chat\deepseek-chat.mjs'),(Join-Path $root 'chat\web-server.mjs'),(Join-Path $root 'chat\motor-workflow.mjs'),(Join-Path $root 'chat\package.json'),(Join-Path $root 'chat\package-lock.json'),(Join-Path $root 'chat\README.md') -Destination (Join-Path $dist 'chat')
New-Item -ItemType Directory -Force -Path (Join-Path $dist 'chat\lad-adapter') | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'chat\lad-adapter\generator.mjs'),(Join-Path $root 'chat\lad-adapter\ps-runner.js'),(Join-Path $root 'chat\lad-adapter\write-block.ps1') -Destination (Join-Path $dist 'chat\lad-adapter')
Copy-Item -LiteralPath (Join-Path $root 'chat\node_modules') -Destination (Join-Path $dist 'chat') -Recurse
Copy-Item -LiteralPath (Join-Path $root 'docs\validation.md'),(Join-Path $root 'docs\roadmap.md'),(Join-Path $root 'docs\first-connection.md'),(Join-Path $root 'docs\requirements-matrix.md'),(Join-Path $root 'docs\BEGINNER-GUIDE.md'),(Join-Path $root 'docs\USER-INSTALL-GUIDE.md'),(Join-Path $root 'docs\AUTO-INSTALL-DESIGN.md'),(Join-Path $root 'docs\full-flow-test-20260829.md'),(Join-Path $root 'docs\FINAL-TEST-REPORT.md'),(Join-Path $root 'docs\OPEN-SOURCE-AGENT-PATTERNS.md') -Destination (Join-Path $dist 'docs')
if(Test-Path (Join-Path $root 'docs\third-party.md')){Copy-Item -LiteralPath (Join-Path $root 'docs\third-party.md') -Destination (Join-Path $dist 'docs')}
Copy-Item -LiteralPath (Join-Path $root 'scripts\preflight-v20.ps1'),(Join-Path $root 'scripts\build-user-release.ps1') -Destination (Join-Path $dist 'scripts')
Copy-Item -LiteralPath (Join-Path $root 'scripts\make-manifest.ps1') -Destination (Join-Path $dist 'scripts')
Copy-Item -LiteralPath (Join-Path $root 'scripts\verify-manifest.ps1') -Destination (Join-Path $dist 'scripts')
Copy-Item -LiteralPath (Join-Path $root 'scripts\diagnose-connection-v20.ps1'),(Join-Path $root 'scripts\scan-connection-v20.ps1') -Destination (Join-Path $dist 'scripts')
Copy-Item -LiteralPath (Join-Path $root 'scripts\setup-environment.ps1') -Destination (Join-Path $dist 'scripts')
Copy-Item -LiteralPath (Join-Path $root 'scripts\setup-openness-firewall.ps1') -Destination (Join-Path $dist 'scripts')
if(-not (Test-Path (Join-Path $root 'bin\TiaV20Agent.exe'))){& (Join-Path $root 'scripts\build-launcher.ps1') | Out-Null}
Copy-Item -LiteralPath (Join-Path $root 'bin\TiaV20Agent.exe') -Destination $dist -Force
Copy-Item -LiteralPath (Join-Path $root 'start-agent.ps1'),(Join-Path $root 'start-agent.cmd') -Destination $dist
Copy-Item -LiteralPath (Join-Path $root 'install-agent.ps1'),(Join-Path $root 'install-agent.cmd') -Destination $dist
Copy-Item -LiteralPath (Join-Path $root 'README.md') -Destination (Join-Path $dist 'README.md')
Copy-Item -LiteralPath (Join-Path $root 'config\mcp-package.example.json') -Destination (Join-Path $dist 'mcp.example.json')
Copy-Item -LiteralPath (Join-Path $root 'docs\third-party.md') -Destination (Join-Path $dist 'THIRD-PARTY-SOURCES.txt')
Copy-Item -LiteralPath (Join-Path $root 'skills\tia-v20-agent') -Destination (Join-Path $dist 'skills') -Recurse -Force
@('Siemens.Engineering.dll','Siemens.Engineering.Hmi.dll','*.ap20','*.zap20','*.s7dcl','*.s7res') | ForEach-Object { if(Get-ChildItem -Path $dist -Filter $_ -Recurse -ErrorAction SilentlyContinue){throw "Forbidden artifact staged: $_"} }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\make-manifest.ps1') -PackageRoot $dist | Out-Null
Write-Output "Staged proxy-only package: $dist"
