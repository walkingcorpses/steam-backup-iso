# prep.ps1 - run ModPrep on only the .exe/.dll files of a Steam game.
# ModPrep normally copies the whole game. Here it gets a small stand-in Steam
# library holding just the executables and DLLs, so the prepped folder stays
# small; make_iso.py then lays it over the real install.
# Usage: .\prep.ps1 -AppId 3321460 -ModPrepCli C:\tools\modprep-cli.exe -Work C:\temp\prep
param(
    [Parameter(Mandatory)][string]$AppId,
    [Parameter(Mandatory)][string]$ModPrepCli,
    [Parameter(Mandatory)][string]$Work,
    [string]$SteamRoot = (Get-ItemProperty HKCU:\Software\Valve\Steam).SteamPath
)
$ErrorActionPreference = 'Stop'

# Find the library holding the app manifest.
$libs = Select-String -Path "$SteamRoot\steamapps\libraryfolders.vdf" -Pattern '"path"\s+"(.+)"' |
    ForEach-Object { $_.Matches[0].Groups[1].Value -replace '\\\\', '\' }
$manifest = $libs | ForEach-Object { "$_\steamapps\appmanifest_$AppId.acf" } | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $manifest) { throw "App $AppId is not installed." }
$installDir = (Select-String -Path $manifest -Pattern '"installdir"\s+"(.+)"').Matches[0].Groups[1].Value
$game = Join-Path (Split-Path $manifest) "common\$installDir"

# Stand-in library: manifest, login info (so ModPrep keeps your SteamID for saves), exe/dll files.
$fake = "$Work\fakesteam"; $fakeGame = "$fake\steamapps\common\$installDir"
New-Item -ItemType Directory -Force "$fake\config", $fakeGame | Out-Null
Copy-Item "$SteamRoot\config\loginusers.vdf" "$fake\config\"
Copy-Item $manifest "$fake\steamapps\"
$p = $fake.Replace('\', '\\')
Set-Content "$fake\steamapps\libraryfolders.vdf" -Encoding ascii -Value "`"libraryfolders`"`n{`n`t`"0`"`n`t{`n`t`t`"path`"`t`t`"$p`"`n`t`t`"apps`"`n`t`t{`n`t`t`t`"$AppId`"`t`t`"0`"`n`t`t}`n`t}`n}"
Get-ChildItem $game -Recurse -File | Where-Object Extension -in '.exe', '.dll' | ForEach-Object {
    $d = Join-Path $fakeGame $_.FullName.Substring($game.Length + 1)
    New-Item -ItemType Directory -Force (Split-Path $d) | Out-Null
    Copy-Item $_.FullName $d
}

& $ModPrepCli prep $AppId --steam $fake --dest "$Work\prepped"
if ($LASTEXITCODE) { throw "modprep-cli failed ($LASTEXITCODE)" }
"Game:    $game"
"Prepped: $Work\prepped"
