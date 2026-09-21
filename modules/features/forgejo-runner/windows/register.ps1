#Requires -RunAsAdministrator
<#
    Makes this guest the Forgejo Actions runner.

    Run once from the runner disc:
      powershell -ExecutionPolicy Bypass -File X:\register.ps1

    Everything it writes goes to D:, which outlives the reset of C: on every
    start.
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

$runner = (Get-Volume -FileSystemLabel WINRUN).DriveLetter + ":"

if (-not (Test-Path "D:\")) {
    throw "D: is missing, so the runner would land on C: and die with the next reset"
}

Step "Installing the startup script"
New-Item -ItemType Directory -Force -Path "D:\runner" | Out-Null
Copy-Item "$runner\bootstrap.ps1" "D:\bootstrap.ps1" -Force

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
    Copy-Item "$runner\forgejo-runner.exe" "D:\runner\forgejo-runner.exe" -Force
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
    throw "no token given and no seed disc found, so there is nothing to register with"
}

Step "Done"
