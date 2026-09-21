<#
    Runs at every logon, from the copy the golden image carries at
    C:\windows-vm\bootstrap.ps1.

    -StateOnly stops after D: is ready, for callers that have their own idea of
    what comes next.
#>
[CmdletBinding()]
param(
    [switch]$StateOnly
)

$ErrorActionPreference = "Stop"

# The optical drives take D: and up before any disk gets a letter, so D: is not
# free until they move.
$optical = @(Get-CimInstance Win32_Volume -Filter "DriveType = 5")
# Released first, because the letters they start on overlap the ones they end
# on, and asking for a letter another drive still holds fails with
# "Not available".
$optical | ForEach-Object { $_ | Set-CimInstance -Property @{ DriveLetter = $null } }
$letter = 90
$optical | ForEach-Object {
    $_ | Set-CimInstance -Property @{ DriveLetter = ([char]$letter + ":") }
    $letter--
}

$state = Get-Volume | Where-Object FileSystemLabel -eq "state" | Select-Object -First 1
if (-not $state) {
    # Picking the disk by "not the one holding C:" rather than by RAW, because
    # a half-finished attempt leaves the disk initialized but empty, and a RAW
    # filter then matches nothing and silently skips the whole step. USB is out
    # because the answer disk is one, and it is attached whenever the image
    # itself is being worked on.
    $systemDisk = (Get-Partition -DriveLetter C).DiskNumber
    $candidates = @(Get-Disk | Where-Object { $_.Number -ne $systemDisk -and $_.BusType -ne "USB" })
    if ($candidates.Count -ne 1) {
        throw "expected exactly one non-system disk, found $($candidates.Count)"
    }
    $disk = $candidates[0]

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
    # Windows records the letter against a disk signature, and the image has
    # never seen this guest's disk, so a guest other than the one the image was
    # made on comes up with the state disk somewhere else.
    Set-Partition -DriveLetter $state.DriveLetter -NewDriveLetter D
}

if (-not (Test-Path "D:\")) {
    throw "D: is missing, so anything written there would land on C: and die with the next reset"
}

if (-not $StateOnly -and (Test-Path "D:\bootstrap.ps1")) {
    & "D:\bootstrap.ps1"
}
