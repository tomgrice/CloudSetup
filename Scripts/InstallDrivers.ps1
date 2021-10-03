Invoke-RestMethod "http://www.download.windowsupdate.com/msdownload/update/v3-19990518/cabpool/2060_8edb3031ef495d4e4247e51dcb11bef24d2c4da7.cab" -OutFile "$InstallDir\XboxDrivers.cab"
New-Item -Path "$InstallDir\Drivers\XboxDrivers" -ItemType Directory
Start-Process Expand -ArgumentList "$InstallDir\XboxDrivers.cab -F:* $InstallDir\Drivers\XboxDrivers" -NoNewWindow -Wait
Start-Process "pnputil" -ArgumentList "/add-driver $InstallDir\Drivers\XboxDrivers\xusb21.inf /install" -NoNewWindow -Wait

choco install vb-cable -y

choco install vigembus -y
