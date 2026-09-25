// Nuketown Survival by CheeseToast, supplied in King of Hax.
// Port integration: lifecycle, shared rounds, purchases and cleanup rewritten for Niggy BO1.
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
    restoreDvars();
    if(getDvarInt("jm_rtd")!=3) return;
    if(getDvar("mapname")!="mp_nuked" || getDvar("g_gametype")!="tdm") { setDvar("jm_rtd",0); return; }
    level.nz_round=1; level.nz_intermission=false; level.nz_started=false; level.nz_over=false; level.nz_assigned=false;
    level.gun=[]; level.perk=[]; level.bunkers=[]; level.gunner=[]; level.perks=[]; level.ammo=[]; level.mystery=[];
    level.nz_weapons=strTok("ak47_mp|ak74u_mp|aug_mp|crossbow_explosive_mp|cz75_mp|defaultweapon_mp|dragunov_mp|enfield_mp|famas_mp|fnfal_mp|g11_mp|galil_mp|hk21_mp|hs10_mp|knife_ballistic_mp|l96a1_mp|m16_mp|m60_mp|mac11_mp|minigun_mp|mp5k_mp|mpl_mp|pm63_mp|psg1_mp|python_mp|rpg_mp|rpk_mp|spas_mp|spectre_mp|stoner63_mp|strela_mp|uzi_mp|wa2000_mp","|");
    for(i=0;i<level.nz_weapons.size;i++) precacheItem(level.nz_weapons[i]);
    extra=strTok("m1911_mp|asp_mp|skorpion_mp|rottweil72_mp|m14_mp|acoustic_sensor_mp|claymore_mp|frag_grenade_mp|knife_mp","|");
    for(i=0;i<extra.size;i++) precacheItem(extra[i]);
    names=dvarNames(); values=strTok("0|0|0|1|0|0|Humans|Zombies","|");
    for(i=0;i<names.size;i++)
    {
        setDvar("ng_nz_saved_"+i,getDvar(names[i]));
        setDvar(names[i],values[i]);
    }
    setDvar("ng_nz_restore",1);
    doBlocks();
    initShops();
    registerBarricades();
    level thread connect();
    level thread chooseZombies();
    level thread rounds();
    level thread restoreAtEnd();
}

dvarNames()
{
    return strTok("scr_tdm_timelimit|scr_tdm_scorelimit|scr_game_killstreaks|scr_disable_weapondrop|scr_teambalance|scr_team_fftype|g_TeamName_Allies|g_TeamName_Axis","|");
}

restoreDvars()
{
    if(getDvarInt("ng_nz_restore")!=1) return;
    names=dvarNames();
    for(i=0;i<names.size;i++) { setDvar(names[i],getDvar("ng_nz_saved_"+i)); setDvar("ng_nz_saved_"+i,""); }
    setDvar("ng_nz_restore",0);
}

restoreAtEnd()
{
    level waittill("game_ended");
    restoreDvars();
}

connect()
{
    for(;;)
    {
        level waittill("connected",p);
        p thread player();
    }
}

player()
{
    self endon("disconnect");
    self.cash=500; self.nz_waiting=false;
    if(level.nz_assigned) self.nz_team="axis";
    self thread display();
    self thread spawnListener();
    self iPrintln("Nuketown Survival by CheeseToast | Infection: zombie kills turn survivors into zombies.");
    // Keep the chosen team. Spectators/new arrivals can choose a team and class normally.
    // This also handles clients auto-respawned before the connection listener starts.
    wait 0.5;
    if(isAlive(self) && !isDefined(self.nz_lifeConfigured)) self thread life();
}

spawnListener()
{
    self endon("disconnect");
    for(;;) { self waittill("spawned_player"); self thread life(); }
}

life()
{
    self endon("death"); self endon("disconnect");
    self notify("nz_new_life"); self endon("nz_new_life");
    self.nz_lifeConfigured=true;
    // Let stock loadouts and RTD cleanup finish first.
    wait 0.3;
    while(!level.nz_assigned) wait 0.1;
    if(!isDefined(self.nz_team)) self.nz_team="axis";
    if(self.pers["team"]!=self.nz_team) { self thread joinAssignedTeam(); return; }
    self.ng_adminGod=false; self.ng_adminAmmo=false; self DisableInvulnerability();
    self.nz_jugg=false; self.nz_overkill=false; self.nz_fast=false; self.nz_steady=false;
    self takeAllWeapons();
    if(self.pers["team"]=="axis")
    {
        self ZombiePerks();
        self giveWeapon("knife_ballistic_mp"); self giveWeapon("knife_mp");
        self switchToWeapon("knife_ballistic_mp");
        self setWeaponAmmoClip("knife_ballistic_mp",0); self setWeaponAmmoStock("knife_ballistic_mp",0);
        self zombieHealth();
        self placeAtTeamSpawn();
    }
    else if(self.pers["team"]=="allies")
    {
        self HumansPerks();
        self giveWeapon("m1911_mp"); self giveWeapon("asp_mp"); self giveWeapon("knife_mp"); self giveWeapon("frag_grenade_mp");
        self switchToWeapon("m1911_mp");
        self.maxhealth=400; self.health=400;
        self placeAtTeamSpawn();
        self thread purchases();
        self thread regeneration();
    }
}

zombieHealth()
{
    round=level.nz_round; if(round>20) round=20;
    self.maxhealth=100+25*(round-1); self.health=self.maxhealth;
}

onKill(attacker)
{
    if(level.nz_intermission) return;
    if(isDefined(attacker) && isPlayer(attacker) && attacker!=self && attacker.pers["team"]=="allies" && self.pers["team"]=="axis")
    { if(!isDefined(attacker.cash)) attacker.cash=500; attacker.cash+=125; }
    if(self.pers["team"]=="allies" && isDefined(attacker) && isPlayer(attacker) && attacker!=self && attacker.pers["team"]=="axis" && (!isDefined(self.switching_teams) || !self.switching_teams))
    {
        self.nz_team="axis";
        self iPrintlnBold("INFECTED! You will respawn as a zombie.");
        self thread infectedRespawn();
    }
}

infectedRespawn()
{
    self endon("disconnect");
    round=level.nz_round;
    wait 1;
    if(level.nz_intermission || round!=level.nz_round) return;
    self joinAssignedTeam();
}

chooseZombies()
{
    level endon("game_ended");
    // Give players time to reconnect after the restart. Never choose from spectators.
    if(!level.nz_started) wait 8;
    for(;;)
    {
        pool=[];
        for(i=0;i<level.players.size;i++)
        {
            p=level.players[i];
            if(isDefined(p.pers["team"]) && (p.pers["team"]=="allies" || p.pers["team"]=="axis")) pool[pool.size]=p;
        }
        if(pool.size>=2) break;
        iPrintlnBold("Nuketown Zombies needs at least 2 players. Waiting for players...");
        wait 5;
    }
    for(i=0;i<pool.size;i++) pool[i].nz_team="allies";
    count=3+randomInt(2); if(count>=pool.size) count=pool.size-1;
    remaining=pool.size;
    for(i=0;i<count;i++)
    {
        pick=randomInt(remaining); pool[pick].nz_team="axis";
        swap=pool[pick]; pool[pick]=pool[remaining-1]; pool[remaining-1]=swap;
        remaining--;
    }
    level.nz_assigned=true; level.nz_started=true;
    iPrintlnBold(count+" random zombies chosen. Last survivors: defend the house!");
    for(i=0;i<pool.size;i++) pool[i] thread joinAssignedTeam();
}

joinAssignedTeam()
{
    self endon("disconnect");
    if(isDefined(self.nz_joining)) return;
    self.nz_joining=true;
    self common_scripts\jellymod::closeModMenu();
    self common_scripts\ng_forge::stop();
    if(self.pers["team"]!=self.nz_team)
    {
        if(self.nz_team=="axis") self [[level.axis]]();
        else self [[level.allies]]();
        self [[level.class]]("smg_mp");
    }
    else if(isAlive(self)) self thread life();
    else self [[level.spawnPlayer]]();
    self.nz_joining=undefined;
}

rounds()
{
    level endon("game_ended");
    while(!level.nz_started) wait 0.5;
    deadline=getTime()+120000; grace=getTime()+10000;
    for(;;)
    {
        survivors=0; zombies=0;
        for(i=0;i<level.players.size;i++)
        {
            p=level.players[i];
            if(!isDefined(p.nz_team) || !isDefined(p.pers["team"]) || p.pers["team"]=="spectator") continue;
            if(p.nz_team=="allies") survivors++; else zombies++;
        }
        if(getTime()>grace && (survivors==0 || zombies==0 || getTime()>=deadline))
        {
            if(survivors==0) iPrintlnBold("Zombies win round "+level.nz_round+"!");
            else iPrintlnBold("Survivors win round "+level.nz_round+"!");
            level.nz_intermission=true;
            wait 5;
            level.nz_round++;
            for(i=0;i<level.players.size;i++)
            {
                p=level.players[i]; p.cash=500;
                p common_scripts\ng_forge::stop();
                p common_scripts\jellymod::closeModMenu();
            }
            chooseZombies();
            level.nz_intermission=false;
            deadline=getTime()+120000; grace=getTime()+10000;
            iPrintlnBold("Round "+level.nz_round+": survive for 2 minutes!");
        }
        wait 0.5;
    }
}

placeAtTeamSpawn()
{
    // The original source's house interior and exterior anchors, spread to avoid stacking.
    slot=(self getEntityNumber())%4;
    if(self.nz_team=="axis")
    { self setOrigin((1100+slot*32,823,-45)); self setPlayerAngles((0,60,0)); }
    else
    { self setOrigin((841+slot*22,584,-34)); self setPlayerAngles((0,225,0)); }
}

registerBarricades()
{
    for(i=1;i<=28;i++) if(isDefined(level.bunkers[i])) level.bunkers[i] registerSolid();
    for(i=1;i<=4;i++) if(isDefined(level.perk[i])) level.perk[i] registerSolid();
    level.ammobox registerSolid(); level.Mbox registerSolid();
}

registerSolid()
{
    self.ng_locked=true; self.ng_model="mp_supplydrop_ally";
    self common_scripts\ng_forge::captureBounds();
    self solid();
    level.ng_solidProps[level.ng_solidProps.size]=self;
}


display()
{
    self endon("disconnect");
    hud=self createFontString("objective",1.35);
    hud setPoint("TOPLEFT","TOPLEFT",10,35); hud.sort=5;
    self thread common_scripts\jellymod::destroyEvent(hud,"disconnect","game_ended");
    old="";
    for(;;)
    {
        message="^3Nuketown Survival ^7| Round "+level.nz_round+" ^2$"+self.cash;
        if(isDefined(self.nz_team)) { if(self.nz_team=="axis") message+=" ^1ZOMBIE"; else message+=" ^2SURVIVOR"; }
        if(message!=old) { hud setText(message); old=message; }
        if(self.menuOpen) hud.alpha=0; else hud.alpha=1;
        wait 0.5;
    }
}

regeneration()
{
    self endon("death"); self endon("disconnect"); self endon("nz_new_life");
    for(;;)
    {
        if(self.health<self.maxhealth)
        {
            delay=5; if(self.nz_jugg) delay=8;
            wait delay;
            if(isAlive(self)) self.health=self.maxhealth;
        }
        wait 0.25;
    }
}

initShops()
{
    level.nz_shops=[];
    shop(level.gun["skorpion"],"Skorpion",500,"skorpion_mp");
    shop(level.gun["rottweil72"],"Olympia",500,"rottweil72_mp");
    shop(level.gun["m14"],"M14",500,"m14_mp");
    shop(level.gun["acoustic_sensor"],"Motion Sensor",250,"acoustic_sensor_mp");
    shop(level.gun["claymore"],"Claymore",100,"claymore_mp");
    shop(level.perk[1],"Juggernaut",2000,"jugg");
    shop(level.perk[2],"Overkill - 3 guns",1000,"overkill");
    shop(level.perk[3],"Sleight of Hand Pro",1500,"fast");
    shop(level.perk[4],"Steady Aim",500,"steady");
    shop(level.ammobox,"Ammo",300,"ammo");
    shop(level.Mbox,"Mystery Box",750,"mystery");
}

shop(entity,name,cost,item)
{
    s=spawnStruct(); s.entity=entity; s.name=name; s.cost=cost; s.item=item;
    level.nz_shops[level.nz_shops.size]=s;
}

purchases()
{
    self endon("death"); self endon("disconnect"); self endon("nz_new_life");
    down=true; last=-1;
    for(;;)
    {
        pressed=self useButtonPressed(); found=-1; nearest=3600;
        if(!self.menuOpen && self.pers["team"]=="allies" && !self.nz_waiting)
        {
            for(i=0;i<level.nz_shops.size;i++)
            {
                d=distanceSquared(self.origin,level.nz_shops[i].entity.origin);
                if(d<nearest) { nearest=d; found=i; }
            }
            if(found>=0)
            {
                s=level.nz_shops[found];
                if(found!=last) self iPrintln("USE: "+s.name+" ^2$"+s.cost);
                if(pressed && !down) self buy(s);
            }
        }
        last=found; down=pressed;
        wait 0.1;
    }
}

buy(s)
{
    item=s.item;
    if((item=="jugg" && self.nz_jugg) || (item=="overkill" && self.nz_overkill) || (item=="fast" && self.nz_fast) || (item=="steady" && self.nz_steady))
    { self iPrintln("Already owned this life."); return; }
    if(item=="ammo" && self getCurrentWeapon()=="minigun_mp") { self iPrintln("The Death Machine cannot buy ammo."); return; }
    if(self.cash<s.cost) { self iPrintln("Not enough cash."); return; }
    self.cash-=s.cost;
    switch(item)
    {
        case "jugg": self.nz_jugg=true; self.maxhealth=720; self.health=720; break;
        case "overkill": self.nz_overkill=true; self giveWeapon("python_mp"); self setWeaponAmmoClip("python_mp",0); self setWeaponAmmoStock("python_mp",0); self iPrintln("Swap the empty Python for a third weapon."); break;
        case "fast": self.nz_fast=true; self setPerk("specialty_fastreload"); self setPerk("specialty_fastads"); break;
        case "steady": self.nz_steady=true; self setPerk("specialty_bulletaccuracy"); break;
        case "ammo": self giveMaxAmmo(self getCurrentWeapon()); self giveMaxAmmo("m1911_mp"); self giveMaxAmmo("asp_mp"); self setWeaponAmmoStock("frag_grenade_mp",1); break;
        case "mystery": self mysteryWeapon(); break;
        default:
            if(item!="acoustic_sensor_mp" && item!="claymore_mp") self takeWeapon(self getCurrentWeapon());
            self giveWeapon(item); self giveMaxAmmo(item); self switchToWeapon(item); break;
    }
}

mysteryWeapon()
{
    self endon("death"); self endon("disconnect"); self endon("nz_new_life");
    weapon=level.nz_weapons[randomInt(level.nz_weapons.size)];
    self iPrintlnBold(weapon+" | FIRE: keep / AIM: leave");
    // No frozen controls or unbounded prompt threads if a player dies or walks away.
    deadline=getTime()+8000;
    while(self attackButtonPressed() || self adsButtonPressed()) { if(getTime()>deadline) return; wait 0.05; }
    while(getTime()<deadline)
    {
        if(self.menuOpen || self adsButtonPressed()) return;
        if(self attackButtonPressed())
        {
            self takeWeapon(self getCurrentWeapon()); self giveWeapon(weapon); self giveMaxAmmo(weapon); self switchToWeapon(weapon); return;
        }
        wait 0.05;
    }
}

createGun( pos, angle, gun )
{
	level.gun[gun] = spawn( "script_model", pos, 1 );
	level.gun[gun] setModel( getWeaponModel( gun + "_mp" ) );
	level.gun[gun].angles = angle;
}

createBlock( pos, angle )
{
        crate = spawn( "script_model", pos, 1 );
        crate setModel( "mp_supplydrop_ally" );
        crate.angles = angle;
        crate solid();
        return crate;
}

createPerk( pos, angle, num )
{
        level.perk[num] = spawn( "script_model", pos, 1 );
        level.perk[num] setModel( "mp_supplydrop_axis" );
        level.perk[num].angles = angle;
}

AmmoBox( pos, angle )
{
        level.ammobox = spawn( "script_model", pos, 1 );
        level.ammobox setModel( "mp_supplydrop_axis" );
        level.ammobox.angles = angle;	
}

MysteryBox( pos, angle )
{
        level.Mbox = spawn( "script_model", pos, 1 );
        level.Mbox setModel( "mp_supplydrop_boobytrapped" );
        level.Mbox.angles = angle;	
}

doBlocks()
{
	level.bunkers[1] = createBlock( ( 575, 116, -31), (0, 195, 0) );	
	level.bunkers[2] = createBlock( ( 575, 116, -46), (0, 195, 0) );		
	level.bunkers[3] = createBlock( ( 551, 111, -46), (0, 195, 0) );
	level.bunkers[4] = createBlock( ( 1146, 306, 92), (0, 195, 0) );	
	level.bunkers[5] = createBlock( ( 1146, 306, 107), (0, 195, 0) );
	level.bunkers[6] = createBlock( ( 1180, 312, 92), (0, 195, 0) );
	level.bunkers[7] = createBlock( ( 1155, 267, -31), (0, 195, 0) );	
	level.bunkers[8] = createBlock( ( 1155, 267, -46), (0, 195, 0) );
	level.bunkers[9] = createBlock( ( 1189, 273, -46), (0, 195, 0) );
	level.bunkers[10] = createBlock( ( 681, 518, -41), (0, 195, 0) );
	level.bunkers[11] = createBlock( ( 681, 518, -6), (0, 195, 0) );
	level.bunkers[12] = createBlock( ( 681, 518, 29), (0, 195, 0) );
	level.bunkers[13] = createBlock( ( 700, 456, -41), (0, 195, 0) );
	level.bunkers[14] = createBlock( ( 700, 456, -6), (0, 195, 0) );
	level.bunkers[15] = createBlock( ( 700, 456, 29), (0, 195, 0) );
	level.bunkers[16] = createBlock( ( 1010, 693, -41), (0, 195, 0) );	
	level.bunkers[17] = createBlock( ( 1010, 693, -6), (0, 195, 0) );
	level.bunkers[18] = createBlock( ( 1010, 693, 29), (0, 195, 0) );
	level.bunkers[19] = createBlock( ( 745, 146, 96), (0, 195, 0) );
	level.bunkers[20] = createBlock( ( 745, 146, 111), (0, 195, 0) );
	level.bunkers[21] = createBlock( ( 696, 205, 96), (0, 243, 0) );
	level.bunkers[22] = createBlock( ( 696, 205, 111), (0, 243, 0) );
	level.bunkers[23] = createBlock( ( 591, 209, 96), (0, 282, 0) );
	level.bunkers[24] = createBlock( ( 591, 209, 111), (0, 282, 0) );
	level.bunkers[25] = createBlock( ( 618, 216, 96), (0, 282, 0) );
	level.bunkers[26] = createBlock( ( 618, 216, 111), (0, 282, 0) );
	level.bunkers[27] = createBlock( ( 680, 174, 96), (0, 243, 0) );
	level.bunkers[28] = createBlock( ( 665, 302, 166), (0, 195, 0) );

	level.gunner[1] = createGun( ( 677, 596, -8 ), ( 0, 105, 0 ), "m14" );
	level.gunner[2] = createGun( ( 660, 650, -8 ), ( 0, 105, 0 ), "rottweil72" );
	level.gunner[3] = createGun( ( 910, 179, -3 ), ( 0, 105, 0 ), "skorpion" );
	level.gunner[4] = createGun( ( 795, 425, -8), ( 90, 105, 0 ), "acoustic_sensor" );
	level.gunner[5] = createGun( ( 795, 425, -32), ( 90, 105, 0 ), "claymore" );

	level.perks[1] = createPerk( ( 950, 747, -32 ), ( 0, 285, 90 ), 1 );
	level.perks[2] = createPerk( ( 900, 734, -32 ), ( 0, 285, 90 ), 2 );
	level.perks[3] = createPerk( ( 850, 721, -32 ), ( 0, 285, 90 ), 3 );
	level.perks[4] = createPerk( ( 800, 707, -32 ), ( 0, 285, 90 ), 4 );

	level.ammo[1] = AmmoBox( ( 845, 454, -25), (0, 105, 90) );
	level.mystery[1] = MysteryBox( ( 799, 376, -37), (0, 195, 0) );
}

HumansPerks()
{
	self endon ( "disconnect" );

	self clearPerks();
	self setPerk("specialty_healthregen");
	self setPerk("specialty_finalstand");  
	self setPerk("specialty_pistoldeath"); 
	self setPerk("specialty_quieter");  
	self setPerk("specialty_loudenemies");
	self setPerk("specialty_nomotionsensor"); 
	self setPerk("specialty_gpsjammer");
}

ZombiePerks()
{
	self endon ( "disconnect" );

	self clearPerks();
	self setPerk("specialty_gpsjammer");  
	self setPerk("specialty_reconnaissance");  
	self setPerk("specialty_nottargetedbyai");  
	self setPerk("specialty_noname");
	self setPerk("specialty_detectexplosive");
}

