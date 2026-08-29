$ErrorActionPreference = 'Stop'
$api = 'E:\simense\Portal V20\PublicAPI\V20\Siemens.Engineering.dll'
$projectPath = 'E:\simense\Projects\SelfHoldRelay\SelfHoldRelay.ap20'
Add-Type -Path $api
$portal=$null; $project=$null
try {
  $portal=New-Object Siemens.Engineering.TiaPortal([Siemens.Engineering.TiaPortalMode]::WithoutUserInterface)
  $project=$portal.Projects.Open([IO.FileInfo]::new($projectPath))
  $getService=$project.Devices[0].DeviceItems[1].GetType().GetMethod('GetService')
  $container=$getService.MakeGenericMethod([Siemens.Engineering.HW.Features.SoftwareContainer]).Invoke($project.Devices[0].DeviceItems[1], @())
  $software=$container.Software
  $compilerType = [AppDomain]::CurrentDomain.GetAssemblies() | ForEach-Object { $_.GetType('Siemens.Engineering.Compiler.CompileProvider') } | Where-Object { $_ } | Select-Object -First 1
  $compiler = $software.GetType().GetMethod('GetService').MakeGenericMethod($compilerType).Invoke($software, @())
  $result=$compiler.Compile()
  [pscustomobject]@{ State="$($result.State)"; Messages=@($result.Messages | ForEach-Object { [pscustomobject]@{ Severity="$($_.Severity)"; Description="$($_.Description)" } }) } | ConvertTo-Json -Depth 8
} finally { if($project){$project.Close()}; if($portal){$portal.Dispose()} }
