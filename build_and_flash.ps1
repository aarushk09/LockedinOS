<#
.SYNOPSIS
    LockedinOS - Windows 1-Click Build and Flash Script

.DESCRIPTION
    This script automates building the LockedinOS ISO using Windows Subsystem for Linux (WSL),
    and then downloads and launches Rufus to flash the resulting ISO to a USB flash drive.

.NOTES
    Run this script as Administrator.
#>

Param (
    [switch]$SkipBuild,
    [switch]$SkipFlash,
    [switch]$CleanBuild
)

$ErrorActionPreference = "Stop"

# Get current directory of this script
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Administrator check
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "This script should be run as Administrator for Rufus to run without prompts, and for certain build permissions."
    Write-Host "Please close this window, right-click PowerShell, select 'Run as Administrator', and run the script again."
    Read-Host "Press Enter to exit..."
    exit
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  LockedinOS Build & Flash Tool (Windows) " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 2. Check for WSL and Ubuntu
$wslCheck = wsl -l -q 2>$null
if (-not $wslCheck) {
    Write-Error "WSL (Windows Subsystem for Linux) is not installed or enabled."
    Write-Host "To install WSL, run: wsl --install" -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
    exit
}

# 3. Build ISO via WSL
if (-not $SkipBuild) {
    Write-Host "`n[1/3] Building LockedinOS via WSL Ubuntu..." -ForegroundColor Green
    
    # Convert Windows path to WSL path, accounting for volume
    # e.g., C:\path\to\repo -> /mnt/c/path/to/repo
    $Drive = $ScriptDir.Substring(0, 1).ToLower()
    $Path = $ScriptDir.Substring(2).Replace('\', '/')
    $WslPath = "/mnt/$Drive$Path"
    
    # Run the master build script inside WSL
    $CleanArg = if ($CleanBuild) { " --clean" } else { "" }
    $wslCommand = "cd '$WslPath' && apt-get update && apt-get install -y dos2unix && find . -type f -name '*.sh' -exec dos2unix {} + && bash ./build-all.sh$CleanArg"
    
    Write-Host "Executing in WSL: $wslCommand" -ForegroundColor DarkGray
    
    # Execute wsl using the default distro
    try {
        wsl --user root -e bash -c "$wslCommand"
    }
    catch {
        Write-Error "Failed to build ISO within WSL. Make sure Ubuntu is your default WSL distribution and the project files are accessible."
        exit
    }
}
else {
    Write-Host "`n[1/3] Skipping WSL Build phase (-SkipBuild provided)." -ForegroundColor DarkGray
}

$ReleaseDir = Join-Path $ScriptDir "release"
$IsoFile = Get-ChildItem -Path $ReleaseDir -Filter "LockedinOS*.iso" | Select-Object -First 1

if (-not $IsoFile) {
    Write-Error "Could not find any LockedinOS*.iso file in $ReleaseDir !"
    Write-Host "The build process may have failed." -ForegroundColor Yellow
    exit
}

$IsoPath = $IsoFile.FullName
Write-Host "Found compiled ISO at: $IsoPath" -ForegroundColor Green

# 4. Flash via Rufus
if (-not $SkipFlash) {
    Write-Host "`n[2/3] Preparing Rufus to flash ISO to USB..." -ForegroundColor Green
    $RufusUrl = "https://github.com/pbatard/rufus/releases/download/v4.4/rufus-4.4p.exe"
    $RufusPath = Join-Path $ReleaseDir "rufus.exe"

    if (-not (Test-Path $RufusPath)) {
        Write-Host "Downloading Rufus portable..."
        if (-not (Test-Path $ReleaseDir)) { New-Item -ItemType Directory -Force -Path $ReleaseDir | Out-Null }
        Invoke-WebRequest -Uri $RufusUrl -OutFile $RufusPath
    }
    else {
        Write-Host "Rufus already downloaded."
    }

    Write-Host "`n[3/3] Launching Rufus. Please select your USB drive and click START." -ForegroundColor Green
    Write-Host "/!\ WARNING: This will ERASE the USB drive completely! /!\" -ForegroundColor Red
    
    # Launch Rufus and pass the ISO parameter so it's pre-selected
    Start-Process -FilePath $RufusPath -ArgumentList "`"$IsoPath`"" -Wait
    
    Write-Host "`nFlash tool closed." -ForegroundColor Green
}
else {
    Write-Host "`n[2/3] Skipping USB Flashing phase (-SkipFlash provided)." -ForegroundColor DarkGray
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "  Done! You can now boot from the USB.    " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Read-Host "Press Enter to exit..."
