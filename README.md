# ANDoc PowerShell Module
## Overview
The `ANDoc` PowerShell module helps generate documentation for projects using tools like ALDoc and DocFX. This module ensures that all necessary dependencies are installed and configured, and provides a streamlined way to add applications to the configuration, generate documentation, and manage local test environments.

**Note:** This solution is far from being optimal for generating documentation. Ideally, this should be handled in the CI cycle after generating the package, not as this module suggests, which is running locally compiled. For personal projects or small projects where only one person is involved, this might be a solution. The initial purpose of this module was to cover the need to start documenting my personal projects better, as an excuse to study, practice with PowerShell, and become more familiar with ALDocs.

I share this small module in case it might be useful to someone else.<br> <br> 
**Usage video(ENU AI generated):** <br> 
replacename

**Usage video(ESP):** <br> 
replacename<br>

## Features
### Configuration Management
-   **Add Application to Configuration:** Allows users to add a new application path to the `aldoc.yml` configuration file. This enables the documentation generation process to include the specified applications.
-   **Remove Application from Configuration:** Provides an option to remove an existing application from the `aldoc.yml` configuration file, ensuring that only relevant applications are documented.
-   **View List of Added Applications:** Displays a list of all applications currently included in the `aldoc.yml` configuration file, allowing users to easily manage their documentation scope.

### Documentation Generation
Builds and generates documentation for the specified application paths using ALDoc and DocFX. This feature ensures that the documentation is up-to-date and accurately reflects the current state of the applications.

### Local Test Environment
Sets up a local test environment to serve the generated documentation using DocFX. This allows users to preview the documentation locally before deploying it to a production environment.

## Prerequisites
-   .NET SDK 6.0 or higher
-   DocFX 2.70

## Installation
For now, a manual installation is required. In the future, I will create a script to automate this process (wink wink).

1.  **Clone the Repository Locally:**
    
    Clone the repository to your local machine.
    
2.  **Copy the Module:**
    Copy the `ANDoc.psm1` file to the following directory:
    makefile
    Copiar código
    `C:\Program Files\WindowsPowerShell\Modules\ANDoc` 
    Ensure that the `ANDoc` folder exists within `Modules`. If not, create it.
    
3.  **Restart PowerShell:**
    If you have PowerShell open, close and reopen it to ensure the new module is loaded.
    
4.  **Verify Installation:**
    Open PowerShell with administrative privileges and run:
    powershell
    Copiar código
    `Get-Module -ListAvailable ANDoc` 
    You should see `ANDoc` listed in the available modules.
    

## Usage
1.  **Open PowerShell as Administrator:**
    
    Right-click on the PowerShell icon and select "Run as administrator".
    
2.  **Run the Module:**
    
    powershell
    
    Copiar código
    
    `ANDoc` 
    
3.  **Follow the Menu:**
    
    The main menu provides options to view, add, remove applications, generate documentation, and set up a local test environment.