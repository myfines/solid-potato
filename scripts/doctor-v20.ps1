$ErrorActionPreference = 'Stop'
$apiCandidates = @(
  'E:\simense\Portal V20\PublicAPI\V20\Siemens.Engineering.dll',
  "$env:ProgramFiles\Siemens\Automation\Portal V20\PublicAPI\V20\Siemens.Engineering.dll",
  "$env:ProgramFiles\Siemens\Automation\Portal V20_0\PublicAPI\V20\Siemens.Engineering.dll"
)
$api = $apiCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
Write-Output "TIA Portal V20 Agent Doctor"
Write-Output "API: $(if ($api) { $api } else { 'NOT FOUND' })"
Write-Output "PLCSIM V20: $(if (Test-Path 'E:\simense\PLCSIM_V20') { 'FOUND' } else { 'NOT FOUND' })"
$member = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$group = Get-LocalGroup -ErrorAction SilentlyContinue | Where-Object Name -Match 'TIA Openness'
Write-Output "Windows user: $member"
Write-Output "Openness group: $(if ($group) { $group.Name -join ', ' } else { 'NOT DISCOVERED' })"
if (-not $api) { exit 2 }

