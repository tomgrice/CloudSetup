foreach ($AppName in $ScriptConfig.ChocoInstall)
{
    Start-Process choco -ArgumentList "install", $AppName, "-y" -NoNewWindow -Wait
}

"https://d1uj6qtbmh3dt5.cloudfront.net/" | Set-Variable BucketURL -Scope Private ; Set-Variable DCVUrl -Value ("$BucketURL" + ((Invoke-RestMethod "$BucketURL").ListBucketResult.Contents | Where-Object {$_.Key -like "*/Servers/*.msi"} | Sort-Object {$_.LastModified} -Descending | Select-Object -First 1).Key)
Write-Host "Installing NICE-DCV from $DCVUrl"
Invoke-RestMethod $DCVUrl -OutFile "$InstallDir\NiceDCV.msi"

Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList "/i $InstallDir\NiceDCV.msi ADDLOCAL=ALL AUTOMATIC_SESSION_OWNER=Administrator /quiet /norestart" -Wait
New-Item -Path "Microsoft.PowerShell.Core\Registry::\HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\" -Name security -Force | Set-ItemProperty -Name os-auto-lock -Value 0