# Nastavení koøenového adresáøe
$RootPath = "\\fsch01\Prijem\NAD1261\NAD1261_008"

Get-ChildItem -Path $RootPath -Directory -Filter "Ka*" |
ForEach-Object {

    $subDirs = Get-ChildItem -Path $_.FullName -Directory

    if ($subDirs.Count -gt 0) {
        Write-Host ""
        Write-Host "$($_.FullName)"
        Write-Host "  Podsložky:"
        $subDirs | ForEach-Object {
            Write-Host "    $($_.Name)"
        }
    }
}