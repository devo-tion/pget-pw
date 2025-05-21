# Create a temporary directory
$tempDir = Join-Path $env:TEMP "pget-pw-installer"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# Change to the temporary directory
Set-Location $tempDir

# Download the repository
$repoUrl = "https://github.com/devo-tion/pget-pw/archive/refs/heads/main.zip"
$zipFile = Join-Path $tempDir "main.zip"
Invoke-WebRequest -Uri $repoUrl -OutFile $zipFile

# Extract the zip file
Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force

# Change to the extracted directory
Set-Location (Join-Path $tempDir "pget-pw-main")

# Run the installer
.\installer.ps1 