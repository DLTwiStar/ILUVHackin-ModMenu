#include common_scripts\utility;
#include maps\mp\_utility;

init()
{
    // VIP powers use no extra visual assets.
}

setup()
{
    self.ng_vipMoon=false; self.ng_vipAim=false; self.ng_vipSpeed=false;
    self.ng_vipRadar=false; self.ng_vipNoFall=false; self.ng_vipVampire=false;
    self thread onEnd("death"); self thread onEnd("spawned");
    self thread onEnd("joined_team"); self thread onEnd("joined_spectators");
    self thread onEnd("disconnect"); self thread gameEnd();
    self thread think();
}

available()
{
    if(!isAlive(self) || self common_scripts\ng_access::rank()<2) return false;
    if(getDvarInt("jm_rtd")!=0 || common_scripts\ng_admin::isWagerMode()) return false;
    return true;
}

route(input)
{
    if(!common_scripts\ng_access::contains("Moon Gravity|Aimbot|Super Speed|No Fall Damage|Vampire|Infinite Advanced UAV",input)) return false;
    if(!self available()) { self iPrintln("VIP powers are available while alive in the base menu mode."); return true; }
    switch(input)
    {
        case "Moon Gravity": self.ng_vipMoon=!self.ng_vipMoon; break;
        case "Aimbot": self.ng_vipAim=!self.ng_vipAim; self iPrintln("Aimbot: AIM or FIRE locks visible heads. Bullet hits become lethal headshots."); break;
        case "Super Speed":
            if(self.ng_vipSpeed) { self setMoveSpeedScale(self.ng_vipOldSpeed); self.ng_vipSpeed=false; }
            else { self.ng_vipOldSpeed=self getMoveSpeedScale(); self setMoveSpeedScale(self.ng_vipOldSpeed*4); self.ng_vipSpeed=true; }
            break;
        case "No Fall Damage": self.ng_vipNoFall=!self.ng_vipNoFall; break;
        case "Vampire": self.ng_vipVampire=!self.ng_vipVampire; break;
        case "Infinite Advanced UAV":
            if(self.ng_vipRadar) self releaseRadar();
            else self acquireRadar();
            break;
    }
    return true;
}

think()
{
    self endon("disconnect");
    last=getTime(); nextAim=0;
    gravity=getDvarInt("bg_gravity"); if(gravity<=0) gravity=800;
    for(;;)
    {
        wait 0.05;
        now=getTime(); elapsed=(now-last)/1000.0; last=now;
        if(elapsed>0.1) elapsed=0.1;
        if(!self available()) { self reset(false); wait 0.2; continue; }
        busy=isDefined(self.newufo) || isDefined(self.rtd_anchor) || isDefined(self.ng_holder) || self IsRemoteControlling();
        if(isDefined(self.ng_formActive) && self.ng_formActive) busy=true;
        if(self.ng_vipMoon && !busy && !self isOnGround())
        {
            velocity=self getVelocity();
            self setVelocity(velocity+(0,0,gravity*0.75*elapsed));
        }
        if(self.ng_vipAim && !busy && !self.menuOpen && (self adsButtonPressed() || self attackButtonPressed()) && now>=nextAim)
        { nextAim=now+50; self aim(); }
    }
}

aim()
{
    eye=self getEye(); forward=anglesToForward(self getPlayerAngles());
    target=undefined; best=-2;
    for(i=0;i<level.players.size;i++)
    {
        p=level.players[i]; if(!self common_scripts\nitys_rtd::enemy(p)) continue;
        head=p getTagOrigin("j_head"); delta=head-eye; range=length(delta);
        if(range<1 || range>6000) continue;
        score=vectorDot(forward,delta*(1/range)); if(score<=best) continue;
        trace=bulletTrace(eye,head,true,self);
        if(trace["fraction"]<0.99 && (!isDefined(trace["entity"]) || trace["entity"]!=p)) continue;
        best=score; target=p;
    }
    if(isDefined(target)) self setPlayerAngles(vectorToAngles(target getTagOrigin("j_head")-eye));
}

headshotEnabled(attacker,means)
{
    if(!isDefined(attacker) || !isPlayer(attacker)) return false;
    if(!isDefined(attacker.ng_vipAim) || !attacker.ng_vipAim) return false;
    if(!attacker available() || !attacker common_scripts\nitys_rtd::enemy(self)) return false;
    if(isDefined(attacker.forgeOn) && attacker.forgeOn) return false;
    return means=="MOD_RIFLE_BULLET" || means=="MOD_PISTOL_BULLET" || means=="MOD_HEAD_SHOT";
}

noFallEnabled()
{
    return isDefined(self.ng_vipNoFall) && self.ng_vipNoFall && self available();
}

onKill(attacker)
{
    if(!isDefined(attacker) || !isPlayer(attacker) || attacker==self) return;
    if(!isDefined(attacker.ng_vipVampire) || !attacker.ng_vipVampire || !attacker available()) return;
    if(level.teambased && attacker.pers["team"]==self.pers["team"]) return;
    if(!isDefined(attacker.maxhealth)) return;
    health=attacker.health+25; if(health>attacker.maxhealth) health=attacker.maxhealth;
    attacker.health=health;
}

acquireRadar()
{
    if(self.ng_vipRadar) return;
    key=self getEntityNumber();
    if(level.teambased) key=self.team;
    if(!isDefined(level.activeSatellites) || !isDefined(level.activeSatellites[key]))
    { self iPrintln("Radar is not ready yet. Try again after spawning."); return; }
    self.ng_vipRadarKey=key; self.ng_vipRadarTeam=level.teambased;
    // Own exactly one stock satellite reference; real Blackbirds retain their own counts.
    level.activeSatellites[key]++;
    self.ng_vipRadar=true;
    refreshRadar(key,self.ng_vipRadarTeam);
    if(level.teambased) self iPrintln("Infinite Blackbird ON for your team.");
    else self iPrintln("Infinite Blackbird ON.");
}

releaseRadar()
{
    if(!isDefined(self.ng_vipRadar) || !self.ng_vipRadar) return;
    self.ng_vipRadar=false;
    key=self.ng_vipRadarKey;
    if(isDefined(level.activeSatellites) && isDefined(level.activeSatellites[key]))
    {
        if(level.activeSatellites[key]>0) level.activeSatellites[key]--;
        refreshRadar(key,self.ng_vipRadarTeam);
    }
    self.ng_vipRadarKey=undefined;
}

refreshRadar(key,teamBased)
{
    if(teamBased) maps\mp\_spyplane::updateTeamUAVStatus(key);
    else maps\mp\_spyplane::updatePlayersUAVStatus();
}

reset(disconnected)
{
    if(!self.ng_vipMoon && !self.ng_vipAim && !self.ng_vipSpeed && !self.ng_vipRadar && !self.ng_vipNoFall && !self.ng_vipVampire) return;
    self releaseRadar();
    if(!disconnected)
    {
        if(isDefined(self.ng_vipSpeed) && self.ng_vipSpeed && isDefined(self.ng_vipOldSpeed)) self setMoveSpeedScale(self.ng_vipOldSpeed);
    }
    self.ng_vipMoon=false; self.ng_vipAim=false; self.ng_vipSpeed=false; self.ng_vipNoFall=false; self.ng_vipVampire=false;
}

onEnd(event)
{
    if(event!="disconnect") self endon("disconnect");
    for(;;)
    {
        self waittill(event);
        self reset(event=="disconnect");
        if(event=="disconnect") return;
    }
}

gameEnd()
{
    self endon("disconnect");
    level waittill("game_ended");
    self reset(false);
}
