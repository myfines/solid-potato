$ErrorActionPreference='SilentlyContinue'
$root=Split-Path -Parent $PSScriptRoot
$apiCandidates=@('E:\simense\Portal V20\PublicAPI\V20\Siemens.Engineering.dll',"$env:ProgramFiles\Siemens\Automation\Portal V20\PublicAPI\V20\Siemens.Engineering.dll","$env:ProgramFiles(x86)\Siemens\Automation\Portal V20\PublicAPI\V20\Siemens.Engineering.dll")
$api=$apiCandidates | Where-Object {Test-Path $_} | Select-Object -First 1
$node=Get-Command node.exe
$portableNode=Test-Path (Join-Path $root 'runtime\node.exe')
$group=Get-LocalGroup -Name 'Siemens TIA Openness' -ErrorAction SilentlyContinue
$member=$false
if($group){$member=@(Get-LocalGroupMember -Group $group.Name -ErrorAction SilentlyContinue | ForEach-Object Name) -contains "$env:USERDOMAIN\$env:USERNAME"}
$bridge=Test-Path (Join-Path $root 'bin\tia-agent-bridge.exe')
$unified=(Test-Path (Join-Path $root 'vendor\chewcw-tia-mcp\TiaPortalMcpServer\bin\Release\net48\TiaPortalMcpServer.exe')) -or (Test-Path (Join-Path $root 'runtime\TiaPortalMcpServer.exe')) -or (Test-Path (Join-Path $root 'runtime\TiaV20UnifiedMcpServer.exe'))
$chatPackage=Test-Path (Join-Path $root 'chat\package.json')
$chatSdk=Test-Path (Join-Path $root 'chat\node_modules\@modelcontextprotocol\sdk')
$plcsim=Test-Path 'E:\simense\PLCSIM_V20\S7PLCSIMV20.exe'
$netRelease=(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release -ErrorAction SilentlyContinue).Release
$net48=([int]$netRelease -ge 528040)
$tiaProcesses=@(Get-Process -Name 'Siemens.Automation.Portal' -ErrorAction SilentlyContinue)
$tiaRunning=($tiaProcesses.Count -gt 0)
$missing=@(); if(-not ($node -or $portableNode)){$missing+='Node.js 18+ or portable runtime'}; if(-not $net48){$missing+='.NET Framework 4.8'}; if(-not $api){$missing+='TIA Portal V20 Openness'}; if(-not $group){$missing+='Siemens TIA Openness Windows group'}; if($group -and -not $member){$missing+='Current user membership in Siemens TIA Openness'}; if(-not $unified){$missing+='TiaPortalMcpServer.exe'}; if(-not $chatPackage -or -not $chatSdk){$missing+='DeepSeek chat client dependencies'}
$next=@(); if(-not $api){$next+='Install TIA Portal V20 and ensure the V20 Openness API is available.'}; if(-not $group){$next+='Enable/install the Siemens TIA Openness Windows group with the TIA Openness component.'}; elseif(-not $member){$next+='Add the current Windows user to Siemens TIA Openness, then sign in again.'}; if(-not $plcsim){$next+='PLCSIM is optional; simulation tools will be disabled.'}
if($tiaRunning){$next+='TIA Portal is currently running; close all TIA Portal windows before opening a project through Openness to avoid project locks.'}
[ordered]@{ready=[bool](($node -or $portableNode) -and $net48 -and $api -and $group -and $member -and $unified -and $chatPackage -and $chatSdk);simulationReady=[bool]$plcsim;missing=$missing;nextActions=$next;tiaPortalRunning=$tiaRunning;tiaPortalProcessCount=$tiaProcesses.Count;windowsVersion=(Get-CimInstance Win32_OperatingSystem).Version;dotNetFramework48=$net48;dotNetRelease=$netRelease;node=if($node){$node.Source}elseif($portableNode){'runtime\node.exe'}else{''};portableNode=$portableNode;tiaApi=if($api){$api}else{''};opennessGroup=if($group){$group.Name}else{''};opennessMember=$member;plcsim=$plcsim;legacyBridge=$bridge;unifiedMcp=$unified;chatPackage=$chatPackage;chatSdk=$chatSdk} | ConvertTo-Json -Depth 4
