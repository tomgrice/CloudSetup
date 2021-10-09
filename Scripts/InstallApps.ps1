foreach ($AppName in $ScriptConfig.ChocoInstall)
{
    Start-Process choco -ArgumentList "install", $AppName, "-y" -NoNewWindow -Wait
}