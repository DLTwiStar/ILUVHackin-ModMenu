# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**iluvhackin Menu 1.0** is a Call of Duty: Black Ops 1 (T5) multiplayer mod menu written in GSC. It started as a PC port of the Wii mod menu "Nity's Mod Menu V.1" and was extended with extra modes: Roll the Dice (100 rolls), RTD V2 (JellyInjector's 81 rolls, from King of Hax), Nuketown Zombies/Infection (CheeseToast), Bounty Relay, Forge, Play-As forms, VIP powers, and admin/map tools. It targets Plutonium T5 and Steam BO1, and runs only in private or local matches. The host's script VM runs all of the logic.

## Build, install, test

- **No build tooling is included in this repo.** The game loads `mods/mp_iluvhackin/mod.ff`, a compressed T5 fastfile (`IWffu100` header) that holds every file listed in `mod.csv`/`mod.zone` as a `rawfile`. **Editing a `.gsc` changes nothing in-game until `mod.ff` is rebuilt** with an external T5 fastfile linker. When you add a script or asset, add it to both `mod.csv` and `mod.zone` (they must stay identical, apart from the `>game,T5` header line in `mod.zone`).
- `build-verification.json` and `verification.json` record the checks run on the last build (fastfile round-trip, script references). The runtime/gameplay test is always recorded as `NOT RUN`. The parser used for those checks used T6 grammar, not BO1's compiler, so a passing check does not prove the scripts compile in BO1.
- Install (copies `mod.ff`, backs up any existing one, and verifies the copy by SHA-256):
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1 -Target Plutonium          # %LOCALAPPDATA%\Plutonium\storage\t5\mods\mp_iluvhackin
  powershell -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1 -Target Both -Bo1Root "<folder containing BlackOpsMP.exe>"
  ```
  `Install-Plutonium.cmd` and `Install-Both.cmd` are double-click wrappers. `Install.ps1` must stay compatible with Windows PowerShell 5.1, because the `.cmd` files launch `powershell`, not `pwsh`. Without `-Bo1Root`, `Find-Bo1Roots` looks for BO1 in this order:
  1. `t5Path` in `%LOCALAPPDATA%\Plutonium\config.json`
  2. Steam's `Steam App 42700` uninstall key
  3. Every library in Steam's `libraryfolders.vdf`
  4. Common folders on every drive

  Any folder that contains `BlackOpsMP.exe` counts as a match. The mod is installed into every match found. If there are none, the installer asks for the folder when run interactively. `-Target Both` then falls back to installing for Plutonium only.
- There are no unit tests or lint. The only real test is in-game: load **Mods > mp_iluvhackin**, start a local match (TDM recommended), open the menu with crouch + melee, then check the console for script errors.
- Debug dvars: `set jm_rtd_force <1-100|rollId>` forces an RTD roll on the next spawn; `set ng_rtd_v2_force <1-81>` does the same for V2. Switching modes clears both.

## Script layout and load path

Everything lives under `mods/mp_iluvhackin/`:

- `maps/mp/gametypes/_callbacksetup.gsc` overrides the stock file and is **the only entry point**. `CodeCallback_StartGameType` threads `common_scripts\jellymod::init()`. `CodeCallback_PlayerDamage` and `CodeCallback_PlayerKilled` form the damage/kill pipeline that every mode hooks into (see below).
- `common_scripts/jellymod.gsc` is the original Wii menu core. It holds `init()` (which calls every other module's `init()`, **in order**), the per-player spawn loop, button monitors, `runMenu`/`changeMenu`/`closeModMenu`, and the large `runFunc(input)` switch.
- `ng_*.gsc` are newer modules, each exposing `init()` and usually `route(input)`:
  - `ng_menu`: renders the menu, handles on/off state colouring and back-navigation history.
  - `ng_access`: roles, permissions, player list and player actions.
  - `ng_admin`: map and gametype changes, the transition controller, and bots.
  - `ng_forge`: props, grabbing, phase/noclip, and scripted collision.
  - `ng_forms`: Play as a Car or Dog.
  - `ng_vip`: VIP powers.
  - `ng_visuals`: spiral tracers and Wii Graphics, both restorable.
  - `ng_nuketown`: Nuketown Zombies.
  - `ng_bounty`: Bounty Relay.
- `nitys_rtd.gsc` handles RTD mode and switches the mode dvar at load. `niggy_extra.gsc` holds RTD rolls 40–100. `niggy_rtd_v2.gsc` is JellyInjector's RTD V2, kept mostly verbatim. `niggy_fun.gsc` has the mode-switch helpers, the roll browser and the helicopters.
- `animtrees/ng_forms.atr` holds the dog animations used by `#using_animtree("ng_forms")`.

Modules call each other with fully qualified paths (`common_scripts\ng_access::rank()`), never with `#include` of sibling modules.

## Core architecture

### Menu dispatch is string-keyed
Each menu page is `changeMenu(id, title, "Opt A|Opt B|...")`. Selecting an option calls `jellymod::runFunc(<option text>)`. **The option's display text is its dispatch key.** `runFunc` checks handlers in this order:

1. Confirm/back keywords (`Previous Screen`, `No - Go Back`, `Yes - Restart Now`)
2. The form lock (`ng_formActive`)
3. `ng_access::allowed(input)`, the permission gate
4. `ng_forms::route`
5. `ng_access::route`, which chains into `ng_vip::route`, then `ng_admin::route`, then `ng_forge::route`
6. `#N` roll-browser entries
7. The legacy `switch` in `runFunc`

Each `route()` returns `true` once it has consumed the input.

Adding or renaming an option usually means updating **several string lists that must agree**:
- the option list passed to `changeMenu`
- the handler (`route`/`case`)
- `ng_access::allowed()`: either the view-only navigation list, or the rank-gated action lists
- `ng_menu::label()`: its list of submenu entries decides whether the prefix is `>` (submenu) or `*` (action)
- `ng_menu::state()`, if the option is an on/off toggle

Dynamic options encode an index in the text and are parsed back out: `Player #i name`, `Drive/Play #i name`, `Car Prop #i ...`, `Streak Prop #i ...`, `Map: <name>`, `#N rollname`.

Menu page IDs used so far: 1–5, 7–11, 14–19, 21–33, 40. `changeMenu` pushes the previous page onto `self.ng_history` for Back, and appends `Previous Screen` to every page except page 1.

### Roles
`ng_access::rank()` returns 0 Scrub, 1 The new guy, 2 VIP, 3 Cohost, 4 Host. The host is always 4; everyone else is stored in `self.pers["ng_role"]`. Most actions need rank 3 or higher. Each module re-checks rank itself, not just through `allowed()`. The host is protected from player actions. Roles are only granted through the in-game Permissions menu.

### Game modes: the `jm_rtd` dvar
`jm_rtd` sets the mode: 0 normal, 1 RTD, 2 RTD V2, 3 Nuketown Zombies, 4 Bounty Relay. Level variables do not survive a map load, so mode changes pass state through dvars:

1. `niggy_fun::switchMode` or `ng_admin::change` calls `requestChange`, which opens the confirm page (32).
2. `confirmChange` sets `level.ng_transition`.
3. The level thread `ng_admin::transitionController` stops forms, VIP and visuals, restores mode dvars, sets `ng_rtd_nextmode` and `g_gametype`, then calls `map_restart` (same map and gametype) or `map()`.
4. On the next load, `nitys_rtd::init` turns `ng_rtd_nextmode` into `jm_rtd` and clears it. **Any other load (fresh map, manual restart) resets to normal mode.**

Because of this, `nitys_rtd::init` must run before `ng_nuketown`, `ng_bounty` and the `jm_rtd==2` V2 init in `jellymod::init`. Keep that order.

Modes that change stock dvars save them to `ng_nz_saved_<i>`/`ng_br_saved_<i>` and set `ng_nz_restore`/`ng_br_restore`. `restoreDvars()` restores them on `game_ended`, before a transition, and at the next `init`.

Host auto-Godmode and Infinite Ammo (`ng_access::hostDefaults`), VIP powers and Play-As are all disabled whenever `jm_rtd != 0` or a wager gametype (`gun|oic|hlnd|shrp`) is active.

### Damage and kill pipeline
`_callbacksetup::CodeCallback_PlayerDamage` runs these checks in order:

1. The Nuketown intermission blocks damage.
2. The Forge Python never deals damage.
3. Admin godmode blocks damage.
4. VIP no-fall blocks fall damage.
5. The VIP aimbot upgrades eligible hits to headshots.
6. If `jm_rtd==2`, the hit goes to `niggy_rtd_v2::Callback_PlayerDamage`. Otherwise it goes to `nitys_rtd::damage`, then `niggy_extra::modifyDamage`.

Each of those finally calls `[[level.callbackPlayerDamage]]`, the stock handler. Scripted damage, such as the dog bite in `ng_forms`, calls `CodeCallback_PlayerDamage` directly so the same rules apply.

`CodeCallback_PlayerKilled` removes duplicate engine deaths using `self.ng_deathDispatched`, which is reset on `"spawned"`. It then calls `ng_vip::onKill`, then the kill hook for the active mode, then the stock handler.

### Per-player lifecycle
`jellymod::OnPlayerSpawned` runs once per connection (`playerVars`, `ng_access::setup`) and then loops on `spawned_player`. Each spawn it:
- closes the menu and releases Forge grabs
- starts the life-scoped Forge workers (`guardProps`, `grabLoop`, `propShots`, `lockLoadout`)
- starts the RTD roll (`nitys_rtd::spawnRoll`)
- starts the menu monitors

Life-scoped threads use `endon("death")`. Mode and feature cleanup hangs off `death`, `disconnect`, `game_ended`, `spawned`, `joined_team` and the feature's own notify (`rtd_stop`, `ng_form_end`, `ng_forge_stop`, `stop_noclip`, `exit_menu`). When you add a stateful feature, give it a cleanup function that is safe to call more than once. Then wire that function into these events and into `transitionController`.

### RTD roll data is duplicated
The 100 RTD rolls exist in parallel, in order, across:
- `nitys_rtd::rollIds()`, `rollNames()` and `rollHints()`
- the `switch` in `spawnRoll`, which covers rolls 1–39
- `niggy_extra::apply()`/`cleanup()`, which cover rolls 40–100 and track state in `self.ng_*` fields
- `rolls.json` and the list in `README-100-ROLLS.md`

When you add, remove or reorder a roll, update all of them. The roll number is its array index + 1. `RTD-V2-ROLLS.md` lists the separate V2 rolls, whose count is set by `level.rollCount=81`.

## GSC / BO1 conventions and gotchas

- Avoid unary minus on expressions. Earlier builds hit a BO1 compiler regression with it, so the code writes `(0-bound-position)` and `*-1` (see `ng_forge::segmentHit`). Negative numeric literals in calls are fine.
- Precache everything in `init()`. `precacheModel`, `precacheItem`, `precacheShader` and `loadfx` can't be called at runtime on PC. The Wii original precached nothing.
- Pass player names through `ng_access::safeName()` before putting them into menu strings. It strips `^` colour codes and replaces `|` and newlines, because `|` separates menu options.
- Menu button mapping: attack = Up, ADS = Down, use = Select, melee = Back/close. Crouch + melee opens the menu. Each monitor waits for its button to be released first, so a press can't carry over into the next page.
- `jellymod::statEditorApply` and `derankPlayer` write **permanent** profile stats (`setdstat` + `UploadStats`).
- The legacy `switch` in `jellymod::runFunc` only runs for inputs that no `route()` consumed. Adding a `case` there for a string a `route()` already handles creates unreachable code, so put new behaviour in the `ng_*` modules. Unreachable Wii code (the level-notify player monitors, the old UFO/noclip/forge implementations, the RTD V2 in-game kick menu and intro) was removed in the dead-code cleanup. Don't restore it from git history.
- The Wii-era dvar toggles `Vision` and `Sexy Graphics` change client dvars and never restore them. `ng_visuals` shows the restorable pattern: save the old values, restore them on toggle-off, disconnect, `game_ended` and transitions.
- `README.md`, `README-LATEST.md` and `README-UPDATE.md` are identical release notes. `README-CHAOS.md` documents the newest features (wager modes, Infection rounds, Forge collision, tracers, Wii Graphics, Bounty Relay) and what still needs in-game testing.
