Installs the tools & apps listed below on a Windows system using PowerShell and acounts for Windows Defender blocking .\MFASweep.ps1

1. NuGet Package Provider
Installs the NuGet provider required for managing PowerShell modules from the PowerShell Gallery.

2. Microsoft Graph PowerShell SDK
Installs the Microsoft.Graph module, providing cmdlets to interact with the Microsoft Graph API.

3. Azure CLI
Downloads and installs the Azure Command-Line Interface (AzureCLI.msi) for managing Azure resources via the command line.

4. WinGet (Windows Package Manager)
Downloads and installs the Windows Package Manager (Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle), enabling command-line installation of software.

5. Git
Installs Git for Windows, either using WinGet or by directly downloading the installer from GitHub if WinGet is not available.

6. Windows Defender Exclusions
Adds an exclusion for MFASweep.ps1 in Windows Defender to prevent it from being quarantined (configuration change, not a software installation).

7. MFASweep
Clones the MFASweep repository from GitHub to your local machine for scanning MFA configurations.
Repository URL: https://github.com/dafthack/MFASweep

8. GraphRunner
Clones the GraphRunner repository from GitHub to your local machine for running queries against Microsoft Graph.
Repository URL: https://github.com/dafthack/GraphRunner

9. Az PowerShell Module
Installs the Az module, providing PowerShell cmdlets for managing Azure resources.
