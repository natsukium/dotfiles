Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
choco install Microsoft-Windows-Subsystem-Linux -source windowsfeatures
Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile ~/Ubuntu.appx -UseBasicParsing
Add-AppxPackage -Path ~/Ubuntu.appx

RefreshEnv
Ubuntu1804 install --root
Ubuntu1804 run apt update
Ubuntu1804 run apt upgrade -y

dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

wsl --set-version Ubuntu18.04 2
wsl --set-default-version 2