# Extract source code from embeded svg file.

param (
    [Parameter(Mandatory=$true)]
    [string]$path,
    [string]$imageDir = $null
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

Write-Host "Extracting source code from $path"
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

# Image Extraction

if ([string]::IsNullOrEmpty($imageDir)) {
    exit 0
}

Write-Host "Extracting images into $imageDir"
if (-not (Test-Path -Path $imageDir)) {
    try {
        Write-Host "Creating directory $imageDir"
        New-Item -Path $imageDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    } catch {
        Write-Error "Failed to create directory: $imageDir"
        exit 1
    }
}
$imageDir = Resolve-Path -Path $imageDir

[xml]$svgXml = $embededContent
$svgElement = $svgXml.DocumentElement

if ("svg" -ne $svgElement.Name) {
    Write-Error "Not an svg element"
    exit 1
}

$namespaces = @{}
foreach ($attr in $svgElement.Attributes) {
    if ($attr.Name -like "xmlns*") {
        $prefix = ""
        if ($attr.Name -ne "xmlns") {
            $prefix = $attr.Name.Split(":")[1] + ":"
        }
        $namespaces[$prefix] = $attr.Value
    }
}

$namespaceManager = New-Object System.Xml.XmlNamespaceManager($svgXml.NameTable)

foreach ($prefix in $namespaces.Keys) {
    $namespaceManager.AddNamespace("svg" + $prefix, $namespaces[$prefix])
}

$imageElements = $svgXml.SelectNodes("//svg:image", $namespaceManager)

Write-Host "Found $($imageElements.Count) image nodes"
$pattern = "^data:image/([^;]+);([^,]+),(.*)$"
$svgFileName = [System.IO.Path]::GetFileName($path)
$image_cnt = 0
foreach ($imageElement in $imageElements) {
    $image_cnt = $image_cnt + 1
    $href = $imageElement.GetAttribute("xlink:href")
    $match = [regex]::Match($href, $pattern)

    if (-not $match.Success) {
        Write-Warning "Image $image_cnt (starts from 1) href attribute format is unexpected"
        continue
    }

    $format = $match.Groups[1].Value
    $encoding = $match.Groups[2].Value
    $encodedData = $match.Groups[3].Value

    if ("base64" -ne $encoding) {
        Write-Warning "Image $image_cnt (starts from 1) is not base64-encoded"
        continue
    }

    $decodedBytes = [System.Convert]::FromBase64String($encodedData)
    $outputPath = Join-Path -Path $imageDir -ChildPath "$svgFileName.extracted.$image_cnt.$format"
    [System.IO.File]::WriteAllBytes($outputPath, $decodedBytes)
    Write-Host "Image $image_cnt saved to $outputPath"
}
