# KontrolaSlozekB000.ps1

$root = "c:\NAD1261_008"

Write-Host ""
Write-Host "Kontrola slozek zacinajicich na b000 v $root"
Write-Host ""

if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    Write-Host "Zadana cesta neexistuje: $root"
    Write-Host ""
    Pause
    exit 1
}

$matches = Get-ChildItem -LiteralPath $root -Directory -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like 'b000*' }

if ($matches.Count -gt 0) {
    Write-Host "Nalezeny slozky zacinajici na b000:"
    Write-Host ""

    $matches | ForEach-Object {
        Write-Host $_.FullName
    }
} else {
    Write-Host "Nenalezena zadna slozka zacinajici na b000."
}

Write-Host ""
Pause
