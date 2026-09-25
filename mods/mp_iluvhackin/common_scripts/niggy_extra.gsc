#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

apply(roll)
{
    self.ng_start = self.origin;
    self.ng_nextUse = 0;
    switch(roll)
    {
        case "bishop": self thread bishop(); break;
        case "juggernaut": self.maxhealth=300; self.health=300; self.ng_speedFactor=0.7; break;
        case "speed_demon": self.ng_speedFactor=2; break;
        case "snail": self.ng_speedFactor=0.15; break;
        case "regenerator": self.ng_regen=8; break;
        case "poison": self.ng_poison=3; break;
        case "bloodsucker": self.ng_lifesteal=0.2; break;
        case "thorns": self.ng_thorns=0.25; break;
        case "damage_dice": self.ng_damageDice=true; break;
        case "critical": self.ng_critical=true; break;
        case "first_shield": self.ng_shield=1; break;
        case "second_wind": self.ng_secondWind=true; break;
        case "mercy": self.ng_mercy=true; break;
        case "executioner": self.ng_execute=true; break;
        case "medic_bullets": self.ng_healBullets=true; break;
        case "blood_donor": self.ng_donor=true; break;
        case "heavy_caliber": self.ng_bulletScale=2; self.ng_speedFactor=0.7; break;
        case "featherweight": self.ng_speedFactor=1.7; self.ng_incoming=1.5; break;
        case "moonboots": self.ng_moonboots=true; break;
        case "anchor": self.ng_anchor=true; break;
        case "blink": self.ng_blink=true; break;
        case "kill_teleport": self.ng_killTeleport=true; break;
        case "rewind": self.ng_rewind=true; break;
        case "supply_fairy": self.ng_supply=true; break;
        case "roulette_gun": self.ng_roulette=true; break;
        case "pistol_party": self loadout("python_mp"); break;
        case "rocketman": self loadout("rpg_mp"); self.ng_ammo=true; break;
        case "silent_runner": self loadout("mp5k_silencer_mp"); self.ng_speedFactor=1.25; break;
        case "boomstick": self loadout("rottweil72_mp"); self.ng_outgoing=2; break;
        case "deathmachine": self loadout("minigun_mp"); self.ng_ammo=true; break;
        case "grim_reaper": self loadout("m202_flash_mp"); self.ng_ammo=true; break;
        case "crossbow_club": self loadout("crossbow_explosive_mp"); break;
        case "ballistic": self loadout("knife_ballistic_mp"); self.ng_speedFactor=1.5; break;
        case "kalashnikov": self loadout("ak47_mp"); self.ng_outgoing=1.25; break;
        case "rambo": self loadout("m60_mp"); self.maxhealth=200; self.health=200; self.ng_speedFactor=0.85; break;
        case "scavenger": self.ng_scavenger=true; break;
        case "dry_mag": self.ng_dry=true; break;
        case "bottomless": self.ng_ammo=true; break;
        case "one_bullet": self.ng_oneBullet=true; break;
        case "blood_ammo": self.ng_bloodAmmo=true; break;
        case "rocket_boots": self.ng_rocketBoots=true; break;
        case "recoil_rocket": self.ng_recoil=true; break;
        case "punch_rounds": self.ng_punch=true; break;
        case "sky_rounds": self.ng_sky=true; break;
        case "frost_rounds": self.ng_frost=true; break;
        case "ammo_thief": self.ng_ammoThief=true; break;
        case "rattle_rounds": self.ng_rattle=true; break;
        case "coward": self.ng_coward=true; break;
        case "berserker": self.ng_berserker=true; break;
        case "fireworks": self.ng_fireworks=true; break;
        case "confetti": self.ng_confetti=true; self common_scripts\nitys_rtd::overlay((1,0,1),0); break;
        case "hulk": self.ng_hulk=true; break;
        case "cinema": self letterbox(); break;
        case "green": self common_scripts\nitys_rtd::overlay((0,1,0),0.3); self.ng_speedFactor=1.25; break;
        case "red_alert": self common_scripts\nitys_rtd::overlay((1,0,0),0.15); self.ng_red=true; break;
        case "disco_aim": self.ng_discoAim=true; break;
        case "gravity_well": self.ng_gravity=true; break;
        case "repulsor": self.ng_repulsor=true; break;
        case "healer": self.ng_healer=true; break;
        case "plague": self.ng_plague=true; break;
        case "jackpot": self.maxhealth=200; self.health=200; self.ng_speedFactor=1.5; self.ng_ammo=true; self.ng_lifesteal=0.25; break;

    }
    if(self.maxhealth!=self.rtd_health) self.ng_healthChanged=true;
    if(isDefined(self.ng_speedFactor)) self setMoveSpeedScale(self.rtd_speed*self.ng_speedFactor);
    self thread lifeLoop();
}

cleanup()
{
    self notify("ng_slow_stop");
    if(isDefined(self.ng_slowed) && isDefined(self.ng_slowBase)) self setMoveSpeedScale(self.ng_slowBase);
    self.ng_slowed = undefined;
    self.ng_slowBase = undefined;
    if(isDefined(self.ng_healthChanged) && isDefined(self.rtd_health)) self.maxhealth=self.rtd_health;
    if(isDefined(self.rtd_speed) && (isDefined(self.ng_speedFactor) || isDefined(self.ng_anchor) || isDefined(self.ng_coward))) self setMoveSpeedScale(self.rtd_speed);
    if(isDefined(self.ng_bars)) for(i=0;i<self.ng_bars.size;i++) if(isDefined(self.ng_bars[i])) self.ng_bars[i] destroy();
    self.ng_bars=undefined;
    if(isDefined(self.ng_bishop))
    {
        bot=self.ng_bishop;
        if(isDefined(bot.ng_bishop_owner) && bot.ng_bishop_owner==self) kick(bot getEntityNumber());
    }
    self.ng_bishop=undefined;
    if(isDefined(self.ng_bishopHud)) self.ng_bishopHud destroy();
    self.ng_bishopHud=undefined;
    self.ng_ammo=undefined;
    self.ng_ammoThief=undefined;
    self.ng_anchor=undefined;
    self.ng_berserker=undefined;
    self.ng_blink=undefined;
    self.ng_bloodAmmo=undefined;
    self.ng_bulletScale=undefined;
    self.ng_confetti=undefined;
    self.ng_coward=undefined;
    self.ng_critical=undefined;
    self.ng_damageDice=undefined;
    self.ng_discoAim=undefined;
    self.ng_donor=undefined;
    self.ng_dry=undefined;
    self.ng_execute=undefined;
    self.ng_fireworks=undefined;
    self.ng_frost=undefined;
    self.ng_gravity=undefined;
    self.ng_healBullets=undefined;
    self.ng_healer=undefined;
    self.ng_hulk=undefined;
    self.ng_incoming=undefined;
    self.ng_killTeleport=undefined;
    self.ng_lifesteal=undefined;
    self.ng_mercy=undefined;
    self.ng_moonboots=undefined;
    self.ng_oneBullet=undefined;
    self.ng_outgoing=undefined;
    self.ng_plague=undefined;
    self.ng_poison=undefined;
    self.ng_punch=undefined;
    self.ng_rattle=undefined;
    self.ng_recoil=undefined;
    self.ng_red=undefined;
    self.ng_regen=undefined;
    self.ng_repulsor=undefined;
    self.ng_rewind=undefined;
    self.ng_rocketBoots=undefined;
    self.ng_roulette=undefined;
    self.ng_scavenger=undefined;
    self.ng_secondWind=undefined;
    self.ng_shield=undefined;
    self.ng_sky=undefined;
    self.ng_speedFactor=undefined;
    self.ng_supply=undefined;
    self.ng_thorns=undefined;
    self.ng_healthChanged=undefined;
}

loadout(weapon)
{
    self takeAllWeapons();
    self common_scripts\nitys_rtd::grant(weapon);
}

refill()
{
    weapons=self getWeaponsList();
    for(i=0;i<weapons.size;i++) if(weapons[i]!="knife_mp" && weapons[i]!="none") self giveMaxAmmo(weapons[i]);
}

lifeLoop()
{
    self endon("death"); self endon("disconnect"); self endon("rtd_stop");
    tick=0; wasGrounded=true;
    for(;;)
    {
        if(isDefined(self.ng_ammo) && tick%2==0) self refill();
        if(isDefined(self.ng_dry))
        {
            weapons=self getWeaponsList();
            for(i=0;i<weapons.size;i++) if(weapons[i]!="knife_mp" && weapons[i]!="none") self setWeaponAmmoStock(weapons[i],0);
        }
        if(isDefined(self.ng_anchor))
        {
            if(tick%32>=24) self setMoveSpeedScale(0); else self setMoveSpeedScale(self.rtd_speed);
        }
        if(isDefined(self.ng_coward))
        {
            near=false;
            for(i=0;i<level.players.size;i++) if(self common_scripts\nitys_rtd::enemy(level.players[i]) && distance(self.origin,level.players[i].origin)<450) near=true;
            if(near) self setMoveSpeedScale(self.rtd_speed*2); else self setMoveSpeedScale(self.rtd_speed);
        }
        grounded=self isOnGround();
        if(isDefined(self.ng_moonboots) && wasGrounded && !grounded)
        {
            v=self getVelocity();
            if(v[2]>50) self setVelocity(v+(0,0,150));
        }
        wasGrounded=grounded;
        if((isDefined(self.ng_rocketBoots)||isDefined(self.ng_hulk)) && !self.menuOpen && self useButtonPressed() && getTime()>self.ng_nextUse)
        {
            if(!isDefined(self.ng_hulk)||self getStance()=="crouch")
            {
                if(isDefined(self.ng_hulk)) boost=600; else boost=350;
                self setVelocity(self getVelocity()+(0,0,boost)); self.ng_nextUse=getTime()+3000;
            }
        }
        if(tick%4==0)
        {
            if(isDefined(self.ng_regen)) self heal(self.ng_regen);
            if(isDefined(self.ng_poison)) self common_scripts\nitys_rtd::hurt(self.ng_poison);
            if(isDefined(self.ng_healer)) self heal(5);
            self aura();
        }
        if(tick>0 && tick%60==0)
        {
            if(isDefined(self.ng_blink)) self thread common_scripts\nitys_rtd::teleport();
            if(isDefined(self.ng_rewind)) self setOrigin(self.ng_start);
            if(isDefined(self.ng_roulette))
            {
                guns=strTok("ak47_mp|python_mp|m60_mp|l96a1_mp|rottweil72_mp|crossbow_explosive_mp","|");
                self loadout(guns[randomInt(guns.size)]);
            }
        }
        if(isDefined(self.ng_red) && isDefined(self.rtd_overlay)) self.rtd_overlay.alpha=0.12+abs(sin(tick*30))*0.25;
        tick++; wait 0.25;
    }
}

heal(amount)
{
    if(!isAlive(self)) return;
    self.health+=int(amount);
    if(self.health>self.maxhealth) self.health=self.maxhealth;
}

modifyDamage(attacker,amount,mod,weapon,point,direction,hitloc,offset)
{
    if(isDefined(attacker) && isPlayer(attacker) && isDefined(attacker.ng_bishop_owner) && attacker.ng_bishop_owner==self) return 0;
    if(mod=="MOD_FALLING" && isDefined(self.ng_hulk)) return 0;
    bullet=mod=="MOD_RIFLE_BULLET"||mod=="MOD_PISTOL_BULLET"||mod=="MOD_HEAD_SHOT";
    direct=bullet||mod=="MOD_MELEE"||mod=="MOD_PROJECTILE"||mod=="MOD_PROJECTILE_SPLASH"||mod=="MOD_GRENADE"||mod=="MOD_GRENADE_SPLASH";
    enemyHit=isDefined(attacker)&&isPlayer(attacker)&&attacker!=self;
    if(enemyHit && isDefined(level.teambased) && level.teambased && attacker.pers["team"]==self.pers["team"]) enemyHit=false;
    if(enemyHit && direct)
    {
        if(isDefined(attacker.ng_healBullets) && bullet) { self heal(amount); return 0; }
        if(isDefined(attacker.ng_outgoing)) amount=int(amount*attacker.ng_outgoing);
        if(isDefined(attacker.ng_bulletScale)&&bullet) amount=int(amount*attacker.ng_bulletScale);
        if(isDefined(attacker.ng_damageDice)) amount=int(amount*randomFloatRange(0.25,2));
        if(isDefined(attacker.ng_critical)&&randomInt(5)==0) amount*=3;
        if(isDefined(attacker.ng_berserker)&&attacker.health<30) amount*=3;
        if(isDefined(attacker.ng_execute)&&self.health<30) amount=self.health+100;
        if(isDefined(attacker.ng_mercy)&&amount>=self.health) amount=self.health-1;
        if(isDefined(attacker.ng_lifesteal)) attacker heal(int(amount*attacker.ng_lifesteal));
        if(isDefined(self.ng_donor)) attacker heal(15);
        if(bullet)
        {
            if(isDefined(attacker.ng_punch)) self setVelocity(vectorNormalize(self.origin-attacker.origin)*450+(0,0,150));
            if(isDefined(attacker.ng_sky)) self setVelocity(self getVelocity()+(0,0,350));
            if(isDefined(attacker.ng_frost)) self thread briefSlow();
            if(isDefined(attacker.ng_rattle)) earthquake(0.3,0.5,self.origin,64,self);
            if(isDefined(attacker.ng_ammoThief))
            {
                gun=self getCurrentWeapon();
                if(gun!="none") { ammo=self getWeaponAmmoClip(gun)-5; if(ammo<0) ammo=0; self setWeaponAmmoClip(gun,ammo); }
            }
        }
        if(isDefined(self.ng_thorns) && amount>0)
            attacker [[level.callbackPlayerDamage]](self,self,int(amount*self.ng_thorns),0,"MOD_IMPACT","none",attacker.origin,(0,0,0),"none",0);
    }
    if(isDefined(self.ng_incoming)) amount=int(amount*self.ng_incoming);
    if(isDefined(self.ng_shield)&&self.ng_shield>0&&amount>0) { self.ng_shield--; return 0; }
    if(isDefined(self.ng_secondWind)&&amount>=self.health) { self.ng_secondWind=undefined; return self.health-1; }
    return amount;
}

briefSlow()
{
    self endon("disconnect"); self endon("death"); self endon("rtd_stop");
    if(!isDefined(self.ng_slowed)) self.ng_slowBase=self getMoveSpeedScale();
    self.ng_slowed=true;
    self notify("ng_slow_stop"); self endon("ng_slow_stop");
    self setMoveSpeedScale(self.ng_slowBase*0.3);
    wait 0.75;
    self setMoveSpeedScale(self.ng_slowBase); self.ng_slowed=undefined;
}

shot()
{
    if(isDefined(self.ng_oneBullet)) { gun=self getCurrentWeapon(); if(gun!="none") self setWeaponAmmoClip(gun,1); }
    if(isDefined(self.ng_bloodAmmo)) self common_scripts\nitys_rtd::hurt(2);
    if(isDefined(self.ng_recoil)) self setVelocity(self getVelocity()-anglesToForward(self getPlayerAngles())*250);
    if(isDefined(self.ng_discoAim)) { a=self getPlayerAngles(); self setPlayerAngles((a[0],a[1]+25,0)); }
}

killed(victimOrigin)
{
    if(isDefined(self.ng_scavenger)) self refill();
    if(isDefined(self.ng_supply)) self common_scripts\nitys_rtd::randomStreak();
    if(isDefined(self.ng_killTeleport)) self thread common_scripts\nitys_rtd::teleport();
    if(isDefined(self.ng_fireworks)&&isDefined(victimOrigin)) playFx(level._effect["jm_expbullet"],victimOrigin);
    if(isDefined(self.ng_confetti)&&isDefined(self.rtd_overlay))
    {
        self.rtd_overlay.color=(randomFloat(1),randomFloat(1),randomFloat(1));
        self.rtd_overlay.alpha=0.5; self.rtd_overlay fadeOverTime(1); self.rtd_overlay.alpha=0;
    }
}

aura()
{
    if(!isDefined(self.ng_gravity)&&!isDefined(self.ng_repulsor)&&!isDefined(self.ng_healer)&&!isDefined(self.ng_plague)) return;
    for(i=0;i<level.players.size;i++)
    {
        p=level.players[i]; if(p==self||!isAlive(p)) continue;
        dist=distance(self.origin,p.origin); if(dist>300||dist<1) continue;
        hostile=self common_scripts\nitys_rtd::enemy(p);
        if(hostile)
        {
            trace=bulletTrace(self getTagOrigin("j_head"),p getTagOrigin("j_head"),true,self);
            visible=trace["fraction"]>=0.99||(isDefined(trace["entity"])&&trace["entity"]==p);
            if(!visible) continue;
            if(isDefined(self.ng_gravity)) p setVelocity(vectorNormalize(self.origin-p.origin)*180+(0,0,70));
            if(isDefined(self.ng_repulsor)&&dist<160) p setVelocity(vectorNormalize(p.origin-self.origin)*350+(0,0,120));
            if(isDefined(self.ng_plague)) p [[level.callbackPlayerDamage]](self,self,3,0,"MOD_BURNED","none",p.origin,(0,0,0),"none",0);
        }
        else if(isDefined(self.ng_healer)) p heal(5);
    }
}

letterbox()
{
    self.ng_bars=[];
    for(i=0;i<2;i++)
    {
        h=newClientHudElem(self); h.horzAlign="fullscreen"; h.vertAlign="fullscreen";
        h.alignX="center"; h.alignY="middle"; h.x=320;
        if(i==0) h.y=0; else h.y=480;
        h setShader("black",2000,150); h.color=(0,0,0); h.alpha=1; h.sort=-9;
        self.ng_bars[i]=h;
    }
}

bishop()
{
    self endon("death"); self endon("disconnect"); self endon("rtd_stop");
    bot=addTestClient();
    if(!isDefined(bot)) { self iPrintln("Bishop needs one free player slot."); return; }
    self.ng_bishop=bot; bot.ng_bishop_owner=self; bot.pers["isBot"]=true;
    self thread bishopDisconnect(bot);
    bot thread maps\mp\gametypes\_bot::bot_spawn_think(self.pers["team"]);
    deadline=getTime()+10000;
    while(isDefined(bot)&&!isAlive(bot)&&getTime()<deadline) wait 0.1;
    if(!isDefined(bot)) return;
    if(!isAlive(bot)) { kick(bot getEntityNumber()); self.ng_bishop=undefined; self iPrintln("Bishop could not spawn in this match."); return; }
    wait 0.5;
    bot setOrigin(self.origin+anglesToRight(self getPlayerAngles())*60);
    if(isDefined(bot.bot)) bot.bot["primary"]="minigun_mp";
    bot takeAllWeapons(); bot giveWeapon("minigun_mp"); bot giveMaxAmmo("minigun_mp"); bot switchToWeapon("minigun_mp");
    bot.maxhealth=300; bot.health=300;
    bot thread bishopDies();
    self.ng_bishopHud=newClientHudElem(self); self.ng_bishopHud setText("^2Bishop");
    self.ng_bishopHud setWaypoint(true); self.ng_bishopHud setTargetEnt(bot);
    count=0;
    while(isDefined(bot)&&isAlive(bot))
    {
        bot giveMaxAmmo("minigun_mp");
        if(distance(bot.origin,self.origin)>120) { bot clearScriptGoal(); bot setScriptGoal(self.origin,80); }
        if(count%12==0)
        {
            voice=getDvar("ng_bishop_voice");
            if(voice!="") bot playSound(voice);
            self iPrintln("^2Bishop: ^7You can't kill me!");
        }
        count++; wait 0.5;
    }
}

bishopDies()
{
    self endon("disconnect"); self waittill("death");
    if(isDefined(self.ng_bishop_owner)) kick(self getEntityNumber());
}

bishopDisconnect(bot)
{
    self endon("rtd_stop"); self waittill("disconnect");
    if(isDefined(bot)&&isDefined(bot.ng_bishop_owner)) kick(bot getEntityNumber());
}
