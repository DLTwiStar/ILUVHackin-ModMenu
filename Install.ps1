param(
    [ValidateSet('Plutonium','Steam','Both')][string]$Target = 'Plutonium',
    [string]$Bo1Root = ''
)
$ErrorActionPreference = 'Stop'
function Get-ModHash([string]$Path) {
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    try { return [Convert]::ToBase64String($hasher.ComputeHash([IO.File]::ReadAllBytes($Path))) }
    finally { $hasher.Dispose() }
}
$modName = 'mp_iluvhackin'
$source = Join-Path $PSScriptRoot "mods\$modName\mod.ff"
if (!(Test-Path -LiteralPath $source -PathType Leaf)) { throw 'Extract the entire ZIP before running the installer. mod.ff is missing.' }
$destinations = @()
if ($Target -in @('Plutonium','Both')) {
    $destinations += Join-Path $env:LOCALAPPDATA "Plutonium\storage\t5\mods\$modName"
}
if ($Target -in @('Steam','Both')) {
    if (!$Bo1Root) {
        $candidates = @('F:\SteamLibrary\steamapps\common\Call of Duty Black Ops', 'F:\SteamLibrary\steamapps\common\Call of Duty Black Ops 42740')
        foreach ($candidate in $candidates) {
            if (Test-Path -LiteralPath (Join-Path $candidate 'BlackOpsMP.exe')) { $Bo1Root = $candidate; break }
        }
    }
    if (!$Bo1Root -or !(Test-Path -LiteralPath (Join-Path $Bo1Root 'BlackOpsMP.exe'))) {
        throw 'BO1 multiplayer was not found. Run Install.ps1 with -Bo1Root pointing to the folder containing BlackOpsMP.exe.'
    }
    $destinations += Join-Path $Bo1Root "mods\$modName"
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
