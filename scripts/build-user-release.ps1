param(
  [Parameter(Mandatory=$true)][string]$PackageRoot,
  [string]$OutputZip=''
)
$ErrorActionPreference='Stop'
$PackageRoot=[IO.Path]::GetFullPath($PackageRoot).TrimEnd([char[]]'\\/')
if(-not (Test-Path -LiteralPath $PackageRoot -PathType Container)){throw "PackageRoot not found: $PackageRoot"}
foreach($required in @('TiaV20Agent.exe','README.md','MANIFEST.sha256.json','docs\USER-INSTALL-GUIDE.md','chat\web-server.mjs','chat\motor-workflow.mjs')){
  if(-not (Test-Path -LiteralPath (Join-Path $PackageRoot $required))){throw "Required release file missing: $required"}
}
if(-not $OutputZip){$OutputZip=Join-Path (Split-Path -Parent $PackageRoot) 'TiaV20Agent-UserRelease.zip'}
$OutputZip=[IO.Path]::GetFullPath($OutputZip)
if(Test-Path -LiteralPath $OutputZip){
  $dir=Split-Path -Parent $OutputZip
  $stem=[IO.Path]::GetFileNameWithoutExtension($OutputZip)
  $OutputZip=Join-Path $dir ($stem+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.zip')
}
Compress-Archive -Path (Join-Path $PackageRoot '*') -DestinationPath $OutputZip -CompressionLevel Fastest -Force
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::OpenRead($OutputZip)
try {
  $entries=@($zip.Entries | ForEach-Object {$_.FullName.Replace('\','/')})
  foreach($required in @('TiaV20Agent.exe','README.md','MANIFEST.sha256.json','docs/USER-INSTALL-GUIDE.md','chat/web-server.mjs','chat/motor-workflow.mjs')){
    if($entries -notcontains $required){throw "Release ZIP missing: $required"}
  }
  Write-Output "Release verified: $OutputZip ($($entries.Count) entries) from $PackageRoot"
} finally {$zip.Dispose()}
