#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

//	iluvhackin Menu 1.0 - PC port
//
//	Original: Wii BO1 "Nity's Mod Menu V.1 Pre-Release" (common_scripts/jellymod.gsc)
//	PC controls:  crouch + [melee] opens.  [attack] up, [ads] down, [use] select, [melee] back.
//
//	Private / unranked lobbies only. Stat writes are permanent on the local profile.

init()
{
	if ( isDefined( level.jm_initialized ) ) return;
	level.jm_initialized = true;
    common_scripts\ng_forge::init();
    common_scripts\ng_forms::init();
    common_scripts\ng_vip::init();
    common_scripts\ng_visuals::init();
    common_scripts\ng_admin::init();
	common_scripts\nitys_rtd::init();
    common_scripts\ng_nuketown::init();
    common_scripts\ng_bounty::init();
    if(getDvarInt("jm_rtd")==2 && !isDefined(level.kh_initialized))
    { level.kh_initialized=true; common_scripts\niggy_rtd_v2::init(); }
	// Wii build precached nothing; on PC an unprecached shader or a runtime loadfx is a crash/hitch.
	PrecacheShader( "black" );

	level._effect[ "jm_expbullet" ] = loadfx( "explosions/fx_exp_aerial" );
	if ( getDvar( "mapname" ) == "mp_nuked" )
		level._effect[ "jm_nuke" ] = loadfx( "maps/mp_maps/fx_mp_nuked_nuclear_explosion" );

	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );
		if(!player isTestClient()) player HUDVariables();
		if(!player isTestClient()) player thread scrollingText(); //trents scroll bar because im lazy
		player thread OnPlayerSpawned();
	}
}


OnPlayerSpawned()
{
	self endon ( "disconnect" );
	self playerVars();
    self common_scripts\ng_access::setup();
	self thread infiniteAmmo();
	// Optional legacy lobby tweaks are deliberately not applied on connect.
	if(!self isTestClient()) self thread status();
	for (;;)
	{
		self waittill ("spawned_player");
		self.rtd_enabled = getDvarInt( "jm_rtd" ) != 0;
        self common_scripts\ng_access::hostDefaults();
        if(isDefined(self.ng_forgeOffhandLock)) { self EnableOffhandWeapons(); self.ng_forgeOffhandLock=undefined; }
		self thread common_scripts\nitys_rtd::spawnRoll();
		self closeModMenu();
		self common_scripts\ng_forge::release();
        self.forgeOn = false;
		self.noclipOn = false;
		self.shootCarePackages = false;
		self.nukeBulletsTog = false;
		self thread jm_deathCleanup();
        self thread common_scripts\ng_forge::guardProps();
        self thread common_scripts\ng_forge::grabLoop();
        self thread common_scripts\ng_forge::propShots();
        self thread common_scripts\ng_forge::lockLoadout();
		if(!self isTestClient()) self thread openMenu();
		if(!self isTestClient()) self thread monitorMenuOpen();
		if(!self isTestClient() && !isDefined(self.jm_welcomed)) self thread showmessage( "^2"+level.hostPlayer+"'s ^1M^2o^3d^4i^5f^6i^7e^8d ^3Lobby", "^7Crouch + Melee to open mod menu", 6);
		self.jm_welcomed=true;
		self iPrintln( "^2iluvhackin Menu ^7| 1.0" );

		if( self jm_isAdmin() )
		{
			// Godmode is controlled explicitly by the VIP/Players options.
			self freezeControls( false );
			self common_scripts\ng_access::updateStatus();
		}
		else
			self common_scripts\ng_access::updateStatus(); // Player actions now use direct per-admin targets.

		if(self.varStatus == "VIP")
		{
			self iPrintlnBold( "^3Welcome ^5V^2I^8P" );
			// Godmode is controlled explicitly by the VIP/Players options.
		}

		self notify( "update_status" );
	}
}

// Host or Cohost role.
jm_isAdmin()
{
    return self common_scripts\ng_access::rank()>=3;
}

//-------------------initialization crap--------------------
playerVars()
{
	temphost = GetHostPlayer();
	if( isDefined( temphost ) )
		level.hostPlayer = temphost.name;
	if( !isDefined( level.hostPlayer ) )
		level.hostPlayer = "Host";

	// Read the profile directly: statGet returns 0 outside ranked matches, and a mod lobby is never ranked.
	self.prestigeToggle = self jm_getStat( "plevel" );
	if( self.prestigeToggle > 15 ) self.prestigeToggle = 15;
	self.killstat = self jm_getStat( "kills" );
	self.deathstat = self jm_getStat( "deaths" );
	self.timeplayed = self jm_getStat( "time_played_total" );
	self.shootCarePackages = false;
	self.nukeBulletsTog = false;
	self.togtimescale = 0;
	self.waxVision = 0;
	self.varStatus = "Normal";
	self.unlockPro = false;
	self.togThird = false;
	self.menuOpen = 0;
	self.forgeOn = false;
	self.noclipOn = false;
	self doScrollText();
}

scrollingText()
{
	self endon( "disconnect" );
	i = 0;

	self.scrollingBar.alpha = 1;

	// doScrollText() is threaded later (from playerVars), so wait for the array to exist.
	while( !isDefined( self.scrollingText ) || self.scrollingText.size == 0 )
		wait 0.5;

	for(;;)
	{
		self.scrollingBar setText( self.scrollingText[i] );
		self.scrollingBar setPoint( "BOTTOMRIGHT", "BOTTOMRIGHT", 1440, 5 );
		self.scrollingBar moveOverTime( 30.00 );
		self.scrollingBar setPoint( "BOTTOMRIGHT", "BOTTOMRIGHT", -1000, 5 );

		wait 30.00;

		i++;
		if( i >= self.scrollingText.size ) i = 0;
	}
}

HUDVariables()
{
	self.scrollingBar = self createFontString( "objective", 1.35 );
	self.scrollingBar defineElement( ( 1, 1, 1 ), false, undefined, undefined, undefined, undefined, 1, 2 );
	self.scrollingShader = newClientHudElem( self );
	self.scrollingShader defineElement( ( 0, 0, 0 ), false, "center", "bottom", 0, 5, 0.7, 1 );
	self.scrollingShader setShader( "black", 820, 20 );
	self thread destroyEvent( self.scrollingShader, "disconnect" );
	self thread destroyEvent( self.scrollingBar, "disconnect" );
}

//----------------------menu-----------------------------------

openMenu()
{
    self endon( "death" );
    self endon( "disconnect" );
    for(;;)
    {
        self waittill( "OpenMenu" );
        self.ng_history=[]; self.ng_currentMenu=undefined;
        self thread changeMenu( 1, "^7iluvhackin ^2Menu 1.0", "Toggle Prestige|Pro Perks|Stats|Killstreaks|Special Guns|Miscellaneous|VIP Menu|Fun|Admin Menu|Close Menu" );
    }
}


runMenu( title, options )
{
	self endon( "death" );
	self endon( "exit_menu" );
	self endon( "disconnect" );
	self notify( "enter_menu" );

	self thread monitorMenuUp();
	self thread monitorMenuDown();
	self thread monitorMenuSelect();
	self thread monitorMenuBack();

	cursPos = 0;
	self.menuOpen = 1;
	menuText = strTok( options, "|" );
	if(getDvarInt("jm_rtd")!=2) self thread enableBlur();
	self DisableWeapons();
	// Keep button polling available; weapon use is disabled while the menu is open.
	if(isDefined(self.ng_adminGod) && self.ng_adminGod) self EnableInvulnerability();
	self setClientUIVisibilityFlag( "hud_visible", 0 );
	self thread menuInstructions();

	titleDisp = self createFontString( "objective", 2.5 );
	titleDisp setPoint( "TOPRIGHT", "TOPRIGHT", 0, 0 );
	titleDisp setText( title );
	self thread destroyEvent( titleDisp, "death", "exit_menu", "disconnect" );
    if(isDefined(self.ng_backCursor)) { cursPos=self.ng_backCursor; self.ng_backCursor=undefined; }
    if(cursPos>=menuText.size) cursPos=0;
    self.ng_cursor=cursPos;
    self thread common_scripts\ng_menu::render(menuText);
    while(self.menuOpen)
    {
		button = self waittill_any_return( "Up", "Down", "Plus", "Left" );
		switch( button )
		{
			case "Up":
				cursPos--;
				break;
			case "Down":
				cursPos++;
				break;
			case "Plus":
				self thread runFunc( menuText[cursPos] );
				break;
			case "Left":
				// Wii build only restored the HUD and weapons here, leaving the player frozen and
				// invulnerable. Back was an obscure button there; on PC it is melee, so close properly.
				self thread common_scripts\ng_menu::back();
				break;
		}
		// wrap instead of the original's snap-back-to-zero
		if( cursPos < 0 ) cursPos = menuText.size - 1;
		if( cursPos >= menuText.size ) cursPos = 0;
        self.ng_cursor=cursPos;
	}
}

runFunc( input )
{
    if(input=="Previous Screen") { self common_scripts\ng_menu::back(); return; }
    if(input=="No - Go Back") { self.ng_pendingChange=undefined; self common_scripts\ng_menu::back(); return; }
    if(input=="Yes - Restart Now") { self common_scripts\ng_admin::confirmChange(); return; }
    if(isDefined(self.ng_formActive) && self.ng_formActive && input!="Exit Form" && input!="Close Menu")
    { self iPrintln("Hold USE / INTERACT to exit your form first."); return; }
    if(!self common_scripts\ng_access::allowed(input)) return;
    if(self common_scripts\ng_forms::route(input)) return;
    if(self common_scripts\ng_access::route(input)) return;
    if(getSubStr(input,0,1)=="#") { self common_scripts\niggy_fun::describe(input); return; }
	switch( input )
	{
		case "Toggle Prestige":
			self iPrintlnBold( "^1"+self.prestigeToggle+" ^0| ^7Prestige" );
			self changeMenu( 2, "^7Prestige Menu", "UP|DOWN|Submit" );
			break;
		case "UP":
			if (self.prestigeToggle<16)
				self.prestigeToggle++;

			if (self.prestigeToggle==16)
				self.prestigeToggle=0;

			self iPrintlnBold( "^1"+self.prestigeToggle+" ^0| ^7Prestige" );
			break;
		case "DOWN":
			if (self.prestigeToggle>-1)
				self.prestigeToggle--;

			if (self.prestigeToggle==-1)
				self.prestigeToggle=15;

			self iPrintlnBold( "^1"+self.prestigeToggle+" ^0| ^7Prestige" );
			break;
		case "Submit":
			self changeMenu( 15, "^1Confirm ^7Stat Write", "Confirm|Cancel" );
			break;
		case "Pro Perks":
			self.unlockPro = true;
			self changeMenu( 15, "^1Confirm ^7Stat Write", "Confirm|Cancel" );
			break;
		case "Confirm":
			self iPrintlnBold( "^7Writing stats..." );
			self thread closeModMenu();
			self thread statEditorApply();
			break;
		case "Cancel":
			self.unlockPro = false;
			self iPrintlnBold( "^7Cancelled" );
			self thread closeModMenu();
			break;
		case "Miscellaneous":
			self changeMenu( 8, "^7Miscellaneous ^2Menu", "Teleport|Suicide|UFO Mode|Noclip|Forge|Vision|3rd Person|Sexy Graphics|Close Menu" );
			break;
		case "Sexy Graphics":
			self setClientDvar("r_specularcolorscale", 0);
			self setClientDvar("r_enablePlayerShadow", 0 );
			self setClientDvar("r_fog", 0 );
			self setClientDvar("r_flashLightShadows", 0 );
			self setClientDvar("r_specular", "1" );
			self setClientDvar("r_contrast", "1" );
			self setClientDvar("r_dlightLimit", 0);
			self setClientDvar("r_desaturation", 0);
			self setClientDvar("r_zfeather", 0);
			self setClientDvar("r_smc_enable", 0);
			self setClientDvar("r_distortion", 0);
			self setClientDvar("sm_enable", 0);
			self setClientDvar("cg_brass", 0 );
			self setClientDvar("r_lighttweaksunlight", "1.57" );
			self setClientDvar("r_dlightLimit", "0" );
			self setClientDvar("snaps", 30 );
			self setClientDvar("r_filmusetweaks", "1" );
			self setClientdvar("r_brightness", "0" );
			self setClientDvar("r_heroLighting", "0" );
			break;
		case "3rd Person":
			if(self.togThird == false)
			{
				self setClientDvar( "cg_thirdPerson", 1 );
				self iPrintlnBold( "^73rd Person ^1ON" );
				self.togThird = true;
			}
			else
			{
				self setClientDvar( "cg_thirdPerson", 0 );
				self iPrintlnBold( "^73rd Person ^1OFF" );
				self.togThird = false;
			}
			break;
		case "Vision":
			self.waxVision++;
			if(self.waxVision > 4)
				self.waxVision = 1;
			if(self.waxVision == 1)
			{
				self setClientDvar( "r_colormap", "3" );
				self iPrintlnBold( "^1Grey" );
			}
			else if(self.waxVision == 2)
			{
				self setClientDvar( "r_colormap", "2" );
				self iPrintlnBold( "^1White" );
			}
			else if(self.waxVision == 3)
			{
				self setClientDvar( "r_filmTweakInvert", "1" );
				self setClientDvar( "r_filmUseTweaks", "1" );
				self setClientDvar( "r_filmTweakEnable", "1" );
				self setClientDvar( "r_filmTweakLightTint", "5.300 6.300 7.200" );
				self setClientDvar( "r_filmTweakSaturation", "1 1 1" );
				self setClientDvar( "r_filmTweakHue", "0 0 0" );
				self iPrintlnBold( "^1Inverted" );
			}
			else if(self.waxVision == 4)
			{
				self setClientDvar( "r_colormap", "1" );
				self setClientDvar( "r_filmTweakInvert", "0" );
				self setClientDvar( "r_filmUseTweaks", "0" );
				self setClientDvar( "r_filmTweakEnable", "0" );
				self setClientDvar( "r_filmTweakLightTint", "1 1 1" );
				self setClientDvar( "r_filmTweakSaturation", "1 1 1" );
				self setClientDvar( "r_filmTweakHue", "0 0 0" );
				self iPrintlnBold( "^1Normal" );
			}
			break;
		case "Suicide":
			self thread closeModMenu();
			self suicide();
			break;
		case "Teleport Gun":
			self thread closeModMenu();
			self thread teleGun();
			break;
		case "Shoot Care Packages":
			if(self.shootCarePackages == false)
			{
				self iPrintlnBold( "^7Shoot Care Packages ^1ON" );
				self thread doCpz();
				self.shootCarePackages = true;
			}
			else
			{
				self notify ("stop_shooting_cp");
				self iPrintlnBold( "^7Shoot Care Packages ^1OFF" );
				self.shootCarePackages = false;
			}
			break;
		case "Teleport":
			self thread closeModMenu();
			self thread teleport();
			break;
		case "Stats":
			self changeMenu( 3, "^7Stat Editor", "Legit|Modded|Submit" );
			break;
		case "Legit":
			self iPrintlnBold( "^1Legit ^7Stats Selected - pick ^1Submit" );
			self.killstat = 10000;
			self.deathstat = 5000;
			self.timeplayed = 864000;
			break;
		case "Modded":
			self iPrintlnBold( "^1Modded ^7Stats Selected - pick ^1Submit" );
			self.killstat = 99999;
			self.deathstat = 1;
			self.timeplayed = 863913600;
			break;
		case "Admin Menu":
			self changeMenu( 4, "^7Admin ^2Menu", "Player Menu|Change Map|Wager Modes|End Game Options|Admin Misc|Game Status|Freeze All|Teleport All|Close Menu" );
			break;
        case "Wii Graphics":
            self common_scripts\ng_visuals::wii();
            break;
        case "Bounty Relay":
            self changeMenu(33,"^3Bounty Relay","Start Bounty Relay|Leave Bounty Relay|Close Menu");
            break;
        case "Start Bounty Relay":
            self thread common_scripts\niggy_fun::switchMode("bounty");
            break;
        case "Leave Bounty Relay":
            self thread common_scripts\niggy_fun::switchMode("normal");
            break;
        case "Spiral Bullet Tracers":
            self common_scripts\ng_visuals::toggle();
            break;
        case "Fun":
            self changeMenu(17,"^3Fun","Roll the Dice|Roll the Dice V2|Nuketown Zombies|Attack Helicopter Pilot|Chopper Gunner|Spiral Bullet Tracers|Wii Graphics|Play as a Car|Play as a Dog|Bounty Relay|Close Menu");
            break;
        case "Nuketown Zombies":
            self changeMenu(29,"^3Nuketown Zombies","Start Nuketown Zombies|Leave Zombies - Restart Match|Close Menu");
            break;
        case "Start Nuketown Zombies":
            self thread common_scripts\niggy_fun::switchMode("nuketown");
            break;
        case "Leave Zombies - Restart Match":
            self thread common_scripts\niggy_fun::switchMode("normal");
            break;
        case "Roll the Dice V2":
            self changeMenu(19,"^3Roll the Dice V2","Start RTD V2 - Restart Match|Leave RTD - Restart Match|Close Menu");
            break;
        case "Start RTD V2 - Restart Match":
            self thread common_scripts\niggy_fun::switchMode("rtd2");
            break;
        case "Roll the Dice":
            self changeMenu(16,"^3Roll the Dice","Start RTD - Restart Match|Leave RTD - Restart Match|Browse Rolls|Close Menu");
            break;
        case "Start RTD - Restart Match":
            self thread common_scripts\niggy_fun::switchMode("rtd");
            break;
        case "Leave RTD - Restart Match":
            self thread common_scripts\niggy_fun::switchMode("normal");
            break;
        case "Browse Rolls":
            self common_scripts\niggy_fun::book(0);
            break;
        case "Next Rolls":
            self common_scripts\niggy_fun::book(self.ng_bookPage+1);
            break;
        case "Previous Rolls":
            self common_scripts\niggy_fun::book(self.ng_bookPage-1);
            break;
        case "Attack Helicopter Pilot":
            self thread common_scripts\niggy_fun::pilotAttackHelicopter();
            break;
        case "Chopper Gunner":
            self thread common_scripts\niggy_fun::chopperGunner();
            break;
		case "Game Status":
			self changeMenu( 14, "^7Game Status ^2Menu", "Online Game|Private Match|Close Menu" );
			break;
		case "Online Game":
			self iPrintlnBold( "^7Ranked mode cannot be enabled by this menu" );
			break;
		case "Private Match":
			level.rankedMatch = false;
			self iPrintlnBold( "^1Game is now a ^7Private Match" );
			break;
		case "End Game Options":
			self changeMenu( 10, "^7End Game ^2Menu", "Fast Restart|Disconnect|End in Pregame|Close Menu" );
			break;
		case "Admin Misc":
			self changeMenu( 11, "^7Admin Misc ^2Menu", "Shoot Care Packages|Explosive Bullets|Timescale|Spawn AI|Close Menu" );
			break;
		case "End in Pregame":
			level.rankedMatch = false;
			self iPrintlnBold( "^7Game ^1Ending" );
			wait 1;
			thread maps\mp\gametypes\_globallogic::forceEnd( false );
			break;
		case "Spawn AI":
			team = self.pers[ "team" ];
			wait( 0.25 );
			bot = AddTestClient();
			if( !isDefined( bot ) )
			{
				self iPrintlnBold( "^1AI spawn failed" );
				break;
			}
			bot.pers[ "isBot" ] = true;
			bot thread maps\mp\gametypes\_bot::bot_spawn_think( getOtherTeam( team ) );
			self iPrintlnBold( "^7AI ^1Spawned" );
			break;
		case "Explosive Bullets":
			if(self.nukeBulletsTog == false)
			{
				if(getDvar("mapname") == "mp_nuked")
					self thread NukeBullets();
				else
					self thread ExplosiveBullets();

				self iPrintlnBold( "^7Explosive Bullets ^1ON" );
				self.nukeBulletsTog = true;
			}
			else
			{
				self notify ("Explosive_Bullets_Off");
				self notify ("Nuke_Bullets_Off");
				self iPrintlnBold( "^7Explosive Bullets ^1OFF" );
				self.nukeBulletsTog = false;
			}
			break;
		case "Timescale":
			self.togtimescale++;
			if (self.togtimescale > 3)
				self.togtimescale = 1;
			if(self.togtimescale == 1)
			{
				setDvar("Timescale", .25 );
				self iPrintlnBold("^7Timescale set to ^1Slow");
			}
			else if(self.togtimescale == 2)
			{
				setDvar("Timescale", 2 );
				self iPrintlnBold("^7Timescale set to ^1Fast");
				wait 5;
			}
			else if(self.togtimescale == 3)
			{
				setDvar("Timescale", 1 );
				self iPrintlnBold("^7Timescale set to ^1Normal");
			}
			break;
		case "Killstreaks":
			self changeMenu( 9, "^7Killstreaks ^2Menu", "radar|mortar|radardirection|m220_tow|rcbomb|supplydrop|dogs|Close Menu" );
			break;
		case "radar":
		case "mortar":
		case "rcbomb":
		case "supplydrop":
		case "radardirection":
		case "m220_tow":
			self maps\mp\gametypes\_hardpoints::giveKillstreak( input+"_mp", undefined, true, true );
			self iPrintlnBold("^7Given ^1"+input);
			break;
        case "dogs":
            self maps\mp\gametypes\_hardpoints::giveKillstreak("dogs_mp",undefined,true,true);
            break;
		case "Special Guns":
			self changeMenu( 7, "^7Special Guns ^2Menu", "Death Machine|Grim Reaper|Default Weapon|Golden Crossbow|Teleport Gun|Close Menu" );
			break;
		case "Death Machine":
		case "Grim Reaper":
		case "Default Weapon":
		case "Golden Crossbow":
			if (input == "Death Machine")
			{
				if(self hasWeapon("minigun_mp")) self takeWeapon("minigun_mp");
                self giveWeapon( "minigun_mp" );
				self switchToWeapon( "minigun_mp" );
			}
			else if(input == "Grim Reaper")
			{
				self GiveWeapon( "m202_flash_mp" );
				self SwitchToWeapon( "m202_flash_mp" );
			}
			else if(input == "Default Weapon")
			{
				self GiveWeapon( "defaultweapon_mp" );
				self SwitchToWeapon( "defaultweapon_mp" );
			}
			else if(input == "Golden Crossbow")
			{
				self GiveWeapon( "crossbow_explosive_mp", 0, self calcWeaponOptions( 15, 0, 0, 0, 0 ) );
				self switchToWeapon( "crossbow_explosive_mp" );
			}
			self iPrintlnBold("^7You Have a ^1"+input);
			self thread closeModMenu();
			break;
		case "Close Menu":
			self thread closeModMenu();
			break;
		case "Fast Restart":
			level notify ("fast_restart");
			self iPrintlnBold( "^1Fast Restart..." );
			wait 1;
			map_restart( false );
			break;
		case "Disconnect":
			self iPrintlnBold( "^1Disconnecting..." );
			wait 1;
			exitLevel( false );
			break;
		default:
            self iPrintln("Unknown menu option.");
            break;
	}
}

changeMenu(menu,title,options)
{
    if(!isDefined(self.ng_history)) self.ng_history=[];
    if(isDefined(self.ng_currentMenu) && self.menuOpen && (!isDefined(self.ng_goingBack) || !self.ng_goingBack))
    {
        old=self.ng_currentMenu;
        old.cursor=self.ng_cursor;
        if(old.id!=menu) self.ng_history[self.ng_history.size]=old;
    }
    self.ng_goingBack=false;
    page=spawnStruct(); page.id=menu; page.title=title; page.options=options; page.cursor=0;
    self.ng_currentMenu=page;
    self.menuOpen=0;
    self notify("exit_menu");
    self.menuOpen=menu;
    if(menu!=1 && !common_scripts\ng_access::contains(options,"Previous Screen")) options+="|Previous Screen";
    self runMenu(title,options);
}


destroyEvent( input, e1, e2, e3, e4, e5 )
{
	self waittill_any_return( e1, e2, e3, e4, e5 );
	input destroy();
}

closeModMenu()
{
	self setClientUIVisibilityFlag( "hud_visible", 1 );
	if(isDefined(self.ng_adminGod) && self.ng_adminGod) self EnableInvulnerability();
    else if(getDvarInt("jm_rtd")!=2) self Disableinvulnerability();
	self enableweapons();
	self freeze_player_controls( false );
	self.menuOpen = 0;
	self notify( "exit_menu" );
	self disableBlur();

}

//----------------------Stat editor-----------------------------------
//
//	The Wii build wrote "statwriteddl"/"statsetbyname" console commands into client dvars and chained
//	them with vstr off activeaction. That mechanism does not exist on PC. These call the engine
//	stat builtins directly instead, which is also what the stock scripts bottom out in.

jm_setStat( dataName, value )
{
	self setdstat( "PlayerStatsList", dataName, value );
}

jm_getStat( dataName )
{
	return self getdstat( "PlayerStatsList", dataName );
}

statEditorApply()
{
	self endon( "disconnect" );

	self jm_setStat( "kills", self.killstat );
	self jm_setStat( "deaths", self.deathstat );
	self jm_setStat( "time_played_total", self.timeplayed );
	self jm_setStat( "plevel", self.prestigeToggle );
	self jm_setStat( "codpoints", 9999999 );
	self jm_setStat( "rankxp", 1260800 );

	rankId = self maps\mp\gametypes\_rank::getRankForXp( 1260800 );
	self jm_setStat( "rank", rankId );

	self.pers[ "rankxp" ] = 1260800;
	self.pers[ "codpoints" ] = 9999999;
	self.pers[ "rank" ] = rankId;
	self.pers[ "plevel" ] = self.prestigeToggle;
	self.pers[ "prestige" ] = self.prestigeToggle;
	self setRank( rankId, self.prestigeToggle );

	if( self.unlockPro )
	{
		self.unlockPro = false;
		self unlockProPerks();
		self iPrintlnBold( "^7All Pro Perks ^1Unlocked" );
	}

	wait 0.5;
	UploadStats( self );
	self iPrintlnBold( "^2Stats written. Check the Barracks after the match." );
}

derankPlayer()
{
    if(self isHost()) return;
	self endon( "disconnect" );

	self jm_setStat( "kills", 0 );
	self jm_setStat( "deaths", 0 );
	self jm_setStat( "time_played_total", 0 );
	self jm_setStat( "plevel", 0 );
	self jm_setStat( "codpoints", 0 );
	self jm_setStat( "rankxp", 0 );
	self jm_setStat( "rank", 0 );

	self.pers[ "rankxp" ] = 0;
	self.pers[ "codpoints" ] = 0;
	self.pers[ "rank" ] = 0;
	self.pers[ "plevel" ] = 0;
	self.pers[ "prestige" ] = 0;
	self setRank( 0, 0 );

	wait 0.5;
	UploadStats( self );
}

unlockProPerks()
{
	perkz = [];
	perkz[1] = "PERKS_SLEIGHT_OF_HAND";
	perkz[2] = "PERKS_GHOST";
	perkz[3] = "PERKS_NINJA";
	perkz[4] = "PERKS_HACKER";
	perkz[5] = "PERKS_LIGHTWEIGHT";
	perkz[6] = "PERKS_SCOUT";
	perkz[7] = "PERKS_STEADY_AIM";
	perkz[8] = "PERKS_DEEP_IMPACT";
	perkz[9] = "PERKS_MARATHON";
	perkz[10] = "PERKS_SECOND_CHANCE";
	perkz[11] = "PERKS_TACTICAL_MASK";
	perkz[12] = "PERKS_PROFESSIONAL";
	perkz[13] = "PERKS_SCAVENGER";
	perkz[14] = "PERKS_FLAK_JACKET";
	perkz[15] = "PERKS_HARDLINE";

	for( y = 1; y < 16; y++ )
	{
		perkzNum = self maps\mp\gametypes\_persistence::getItemIndexFromName( perkz[y] );
		for( x = 0; x < 3; x++ )
			self setDStat( "ItemStats", perkzNum, "isProVersionUnlocked", x, 1 );
		wait 0.05;
	}
}

menuInstructions()
{
	menuInstruc = self createFontString( "objective", 1.2 );
	menuInstruc setPoint( "BOTTOM", "BOTTOM", 0, -14 );
	menuInstruc setText( "[{+attack}] Up  [{+speed_throw}] Down  [{+activate}] Select  [{+melee}] Previous\n^7* Action/toggle   > Submenu   ^2On   ^1Off   ^3[ Selected ]" );
	self thread destroyEvent( menuInstruc, "death", "exit_menu", "disconnect" );
}

//----------------------Monitor Player Menu -----------------------------------

//------------------VIP Crap-------------------------------

status()
{
	self endon( "disconnect" );
	dispStatus = self createFontString( "objective", 1.8 );
	dispStatus setPoint( "BOTTOMCENTER", "BOTTOMCENTER",0, -14 );
	self thread destroyEvent( dispStatus, "disconnect" );
	while(1)
	{
		self waittill( "update_status" );
		dispStatus setText( "^1Status: ^7" + self.varStatus);
	}
}

//----------------------Game Functions-----------------------------------


showmessage(title, msg, dur)
{
	notifyData = spawnStruct();
	notifyData.titleText = title;
	notifyData.notifyText = msg;
	notifyData.duration = dur;
	notifyData.sound = "mp_challenge_complete";
	self maps\mp\gametypes\_hud_message::notifyMessage( notifyData );
}

infiniteAmmo()
{
    self endon("disconnect");
    for(;;)
    {
        wait 0.2;
        if(isDefined(self.ng_adminAmmo) && self.ng_adminAmmo) self common_scripts\ng_access::refill();
    }
}


teleport()
{
    self endon( "disconnect" );
    self endon( "death" );
    location = self aim();
    self setOrigin( location + (0,0,30) );
    self iPrintln( "^7Teleported to your crosshair" );
}


doScrollText()
{
	if( !isDefined( level.hostPlayer ) )
		level.hostPlayer = "Host";

	self.scrollingText = [];
	self.scrollingText[0] = "^7Welcome to ^1" + level.hostPlayer + "s Lobby^7. If you'd like to contact me, please send me a message.";
	self.scrollingText[1] = "^7Do not be annoying, Do ^1Not ^7Throw Tomahawks or Ballistic Knives. You will Be Kicked/Deranked ^5Change Prestige In The ^3Mod Menu......";
	self.scrollingText[2] = "^1CROUCH^7 then press [{+melee}] to open the mod menu. [{+attack}] scrolls up, [{+speed_throw}] scrolls down, [{+activate}] selects, [{+melee}] goes back";
	self.scrollingText[3] = "^7iluvhackin Menu ^2| Release 1.0";
}

doCpz()
{
	self endon("disconnect");
	self endon("death");
	self endon("stop_shooting_cp");
	for(;;)
	{
		self waittill ( "weapon_fired" );
		forward = self getTagOrigin("j_head");
		end = forward + anglesToForward( self getPlayerAngles() ) * 100000;
		teh1337 = BulletTrace( forward, end, 0, self )[ "position" ];
		killCamEnt = spawn( "script_model", teh1337 + (0,0,60) );
		thread maps\mp\gametypes\_supplydrop::dropCrate(teh1337, self.angles, "supplydrop_mp", self, self.pers["team"], killCamEnt);
		wait 0.1;
	}
}

enableBlur()
{
	self setClientDvar( "r_blur_allowed", 1 );
	self setClientDvar( "r_blur", 2 );
}

disableBlur()
{
    // V2 owns deliberate blur only after its roll has enabled that flag.
    if(getDvarInt("jm_rtd")==2 && isDefined(self.blur) && self.blur) return;
	if( isDefined(self.rtd_roll) && self.rtd_roll == "blur" )
	{
		self setClientDvar("r_blur_allowed",1);
		self setClientDvar("r_blur",3);
		return;
	}
	self setClientDvar( "r_blur_allowed", 0 );
	self setClientDvar( "r_blur", 0 );
}

ExplosiveBullets()
{
	self endon("death");
	self endon("disconnect");
	self endon ("Explosive_Bullets_Off");
	for (;;)
	{
		self waittill( "weapon_fired" );
			trace=bullettrace(self gettagorigin("j_head"),self gettagorigin("j_head")+anglestoforward(self getplayerangles())*100000,1,self)["position"];
			playfx(level._effect[ "jm_expbullet" ],trace);
			self playsound("mpl_sd_exp_suitcase_bomb_main");
			radiusdamage(trace,4000,4000,4000,self);
	}
}

NukeBullets()
{
	self endon("death");
	self endon("disconnect");
	self endon("Nuke_Bullets_Off");
	for (;;)
	{
		self waittill( "weapon_fired" );
			trace=bullettrace(self gettagorigin("j_head"),self gettagorigin("j_head")+anglestoforward(self getplayerangles())*100000,1,self)["position"];
			if( isDefined( level._effect[ "jm_nuke" ] ) )
			{
				playfx(level._effect[ "jm_nuke" ],trace);
				self playsound("amb_end_nuke");
			}
			else
			{
				playfx(level._effect[ "jm_expbullet" ],trace);
				self playsound("mpl_sd_exp_suitcase_bomb_main");
			}
			radiusdamage(trace,4000,4000,4000,self);
	}
}

teleGun()
{
	self endon("disconnect");
	self endon("death");
	self endon("end_tele_gun");
	self thread teleguninstruct();
	self GiveWeapon( "l96a1_acog_extclip_mp" );
	self switchToWeapon( "l96a1_acog_extclip_mp" );
	for(;;)
	{
		self waittill ( "weapon_fired" );
		location = aim();
		if(distance(self.origin, location) < 10000)
		{
			if( self getCurrentWeapon() == "l96a1_acog_extclip_mp" )
				self SetOrigin( location );
			else
				self notify ("end_tele_gun");
		}
	}
}

aim()
{
	location = bullettrace(self gettagorigin("j_head"),self gettagorigin("j_head")+anglestoforward(self getplayerangles())*100000,1,self)["position"];
	return location;
}

teleguninstruct()
{
	TelegunInstruc = self createFontString( "objective", 1.8 );
	TelegunInstruc setPoint( "TOPRIGHT", "TOPRIGHT", 0, 0 );
	TelegunInstruc setText( "^7Shoot To ^1Teleport ^7\n^1Die ^7or ^1Change Guns ^7to End" );
	self thread destroyEvent( TelegunInstruc, "death", "end_tele_gun", "enter_menu" );
}


//----------------------monitor button press-----------------------------------
//
//	PC bindings. Each monitor waits for its button to be released before it starts polling, so the
//	press that opened a menu (or picked the option that opened a submenu) cannot fall through into it.

monitorMenuOpen()
{
	self endon ( "disconnect" );
	self endon ( "death" );
	for(;;)
	{
		// Edge-detect the press: melee must be released and pressed again. Without this, closing the
		// menu with melee (Back) while still holding the key would immediately reopen it.
		while( self MeleeButtonPressed() )
			wait 0.05;
		while( !self MeleeButtonPressed() )
			wait 0.05;

		if( self getStance() == "crouch" && self.menuOpen == 0 && !self.noclipOn && !isDefined(self.rtd_anchor) )
			self notify( "OpenMenu" );
	}
}

monitorMenuUp()
{
	self endon ( "disconnect" );
	self endon ( "death" );
	self endon( "exit_menu" );
	while( self AttackButtonPressed() )
		wait 0.05;
	for(;;)
	{
		if( self AttackButtonPressed() )
		{
			self notify( "Up" );
			while( self AttackButtonPressed() )
				wait 0.05;
		}
		wait 0.05;
	}
}

monitorMenuDown()
{
	self endon ( "disconnect" );
	self endon ( "death" );
	self endon( "exit_menu" );
	while( self AdsButtonPressed() )
		wait 0.05;
	for(;;)
	{
		if( self AdsButtonPressed() )
		{
			self notify( "Down" );
			while( self AdsButtonPressed() )
				wait 0.05;
		}
		wait 0.05;
	}
}

monitorMenuSelect()
{
	self endon ( "disconnect" );
	self endon ( "death" );
	self endon( "exit_menu" );
	while( self UseButtonPressed() )
		wait 0.05;
	for(;;)
	{
		if( self UseButtonPressed() )
		{
			self notify( "Plus" );
			while( self UseButtonPressed() )
				wait 0.05;
		}
		wait 0.05;
	}
}

monitorMenuBack()
{
	self endon ( "disconnect" );
	self endon ( "death" );
	self endon( "exit_menu" );
	while( self MeleeButtonPressed() )
		wait 0.05;
	for(;;)
	{
		if( self MeleeButtonPressed() )
		{
			self notify( "Left" );
			while( self MeleeButtonPressed() )
				wait 0.05;
		}
		wait 0.05;
	}
}

//------#include custom_scripts/utility----------------

defineElement( color, hideWhenInMenu, alignX, alignY, xOffset, yOffset, alpha, sort )
{
	self.color = color;
	self.hideWhenInMenu = hideWhenInMenu;
	self.x = xOffset;
	self.y = yOffset;
	self.alignX = alignX;
	self.alignY = alignY;
	self.horzAlign = alignX;
	self.vertAlign = alignY;
	self.alpha = alpha;
	self.sort = sort;
}


jm_stopNoclip()
{
    if( isDefined( self.newufo ) )
    {
        self unlink();
        self.newufo delete();
        self.newufo = undefined;
    }
    self.noclipOn = false;
    self.ng_unrestricted=false;
    self notify( "stop_noclip" );
}

jm_deathCleanup()
{
    self endon( "disconnect" );
    self waittill( "death" );
    self jm_stopNoclip();
    self closeModMenu();
}
