# PowerShell script to install tools, handle Windows Defender exclusions, and retry if necessary.

# Function to add Windows Defender exclusions
function Add-WindowsDefenderExclusions {
    Write-Host "Adding Windows Defender exclusions for MFASweep..."
    $excludedFiles = @(
        "$env:USERPROFILE\Desktop\tools\MFASweep\MFASweep.ps1"
    )

    foreach ($file in $excludedFiles) {
        if (Test-Path $file) {
            Write-Host "Excluding: $file"
            Add-MpPreference -ExclusionPath $file
        } else {
            Write-Host "File not found: $file. Ensure it exists before running this script again."
        }
    }
    Write-Host "Windows Defender exclusions added."
}

# Function to re-run the script
function ReRun-Script {
    Write-Host "Re-running the script to ensure all components are installed..."
    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`"" -Wait
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

# Main Installation Script
$ErrorActionPreference = "Stop"

# Step 1: Install Az PowerShell Module
if (!(Get-Module -ListAvailable -Name Az)) {
    Write-Host "Installing Az PowerShell Module..."
    Install-Module Az -Force -ErrorAction Stop
} else {
    Write-Host "Az PowerShell Module is already installed."
}

# Step 2: Install Azure CLI
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Azure CLI..."
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
    Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
    Remove-Item .\AzureCLI.msi -Force
} else {
    Write-Host "Azure CLI is already installed."
}

# Step 3: Install Git
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Git using winget..."
    winget install --id Git.Git -e --source winget
} else {
    Write-Host "Git is already installed."
}

# Step 4: Set up tools directory
Write-Host "Setting up tools directory..."
cd $env:USERPROFILE\Desktop
mkdir tools -Force
cd .\tools\

# Step 5: Clone and Set Up MFA Sweep
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

# Step 6: Clone and Set Up GraphRunner
cd ..
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

Write-Host "Setup Complete!"
