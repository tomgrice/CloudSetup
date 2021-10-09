$ErrorActionPreference = 'SilentlyContinue'

$user_data = Invoke-RestMethod -Uri 'http://169.254.169.254/latest/user-data'

if ($user_data.DebugMode) {
    Start-Transcript 
}

$license = (Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" | Where-Object { $_.PartialProductKey } | Select-Object LicenseStatus).LicenseStatus

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

$DNSHost = $user_data.DNSHost
$DNSToken = $user_data.DNSToken

if($null -ne $DNSToken)
{
    $DNSQuery = Invoke-RestMethod "https://dyndns.ionobeam.xyz/update/$DNSHost/$DNSToken" -SkipHttpErrorCheck -StatusCodeVariable DNSStatusCode

    if($DNSStatusCode -eq 200)
    {
        [Environment]::SetEnvironmentVariable("ServerAddress", $DNSQuery.fqdn)
        [Environment]::SetEnvironmentVariable("ServerIP", $DNSQuery.current_ip)
        Write-Host $DNSQuery.status
    } else {
        Write-Host $DNSQuery.error
        [Environment]::SetEnvironmentVariable("ServerAddress", "UNKNOWN")
        [Environment]::SetEnvironmentVariable("ServerIP", "UNKNOWN")
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