$configFolderPath = "C:/ANDoc"

if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "powershell-yaml module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
}

Import-Module powershell-yaml

function CheckDependencies {
    $dotnetSdks = dotnet --list-sdks
    $dotnetInstalled = $false
    foreach ($sdk in $dotnetSdks) {
        $sdkVersion = [version]($sdk.Split()[0])
        if ($sdkVersion.Major -ge 6) {
            $dotnetInstalled = $true
            break
        }
    }

    if (-not $dotnetInstalled) {
        Write-Host "No .NET SDK 6.0 or higher found. Please install the .NET SDK 6.0 or higher to continue." -ForegroundColor Red
        return $false
    }

    $nugetSources = dotnet nuget list source
    if (-not $nugetSources -or $nugetSources -notcontains "nuget.org") {
        Write-Host "NuGet source is not configured correctly. Adding nuget.org source." -ForegroundColor Yellow
        dotnet nuget add source --name nuget.org https://api.nuget.org/v3/index.json
    }

    $docfxPath = Get-Command docfx -ErrorAction SilentlyContinue
    if ($docfxPath) {
        $docfxVersion = docfx --version
        $docfxVersion = $docfxVersion.Split('+')[0]
        if ([version]$docfxVersion -ne [version]"2.70.0") {
            Write-Host "DocFX version is not 2.70.0. Installing the correct version." -ForegroundColor Yellow
            dotnet tool update docfx --version 2.70 -g
        }
    } else {
        Write-Host "DocFX is not installed. Installing DocFX version 2.70." -ForegroundColor Yellow
        dotnet tool install docfx --version 2.70 -g
    }

    Write-Host "All dependencies are installed and configured correctly." -ForegroundColor Green
    return $true
}

function GetALDocFolder {
    $userProfile = [System.Environment]::GetFolderPath('UserProfile')
    $vscodeExtensionsPath = Join-Path -Path $userProfile -ChildPath ".vscode\extensions"
    $vscodeInsidersExtensionsPath = Join-Path -Path $userProfile -ChildPath ".vscode-insiders\extensions"

    $allALDocDirectories = @()

    if (Test-Path $vscodeExtensionsPath) {
        $vscodeALDocDirectories = Get-ChildItem -Path $vscodeExtensionsPath -Directory | Where-Object { $_.Name -match "^ms-dynamics-smb\.al-\d+\.\d+\.\d+$" }
        $allALDocDirectories += $vscodeALDocDirectories
    }

    if (Test-Path $vscodeInsidersExtensionsPath) {
        $vscodeInsidersALDocDirectories = Get-ChildItem -Path $vscodeInsidersExtensionsPath -Directory | Where-Object { $_.Name -match "^ms-dynamics-smb\.al-\d+\.\d+\.\d+$" }
        $allALDocDirectories += $vscodeInsidersALDocDirectories
    }

    if ($allALDocDirectories -and $allALDocDirectories.Count -gt 0) {
        $latestALDocDirectory = $allALDocDirectories | Sort-Object { [version]($_.Name -replace "ms-dynamics-smb\.al-", "") } -Descending | Select-Object -First 1
        $ALDocPath = Join-Path -Path $latestALDocDirectory.FullName -ChildPath "bin\win32\aldoc.exe"

        if (Test-Path $ALDocPath) {
            if ($latestALDocDirectory.FullName -like "*\.vscode\extensions*") {
                Write-Host "ALDoc found in .vscode" -ForegroundColor White
            } elseif ($latestALDocDirectory.FullName -like "*\.vscode-insiders\extensions*") {
                Write-Host "ALDoc found in .vscode-insiders" -ForegroundColor White
            }
            return $ALDocPath
        } else {
            Write-Host "ALDoc not found in the latest ms-dynamics-smb.al- directory" -ForegroundColor Red
            return $null
        }
    } else {
        Write-Host "No ms-dynamics-smb.al- directories found" -ForegroundColor Red
        return $null
    }
}

function GetYmlConfig {
    $configFilePath = Join-Path -Path $configFolderPath -ChildPath "aldoc.yml"

    if (-not (Test-Path $configFolderPath)) {
        Write-Host "$configFolderPath folder not found. Creating the folder." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $configFolderPath -Force | Out-Null
    }

    if (-not (Test-Path $configFilePath)) {
        Write-Host "aldoc.yml not found in $configFolderPath folder. Creating the file." -ForegroundColor Yellow
        $initialContent = "OutputPath: ''`nitems: []"
        Set-Content -Path $configFilePath -Value $initialContent
    }

    return $configFilePath
}

function GetOutputPath {
    $configFilePath = GetYmlConfig

    $configContent = Get-Content -Path $configFilePath -Raw
    $configData = $configContent | ConvertFrom-Yaml

    if (-not $configData.OutputPath -or $configData.OutputPath -eq "") {
        Write-Host "OutputPath not found or is empty in aldoc.yml." -ForegroundColor Yellow
        do {
            Write-Host "Please select the output path:" -ForegroundColor White
            $outputPath = GetFolder "Please select the output path"
            if ($outputPath -eq "") {
                Write-Host "Output path cannot be empty. Please enter a valid path." -ForegroundColor Red
            }
        } until ($outputPath -ne "")

        $configData.OutputPath = $outputPath
        $yamlContent = $configData | ConvertTo-Yaml
        Set-Content -Path $configFilePath -Value $yamlContent
    } else {
        $outputPath = $configData.OutputPath
    }

    return $outputPath
}

function InitialConfiguration {
    $dependenciesOk = CheckDependencies
    if (-not $dependenciesOk) {
        Write-Host "Dependencies check failed. Please resolve the issues and try again." -ForegroundColor Red
        return
    }

    $ALDocPath = GetALDocFolder
    if (-not $ALDocPath) {
        Write-Host "ALDoc path is not set correctly. Please check the installation and try again." -ForegroundColor Red
        return
    }

    $outputPath = GetOutputPath
    Write-Host "OutputPath is set to: $outputPath" -ForegroundColor Green

    Write-Host "Initial configuration completed successfully." -ForegroundColor Green
}

function GetFolder {
    param (
        [string]$DialogDescription
    )
    
    [void] [System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms')

    $FolderSelection = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderSelection.Description = $DialogDescription

    $TopmostForm = New-Object System.Windows.Forms.Form
    $TopmostForm.TopMost = $true
    $TopmostForm.MinimizeBox = $true

    $FolderSelection.ShowDialog($TopmostForm) | Out-Null
    return $FolderSelection.SelectedPath
}

function GenerateDocumentation {
    param (
        [string]$AppPath
    )

    $ALDocPath = GetALDocFolder
    if (-not $ALDocPath) {
        Write-Host "ALDoc path is not set correctly. Please check the installation and try again." -ForegroundColor Red
        return
    }

    $outputPath = GetOutputPath
    $referencesPath = Join-Path -Path $outputPath -ChildPath "reference"
    if (-not (Test-Path $referencesPath)) {
        New-Item -ItemType Directory -Path $referencesPath -Force | Out-Null
    }

    $OutputJsonPath = Join-Path -Path $outputPath -ChildPath "docfx.json"

    $configFilePath = GetYmlConfig
    $configContent = Get-Content -Path $configFilePath -Raw
    $configData = $configContent | ConvertFrom-Yaml

    $appPaths = @()
    $initPaths = @()
    foreach ($item in $configData.items) {
        $latestAppPath = GetLatestAppVersionPath -basePath $item.href
        if ($latestAppPath) {
            $appPaths += $latestAppPath
            $appName = Split-Path -Path $latestAppPath -Leaf
            $referenceAppPath = Join-Path -Path $referencesPath -ChildPath $appName
            if (-not (Test-Path $referenceAppPath)) {
                $initPaths += $latestAppPath
            }
        }
    }
    
    $initPathsString = $initPaths -join ','

    if ($initPathsString) {
        Write-Host "Initializing new ALDoc project for new applications." -ForegroundColor White 
        & $ALDocPath init -o $outputPath -t $initPathsString
    }

    Write-Host "Refreshing existing ALDoc project." -ForegroundColor White
    & $ALDocPath refresh -o $outputPath

    $cachePathsString = $appPaths -join ','

    & $ALDocPath build -o $outputPath -c $cachePathsString -s $AppPath
    docfx build $OutputJsonPath
}

function AddApplicationToConfiguration {
    $configFilePath = Join-Path -Path $configFolderPath -ChildPath "aldoc.yml"
    Clear-Host
    WriteBlankLine
    WriteTitle
    Write-Host "Add Application to Configuration:" -ForegroundColor Cyan
    WriteFooter

    if (-not (Test-Path $configFilePath)) {
        InitialConfiguration
    }

    $configFilePath = GetYmlConfig

    if (-not $configFilePath) {
        Write-Host "Failed to get configuration file path. Aborting." -ForegroundColor Red
        return
    }

    do {
        Write-Host "Please select the path to the .app file:" -ForegroundColor White
        $AppPath = GetFolder "Please select the path to the .app file"
        if ($AppPath -eq "") {
            Write-Host "Application path cannot be empty. Please enter a valid path." -ForegroundColor Red
        } elseif (-not (Test-Path $AppPath)) {
            Write-Host "The provided path does not exist. Please enter a valid path." -ForegroundColor Red
            $AppPath = ""
        }
    } until ($AppPath -ne "")

    $AppName = Split-Path -Path $AppPath -Leaf

    $configContent = Get-Content -Path $configFilePath -Raw
    $configData = $null

    try {
        $configData = $configContent | ConvertFrom-Yaml
    } catch {
        Write-Host "Error parsing YML file. Creating a new configuration." -ForegroundColor Yellow
        $configData = [ordered]@{ OutputPath = ""; items = @() }
    }

    if (-not $configData.items) {
        $configData.items = @()
    }

    $itemExists = $false
    foreach ($item in $configData.items) {
        if ($item.name -eq $AppName) {
            $itemExists = $true
            break
        }
    }

    if (-not $itemExists) {
        $newItem = [ordered]@{ name = $AppName; href = $AppPath }
        $configData.items += $newItem
        Write-Host "Application path added to configuration." -ForegroundColor Green

        $yamlContent = $configData | ConvertTo-Yaml
        Set-Content -Path $configFilePath -Value $yamlContent
    } else {
        Write-Host "Application path already exists in configuration." -ForegroundColor Yellow
    }
}

function MainMenu {
    while ($true) {
        Write-Host "Please select an option:" -ForegroundColor Cyan
        WriteFooter
        Write-Host "1. View List of Added Applications"
        Write-Host "2. Add Application to Configuration"
        Write-Host "3. Remove Application from Configuration"
        Write-Host "4. Generate Documentation"
        Write-Host "5. Setup Local Test Environment"
        Write-Host "6. Exit"
        $choice = Read-Host "Enter your choice (1, 2, 3, 4, 5, or 6)"

        switch ($choice) {
            1 {
                ViewAddedApplications
                WriteBlankLine
                break
            }
            2 {
                AddApplicationToConfiguration
                WriteBlankLine
                break
            }
            3 {
                RemoveApplicationFromConfiguration
                WriteBlankLine
                break
            }
            4 {
                UpdateAppPathAndGenerateDocumentation
                WriteBlankLine
                break
            }
            5 {
                SetupLocalTestEnvironment
                WriteBlankLine
                WriteTitle
                break
            }
            6 {
                Write-Host "Exiting..." -ForegroundColor Red
                return
            }
            default {
                Write-Host "Invalid choice. Please enter 1, 2, 3, 4, 5, or 6." -ForegroundColor Red
            }
        }
    }
}
function SetupLocalTestEnvironment {
    Clear-Host
    $outputPath = GetOutputPath
    $OutputSitePath = Join-Path -Path $outputPath -ChildPath "_site"
    
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "docfx serve $OutputSitePath"
}

function RemoveApplicationFromConfiguration {
    $configFilePath = GetYmlConfig
    Clear-Host

    if (-not (Test-Path $configFilePath)) {
        Write-Host "Configuration file not found." -ForegroundColor Red
        return
    }

    $configContent = Get-Content -Path $configFilePath -Raw

    try {
        $configData = $configContent | ConvertFrom-Yaml
    } catch {
        Write-Host "Error parsing YML file. Please check the format of your YAML configuration." -ForegroundColor Red
        return
    }

    if ($configData -and $configData.items -and $configData.items.Count -gt 0) {
        WriteBlankLine
        WriteTitle
        Write-Host "Remove application from list:" -ForegroundColor Cyan
        WriteFooter

        for ($i = 0; $i -lt $configData.items.Count; $i++) {
            Write-Host "$($i + 1). $($configData.items[$i].name)" -ForegroundColor White
        }

        $indexToRemove = Read-Host "Enter the number of the application to remove"

        if ($indexToRemove -match '^\d+$' -and $indexToRemove -gt 0 -and $indexToRemove -le $configData.items.Count) {
            $indexToRemove = [int]$indexToRemove - 1
            $configData.items.RemoveAt($indexToRemove)
            Write-Host "Application removed from configuration." -ForegroundColor Green

            $yamlContent = $configData | ConvertTo-Yaml
            Set-Content -Path $configFilePath -Value $yamlContent
        } else {
            Write-Host "Invalid number. No application removed." -ForegroundColor Red
        }
    } else {
        Write-Host "No applications found in the configuration." -ForegroundColor Red
    }
}

function UpdateAppPathAndGenerateDocumentation {
    $configFilePath = GetYmlConfig
    Clear-Host
    WriteBlankLine
    WriteTitle
    Write-Host "Generate Documentation:" -ForegroundColor Cyan
    WriteFooter

    if (-not (Test-Path $configFilePath)) {
        Write-Host "Configuration file not found." -ForegroundColor Red
        return
    }

    $configContent = Get-Content -Path $configFilePath -Raw

    try {
        $configData = $configContent | ConvertFrom-Yaml
    } catch {
        Write-Host "Error parsing YML file. Please check the format of your YAML configuration." -ForegroundColor Red
        return
    }

    if ($configData -and $configData.items -and $configData.items.Count -gt 0) {
        foreach ($item in $configData.items) {
            $appPath = GetLatestAppVersionPath -basePath $item.href
            if ($appPath) {
                GenerateDocumentation -AppPath $appPath
            } else {
                Write-Host "Could not find the latest version for application: $($item.name)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "No applications found in the configuration." -ForegroundColor Red
    }
}

function GetLatestAppVersionPath {
    param (
        [string]$basePath
    )

    if (-not (Test-Path $basePath)) {
        Write-Host "The base path does not exist: $basePath" -ForegroundColor Red
        return $null
    }

    $appFiles = Get-ChildItem -Path $basePath -Filter *.app

    if (-not $appFiles) {
        Write-Host "No .app files found in the base path: $basePath" -ForegroundColor Red
        return $null
    }

    $latestAppFile = $null
    $latestVersion = [version]"0.0.0.0"

    foreach ($file in $appFiles) {
        $fileName = $file.Name
        $versionString = $fileName -replace '.*_([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\.app', '$1'
        try {
            $currentVersion = [version]$versionString
            if ($currentVersion -gt $latestVersion) {
                $latestVersion = $currentVersion
                $latestAppFile = $file.FullName
            }
        } catch {
            Write-Host "Failed to parse version from file name: $fileName" -ForegroundColor Yellow
        }
    }

    if ($latestAppFile) {
        Write-Host "Latest .app file found: $fileName" -ForegroundColor White
        return $latestAppFile
    } else {
        Write-Host "No valid .app files found in the base path: $basePath" -ForegroundColor Red
        return $null
    }
}

function ViewAddedApplications {
    $configFilePath = GetYmlConfig
    Clear-Host

    if (-not (Test-Path $configFilePath)) {
        Write-Host "Configuration file not found." -ForegroundColor Red
        return
    }

    $configContent = Get-Content -Path $configFilePath -Raw

    try {
        $configData = $configContent | ConvertFrom-Yaml
    } catch {
        Write-Host "Error parsing YML file. Please check the format of your YAML configuration." -ForegroundColor Red
        return
    }

    if ($configData -and $configData.items -and $configData.items.Count -gt 0) {
        WriteBlankLine
        WriteTitle
        Write-Host "List of added applications:" -ForegroundColor Cyan
        WriteFooter
        foreach ($item in $configData.items) {
            Write-Host "- $($item.name)" -ForegroundColor White
        }
    } else {
        Write-Host "No applications found in the configuration." -ForegroundColor Red
    }
}

function WriteBlankLine {
    Write-Host " " -ForegroundColor White
}

function WriteTitle {
    Write-Host "----------------- ANDoc -----------------" -ForegroundColor Cyan
}

function WriteFooter {
    Write-Host "------------------------------------------" -ForegroundColor Cyan
}

function ANDoc {
    Clear-Host
    WriteBlankLine
    WriteTitle
    MainMenu
}

Export-ModuleMember -Function ANDoc