$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$source='E:\simense\Projects\SelfHoldRelay'
$stamp=Get-Date -Format yyyyMMdd-HHmmss
$test=Join-Path $root "testdata\Regression-$stamp"
New-Item -ItemType Directory -Force -Path (Split-Path $test) | Out-Null
Copy-Item -LiteralPath $source -Destination $test -Recurse
$project=Join-Path $test 'SelfHoldRelay.ap20'
$projectJson=$project.Replace('\','\\')
$scl=Join-Path $root 'testdata\SelfHoldRelay.scl'
$sclJson=$scl.Replace('\','\\')
$input=@"
{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"environment_doctor","arguments":{}}}
{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"project_open","arguments":{"path":"$projectJson"}}}
{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"devices_list","arguments":{}}}
{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"project_compile","arguments":{"project":"$projectJson","confirmed":false}}}
{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"scl_apply","arguments":{"sourceName":"RegressionBlock","file":"$sclJson","confirmed":true,"backupConfirmed":true}}}
{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"blocks_list","arguments":{"device":"CPU_1"}}}
"@
$output=$input | powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\tia-mcp-v20.ps1')
$lines=@($output -split "`r?`n" | Where-Object {$_ -match '^\{"jsonrpc"'})
if($lines.Count -lt 6){throw "Expected 6 JSON responses, got $($lines.Count)"}
$responses=$lines | ForEach-Object {$_ | ConvertFrom-Json}
if($responses[0].result -eq $null){throw 'environment_doctor failed'}
if($responses[1].result -eq $null){throw 'project_open failed'}
if($responses[3].error -eq $null){throw 'unauthorized compile was not rejected'}
if($responses[4].result -eq $null){throw "SCL apply failed: $($responses[4].error.message)"}
if(($responses[5].result.content[0].text -notmatch 'AiSelfHoldTest')){throw 'generated block was not found'}
Write-Output "PASS: MCP V20 regression ($test)"
