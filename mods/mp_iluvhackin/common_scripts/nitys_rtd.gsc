#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// Niggy menu RTD extension. One roll per spawn; no client commands or key rebinding.
init()
{
    if( isDefined( level.rtd_initialized ) ) return;
    level.rtd_initialized = true;
    if(getDvar("ng_rtd_nextmode")=="rtd") setDvar("jm_rtd",1);
    else if(getDvar("ng_rtd_nextmode")=="rtd2") setDvar("jm_rtd",2);
    else if(getDvar("ng_rtd_nextmode")=="nuketown") setDvar("jm_rtd",3);
    else if(getDvar("ng_rtd_nextmode")=="bounty") setDvar("jm_rtd",4);
    else setDvar("jm_rtd",0);
    setDvar("ng_rtd_nextmode","");
    precacheShader( "white" );
    precacheShader( "waypoint_targetneutral" );
    precacheItem( "defaultweapon_mp" );
    precacheItem( "l96a1_mp" );
    precacheItem( "hatchet_mp" );
    precacheItem( "crossbow_explosive_mp" );
    weapons=strTok("python_mp|rpg_mp|mp5k_silencer_mp|rottweil72_mp|minigun_mp|m202_flash_mp|knife_ballistic_mp|ak47_mp|m60_mp","|");
    for(w=0;w<weapons.size;w++) precacheItem(weapons[w]);
    level thread endMatch();
}

endMatch()
{
    level waittill( "game_ended" );
    for( i = 0; i < level.players.size; i++ )
        level.players[i] cleanup();
}

spawnRoll()
{
    self endon( "disconnect" );
    self cleanup();
    if(isDefined(self.ng_bishop_owner)) return;
    self endon( "death" );
    self endon( "rtd_stop" );
    // Class loadout and movement modifiers finish before a roll is applied.
    wait 0.5;
    if( getDvarInt( "jm_rtd" ) != 1 || !isAlive( self ) || self.sessionstate != "playing" ) return;
    if( isDefined( level.gameEnded ) && level.gameEnded ) return;
    pool = rollIds();
    roll = pool[randomInt( pool.size )];
    while( isDefined( self.rtd_previous ) && roll == self.rtd_previous )
        roll = pool[randomInt( pool.size )];
    forced = getDvar( "jm_rtd_force" );
    for( i = 0; i < pool.size; i++ )
        if( forced == pool[i] || forced == ""+(i+1) ) roll = pool[i];
    number=1;
    for(i=0;i<pool.size;i++) if(pool[i]==roll) number=i+1;
    self.rtd_number=number;
    self.rtd_previous = roll;
    self.rtd_roll = roll;
    self.rtd_speed = self getMoveSpeedScale();
    self.rtd_health = self.maxhealth;
    self.rtd_icons = [];
    self.rtd_shots = 0;
    self.rtd_started = getTime();
    self thread deathCleanup();
    self thread shots();
    self thread kills();
    label = "";
    hint = "Until your next death";
    switch( roll )
    {
        case "scream": label = "Orgasm"; hint = "MP fire screams; repeats until death"; self thread screams(); break;
        case "blur": label = "Dropped My Glasses"; self setClientDvar( "r_blur_allowed", 1 ); self setClientDvar( "r_blur", 3 ); break;
        case "fire": label = "On Fire"; hint = "5 burn damage per second"; self thread burnLoop( false ); break;
        case "uav": label = "Infinite UAV"; self thread radar(); break;
        case "snackbar": label = "Snackbar"; hint = "Explode in 30 seconds"; self thread timeBomb(); break;
        case "defaultweapon": label = "Default Weapon"; self grant( "defaultweapon_mp" ); break;
        case "killstreak": label = "Random Killstreak"; self randomStreak(); break;
        case "rubber": label = "Bullets Do No Damage"; hint = "Your bullet damage is zero"; break;
        case "ricochet": label = "Ricochet Rounds"; hint = "Your bullet damage hits you instead"; break;
        case "slow": label = "Cement Shoes"; self setMoveSpeedScale( self.rtd_speed * 0.5 ); break;
        case "fast": label = "Super Speed"; self setMoveSpeedScale( self.rtd_speed * 1.5 ); break;
        case "falls": label = "Tungsten Ballsack"; hint = "Double fall damage"; break;
        case "sounds": label = "Kill Sound Roulette"; hint = "Random local sound on every enemy kill"; break;
        case "strength": label = "Strength Bonus"; hint = "+50% direct weapon damage"; break;
        case "lava": label = "The Floor Is Lava"; hint = "Starts in 5s; 10 damage per second on ground"; self thread burnLoop( true ); break;
        case "headshots": label = "Headshots Only"; hint = "Your bullets only hurt on headshots"; break;
        case "aimbot": label = "10 Second Aimbot"; hint = "Hold ADS: aims at a visible enemy; fire manually"; self thread aimAssist(); break;
        case "explosive": label = "Explosive Rounds"; hint = "Every fifth gunshot explodes"; break;
        case "sniper": label = "L96A1 + Tomahawk"; self takeAllWeapons(); self grant( "l96a1_mp" ); self giveWeapon( "hatchet_mp" ); self setOffhandPrimaryClass( "hatchet_mp" ); self giveMaxAmmo( "hatchet_mp" ); break;
        case "wallhacks": label = "Wallhacks"; hint = "Enemy location markers through walls"; self thread enemyMarkers(); break;
        case "noclip": label = "No Collision"; hint = "Hold USE to fly through walls; melee returns you to start"; self thread phaseFlight(); break;
        case "shake": label = "Camera Shake"; self thread shake(); break;
        case "knife": label = "Knife Only"; hint = "20 seconds of melee-only damage and empty guns"; self thread knifeOnly(); break;
        case "grenades": label = "Unlimited Nades"; hint = "Refills equipped frag/semtex, claymore or C4"; self thread grenades(); break;
        case "armor": label = "Thick Skin"; hint = "Half incoming damage"; break;
        case "vampire": label = "Vampire"; hint = "Enemy kills heal 30 HP"; break;
        case "fragile": label = "Glass Cannon"; hint = "1 HP, double direct weapon damage"; self.health = 1; break;
        case "tunnel": label = "Tunnel Vision"; hint = "A heavily darkened view."; self overlay( (0,0,0), 0.82 ); break;
        case "rainbow": label = "Rainbow Flash Rounds"; hint = "Full-screen rainbow flashes with each gunshot."; self overlay( (1,0,1), 0 ); break;
        case "gravitykick": label = "Gravity Kick on Kill"; hint = "Enemy kills launch YOU upward"; break;
        case "disco": label = "Disco Tint"; hint = "A cycling rainbow tint covers your view."; self overlay( (1,0,0), 0.2 ); self thread disco(); break;
        case "crawl": label = "Crawl Pace"; hint = "25% movement speed."; self setMoveSpeedScale( self.rtd_speed * 0.25 ); break;
        case "drunk": label = "Drunk Sway"; hint = "Your camera sways."; self thread sway(); break;
        case "noisy": label = "Everyone Hears You"; hint = "Loud positional beeps give you away."; self thread noisy(); break;
        case "teleport": label = "Random Teleport"; hint = "YOU move to a free map spawn after 3 seconds"; self thread teleport(); break;
        case "mirror": label = "Turnaround"; hint = "Your view turns 180 degrees every 6 seconds"; self thread turnaround(); break;
        case "cartoon": label = "Cartoon Bounce"; hint = "You bounce automatically."; self thread bounce(); break;
        case "dance": label = "Dance Spin"; hint = "Your camera spins for 3 seconds."; self thread dance(); break;
        case "raybow": label = "Raybow"; hint = "Equip an explosive crossbow."; self grant( "crossbow_explosive_mp" ); break;
    }
    names=rollNames(); hints=rollHints();
    label=names[number-1]; hint=hints[number-1];
    self common_scripts\niggy_extra::apply(roll);
    self.rtd_label = label;
    self.rtd_hud = self createFontString( "objective", 1.3 );
    self.rtd_hud setPoint( "TOP", "TOP", 0, 45 );
    self.rtd_hud setText( "^3RTD #"+number+": ^7" + label );
    self iPrintlnBold( "^3RTD #"+number+": ^7" + label );
    self iPrintln( "^3RTD: ^7" + hint );
}

deathCleanup()
{
    self endon( "disconnect" );
    self endon( "rtd_stop" );
    self waittill( "death" );
    self cleanup();
}

cleanup()
{
    // Clear the flag before stopping workers. Caller must not be a worker with rtd_stop endon.
    self common_scripts\niggy_extra::cleanup();
    prior = "";
    if( isDefined( self.rtd_roll ) ) prior = self.rtd_roll;
    self.rtd_roll = "";
    if( isDefined( self.rtd_hud ) ) self.rtd_hud destroy();
    self.rtd_hud = undefined;
    if( isDefined( self.rtd_overlay ) ) self.rtd_overlay destroy();
    self.rtd_overlay = undefined;
    if( isDefined( self.rtd_icons ) )
        for( i = 0; i < self.rtd_icons.size; i++ )
            if( isDefined( self.rtd_icons[i] ) ) self.rtd_icons[i] destroy();
    self.rtd_icons = [];
    if( isDefined( self.rtd_anchor ) )
    {
        self unlink();
        self.rtd_anchor delete();
        self.rtd_anchor = undefined;
    }
    if( prior == "slow" || prior == "fast" || prior == "crawl" )
        if( isDefined( self.rtd_speed ) ) self setMoveSpeedScale( self.rtd_speed );
    if( prior == "blur" )
    {
        self setClientDvar( "r_blur", 0 );
        self setClientDvar( "r_blur_allowed", 0 );
    }
    if( prior == "uav" ) self setClientUIVisibilityFlag( "g_compassShowEnemies", getDvarInt( "scr_game_forceradar" ) );
    self.rtd_knife = false;
    self notify( "rtd_stop" );
}

has( roll )
{
    return isDefined( self.rtd_roll ) && self.rtd_roll == roll;
}

// Called from the real BO1 engine callback, before the stock damage implementation.
damage( inflictor, attacker, amount, flags, mod, weapon, point, direction, hitloc, offset )
{
    bullet = mod == "MOD_RIFLE_BULLET" || mod == "MOD_PISTOL_BULLET" || mod == "MOD_HEAD_SHOT";
    direct = bullet || mod == "MOD_MELEE" || mod == "MOD_PROJECTILE" || mod == "MOD_PROJECTILE_SPLASH" || mod == "MOD_GRENADE" || mod == "MOD_GRENADE_SPLASH";
    if( isDefined( attacker ) && isPlayer( attacker ) && attacker != self )
    {
        if( bullet && attacker has( "rubber" ) ) return;
        if( bullet && attacker has( "headshots" ) && mod != "MOD_HEAD_SHOT" && hitloc != "head" && hitloc != "helmet" ) return;
        if( isDefined( attacker.rtd_knife ) && attacker.rtd_knife && mod != "MOD_MELEE" ) return;
        if( bullet && attacker has( "ricochet" ) )
        {
            attacker [[level.callbackPlayerDamage]]( attacker, attacker, amount, flags, "MOD_SUICIDE", weapon, attacker.origin, direction, "none", offset );
            return;
        }
        if( direct && attacker has( "strength" ) ) amount = int( amount * 1.5 );
        if( direct && attacker has( "fragile" ) ) amount *= 2;
    }
    if( mod == "MOD_FALLING" && self has( "falls" ) ) amount *= 2;
    if( self has( "armor" ) ) amount = int( amount * 0.5 );
    if( amount < 0 ) amount = 0;
    amount=self common_scripts\niggy_extra::modifyDamage(attacker,amount,mod,weapon,point,direction,hitloc,offset);
    if(amount<=0) return;
    self [[level.callbackPlayerDamage]]( inflictor, attacker, amount, flags, mod, weapon, point, direction, hitloc, offset );
}

onKill( attacker )
{
    if( !isDefined( attacker ) || !isPlayer( attacker ) || attacker == self || !isAlive( attacker ) ) return;
    if( isDefined( level.teambased ) && level.teambased && attacker.pers["team"] == self.pers["team"] ) return;
    attacker notify( "rtd_kill", self.origin );
}

grant( weapon )
{
    self giveWeapon( weapon );
    self giveMaxAmmo( weapon );
    self switchToWeapon( weapon );
}

randomStreak()
{
    options = strTok( "radar_mp|counteruav_mp|radardirection_mp|mortar_mp|rcbomb_mp|supplydrop_mp|dogs_mp", "|" );
    available = [];
    for( i = 0; i < options.size; i++ )
        if( isDefined( level.killstreaks[options[i]] ) ) available[available.size] = options[i];
    if( available.size == 0 ) { self iPrintln( "^3RTD: Killstreaks unavailable in this mode" ); return; }
    choice = available[randomInt( available.size )];
    self maps\mp\gametypes\_hardpoints::giveKillstreak( choice, undefined, true, true );
    self iPrintln( "^3RTD: ^7" + choice );
}

screams()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    for(;;)
    {
        if( isDefined( self.bcVoiceNumber ) && isDefined( self.team ) && isDefined( level.teamPrefix[self.team] ) && isDefined( level.bcSounds["fire"] ) )
            self playSound( level.teamPrefix[self.team] + "_" + self.bcVoiceNumber + "_" + level.bcSounds["fire"] + "_scream" );
        wait 3;
    }
}

burnLoop( lava )
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    if( lava ) wait 5;
    for(;;)
    {
        if( !lava || self isOnGround() )
        {
            self setBurn( 0.8 );
            self notify( "snd_burn_scream" );
            if( lava ) amount = 10; else amount = 5;
            self hurt( amount );
        }
        wait 1;
    }
}

hurt( amount )
{
    if( !isAlive( self ) ) return;
    // Stock damage handling retains hit feedback, death callbacks and score bookkeeping.
    self [[level.callbackPlayerDamage]]( self, self, amount, 0, "MOD_BURNED", "none", self.origin, (0,0,0), "none", 0 );
}

radar()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    for(;;) { self setClientUIVisibilityFlag( "g_compassShowEnemies", 1 ); wait 0.5; }
}

timeBomb()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    for( left = 30; left > 0; left-- )
    {
        if( left <= 5 || left == 10 || left == 20 ) self iPrintlnBold( "^1Snackbar: " + left );
        wait 1;
    }
    pos = self.origin;
    playFx( level._effect["jm_expbullet"], pos );
    radiusDamage( pos, 200, 150, 30, self );
    if( isAlive( self ) ) self suicide();
}

shots()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    for(;;)
    {
        self waittill( "weapon_fired", weapon );
        if( !isDefined( weapon ) ) weapon = self getCurrentWeapon();
        if( weapon == "frag_grenade_mp" || weapon == "sticky_grenade_mp" || weapon == "hatchet_mp" || weapon == "claymore_mp" || weapon == "satchel_charge_mp" ) continue;
        self.rtd_shots++;
        self common_scripts\niggy_extra::shot();
        if( self has( "explosive" ) && self.rtd_shots % 5 == 0 )
        {
            start = self getTagOrigin( "j_head" );
            trace = bulletTrace( start, start + anglesToForward( self getPlayerAngles() ) * 100000, true, self );
            playFx( level._effect["jm_expbullet"], trace["position"] );
            radiusDamage( trace["position"], 160, 90, 15, self );
        }
        if( self has( "rainbow" ) && isDefined( self.rtd_overlay ) )
        {
            self.rtd_overlay.color = (randomFloat(1),randomFloat(1),randomFloat(1));
            self.rtd_overlay.alpha = 0.85;
            self.rtd_overlay fadeOverTime( 0.5 );
            self.rtd_overlay.alpha = 0;
        }
    }
}

kills()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    sounds = strTok( "mp_challenge_complete|uin_timer_wager_beep|uin_alert_cash_register|mpl_oic_bullet_pickup", "|" );
    for(;;)
    {
        self waittill( "rtd_kill", victimOrigin );
        self common_scripts\niggy_extra::killed(victimOrigin);
        if( self has( "sounds" ) ) self playLocalSound( sounds[randomInt( sounds.size )] );
        if( self has( "gravitykick" ) ) self setVelocity( self getVelocity() + (0,0,400) );
        if( self has( "vampire" ) )
        {
            self.health += 30;
            if( self.health > self.maxhealth ) self.health = self.maxhealth;
        }
    }
}

aimAssist()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    until = getTime() + 10000;
    while( getTime() < until )
    {
        if( self adsButtonPressed() && !self.menuOpen )
        {
            target = undefined; nearest = 100000;
            for( i = 0; i < level.players.size; i++ )
            {
                p = level.players[i];
                if( !self enemy( p ) ) continue;
                d = distance( self.origin, p.origin );
                trace = bulletTrace( self getTagOrigin("j_head"), p getTagOrigin("j_head"), true, self );
                if( d < nearest && (trace["fraction"] >= 0.99 || (isDefined(trace["entity"]) && trace["entity"] == p)) )
                { target = p; nearest = d; }
            }
            if( isDefined( target ) ) self setPlayerAngles( vectorToAngles( target getTagOrigin("j_head") - self getTagOrigin("j_head") ) );
        }
        wait 0.05;
    }
    self iPrintln( "^3RTD: Aimbot expired" );
}

enemy( p )
{
    if( !isDefined(p) || p == self || !isAlive(p) || p.sessionstate != "playing" ) return false;
    if( isDefined(level.teambased) && level.teambased && p.pers["team"] == self.pers["team"] ) return false;
    return true;
}

enemyMarkers()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    for(;;)
    {
        for( i = 0; i < self.rtd_icons.size; i++ ) if( isDefined(self.rtd_icons[i]) ) self.rtd_icons[i] destroy();
        self.rtd_icons = [];
        for( i = 0; i < level.players.size; i++ )
        {
            p = level.players[i];
            if( !self enemy(p) ) continue;
            icon = newClientHudElem( self );
            icon setShader( "waypoint_targetneutral", 12, 12 );
            icon.color = (1,0.15,0.15);
            icon.alpha = 0.8;
            icon setWaypoint( true );
            icon setTargetEnt( p );
            self.rtd_icons[self.rtd_icons.size] = icon;
        }
        wait 0.5;
    }
}

phaseFlight()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    self.rtd_phaseOrigin = self.origin;
    self.rtd_anchor = spawn( "script_origin", self.origin );
    self thread deleteAnchorOnDisconnect( self.rtd_anchor );
    self linkTo( self.rtd_anchor );
    while( self useButtonPressed() || self meleeButtonPressed() ) wait 0.05;
    for(;;)
    {
        if( !self.menuOpen && self useButtonPressed() ) self.rtd_anchor.origin += anglesToForward( self getPlayerAngles() ) * 20;
        if( !self.menuOpen && self meleeButtonPressed() ) break;
        wait 0.05;
    }
    self unlink(); self.rtd_anchor delete(); self.rtd_anchor = undefined;
    self setOrigin( self.rtd_phaseOrigin );
    self iPrintln( "^3RTD: Flight ended" );
}

deleteAnchorOnDisconnect( anchor )
{
    // Entity deletion is also needed when disconnect ends the ordinary player workers.
    self endon( "rtd_stop" );
    self waittill( "disconnect" );
    if( isDefined( anchor ) ) anchor delete();
}

shake()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    for(;;) { earthquake( 0.15, 0.5, self.origin, 64, self ); wait 0.5; }
}

knifeOnly()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    self.rtd_knife = true;
    weapons = self getWeaponsList();
    weapons = array_remove( weapons, "knife_mp" );
    clips = []; stocks = [];
    for( i = 0; i < weapons.size; i++ )
    {
        clips[i] = self getWeaponAmmoClip( weapons[i] );
        stocks[i] = self getWeaponAmmoStock( weapons[i] );
    }
    until = getTime() + 20000;
    while( getTime() < until )
    {
        current = self getWeaponsList();
        current = array_remove( current, "knife_mp" );
        for( i = 0; i < current.size; i++ )
        { self setWeaponAmmoClip(current[i],0); self setWeaponAmmoStock(current[i],0); }
        wait 0.1;
    }
    self.rtd_knife = false;
    for( i = 0; i < weapons.size; i++ )
        if( self hasWeapon(weapons[i]) ) { self setWeaponAmmoClip(weapons[i],clips[i]); self setWeaponAmmoStock(weapons[i],stocks[i]); }
    self iPrintln( "^3RTD: Knife-only expired" );
}

grenades()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    types = strTok( "frag_grenade_mp|sticky_grenade_mp|claymore_mp|satchel_charge_mp", "|" );
    for(;;)
    {
        for( i = 0; i < types.size; i++ ) if( self hasWeapon(types[i]) ) self giveMaxAmmo(types[i]);
        wait 0.5;
    }
}

overlay( color, alpha )
{
    self.rtd_overlay = newClientHudElem( self );
    self.rtd_overlay.horzAlign = "fullscreen"; self.rtd_overlay.vertAlign = "fullscreen";
    self.rtd_overlay.alignX = "center"; self.rtd_overlay.alignY = "middle";
    self.rtd_overlay.x = 320; self.rtd_overlay.y = 240;
    self.rtd_overlay setShader( "white", 4096, 4096 );
    self.rtd_overlay.color = color; self.rtd_overlay.alpha = alpha;
    self.rtd_overlay.sort = -10;
}

disco()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    colors = []; colors[0]=(1,0,0); colors[1]=(0,1,0); colors[2]=(0,0,1); colors[3]=(1,0,1); colors[4]=(1,1,0);
    i=0;
    for(;;) { self.rtd_overlay.color=colors[i]; i=(i+1)%colors.size; wait 1; }
}

sway()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    t=0;
    for(;;)
    {
        if( !self.menuOpen ) { a=self getPlayerAngles(); self setPlayerAngles((a[0]+sin(t)*0.5,a[1]+cos(t)*0.7,0)); }
        t+=12; wait 0.05;
    }
}

noisy()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    for(;;) { self playSound( "uin_timer_wager_beep" ); wait 4; }
}

teleport()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    wait 3;
    if( !isDefined(level.spawnpoints) || level.spawnpoints.size == 0 ) { self iPrintln("^3RTD: No map spawnpoints available"); return; }
    start=randomInt(level.spawnpoints.size);
    for( n=0; n<level.spawnpoints.size; n++ )
    {
        p=level.spawnpoints[(start+n)%level.spawnpoints.size]; occupied=false;
        for( i=0; i<level.players.size; i++ )
            if( isAlive(level.players[i]) && distance(level.players[i].origin,p.origin)<100 ) occupied=true;
        if( !occupied ) { self setOrigin(p.origin+(0,0,10)); self setPlayerAngles(p.angles); return; }
    }
    self iPrintln("^3RTD: All spawnpoints occupied; teleport skipped");
}

turnaround()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    for(;;) { wait 6; if(!self.menuOpen) { a=self getPlayerAngles(); self setPlayerAngles((a[0],a[1]+180,0)); } }
}

bounce()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    for(;;) { if(self isOnGround() && !self.menuOpen) self setVelocity(self getVelocity()+(0,0,220)); wait 1; }
}

dance()
{
    self endon( "death" ); self endon( "disconnect" ); self endon( "rtd_stop" );
    for(i=0;i<60;i++) { if(!self.menuOpen) { a=self getPlayerAngles(); self setPlayerAngles((a[0],a[1]+6,0)); } wait 0.05; }
}

rollIds()
{
    a=[];
    a[0]="scream";
    a[1]="blur";
    a[2]="fire";
    a[3]="uav";
    a[4]="snackbar";
    a[5]="defaultweapon";
    a[6]="killstreak";
    a[7]="rubber";
    a[8]="ricochet";
    a[9]="slow";
    a[10]="fast";
    a[11]="falls";
    a[12]="sounds";
    a[13]="strength";
    a[14]="lava";
    a[15]="headshots";
    a[16]="aimbot";
    a[17]="explosive";
    a[18]="sniper";
    a[19]="wallhacks";
    a[20]="noclip";
    a[21]="shake";
    a[22]="knife";
    a[23]="grenades";
    a[24]="armor";
    a[25]="vampire";
    a[26]="fragile";
    a[27]="tunnel";
    a[28]="rainbow";
    a[29]="gravitykick";
    a[30]="disco";
    a[31]="crawl";
    a[32]="drunk";
    a[33]="noisy";
    a[34]="teleport";
    a[35]="mirror";
    a[36]="cartoon";
    a[37]="dance";
    a[38]="raybow";
    a[39]="bishop";
    a[40]="juggernaut";
    a[41]="speed_demon";
    a[42]="snail";
    a[43]="regenerator";
    a[44]="poison";
    a[45]="bloodsucker";
    a[46]="thorns";
    a[47]="damage_dice";
    a[48]="critical";
    a[49]="first_shield";
    a[50]="second_wind";
    a[51]="mercy";
    a[52]="executioner";
    a[53]="medic_bullets";
    a[54]="blood_donor";
    a[55]="heavy_caliber";
    a[56]="featherweight";
    a[57]="moonboots";
    a[58]="anchor";
    a[59]="blink";
    a[60]="kill_teleport";
    a[61]="rewind";
    a[62]="supply_fairy";
    a[63]="roulette_gun";
    a[64]="pistol_party";
    a[65]="rocketman";
    a[66]="silent_runner";
    a[67]="boomstick";
    a[68]="deathmachine";
    a[69]="grim_reaper";
    a[70]="crossbow_club";
    a[71]="ballistic";
    a[72]="kalashnikov";
    a[73]="rambo";
    a[74]="scavenger";
    a[75]="dry_mag";
    a[76]="bottomless";
    a[77]="one_bullet";
    a[78]="blood_ammo";
    a[79]="rocket_boots";
    a[80]="recoil_rocket";
    a[81]="punch_rounds";
    a[82]="sky_rounds";
    a[83]="frost_rounds";
    a[84]="ammo_thief";
    a[85]="rattle_rounds";
    a[86]="coward";
    a[87]="berserker";
    a[88]="fireworks";
    a[89]="confetti";
    a[90]="hulk";
    a[91]="cinema";
    a[92]="green";
    a[93]="red_alert";
    a[94]="disco_aim";
    a[95]="gravity_well";
    a[96]="repulsor";
    a[97]="healer";
    a[98]="plague";
    a[99]="jackpot";
    return a;
}

rollNames()
{
    a=[];
    a[0]="Orgasm";
    a[1]="Dropped My Glasses";
    a[2]="On Fire";
    a[3]="Infinite UAV";
    a[4]="Snackbar";
    a[5]="Default Weapon";
    a[6]="Random Killstreak";
    a[7]="Bullets Do No Damage";
    a[8]="Ricochet Rounds";
    a[9]="Cement Shoes";
    a[10]="Super Speed";
    a[11]="Tungsten Ballsack";
    a[12]="Kill Sound Roulette";
    a[13]="Strength Bonus";
    a[14]="The Floor Is Lava";
    a[15]="Headshots Only";
    a[16]="10 Second Aimbot";
    a[17]="Explosive Rounds";
    a[18]="L96A1 + Tomahawk";
    a[19]="Wallhacks";
    a[20]="No Collision";
    a[21]="Camera Shake";
    a[22]="Knife Only";
    a[23]="Unlimited Nades";
    a[24]="Thick Skin";
    a[25]="Vampire";
    a[26]="Glass Cannon";
    a[27]="Tunnel Vision";
    a[28]="Rainbow Flash Rounds";
    a[29]="Gravity Kick on Kill";
    a[30]="Disco Tint";
    a[31]="Crawl Pace";
    a[32]="Drunk Sway";
    a[33]="Everyone Hears You";
    a[34]="Random Teleport";
    a[35]="Turnaround";
    a[36]="Cartoon Bounce";
    a[37]="Dance Spin";
    a[38]="Raybow";
    a[39]="Bishop";
    a[40]="Juggernaut";
    a[41]="Speed Demon";
    a[42]="Snail Mail";
    a[43]="Regenerator";
    a[44]="Poison Ivy";
    a[45]="Bloodsucker";
    a[46]="Thorns";
    a[47]="Damage Dice";
    a[48]="Critical Mass";
    a[49]="First One Is Free";
    a[50]="Second Wind";
    a[51]="Mercy Rule";
    a[52]="Executioner";
    a[53]="Medical Malpractice";
    a[54]="Blood Donor";
    a[55]="Heavy Caliber";
    a[56]="Featherweight";
    a[57]="Moon Boots";
    a[58]="Anchor Management";
    a[59]="Blink And You Miss It";
    a[60]="Hit And Run";
    a[61]="Return To Sender";
    a[62]="Supply Fairy";
    a[63]="Weapon Roulette";
    a[64]="Pistol Party";
    a[65]="Rocket Man";
    a[66]="Silent Runner";
    a[67]="Boomstick";
    a[68]="Death Machine";
    a[69]="Grim Reaper";
    a[70]="Crossbow Club";
    a[71]="Ballistic Ballet";
    a[72]="Kalashnikov King";
    a[73]="Rambo";
    a[74]="Scavenger King";
    a[75]="Dry County";
    a[76]="Bottomless Pockets";
    a[77]="One Bullet Wonder";
    a[78]="Blood Ammunition";
    a[79]="Rocket Boots";
    a[80]="Recoil Rocket";
    a[81]="Punch Rounds";
    a[82]="Sky Rounds";
    a[83]="Frost Rounds";
    a[84]="Ammo Thief";
    a[85]="Rattle Rounds";
    a[86]="Fight Or Flight";
    a[87]="Berserker";
    a[88]="Victory Fireworks";
    a[89]="Confetti Cannon";
    a[90]="Hulk Smash";
    a[91]="Cinema Club";
    a[92]="Green Machine";
    a[93]="Red Alert";
    a[94]="Disco Aim";
    a[95]="Gravity Well";
    a[96]="Repulsor";
    a[97]="Healing Aura";
    a[98]="Plague Bearer";
    a[99]="Jackpot";
    return a;
}

rollHints()
{
    a=[];
    a[0]="MP fire screams; repeats until death";
    a[1]="Blurry vision until death.";
    a[2]="5 burn damage per second";
    a[3]="Continuous enemy radar.";
    a[4]="Explode in 30 seconds";
    a[5]="Equip the default weapon.";
    a[6]="Receive a random killstreak.";
    a[7]="Your bullet damage is zero";
    a[8]="Your bullet damage hits you instead";
    a[9]="50% movement speed.";
    a[10]="150% movement speed.";
    a[11]="Double fall damage";
    a[12]="Random local sound on every enemy kill";
    a[13]="+50% direct weapon damage";
    a[14]="Starts in 5s; 10 damage per second on ground";
    a[15]="Your bullets only hurt on headshots";
    a[16]="Hold ADS: aims at a visible enemy; fire manually";
    a[17]="Every fifth gunshot explodes";
    a[18]="L96A1 and tomahawk only.";
    a[19]="Enemy location markers through walls";
    a[20]="Hold USE to fly through walls; melee returns you to start";
    a[21]="Constant camera shake.";
    a[22]="20 seconds of melee-only damage and empty guns";
    a[23]="Refills equipped frag/semtex, claymore or C4";
    a[24]="Half incoming damage";
    a[25]="Enemy kills heal 30 HP";
    a[26]="1 HP, double direct weapon damage";
    a[27]="A heavily darkened view.";
    a[28]="Full-screen rainbow flashes with each gunshot.";
    a[29]="Enemy kills launch YOU upward";
    a[30]="A cycling rainbow tint covers your view.";
    a[31]="25% movement speed.";
    a[32]="Your camera sways.";
    a[33]="Loud positional beeps give you away.";
    a[34]="YOU move to a free map spawn after 3 seconds";
    a[35]="Your view turns 180 degrees every 6 seconds";
    a[36]="You bounce automatically.";
    a[37]="Your camera spins for 3 seconds.";
    a[38]="Equip an explosive crossbow.";
    a[39]="A Death Machine bodyguard follows you.";
    a[40]="300 HP, 70% speed.";
    a[41]="Double movement speed.";
    a[42]="15% movement speed.";
    a[43]="Heal 8 HP every second.";
    a[44]="Lose 3 HP every second.";
    a[45]="Weapon hits heal you for 20% of damage.";
    a[46]="Return 25% of incoming enemy weapon damage.";
    a[47]="Every weapon hit does 25%-200% damage.";
    a[48]="One in five weapon hits does triple damage.";
    a[49]="Your first damaging hit is absorbed.";
    a[50]="Survive one fatal hit at 1 HP.";
    a[51]="Your weapon hits cannot finish an enemy.";
    a[52]="Weapon hits finish enemies below 30 HP.";
    a[53]="Your bullets heal enemies instead of hurting them.";
    a[54]="Enemies that hit you regain 15 HP.";
    a[55]="Double bullet damage, 70% speed.";
    a[56]="170% speed, take 50% more damage.";
    a[57]="Your jumps receive an extra upward boost.";
    a[58]="You stop moving for 2 seconds out of every 8.";
    a[59]="Teleport to a free map spawn every 15 seconds.";
    a[60]="An enemy kill triggers a teleport.";
    a[61]="Return to your roll starting position every 15 seconds.";
    a[62]="Enemy kills award a random killstreak.";
    a[63]="Receive a different primary weapon every 15 seconds.";
    a[64]="Python revolver only.";
    a[65]="RPG only, with periodic ammo refills.";
    a[66]="125% speed and suppressed MP5K.";
    a[67]="Olympia only, with double direct damage.";
    a[68]="Equip the minigun with endless ammunition.";
    a[69]="Equip the M202 with ammo refills.";
    a[70]="Explosive crossbow only.";
    a[71]="Ballistic knife, 150% speed.";
    a[72]="AK-47 with 25% bonus damage.";
    a[73]="M60, 200 HP, 85% speed.";
    a[74]="Enemy kills refill your weapons.";
    a[75]="No reserve ammunition.";
    a[76]="All carried weapons refill every half-second.";
    a[77]="Exactly one bullet in your current gun after each shot.";
    a[78]="Each shot costs 2 HP.";
    a[79]="USE launches you upward; 3-second cooldown.";
    a[80]="Shots push you backward.";
    a[81]="Bullet hits launch enemies away.";
    a[82]="Bullet hits toss enemies into the air.";
    a[83]="Bullet hits slow an enemy for 0.75 seconds.";
    a[84]="Bullet hits remove five rounds from the victim's clip.";
    a[85]="Bullet hits shake the victim's camera.";
    a[86]="Double speed whenever an enemy is within 450 units.";
    a[87]="Triple direct damage below 30 HP.";
    a[88]="Enemy kills create a harmless explosion effect.";
    a[89]="Enemy kills splash your screen with color.";
    a[90]="Crouch + USE launches you; take no fall damage.";
    a[91]="Letterboxed vision for your whole life.";
    a[92]="Green-tinted vision and 125% speed.";
    a[93]="Your screen pulses red, faster at low health.";
    a[94]="Every shot rotates your view 25 degrees.";
    a[95]="Pull nearby enemies toward you.";
    a[96]="Push nearby enemies away.";
    a[97]="Heal yourself and nearby teammates.";
    a[98]="Nearby visible enemies take 3 damage per second.";
    a[99]="200 HP, 150% speed, infinite ammo, life-steal.";
    return a;
}
