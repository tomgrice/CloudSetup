# Script to convert Windows Server 2019 into a Windows 10-like desktop
function Disable-IEESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

function Set-PriorityControl {
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38
    Write-Host "PriorityControl set to Programs." -ForegroundColor Green
}

function Set-BestAppearance {
    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
    try {
        $s = (Get-ItemProperty -ErrorAction stop -Name VisualFXSetting -Path $path).VisualFXSetting 
        if ($s -ne 1) {
            Set-ItemProperty -Path $path -Name 'VisualFXSetting' -Value 1
        }
    }
    catch {
        New-ItemProperty -Path $path -Name 'VisualFXSetting' -Value 1 -PropertyType 'DWORD'
    }
   
}

Disable-IEESC
Set-PriorityControl
Set-BestAppearance

# Audio fix
New-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "ServicesPipeTimeout" -Value 600000 -PropertyType "DWord" | Out-Null
Set-Service -Name Audiosrv -StartupType Automatic

# Disable Shutdown Tracker
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" | New-ItemProperty -Name ShutdownReasonOn -Value 0

if (-Not (Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability'))
{
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT' -Name Reliability -Force
}

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability' -Name ShutdownReasonOn -Value 0
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability' -Name ShutdownReasonUI -Value 0