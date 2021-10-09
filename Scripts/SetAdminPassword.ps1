. C:\ProgramData\Amazon\EC2-Windows\Launch\Module\Scripts\Invoke-NetUser.ps1

$ScriptConfig = Get-Content -Path "C:\imageconfig.json" | ConvertFrom-Json
$AdminUser = "Administrator"
$AdminPassword = $ScriptConfig.DefaultPassword
Invoke-NetUser -UserName $AdminUser -Password $AdminPassword -Flags @("/ACTIVE:YES", "/LOGONPASSWORDCHG:NO", "/EXPIRES:NEVER", "/PASSWORDREQ:NO")

function Disable-CAD {
    $DisableCADKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    Set-ItemProperty -Path $DisableCADKey -Name "DisableCAD" -Value 1
    Write-Host "Ctrl-Alt-Del to log in has been disabled." -ForegroundColor Green
}

$JSON = ConvertFrom-Json (Get-Content "C:\ProgramData\Amazon\EC2-Windows\Launch\Config\LaunchConfig.json" -raw)
$JSON.adminPasswordType = "DoNothing"
$JSON | ConvertTo-Json | Set-Content "C:\ProgramData\Amazon\EC2-Windows\Launch\Config\LaunchConfig.json"

Invoke-RestMethod "https://live.sysinternals.com/Autologon.exe" -OutFile "C:\Autologon.exe" -Wait

Disable-CAD
<# $RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty $RegistryPath 'AutoAdminLogon' -Value "1" -Type String
Set-ItemProperty $RegistryPath 'ForceAutoLogon' -Value "1" -Type String
Set-ItemProperty $RegistryPath 'DefaultUsername' -Value $AdminUser -Type String
Set-ItemProperty $RegistryPath 'DefaultPassword' -Value $AdminPassword -Type String
Set-ItemProperty $RegistryPath 'DefaultDomain' -Value '.\' -Type String #>

Start-Process "C:\Autologon.exe" -ArgumentList $AdminUser, ".\", $AdminPassword, "/accepteula" -NoNewWindow -Wait