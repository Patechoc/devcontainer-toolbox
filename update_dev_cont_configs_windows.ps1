# Define variables
$repoURL = "https://github.com/norwegianredcross/devcontainer-toolbox/releases/latest"
$downloadPath = "$env:TEMP\devcontainer-toolbox.zip"
$extractPath = "$env:TEMP\devcontainer-toolbox"

# Get the latest release download URL
$releasePage = Invoke-WebRequest -Uri $repoURL -UseBasicParsing
$downloadLink = $releasePage.Links | Where-Object { $_.href -match "\.zip$" } | Select-Object -ExpandProperty href
if (-not $downloadLink) {
    Write-Host "Error: Could not find a .zip file in the latest release page."
    exit 1
}

# Ensure full URL
if ($downloadLink -notmatch "^https://") {
    $downloadLink = "https://github.com$downloadLink"
}

Write-Host "Downloading from: $downloadLink"
Invoke-WebRequest -Uri $downloadLink -OutFile $downloadPath

# Remove old extraction folder if exists
if (Test-Path $extractPath) {
    Remove-Item -Recurse -Force $extractPath
}

# Extract archive
Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force

# Identify the extracted folder name
$extractedFolders = Get-ChildItem -Path $extractPath | Where-Object { $_.PSIsContainer } | Select-Object -ExpandProperty FullName
$sourcePath = $extractedFolders | Select-Object -First 1  # Assume first folder is the correct one

if (-not $sourcePath) {
    Write-Host "Error: Could not find extracted content."
    exit 1
}

# Overwrite .devcontainer/ and .devcontainer.extend/
$destinations = @(".devcontainer", ".devcontainer.extend")
foreach ($folder in $destinations) {
    $targetPath = "$PWD\$folder"
    $sourceFolder = "$sourcePath\$folder"
    
    if (Test-Path $sourceFolder) {
        if (Test-Path $targetPath) {
            Remove-Item -Recurse -Force $targetPath
        }
        Copy-Item -Path $sourceFolder -Destination $targetPath -Recurse -Force
        Write-Host "Updated: $folder"
    } else {
        Write-Host "Warning: $folder not found in archive. Skipping."
    }
}

Write-Host "Update complete."
