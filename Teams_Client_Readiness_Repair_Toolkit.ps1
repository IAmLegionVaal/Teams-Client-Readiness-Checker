[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
 [switch]$ClearTeamsCache,
 [switch]$ResetTeamsPackage,
 [switch]$RestartAudioServices,
 [switch]$FlushDns,
 [switch]$RestartTeams,
 [switch]$DryRun,
 [switch]$Yes,
 [string]$OutputPath=(Join-Path $env:LOCALAPPDATA 'TeamsClientReadinessRepair')
)
$ErrorActionPreference='Stop';$script:Failures=0;$script:Actions=0
$run=Join-Path $OutputPath (Get-Date -Format yyyyMMdd_HHmmss);New-Item -ItemType Directory $run -Force|Out-Null
$log=Join-Path $run 'repair.log';$before=Join-Path $run 'before.json';$after=Join-Path $run 'after.json'
function Log($m){"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m"|Tee-Object -FilePath $log -Append}
function Admin{$p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent());$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
function State{[pscustomobject]@{Collected=Get-Date;Teams=Get-Process ms-teams,Teams -ErrorAction SilentlyContinue|Select-Object Id,Name,StartTime,Path;Package=Get-AppxPackage MSTeams -ErrorAction SilentlyContinue|Select-Object Name,Version,InstallLocation;Audio=Get-CimInstance Win32_SoundDevice -ErrorAction SilentlyContinue|Select-Object Name,Status;Camera=Get-PnpDevice -Class Camera -ErrorAction SilentlyContinue|Select-Object FriendlyName,Status,InstanceId;Endpoints=@('teams.microsoft.com','login.microsoftonline.com')|ForEach-Object{[pscustomobject]@{Host=$_;Https=Test-NetConnection $_ -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue}}}}
function Act($d,[scriptblock]$a){$script:Actions++;Log $d;if($DryRun){Log "DRY-RUN: $d";return};try{&$a;Log "SUCCESS: $d"}catch{$script:Failures++;Log "FAILED: $d - $($_.Exception.Message)"}}
State|ConvertTo-Json -Depth 6|Set-Content $before -Encoding UTF8
if(-not($ClearTeamsCache -or $ResetTeamsPackage -or $RestartAudioServices -or $FlushDns -or $RestartTeams)){Write-Error 'Choose at least one repair action.';exit 2}
if($RestartAudioServices -and -not $DryRun -and -not(Admin)){Write-Error 'Run from elevated PowerShell for audio service repair.';exit 4}
if(-not $Yes -and -not $DryRun){if((Read-Host 'Apply selected Teams client repairs? Teams may close. Type YES') -ne 'YES'){Log 'Cancelled.';exit 10}}
if($ClearTeamsCache -or $ResetTeamsPackage -or $RestartTeams){Act 'Closing Microsoft Teams' {Get-Process ms-teams,Teams -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction SilentlyContinue}}
if($ClearTeamsCache){foreach($p in @("$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams","$env:APPDATA\Microsoft\Teams")){Act "Clearing Teams cache at $p" {if(Test-Path $p){Get-ChildItem $p -Force -ErrorAction SilentlyContinue|Remove-Item -Recurse -Force -ErrorAction SilentlyContinue}}}}
if($ResetTeamsPackage){$pkg=Get-AppxPackage MSTeams -ErrorAction Stop;if(Get-Command Reset-AppxPackage -ErrorAction SilentlyContinue){Act 'Resetting Teams package' {$pkg|Reset-AppxPackage}}else{Act 'Re-registering Teams package' {Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $pkg.InstallLocation 'AppxManifest.xml')}}}
if($RestartAudioServices){Act 'Restarting Windows Audio services' {Restart-Service AudioEndpointBuilder -Force;Restart-Service Audiosrv -Force}}
if($FlushDns){Act 'Flushing DNS cache' {Clear-DnsClientCache}}
if($RestartTeams){Act 'Starting Microsoft Teams' {Start-Process 'ms-teams:'}}
Start-Sleep 3;State|ConvertTo-Json -Depth 6|Set-Content $after -Encoding UTF8
if($script:Failures){exit 20};Log "Repair completed. Actions: $script:Actions";exit 0
