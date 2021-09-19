# Setup
Disable-UAC
Disable-BingSearch
Disable-GameBarTips

# Enable dark mode
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0 -Type Dword -Force
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name ColorPrevalence -Value 0 -Type Dword -Force
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0 -Type Dword -Force

# Files setting
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions

# Taskbar setting
Set-TaskbarOptions -Size Small -Dock Top -Combine Full -Lock

# CapsLock -> Ctrl
Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout" `
-name "Scancode Map" -Value ([byte[]](`
0x00,0x00,0x00,0x00,`
0x00,0x00,0x00,0x00,`
0x02,0x00,0x00,0x00,`
0x1d,0x00,0x3a,0x00,`
0x00,0x00,0x00,0x00))

function excuteScript($url) {
    . { Invoke-WebRequest -useb $url } | Invoke-Expression
}
$baseUrl = "https://raw.githubusercontent.com/natsukium/dotfiles/master/win/"

# Setup WSL
wsl --install

# Remove unnecessary apps
excuteScript ($baseUrl + "del_default_apps.ps1")

# Add apps
excuteScript ($baseUrl + "add_apps.ps1")

# Tear down
Remove-Item .\Desktop\*
Enable-MicrosoftUpdate
Install-WindowsUpdate -acceptEula
Enable-UAC
