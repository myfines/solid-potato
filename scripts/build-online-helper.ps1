$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$out=Join-Path $root 'bin'
$api='E:\simense\Portal V20\PublicAPI\V20'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$exe=Join-Path $out 'tia-v20-online-helper.exe'
$ref1=Join-Path $api 'Siemens.Engineering.dll'
$ref2=Join-Path $api 'Siemens.Engineering.Contract.dll'
$source=Join-Path $root 'src\TiaV20.OnlineHelper.cs'
& 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe' /nologo /target:exe /platform:x64 "/out:$exe" "/reference:$ref1" "/reference:$ref2" $source
if($LASTEXITCODE -ne 0){throw 'online helper build failed'}
Write-Output $exe
