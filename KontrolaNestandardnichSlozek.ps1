# KontrolaNestandardnichSlozek.ps1

$root = "\\fsch01\Prijem\NAD1261\D8_neuplne"

Write-Host ""
Write-Host "Kontrola nestandardních složek v $root"
Write-Host ""

$found = $false

Get-ChildItem $root -Directory | ForEach-Object {

    $kaDir = $_

    Get-ChildItem $kaDir.FullName -Directory |
    Where-Object { $_.Name -notmatch '^aj\d+[a-z]?$' } |
    ForEach-Object {

        $found = $true

        Write-Host "Ka adresáø : $($kaDir.Name)"
        Write-Host "Složka      : $($_.Name)"
        Write-Host "Cesta       : $($_.FullName)"
        Write-Host ""
    }
}

if (-not $found) {
    Write-Host "Nebyly nalezeny žádné nestandardní složky."
}

Write-Host ""
Pause