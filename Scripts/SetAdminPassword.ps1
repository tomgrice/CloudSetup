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

Disable-CAD
choco install autologon -y
Start-Process AutoLogon -ArgumentList $AdminUser, $env:UserDomain, $AdminPassword -Wait

Remove-Item "C:\imageconfig.json" -Force