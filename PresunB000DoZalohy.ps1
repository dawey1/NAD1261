param(
    [string]$Root = "C:\NAD1261_008"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Presun slozek b000* do zaloha v $Root"
Write-Host ""

if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
    Write-Host "Zadana cesta neexistuje: $Root"
    Write-Host ""
    Pause
    exit 1
}

$ajFolders = @(Get-ChildItem -LiteralPath $Root -Directory -ErrorAction Stop |
    Where-Object { $_.Name -like "aj*" } |
    Sort-Object Name)

if ($ajFolders.Count -eq 0) {
    Write-Host "Nenalezeny zadne slozky aj*."
    Write-Host ""
    Pause
    exit 0
}

$backupRoot = Join-Path $Root "zaloha"
$operations = @()

foreach ($aj in $ajFolders) {
    $sources = @(Get-ChildItem -LiteralPath $aj.FullName -Directory -ErrorAction Stop |
        Where-Object { $_.Name -like "b000*" } |
        Sort-Object Name)

    foreach ($source in $sources) {
        $destinationAj = Join-Path $backupRoot $aj.Name
        $destination = Join-Path $destinationAj $source.Name

        if (Test-Path -LiteralPath $destination) {
            throw "Cilova slozka jiz existuje: $destination"
        }

        $operations += [PSCustomObject]@{
            Source = $source.FullName
            DestinationAj = $destinationAj
            Destination = $destination
        }
    }
}

if ($operations.Count -eq 0) {
    Write-Host "Nenalezeny zadne slozky b000*."
    Write-Host ""
    Pause
    exit 0
}

$null = New-Item -Path $backupRoot -ItemType Directory -Force

foreach ($operation in $operations) {
    if (-not (Test-Path -LiteralPath $operation.DestinationAj)) {
        $null = New-Item -Path $operation.DestinationAj -ItemType Directory
    }

    Write-Host "Presouvam:"
    Write-Host "  $($operation.Source)"
    Write-Host "  -> $($operation.Destination)"

    Move-Item -LiteralPath $operation.Source -Destination $operation.DestinationAj
}

foreach ($aj in $ajFolders) {
    $newB000 = Join-Path $aj.FullName "NEW_b000"
    $b000 = Join-Path $aj.FullName "b000"

    if (Test-Path -LiteralPath $newB000) {
        if (Test-Path -LiteralPath $b000) {
            throw "Cilova slozka jiz existuje: $b000"
        }

        Write-Host "Prejmenovavam:"
        Write-Host "  $newB000"
        Write-Host "  -> $b000"

        Rename-Item -LiteralPath $newB000 -NewName "b000"
    }
}

Write-Host ""
Write-Host "Hotovo. Presunuto slozek: $($operations.Count)"
Write-Host "Puvodni struktura b000* je v: $backupRoot"
Write-Host "Slozky NEW_b000 byly prejmenovany na b000."
Write-Host ""
Pause
