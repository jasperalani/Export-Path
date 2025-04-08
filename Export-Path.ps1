# Export-Path.ps1
# Get current date in yyyy-MM-dd format
$date = Get-Date -Format "yyyy-MM-dd"
# Get computer/hostname
$computerName = $env:COMPUTERNAME
# Define output file paths (with computer name in filename)
$basePath = "C:\Users\jaspe\OneDrive\Documents\Export-Path"
$outputFile = "$basePath\PATH_Backup_${computerName}_$date.txt"

# Define max age for backup files (in days)
$maxBackupAgeDays = 5

# Get system PATH variable
$systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
# Save to files
$systemPath | Out-File -FilePath $outputFile -Encoding UTF8

# Clean up old backup files
$backupFiles = Get-ChildItem -Path $basePath -Filter "PATH_Backup_*.txt"
foreach ($file in $backupFiles) {
    $fileAge = (Get-Date) - $file.LastWriteTime
    if ($fileAge.Days -gt $maxBackupAgeDays) {
        Remove-Item -Path $file.FullName -Force
        Write-Host "Deleted old backup file: $($file.Name) (Age: $($fileAge.Days) days)"
    }
}

# Define max backup age in days
$maxBackupAgeDays = 5

# Clean up old backup files
$backupFiles = Get-ChildItem -Path $basePath -Filter "PATH_Backup_*.txt"
foreach ($file in $backupFiles) {
    $fileAge = (Get-Date) - $file.LastWriteTime
    if ($fileAge.Days -gt $maxBackupAgeDays) {
        Remove-Item -Path $file.FullName -Force
        Write-Host "Deleted old backup file: $($file.Name) (Age: $($fileAge.Days) days)"
    }
}
