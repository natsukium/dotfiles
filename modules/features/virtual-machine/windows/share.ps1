#Requires -RunAsAdministrator
<#
    Mounts whatever the domain shares over virtiofs at S:.

    Run once from the payload disc:
      powershell -ExecutionPolicy Bypass -File X:\share.ps1

    Not part of provision.ps1, because the golden image is shared with a guest
    that has no share to reach. This guest's C: is never reset, so once is once.
#>
[CmdletBinding()]
param(
    [string]$MountPoint = "S:"
)

$ErrorActionPreference = "Stop"

function Step($message) {
    Write-Host "==> $message" -ForegroundColor Cyan
}

# The viofs driver and its service come off the virtio-win disc with the rest of
# the guest tools. WinFsp is what they mount through, and nothing installs it.
if (-not (Test-Path "${env:ProgramFiles(x86)}\WinFsp\bin")) {
    Step "Installing WinFsp"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $asset = (Invoke-RestMethod "https://api.github.com/repos/winfsp/winfsp/releases/latest").assets |
        Where-Object name -like "winfsp-*.msi" |
        Select-Object -First 1
    $installer = Join-Path $env:TEMP $asset.name
    if (-not (Test-Path $installer)) {
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installer -UseBasicParsing
    }
    Start-Process msiexec.exe -Wait -ArgumentList @("/i", $installer, "/qn", "/norestart")
}

$service = Get-Service VirtioFsSvc -ErrorAction SilentlyContinue
if (-not $service) {
    throw "the virtio-win guest tools have not installed VirtioFsSvc, so there is nothing to mount with"
}

Step "Pinning the share to $MountPoint"
# Left alone the service takes the first free letter counting down from Z, which
# is where the optical drives sit, so the share lands wherever the disc count
# leaves room. -m is the only way it takes a letter: the Parameters key the
# older builds read is gone.
$key = "HKLM:\SYSTEM\CurrentControlSet\Services\VirtioFsSvc"
$exe = ([string](Get-ItemProperty $key).ImagePath) -replace ' -m .*$', ''
if ($service.Status -eq "Running") {
    Stop-Service -Name VirtioFsSvc
}
Set-ItemProperty -Path $key -Name ImagePath -Value "$exe -m $MountPoint" -Type ExpandString

Set-Service -Name VirtioFsSvc -StartupType Automatic
Start-Service -Name VirtioFsSvc

Step "Done"
