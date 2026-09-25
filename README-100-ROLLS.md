# iluvhackin Menu 1.0 menu: 100-roll edition

Extract the entire ZIP. Double-click **Install-Both.cmd** to install for Plutonium and Steam, or **Install-Plutonium.cmd** for Plutonium only. Close BO1 before installing. Load **mp_iluvhackin** from the multiplayer Mods menu and start a local match. Older mod folders are preserved; select this new folder to use this version.

If Windows opens a script in Notepad, use the CMD launcher above. From PowerShell inside the extracted folder you can also run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1 -Target Both -Bo1Root "F:\SteamLibrary\steamapps\common\Call of Duty Black Ops"
```

## Menu and mode

Crouch + Melee opens the menu. Attack scrolls up, ADS scrolls down, Use selects, and Melee goes back.

The mod starts in normal mode. Choose **Fun > Roll the Dice > Start RTD - Restart Match**. The match restarts, then every player receives a random numbered roll on each spawn. Choose **Leave RTD - Restart Match** to return to normal. A fresh map or separate manual restart returns to normal; select RTD again when wanted. Automatic god mode and the menu's universal ammo refill are disabled during RTD.

**Browse Rolls** has ten pages of ten rolls. Selecting a roll displays its description. The roll name and number also appear during play. Rainbow Flash Rounds covers the whole view with a strong colored flash on each shot.

## Bishop and helicopters

Roll #40, Bishop, attempts to spawn a friendly Death Machine bot beside you with 300 HP. It follows using BO1 bot navigation, refills its ammunition, and displays "You can't kill me!" every six seconds. It requires a free player slot and a map/mode that supports stock bots. Team Deathmatch is the recommended first test. Its death or your death removes it.

**The Woods campaign voice recording is not included.** No verified multiplayer alias for that line was found. The recurring line is a caption. If a working, loaded sound alias becomes available, `ng_bishop_voice` can select it; this setting cannot load an arbitrary audio file.

**Fun > Attack Helicopter Pilot** uses BO1's native Gunship pilot controls and the Hind attack-helicopter exterior used by the seven-kill streak. This is an adaptation using the game's pilot system, not a recreation of the Wii helicopter script. **Fun > Chopper Gunner** starts the separate gunner seat. Use these in normal mode, on open ground, with available airspace and helicopter paths on the map. The game supplies its usual control prompts and vehicle exit behavior.

## Verification and first run

The package's fastfile structure and script contents were checked, script references were checked against BO1 scripts, and both installer destinations were tested in isolated folders, including repeat-install backups. A preliminary parser check also passed. These checks do not replace a BO1 map load: **this new 100-roll build has not been tested in-game here**. The earlier 39-roll build was confirmed working by you.

First load a local TDM match, enter RTD from Fun, confirm the restart and numbered roll, then die and confirm a fresh roll. Test leaving RTD and both helicopter entries. For targeted local testing, `set jm_rtd_force 40` selects Bishop on the next spawn; any number 1-100 works. Clear it with `set jm_rtd_force ""` to restore randomness. Starting/leaving RTD clears this override.

If the game reports a script error, retain its exact text. The included source files and verification reports identify this build. Previously installed versions remain available in the Mods menu.

## All 100 rolls

1. **Orgasm** — MP fire screams; repeats until death
2. **Dropped My Glasses** — Blurry vision until death.
3. **On Fire** — 5 burn damage per second
4. **Infinite UAV** — Continuous enemy radar.
5. **Snackbar** — Explode in 30 seconds
6. **Default Weapon** — Equip the default weapon.
7. **Random Killstreak** — Receive a random killstreak.
8. **Bullets Do No Damage** — Your bullet damage is zero
9. **Ricochet Rounds** — Your bullet damage hits you instead
10. **Cement Shoes** — 50% movement speed.
11. **Super Speed** — 150% movement speed.
12. **Tungsten Ballsack** — Double fall damage
13. **Kill Sound Roulette** — Random local sound on every enemy kill
14. **Strength Bonus** — +50% direct weapon damage
15. **The Floor Is Lava** — Starts in 5s; 10 damage per second on ground
16. **Headshots Only** — Your bullets only hurt on headshots
17. **10 Second Aimbot** — Hold ADS: aims at a visible enemy; fire manually
18. **Explosive Rounds** — Every fifth gunshot explodes
19. **L96A1 + Tomahawk** — L96A1 and tomahawk only.
20. **Wallhacks** — Enemy location markers through walls
21. **No Collision** — Hold USE to fly through walls; melee returns you to start
22. **Camera Shake** — Constant camera shake.
23. **Knife Only** — 20 seconds of melee-only damage and empty guns
24. **Unlimited Nades** — Refills equipped frag/semtex, claymore or C4
25. **Thick Skin** — Half incoming damage
26. **Vampire** — Enemy kills heal 30 HP
27. **Glass Cannon** — 1 HP, double direct weapon damage
28. **Tunnel Vision** — A heavily darkened view.
29. **Rainbow Flash Rounds** — Full-screen rainbow flashes with each gunshot.
30. **Gravity Kick on Kill** — Enemy kills launch YOU upward
31. **Disco Tint** — A cycling rainbow tint covers your view.
32. **Crawl Pace** — 25% movement speed.
33. **Drunk Sway** — Your camera sways.
34. **Everyone Hears You** — Loud positional beeps give you away.
35. **Random Teleport** — YOU move to a free map spawn after 3 seconds
36. **Turnaround** — Your view turns 180 degrees every 6 seconds
37. **Cartoon Bounce** — You bounce automatically.
38. **Dance Spin** — Your camera spins for 3 seconds.
39. **Raybow** — Equip an explosive crossbow.
40. **Bishop** — A Death Machine bodyguard follows you.
41. **Juggernaut** — 300 HP, 70% speed.
42. **Speed Demon** — Double movement speed.
43. **Snail Mail** — 15% movement speed.
44. **Regenerator** — Heal 8 HP every second.
45. **Poison Ivy** — Lose 3 HP every second.
46. **Bloodsucker** — Weapon hits heal you for 20% of damage.
47. **Thorns** — Return 25% of incoming enemy weapon damage.
48. **Damage Dice** — Every weapon hit does 25%-200% damage.
49. **Critical Mass** — One in five weapon hits does triple damage.
50. **First One Is Free** — Your first damaging hit is absorbed.
51. **Second Wind** — Survive one fatal hit at 1 HP.
52. **Mercy Rule** — Your weapon hits cannot finish an enemy.
53. **Executioner** — Weapon hits finish enemies below 30 HP.
54. **Medical Malpractice** — Your bullets heal enemies instead of hurting them.
55. **Blood Donor** — Enemies that hit you regain 15 HP.
56. **Heavy Caliber** — Double bullet damage, 70% speed.
57. **Featherweight** — 170% speed, take 50% more damage.
58. **Moon Boots** — Your jumps receive an extra upward boost.
59. **Anchor Management** — You stop moving for 2 seconds out of every 8.
60. **Blink And You Miss It** — Teleport to a free map spawn every 15 seconds.
61. **Hit And Run** — An enemy kill triggers a teleport.
62. **Return To Sender** — Return to your roll starting position every 15 seconds.
63. **Supply Fairy** — Enemy kills award a random killstreak.
64. **Weapon Roulette** — Receive a different primary weapon every 15 seconds.
65. **Pistol Party** — Python revolver only.
66. **Rocket Man** — RPG only, with periodic ammo refills.
67. **Silent Runner** — 125% speed and suppressed MP5K.
68. **Boomstick** — Olympia only, with double direct damage.
69. **Death Machine** — Equip the minigun with endless ammunition.
70. **Grim Reaper** — Equip the M202 with ammo refills.
71. **Crossbow Club** — Explosive crossbow only.
72. **Ballistic Ballet** — Ballistic knife, 150% speed.
73. **Kalashnikov King** — AK-47 with 25% bonus damage.
74. **Rambo** — M60, 200 HP, 85% speed.
75. **Scavenger King** — Enemy kills refill your weapons.
76. **Dry County** — No reserve ammunition.
77. **Bottomless Pockets** — All carried weapons refill every half-second.
78. **One Bullet Wonder** — Exactly one bullet in your current gun after each shot.
79. **Blood Ammunition** — Each shot costs 2 HP.
80. **Rocket Boots** — USE launches you upward; 3-second cooldown.
81. **Recoil Rocket** — Shots push you backward.
82. **Punch Rounds** — Bullet hits launch enemies away.
83. **Sky Rounds** — Bullet hits toss enemies into the air.
84. **Frost Rounds** — Bullet hits slow an enemy for 0.75 seconds.
85. **Ammo Thief** — Bullet hits remove five rounds from the victim's clip.
86. **Rattle Rounds** — Bullet hits shake the victim's camera.
87. **Fight Or Flight** — Double speed whenever an enemy is within 450 units.
88. **Berserker** — Triple direct damage below 30 HP.
89. **Victory Fireworks** — Enemy kills create a harmless explosion effect.
90. **Confetti Cannon** — Enemy kills splash your screen with color.
91. **Hulk Smash** — Crouch + USE launches you; take no fall damage.
92. **Cinema Club** — Letterboxed vision for your whole life.
93. **Green Machine** — Green-tinted vision and 125% speed.
94. **Red Alert** — Your screen pulses red, faster at low health.
95. **Disco Aim** — Every shot rotates your view 25 degrees.
96. **Gravity Well** — Pull nearby enemies toward you.
97. **Repulsor** — Push nearby enemies away.
98. **Healing Aura** — Heal yourself and nearby teammates.
99. **Plague Bearer** — Nearby visible enemies take 3 damage per second.
100. **Jackpot** — 200 HP, 150% speed, infinite ammo, life-steal.
