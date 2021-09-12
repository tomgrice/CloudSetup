$WebContent = Invoke-WebRequest -Uri 'https://ec2-amd-windows-drivers.s3.amazonaws.com/?prefix=latest&max-keys=1' -UseBasicParsing
[xml]$xmlVideoDriverS3 = $WebContent.Content
$VideoDriverURL = "https://ec2-amd-windows-drivers.s3.amazonaws.com/" + $xmlVideoDriverS3.ListBucketResult.Contents.Key
DlFile "$VideoDriverURL" "$InstallDir\AMDDrivers.zip" "AMD Graphics Drivers"



Expand-Archive -Path "$InstallDir\AMDDrivers.zip" -DestinationPath "$InstallDir\Drivers\AMDDrivers"
$Driverdir = Get-ChildItem "$InstallDir\Drivers\AMDDrivers\" -Directory -Filter "*Retail*"
Start-Process "pnputil" -ArgumentList "/add-driver $InstallDir\Drivers\AMDDrivers\$Driverdir\Packages\Drivers\Display\WT6A_INF\*inf /install" -NoNewWindow -Wait

DlFile "http://www.download.windowsupdate.com/msdownload/update/v3-19990518/cabpool/2060_8edb3031ef495d4e4247e51dcb11bef24d2c4da7.cab" "$InstallDir\XboxDrivers.cab" "Xbox Controller Drivers"
New-Item -Path "$InstallDir\Drivers\XboxDrivers" -ItemType Directory
Start-Process Expand -ArgumentList "$InstallDir\XboxDrivers.cab -F:* $InstallDir\Drivers\XboxDrivers" -NoNewWindow -Wait
Start-Process "pnputil" -ArgumentList "/add-driver $InstallDir\Drivers\XboxDrivers\xusb21.inf /install" -NoNewWindow -Wait

DlFile "https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip" "$InstallDir/VBCABLE.zip" "VBCABLE"
Expand-Archive -Path "$InstallDir\VBCABLE.zip" -DestinationPath "$InstallDir\Drivers\VBCABLE"
(Get-AuthenticodeSignature -FilePath "$InstallDir\Drivers\VBCABLE\vbaudio_cable64_win7.cat").SignerCertificate | Export-Certificate -Type CERT -FilePath "$InstallDir\Drivers\VBCABLE\vbcable.cer"
Import-Certificate -FilePath "$InstallDir\Drivers\VBCABLE\vbcable.cer" -CertStoreLocation 'Cert:\LocalMachine\TrustedPublisher'

Start-Process "pnputil" -ArgumentList "/add-driver $InstallDir\Drivers\VBCABLE\vbMmeCable64_win7.inf /install" -NoNewWindow -Wait

DlFile "https://github.com/ViGEm/ViGEmBus/releases/download/setup-v1.17.333/ViGEmBusSetup_x64.msi" "$InstallDir/ViGEmBus.msi" "ViGEmBus"
Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList "/i $InstallDir\ViGEmBus.msi /qn" -Wait