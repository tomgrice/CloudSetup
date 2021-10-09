$ErrorActionPreference = 'SilentlyContinue'
$InstallDir = "C:\CloudSetup"
$user_data = Invoke-RestMethod -Uri 'http://169.254.169.254/latest/user-data'
$ScriptConfig = Get-Content -Path "C:\imageconfig.json" | ConvertFrom-Json

if ($user_data.DebugMode) {
    Start-Transcript 
}

function CreateShortcut([string]$ShortcutLocation,[string]$ShortcutPath,[string]$ShortcutArguments)
{
    $WS = New-Object -ComObject WScript.Shell

    $SC = $WS.CreateShortcut($ShortcutLocation)
    $SC.TargetPath = $ShortcutPath
    $SC.Arguments = $ShortcutArguments
    $SC.Save()
}

& $InstallDir\Scripts\Convert.ps1
& $InstallDir\Scripts\InstallDrivers.ps1
& $InstallDir\Scripts\InstallApps.ps1
& $InstallDir\Scripts\Tweaks.ps1
& $InstallDir\Scripts\Cleanup.ps1

Remove-Item "C:\imageconfig.json" -Force

Unregister-ScheduledTask -TaskName SetupTask -Confirm:$false

if ($user_data.DebugMode) {
    Stop-Transcript 
}

Start-Sleep -Seconds 5 ; Restart-Computer -Force