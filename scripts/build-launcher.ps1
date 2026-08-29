$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$out=Join-Path $root 'bin'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$exe=Join-Path $out 'TiaV20Agent.exe'
& 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe' /nologo /target:exe /platform:x64 "/out:$exe" (Join-Path $root 'src\Launcher.cs')
if($LASTEXITCODE -ne 0){throw 'launcher build failed'}
Write-Output $exe

