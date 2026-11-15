# steam-backup-iso

Make a personal backup ISO of a Steam game **you own**, prepped with
[ModPrep](https://github.com/DarrellBest/ModPrep) by Darrell Best, without
needing room for a second full copy of the game.

This repo contains scripts only. It contains no game files, and it does not
remove Denuvo or any other DRM beyond what ModPrep does. Keep the ISOs you make
to yourself.

## How it works

1. `prep.ps1` builds a small stand-in Steam library with only the game's
   `.exe`/`.dll` files and runs `modprep-cli prep` on it. ModPrep removes
   SteamStub (if present) and swaps in its Steam API replacement, so the
   prepped folder is about 1 GB, not the full game size.
2. `make_iso.py` writes a UDF 2.60 ISO. The game files are read straight from
   the Steam install (never changed), and ModPrep's changed files replace the
   originals inside the image. `install.cmd` goes in the ISO root.
3. To install: mount the ISO, run `install.cmd`, pick a folder.

Disk space needed: the ISO (about the game's size) plus about 1 GB.

## Usage (Windows)

```powershell
# 1. ModPrep: download the latest release zip from DarrellBest/ModPrep and unzip it.
python -m pip install pycdlib

# 2. Prep the exe/dll files (example: app id 3321460)
.\prep.ps1 -AppId 3321460 -ModPrepCli C:\tools\ModPrep\modprep-cli.exe -Work C:\temp\prep

# 3. Build the ISO (paths printed by prep.ps1)
python -I make_iso.py "D:\SteamLibrary\steamapps\common\<Game>" C:\temp\prep\prepped D:\Backups\Game.iso
```

The prepped `steam_settings` folder holds your Steam account name and SteamID
(so saves match). Don't share the ISO or that folder.

## Verify

Mount the ISO and compare it with the install: same file count (plus the
`steam_settings` files), same sizes, and matching hashes on a few files.

## Credits and license

ModPrep is by Darrell Best (PolyForm Noncommercial 1.0.0 + attribution), not
bundled here. These scripts are MIT licensed.
