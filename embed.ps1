# Embed source code into generated svg file.

param (
    [Parameter(Mandatory=$true)]
    [string]$path,
    [string]$tmpFileName = "__tmpfile.svg",
    [string]$imageDir = $null
)

$srcFilePath = Resolve-Path -Path $path 2> $null
if (-not $srcFilePath) {
    Write-Error "Can't resolve path: $path"
    exit 1
}

$parentDir = Split-Path -Path $srcFilePath -Parent
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($srcFilePath)
$extension = [System.IO.Path]::GetExtension($srcFilePath)
$tmpFilePath = $(Join-Path -Path $parentDir -ChildPath $tmpFileName)
$targetFilePath = $(Join-Path -Path $parentDir -ChildPath "$baseName.svg")

if (Test-Path $tmpFilePath) {
    Write-Error "Tmpfile $tmpFilePath already exists, please specify another filename for tmpfile"
    exit 1
}

# Create temporary svg file
Write-Host "Creating tmpfile"
if (".typ" -eq $extension) {
    $version = $(typst --version)
    typst compile $srcFilePath $tmpFilePath
} elseif (".mmd" -eq $extension) {
    $version = "mmdc $(mmdc --version)"
    mmdc -i $srcFilePath -o $tmpFilePath
} else {
    Write-Error "Unsupported file extension: $srcFilePath"
    exit 1
}
Write-Host "Tmpfile created: $tmpFilePath"

# Get file content and cleanup tmpfile
$svg = ([System.IO.File]::ReadAllText($tmpFilePath) -replace "`r`n", "`n").Trim()
Remove-Item $tmpFilePath
Write-Host "Tmpfile deleted: $tmpFilePath"

# Embed source code into target svg file
$src = ([System.IO.File]::ReadAllText($srcFilePath) -replace "`r`n", "`n").Trim()
$srcBytes = [System.Text.Encoding]::UTF8.GetBytes($src)
$srcEncoded = [System.Convert]::ToBase64String($srcBytes)
$decodedBytes = [System.Convert]::FromBase64String($srcEncoded)
$decoded = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
if ($decoded -ne $src) {
    Write-Error "Base64 decoded source code don't match original source code"
    exit 1
}

[System.IO.File]::WriteAllText($targetFilePath, "<!--`n$version`n`nsource code (base64):`n$srcEncoded`n-->`n$svg")
Write-Host "`nEmbedding completed"
Write-Host "Source: $srcFilePath"
Write-Host "Target: $targetFilePath"

Write-Host "`nExtracting from embeded svg file"
Write-Host "========================================="
$extractScript = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "extract.ps1"
if ([string]::IsNullOrEmpty($imageDir)) {
    $extractedSourceCode = Invoke-Expression "$extractScript -path $targetFilePath"
} else {
    $extractedSourceCode = Invoke-Expression "$extractScript -path $targetFilePath -imageDir $imageDir"
}
Write-Host "Extracted source code:`n$extractedSourceCode"
