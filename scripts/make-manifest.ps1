param([Parameter(Mandatory=$true)][string]$PackageRoot)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath($PackageRoot)
if(-not (Test-Path $root)){throw "Package root not found: $root"}
$files=Get-ChildItem -LiteralPath $root -File -Recurse | Sort-Object FullName
$items=@($files | ForEach-Object { $relative=$_.FullName.Substring($root.Length).TrimStart([char[]]'\\/'); [ordered]@{path=$relative;length=$_.Length;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash} })
[ordered]@{generated=(Get-Date).ToUniversalTime().ToString('o');fileCount=$items.Count;files=$items} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $root 'MANIFEST.sha256.json') -Encoding UTF8
Write-Output (Join-Path $root 'MANIFEST.sha256.json')
