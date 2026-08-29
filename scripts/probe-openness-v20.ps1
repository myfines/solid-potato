$ErrorActionPreference = 'Stop'
$api = 'E:\simense\Portal V20\PublicAPI\V20\Siemens.Engineering.dll'
if (-not (Test-Path -LiteralPath $api)) { throw "V20 Openness DLL not found: $api" }
Add-Type -Path $api
$tia = $null
try {
  $tia = New-Object Siemens.Engineering.TiaPortal([Siemens.Engineering.TiaPortalMode]::WithoutUserInterface)
  Write-Output "OK: TIA Portal Openness instance created"
  Write-Output "Version: $($tia.Version)"
  Write-Output "Projects collection: $($tia.Projects.Count) attached project(s)"
} finally {
  if ($tia) { $tia.Dispose(); Write-Output 'OK: disposed' }
}

