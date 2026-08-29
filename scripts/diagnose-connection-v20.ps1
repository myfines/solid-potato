$ErrorActionPreference='Stop'
Add-Type -Path 'E:\simense\Portal V20\PublicAPI\V20\Siemens.Engineering.dll'
$portal=New-Object Siemens.Engineering.TiaPortal([Siemens.Engineering.TiaPortalMode]::WithoutUserInterface)
$project=$portal.Projects.Open([IO.FileInfo]::new('E:\simense\Projects\SelfHoldRelay\SelfHoldRelay.ap20'))
try {
  $results=@()
  foreach($device in $project.Devices){
    $queue=New-Object System.Collections.Generic.Queue[object]; foreach($root in $device.DeviceItems){$queue.Enqueue($root)}
    while($queue.Count){
      $item=$queue.Dequeue(); foreach($child in $item.DeviceItems){$queue.Enqueue($child)}
      $method=$item.GetType().GetMethod('GetService'); if(-not $method){continue}
      $download=$method.MakeGenericMethod([Siemens.Engineering.Download.DownloadProvider]).Invoke($item,@())
      if($download){
        $online=$method.MakeGenericMethod([Siemens.Engineering.Online.OnlineProvider]).Invoke($item,@())
        $modes=@(); foreach($mode in $download.Configuration.Modes){$ifs=@(); foreach($iface in $mode.PcInterfaces){$addresses=@(); foreach($address in $iface.Addresses){$addresses += [ordered]@{name="$($address.Name)";address="$($address.Address)"}}; $targets=@(); foreach($target in $iface.TargetInterfaces){$targets += [ordered]@{name="$($target.Name)";addresses=@($target.Addresses | ForEach-Object {[ordered]@{name="$($_.Name)";address="$($_.Address)"}})}}; $ifs += [ordered]@{name="$($iface.Name)";addresses=$addresses;targets=$targets}}; $modes += [ordered]@{name="$($mode.Name)";pcInterfaces=$ifs}}
        $results += [pscustomobject]@{Device=$device.Name;Item=$item.Name;Configured=[bool]$download.Configuration.IsConfigured;Modes=$modes;OnlineState="$($online.OnlineState)"}
      }
    }
  }
  $results | ConvertTo-Json -Depth 12
} finally { $project.Close(); $portal.Dispose() }
