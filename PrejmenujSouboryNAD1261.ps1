param(
    [string]$Root = "c:\NAD1261_008",
    [ValidateSet("Check", "Rename", "Test")]
    [string]$Mode = "Check",
    [string]$DestinationRoot,
    [string]$LogDirectory = (Join-Path $PSScriptRoot "logs")
)

$ErrorActionPreference = "Stop"

function Write-EventLog {
    param([string]$Path, [hashtable]$Event)
    $Event.timestamp = (Get-Date).ToString("o")
    $Event | ConvertTo-Json -Compress -Depth 8 | Add-Content -LiteralPath $Path -Encoding UTF8
}

function Write-State {
    param([hashtable]$State)
    $State.timestamp = (Get-Date).ToString("o")
    $temporary = "$script:StatePath.tmp"
    $State | ConvertTo-Json -Compress -Depth 12 | Set-Content -LiteralPath $temporary -Encoding UTF8
    Move-Item -LiteralPath $temporary -Destination $script:StatePath -Force
}

function Add-Failure {
    param([string]$Operation, [string]$Path, [System.Exception]$Exception)
    Write-EventLog $script:ChangesLog @{ level = "ERROR"; operation = $Operation; path = $Path; message = $Exception.Message }
}

function Get-NormalizedAjCode {
    param([string]$Name)
    if ($Name -notmatch '^aj(\d+)([a-z]?)$') { throw "Neplatny nazev adresare aj: $Name" }
    return ("{0:D3}{1}" -f [int]$Matches[1], $Matches[2].ToLowerInvariant())
}

function Get-SourceFolderInfo {
    param([System.IO.DirectoryInfo]$Folder)
    if ($Folder.Name -match '^b(\d+)([a-z]?)(?:-(\d+))?$') {
        return [PSCustomObject]@{ Type = "b"; Code = ("{0:D2}{1}" -f [int]$Matches[1], $Matches[2].ToLowerInvariant()); Folder = $Folder }
    }
    if ($Folder.Name -match '^inf(\d+)$') {
        return [PSCustomObject]@{ Type = "inf"; Code = ("{0:D2}" -f [int]$Matches[1]); Folder = $Folder }
    }
    return $null
}

function Get-ScanParts {
    param([string]$BaseName)
    if ($BaseName -notmatch '^(.*?)(\d+)([a-z]*)$') { return $null }
    return [PSCustomObject]@{
        GroupKey = $BaseName.Substring(0, $BaseName.Length - $Matches[2].Length - $Matches[3].Length).ToLowerInvariant() + $Matches[2]
        Variant = $Matches[3].ToLowerInvariant()
    }
}

function Get-TargetName {
    param([string]$AjCode, [PSCustomObject]$FolderInfo, [int]$Number, [string]$Variant)
    if ($FolderInfo.Type -eq "inf") { return "NAD1261_008_{0}_inf_{1}_{2:D4}{3}.jpg" -f $AjCode, $FolderInfo.Code, $Number, $Variant }
    return "NAD1261_008_{0}_{1}_{2:D4}{3}.jpg" -f $AjCode, $FolderInfo.Code, $Number, $Variant
}

if (-not (Test-Path -LiteralPath $Root -PathType Container)) { throw "Zadana cesta neexistuje: $Root" }
if ($Mode -eq "Test" -and [string]::IsNullOrWhiteSpace($DestinationRoot)) {
    $DestinationRoot = Join-Path (Split-Path -Parent $Root) ("{0}_test" -f (Split-Path -Leaf $Root))
}
if ($Mode -eq "Test" -and [IO.Path]::GetFullPath($DestinationRoot).TrimEnd("\") -eq [IO.Path]::GetFullPath($Root).TrimEnd("\")) { throw "Testovaci cil musi byt odlisny od zdroje." }

$null = New-Item -Path $LogDirectory -ItemType Directory -Force
$script:ChangesLog = Join-Path $LogDirectory "rename_changes.log"
$script:IgnoredLog = Join-Path $LogDirectory "ignored_files.log"
$script:StatePath = Join-Path $LogDirectory "rename_state.log"
$state = @{ mode = $Mode; root = $Root; completed = @{}; groupNumbers = @{}; status = "RUNNING" }

if ($Mode -ne "Check" -and (Test-Path -LiteralPath $StatePath)) {
    try { $saved = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json } catch { Add-Failure "load-state" $StatePath $_.Exception; $saved = $null }
    if ($null -ne $saved -and $saved.root -eq $Root -and $saved.mode -eq $Mode) {
        foreach ($property in $saved.completed.PSObject.Properties) { $state.completed[$property.Name] = $property.Value }
        foreach ($property in $saved.groupNumbers.PSObject.Properties) { $state.groupNumbers[$property.Name] = [int]$property.Value }
    }
}

$ajFolders = @(Get-ChildItem -LiteralPath $Root -Directory -Force -ErrorAction Stop | Where-Object { $_.Name -match '^aj\d+[a-z]?$' } | Sort-Object Name)
foreach ($aj in $ajFolders) {
    try {
        $ajCode = Get-NormalizedAjCode $aj.Name
        $sourceFolders = @(Get-ChildItem -LiteralPath $aj.FullName -Directory -Force -ErrorAction Stop | ForEach-Object { Get-SourceFolderInfo $_ } | Where-Object { $null -ne $_ } | Sort-Object { $_.Folder.Name })
        foreach ($folderInfo in $sourceFolders) {
            $sourceFolder = $folderInfo.Folder
            $sourceFolderPath = $sourceFolder.FullName
            $normalizedName = $sourceFolder.Name -replace '-\d+$', ''
            $isRange = $folderInfo.Type -eq "b" -and $sourceFolder.Name -ne $normalizedName
            $destinationFolder = $sourceFolderPath

            if ($isRange -and $Mode -eq "Rename") {
                $destinationFolder = Join-Path $sourceFolder.Parent.FullName $normalizedName
                if (Test-Path -LiteralPath $destinationFolder) { Add-Failure "rename-folder-collision" $sourceFolderPath ([Exception]::new("Cilova slozka existuje: $destinationFolder")); continue }
                Rename-Item -LiteralPath $sourceFolderPath -NewName $normalizedName
                Write-EventLog $script:ChangesLog @{ level = "INFO"; operation = "rename-folder"; source = $sourceFolderPath; destination = $destinationFolder }
                $sourceFolderPath = $destinationFolder
            } elseif ($isRange -and $Mode -eq "Test") { $destinationFolder = Join-Path (Join-Path $DestinationRoot $aj.Name) $normalizedName }
            elseif ($Mode -eq "Test") { $destinationFolder = Join-Path (Join-Path $DestinationRoot $aj.Name) $sourceFolder.Name }

            if ($Mode -eq "Test" -and -not (Test-Path -LiteralPath $destinationFolder)) { $null = New-Item -Path $destinationFolder -ItemType Directory -Force; Write-EventLog $script:ChangesLog @{ level = "INFO"; operation = "create-folder"; source = $sourceFolderPath; destination = $destinationFolder } }
            $files = @(Get-ChildItem -LiteralPath $sourceFolderPath -File -Force -ErrorAction Stop | Sort-Object Name)
            foreach ($file in $files | Where-Object { $_.Extension -cne ".jpg" }) { Write-EventLog $script:IgnoredLog @{ level = "IGNORED"; path = $file.FullName; reason = "Pripona neni .jpg" } }
            foreach ($file in @($files | Where-Object { $_.Extension -ceq ".jpg" })) {
                $parts = Get-ScanParts $file.BaseName
                if ($null -eq $parts) { Write-EventLog $script:IgnoredLog @{ level = "IGNORED"; path = $file.FullName; reason = "Nazev neobsahuje cislo skenu" }; continue }
                $key = "$sourceFolderPath|$($parts.GroupKey)"
                if (-not $state.groupNumbers.ContainsKey($key)) {
                    $next = 1
                    $folderPrefix = "$sourceFolderPath|"
                    $usedNumbers = @($state.groupNumbers.GetEnumerator() | Where-Object { $_.Key.StartsWith($folderPrefix) } | ForEach-Object { [int]$_.Value })
                    while ($usedNumbers -contains $next) { $next++ }
                    $state.groupNumbers[$key] = $next
                }
                $targetName = Get-TargetName $ajCode $folderInfo $state.groupNumbers[$key] $parts.Variant
                $targetPath = Join-Path $destinationFolder $targetName
                $operationKey = "$($file.FullName)|$targetPath"
                if ($state.completed.ContainsKey($operationKey)) { continue }
                if ($Mode -eq "Check") { Write-EventLog $script:ChangesLog @{ level = "PLAN"; operation = "rename-file"; source = $file.FullName; destination = $targetPath }; continue }
                if (Test-Path -LiteralPath $targetPath) { Add-Failure "destination-collision" $targetPath ([Exception]::new("Cilovy soubor existuje.")); continue }
                try {
                    if ($Mode -eq "Rename") { Rename-Item -LiteralPath $file.FullName -NewName $targetName } else { $null = New-Item -Path $targetPath -ItemType File -Force }
                    $state.completed[$operationKey] = $true
                    Write-EventLog $script:ChangesLog @{ level = "INFO"; operation = $(if ($Mode -eq "Rename") { "rename-file" } else { "create-file" }); source = $file.FullName; destination = $targetPath }
                    Write-State $state
                } catch { Add-Failure $(if ($Mode -eq "Rename") { "rename-file" } else { "create-file" }) $file.FullName $_.Exception; Write-State $state }
            }
        }
    } catch { Add-Failure "scan-aj" $aj.FullName $_.Exception }
}

$state.status = "COMPLETED"
Write-State $state
Write-Host "Rezim $Mode dokoncen. Logy: $LogDirectory"