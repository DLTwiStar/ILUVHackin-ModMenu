# iluvhackin Menu 1.0

Black Ops 1 multiplayer mod — release 1.0.

## Install for Plutonium

1. Close BO1 and extract the entire ZIP.
2. Run **Install-Plutonium.cmd**. It automatically uses your Windows user folder.
3. Launch Plutonium BO1 multiplayer and select **Mods > mp_iluvhackin**.
4. Start a local match. The welcome message reads **iluvhackin Menu | 1.0**.

Previous mod folders are preserved. Select mp_iluvhackin to use this release.

## Steam or both installations

Open PowerShell in the extracted folder and run the following, replacing the example path with the folder containing your BlackOpsMP.exe:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1 -Target Both -Bo1Root "D:\SteamLibrary\steamapps\common\Call of Duty Black Ops"
```

Use -Target Steam for Steam only. Install-Both.cmd automatically checks the original F: installation paths; use the command above for other locations.

## Menu controls

Crouch + melee opens the menu. Attack moves up, aim moves down, Use selects, and melee goes back. The host receives host permissions; other players start as Scrub.

## Release changes

Renamed the menu, welcome message, scrolling banner, and Mods entry to iluvhackin Menu / mp_iluvhackin. All gameplay features from the previous package are retained. No Recoil remains removed.

Original menu foundation: Nity. Nuketown Survival: CheeseToast, from the supplied King of Hax menu. RTD V2: the supplied King of Hax/JellyInjector source.

Package contents, script references, installer copies/backups, and ZIP integrity were checked. This renamed release has not been tested in BO1/Plutonium.
