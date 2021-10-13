Get-PnpDevice -Class "Display" -Status OK | Where-Object { $_.Name -notmatch "AMD" } | Disable-PnpDevice -confirm:$false
Start-Sleep -Seconds 5
Start-Sleep -Seconds 5
Write-Host "Adding startup script." -ForegroundColor Green

Copy-Item "$InstallDir\Scripts\StartupActions.ps1" -Destination "C:\"

if (!(Get-ScheduledTask -TaskName "StartupActions" -ErrorAction SilentlyContinue)) {
    $action = New-ScheduledTaskAction -Execute "pwsh" -Argument "-File C:\StartupActions.ps1 -WindowStyle Minimized" -WorkingDirectory "C:\"
    $trigger = New-ScheduledTaskTrigger -AtLogon -RandomDelay "00:00:20"
    $settings = New-ScheduledTaskSettingsSet -Priority 1
    $principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "StartupActions" -Settings $settings -Principal $principal -Description "Runs StartupActions powershell script." | Out-Null
}

Write-Host "Set Windows appearance." -ForegroundColor Green
Start-Process "$InstallDir\Scripts\NightViolet.deskthemepack"
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarGlomLevel -Value 1
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarSmallIcons -Value 1

Write-Host "Enable Memory Compression" -ForegroundColor Green
Enable-MMAgent -MemoryCompression

Write-Host "Disable Windows Firewall."
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

Write-Host "Create desktop system info template." -ForegroundColor Green
[System.IO.File]::WriteAllBytes("C:\DesktopInfo.bgi",([convert]::FromBase64String("CwAAAEJhY2tncm91bmQABAAAAAQAAAATEx8ACQAAAFBvc2l0aW9uAAQAAAAEAAAA/AMAAAgAAABNb25pdG9yAAQAAAAEAAAAXAQAAA4AAABUYXNrYmFyQWRqdXN0AAQAAAAEAAAAAQAAAAsAAABUZXh0V2lkdGgyAAQAAAAEAAAAwHsAAAsAAABPdXRwdXRGaWxlAAEAAAASAAAAJVRlbXAlXEJHSW5mby5ibXAACQAAAERhdGFiYXNlAAEAAAABAAAAAAwAAABEYXRhYmFzZU1SVQABAAAAAgAAAAAACgAAAFdhbGxwYXBlcgABAAAAAQAAAAANAAAAV2FsbHBhcGVyUG9zAAQAAAAEAAAAAgAAAA4AAABXYWxscGFwZXJVc2VyAAQAAAAEAAAAAQAAAA0AAABNYXhDb2xvckJpdHMABAAAAAQAAAAAAAAADAAAAEVycm9yTm90aWZ5AAQAAAAEAAAAAAAAAAsAAABVc2VyU2NyZWVuAAQAAAAEAAAAAQAAAAwAAABMb2dvblNjcmVlbgAEAAAABAAAAAEAAAAPAAAAVGVybWluYWxTY3JlZW4ABAAAAAQAAAABAAAADgAAAE9wYXF1ZVRleHRCb3gABAAAAAQAAAAAAAAABAAAAFJURgABAAAAtQEAAHtccnRmMVxhbnNpXGFuc2ljcGcxMjUyXGRlZmYwXG5vdWljb21wYXRcZGVmbGFuZzEwMzN7XGZvbnR0Ymx7XGYwXGZuaWxcZmNoYXJzZXQwIEFyaWFsO319DQp7XGNvbG9ydGJsIDtccmVkMTUzXGdyZWVuMjA0XGJsdWUyNTU7XHJlZDI1NVxncmVlbjI1NVxibHVlMjU1O30NCntcKlxnZW5lcmF0b3IgUmljaGVkMjAgMTAuMC4xNzc2M31cdmlld2tpbmQ0XHVjMSANClxwYXJkXGZpLTI4ODBcbGkyODgwXHR4Mjg4MFxjZjFcYlxmczI0IElvbm9iZWFtIENsb3VkIERlc2t0b3BccGFyDQpcY2YyXGZzMjBccGFyDQoNClxwYXJkXGZpLTIzMDRcbGkyMzA0XHR4MjMwNCBTZXJ2ZXIgQWRkcmVzczpcdGFiXHByb3RlY3QgPFNlcnZlciBBZGRyZXNzPlxwcm90ZWN0MFxwYXINClNlcnZlciBJUDpcdGFiXHByb3RlY3QgPFNlcnZlciBJUD5ccHJvdGVjdDBcZnMyNFxwYXINCn0NCgAACwAAAFVzZXJGaWVsZHMAAIAAgAAAAAAPAAAAU2VydmVyIEFkZHJlc3MAAQAAAA8AAAAzU2VydmVyQWRkcmVzcwAKAAAAU2VydmVyIElQAAEAAAAKAAAAM1NlcnZlcklQAAEAAAAAAYAAgAAAAAA=")))

Write-Host "Download Automatic Shutdown script." -ForegroundColor Green
New-Item -ItemType Directory -Path "$env:ProgramData\CloudGaming"
Invoke-RestMethod "https://raw.githubusercontent.com/tomgrice/Parsec-Cloud-Preparation-Tool/master/PreInstall/CreateAutomaticShutdownScheduledTask.ps1" -OutFile "$env:Programdata\CloudGaming\CreateAutomaticShutdownScheduledTask.ps1"
Invoke-RestMethod "https://raw.githubusercontent.com/tomgrice/Parsec-Cloud-Preparation-Tool/master/PreInstall/Automatic-Shutdown.ps1" -OutFile "$env:Programdata\CloudGaming\Automatic-Shutdown.ps1"
CreateShortcut "$ENV:HomeDrive$ENV:HomePath\Desktop\Enable Automatic Shutdown.lnk" "powershell" "-ExecutionPolicy Bypass -File `"$env:Programdata\CloudGaming\CreateAutomaticShutdownScheduledTask.ps1`""

#Remove EC2 shortcuts from desktop
Remove-Item "$env:USERPROFILE\Desktop\EC2*.website"

Set-Service dcvserver -StartupType Manual