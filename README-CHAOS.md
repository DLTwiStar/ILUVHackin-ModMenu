# iluvhackin Menu 1.0 — Chaos Update 3

Close BO1, extract this ZIP, and run **Install-Plutonium.cmd** (or **Install-Both.cmd** for Steam too). Load **Mods > mp_iluvhackin**. The spawn message should say **iluvhackin Menu | 1.0**. The installer backs up the previous fastfile.

## Changes in this build

**Wager modes:** a native game-type change now takes the full map-load path, even when keeping the same map. Previously that situation took the fast-restart path. Yes/No confirmation and Previous Screen remain. Gun Game, One in the Chamber, Sticks and Stones, and Sharpshooter use the stock game rules, with COD Point bets disabled.

**Nuketown Infection:** start through **Fun > Nuketown Zombies**. Survivors spawn inside the original survival house; zombies spawn at its exterior yard anchor, with offsets to reduce player stacking. Every round lasts up to two minutes. All survivors infected means a zombie win; survivors remaining at the time limit means a survivor win. After a five-second break, another round begins with a new random selection of 3–4 starting zombies, reduced for small lobbies to leave a survivor. Cash and purchased perks reset for the fresh round. Zombie kills still convert survivors at respawn. Late joiners become zombies. The match continues until you choose to leave the mode.

The 28 house barricades and six perk/ammo/mystery care packages are registered as locked collision objects. The same movement checks used by phasing now include them. They cannot be grabbed, deleted, or bypassed using Forge's phase movement. Native solid spawning remains enabled as well. The scripted collision envelopes approximate the crate models, so their edges and spawn placement still need a live collision test.

**Forge:** grabbing still uses the direct movement that worked in Controls Fix 2. Held props no longer receive repeated `moveTo` commands. Their movement is capped to short steps, and collision is temporarily disabled while dragging to avoid pushing/flinging nearby players. Dropping the prop restores solidity. Locked Nuketown barricades are never eligible for dragging. Grabbed players retain their direct movement and emergency-release watchdog.

**Spiral Bullet Tracers:** the earlier scripted particle effects are removed. The toggle now uses BO1's native `cg_tracerScrewDist` and `cg_tracerScrewRadius` controls, plus tracer visibility, width, speed and length settings. These setting names were verified in the installed multiplayer executable. This is a viewing setting for normal bullet tracers; it does not create a projectile trail for grenades or rockets. Other clients use their own tracer settings. Toggle off restores the captured values (the host's original values; remote clients restore the server-side baseline). Exact color/shape and whether Plutonium accepts every setting still need in-game verification.

**Wii Graphics:** **Fun > Wii Graphics** applies flat lighting, low-detail models, a strong texture mip bias, flat normal maps, no specular contribution, and no depth of field. It is a local-host toggle so the actual original graphics values can be captured. Toggle off restores those values. Menu-driven map/mode changes restore graphics and tracer settings before loading. Some renderer settings may be restricted by the engine; the code does not enable server cheats or edit your configuration files. Turn the toggle off before quitting if you want to be certain the old settings are restored.

## Original mode: Bounty Relay

Select **Fun > Bounty Relay > Start Bounty Relay**, then confirm. It loads Free For All on the current map.

- One living player receives a gold waypoint: the bounty.
- The carrier earns one point per second while at least one opponent is present.
- Kill the carrier to steal the bounty. Each player keeps their own accumulated points during the round.
- A suicide, environmental death, or disconnect makes the game choose another living carrier.
- First to 60 points wins. After five seconds, scores reset and another round begins.
- **Leave Bounty Relay** returns to the base menu with Free For All rules.

The host's automatic Godmode and Infinite Ammo remain disabled in RTD, Infection, Bounty Relay and all four wager modes. Both RTD roll lists are preserved. Existing permission and player-management options remain.

## Verification

The scripts passed the available preliminary parser, cross-script reference checks, and the previous BO1 unary-minus syntax regression scan. Reload routing and capped movement were checked with modeled cases. The real installer was tested in isolated folders, including replacement backups. The package's fastfile was built and decoded back to all source scripts.

**This build has not been run in BO1/Plutonium.** The parser uses T6 grammar, not BO1's runtime compiler. Native mode loading, round transitions, house/yard placement, collision, dragging, tracer appearance and graphics changes require an in-game test. See `verification.json` for the precise scope of checks.

Original menu foundation: Nity. Nuketown Survival: CheeseToast, from the supplied King of Hax menu. RTD V2: the supplied King of Hax/JellyInjector source. Bounty Relay is the new mode created for this update.
