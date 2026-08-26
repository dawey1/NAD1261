# KopirujDoZpracovano.ps1

$root = "\\fsch01\Prijem\NAD1261\NAD1261_008"
$outRoot = "${root}_zpracovano"

# Nastavení
$startKa = 1      # od kterého Ka zaèít, napø. 11 = Ka011
$maxKa   = 0      # kolik Ka zpracovat; 0 = všechny od $startKa dál

Write-Host ""
Write-Host "Zdroj: $root"
Write-Host "Cíl:   $outRoot"
Write-Host "Start: Ka$($startKa.ToString('000'))"
Write-Host "Poèet: $(if ($maxKa -eq 0) { 'všechny' } else { $maxKa })"
Write-Host ""

if (-not (Test-Path $outRoot)) {
    New-Item -Path $outRoot -ItemType Directory | Out-Null
}

$kaList = Get-ChildItem $root -Directory |
Where-Object { $_.Name -match '^Ka\d+$' } |
Sort-Object Name |
Where-Object {
    [int]($_.Name.Substring(2)) -ge $startKa
}

if ($maxKa -gt 0) {
    $kaList = $kaList | Select-Object -First $maxKa
}

$kaList | ForEach-Object {

    $kaDir = $_
    Write-Host "Zpracovávám $($kaDir.Name)"

    Get-ChildItem $kaDir.FullName -Directory |
    Where-Object { $_.Name -match '^aj\d+[a-z]?$' } |
    ForEach-Object {

        $source = $_.FullName
        $name = $_.Name
        $target = Join-Path $outRoot $name

        $i = 1
        while (Test-Path $target) {
            $target = Join-Path $outRoot ("{0}_{1}" -f $name, $i)
            $i++
        }

        Write-Host "  Kopíruji $name -> $(Split-Path $target -Leaf)"

        Copy-Item -Path $source -Destination $target -Recurse
    }
}

Write-Host ""
Write-Host "Hotovo. Pùvodní data zùstala beze zmìny."
Pause