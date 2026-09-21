#Requires -RunAsAdministrator
<#
    Turns a bare Windows install into the golden image, and a guest's blank
    second disk into D:.

    Run from the payload disc:
      powershell -ExecutionPolicy Bypass -File X:\provision.ps1

    Re-running is safe. Each step checks for its own result first, so this is
    both how the image is changed after the fact and how a new guest gets its own
    toolchain onto D:.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Step($message) {
    Write-Host "==> $message" -ForegroundColor Cyan
}

# Native tools write their progress to stderr, and with ErrorActionPreference
# set to Stop a single line there aborts the script. Redirecting stderr is not
# enough on its own: the preference has to come down for the call as well.
function Invoke-Native($exe, [string[]]$arguments) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $exe @arguments 2>&1 | ForEach-Object { Write-Host $_ }
    }
    finally {
        $ErrorActionPreference = $previous
    }
}

function Set-MachineVariable($name, $value) {
    if ([Environment]::GetEnvironmentVariable($name, "Machine") -ne $value) {
        [Environment]::SetEnvironmentVariable($name, $value, "Machine")
    }
    Set-Item -Path "Env:$name" -Value $value
}

$payload = (Get-Volume -FileSystemLabel WINVM).DriveLetter + ":"

if (-not (Get-Service -Name "QEMU-GA" -ErrorAction SilentlyContinue)) {
    Step "Installing the virtio guest tools"
    # The disc has no Joliet names, so every hyphen in a filename arrives as an
    # underscore.
    $tools = Get-Volume |
        Where-Object DriveLetter |
        ForEach-Object { Get-Item "$($_.DriveLetter):\virtio?win?gt?x64.msi" -ErrorAction SilentlyContinue } |
        Select-Object -First 1
    if (-not $tools) {
        throw "the virtio-win disc is not attached, so there is no guest agent to install"
    }
    Start-Process msiexec.exe -Wait -ArgumentList @("/i", $tools.FullName, "/qn", "/norestart")

    # The guest tools package installs the drivers but leaves the agent out.
    $agent = Get-Item (Join-Path $tools.PSDrive.Root "guest?agent\qemu?ga?x86_64.msi")
    Start-Process msiexec.exe -Wait -ArgumentList @("/i", $agent.FullName, "/qn", "/norestart")
}

# The guest tools usually carry a vdagent of their own. This stays because
# they have dropped it before, and a console you cannot paste into is miserable.
if (-not (Get-Service -Name "spice-agent", "vdservice" -ErrorAction SilentlyContinue)) {
    Step "Installing the SPICE agent so the console has a clipboard"
    Start-Process msiexec.exe -Wait -ArgumentList "/i `"$payload\spice-vdagent.msi`" /qn /norestart"
}

Step "Installing the logon task"
New-Item -ItemType Directory -Force -Path "C:\windows-vm" | Out-Null
Copy-Item "$payload\bootstrap.ps1" "C:\windows-vm\bootstrap.ps1" -Force

# At logon as the interactive user, not at startup as SYSTEM: a job that opens a
# real window and a wgpu swapchain needs a desktop, and session 0 has none, where
# wgpu fails with "Invalid surface" before the first frame. The account autologs
# on, so this fires on every boot anyway.
Register-ScheduledTask -TaskName "windows-vm-bootstrap" -Force `
    -Action (New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\windows-vm\bootstrap.ps1") `
    -Trigger (New-ScheduledTaskTrigger -AtLogOn -User "ci") `
    -Principal (New-ScheduledTaskPrincipal -UserId "ci" -LogonType Interactive -RunLevel Highest) `
    -Settings (New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)) |
    Out-Null

Step "Preparing the state disk"
# -StateOnly, because the guest's own bootstrap may never return: on the runner
# guest it is the daemon.
& "C:\windows-vm\bootstrap.ps1" -StateOnly
# The disc the script itself came from moved with the other optical drives.
$payload = (Get-Volume -FileSystemLabel WINVM).DriveLetter + ":"

Step "Pointing the toolchain caches at D:"
Set-MachineVariable "RUSTUP_HOME" "D:\rustup"
Set-MachineVariable "CARGO_HOME" "D:\cargo"
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($machinePath -notlike "*D:\cargo\bin*") {
    [Environment]::SetEnvironmentVariable("Path", "$machinePath;D:\cargo\bin", "Machine")
}
$env:Path = "$env:Path;D:\cargo\bin"

# winget is an AppX package, so it is missing or unusable depending on which
# account runs the script and whether the Store has updated App Installer.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-Installer($url, $name) {
    $path = Join-Path $env:TEMP $name
    if (-not (Test-Path $path)) {
        Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing
    }
    return $path
}

if (-not (Test-Path "C:\Program Files\Git\cmd\git.exe")) {
    Step "Installing Git for Windows"
    $asset = (Invoke-RestMethod "https://api.github.com/repos/git-for-windows/git/releases/latest").assets |
        Where-Object name -like "*-64-bit.exe" |
        Select-Object -First 1
    $installer = Get-Installer $asset.browser_download_url $asset.name
    Invoke-Native $installer @("/VERYSILENT", "/NORESTART", "/NOCANCEL", "/SP-", "/SUPPRESSMSGBOXES")
}
$env:Path = "$env:Path;C:\Program Files\Git\cmd"

# The Forgejo runner executes JS actions (actions/checkout above all) with a node
# it finds on the host PATH; without one every job dies at its first step with
# "Cannot find: node in PATH" before any tool of ours runs.
if (-not (Test-Path "C:\Program Files\nodejs\node.exe")) {
    Step "Installing Node.js"
    $lts = (Invoke-RestMethod "https://nodejs.org/dist/index.json") |
        Where-Object lts |
        Select-Object -First 1
    $installer = Get-Installer "https://nodejs.org/dist/$($lts.version)/node-$($lts.version)-x64.msi" "node-$($lts.version)-x64.msi"
    Start-Process msiexec.exe -Wait -ArgumentList @("/i", $installer, "/qn", "/norestart")
}
$env:Path = "$env:Path;C:\Program Files\nodejs"

if (-not (Test-Path "D:\cargo\bin\rustup.exe")) {
    Step "Installing rustup with the nightly toolchain"
    $installer = Get-Installer "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe" "rustup-init.exe"
    # The machine PATH already carries D:\cargo\bin, and letting rustup edit
    # the user PATH would put the entry on C:, where a reset erases it.
    Invoke-Native $installer @("-y", "--no-modify-path", "--default-toolchain", "nightly", "--profile", "default")
    if ($LASTEXITCODE -ne 0) {
        throw "rustup-init failed (exit $LASTEXITCODE)"
    }
}

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$hasVCTools = (Test-Path $vswhere) -and
    (& $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath)
if (-not $hasVCTools) {
    Step "Installing the MSVC build tools (this takes a while)"
    $installer = Get-Installer "https://aka.ms/vs/17/release/vs_BuildTools.exe" "vs_BuildTools.exe"
    Invoke-Native $installer @("--quiet", "--wait", "--norestart", "--nocache",
        "--add", "Microsoft.VisualStudio.Workload.VCTools", "--includeRecommended")
    # 3010 means it wants a reboot, which is not a failure.
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 3010) {
        throw "vs_BuildTools failed (exit $LASTEXITCODE)"
    }
}

Step "Pinning nightly as the default toolchain"
Invoke-Native "D:\cargo\bin\rustup.exe" @("default", "nightly")

if (-not (Test-Path "D:\cargo\bin\cargo-nextest.exe")) {
    # The prebuilt binary takes seconds, where `cargo install` rebuilds
    # nextest and everything under it from source.
    Step "Installing cargo-nextest"
    $archive = Join-Path $env:TEMP "cargo-nextest.zip"
    Invoke-WebRequest -Uri "https://get.nexte.st/latest/windows" -OutFile $archive
    Expand-Archive -Path $archive -DestinationPath "D:\cargo\bin" -Force
    Remove-Item $archive
}

Step "Keeping the guest awake and out of Windows Update's way"
# A reset throws away whatever Windows Update installed on a guest that resets,
# and a reboot taken mid-job is a failed job.
$policy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
New-Item -Path $policy -Force | Out-Null
Set-ItemProperty -Path $policy -Name "NoAutoUpdate" -Value 1 -Type DWord

Invoke-Native powercfg @("/change", "standby-timeout-ac", "0")
Invoke-Native powercfg @("/change", "hibernate-timeout-ac", "0")
Invoke-Native powercfg @("/change", "monitor-timeout-ac", "0")

Step "Turning the desktop effects off"
# Written into the account's own hive rather than through HKCU, because the
# script runs as SYSTEM when it is driven through the guest agent.
$sid = (Get-CimInstance Win32_UserAccount -Filter "Name='ci' AND LocalAccount=True").SID
New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
if (-not (Test-Path "HKU:\$sid")) {
    throw "ci is not logged on, so its hive is not loaded and there is nothing to write to"
}

function Set-UserValue($path, $name, $value, $type) {
    $full = "HKU:\$sid\$path"
    if (-not (Test-Path $full)) {
        New-Item -Path $full -Force | Out-Null
    }
    Set-ItemProperty -Path $full -Name $name -Value $value -Type $type
}

Set-UserValue "Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2 DWord
Set-UserValue "Control Panel\Desktop" "UserPreferencesMask" ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)) Binary
Set-UserValue "Control Panel\Desktop" "DragFullWindows" "0" String
Set-UserValue "Control Panel\Desktop" "MenuShowDelay" "0" String
Set-UserValue "Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" String
# ClearType stays on. Unreadable text costs more than the cycles it saves.
Set-UserValue "Control Panel\Desktop" "FontSmoothing" "2" String
foreach ($name in "TaskbarAnimations", "ListviewAlphaSelect", "ListviewShadow") {
    Set-UserValue "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" $name 0 DWord
}
Set-UserValue "Software\Microsoft\Windows\DWM" "EnableAeroPeek" 0 DWord
Set-UserValue "Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0 DWord

Step "Done"
