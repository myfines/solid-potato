# Minimal MCP stdio server for TIA Portal V20.
# This host intentionally uses late-bound Openness calls: Windows PowerShell parses
# the script before Add-Type runs, so strong Siemens type annotations are unsafe here.
$ErrorActionPreference = 'Stop'
$script:Api = 'E:\simense\Portal V20\PublicAPI\V20\Siemens.Engineering.dll'
$script:Bridge = Join-Path (Split-Path -Parent $PSScriptRoot) 'bin\tia-agent-bridge.exe'
$script:Portal = $null; $script:Project = $null
Add-Type -Path $script:Api

function Result($id, $value) {
  [ordered]@{ jsonrpc='2.0'; id=$id; result=[ordered]@{ content=@([ordered]@{ type='text'; text=($value | ConvertTo-Json -Depth 12 -Compress) }) } } | ConvertTo-Json -Depth 20 -Compress
}
function ErrorResult($id, $message) {
  [ordered]@{ jsonrpc='2.0'; id=$id; error=[ordered]@{ code=-32000; message=$message } } | ConvertTo-Json -Depth 10 -Compress
}
function ExceptionText($exception) {
  $parts=@(); $current=$exception
  while($current){if($current.Message){$parts+=$current.Message}; $current=$current.InnerException}
  return ($parts -join ' | ')
}
function EnsurePortal {
  if (-not $script:Portal) { $script:Portal = New-Object Siemens.Engineering.TiaPortal([Siemens.Engineering.TiaPortalMode]::WithoutUserInterface) }
}
function EnsureProject { if (-not $script:Project) { throw 'No project is open. Call project_open first.' } }
function GetService($object, $serviceType) {
  $method = $object.GetType().GetMethod('GetService')
  if (-not $method) { return $null }
  $method.MakeGenericMethod($serviceType).Invoke($object, @())
}
function GetDevice($name) {
  EnsureProject
  foreach($device in $script:Project.Devices){if($device.Name -eq $name){return $device}}
  throw "Device not found: $name"
}
function FindDeviceService($device, $serviceType) {
  $queue=New-Object System.Collections.Generic.Queue[object]; foreach($root in $device.DeviceItems){$queue.Enqueue($root)}
  while($queue.Count){$item=$queue.Dequeue(); foreach($child in $item.DeviceItems){$queue.Enqueue($child)}; $service=GetService $item $serviceType; if($service){return $service}}
  return $null
}
function GetPlcSoftware($deviceName) {
  EnsureProject
  foreach ($device in $script:Project.Devices) {
    if ($device.Name -ne $deviceName) { continue }
    $pending = New-Object System.Collections.Generic.Queue[object]
    foreach ($item in $device.DeviceItems) { $pending.Enqueue($item) }
    while ($pending.Count) {
      $item = $pending.Dequeue(); foreach ($child in $item.DeviceItems) { $pending.Enqueue($child) }
      $container = GetService $item ([Siemens.Engineering.HW.Features.SoftwareContainer])
      if ($container -and $container.Software) { return $container.Software }
    }
  }
  throw "PLC software not found on device: $deviceName"
}
function FlattenMessages($messages, [string]$parentPath='') {
  $out=@()
  foreach($message in $messages) {
    $path=if([string]::IsNullOrWhiteSpace("$($message.Path)")){$parentPath}else{"$($message.Path)"}
    $out += [ordered]@{state="$($message.State)";path=$path;description="$($message.Description)"}
    if($message.Messages){$out += FlattenMessages $message.Messages $path}
  }
  return $out
}
function InvokeBridge($command, [string[]]$arguments) {
  if (-not (Test-Path -LiteralPath $script:Bridge)) { throw "C# bridge not built. Run scripts\\build-bridge.ps1 first." }
  $output = & $script:Bridge $command @arguments 2>&1 | Out-String
  $line = ($output -split "`r?`n" | Where-Object { $_ -match '^\{"ok"' } | Select-Object -Last 1)
  if (-not $line) { throw "Bridge returned no JSON: $output" }
  $payload = $line | ConvertFrom-Json
  if (-not $payload.ok) { throw [string]$payload.error }
  return [ordered]@{ action=$payload.action; result=$payload.result }
}
function CallTool($name, $arguments) {
  switch ($name) {
    'environment_doctor' {
      $plcCandidates=@('E:\simense\PLCSIM_V20\S7PLCSIMV20.exe','E:\simense\PLCSIM_V20\resources\bin\plcsim.exe',"$env:ProgramFiles\Siemens\Automation\PLCSIM V20\bin\PLCSIM.exe")
      $plcExe=$plcCandidates | Where-Object {Test-Path $_} | Select-Object -First 1
      $plcVersion=if($plcExe){(Get-Item $plcExe).VersionInfo.ProductVersion}else{''}
      return [ordered]@{ tiaApi=$script:Api; apiFound=(Test-Path $script:Api); plcsimFound=(Test-Path 'E:\simense\PLCSIM_V20'); plcsimExecutable=if($plcExe){[string]$plcExe}else{''}; plcsimVersion=$plcVersion; projectOpen=($null -ne $script:Project) }
    }
    'plcsim_status' {
      $names=@('S7PLCSIMV20','plcsim','Siemens.Simatic.PlcSim.VplcHost','Siemens.Simatic.PlcSim.VplcHost64')
      $processes=@($names | ForEach-Object { Get-Process -Name $_ -ErrorAction SilentlyContinue | ForEach-Object { [ordered]@{name=$_.ProcessName;id=$_.Id;path=if($_.Path){$_.Path}else{''}} } })
      $ports=@(8100,8101) | ForEach-Object { $c=Get-NetTCPConnection -LocalPort $_ -State Listen -ErrorAction SilentlyContinue; [ordered]@{port=$_;listening=($null -ne $c);owners=@($c | Select-Object -ExpandProperty OwningProcess -Unique)} }
      return [ordered]@{running=($processes.Count -gt 0);processes=$processes;ports=$ports}
    }
    'plcsim_launch' {
      if(-not [bool]$arguments.confirmed){throw 'PLCSIM launch requires confirmed=true.'}
      $exe='E:\simense\PLCSIM_V20\S7PLCSIMV20.exe'; if(-not (Test-Path $exe)){throw "PLCSIM executable not found: $exe"}
      $process=Start-Process -FilePath $exe -PassThru; return [ordered]@{started=$true;pid=$process.Id;path=$exe}
    }
    'project_open' {
      EnsurePortal; $path=[string]$arguments.path; if (-not (Test-Path $path)) { throw "Project not found: $path" }
      if ($script:Project) { $script:Project.Close(); $script:Project=$null }
      $script:Project=$script:Portal.Projects.Open([IO.FileInfo]::new($path)); return [ordered]@{ name=$script:Project.Name; path="$($script:Project.Path)" }
    }
    'project_info' { EnsureProject; return [ordered]@{ name=$script:Project.Name; path="$($script:Project.Path)"; deviceCount=$script:Project.Devices.Count } }
    'devices_list' { EnsureProject; return @($script:Project.Devices | ForEach-Object { [ordered]@{ name=$_.Name; type="$($_.TypeIdentifier)"; items=@($_.DeviceItems | ForEach-Object Name) } }) }
    'device_online_status' {
      $device=GetDevice ([string]$arguments.device); $provider=FindDeviceService $device ([Siemens.Engineering.Online.OnlineProvider]); if(-not $provider){throw 'Online provider unavailable for device.'}; return [ordered]@{device=$device.Name;state="$($provider.OnlineState)"}
    }
    'device_go_online' {
      if(-not [bool]$arguments.confirmed){throw 'Going online requires confirmed=true.'}
      $device=GetDevice ([string]$arguments.device); $provider=FindDeviceService $device ([Siemens.Engineering.Online.OnlineProvider]); if(-not $provider){throw 'Online provider unavailable for device.'}; $provider.GoOnline(); return [ordered]@{device=$device.Name;state="$($provider.OnlineState)"}
    }
    'device_go_offline' {
      if(-not [bool]$arguments.confirmed){throw 'Going offline requires confirmed=true.'}
      $device=GetDevice ([string]$arguments.device); $provider=FindDeviceService $device ([Siemens.Engineering.Online.OnlineProvider]); if(-not $provider){throw 'Online provider unavailable for device.'}; $provider.GoOffline(); return [ordered]@{device=$device.Name;state="$($provider.OnlineState)"}
    }
    'device_capabilities' {
      $device=GetDevice ([string]$arguments.device)
      $software=$null; $items=New-Object System.Collections.Generic.Queue[object]; foreach($root in $device.DeviceItems){$items.Enqueue($root)}
      while($items.Count -and -not $software){$item=$items.Dequeue(); foreach($child in $item.DeviceItems){$items.Enqueue($child)}; $container=GetService $item ([Siemens.Engineering.HW.Features.SoftwareContainer]); if($container){$software=$container.Software}}
      $compile=if($software){[bool](GetService $software ([Siemens.Engineering.Compiler.ICompilable]))}else{$false}
      return [ordered]@{device=$device.Name;software=if($software){$software.GetType().FullName}else{''};compile=$compile;download=[bool](FindDeviceService $device ([Siemens.Engineering.Download.DownloadProvider]));online=[bool](FindDeviceService $device ([Siemens.Engineering.Online.OnlineProvider]));plcsimDetected=(Test-Path 'E:\simense\PLCSIM_V20')}
    }
    'device_connection_targets' {
      $device=GetDevice ([string]$arguments.device); $provider=FindDeviceService $device ([Siemens.Engineering.Online.OnlineProvider]); if(-not $provider){throw 'Online provider unavailable for device.'}
      $modes=@(); foreach($mode in $provider.Configuration.Modes){$ifs=@(); foreach($iface in $mode.PcInterfaces){$ifs += [ordered]@{name="$($iface.Name)";addresses=@($iface.Addresses | ForEach-Object {[string]$_.Address});targets=@($iface.TargetInterfaces | ForEach-Object {[ordered]@{name="$($_.Name)";addresses=@($_.Addresses | ForEach-Object {[string]$_.Address})}})}}; $modes += [ordered]@{name="$($mode.Name)";pcInterfaces=$ifs}}
      $interfaceNames=@($modes | ForEach-Object {$_.pcInterfaces | ForEach-Object {$_.name}})
      $hasPlcSim=($interfaceNames -contains 'PLCSIM')
      $next=if($hasPlcSim){'Select a PLCSIM target interface and instance.'}else{'Configure the TIA online path to use the PLCSIM PC interface, then retry.'}
      return [ordered]@{device=$device.Name;configured=[bool]$provider.Configuration.IsConfigured;plcsimInterfaceFound=$hasPlcSim;modes=$modes;nextAction=$next}
    }
    'plc_list' { EnsureProject; $out=@(); foreach($d in $script:Project.Devices){ try { $sw=GetPlcSoftware $d.Name; $out += [ordered]@{device=$d.Name; softwareType=$sw.GetType().FullName} } catch {} }; return $out }
    'blocks_list' { $sw=GetPlcSoftware ([string]$arguments.device); return @($sw.BlockGroup.Blocks | ForEach-Object { [ordered]@{name=$_.Name; type=$_.GetType().Name; number="$($_.NumberOfBlock.Number)"} }) }
    'tags_list' { $sw=GetPlcSoftware ([string]$arguments.device); $out=@(); foreach($table in $sw.TagTableGroup.TagTables){ foreach($tag in $table.Tags){$out += [ordered]@{table=$table.Name; name=$tag.Name; dataType="$($tag.DataTypeName)"; address="$($tag.LogicalAddress)"}}}; return $out }
    'scl_apply' {
      if (-not [bool]$arguments.confirmed) { throw 'SCL mutation requires confirmed=true.' }
      if (-not [bool]$arguments.backupConfirmed) { throw 'Backup confirmation requires backupConfirmed=true.' }
      EnsureProject; $file=[IO.Path]::GetFullPath([string]$arguments.file); if(-not (Test-Path $file)){throw "SCL file not found: $file"}
      $backup="$($script:Project.Path).backup-$(Get-Date -Format yyyyMMdd-HHmmss)"; Copy-Item -LiteralPath $script:Project.Path -Destination $backup -Recurse -Force
      $device=$script:Project.Devices | Select-Object -First 1; $items=New-Object System.Collections.Generic.Queue[object]; foreach($root in $device.DeviceItems){$items.Enqueue($root)}; $software=$null
      while($items.Count -and -not $software){$item=$items.Dequeue(); foreach($child in $item.DeviceItems){$items.Enqueue($child)}; $container=GetService $item ([Siemens.Engineering.HW.Features.SoftwareContainer]); if($container){$software=$container.Software}}
      if(-not $software){throw 'No PLC software in project.'}
      $name=[string]$arguments.sourceName; $existing=@($software.ExternalSourceGroup.ExternalSources | Where-Object Name -eq $name); if($existing.Count -and -not [bool]$arguments.replace){throw "External source exists: $name. Set replace=true."}; foreach($old in $existing){$old.Delete()}
      $src=$software.ExternalSourceGroup.ExternalSources.CreateFromFile($name,[IO.FileInfo]::new($file)); $src.GenerateBlocksFromSource()
      $compilable=GetService $software ([Siemens.Engineering.Compiler.ICompilable]); $r=$compilable.Compile(); $messages=@($r.Messages | ForEach-Object { [ordered]@{state="$($_.State)";path="$($_.Path)";description="$($_.Description)"} })
      if([int]$r.ErrorCount -gt 0){throw "SCL compile failed with $($r.ErrorCount) error(s); backup=$backup"}
      $script:Project.Save(); return [ordered]@{imported=$name;compiled="$($r.State)";errors=$r.ErrorCount;warnings=$r.WarningCount;backup=$backup;messages=$messages}
    }
    'project_compile' {
      if (-not [bool]$arguments.confirmed) { throw 'Compile requires confirmed=true.' }
      $requestedPath=[IO.Path]::GetFullPath([string]$arguments.project).TrimEnd([char[]]'\\/')
      $openPath=if($script:Project){([IO.Path]::GetFullPath([string]$script:Project.Path)).TrimEnd([char[]]'\\/') } else { '' }
      if ($script:Project -and $openPath -eq $requestedPath) {
        $device = $script:Project.Devices | Select-Object -First 1
        $items = New-Object System.Collections.Generic.Queue[object]; foreach($root in $device.DeviceItems){$items.Enqueue($root)}
        $software=$null; while($items.Count -and -not $software){$item=$items.Dequeue(); foreach($child in $item.DeviceItems){$items.Enqueue($child)}; $container=GetService $item ([Siemens.Engineering.HW.Features.SoftwareContainer]); if($container){$software=$container.Software}}
        if(-not $software){throw 'No PLC software in project.'}
        $compilable=GetService $software ([Siemens.Engineering.Compiler.ICompilable]); if(-not $compilable){throw 'V20 compile service unavailable.'}
        $r=$compilable.Compile(); return [ordered]@{state="$($r.State)"; errors=$r.ErrorCount; warnings=$r.WarningCount; messages=@(FlattenMessages $r.Messages)}
      }
      return InvokeBridge 'compile' @([string]$arguments.project)
    }
    'project_create' {
      if (-not [bool]$arguments.confirmed) { throw 'Project creation requires confirmed=true.' }
      return InvokeBridge 'create-project' @([string]$arguments.name,([string]$arguments.cpuHint))
    }
    'block_export' {
      if (-not [bool]$arguments.confirmed) { throw 'Block export requires confirmed=true.' }
      $output=if($arguments.output){[string]$arguments.output}else{''}; return InvokeBridge 'export-block' @([string]$arguments.project,[string]$arguments.block,$output)
    }
    'project_save_backup' {
      if (-not [bool]$arguments.confirmed) { throw 'Save requires confirmed=true.' }
      EnsureProject; $source="$($script:Project.Path)"; $dest=[string]$arguments.backupPath; if ([string]::IsNullOrWhiteSpace($dest)) { $dest="$source.backup-$(Get-Date -Format yyyyMMdd-HHmmss)" }
      Copy-Item -LiteralPath $source -Destination $dest -Recurse -Force; $script:Project.Save(); return [ordered]@{ saved=$true; backup=$dest }
    }
    default { throw "Unknown tool: $name" }
  }
}
$tools=@(
  @{name='environment_doctor';description='Detect TIA Portal V20 Openness and PLCSIM';inputSchema=@{type='object';properties=@{}}},
  @{name='plcsim_status';description='Read PLCSIM process status without changing state';inputSchema=@{type='object';properties=@{}}},
  @{name='plcsim_launch';description='Launch PLCSIM V20; requires explicit confirmation';inputSchema=@{type='object';properties=@{confirmed=@{type='boolean'}};required=@('confirmed')}},
  @{name='project_open';description='Open a TIA Portal V20 .ap20 project';inputSchema=@{type='object';properties=@{path=@{type='string'}};required=@('path')}},
  @{name='project_info';description='Read the current project summary';inputSchema=@{type='object';properties=@{}}},
  @{name='devices_list';description='List devices and device items';inputSchema=@{type='object';properties=@{}}},
  @{name='device_online_status';description='Read the online state of a device without changing it';inputSchema=@{type='object';properties=@{device=@{type='string'}};required=@('device')}},
  @{name='device_go_online';description='Connect a device online; requires explicit confirmation';inputSchema=@{type='object';properties=@{device=@{type='string'};confirmed=@{type='boolean'}};required=@('device','confirmed')}},
  @{name='device_go_offline';description='Disconnect a device; requires explicit confirmation';inputSchema=@{type='object';properties=@{device=@{type='string'};confirmed=@{type='boolean'}};required=@('device','confirmed')}},
  @{name='device_capabilities';description='Probe compile, download, online and PLCSIM capability without changing state';inputSchema=@{type='object';properties=@{device=@{type='string'}};required=@('device')}},
  @{name='device_connection_targets';description='Read configured online interfaces and target slots without changing state';inputSchema=@{type='object';properties=@{device=@{type='string'}};required=@('device')}},
  @{name='plc_list';description='Find PLC software objects';inputSchema=@{type='object';properties=@{}}},
  @{name='blocks_list';description='List PLC blocks';inputSchema=@{type='object';properties=@{device=@{type='string'}};required=@('device')}},
  @{name='tags_list';description='List PLC tag tables and tags';inputSchema=@{type='object';properties=@{device=@{type='string'}};required=@('device')}},
  @{name='scl_apply';description='Import an SCL external source and generate blocks; requires backup and confirmation';inputSchema=@{type='object';properties=@{project=@{type='string'};sourceName=@{type='string'};file=@{type='string'};replace=@{type='boolean'};confirmed=@{type='boolean'};backupConfirmed=@{type='boolean'}};required=@('project','sourceName','file','confirmed','backupConfirmed')}},
  @{name='project_compile';description='Compile a project and return diagnostics; requires confirmation';inputSchema=@{type='object';properties=@{project=@{type='string'};confirmed=@{type='boolean'}};required=@('project','confirmed')}},
  @{name='project_create';description='Create a new V20 project using the hardware catalog; never overwrites; requires confirmation';inputSchema=@{type='object';properties=@{name=@{type='string'};cpuHint=@{type='string';default='1214C'};confirmed=@{type='boolean'}};required=@('name','confirmed')}},
  @{name='block_export';description='Export a PLC block as XML; requires confirmation';inputSchema=@{type='object';properties=@{project=@{type='string'};block=@{type='string'};output=@{type='string'};confirmed=@{type='boolean'}};required=@('project','block','confirmed')}},
  @{name='project_save_backup';description='Backup and save the current project; requires confirmation';inputSchema=@{type='object';properties=@{backupPath=@{type='string'};confirmed=@{type='boolean'}};required=@('confirmed')}}
)
try {
  while ($line=[Console]::In.ReadLine()) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try { $req=$line | ConvertFrom-Json; $id=$req.id
      if ($req.method -eq 'initialize') { Write-Output (Result $id ([ordered]@{protocolVersion='2024-11-05';capabilities=@{tools=@{}};serverInfo=@{name='tia-v20-agent';version='0.1.0'}})); continue }
      if ($req.method -eq 'notifications/initialized') { continue }
      if ($req.method -eq 'tools/list') { Write-Output (Result $id ([ordered]@{tools=$tools})); continue }
      if ($req.method -eq 'tools/call') { Write-Output (Result $id (CallTool ([string]$req.params.name) $req.params.arguments)); continue }
      Write-Output (ErrorResult $id "Unsupported method: $($req.method)")
    } catch { Write-Output (ErrorResult $id (ExceptionText $_.Exception)) }
    [Console]::Out.Flush()
  }
} finally { if($script:Project){$script:Project.Close()}; if($script:Portal){$script:Portal.Dispose()} }
