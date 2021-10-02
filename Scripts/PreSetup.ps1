Set-ExecutionPolicy Bypass -Force

$InstallDir = "C:\CloudSetup"
$ScriptConfig = Get-Content -Path "C:\imageconfig.json" | ConvertFrom-Json

New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS

# This adds a LOT of time to the image build process but reduces the \Windows folder size.
Start-Process DISM -ArgumentList "/online /Cleanup-Image /StartComponentCleanup /ResetBase" -NoNewWindow -Wait
Start-Process Compact -ArgumentList "/CompactOS:Always" -NoNewWindow -Wait

# Disable UAC
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA -Value 0 -Force

# Disable QuickEdit
Set-ItemProperty -Path "HKU:\.DEFAULT\Console" -Name QuickEdit -Value 0 -Force

# Install Chocolatey
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

Invoke-RestMethod -Uri 'https://api.github.com/repos/tomgrice/CloudSetup/zipball/dev' -OutFile "C:\CloudSetup.zip"
Expand-Archive -Path "C:\CloudSetup.zip" -DestinationPath "C:\"
Move-Item -Path "C:\*CloudSetup*" -Destination $InstallDir

$DCVUrl = ("https://d1uj6qtbmh3dt5.cloudfront.net/" + ((Invoke-RestMethod "https://d1uj6qtbmh3dt5.cloudfront.net").ListBucketResult.Contents | Where-Object {$_.Key -like "*/Servers/*.msi"} | Sort-Object {$_.LastModified} -Descending | Select-Object -First 1).Key)

Invoke-RestMethod $DCVUrl -OutFile "$InstallDir\NiceDCV.msi"

Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList "/i $InstallDir\NiceDCV.msi /quiet /norestart AUTOMATIC_SESSION_OWNER=Administrator ADDLOCAL=ALL DISABLE_SERVER_AUTOSTART=1"

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
$settings = New-ScheduledTaskSettingsSet -Priority 1
$principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "SetupTask" -Settings $settings -Principal $principal -Description "Runs inital setup task." | Out-Null