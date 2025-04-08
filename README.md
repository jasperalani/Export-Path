# Export Path

Exports the system path variable to a text file in OneDrive for backup.
For when you've deleted your system PATH variable accidentally one too many times...

### Features:
- Powershell Installer
- Creates a daily Task in Windows Task Scheduler
- Only keeps backups for 5 days.

### Install:

1. Download installer file from [https://raw.githubusercontent.com/jasperalani/Export-Path/refs/heads/main/Install-ExportPathUtil.ps1](here) and save the page as `Install-ExportPathUtil.ps1`
2. Open PowerShell as Administrator
3. Navigate to downloads folder `cd "~\Downloads"`
4. Run the installer script `powershell -ExecutionPolicy Bypass -File .\Install-ExportPathUtil.ps1`