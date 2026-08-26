param(
    [string]$Root = "C:\NAD1261_008"
)

$ErrorActionPreference = "Stop"

function Get-FlatFileName {
    param(
        [Parameter(Mandatory = $true)][string]$SourceName,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $parts = @($SourceName)
    if ($RelativePath) {
        $parts += ($RelativePath -split "[\\/]" | Where-Object { $_ })
    }

    $name = $parts -join "__"

    foreach ($c in [System.IO.Path]::GetInvalidFileNameChars()) {
        $name = $name.Replace($c, "_")
    }

    return $name
}

function Get-UniqueDestinationPath {
    param(
        [Parameter(Mandatory = $true)][string]$DestinationRoot,
        [Parameter(Mandatory = $true)][string]$BaseName
    )

    $candidate = Join-Path $DestinationRoot $BaseName
    $index = 1

    while (Test-Path -LiteralPath $candidate) {
        $stem = [System.IO.Path]::GetFileNameWithoutExtension($BaseName)
        $ext = [System.IO.Path]::GetExtension($BaseName)
        $prefix = "DUP{0:D3}" -f $index
        $candidate = Join-Path $DestinationRoot ("{0}__{1}{2}" -f $prefix, $stem, $ext)
        $index++
    }

    return $candidate
}

Write-Host ""
Write-Host "Presun a slouceni slozek b000* v $Root"
Write-Host ""

if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
    Write-Host "Zadana cesta neexistuje: $Root"
    Write-Host ""
    Pause
    exit 1
}

$ajFolders = Get-ChildItem -LiteralPath $Root -Directory -ErrorAction Stop |
    Where-Object { $_.Name -like "aj*" } |
    Sort-Object Name

$ajWithoutB000 = @()

if (-not $ajFolders) {
    Write-Host "Nenalezeny zadne slozky aj*."
    Write-Host ""
    Pause
    exit 0
}

foreach ($aj in $ajFolders) {
    Write-Host "Zpracovavam $($aj.Name)"

    $sources = Get-ChildItem -LiteralPath $aj.FullName -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "b000*" } |
        Sort-Object Name

    if (-not $sources) {
        Write-Host "  Zadna slozka b000*."
        $ajWithoutB000 += $aj.Name
        continue
    }

    $target = Join-Path $aj.FullName "NEW_b000"
    if (Test-Path -LiteralPath $target) {
        throw "Cilova slozka jiz existuje: $target"
    }

    $null = New-Item -Path $target -ItemType Directory

    $copiedFiles = 0

    foreach ($source in $sources) {
        $files = Get-ChildItem -LiteralPath $source.FullName -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne "Thumbs.db" }

        foreach ($file in $files) {
            $relative = $file.FullName.Substring($source.FullName.Length).TrimStart("\")
            $flatName = Get-FlatFileName -SourceName $source.Name -RelativePath $relative
            $destPath = Get-UniqueDestinationPath -DestinationRoot $target -BaseName $flatName

            Copy-Item -LiteralPath $file.FullName -Destination $destPath
            $copiedFiles++
        }
    }

    Write-Host "  Hotovo: $copiedFiles souboru do NEW_b000"
}

Write-Host ""
if ($ajWithoutB000.Count -gt 0) {
    Write-Host "AJ bez b000*: $($ajWithoutB000 -join ', ')"
    Write-Host ""
}
Write-Host "Hotovo. Puvodni slozky zustaly beze zmen a nove soubory jsou v NEW_b000."
Write-Host ""
Pause
