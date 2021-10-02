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

function AutoLogin([string]$User,[string]$Pass) {
    $AutoLoginPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty $AutoLoginPath 'AutoAdminLogon' -Value "1" -Type String
    Set-ItemProperty $AutoLoginPath 'DefaultUsername' -Value "$User" -Type String
    Set-ItemProperty $AutoLoginPath 'DefaultPassword' -Value "$Pass" -Type String
    Write-Host "Auto-login has been enabled." -ForegroundColor Green
}

$JSON = ConvertFrom-Json (Get-Content "C:\ProgramData\Amazon\EC2-Windows\Launch\Config\LaunchConfig.json" -raw)
$JSON.adminPasswordType = "DoNothing"
$JSON | ConvertTo-Json | Set-Content "C:\ProgramData\Amazon\EC2-Windows\Launch\Config\LaunchConfig.json"

Disable-CAD
AutoLogin "$AdminUser" "$AdminPassword"

Remove-Item "C:\imageconfig.json" -Force