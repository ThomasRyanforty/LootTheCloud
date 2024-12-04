# PowerShell script to install tools, handle Windows Defender exclusions, and retry if necessary.

# Function to add Windows Defender exclusions
function Add-WindowsDefenderExclusions {
    Write-Host "Adding Windows Defender exclusions for MFASweep..."

    # Ensure the tools directory exists
    $toolsDir = "$env:USERPROFILE\Desktop\tools"
    if (!(Test-Path $toolsDir)) {
        New-Item -ItemType Directory -Path $toolsDir -Force
    }

    # Add exclusion for the MFASweep.ps1 file
    $mfSweepPath = "$toolsDir\MFASweep\MFASweep.ps1"
    $exclusionAdded = $false

    if (!(Get-MpPreference).ExclusionPath -contains $mfSweepPath) {
        Write-Host "Excluding: $mfSweepPath"
        Add-MpPreference -ExclusionPath $mfSweepPath
        $exclusionAdded = $true
    } else {
        Write-Host "MFASweep.ps1 is already excluded in Windows Defender."
    }

    Write-Host "Windows Defender exclusions added."

    # Restore the file from quarantine if it was quarantined
    Restore-QuarantinedFile -FilePath $mfSweepPath
}

# Function to restore a quarantined file
function Restore-QuarantinedFile {
    param (
        [string]$FilePath
    )

    Write-Host "Attempting to restore quarantined file: $FilePath"

    # Get the list of quarantined items
    $quarantinedItems = Get-MpThreatDetection

    foreach ($item in $quarantinedItems) {
        if ($item.Resources -contains $FilePath) {
            Write-Host "Restoring quarantined file: $FilePath"
            Start-MpScan -ScanType CustomScan -ScanPath $FilePath -Restore -Force
            Write-Host "File restored from quarantine."
            return
        }
    }

    Write-Host "File not found in quarantine."
}

# Function to re-run the script
function ReRun-Script {
    Write-Host "Re-running the script to ensure all components are installed..."
    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`"" -Wait -Verb RunAs
    Exit
}

# Function to check if a previous run was interrupted by Windows Defender
function Check-DefenderInterrupt {
    Write-Host "Checking for Windows Defender interruptions..."
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Windows Defender may have interrupted the script. Adding exclusions and re-running..."
        Add-WindowsDefenderExclusions
        ReRun-Script
    }
}

# Function to refresh environment variables in the current session
function Refresh-EnvironmentVariables {
    Write-Host "Refreshing environment variables..."
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine) + ';' +
                [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
}

# Main Installation Script
$ErrorActionPreference = "Stop"

# Ensure the NuGet provider is installed
Write-Host "Installing NuGet provider..."
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# Step 1: Install Microsoft Graph PowerShell SDK
if (!(Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Installing Microsoft Graph PowerShell SDK..."
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -ErrorAction Stop
} else {
    Write-Host "Microsoft Graph PowerShell SDK is already installed."
}

# Step 2: Install Azure CLI
Write-Host "Checking for Azure CLI installation..."
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Azure CLI is not installed. Installing now..."
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
    Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
    Remove-Item .\AzureCLI.msi -Force
} else {
    Write-Host "Azure CLI is already installed."
}

# Step 3: Install WinGet
Write-Host "Checking for WinGet installation..."
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "WinGet is not installed. Downloading and installing now..."

    # Download the WinGet installer directly from GitHub
    $wingetInstallerUrl = "https://github.com/microsoft/winget-cli/releases/download/v1.9.25200/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    $wingetInstallerPath = "$env:TEMP\WinGet.msixbundle"
    Invoke-WebRequest -Uri $wingetInstallerUrl -OutFile $wingetInstallerPath -UseBasicParsing

    # Install WinGet
    Add-AppxPackage -Path $wingetInstallerPath

    # Clean up installer file
    Remove-Item $wingetInstallerPath -Force

    Write-Host "WinGet installation complete."
} else {
    Write-Host "WinGet is already installed."
}

# Step 4: Install Git
Write-Host "Checking for Git installation..."
if (!(Get-Command git.exe -ErrorAction SilentlyContinue)) {
    Write-Host "Git is not installed. Installing Git..."
    $ProgressPreference = 'SilentlyContinue'

    # Update winget sources
    winget source update

    # Use winget to install Git if available, otherwise fall back to direct download
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements --silent
    } else {
        Write-Host "winget is still unavailable. Installing Git using direct download..."
        $GitInstaller = "$env:USERPROFILE\Downloads\GitInstaller.exe"
        Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/latest/download/Git-64-bit.exe" -OutFile $GitInstaller

        # Install Git silently
        Start-Process -FilePath $GitInstaller -ArgumentList "/VERYSILENT" -Wait

        # Remove the installer file after installation
        Remove-Item -Path $GitInstaller -Force
    }

    # Refresh environment variables
    Refresh-EnvironmentVariables

    # Verify Git installation
    if (Get-Command git.exe -ErrorAction SilentlyContinue) {
        Write-Host "Git was installed successfully."
    } else {
        Write-Host "Git installation failed. Please check your system and try again."
        Exit 1
    }
} else {
    Write-Host "Git is already installed."
}

# Step 5: Add Windows Defender exclusions before cloning repositories
Add-WindowsDefenderExclusions

# Step 6: Set up tools directory
Write-Host "Setting up tools directory..."
$toolsDir = "$env:USERPROFILE\Desktop\tools"
mkdir $toolsDir -Force
cd $toolsDir

# Step 7: Clone and Set Up MFA Sweep
if (!(Test-Path .\MFASweep)) {
    Write-Host "Cloning MFA Sweep..."
    git clone https://github.com/dafthack/MFASweep.git
    Check-DefenderInterrupt
} else {
    Write-Host "MFASweep already exists. Skipping clone..."
}
cd .\MFASweep\
Import-Module .\MFASweep.ps1
Check-DefenderInterrupt

# Step 8: Clone and Set Up GraphRunner
cd $toolsDir
if (!(Test-Path .\GraphRunner)) {
    Write-Host "Cloning GraphRunner..."
    git clone https://github.com/dafthack/GraphRunner.git
    Check-DefenderInterrupt
} else {
    Write-Host "GraphRunner already exists. Skipping clone..."
}
cd .\GraphRunner\
Import-Module .\GraphRunner.ps1
Check-DefenderInterrupt

# Step 9: Install Az PowerShell Module
Write-Host "Checking for Az PowerShell Module..."
$AzModule = Get-Module -ListAvailable -Name Az | Select-Object -First 1

if ($AzModule) {
    Write-Host "Az PowerShell Module is already installed. Version: $($AzModule.Version)"
} else {
    Write-Host "Az PowerShell Module is not installed. Installing now..."
    Install-Module Az -Force -ErrorAction Stop
}

# Optional: Check for a specific minimum version
$RequiredAzVersion = [Version]"10.0.0"  # Specify your required version here
if ($AzModule -and $AzModule.Version -lt $RequiredAzVersion) {
    Write-Host "Az PowerShell Module is outdated (Version: $($AzModule.Version)). Upgrading to $RequiredAzVersion..."
    Install-Module Az -Force -ErrorAction Stop
}

Write-Host "Setup Complete!"
