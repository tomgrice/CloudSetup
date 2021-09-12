$ErrorActionPreference = 'SilentlyContinue'
$InstallDir = "C:\CloudSetup"
$user_data = Invoke-RestMethod -Uri 'http://169.254.169.254/latest/user-data'

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

Function DlFile([string]$Url, [string]$Path, [string]$Name) {
    try {
        if(![System.IO.File]::Exists($Path)) {
	        Write-Host "Downloading `"$Name`"..."
	        Start-BitsTransfer $Url $Path
        }
    } catch {
        throw "`"$Name`" download failed."
    }
}

Import-Module BitsTransfer

& $InstallDir\Scripts\Convert.ps1
& $InstallDir\Scripts\InstallDrivers.ps1
& $InstallDir\Scripts\InstallApps.ps1
& $InstallDir\Scripts\Tweaks.ps1
& $InstallDir\Scripts\Cleanup.ps1

Unregister-ScheduledTask -TaskName SetupTask -Confirm:$false

if ($user_data.DebugMode) {
    Stop-Transcript 
}

Start-Sleep -Seconds 5 ; Restart-Computer -Force