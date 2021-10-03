$ErrorActionPreference = 'SilentlyContinue'

$user_data = Invoke-RestMethod -Uri 'http://169.254.169.254/latest/user-data'

if ($user_data.DebugMode) {
    Start-Transcript 
}

$license = (Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" | where { $_.PartialProductKey } | select LicenseStatus).LicenseStatus

if($license -ne "1")
{
  Write-Host "Applying AWS Windows Licencing fix."
  Import-Module "$ENV:ProgramData\Amazon\EC2-Windows\Launch\Module\Ec2Launch.psd1"
  Add-Routes | Out-Null
  Set-ActivationSettings
  slmgr //B /ato
}

Write-Host "Checking for user change requests."


if($null -ne $user_data.TimeUpdated)
{
    if($user_data.TimeUpdated -gt ((Get-ItemProperty -Path "HKLM:\System\Setup" -Name TimeUpdated).TimeUpdated))
    {
        Set-ItemProperty -Path "HKLM:\System\Setup" "TimeUpdated" -Value $user_data.TimeUpdated

        # 1st line: administrator password
        if ($null -ne $user_data.AdminPassword)
        {            
            . C:\ProgramData\Amazon\EC2-Windows\Launch\Module\Scripts\Invoke-NetUser.ps1
            $AdminUser = "Administrator"
            Invoke-NetUser -UserName $AdminUser -Password $user_data.AdminPassword -Flags @("/ACTIVE:YES", "/LOGONPASSWORDCHG:NO", "/EXPIRES:NEVER", "/PASSWORDREQ:NO")
            $RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
            Set-ItemProperty $RegistryPath 'DefaultPassword' -Value $user_data.AdminPassword -type String
        }

        # 2nd line: computer name
        if ($null -ne $user_data.ComputerName)
        {
            Rename-Computer -NewName $user_data.ComputerName

            # Restart due to ComputerName change
            Start-Sleep -Seconds 5 ; Restart-Computer -Force
        }

    }
}


Write-Host "Setting resolution to hostname preferences"

$Hostname = $ENV:ComputerName.ToLower()
$SecretKey = $user_data.IonoSecret
$SecurityKey = ([System.BitConverter]::ToString((new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider).ComputeHash((new-object -TypeName System.Text.UTF8Encoding).GetBytes($Hostname+"dk34Jd02m"))) -replace '-', '').ToLower()
$DDNSQuery = Invoke-WebRequest -Uri "https://ionobeam.xyz/ddns-api.php?name=$Hostname&key=$SecurityKey&secret=$SecretKey" -UseBasicParsing
$DDNSResult = $DDNSQuery.Content

if($DDNSQuery.StatusCode -eq "200")
{
    if(($DDNSResult -eq "Invalid key") -Or ($DDNSResult -eq "Invalid secret"))
    {
        Write-Host $DDNSResult
        [Environment]::SetEnvironmentVariable("ServerAddress", "UNKNOWN")
        [Environment]::SetEnvironmentVariable("ServerIP", "UNKNOWN")
    }
    else
    {
        Write-Host "Dynamic DNS set successfully."
        $DDNSResponse = $DDNSResult -split ":"
        [Environment]::SetEnvironmentVariable("ServerAddress", $DDNSResponse[0])
        [Environment]::SetEnvironmentVariable("ServerIP", $DDNSResponse[1])
    }
    Start-Process -FilePath "bginfo" -ArgumentList "C:\DesktopInfo.bgi /timer:0 /accepteula /silent" -NoNewWindow -Wait
    if (-Not (Test-Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System)) {
        New-Item -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System
    }
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name WallpaperStyle -Value 6
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name TileWallpaper -Value 0
    Stop-Process -ProcessName explorer
}

if ($user_data.DebugMode) {
    Stop-Transcript 
}