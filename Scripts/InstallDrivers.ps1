Invoke-RestMethod "http://www.download.windowsupdate.com/msdownload/update/v3-19990518/cabpool/2060_8edb3031ef495d4e4247e51dcb11bef24d2c4da7.cab" -OutFile "$InstallDir\XboxDrivers.cab"
New-Item -Path "$InstallDir\Drivers\XboxDrivers" -ItemType Directory
Start-Process Expand -ArgumentList "$InstallDir\XboxDrivers.cab -F:* $InstallDir\Drivers\XboxDrivers" -NoNewWindow -Wait
Start-Process "pnputil" -ArgumentList "/add-driver $InstallDir\Drivers\XboxDrivers\xusb21.inf /install" -NoNewWindow -Wait

choco install vb-cable -y

choco install vigembus -y

<#  Install video drivers
Write-Host "Downloading and installing AMD video drivers."
$DriverURL = (Invoke-RestMethod "https://ec2-amd-windows-drivers.s3.amazonaws.com/?prefix=latest").ListBucketResult ; $DriverURL = "https://" + $DriverURL.Name + ".s3.amazonaws.com/" + $DriverURL.Contents.Key
Invoke-RestMethod "$DriverURL" -OutFile "$InstallDir\AMDDrivers.zip"

Expand-Archive -Path "$InstallDir\AMDDrivers.zip" -DestinationPath "$InstallDir\Drivers\AMDDrivers"
$Driverdir = Get-ChildItem "$InstallDir\Drivers\AMDDrivers\" -Directory -Filter "*Retail*"
pnputil /?
Start-Process "pnputil" -ArgumentList "/add-driver $InstallDir\Drivers\AMDDrivers\$Driverdir\Packages\Drivers\Display\WT6A_INF\*inf /install" -NoNewWindow -Wait #>