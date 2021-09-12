$InstallDir = "C:\CloudSetup"
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS

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

# Disable UAC
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA -Value 0 -Force

# Disable QuickEdit
Set-ItemProperty -Path "HKU:\.DEFAULT\Console" -Name QuickEdit -Value 0 -Force

Invoke-RestMethod -Uri 'https://api.github.com/repos/tomgrice/CloudSetup/zipball/main' -OutFile "C:\CloudSetup.zip"
Expand-Archive -Path "C:\CloudSetup.zip" -DestinationPath "C:\"
Move-Item -Path "C:\*CloudSetup*" -Destination $InstallDir

DlFile "https://d1uj6qtbmh3dt5.cloudfront.net/2021.2/Servers/nice-dcv-server-x64-Release-2021.2-11048.msi" "$InstallDir\NiceDCV.msi" "NICE-DCV"

Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList "/i $InstallDir\NiceDCV.msi /quiet /norestart AUTOMATIC_SESSION_OWNER=Administrator ADDLOCAL=ALL"

#Disable Password Complexity
secedit /export /cfg c:\secpol.cfg
(Get-Content C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
Remove-Item -force c:\secpol.cfg -confirm:$false



$UnattendFile = "C:\ProgramData\Amazon\EC2-Windows\Launch\Sysprep\Unattend.xml"
Set-Content $UnattendFile ((Get-Content $UnattendFile).Replace("C:\ProgramData\Amazon\EC2-Windows\Launch\Sysprep\Randomize-LocalAdminPassword.ps1 Administrator","$InstallDir\Scripts\SetAdminPassword.ps1"))

#Add first startup task

$action = @(0,1)
$action[0] = New-ScheduledTaskAction -Execute "powershell" -Argument "Set-ItemProperty -Path HKCU:\Console -Name QuickEdit -Value 0 ; (Get-ChildItem -Path HKCU:\Console -Recurse -Include *powershell* -ErrorAction SilentlyContinue | Remove-Item)" -WorkingDirectory "$InstallDir"
$action[1] = New-ScheduledTaskAction -Execute "powershell" -Argument "-File $InstallDir\Setup.ps1" -WorkingDirectory "$InstallDir"
$trigger = New-ScheduledTaskTrigger -AtLogon -RandomDelay "00:00:20"
$settings = New-ScheduledTaskSettingsSet -Priority 10
$principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "SetupTask" -Settings $settings -Principal $principal -Description "Runs inital setup task." | Out-Null



# This adds a LOT of time to the image build process but reduces the \Windows folder size.
#Start-Process DISM -ArgumentList "/online /Cleanup-Image /StartComponentCleanup /ResetBase" -NoNewWindow -Wait
#Start-Process Compact -ArgumentList "/CompactOS:Always" -NoNewWindow -Wait
