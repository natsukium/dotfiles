Set-ExecutionPolicy RemoteSigned

# Install Boxstarter
. { Invoke-WebRequest -useb https://boxstarter.org/bootstrapper.ps1 } | Invoke-Expression; Get-Boxstarter -Force

# Execute install scripts
Install-BoxstarterPackage -PackageName https://raw.githubusercontent.com/natsukium/dotfiles/master/win/main.ps1 -DisableReboots
