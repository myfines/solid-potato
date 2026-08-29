$ErrorActionPreference = 'Stop'
$api = 'E:\simense\Portal V20\PublicAPI\V20\Siemens.Engineering.dll'
$projectPath = 'E:\simense\Projects\SelfHoldRelay\SelfHoldRelay.ap20'
Add-Type -Path $api
$portal = $null; $project = $null
try {
  $portal = New-Object Siemens.Engineering.TiaPortal([Siemens.Engineering.TiaPortalMode]::WithoutUserInterface)
  $project = $portal.Projects.Open([IO.FileInfo]::new($projectPath))
  $devices = foreach ($device in $project.Devices) {
    [pscustomobject]@{ Name=$device.Name; Type="$($device.TypeIdentifier)"; Items=@($device.DeviceItems | ForEach-Object Name) }
  }
  [pscustomobject]@{ Project=$project.Name; Path="$($project.Path)"; Devices=$devices } | ConvertTo-Json -Depth 6
} finally {
  if ($project) { $project.Close() }
  if ($portal) { $portal.Dispose() }
}

