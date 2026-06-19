#requires -Version 5.1
[CmdletBinding()]
param([string]$OutputPath)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Teams_Readiness_Reports'}
New-Item -ItemType Directory -Path $OutputPath -Force|Out-Null
$os=Get-CimInstance Win32_OperatingSystem;$cs=Get-CimInstance Win32_ComputerSystem
$teamsProcess=Get-Process -Name ms-teams,Teams -ErrorAction SilentlyContinue|Select-Object Name,Id,Path
$media=Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue|Where-Object{$_.PNPClass -in @('AudioEndpoint','Camera','Image')}|Select-Object Name,PNPClass,Manufacturer,Status
$targets='teams.microsoft.com','login.microsoftonline.com','statics.teams.cdn.office.net'
$connectivity=foreach($target in $targets){[PSCustomObject]@{Target=$target;Https443Reachable=(Test-NetConnection -ComputerName $target -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue)}}
$summary=[PSCustomObject]@{Computer=$env:COMPUTERNAME;OS=$os.Caption;Build=$os.BuildNumber;MemoryGB=[math]::Round($cs.TotalPhysicalMemory/1GB,2);TeamsRunning=[bool]$teamsProcess;MediaDeviceCount=@($media).Count;Generated=Get-Date}
$media|Export-Csv (Join-Path $OutputPath "media_devices_$stamp.csv") -NoTypeInformation -Encoding UTF8
$connectivity|Export-Csv (Join-Path $OutputPath "teams_connectivity_$stamp.csv") -NoTypeInformation -Encoding UTF8
@{Summary=$summary;TeamsProcess=$teamsProcess;MediaDevices=$media;Connectivity=$connectivity}|ConvertTo-Json -Depth 6|Set-Content (Join-Path $OutputPath "teams_readiness_$stamp.json") -Encoding UTF8
$html="<h1>Teams Client Readiness - $env:COMPUTERNAME</h1><p>Generated $(Get-Date)</p><h2>Summary</h2>$(@($summary)|ConvertTo-Html -Fragment)<h2>Media Devices</h2>$($media|ConvertTo-Html -Fragment)<h2>Connectivity</h2>$($connectivity|ConvertTo-Html -Fragment)"
$html|ConvertTo-Html -Title 'Teams Client Readiness'|Set-Content (Join-Path $OutputPath "teams_readiness_$stamp.html") -Encoding UTF8
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
