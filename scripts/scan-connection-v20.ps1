$ErrorActionPreference='Stop'
Add-Type -Path 'E:\simense\Portal V20\PublicAPI\V20\Siemens.Engineering.dll'
$portal=New-Object Siemens.Engineering.TiaPortal([Siemens.Engineering.TiaPortalMode]::WithoutUserInterface)
$project=$portal.Projects.Open([IO.FileInfo]::new('E:\simense\Projects\SelfHoldRelay\SelfHoldRelay.ap20'))
try {
  $results=@()
  $device=$project.Devices | Select-Object -First 1
  $queue=New-Object System.Collections.Generic.Queue[object]; foreach($root in $device.DeviceItems){$queue.Enqueue($root)}
  while($queue.Count){
    $item=$queue.Dequeue()
    foreach($child in $item.DeviceItems){$queue.Enqueue($child)}
    $m=$item.GetType().GetMethod('GetService')
    if(-not $m){continue}
    $dp=$m.MakeGenericMethod([Siemens.Engineering.Download.DownloadProvider]).Invoke($item,@())
    if(-not $dp){continue}
    foreach($mode in $dp.Configuration.Modes){
      foreach($iface in $mode.PcInterfaces){
        $found=@()
        try{$found=@($iface.GetAccessibleDevices())}catch{$found=@([pscustomobject]@{Error=$_.Exception.Message})}
        $results += [pscustomobject]@{Mode=$mode.Name;Interface=$iface.Name;AccessibleDevices=@($found | ForEach-Object {[ordered]@{Name="$($_.Name)";Type="$($_.TypeIdentifier)";Address="$($_.Address)";Mac="$($_.MacAddress)"}})}
      }
    }
  }
  $results | ConvertTo-Json -Depth 10
} finally {$project.Close();$portal.Dispose()}
