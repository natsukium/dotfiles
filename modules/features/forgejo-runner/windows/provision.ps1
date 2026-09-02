#Requires -RunAsAdministrator
<#
    Turns a bare Windows install into a Forgejo Actions runner.

    Everything here has to happen before the guest switches to its reset
    shape, because C: goes back to the golden image on every start. Caches and
    the runner credential go to D:, which survives.

    Run from the payload disc:
      powershell -ExecutionPolicy Bypass -File X:\provision.ps1 -RunnerToken <token>

    Re-running is safe. Each step checks for its own result first.
#>
[CmdletBinding()]
param(
    [string]$RunnerToken,
    [string]$InstanceUrl = "@instanceUrl@",
    [string]$RunnerName = "@runnerName@",
    [string]$Labels = "@labels@"
)

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

$payload = (Get-Volume -FileSystemLabel WINCI).DriveLetter + ":"

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

# The optical drives take D: and up before any disk gets a letter, and the
# assignment lives on C:, so a fresh install repeats it. Moving them clears D:
# for the state disk.
Step "Moving the optical drives to the end of the alphabet"
$letter = 90
Get-CimInstance Win32_Volume -Filter "DriveType = 5" | ForEach-Object {
    $_ | Set-CimInstance -Property @{ DriveLetter = ([char]$letter + ":") }
    $letter--
}
# The disc the script itself came from just moved with the others.
$payload = (Get-Volume -FileSystemLabel WINCI).DriveLetter + ":"

$state = Get-Volume | Where-Object FileSystemLabel -eq "state" | Select-Object -First 1
if (-not $state) {
    # Picking the disk by "not the one holding C:" rather than by RAW, because
    # a half-finished attempt leaves the disk initialized but empty, and a RAW
    # filter then matches nothing and silently skips the whole step.
    $systemDisk = (Get-Partition -DriveLetter C).DiskNumber
    $candidates = @(Get-Disk | Where-Object Number -ne $systemDisk)
    if ($candidates.Count -ne 1) {
        throw "expected exactly one non-system disk, found $($candidates.Count)"
    }
    $disk = $candidates[0]

    Step "Initializing disk $($disk.Number) as D:"
    if ($disk.PartitionStyle -eq "RAW") {
        Initialize-Disk -Number $disk.Number -PartitionStyle GPT | Out-Null
    }
    Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue |
        Where-Object Type -ne "Reserved" |
        Remove-Partition -Confirm:$false
    New-Partition -DiskNumber $disk.Number -DriveLetter D -UseMaximumSize |
        Format-Volume -FileSystem NTFS -NewFileSystemLabel state -Confirm:$false |
        Out-Null
}
elseif ($state.DriveLetter -ne "D") {
    # A reinstalled C: has never seen this disk, so it comes back on whatever
    # letter was free instead of the one the caches were built under.
    Step "Putting the state disk back on D:"
    Set-Partition -DriveLetter $state.DriveLetter -NewDriveLetter D
}

if (-not (Test-Path "D:\")) {
    throw "D: is missing, so the caches would land on C: and die with the next reset"
}

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
# A reset throws away whatever Windows Update installed, so the download is
# wasted either way. The reboot it takes mid-job is a failed job.
$policy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
New-Item -Path $policy -Force | Out-Null
Set-ItemProperty -Path $policy -Name "NoAutoUpdate" -Value 1 -Type DWord

Invoke-Native powercfg @("/change", "standby-timeout-ac", "0")
Invoke-Native powercfg @("/change", "hibernate-timeout-ac", "0")
Invoke-Native powercfg @("/change", "monitor-timeout-ac", "0")

# D: outlives resets, so the startup task copies the runner off the disc on
# every boot to keep the flake's version the one that runs.
New-Item -ItemType Directory -Force -Path "D:\runner" | Out-Null
Copy-Item "$payload\forgejo-runner.exe" "D:\runner\forgejo-runner.exe" -Force

Step "Installing the startup task"
New-Item -ItemType Directory -Force -Path "C:\windows-ci" | Out-Null
@'
$ErrorActionPreference = "Stop"
$payload = (Get-Volume -FileSystemLabel WINCI).DriveLetter + ":"
Copy-Item "$payload\forgejo-runner.exe" "D:\runner\forgejo-runner.exe" -Force
Set-Location "D:\runner"
& "D:\runner\forgejo-runner.exe" daemon
'@ | Set-Content -Path "C:\windows-ci\start-runner.ps1" -Encoding UTF8

Register-ScheduledTask -TaskName "forgejo-runner" -Force `
    -Action (New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\windows-ci\start-runner.ps1") `
    -Trigger (New-ScheduledTaskTrigger -AtStartup) `
    -Principal (New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest) `
    -Settings (New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)) |
    Out-Null

if (-not $RunnerToken) {
    $seed = Get-Volume -FileSystemLabel WINCISEED -ErrorAction SilentlyContinue
    if ($seed) {
        $RunnerToken = (Get-Content "$($seed.DriveLetter):\token.txt" -Raw).Trim()
    }
}

if (Test-Path "D:\runner\.runner") {
    # The token stays valid after use, so registering again does not replace
    # the runner, it adds a second one that Forgejo then lists forever.
    Step "The runner is already registered"
}
elseif ($RunnerToken) {
    # Registration writes .runner next to the working directory, so it has to
    # run from D: for the credential to survive a reset.
    Step "Registering the runner"
    Push-Location "D:\runner"
    try {
        Invoke-Native "D:\runner\forgejo-runner.exe" @("register", "--no-interactive",
            "--instance", $InstanceUrl, "--token", $RunnerToken, "--name", $RunnerName,
            "--labels", $Labels)
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host "No token given and no seed disc found, so the runner is installed but not registered." -ForegroundColor Yellow
}

Step "Done"
