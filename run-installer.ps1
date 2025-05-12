# Create a temporary directory
$tempDir = Join-Path $env:TEMP "pget-pw-installer"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Set the base URL for the GitHub repository
$baseUrl = "https://raw.githubusercontent.com/devo-tion/pget-pw/refs/heads/main"

# Download the installer script
$installerUrl = "$baseUrl/installer.ps1"
$installerPath = Join-Path $tempDir "installer.ps1"
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

# Download the tweaks.json file
$tweaksJsonUrl = "$baseUrl/tweaks.json"
$tweaksJsonPath = Join-Path $tempDir "tweaks.json"
Invoke-WebRequest -Uri $tweaksJsonUrl -OutFile $tweaksJsonPath

# Create tweaks directory
$tweaksDir = Join-Path $tempDir "tweaks"
New-Item -ItemType Directory -Force -Path $tweaksDir | Out-Null

# Download the tweaks files
$tweaks = Get-Content $tweaksJsonPath | ConvertFrom-Json
foreach ($tweak in $tweaks.tweaks) {
    $tweakFileName = Split-Path $tweak.filePath -Leaf
    $tweakUrl = "$baseUrl/tweaks/$tweakFileName"
    $tweakPath = Join-Path $tweaksDir $tweakFileName
    try {
        Invoke-WebRequest -Uri $tweakUrl -OutFile $tweakPath
    }
    catch {
        Write-Warning "Could not download tweak file: $tweakFileName"
    }
}

# Change to the temporary directory
Set-Location $tempDir

# Run the installer
& $installerPath

# Clean up (optional - uncomment if you want to remove the temporary files)
Remove-Item -Path $tempDir -Recurse -Force 