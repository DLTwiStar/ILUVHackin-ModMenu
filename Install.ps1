param(
    [ValidateSet('Plutonium','Steam','Both')][string]$Target = 'Plutonium',
    # Optional override: the folder containing BlackOpsMP.exe. Normally detected automatically.
    [string]$Bo1Root = ''
)
$ErrorActionPreference = 'Stop'
function Get-ModHash([string]$Path) {
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    try { return [Convert]::ToBase64String($hasher.ComputeHash([IO.File]::ReadAllBytes($Path))) }
    finally { $hasher.Dispose() }
}

# Accepts a BO1 folder or the path to BlackOpsMP.exe; returns the normalized folder or $null.
function Resolve-Bo1Root([string]$Path) {
    if (!$Path) { return $null }
    $Path = $Path.Trim().Trim('"').Trim()
    if (!$Path) { return $null }
    try {
        if (Test-Path -LiteralPath $Path -PathType Leaf) { $Path = [IO.Path]::GetDirectoryName($Path) }
        if (Test-Path -LiteralPath (Join-Path $Path 'BlackOpsMP.exe') -PathType Leaf) {
            return (Get-Item -LiteralPath $Path).FullName.TrimEnd('\')
        }
    } catch { }
    return $null
}

function Get-RegValue([string]$Key, [string]$Name) {
    try { return (Get-ItemProperty -LiteralPath $Key -Name $Name -ErrorAction Stop).$Name } catch { return $null }
}

# Every BO1 multiplayer install that can be found, most authoritative source first.
function Find-Bo1Roots {
    $candidates = New-Object System.Collections.Generic.List[string]

    # 1. Plutonium launcher records the game folder it was pointed at.
    $plutoConfig = Join-Path $env:LOCALAPPDATA 'Plutonium\config.json'
    if (Test-Path -LiteralPath $plutoConfig) {
        try { $candidates.Add((Get-Content -LiteralPath $plutoConfig -Raw | ConvertFrom-Json).t5Path) } catch { }
    }

    # 2. Steam's uninstall entry for Black Ops (app 42700).
    foreach ($hive in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall') {
        $candidates.Add((Get-RegValue "$hive\Steam App 42700" 'InstallLocation'))
    }

    # 3. Every Steam library listed by the Steam client.
    $steamRoots = @(
        (Get-RegValue 'HKCU:\Software\Valve\Steam' 'SteamPath'),
        (Get-RegValue 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' 'InstallPath'),
        (Get-RegValue 'HKLM:\SOFTWARE\Valve\Steam' 'InstallPath')
    ) | Where-Object { $_ }
    $libraries = New-Object System.Collections.Generic.List[string]
    foreach ($steam in $steamRoots) {
        $libraries.Add($steam)
        $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            # Matches both the current ("path" "X:\\Lib") and legacy ("1" "X:\\Lib") formats.
            foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"(?:path|\d+)"\s+"([^"]*[\\/][^"]*)"')) {
                $libraries.Add($m.Groups[1].Value.Replace('\\', '\'))
            }
        }
    }

    # 4. Common library locations on every local drive, for installs Steam no longer lists.
    foreach ($drive in Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue) {
        if (!$drive.Root) { continue }
        foreach ($sub in 'SteamLibrary', 'Steam', 'Program Files (x86)\Steam', 'Program Files\Steam', 'Games\Steam', 'Games\SteamLibrary', 'Games') {
            $libraries.Add((Join-Path $drive.Root $sub))
        }
    }

    foreach ($lib in $libraries) {
        foreach ($common in (Join-Path $lib 'steamapps\common'), $lib) {
            if (!(Test-Path -LiteralPath $common -PathType Container)) { continue }
            # BO2/BO3 folders also match this pattern; they are rejected because they lack BlackOpsMP.exe.
            Get-ChildItem -LiteralPath $common -Directory -Filter 'Call of Duty*Black Ops*' -ErrorAction SilentlyContinue |
                ForEach-Object { $candidates.Add($_.FullName) }
        }
    }

    $found = New-Object System.Collections.Generic.List[string]
    foreach ($c in $candidates) {
        $root = Resolve-Bo1Root $c
        if ($root -and !($found | Where-Object { $_ -eq $root })) { $found.Add($root) }
    }
    return $found.ToArray()
}

$modName = 'mp_iluvhackin'
$source = Join-Path $PSScriptRoot "mods\$modName\mod.ff"
if (!(Test-Path -LiteralPath $source -PathType Leaf)) { throw 'Extract the entire ZIP before running the installer. mod.ff is missing.' }
$destinations = @()
if ($Target -in @('Plutonium','Both')) {
    $destinations += Join-Path $env:LOCALAPPDATA "Plutonium\storage\t5\mods\$modName"
}
if ($Target -in @('Steam','Both')) {
    $roots = @()
    if ($Bo1Root) {
        $root = Resolve-Bo1Root $Bo1Root
        if (!$root) { throw "BlackOpsMP.exe was not found in: $Bo1Root" }
        $roots = @($root)
    }
    else {
        Write-Host 'Searching for Call of Duty: Black Ops multiplayer...'
        $roots = @(Find-Bo1Roots)
        if ($roots.Count -eq 0 -and [Environment]::UserInteractive) {
            Write-Host 'BO1 multiplayer was not found automatically.'
            while ($roots.Count -eq 0) {
                $answer = Read-Host 'Paste or drag in the folder containing BlackOpsMP.exe (leave blank to skip)'
                if (!$answer) { break }
                $root = Resolve-Bo1Root $answer
                if ($root) { $roots = @($root) } else { Write-Host "BlackOpsMP.exe is not in: $answer" }
            }
        }
    }
    if ($roots.Count -eq 0) {
        $hint = 'Run Install.ps1 with -Bo1Root pointing to the folder containing BlackOpsMP.exe.'
        if ($Target -eq 'Steam') { throw "BO1 multiplayer was not found. $hint" }
        Write-Warning "BO1 multiplayer was not found; skipping the Steam install. $hint"
    }
    foreach ($root in $roots) {
        Write-Host "Found BO1: $root"
        $destinations += Join-Path $root "mods\$modName"
    }
}
foreach ($destination in $destinations) {
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    $targetFile = Join-Path $destination 'mod.ff'
    if (Test-Path -LiteralPath $targetFile) {
        $backup = "$targetFile.backup-$(Get-Date -Format yyyyMMdd-HHmmss-fff)"
        Copy-Item -LiteralPath $targetFile -Destination $backup
        Write-Host "Backup: $backup"
    }
    Copy-Item -LiteralPath $source -Destination $targetFile -Force
    if ((Get-ModHash $source) -ne (Get-ModHash $targetFile)) { throw "Copy verification failed: $targetFile" }
    Write-Host "Installed and verified: $destination"
}
Write-Host 'Load Mods > mp_iluvhackin. Forge is in Miscellaneous; RTD and Nuketown Zombies are in Fun; maps and wager modes are in Admin Menu.'
Write-Host 'Previous mod folders have not been changed.'
