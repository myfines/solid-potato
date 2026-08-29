$ErrorActionPreference = 'Stop'
$api = 'E:\simense\Portal V20\PublicAPI\V20\Siemens.Engineering.dll'
$projectPath = 'E:\simense\Projects\SelfHoldRelay\SelfHoldRelay.ap20'
Add-Type -Path $api
$portal = $null; $project = $null
try {
  $portal = New-Object Siemens.Engineering.TiaPortal([Siemens.Engineering.TiaPortalMode]::WithoutUserInterface)
  $project = $portal.Projects.Open([IO.FileInfo]::new($projectPath))
  $out = [ordered]@{ Project=$project.Name; Devices=@(); Items=@(); Plcs=@(); ServiceErrors=@() }
  foreach ($device in $project.Devices) {
    $d = [ordered]@{ Name=$device.Name; Type="$($device.TypeIdentifier)"; Items=@($device.DeviceItems | ForEach-Object Name) }
    $out.Devices += [pscustomobject]$d
    $items = New-Object System.Collections.Generic.List[object]
    function Add-DeviceItem([object]$node) {
      $items.Add($node)
      foreach ($child in $node.DeviceItems) { Add-DeviceItem $child }
    }
    foreach ($root in $device.DeviceItems) { Add-DeviceItem $root }
    foreach ($item in $items) {
      $out.Items += [pscustomobject]@{ Name=$item.Name; Type=$item.GetType().FullName }
      try {
        $getService = $item.GetType().GetMethod('GetService')
        $container = $getService.MakeGenericMethod([Siemens.Engineering.HW.Features.SoftwareContainer]).Invoke($item, @())
        $sw = if ($container) { $container.Software } else { $null }
        if (-not $sw) { continue }
        $plc = [ordered]@{ Device=$device.Name; Blocks=@(); Tags=@() }
        foreach ($block in $sw.BlockGroup.Blocks) {
          $plc.Blocks += [pscustomobject][ordered]@{ Name=$block.Name; Type=$block.GetType().Name; Number="$($block.NumberOfBlock.Number)" }
        }
        foreach ($table in $sw.TagTableGroup.TagTables) {
          foreach ($tag in $table.Tags) {
            $plc.Tags += [pscustomobject][ordered]@{ Table=$table.Name; Name=$tag.Name; DataType="$($tag.DataTypeName)"; Address="$($tag.LogicalAddress)" }
          }
        }
        $out.Plcs += [pscustomobject]$plc
      } catch { $out.ServiceErrors += [pscustomobject]@{ Item=$item.Name; Error=$_.Exception.Message } }
    }
  }
  [pscustomobject]$out | ConvertTo-Json -Depth 8
} finally {
  if ($project) { $project.Close() }
  if ($portal) { $portal.Dispose() }
}
