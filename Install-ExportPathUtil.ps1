# Install-ExportPath.ps1
# Script to install the Export-Path backup solution

function Download-GitHubRawContent {
    param (
        [string]$GitHubUrl,
        [string]$OutputPath
    )
    
    try {
        Invoke-WebRequest -Uri $GitHubUrl -OutFile $OutputPath -ErrorAction Stop
        Write-Host "Downloaded $OutputPath successfully." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed to download from $GitHubUrl. Error: $_" -ForegroundColor Red
        return $false
    }
}

function Get-UserSID {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    return $currentUser.User.Value
}

function Test-AdminRights {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Create-Directory {
    param (
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "Created directory: $Path" -ForegroundColor Yellow
    }
}

# Check if running as admin
if (-not (Test-AdminRights)) {
    Write-Host "This script should be run as Administrator for best results." -ForegroundColor Yellow
    $continue = Read-Host "Do you want to continue anyway? (Y/N)"
    if ($continue -ne "Y") {
        Write-Host "Exiting installation." -ForegroundColor Red
        exit
    }
}

# Get OneDrive path
$oneDrivePath = $env:OneDrive
if (-not $oneDrivePath) {
    Write-Host "OneDrive not detected. Please enter your OneDrive path:" -ForegroundColor Yellow
    $oneDrivePath = Read-Host "OneDrive path (e.g. C:\Users\YourUsername\OneDrive)"
}

# Create base path
$basePath = "$oneDrivePath\Documents\Export-Path"
Create-Directory -Path $basePath

# Download Export-Path.ps1
$scriptUrl = "https://raw.githubusercontent.com/jasperalani/Export-Path/main/Export-Path.ps1"
$scriptPath = "$basePath\Export-Path.ps1"
$scriptDownloaded = Download-GitHubRawContent -GitHubUrl $scriptUrl -OutputPath $scriptPath

# Download Task XML
$taskUrl = "https://raw.githubusercontent.com/jasperalani/Export-Path/main/Daily%20Path%20Variable%20Backup%20Task.xml"
$taskPath = "$basePath\Daily Path Variable Backup Task.xml"
$taskDownloaded = Download-GitHubRawContent -GitHubUrl $taskUrl -OutputPath $taskPath

if (-not ($scriptDownloaded -and $taskDownloaded)) {
    Write-Host "One or more downloads failed. Please check your internet connection and try again." -ForegroundColor Red
    exit
}

# Modify Export-Path.ps1
$scriptContent = Get-Content -Path $scriptPath -Raw
$modifiedScriptContent = $scriptContent -replace '\$basePath = ".*?"', "`$basePath = `"$basePath`""
$modifiedScriptContent = $modifiedScriptContent + "`n`n# Define max backup age in days`n`$maxBackupAgeDays = 5`n`n# Clean up old backup files`n`$backupFiles = Get-ChildItem -Path `$basePath -Filter `"PATH_Backup_*.txt`"`nforeach (`$file in `$backupFiles) {`n    `$fileAge = (Get-Date) - `$file.LastWriteTime`n    if (`$fileAge.Days -gt `$maxBackupAgeDays) {`n        Remove-Item -Path `$file.FullName -Force`n        Write-Host `"Deleted old backup file: `$(`$file.Name) (Age: `$(`$fileAge.Days) days)`"`n    }`n}"
Set-Content -Path $scriptPath -Value $modifiedScriptContent
Write-Host "Updated Export-Path.ps1 with your settings." -ForegroundColor Green

# Modify Task XML
$taskContent = Get-Content -Path $taskPath -Raw
$userSID = Get-UserSID
$taskContent = $taskContent -replace '<UserId>XXX</UserId>', "<UserId>$userSID</UserId>"
$fullPathNoEnv = $basePath
$taskContent = $taskContent -replace 'SPECIFY_LOCATION\\Export-Path.ps1', "$fullPathNoEnv\Export-Path.ps1"
Set-Content -Path $taskPath -Value $taskContent -Encoding Unicode
Write-Host "Updated Task XML with your settings." -ForegroundColor Green

# Create and register the task
$taskName = "Daily PATH Variable Backup"
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

try {
    if ($taskExists) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "Removed existing task." -ForegroundColor Yellow
    }
    
    Register-ScheduledTask -Xml (Get-Content -Path $taskPath -Raw) -TaskName $taskName
    Write-Host "Task scheduled successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to register the task. You can manually import the task using Task Scheduler." -ForegroundColor Yellow
    Write-Host "Task XML file location: $taskPath" -ForegroundColor Yellow
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host "`nInstallation Complete!" -ForegroundColor Green
Write-Host "The Export-Path script has been set up to run daily and will keep backups for 5 days." -ForegroundColor White
Write-Host "Script location: $scriptPath" -ForegroundColor White
Write-Host "Backups will be stored in: $basePath" -ForegroundColor White