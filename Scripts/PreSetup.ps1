$InstallDir = "C:\CloudSetup"

# Disable UAC
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA -Value 0 -Force

Invoke-RestMethod -Uri 'https://api.github.com/repos/tomgrice/CloudSetup/zipball/dev' -OutFile "C:\CloudSetup.zip"
Expand-Archive -Path "C:\CloudSetup.zip" -DestinationPath "C:\"
Move-Item -Path "C:\*CloudSetup*" -Destination $InstallDir

$DCVUrl = ("https://d1uj6qtbmh3dt5.cloudfront.net/" + ((Invoke-RestMethod "https://d1uj6qtbmh3dt5.cloudfront.net").ListBucketResult.Contents | Where-Object {$_.Key -like "*/Servers/*.msi"} | Sort-Object {$_.LastModified} -Descending | Select-Object -First 1).Key)
Write-Host "Installing NICE-DCV from $DCVUrl"
Invoke-RestMethod $DCVUrl -OutFile "$InstallDir\NiceDCV.msi"

Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList "/i $InstallDir\NiceDCV.msi /quiet /norestart AUTOMATIC_SESSION_OWNER=Administrator ADDLOCAL=ALL DISABLE_SERVER_AUTOSTART=1"

#Disable Password Complexity
secedit /export /cfg c:\secpol.cfg
(Get-Content C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
Remove-Item -force c:\secpol.cfg -confirm:$false

$UnattendFile = "C:\ProgramData\Amazon\EC2-Windows\Launch\Sysprep\Unattend.xml"
Set-Content $UnattendFile ((Get-Content $UnattendFile).Replace("C:\ProgramData\Amazon\EC2-Windows\Launch\Sysprep\Randomize-LocalAdminPassword.ps1 Administrator","$InstallDir\Scripts\SetAdminPassword.ps1"))

# Install video drivers

$DriverURL = (Invoke-RestMethod "https://ec2-amd-windows-drivers.s3.amazonaws.com/?prefix=latest").ListBucketResult ; $DriverURL = "https://" + $DriverURL.Name + ".s3.amazonaws.com/" + $DriverURL.Contents.Key
Invoke-RestMethod "$DriverURL" -OutFile "$InstallDir\AMDDrivers.zip"

Expand-Archive -Path "$InstallDir\AMDDrivers.zip" -DestinationPath "$InstallDir\Drivers\AMDDrivers"
$Driverdir = Get-ChildItem "$InstallDir\Drivers\AMDDrivers\" -Directory -Filter "*Retail*"
Start-Process "pnputil" -ArgumentList "/add-driver $InstallDir\Drivers\AMDDrivers\$Driverdir\Packages\Drivers\Display\WT6A_INF\*inf /install" -NoNewWindow -Wait

#Add first startup task

$action = @(0,1)
$action[0] = New-ScheduledTaskAction -Execute "powershell" -Argument "Set-ItemProperty -Path HKCU:\Console -Name QuickEdit -Value 0 ; (Get-ChildItem -Path HKCU:\Console -Recurse -Include *powershell* -ErrorAction SilentlyContinue | Remove-Item)" -WorkingDirectory "$InstallDir"
$action[1] = New-ScheduledTaskAction -Execute "powershell" -Argument "-File $InstallDir\Setup.ps1" -WorkingDirectory "$InstallDir"
$trigger = New-ScheduledTaskTrigger -AtLogon -RandomDelay "00:00:20"
$settings = New-ScheduledTaskSettingsSet -Priority 1
$principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "SetupTask" -Settings $settings -Principal $principal -Description "Runs inital setup task." | Out-Null

# Install Chocolatey
Invoke-RestMethod -Uri 'https://community.chocolatey.org/install.ps1' | Invoke-Expression
