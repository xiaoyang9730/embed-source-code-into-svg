# Extract source code from embeded svg file.

param (
    [Parameter(Mandatory=$true)]
    [string]$path
)

$embededFilePath = Resolve-Path -Path $path 2> $null
if (-not $embededFilePath) {
    Write-Error "Can't resolve path: $path"
    exit 1
}

$extension = [System.IO.Path]::GetExtension($embededFilePath)
if ($extension -ne ".svg") {
    Write-Error "Not a SVG file: $path"
    exit 1
}

$embededContent = [System.IO.File]::ReadAllText($embededFilePath) -replace "`r`n", "`n"
$sourceCodeEncoded = ""
$isSourceCode = $false;
foreach ($line in $embededContent -split "`n") {
    if ($line -eq "-->") {
        break
    }
    if ($isSourceCode) {
        $sourceCodeEncoded = $sourceCodeEncoded + $line;
    } elseif ($line -eq "source code (base64):") {
        $isSourceCode = $true
    }
}

if ($sourceCodeEncoded.Length -eq 0) {
    Write-Error "No embeded source code found in $path"
    exit 1
}

$sourceCodeBytes = [System.Convert]::FromBase64String($sourceCodeEncoded)
$sourceCodeDecoded = [System.Text.Encoding]::UTF8.GetString($sourceCodeBytes)

Write-Output $sourceCodeDecoded
