param(
    [string]$Root = "c:\NAD1261_008",
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

function Get-AjFolders {
    param([Parameter(Mandatory = $true)][string]$Path)

    Get-ChildItem -LiteralPath $Path -Directory -Recurse -Force -ErrorAction Stop |
        Where-Object { $_.Name -match '^aj(\d+[a-z]?)$' } |
        Sort-Object FullName
}

function Get-FileGroupKey {
    param([Parameter(Mandatory = $true)][string]$BaseName)

    if ($BaseName -match '^(.*\d)[a-z]+$') {
        return $Matches[1].ToLowerInvariant()
    }

    return $BaseName.ToLowerInvariant()
}

function Get-SourceNumber {
    param([Parameter(Mandatory = $true)][string]$BaseName)

    if ($BaseName -match '(\d+)[a-z]*$') {
        return [int]$Matches[1]
    }

    return $null
}

if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
    throw "Zadana cesta neexistuje: $Root"
}

$ajFolders = @(Get-AjFolders -Path $Root)

if ($ajFolders.Count -eq 0) {
    Write-Host "Nenalezeny zadne slozky aj s ciselkem."
    exit 0
}

$operations = @()

foreach ($aj in $ajFolders) {
    $ajMatch = [regex]::Match($aj.Name, '^aj(\d+[a-z]?)$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $ajCode = $ajMatch.Groups[1].Value

    $pointFolders = @(Get-ChildItem -LiteralPath $aj.FullName -Directory -Force -ErrorAction Stop |
        Where-Object { $_.Name -match '^b\d+$' } |
        Sort-Object Name)

    foreach ($point in $pointFolders) {
        $pointMatch = [regex]::Match($point.Name, '^b(\d+)$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $pointCode = ([int]$pointMatch.Groups[1].Value).ToString('D2')
        $allFiles = @(Get-ChildItem -LiteralPath $point.FullName -File -Force -ErrorAction Stop |
            Sort-Object Name)
        $processedFiles = @($allFiles | Where-Object {
            $_.Name -match '^NAD1261_008_\d+_\d+_\d{4}[a-z]*\.[^.]+$'
        })
        $files = @($allFiles | Where-Object {
            $_.Name -notmatch '^NAD1261_008_\d+_\d+_\d{4}[a-z]*\.[^.]+$'
        })

        $sequence = 1
        $groupNumbers = @{}
        $usedNumbers = @{}
        foreach ($processedFile in $processedFiles) {
            if ($processedFile.Name -match '^NAD1261_008_\d+_\d+_(\d{4})[a-z]*\.') {
                $usedNumbers[[int]$Matches[1]] = $true
            }
        }

        foreach ($file in $files) {
            $groupKey = Get-FileGroupKey -BaseName $file.BaseName
            if (-not $groupNumbers.ContainsKey($groupKey)) {
                $sourceNumber = Get-SourceNumber -BaseName $groupKey
                if ($null -ne $sourceNumber -and $usedNumbers.ContainsKey($sourceNumber)) {
                    $groupNumbers[$groupKey] = $sourceNumber
                } else {
                    while ($usedNumbers.ContainsKey($sequence)) {
                        $sequence++
                    }
                    $groupNumbers[$groupKey] = $sequence
                    $usedNumbers[$sequence] = $true
                    $sequence++
                }
            }

            $variant = ""
            if ($file.BaseName -match '\d([a-z]+)$') {
                $variant = $Matches[1].ToLowerInvariant()
            }

            $extension = $file.Extension.ToLowerInvariant()
            $newName = "NAD1261_008_{0}_{1}_{2:D4}{3}{4}" -f $ajCode, $pointCode, $groupNumbers[$groupKey], $variant, $extension
            $operations += [PSCustomObject]@{
                Source = $file.FullName
                Destination = Join-Path $point.FullName $newName
                NewName = $newName
            }
        }
    }
}

$duplicateDestinations = @($operations | Group-Object Destination | Where-Object Count -gt 1)
if ($duplicateDestinations.Count -gt 0) {
    throw "Byly vytvoreny duplicitni cilove nazvy souboru."
}

Write-Host "Nalezeno souboru: $($operations.Count)"

foreach ($operation in $operations) {
    if ($operation.Source -ieq $operation.Destination) {
        continue
    }

    if (Test-Path -LiteralPath $operation.Destination) {
        throw "Cilovy soubor jiz existuje: $($operation.Destination)"
    }

    Write-Host "$($operation.Source) -> $($operation.NewName)"
    if (-not $WhatIf) {
        Rename-Item -LiteralPath $operation.Source -NewName $operation.NewName
    }
}

if ($WhatIf) {
    Write-Host "Nahled dokoncen. Soubory nebyly prejmenovany."
} else {
    Write-Host "Prejmenovani dokonceno."
}