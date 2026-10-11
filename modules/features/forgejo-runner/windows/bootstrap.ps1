<#
    Runs at every logon, from the copy register.ps1 left at D:\bootstrap.ps1.
#>
$ErrorActionPreference = "Stop"

$runner = (Get-Volume -FileSystemLabel WINRUN).DriveLetter + ":"
Copy-Item "$runner\forgejo-runner.exe" "D:\runner\forgejo-runner.exe" -Force
# register.ps1 runs only once, so without this a new version of this script
# never reaches D:.
Copy-Item "$runner\bootstrap.ps1" "D:\bootstrap.ps1" -Force

Set-Location "D:\runner"
# The daemon exits when Forgejo is unreachable, as it is when logon beats the
# network, and nothing else starts it again. cmd does the redirection because
# PowerShell would turn the daemon's stderr into errors.
$ErrorActionPreference = "Continue"
while ($true) {
    cmd /c "D:\runner\forgejo-runner.exe daemon >> D:\runner\daemon.log 2>&1"
    Start-Sleep -Seconds 10
}
