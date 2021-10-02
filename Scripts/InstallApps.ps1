Invoke-RestMethod "https://github.com/loki-47-6F-64/sunshine/releases/latest/download/Sunshine-Windows.zip" -OutFile "$InstallDir/Sunshine.zip"

choco install vcredist140 -y
choco install 7zip -y
choco install open-shell -y
choco install opera -y
choco install qbittorrent -y
choco install bginfo -y
Expand-Archive -Path "$InstallDir\Sunshine.zip" -DestinationPath "C:\sunshine"

. C:\sunshine\install-service.bat
CreateShortcut "$ENV:HomeDrive$ENV:HomePath\Desktop\Restart Sunshine.lnk" "powershell" "-Command `"Stop-Service sunshinesvc ; Start-Sleep 10 ; Start-Service sunshinesvc`""
CreateShortcut "$ENV:HomeDrive$ENV:HomePath\Desktop\Sunshine Control Panel.lnk" "C:\Program Files\Opera\launcher.exe" "https://127.0.0.1:47990"