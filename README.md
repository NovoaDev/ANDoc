# ANDoc PowerShell Module 🚀
## Overview 📄
The `ANDoc` PowerShell module helps generate documentation for projects using tools like ALDoc and DocFX. This module ensures that all necessary dependencies are installed and configured, and provides a streamlined way to add applications to the configuration, generate documentation, and manage local test environments.

**Note:** ⚠️ This solution is far from being optimal for generating documentation. Ideally, this should be handled in the CI cycle after generating the package, not as this module suggests, which is running locally compiled. For personal projects or small projects where only one person is involved, this might be a solution. The initial purpose of this module was to cover the need to start documenting my personal projects better, as an excuse to study, practice with PowerShell, and become more familiar with ALDocs.

I share this small module in case it might be useful to someone else. 😊 <br> <br> 
**Usage video(ENU AI generated):** <br> 
WIP

**Usage video(ESP):** <br> 
https://youtu.be/ut9oV-DECrY<br>

The usage of this tool involves adding extensions to the list for generating documentation, compiling updates in the related BC projects, generating updated documentation, setting up a local environment for testing, checking that everything is correct, and deploying the final version to the documentation server.<br><br>
![workflow01](/res/workflow01.png) 

## Features ✨
### Configuration Management ⚙️
-   **Add Application to Configuration:** Allows users to add a new application path to the `aldoc.yml` configuration file. This enables the documentation generation process to include the specified applications.
-   **Remove Application from Configuration:** Provides an option to remove an existing application from the `aldoc.yml` configuration file, ensuring that only relevant applications are documented.
-   **View List of Added Applications:** Displays a list of all applications currently included in the `aldoc.yml` configuration file, allowing users to easily manage their documentation scope.
<br><br>

![configurationManagement01](/res/configurationManagement01.png)<br>
![configurationManagement02](/res/configurationManagement02.png)<br>

**Note:** The first time you add an application path to the yml file, you will be prompted to specify the OutputPath. This will be the output folder where all files will be extracted. This prompt will only appear the first time you add an extension; afterwards, it will automatically work with the specified OutputPath. If you need to change it, you can do so directly in the yml file. 


![configurationManagement03](/res/configurationManagement03.png)<br>
![configurationManagement04](/res/configurationManagement04.png)

### Documentation Generation 📝
Builds and generates documentation for the specified application paths using ALDoc and DocFX. This feature ensures that the documentation is up-to-date and accurately reflects the current state of the applications.

### Local Test Environment 🖥️
Sets up a local test environment to serve the generated documentation using DocFX. This allows users to preview the documentation locally before deploying it to a production environment.

## Prerequisites 📋
-   .NET SDK 6.0 or higher
-   DocFX 2.70

## Installation 💾
For now, a manual installation is required. In the future, I will create a script to automate this process (wink wink 😉).

1.  **Clone the Repository Locally:**
    
    Clone the repository to your local machine.
    
2.  **Copy the Module:**
    Copy the `ANDoc.psm1` file to the following directory:
    ``` makefile
    C:\Program Files\WindowsPowerShell\Modules\ANDoc 
    ```
    Ensure that the `ANDoc` folder exists within `Modules`. If not, create it.
    ![installation01](/res/installation01.png)
    
3.  **Restart PowerShell:**
    If you have PowerShell open, close and reopen it to ensure the new module is loaded.
    
4.  **Verify Installation:**
    Open PowerShell with administrative privileges and run:
    ```powershell
    Get-Module -ListAvailable ANDoc 
    ```
    You should see `ANDoc` listed in the available modules.<br>
    ![installation02](/res/installation02.png)

## Usage 🎛️
1.  **Open PowerShell as Administrator:**
    
    Right-click on the PowerShell icon and select "Run as administrator".
    
2.  **Run the Module:**
    
    ```powershell
    ANDoc 
    ```

    ![usage01](/res/usage01.png)

3.  **Follow the Menu:**
    
    The main menu provides options to view, add, remove applications, generate documentation, and set up a local test environment.

## Workflow 🔄
1.  **Add Extensions Path**:
    -   If extensions are not already included in the ALDoc project, add the path to the extensions.
    -   ANDoc ensures that projects need to be added to ALDoc only once. Afterward, when documentation is generated, it will automatically refresh the project data.


    ![usage02](/res/usage02.png) <br>
    ![usage03](/res/usage03.png) <br><br>
    **Note:** We can check the extensions added to the list using option 1 in the menu.<br>
    ![usage04](/res/usage04.png)

1.  **Compile Extensions in AL**:
    -   Each time a new comment is added using the ALDoc structure, you must compile to ensure that the documentation generation process takes this change into account.
  
2.  **Generate Documentation**:
    -   Generate the documentation using the ANDoc module.
    -   This process will create/update the necessary files to generate the corresponding documentation.
    -   The output will be a static page that can be deployed on servers such as Nginx, Apache, etc.


    ![usage05](/res/usage05.png) <br><br>
    It will export the files to the output folder specified when adding the first extension to the list (OutputPath key in the yml). <br>
    ![usage06](/res/usage06.png)

3.  **Test in Local Environment**:
    -   Set up a local development environment to preview the documentation.
    -   This allows for adjustments and changes before deploying to the production server.
  

    ![usage07](/res/usage07.png) <br>
    ![usage08](/res/usage08.png)

4.  **Deploy to Production**:
    -   Copy the content from the "_site" folder within the designated output directory to your web server.