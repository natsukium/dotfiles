<#
    Runs at every logon, from the copy register.ps1 left at D:\bootstrap.ps1.
#>
$ErrorActionPreference = "Stop"

$runner = (Get-Volume -FileSystemLabel WINRUN).DriveLetter + ":"
Copy-Item "$runner\forgejo-runner.exe" "D:\runner\forgejo-runner.exe" -Force

Set-Location "D:\runner"
& "D:\runner\forgejo-runner.exe" daemon
