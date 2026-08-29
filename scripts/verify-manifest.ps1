param([Parameter(Mandatory=$true)][string]$PackageRoot)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath($PackageRoot)
$manifest=Join-Path $root 'MANIFEST.sha256.json'
if(-not (Test-Path $manifest)){throw "Manifest not found: $manifest"}
$data=Get-Content -Raw $manifest | ConvertFrom-Json
$failed=@(); foreach($item in $data.files){$file=Join-Path $root $item.path; if(-not (Test-Path $file)){$failed+="$($item.path): missing";continue}; $hash=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash; if($hash -ne $item.sha256){$failed+="$($item.path): hash mismatch"}}
if($failed.Count){$failed | ForEach-Object {Write-Error $_}; exit 1}
Write-Output "Manifest verified: $($data.fileCount) files"
