DlFile "https://aka.ms/vs/16/release/vc_redist.x86.exe" "$InstallDir\redist_x86.exe" "Visual C++ Redist 2015-19 x86"
DlFile "https://aka.ms/vs/16/release/vc_redist.x64.exe" "$InstallDir\redist_x64.exe" "Visual C++ Redist 2015-19 x64"
DlFile "https://www.7-zip.org/a/7z1900-x64.exe" "$InstallDir\7zip.exe" "7zip"
DlFile "https://github.com/Open-Shell/Open-Shell-Menu/releases/download/v4.4.160/OpenShellSetup_4_4_160.exe" "$InstallDir\Open-Shell.exe" "Open-Shell"
DlFile "https://get.geo.opera.com/pub/opera/desktop/78.0.4093.184/win/Opera_78.0.4093.184_Setup_x64.exe" "$InstallDir\Opera.exe" "Opera Browser"
DlFile "https://netcologne.dl.sourceforge.net/project/qbittorrent/qbittorrent-win32/qbittorrent-4.3.8/qbittorrent_4.3.8_x64_setup.exe" "$InstallDir\qbittorrent.exe" "qBittorrent"
DlFile "https://github.com/loki-47-6F-64/sunshine/releases/download/v0.10.1/Sunshine-Windows.zip" "$InstallDir/Sunshine.zip" "Sunshine GameStream Server"
DlFile "https://live.sysinternals.com/Bginfo64.exe" "$ENV:windir\Bginfo64.exe" "Bginfo64 from Sysinternals"

Start-Process -FilePath "$InstallDir\redist_x86.exe" -ArgumentList "/install /q /norestart" -Wait
Start-Process -FilePath "$InstallDir\redist_x64.exe" -ArgumentList "/install /q /norestart" -Wait
Start-Process -FilePath "$InstallDir\7zip.exe" -ArgumentList "/S" -Wait
Start-Process -FilePath "$InstallDir\Open-Shell.exe" -ArgumentList "/qn ADDLOCAL=StartMenu" -Wait
Start-Process -FilePath "$InstallDir\Opera.exe" -ArgumentList "/silent /allusers=1 /launchopera=0" -Wait
Start-Process -FilePath "$InstallDir\qbittorrent.exe" -ArgumentList "/S" -Wait
Expand-Archive -Path "$InstallDir\Sunshine.zip" -DestinationPath "C:\sunshine"

. C:\sunshine\install-service.bat
CreateShortcut "$ENV:HomeDrive$ENV:HomePath\Desktop\Restart Sunshine.lnk" "powershell" "-Command `"Stop-Service sunshinesvc ; Start-Sleep 10 ; Start-Service sunshinesvc`""
CreateShortcut "$ENV:HomeDrive$ENV:HomePath\Desktop\Sunshine Control Panel.lnk" "C:\Program Files\Opera\launcher.exe" "https://127.0.0.1:47990"