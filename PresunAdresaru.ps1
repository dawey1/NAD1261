$root = "\\fsch01\Prijem\NAD1261\D8_neuplne"

Get-ChildItem $root -Directory |
Where-Object { $_.Name -match '^Ka\d+$' } |
ForEach-Object {

    $kaDir = $_

    Get-ChildItem $kaDir.FullName -Directory |
    Where-Object { $_.Name -match '^aj\d+[a-z]?$' } |
    ForEach-Object {

        $source = $_.FullName
        $name = $_.Name
        $target = Join-Path $root $name

        $i = 1
        while (Test-Path $target) {
            $target = Join-Path $root ("{0}_{1}" -f $name, $i)
            $i++
        }

        Write-Host "Pøesouvám:"
        Write-Host "  $source"
        Write-Host "  -> $target"

        Move-Item $source $target
    }
}

Pause