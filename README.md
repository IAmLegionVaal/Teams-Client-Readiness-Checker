# Teams Client Readiness Checker

PowerShell tools for Microsoft Teams device and connectivity readiness plus guarded local client repair.

## Check readiness

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Teams_Client_Readiness_Checker.ps1
```

## Repair

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Teams_Client_Readiness_Repair_Toolkit.ps1 -ClearTeamsCache -DryRun
```

Examples:

```powershell
.\Teams_Client_Readiness_Repair_Toolkit.ps1 -ClearTeamsCache -RestartTeams
.\Teams_Client_Readiness_Repair_Toolkit.ps1 -ResetTeamsPackage
.\Teams_Client_Readiness_Repair_Toolkit.ps1 -RestartAudioServices
.\Teams_Client_Readiness_Repair_Toolkit.ps1 -FlushDns
```

The repair workflow captures Teams, package, audio, camera and endpoint state before and after changes. It supports `-DryRun`, confirmation, logs and clear exit codes. Cache or package reset may require the user to sign in again.

## Author

Dewald Pretorius — L2 IT Support Engineer
