$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'bin'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$source = 'E:\simense\SiemensChatAgent\TiaAgentBridge.cs'
$api = 'E:\simense\Portal V20\PublicAPI\V20'
if (-not (Test-Path $source)) { throw "Bridge source not found: $source" }
$outExe = Join-Path $out 'tia-agent-bridge.exe'
$refEngineering = '/reference:' + (Join-Path $api 'Siemens.Engineering.dll')
$refContract = '/reference:' + (Join-Path $api 'Siemens.Engineering.Contract.dll')
& 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe' /nologo /target:exe "/out:$outExe" $refEngineering $refContract $source
if ($LASTEXITCODE -ne 0) { throw "csc failed with exit code $LASTEXITCODE" }
$runtimeNames = @('Siemens.Engineering.dll','Siemens.Engineering.Contract.dll','Siemens.Engineering.Hmi.dll','Siemens.Engineering.ClientAdapter.Interfaces.dll','Siemens.Engineering.ClientAdapter.MarshallerHook.dll','Siemens.Engineering.ClientAdapter.MarshallerHook.Hmi.dll','Siemens.Automation.Opns.ServerAdpt.MrshHook.Impl.dll','Siemens.Simatic.Hmi.Openness.Server.MarshallerHook.dll')
foreach ($name in $runtimeNames) { Copy-Item -LiteralPath (Join-Path $api $name) -Destination $out -Force }
Write-Output "Built: $(Join-Path $out 'tia-agent-bridge.exe')"
