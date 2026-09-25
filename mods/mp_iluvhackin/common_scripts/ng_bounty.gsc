#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// Original game mode: the marked carrier earns time points; kills steal the bounty.
init()
{
    restoreDvars();
    if(getDvarInt("jm_rtd")!=4) return;
    level.br_round=1; level.br_pause=false;
    names=strTok("scr_dm_timelimit|scr_dm_scorelimit","|");
    for(i=0;i<names.size;i++) { setDvar("ng_br_saved_"+i,getDvar(names[i])); setDvar(names[i],0); }
    setDvar("ng_br_restore",1);
    level thread connect(); level thread timer(); level thread cleanup();
}

restoreDvars()
{
    if(getDvarInt("ng_br_restore")!=1) return;
    names=strTok("scr_dm_timelimit|scr_dm_scorelimit","|");
    for(i=0;i<names.size;i++) { setDvar(names[i],getDvar("ng_br_saved_"+i)); setDvar("ng_br_saved_"+i,""); }
    setDvar("ng_br_restore",0);
}

connect()
{
    for(;;) { level waittill("connected",p); p.br_points=0; p thread display(); }
}

pickCarrier()
{
    pool=[];
    for(i=0;i<level.players.size;i++) if(isAlive(level.players[i]) && level.players[i].sessionstate=="playing") pool[pool.size]=level.players[i];
    if(pool.size>0) setCarrier(pool[randomInt(pool.size)]);
}

setCarrier(p)
{
    if(isDefined(level.br_icon)) level.br_icon destroy();
    level.br_carrier=p;
    if(!isDefined(p)) return;
    if(!isDefined(p.br_points)) p.br_points=0;
    level.br_icon=newHudElem(); level.br_icon setShader("waypoint_targetneutral",18,18);
    level.br_icon.color=(1,0.8,0); level.br_icon.alpha=1;
    level.br_icon setWaypoint(true); level.br_icon setTargetEnt(p);
    iPrintlnBold(p.name+" has the bounty! Kill the carrier to steal it.");
}

onKill(attacker)
{
    if(level.br_pause || !isDefined(level.br_carrier) || self!=level.br_carrier) return;
    if(isDefined(attacker) && isPlayer(attacker) && attacker!=self && isAlive(attacker)) setCarrier(attacker);
    else setCarrier(undefined);
}

timer()
{
    level endon("game_ended");
    wait 5;
    for(;;)
    {
        wait 1;
        if(!isDefined(level.br_carrier) || !isAlive(level.br_carrier)) { pickCarrier(); continue; }
        // A second opponent is required to earn points.
        opponents=0;
        for(i=0;i<level.players.size;i++) if(level.players[i]!=level.br_carrier && level.players[i].sessionstate!="spectator") opponents++;
        if(opponents==0) continue;
        p=level.br_carrier; p.br_points++;
        if(p.br_points>=60)
        {
            iPrintlnBold(p.name+" wins Bounty Relay round "+level.br_round+"!");
            level.br_pause=true; setCarrier(undefined);
            wait 5;
            level.br_round++;
            for(i=0;i<level.players.size;i++) level.players[i].br_points=0;
            level.br_pause=false;
        }
    }
}

display()
{
    self endon("disconnect");
    hud=self createFontString("objective",1.35);
    hud setPoint("TOPLEFT","TOPLEFT",10,35);
    self thread common_scripts\jellymod::destroyEvent(hud,"disconnect");
    for(;;)
    {
        name="Waiting for players";
        if(isDefined(level.br_carrier)) name=common_scripts\ng_access::safeName(level.br_carrier.name);
        hud setText("^3BOUNTY RELAY ^7R"+level.br_round+" | Carrier: "+name+" | Your points: "+self.br_points+"/60");
        if(self.menuOpen) hud.alpha=0; else hud.alpha=1;
        wait 1;
    }
}

cleanup()
{
    level waittill("game_ended");
    if(isDefined(level.br_icon)) level.br_icon destroy();
    restoreDvars();
}
