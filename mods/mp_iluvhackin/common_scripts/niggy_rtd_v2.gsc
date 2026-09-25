#include common_scripts\utility;
#include maps\mp\_airsupport;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

//Roll the Dice v4
//by JellyInjector

//Please don't be a douchebag and take credit for making this mod...
//If you want to have you're name in it, just change the class names

init()
{

    level.kh_fx=[];
    level.kh_fx[0]=loadfx("env/fire/fx_fire_player_md_mp");
    level.kh_fx[1]=loadfx("vehicle/vexplosion/fx_vexplode_helicopter_exp_mp");
    level.kh_fx[2]=loadfx("weapon/crossbow/fx_trail_crossbow_blink_grn_os");
    level.kh_fx[3]=loadfx("weapon/crossbow/fx_trail_crossbow_blink_red_os");
    level.kh_fx[4]=loadfx("weapon/grenade/fx_spark_disabled_weapon");
    level.kh_fx[5]=loadfx("weapon/napalm/fx_napalm_drop_mp");
    precacheItem("ak47_acog_extclip_silencer_mp");
    precacheItem("ak74u_elbit_grip_rf_mp");
    precacheItem("ak74u_mp");
    precacheItem("ak74u_rf_mp");
    precacheItem("asp_mp");
    precacheItem("aspdw_mp");
    precacheItem("aug_extclip_silencer_mp");
    precacheItem("aug_mp");
    precacheItem("china_lake_mp");
    precacheItem("claymore_mp");
    precacheItem("commando_reflex_gl_extclip_mp");
    precacheItem("crossbow_explosive_mp");
    precacheItem("cz75_auto_mp");
    precacheItem("cz75_mp");
    precacheItem("defaultweapon_mp");
    precacheItem("dog_bite_mp");
    precacheItem("famas_mp");
    precacheItem("fnfal_elbit_dualclip_mp");
    precacheItem("frag_grenade_mp");
    precacheItem("g11_mp");
    precacheItem("galil_ir_dualclip_silencer_mp");
    precacheItem("hatchet_mp");
    precacheItem("hk21_ir_extclip_mp");
    precacheItem("hk21_mp");
    precacheItem("hs10dw_mp");
    precacheItem("ithaca_grip_mp");
    precacheItem("ithaca_mp");
    precacheItem("kiparis_acog_mp");
    precacheItem("knife_ballistic_mp");
    precacheItem("knife_mp");
    precacheItem("l96a1_acog_extclip_mp");
    precacheItem("l96a1_extclip_mp");
    precacheItem("l96a1_mp");
    precacheItem("l96a1_vzoom_extclip_mp");
    precacheItem("m14_mp");
    precacheItem("m16_extclip_silencer_mp");
    precacheItem("m16_mp");
    precacheItem("m1911_mp");
    precacheItem("m202_flash_mp");
    precacheItem("m60_mp");
    precacheItem("m72_law_mp");
    precacheItem("mac11_elbit_extclip_mp");
    precacheItem("makarovdw_mp");
    precacheItem("minigun_mp");
    precacheItem("mortar_mp");
    precacheItem("mp5k_mp");
    precacheItem("mp5k_reflex_rf_silencer_mp");
    precacheItem("mpl_grip_dualclip_mp");
    precacheItem("mpl_silencer_mp");
    precacheItem("pm63_grip_extclip_mp");
    precacheItem("psg1_acog_extclip_mp");
    precacheItem("python_acog_mp");
    precacheItem("python_speed_mp");
    precacheItem("pythondw_mp");
    precacheItem("rottweil72_mp");
    precacheItem("rpg_mp");
    precacheItem("rpk_elbit_extclip_mp");
    precacheItem("skorpion_grip_rf_mp");
    precacheItem("skorpiondw_mp");
    precacheItem("spas_mp");
    precacheItem("sticky_grenade_mp");
    precacheItem("stoner63_acog_mp");
    precacheItem("uzi_silencer_mp");
    precacheItem("wa2000_mp");
    level.rollCount=81;
    level.testMode=0;
    level.matchHasntStarted=0;
    precacheModel("test_sphere_silver");
    precacheModel("projectile_hellfire_missile");
    precacheModel("tag_origin");
    precacheShader("waypoint_kill");
    setExpFog(25,500,0.5,0.5,0.5,0);
    level thread onPlayerConnected();
}


onPlayerConnected()
{
    for(;;)
    {
        level waittill("connected",player);
        player selfStuff();
        player gameText();
        player thread onPlayerSpawned();
    }
}


doIntro()
{
	self waittill( "spawned_player" );
	while(level.matchHasntStarted)
		wait 0.1;
	wait 0.8;
	self thread scrollFadeText( 4, "CENTER", "CENTER", 0, 0, "", "ROLL THE DICE" );
}

onPlayerSpawned()
{
    self endon("disconnect");
    for(;;)
    {
        self waittill("spawned_player");
        self thread startLife();
    }
}
startLife()
{
    self endon("death");
    self endon("disconnect"); self endon("disconnect");
    wait 0.6;
    if(!isAlive(self)) return;
    self.kh_speed=self getMoveSpeedScale();
    self.kh_health=self.maxhealth;
    self.extraRollText=[]; self.extraHelpText=[];
    self.kh_rollsThisLife=0;
    self setClientDvar("r_blur",0);
    self.blur=0;
    self setClientDvar("r_blur_allowed",1);
    self thread deathReset();
    forced=getDvarInt("ng_rtd_v2_force");
    if(forced>=1&&forced<=81) self thread rollThemDice(0,forced);
    else self thread rollThemDice();
    self iPrintln("^3Roll the Dice V2 ^7- original RTD by JellyInjector");
}


waitToOpenMenu()
{
	self.inMenu = 0;
	for(;;)
	{
		while(!self useButtonPressed() || !self meleeButtonPressed())
			wait 0.1;
		wait 1;
		if(self useButtonPressed() && self meleeButtonPressed() && !self.inMenu)
			self thread kickMenu();
	}
}

classNames()
{
	self setClientDvar( "customclass1", "^2Welcome to Skittles" );
	self setClientDvar( "customclass2", "Roll the Dice lobby." );
	self setClientDvar( "customclass3", "^2Please don't talk a lot" );
	self setClientDvar( "customclass4", "and don't be annoying." );
	self setClientDvar( "customclass5", "^2Have Fun!" );
}

deathReset()
{
	self endon("disconnect");
	self waittill_any("death","disconnect");
	self restoreLife();
}

restoreLife()
{
    self CameraActivate(false);
    self DisableInvulnerability();
    self enableWeapons();
    self freeze_player_controls(false);
    if(isDefined(self.kh_speed)) self setMoveSpeedScale(self.kh_speed);
    if(isDefined(self.kh_health)) self.maxhealth=self.kh_health;
    self setClientDvar("cg_fov",getDvar("cg_fov"));
    self setClientDvar("cg_thirdperson",0);
    self detach("test_sphere_silver","J_Head");
    self detach("projectile_hellfire_missile","tag_stowed_back");

	if(self.vision)
	{
		self setClientDvar("r_filmUseTweaks","1");
		self setClientDvar("r_filmTweakEnable","0");
		self setClientDvar("r_filmTweakInvert","0");
		self setClientDvar("r_filmTweakLightTint","1 1 1");
		self.vision = 0;
	}
	if(self.disabled)
	{
		self allowJump(true);
		self allowAds(true);
		self allowSprint(true);
		self.disabled = 0;
	}
	if(self.compass)
	{
		self setClientDvar("compassSize",1);
		self.compass = 0;
	}
	if(self.gunStuff)
	{
		self setClientDvar("cg_drawGun",1);
		self setClientDvar("cg_gun_x",0);
		self.gunStuff = 0;
	}
	if(self.mapStuff)
	{
		self setClientDvar("r_colormap","1");
		self setClientDvar("r_debugLayers","0");
		self.mapStuff = 0;
	}
	if(self.fog)
	{
		self setClientDvar("r_fog",0);
		self.fog = 0;
	}
	if(self.WH)
	{
		self setClientDvar("r_znear",2);
		self.WH = 0;
	}
	if(self.blur)
	{
		self setClientDvar("r_blur",0);
		self.blur = 0;
	}
	if(self.noHUD)
	{
		self setClientUIVisibilityFlag("hud_visible",1);
		self setClientDvar("cg_drawCrosshair",1);
		self.noHUD = 0;
	}
	if(self.SH)
	{
		self show();
		self.SH = 0;
	}
	if(isDefined(self.oic))
		self.oic = undefined;
	if(isDefined(self.doubleDamage))
		self.doubleDamage = undefined;
	if(isDefined(self.halfDamage))
		self.halfDamage = undefined;
	if(isDefined(self.vampire))
		self.vampire = undefined;
}

rollThemDice( XR, roll )
{
	self endon("death");
    self endon("disconnect");

	if(!isDefined(XR))
		XR = 0;

	if(isDefined(roll))
		self.dice = roll-1;
	else
	{
        available=[];
        for(candidate=0;candidate<level.rollCount;candidate++)
        {
            recent=false;
            for(i=0;i<16;i++) if(candidate==self.lastDices[i]) recent=true;
            if(!recent) available[available.size]=candidate;
        }
        self.dice=available[randomInt(available.size)];
	}

	for(i=15;i>0;i--)
		self.lastDices[i] = self.lastDices[i-1];
	self.lastDices[0] = self.dice;

    if(!isDefined(self.kh_rollsThisLife)) self.kh_rollsThisLife=0;
    if(self.kh_rollsThisLife>=8) return;
    self.kh_rollsThisLife++;
	RN = self.dice+1;
	switch( self.dice )
	{
		case 0:
			self setRollText( XR, RN, "Sprinter" );
			self setMoveSpeedScale(2);
			break;
		case 1:
			self setRollText( XR, RN, "Turtle" );
			self setMoveSpeedScale(0.5);
			break;
		case 2:
			self setRollText( XR, RN, "Gold Machine" );
			self goldGun("minigun_mp");
			break;
		case 3:
			self setRollText( XR, RN, "Invisibility", "Invisible for 20 seconds", 20 );
			self.SH = 1;
			self hide();
			wait 20;
			self show();
			self iPrintlnBold("You are ^1VISIBLE");
			break;
		case 4:
			self setRollText( XR, RN, "Rockets" );
			self wepStuff("rpg_mp");
			self thread sustainAmmo();
			break;
		case 5:
			self setRollText( XR, RN, "Weakling", "You are a 1 hit kill" );
			self.maxhealth = 1;
			self.health = self.maxhealth;
			break;
		case 6:
			self setRollText( XR, RN, "Invisible Gun" );
			wait 0.8;
			self setClientDvar("cg_drawGun",0);
			self.gunStuff = 1;
			break;
		case 7:
			self setRollText( XR, RN, "Zombie" );
			self wepStuff("defaultweapon_mp",0,0);
			break;
		case 8:
			self setRollText( XR, RN, "Laser Pointer" );
			dot = level.kh_fx[3];
			for(;;)
			{
				playfx(dot,aim());
				wait 0.1;
			}
		case 9:
			self setRollText( XR, RN, "Flashing", "You're flashing bewtween invisible & visible" );
			self.SH = 1;
			for(;;)
			{
				self hide();
				wait 0.3;
				self show();
				wait 0.3;
			}
		case 10:
			self setRollText( XR, RN, "Unlimited Ammo" );
			for(;;)
			{
				self setWeaponAmmoClip(self getCurrentWeapon(),99);
				wait 0.1;
			}
		case 11:
			self setRollText( XR, RN, "Double Roll", "You get two rolls!" );
			wait 1.5;
			self thread rollThemDice(1);
			wait 0.5;
			self thread rollThemDice(1);
			break;
		case 12:
			self setRollText( XR, RN, "Disabled" );
			self allowJump(false);
			self allowAds(false);
			self allowSprint(false);
			self.disabled = 1;
			break;
		case 13:
			self setRollText( XR, RN, "Faker", "Press [{+activate}] to fake your death" );
			self.SH = 1;
			for(;;)
			{
				while(!self usebuttonpressed())
					wait 0.05;
				clone = self ClonePlayer(3);
				clone StartRagdoll();
				self hide();
				self iPrintlnBold("^2Invisible!");
				self thread doTimer(5);
				wait 5;
				self show();
				self iPrintlnBold("^1Visible!");
				wait 1;
				self iPrintlnBold("Charging...");
				wait 6;
				self iPrintlnBold("Press [{+activate}] to fake your death!");
			}
		case 14:
			self setRollText( XR, RN, "Semtex Killer" );
			self wepStuff("sticky_grenade_mp");
			self thread sustainAmmo("sticky_grenade_mp");
			break;	
		case 15:
			self setRollText( XR, RN, "GPS" );
			self setClientDvar("compassSize",5);
			self.compass = 1;
			break;	
		case 16:
			self setRollText( XR, RN, "Gaymore" );
			self wepStuff("claymore_mp");
			self thread sustainAmmo("claymore_mp");
			break;
		case 17:
			self setRollText( XR, RN, "A True Fireman" );
			for(;;)
			{
				playFxOnTag(level._effect["character_fire_death_torso"],self,"J_SpineLower");
				wait 0.5;
			}
		case 18:
			self setRollText( XR, RN, "Double Trouble" );
			self wepStuff("hs10dw_mp");
			break;
		case 19:
			self setRollText( XR, RN, "Golden Crossbow" );
			self goldGun("crossbow_explosive_mp");
			self thread sustainAmmo();
			break;
		case 20:
			self setRollText( XR, RN, "Orgasm", "You are screaming" );
			for(;;)
			{
				level thread maps\mp\gametypes\_battlechatter_mp::mpSayLocalSound(self,"fire","scream");
				wait 2;
			}
		case 21:
			self setRollText( XR, RN, "Golden Spas" );
			self goldGun("spas_mp");
			break;
		case 22:
			self setRollText( XR, RN, "Jetpack" );
			self Jetpack();
		case 23:
			self setRollText( XR, RN, "What Da Fuck?!?" );
			self wepStuff("dog_bite_mp");
			break;
		case 24:
			self setRollText( XR, RN, "Vampire", "Gain health when you hit someone" );
			self.vampire = 1;
			break;
		case 25:
			self setRollText( XR, RN, "Wax World" );
			self setClientDvar("r_colormap","3");
			self.mapStuff = 1;
			break;
		case 26:
			self setRollText( XR, RN, "Heaven" );
			self setClientDvar("r_colormap","2");
			self setClientDvar("r_debugLayers","1");
			self.mapStuff = 1;
			break;
		case 27:
			self setRollText( XR, RN, "Flame Shooter" );
			self wepStuff("mpl_silencer_mp");
			self allowAds(false);
			self.disabled = 1;
			self flamethrower("env/fire/fx_fire_player_md_mp");
		case 28:
			self setRollText( XR, RN, "Foggy" );
			self setClientDvar("r_fog",1);
			self.fog = 1;
			break;
		case 29:
			self setRollText( XR, RN, "Poison", "You have 20 seconds to live!", 20 );
			wait 20;
			self suicide();
			break;
		case 30:
			self setRollText( XR, RN, "Spy", "Hold [{+frag}] for cloaking" );
			self wepStuff("knife_ballistic_mp");
			self.SH = 1;
			self doSpy();
		case 31:
			self setRollText( XR, RN, "Sticks and Stones" );
			self wepStuff("crossbow_explosive_mp");
			self GiveWeapon("knife_ballistic_mp");
			self GiveMaxAmmo("knife_ballistic_mp");
			self GiveWeapon("hatchet_mp");
			self SetWeaponAmmoClip("hatchet_mp",2);
			break;
		case 32:
			self setRollText( XR, RN, "Unlimited Tomahawks" );
			self wepStuff("hatchet_mp");
			self sustainAmmo("hatchet_mp");
		case 33:
			self setRollText( XR, RN, "Sharpshooter" );
			self thread sustainAmmo();
			for(;;)
			{
				self wepStuff(getRandomWep(self GetCurrentWeapon()));
				self thread doTimer(15);
				wait 15;
			}
		case 34:
			self setRollText( XR, RN, "Dragonsbreath" );
			self wepStuff("spas_mp");
			self flamethrower("weapon/napalm/fx_napalm_drop_mp");
		case 35:
			self setRollText( XR, RN, "Wallhack" );
			self setClientDvar("r_znear",50);
			self.WH = 1;
			break;
		case 36:
			self setRollText( XR, RN, "Sniper" );
			self wepStuff("l96a1_extclip_mp");
			break;
		case 37:
			self setRollText( XR, RN, "Smoke Trail" );
			for(;;)
			{
				SpawnTimedFX(level.fx_tabun_1,self.origin);
				wait 0.35;
			}
		case 38:
			self setRollText( XR, RN, "Dropped your glasses" );
			self setClientDvar("r_blur",3);
			self.blur = 1;
			break;
		case 39:
			self setRollText( XR, RN, "Teleporter", "Shoot to Teleport" );
			self setPerk("specialty_bulletpenetration");
			self setPerk("specialty_bulletdamage");
			self setPerk("specialty_bulletaccuracy");
			self setPerk("specialty_fallheight");
			self wepStuff("l96a1_acog_extclip_mp");
			for(;;)
			{
				self waittill("weapon_fired");
				if(distance(self.origin,aim()) < 10000)
					self setOrigin(aim()); 
			}
			break;
		case 40:
			self setRollText( XR, RN, "Paranoid", "Look up" );
			for(;;)
			{
				MagicBullet("rpg_mp",self.origin+(0,0,8000),self.origin,self);
				wait 1;
			}
		case 41:
			self setRollText( XR, RN, "Rocket Pistol" );
			self wepStuff("m1911_mp");
			for(;;)
			{
				self waittill("weapon_fired");
				MagicBullet("rpg_mp",self getTagOrigin("tag_eye"),aim(),self);
			}
		case 42:
			self setRollText( XR, RN, "Artillery Marker", "Shoot to mark artillery spot" );
			for(;;)
			{
				self iPrintlnBold("^2ARTILLERY MISSILES READY");
				self waittill("weapon_fired");
				self iPrintlnBold("^1REARMING");
				loc = aim();
				MagicBullet("rpg_mp",loc+(0,0,7500),loc,self);
				wait 0.1;
				MagicBullet("rpg_mp",loc+(0,0,7500),loc,self);
				wait 0.1;
				MagicBullet("rpg_mp",loc+(0,0,7500),loc,self);
				wait 5;
			}
		case 43:
			self setRollText( XR, RN, "Double Health" );
			self.maxhealth = 200;
			self.health = self.maxhealth;
			break;
		case 44:
			self setRollText( XR, RN, "Blood Bullets", "When you shoot you lose health" );
			for(;;)
			{
				self waittill("weapon_fired");
				if(self.health-5 <= 0)
					self suicide();
				self.health -= 5;
			}
		case 45:
			self setRollText( XR, RN, "Sparky" );
			tag[0] = "J_Spine1";
			tag[1] = "j_knee_ri";
			tag[2] = "j_knee_le";
			tag[3] = "j_spine4";
			tag[4] = "j_head";
			fx = level.kh_fx[4];
			for(;;)
			{
				wait 1;
				for(i=0;i<5;i++)
					PlayFxOnTag(fx,self,tag[i]);
			}
		case 46:
			self setRollText( XR, RN, "Cowboy" );
			self wepStuff("pythondw_mp");
			break;
		case 47:
			self setRollText( XR, RN, "Double Health and Roll Again" );
			self.maxhealth = 200;
			self.health = self.maxhealth;
			wait 1.5;
			self thread rollThemDice(1);
			break;
		case 48:
			self setRollText( XR, RN, "God Mode", "You can't die for 15 seconds", 15 );
			self EnableInvulnerability();
			wait 15;
			self DisableInvulnerability();
			self iPrintlnBold("God mode ^1OFF");
			break;
		case 49:
			self setRollText( XR, RN, "Tank" );
			self.maxhealth = 300;
			self.health = self.maxhealth;
			self takeAllWeapons();
			self GiveWeapon("m60_mp");
			self allowSprint(false);
			self setMoveSpeedScale(0.4);
			self.disabled = 1;
			break;
		case 50:
			self setRollText( XR, RN, "Weak Bullets", "You do less damage" );
			self.halfDamage = 1;
			break;
		case 51:
			self setRollText( XR, RN, "Grenade Training" );
			self takeWeapon(self GetCurrentOffhand());
			self giveWeapon("frag_grenade_mp");
			for(;;)
			{
				self waittill("grenade_fire",grenade,weaponName);
				Camera = spawn("script_model",grenade.origin+(0,0,100));
				pangles = self getPlayerAngles();
				Camera.angles = (pangles[0],pangles[1],45);
				Camera setModel("tag_origin");
				self CameraSetLookAt(Camera);
				self CameraSetPosition(Camera);
				self CameraActivate(true);
				Camera linkTo(grenade);
				self thread cameraDelete(camera);
				a = grenade.angles;
				while(isDefined(grenade))
				{
					grenade.angles = a;
					wait 0.05;
				}
				self notify("cameraDelete");
				wait 0.05;
				self giveMaxAmmo("frag_grenade_mp");
			}
		case 52:
			self setRollText( XR, RN, "Don't leave me hands" );
			self.gunStuff = 1;
			for(i=0;;i+=0.08)
			{
				self setClientDvar("cg_gun_x",i);
				wait 0.05;
			}
		case 53:
			self setRollText( XR, RN, "Bounce" );
			self setPerk("specialty_fallheight");
			wait 1;
			for(;;)
			{
				while(!self isOnGround())
					wait 0.05;
				for(i=3;i>0;i--)
				{
					self setVelocity(self getVelocity()+(0,0,400));
					wait 0.2;
				}
			}
		case 54:
			self setRollText( XR, RN, "Zero Gravity", "Once you jump, you aint coming back" );
			while(self isOnGround())
				wait 0.05;
			self iPrintlnBold("If you get stuck, hold [{+frag}] to kill yourself ");
			for(;;)
			{
				self setVelocity((self getVelocity()[0],self getVelocity()[1],150));
				if(self fragButtonPressed())
					self suicide();
				wait 0.2;
			}
		case 55:
			self setRollText( XR, RN, "Alien" );
			self.vision = 1;
			self setClientDvar("r_filmUseTweaks","1");
			self setClientDvar("r_filmTweakEnable","1");
			self setClientDvar("r_filmTweakInvert","1");
			self setClientDvar("r_filmTweakLightTint","5.3 6.3 7.2");
			break;
		case 56:
			self setRollText( XR, RN, "Darkness" );
			self.vision = 1;
			self setClientDvar("r_filmUseTweaks","1");
			self setClientDvar("r_filmTweakEnable","1");
			self setClientDvar("r_filmTweakLightTint","0 0 0");
			break;
		case 57:
			self setRollText( XR, RN, "Valkyrie Rocket", "You get 1 rocket" );
			self thread valkyrieRocket();
			break;
		case 58:
			self setRollText( XR, RN, "Dead Ops Arcade" );
			self doBirdsEyeView();
		case 59:
			self setRollText( XR, RN, "Anti-Camp" );
			wait 1.5;
			for(;;)
			{
				while(!self isMoving())
				{
					self [[level.callbackPlayerDamage]](undefined,self,self.maxhealth/4,8,"MOD_SUICIDE","mortar_mp",self.origin,self.origin,"none",0);
					wait 1;
				}
				wait 0.1;
			}
		case 60:
			self setRollText( XR, RN, "Stretch" );
			wait 0.8;
			self setClientDvar("cg_fov",150);
			break;
		case 61:
			self setRollText( XR, RN, "Camper Pro" );
			for(;;)
			{
				if(self isMoving())
				{
					self disableWeapons();
					while(self isMoving())
						wait 0.05;
				}
				if(!self isMoving())
				{
					self enableWeapons();
					while(!self isMoving())
						wait 0.05;
				}
				wait 0.1;
			}
		case 62:
			self setRollText( XR, RN, "Bolt Action" );
			self wepStuff("m14_mp",1,1);
			self.oic = 1;
			for(;;)
			{
				if(self getWeaponAmmoStock("m14_mp") != 1)
					self setWeaponAmmoStock("m14_mp",1);
				if(self getWeaponAmmoClip("m14_mp") > 1)
					self setWeaponAmmoClip("m14_mp",1);
				wait 0.2;
			}
		case 63:
			self setRollText( XR, RN, "Hitman", "Kill the right person, or else..." );
			self thread doHitman();
			break;
		case 64:
			self setRollText( XR, RN, "Third Person" );
			wait 0.8;
			self setClientDvar("cg_thirdperson",1);
			break;
		case 65:
			self setRollText( XR, RN, "Drunk", "Stop moving to see clearly" );
			self.blur = 1;
			blur = 0;
			for(;;)
			{
				if(self isMoving())
				{
					if(blur < 4)
						blur += 0.5;
					else if(blur >= 4)
						blur += randomFloatRange(-0.6,0.6);
				}
				else if(blur > 0)
				{
					blur -= 0.7;
					if(blur < 0)
						blur = 0;
				}
				self setClientDvar("r_blur",blur);
				wait 0.1;
			}
		case 66:
			self setRollText( XR, RN, "Gun Game" );
			gun = [];
			gun[0] = "python_speed_mp";
			gun[1] = "makarovdw_mp";
			gun[2] = "spas_mp";
			gun[3] = "ithaca_mp";
			gun[4] = "mp5k_mp";
			gun[5] = "skorpiondw_mp";
			gun[6] = "ak74u_mp";
			gun[7] = "m14_mp";
			gun[8] = "m16_mp";
			gun[9] = "famas_mp";
			gun[10] = "aug_mp";
			gun[11] = "hk21_mp";
			gun[12] = "m60_mp";
			gun[13] = "l96a1_mp";
			gun[14] = "wa2000_mp";
			gun[15] = "m202_flash_mp";
			gun[16] = "m72_law_mp";
			gun[17] = "china_lake_mp";
			gun[18] = "crossbow_explosive_mp";
			gun[19] = "knife_ballistic_mp";
			self thread sustainAmmo();
			for(i=0;i<20;i++)
			{
				self wepStuff(gun[i]);
				self waittill("iGotAKill");
				wait 0.1;
			}
			self iPrintlnBold("HOLY SHIT! You actually finished it!");
			self takeAllWeapons();
			self giveWeapon("minigun_mp");
			break;
		case 67:
			self setRollText( XR, RN, "Fun Ball" );
			self wepStuff("defaultweapon_mp",0,0);
			self attach("test_sphere_silver","J_Head",false);
			wait 0.8;
			self setClientDvar("cg_thirdperson",1);
			break;
		case 68:
			self setRollText( XR, RN, "Choose a roll" );
			self thread rollMenu();
			break;
		case 69:
			self setRollText( XR, RN, "One in the chamber" );
			self wepStuff("m1911_mp",1,0);
			self.oic = 1;
			for(;;)
			{
				self waittill("iGotAKill");
				self SetWeaponAmmoClip("m1911_mp",self GetWeaponAmmoClip("m1911_mp")+1);
			}
		case 70:
			self setRollText( XR, RN, "Double Damage" );
			self.doubleDamage = 1;
			break;
		case 71:
			self setRollText( XR, RN, "Ray Gun" );
			self wepStuff("asp_mp");
			for(;;)
			{
				self waittill("weapon_fired");
				self thread doGreenBullet(self getTagOrigin("tag_eye"),aim(),self GetPlayerAngles());
			}
		case 72:
			self setRollText( XR, RN, "Fatty" );
			self SetMoveSpeedScale(0.5);
			for(;;)
			{
				if(self isMoving() && self isOnGround())
					earthquake(0.3,0.25,self getTagOrigin("j_spinelower"),180);
				wait 0.2;
			}
		case 73:
			self setRollText( XR, RN, "Arsenal", "Multiple Weapons" );
			for(i=0;i<5;i++)
				self giveWeapon(getRandomWep(self GetCurrentWeapon()));
			break;
		case 74:
			self setRollText( XR, RN, "Shooting Guns" );
			self wepStuff("knife_ballistic_mp");
			self thread sustainAmmo();
			for(;;)
			{
				self waittill("missile_fire",missile);
				gun = spawn("script_model",missile.origin);
				gun.angles = missile.angles;
				gun linkTo(missile);
				gun setModel(getWeaponModel(getRandomWep("knife_ballistic_mp")));
				missile hide();
				thread deleteGun(gun,missile);
			}
		case 75:
			self setRollText( XR, RN, "Just Throw It" );
			model = getWeaponModel(self GetCurrentWeapon());
			self wepStuff("hatchet_mp");
			self thread sustainAmmo("hatchet_mp");
			for(;;)
			{
				self waittill("grenade_fire",grenade);
				gun = spawn("script_model",grenade.origin);
				gun.angles = grenade.angles;
				gun linkTo(grenade);
				gun setModel(model);
				grenade hide();
				thread deleteGun(gun,grenade);
			}
		case 76:
			self setRollText( XR, RN, "Ecstasy" );
			screen = createBoxShader("center","middle",320,240,(1,1,1),4096,4096,0.4,-9);
			self thread deathDestroy(screen);
			for(;;)
			{
				screen.color = (randomFloat(1),randomFloat(1),randomFloat(1));
				wait 0.1;
			}
		case 77:
			self setRollText( XR, RN, "Super Stakeout" );
			self giveSuperWeapon("ithaca_mp");
			break;
		case 78:
			self setRollText( XR, RN, "My Favorite Pistol" );
			self giveSuperWeapon("cz75_mp");
			break;
		case 79:
			self setRollText( XR, RN, "Hardcore" );
			self.maxhealth = 40;
			self.health = self.maxhealth;
			self setClientUIVisibilityFlag("hud_visible",0);
			self setClientDvar("cg_drawCrosshair",0);
			self.noHUD = 1;
			break;
		case 80:
			self setRollText( XR, RN, "Skittles Favorite Gun" );
			self wepStuff("ak74u_elbit_grip_rf_mp");
			break;
	}
}

doHitman()
{
	self notify("victim_died");
	self endon("death");
    self endon("disconnect");
	self endon("victim_died");
	lastplayer = self;
	for(;;)
	{
		player = level.players[randomInt(level.players.size)];
		if(!isAlive(player) || player == lastplayer || player == self)
        { wait 0.1; continue; }
		lastplayer = player;
		self thread doHeadIcon(player);
		self iPrintlnBold("Kill ^1"+player.name);
		self waittill("iGotAKill",playerKilled);
		if(playerKilled != player)
			self suicide();
		wait 0.5;	
	}
}

doHeadIcon(player)
{
	self endon("death");
    self endon("disconnect");
	self endon("iGotAKill");
	self endon("victim_died");
	headicon = newClientHudElem(self);
	headicon.archived = true;
	headicon.alpha = 0.8;
	headicon setShader("waypoint_kill",8,8);
	headicon setWaypoint(true);
	self thread destroyHeadicon(headicon);
	for(;;)
	{
		org = player.origin;
		headicon.x = org[0];
		headicon.y = org[1];
		headicon.z = org[2]+70;
		if(!isAlive(player))
			self thread doHitman(player);
		wait 0.03;
	}
}

destroyHeadicon(headicon)
{
	self waittill_any("death","victim_died","iGotAKill","disconnect");
	headicon destroy();
}

deleteGun(gun,obj)
{
	wait 15;
	gun delete();
	if(isDefined(obj))
		obj delete();
}

deathCP(cp)
{
	self waittill_any("death","disconnect");
	if(isDefined(cp))
		cp delete();
}

isMoving()
{
	if(self getVelocity() == (0,0,0))
		return false;
	return true;
}

doGreenBullet(start,end,angle)
{
    self endon("death"); self endon("disconnect");
	dot = level.kh_fx[2];
	for(i=0;;i++)
	{
		org = start+(anglesToForward(angle)*(i*52));
		playfx(dot,org);
		if(distance(org,end) < 27 || i >= 42)
		{
			radiusdamage(org,100,75,25,self);
			break;
		}
        wait 0.01;
	}
}

valkyrieRocket()
{
	self endon( "death" );
    self endon("disconnect");
	self wepStuff("m202_flash_mp",0,0);
	while(!self attackButtonPressed())
		wait 0.05;
	missile = spawn("script_model",self getTagOrigin("tag_eye"));
	missile setModel("projectile_hellfire_missile");
	missile.angles = self getPlayerAngles();
	originToLookAt = spawn("script_model",missile.origin+vector_scale(anglesToForward(missile.angles),25));
	originToLookAt linkTo(missile);
	self CameraSetLookAt(originToLookAt);
	self CameraSetPosition(missile);
	self CameraActivate(true);
	self thread doValkyrie(missile,originToLookAt);
	self thread valkyrieExplode(missile,originToLookAt);
	self SetMoveSpeedScale(0);
}

doValkyrie( missile, org2lookAt )
{
    self endon("death"); self endon("disconnect");
	self.missileOn = 1;
	t = 0;
	while(self.missileOn)
	{
		if(missile.angles != self getPlayerAngles())
			missile.angles = self getPlayerAngles();
		missile moveTo(org2lookAt.origin,0.05);
		if(t < 10)
			t++;
		else if(self attackButtonPressed() || !SightTracePassed(missile.origin, org2lookAt.origin, false, missile))
			self notify("valkyrie_done");
		wait 0.05;
	}
}

valkyrieExplode( missile, cam )
{
	self waittill_any("death","valkyrie_done","disconnect");
	explosion = level.kh_fx[1];
	playFx(explosion,missile.origin);
	radiusDamage(missile.origin,400,300,20,self);
	missile playSound("explo_mine");
	missile delete();
	cam delete();
	self.missileOn = 0;
	if(isAlive(self))
	{
		self thread rollThemDice(1);
		wait 0.1;
		if(self GetCurrentWeapon() == "m202_flash_mp")
			self wepStuff(getRandomWep("m202_flash_mp"));
	}
	wait 1;
	self SetMoveSpeedScale(1);
	self CameraActivate(false);
}

cameraDelete( cam )
{
	self waittill_any( "death", "cameraDelete" );
	cam delete();
	self CameraActivate(false);
}

Jetpack()
{
	self endon("death");
    self endon("disconnect");
	self setPerk("specialty_fallheight");
	self.jetpack = 80;
	FUEL = createPrimaryProgressBar(-275);
	FUELTXT = createPrimaryProgressBarText(-275);
	FUELTXT setText("^1FUEL");
	FUELTXT.y = 178;
	FUEL.bar.y = 190;
	FUEL.y = 190;
	self attach("projectile_hellfire_missile","tag_stowed_back");
	self thread deathDestroy(FUEL.bar,FUEL,FUELTXT);
	for(;;)
	{
		if(self jumpbuttonpressed() && self.jetpack > 0)
		{
			if(self isOnGround())
                                self setOrigin(self.origin+(0,0,30));
			self.jetpack--;
			Earthquake(.15,.2,self gettagorigin("j_spine4"),50);
			PlayFX(level._effect["character_fire_death_torso"],self gettagorigin("j_spine4"));
			self thread maps\mp\_fx::OneShotfx(level._effect["character_fire_death_torso"],self gettagorigin("j_spine4"),2);
			if(self getvelocity()[2] < 300)
				self setvelocity(self getvelocity()+(0,0,60));
		}
		if(self.jetpack<80 &&!self jumpbuttonpressed())
			self.jetpack++;
		FUEL updateBar(self.jetpack/80);
		FUEL.bar.color = (1,self.jetpack/80,self.jetpack/80);
		wait 0.05;
	}
}

deathDestroy(a,b,c)
{
	self waittill_any("death","disconnect");
	a destroy();
	if(isDefined(b))
		b destroy();
	if(isDefined(c))
		c destroy();
}

goldGun(gun)
{
	self takeAllWeapons();
  	self GiveWeapon(gun,0,self calcWeaponOptions(15,0,0,0,0));
	self GiveWeapon("knife_mp");
    self switchToWeapon(gun);
  	self giveMaxAmmo(gun);
}

giveSuperWeapon(gun)
{
    self wepStuff(gun);
    self.doubleDamage=1;
    self thread sustainAmmo(gun);
}


wepStuff(gun,clip,stock)
{
	self takeAllWeapons();
	self giveWeapon(gun);
	self giveWeapon("knife_mp");
    self switchToWeapon(gun);
	if(isDefined(clip))
		self SetWeaponAmmoClip(gun,clip);
	if(isDefined(stock))
		self SetWeaponAmmoStock(gun,stock);
	if(!isDefined(clip) && !isDefined(stock))
		self giveMaxAmmo(gun);
}

selfStuff()
{
	self.lastDices = [];
	for(i=0;i<=15;i++)
		self.lastDices[i] = 999;
	self.SH = 0;
	self.WH = 0;
	self.fog = 0;
	self.blur = 0;
	self.noHUD = 0;
	self.vision = 0;
	self.compass = 0;
	self.disabled = 0;
	self.gunStuff = 0;
	self.mapStuff = 0;
	self setClientDvar("r_fog",0);
	self setClientDvar("lowAmmoWarningColor1","0 0 0 0");
	self setClientDvar("lowAmmoWarningColor2","0 0 0 0");
	self setClientDvar("lowAmmoWarningNoAmmoColor1","0 0 0 0");
	self setClientDvar("lowAmmoWarningNoAmmoColor2","0 0 0 0");
	self setClientDvar("lowAmmoWarningNoReloadColor1","0 0 0 0");
	self setClientDvar("lowAmmoWarningNoReloadColor2","0 0 0 0");
}

gameText()
{
	self.rollText = createCoolText( "default", 2, "RIGHT", "RIGHT", -30, -170, "^3", "^2" );
	self.helpText = createCoolText( "objective", 1.5, "RIGHT", "RIGHT", -30, -190, "", "^2" );
	self.extraText = createCoolText( "objective", 2, "CENTER", "CENTER", 0, 100, "", "^0" );
	self.extraRollText = [];
	self.extraHelpText = [];
}

setRollText( extraRoll, number, name, description, countdown )
{
	if(extraRoll)
	{
		num = self.extraRollText.size;
		self.extraRollText[num] = createCoolText( "default", 2, "RIGHT", "RIGHT", -30, -125+(num*40), "^3", "^2", "["+number+"] "+name );
		self.extraHelpText[num] = createCoolText( "objective", 1.5, "RIGHT", "RIGHT", -30, -145+(num*40), "", "^2" );
		if(isDefined(description))
			self.extraHelpText[num] setCoolText(description);
		self thread waittillDeath(num);
	}
	else
	{
		self.rollText setCoolText("["+number+"] "+name);
		if(isDefined(description))
			self.helpText setCoolText(description);
		else
			self.helpText setCoolText("");
	}
	if(isDefined(countdown))
		self thread doTimer(countdown);
}

waittillDeath(num)
{
	self waittill_any("death","disconnect");
	self.extraRollText[num] destroyCoolText();
	self.extraRollText[num] = undefined;
	self.extraHelpText[num] destroyCoolText();
	self.extraHelpText[num] = undefined;
}
	
flamethrower( fx )
{
	self endon("disconnect");
	self endon("death");
    self endon("disconnect");
	for(;;)
	{
                self waittill("weapon_fired");
		if(fx=="env/fire/fx_fire_player_md_mp") effect=level.kh_fx[0]; else effect=level.kh_fx[5];
        playfx(effect,aim());
		self playsound("mpl_player_burn_loop");
		radiusdamage(aim(),40,40,10,self);
	}
}

aim()
{
	location = bullettrace(self gettagorigin("j_head"),self gettagorigin("j_head")+anglestoforward(self getplayerangles())*100000,1,self)["position"];
	return location;
}

credit()
{
for(;;)
{
wait 45;
iPrintln("You are playing ^3Roll the Dice^7, made by ^2JellyInjector");
}
}

doTimer( time )
{
	self endon("death");
    self endon("disconnect");
	self thread destroyTimer(self.extraText);
	for(i=time;i>0;i--)
	{
		self.extraText setCoolText(i);
		wait 1;
	}
	self notify("endtime");
}

destroyTimer(txt)
{
	self waittill_any("death","endtime");
	txt thread setCoolText("");
}

doBirdsEyeView()
{
	wait .01;
	self setClientUIVisibilityFlag("hud_visible", 0);
	self.noHUD = 1;
	self allowADS(false);
	self.disabled = 1;
	self setMoveSpeedScale(1.2);
	birdsEyeCamera = spawn("script_model", self.origin + (0, 0, 600));
	birdsEyeCamera.angles = (90, 90, 0);
	birdsEyeCamera setModel("tag_origin");
	self CameraSetLookAt(birdsEyeCamera);
	self CameraSetPosition(birdsEyeCamera);
	self CameraActivate(true);
	self thread disableOnDeath(birdsEyeCamera);
	self endon("death");
    self endon("disconnect");
	self endon("disconnect");
	temporaryOffset = 600;
	while(1)
	{
		sightPassed = SightTracePassed(self.origin+(0,0,600), self.origin, false, birdsEyeCamera);
		if(sightPassed && birdsEyeCamera.origin[2] - self.origin[2] < 600)
		{
			temporaryOffset = birdsEyeCamera.origin[2] - self.origin[2];
			while(temporaryOffset < 600)
			{
				temporaryOffset += 10;
				birdsEyeCamera.origin = self.origin + (0, 0, temporaryOffset);
				wait 0.01;
			}
		}
		while(!SightTracePassed(self.origin+(0,0,temporaryOffset), self.origin, false, birdsEyeCamera))
		{
			temporaryOffset -= 20;
			birdsEyeCamera.origin = self.origin + (0, 0, temporaryOffset);
			wait 0.01;
		}
		self SetPlayerAngles(self GetPlayerAngles()*(0,1,0));
		birdsEyeCamera.origin = self.origin + (0, 0, temporaryOffset);
		wait 0.01;
	}
}

disableOnDeath( bCam )
{
	self waittill_any("death","disconnect");
	self CameraActivate(false);
	bCam delete();
}

createCoolText( font, fontScale, pos1, pos2, x, y, primaryColor, secondaryColor, text )
{
	txt = spawnStruct();
	txt.primaryText = createFontString(font,fontScale);
	txt.primaryText setPoint(pos1,pos2,x,y);
	txt.primaryColor = primaryColor;
	if(isDefined(text))
		txt.primaryText setText(primaryColor+text);
	txt.primaryText.sort = -10;
	txt.secondaryText = createFontString(font,fontScale);
	txt.secondaryText setPoint(pos1,pos2,x-fontScale,y+fontScale);
	txt.secondaryColor = secondaryColor;
	if(isDefined(text))
		txt.secondaryText setText(secondaryColor+text);
	txt.secondaryText.sort = -11;
	return txt;
}

setCoolText( text )
{
	self.primaryText setText(self.primaryColor+text);
	self.secondaryText setText(self.secondaryColor+text);
}

destroyCoolText()
{
	self.primaryText destroy();
	self.secondaryText destroy();
}

getRandomWep(weaponNotToGet)
{
	weps[0] = "m72_law_mp";
	weps[1] = "m202_flash_mp";
	weps[2] = "mp5k_reflex_rf_silencer_mp";
	weps[3] = "skorpion_grip_rf_mp";
	weps[4] = "mac11_elbit_extclip_mp";
	weps[5] = "ak74u_rf_mp";
	weps[6] = "uzi_silencer_mp";
	weps[7] = "pm63_grip_extclip_mp";
	weps[8] = "mpl_grip_dualclip_mp";
	weps[9] = "kiparis_acog_mp";
	weps[10] = "m16_extclip_silencer_mp";
	weps[11] = "galil_ir_dualclip_silencer_mp";
	weps[12] = "famas_mp";
	weps[13] = "aug_extclip_silencer_mp";
	weps[14] = "fnfal_elbit_dualclip_mp";
	weps[15] = "ak47_acog_extclip_silencer_mp";
	weps[16] = "commando_reflex_gl_extclip_mp";
	weps[17] = "g11_mp";
	weps[18] = "ithaca_grip_mp";
	weps[19] = "rottweil72_mp";
	weps[20] = "spas_mp";
	weps[21] = "hk21_ir_extclip_mp";
	weps[22] = "rpk_elbit_extclip_mp";
	weps[23] = "stoner63_acog_mp";
	weps[24] = "l96a1_vzoom_extclip_mp";
	weps[25] = "psg1_acog_extclip_mp";
	weps[26] = "aspdw_mp";
	weps[27] = "cz75_auto_mp";
	weps[28] = "python_acog_mp";
	weps[29] = "china_lake_mp";
	weps[30] = "knife_ballistic_mp";
	weps[31] = "crossbow_explosive_mp";
	wep = randomInt(32);
	while(weps[wep] == weaponNotToGet)
		wep = randomInt(31);
	return weps[wep];
}

kickMenu()
{
	self freeze_player_controls(true);
	title = createText( "objective", 1.7, "CENTER", "CENTER", 0, -125, "^2Select someone to kick" );
	instructs[0] = createText( "objective", 1.5, "LEFT", "CENTER", -109, -100+(level.players.size*25), "[{+speed_throw}] Up\n[{+attack}] Down" );
	instructs[1] = createText( "objective", 1.5, "RIGHT", "CENTER", 109, -100+(level.players.size*25), "Kick [{+activate}]" );
	instructs[2] = createText( "objective", 1.5, "RIGHT", "CENTER", 109, -83+(level.players.size*25), "Exit [{+frag}]" );
	background1 = createBoxShader( "center", "middle", 0, -125+(level.players.size*12.5), (0,0.4,0), 220, 25+(level.players.size*25), 1, -5 );
	background2 = createBoxShader( "center", "middle", 0, -125, (0.4,0.4,0.4), 214, 20, 1, -4 );
	playerText = [];
	for(i=0;i<level.players.size;i++)
	{
		playerText[i] = createText( "objective", 1.5, "LEFT", "CENTER", -102, -101+(i*25), level.players[i].name );
		playerText[i].background = createBoxShader( "center", "middle", 0, -100+(i*25), (1,1,1), 214, 20, 0.4, -3 );
		playerText[i].player = level.players[i];
	}
	playerText[0].background.alpha = 1;
	playerText[0].background.color = (0,0,0);
	self.inMenu = 1;
	curPlayer = 0;
	wait 0.3;
	while(self.inMenu)
	{
		while(!self useButtonPressed() && !self attackButtonPressed() && !self adsButtonPressed() && !self fragButtonPressed())
			wait 0.01;
		if(self useButtonPressed())
			if(level.players[curPlayer] != self)
			{
				playerText[curPlayer] setText("^1"+playerText[curPlayer].player.name);
				kick(playerText[curPlayer].player GetEntityNumber());
			}
		if(self fragButtonPressed())
			self.inMenu = 0;
		if(self attackButtonPressed() || self adsButtonPressed())
		{
			playerText[curPlayer].background.alpha = 0.4;
			playerText[curPlayer].background.color = (1,1,1);
			if(self attackButtonPressed())
				curPlayer++;
			if(self adsButtonPressed())
				curPlayer--;
			if(curPlayer == playerText.size)
				curPlayer = 0;
			if(curPlayer < 0)
				curPlayer = playerText.size-1;
			playerText[curPlayer].background.alpha = 1;
			playerText[curPlayer].background.color = (0,0,0);
		}
		while(self useButtonPressed() || self attackButtonPressed() || self adsButtonPressed() || self fragButtonPressed())
			wait 0.05;
	}
	for(i=0;i<playerText.size;i++)
	{
		playerText[i] destroy();
		playerText[i].background destroy();
	}
	background1 destroy();
	background2 destroy();
	title destroy();
	for(i=0;i<4;i++)
		instructs[i] destroy();
	self freeze_player_controls(false);
}

createText( font, fontscale, pos1, pos2, x, y, text )
{
	txt = createFontString(font,fontscale);
	txt setPoint(pos1,pos2,x,y);
	txt setText(text);
	return txt;
}

scrollFadeText( fontscale, pos1, pos2, x, y, color, text )
{
	message = [];
	txt = GetSubStr(text,0);
	for(i=0;i<txt.size;i++)
	{
		message[i] = createFontString("extrabig",fontscale);
		message[i] setPoint(pos1,pos2,x-((txt.size/2)*(fontscale*6))+((fontscale*6)*i),y);
		message[i] setText(color+txt[i]);
		message[i].alpha = 0;
	}
	for(i=0;i<message.size;i++)
	{
		message[i] doFade(0.3,1);
		wait 0.3;
		message[i] doFade(0.5,0);
	}
	wait 0.7;
	for(i=0;i<message.size;i++)
		message[i] doFade(1,1);
	wait 2;
	for(i=0;i<message.size;i++)
		message[i] doFade(2,0);
	wait 2;
	for(i=0;i<message.size;i++)
		message[i] destroy();
}

doFade( time, alpha )
{
	self FadeOverTime(time);
	self.alpha = alpha;
}

doSpy()
{
	self endon("death");
    self endon("disconnect");

	self.cloak = 100;
	cloak = createPrimaryProgressBar(-275);
        cloakText = createPrimaryProgressBarText(-275);
        cloakText setText("^5CLOAK");
        cloakText.y = 175;
        cloak.bar.y = 190;
        cloak.y = 190;
        self thread deathDestroy(cloak.bar,cloak,cloakText);
        for(;;)
        {
                if(self fragButtonPressed() && self.cloak > 0)
                {
			self.cloak -= 3;
			self hide();
                }
                if(self.cloak < 100 && !self fragButtonPressed())
                {
			self.cloak++;
			self show();
                }
		if(self.cloak <= 0)
		{
			self.cloak = 0;
			self show();
		}
                cloak updateBar(self.cloak/100);
                cloak.bar.color = (self.cloak/100,self.cloak/100,1);
                wait 0.05;
        }
}

createBoxShader( pos1, pos2, x, y, color, width, height, alpha, sort )
{
	box = newClientHudElem(self);
	box.x = x;
	box.y = y;
	box.alignX = pos1;
	box.alignY = pos2;
	box.horzAlign = pos1;
	box.vertAlign = pos2;
	box.color = color;
	box setShader("white", width, height);
	box.alpha = alpha;
	box.sort = sort;
	return box;
}

sustainAmmo(weapon)
{
	self endon("death");
    self endon("disconnect");
	for(;;)
	{
		if(isDefined(weapon))
			self giveMaxAmmo(weapon);
		else
			self giveMaxAmmo(self GetCurrentWeapon());
		wait 1;
	}
}

rollMenu()
{
	self endon("rollChosen");
	self endon("death");
    self endon("disconnect");
	if(isDefined(self.pers["isBot"]) && self.pers["isBot"])
    { self thread rollThemDice(1,1); return; }
	self freeze_player_controls(true);
	self hide();
	bg1 = createBoxShader( "center", "middle", 0, 0, (1,1,1), 50, 50, 1, -2 );
	bg2 = createBoxShader( "center", "middle", 0, 0, (0,0,0), 44, 44, 1, -1 );
	number = createText( "objective", 2, "CENTER", "CENTER", 0, 0, "1" );
	instructs = createText( "objective", 1.8, "CENTER", "CENTER", 0, 45, "[{+activate}] Select\n[{+attack}] Up\n[{+speed_throw}] Down" );
	self thread destroyRollMenu(bg1,bg2,number,instructs);
	curRoll = 1;
	q = 1;
	for(;;)
	{
		while(!self adsButtonPressed() && !self attackButtonPressed() && !self useButtonPressed())
			wait 0.05;
		if(self useButtonPressed())
		{
			self thread rollThemDice(1,curRoll);
			self freeze_player_controls(false);
			self show();
			self notify("rollChosen");
		}
		if(self adsButtonPressed())
			q = -1;
		if(self attackButtonPressed())
			q = 1;
		curRoll += q;
		if(curRoll == 69)
			curRoll += q;
		if(curRoll == 0)
			curRoll = level.rollCount;
		if(curRoll > level.rollCount)
			curRoll = 1;
		number setText(curRoll);
		wait 0.1;
	}
}
	
destroyRollMenu(bg1,bg2,num,instructs)
{
	self waittill_any("rollChosen","death","disconnect");

	bg1 destroy();
	bg2 destroy();
	num destroy();
	instructs destroy();
}

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	if(isDefined(attacker) && isPlayer(attacker) && attacker != self)
		attacker notify("iGotAKill",self);
}

Callback_PlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
	if(isDefined(eAttacker) && isPlayer(eAttacker) && eAttacker!=self)
	{
		if(isDefined(eAttacker.oic))
			iDamage = 999;
		if(isDefined(eAttacker.doubleDamage))
			iDamage *= 2;
		if(isDefined(eAttacker.halfDamage))
			iDamage = iDamage/2;
		if(isDefined(eAttacker.vampire))
			eAttacker.health += iDamage;
	}
	self [[level.callbackPlayerDamage]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
}

