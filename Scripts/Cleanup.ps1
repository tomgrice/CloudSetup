Remove-Item "$InstallDir\Drivers" -Recurse -Force
Get-ChildItem "$InstallDir" -Recurse -Force -Include *.zip | Remove-Item -Force
Get-ChildItem "$InstallDir" -Recurse -Force -Include *.exe | Remove-Item -Force
Get-ChildItem "$InstallDir" -Recurse -Force -Include *.msi | Remove-Item -Force
Get-ChildItem "$InstallDir" -Recurse -Force -Include *.cab | Remove-Item -Force