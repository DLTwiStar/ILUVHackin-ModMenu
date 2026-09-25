#include common_scripts\utility;
#include maps\mp\_utility;

init()
{
    level.ng_props=[];
    level.ng_solidProps=[];
    level.ng_mapProps=[];
    level thread cacheMapProps();
    level.ng_barriers=[];
    level.ng_barriersOff=false;
    precacheModel("mp_supplydrop_ally");
    precacheModel("mp_supplydrop_axis");
    precacheModel("mp_supplydrop_boobytrapped");
    precacheItem("python_mp");
    level.ng_streakModels=strTok("t5_veh_rcbomb_allies|t5_veh_rcbomb_axis|t5_weapon_minigun_turret|t5_weapon_sam_turret|t5_veh_helo_hind_killstreak|t5_veh_helo_huey_mp|vehicle_ch46e_mp_light","|");
    level.ng_streakNames=strTok("Allied RC-XD|Axis RC-XD|Sentry Gun|SAM Turret|Attack Helicopter|Huey Chopper|Care Package Helicopter","|");
    for(i=0;i<level.ng_streakModels.size;i++) precacheModel(level.ng_streakModels[i]);
    // Map cars are discovered from existing assets, avoiding missing-model loads on other maps.
    level.ng_carModels=[]; level.ng_carNames=[];
    cars=getEntArray("destructible","targetname");
    for(i=0;i<cars.size;i++)
    {
        p=cars[i];
        if(!isDefined(p.destructibledef) || getSubStr(p.destructibledef,0,4)!="veh_" || !isDefined(p.model) || p.model=="") continue;
        found=false;
        for(n=0;n<level.ng_carModels.size;n++) if(level.ng_carModels[n]==p.model) found=true;
        if(found || level.ng_carModels.size>=12) continue;
        n=level.ng_carModels.size; level.ng_carModels[n]=p.model;
        kind="Car";
        if(isSubStr(p.destructibledef,"truck")) kind="Truck";
        else if(isSubStr(p.destructibledef,"bus")) kind="Bus";
        else if(isSubStr(p.destructibledef,"jeep")) kind="Jeep";
        level.ng_carNames[n]="Map "+kind+" "+(n+1);
        precacheModel(p.model);
    }
}

menu()
{
    self common_scripts\jellymod::changeMenu(25,"^3Forge","Toggle Forge Mode|Forge Props|Forge Object|Phase Through Surfaces|Toggle Script Barriers|Remove My Props|Close Menu");
}

route(input)
{
    if(input=="Forge") { self menu(); return true; }
    if(input=="Forge Props")
    {
        self common_scripts\jellymod::changeMenu(26,"^3Select Prop","Select Allied Crate|Select Axis Crate|Select Marked Crate|Vehicle Props|Killstreak Props|Build 10 Crate Stairs|Forge|Close Menu"); return true;
    }
    if(input=="Vehicle Props" || input=="Killstreak Props")
    {
        text="";
        if(input=="Vehicle Props") names=level.ng_carNames; else names=level.ng_streakNames;
        for(i=0;i<names.size;i++)
        {
            if(input=="Vehicle Props") text+="Car Prop #"+i+" "+names[i]+"|";
            else text+="Streak Prop #"+i+" "+names[i]+"|";
        }
        if(names.size==0) self iPrintln("This map exposes no car models. RC-XD models are in Killstreak Props.");
        self common_scripts\jellymod::changeMenu(28,"^3"+input,text+"Forge Props|Close Menu"); return true;
    }
    if(getSubStr(input,0,10)=="Car Prop #" || getSubStr(input,0,13)=="Streak Prop #")
    {
        if(self common_scripts\ng_access::rank()<3 || !self.forgeOn) { self iPrintln("Enable Forge Mode first."); return true; }
        t=strTok(input," "); n=int(getSubStr(t[2],1,t[2].size));
        if(getSubStr(input,0,10)=="Car Prop #") { models=level.ng_carModels; names=level.ng_carNames; }
        else { models=level.ng_streakModels; names=level.ng_streakNames; }
        if(n<0 || n>=models.size) return true;
        self.ng_propModel=models[n]; self iPrintln(names[n]+" selected. Fire the Forge Python to place it."); return true;
    }
    if(input=="Forge Object")
    {
        self common_scripts\jellymod::changeMenu(27,"^3Selected Object","Select Aimed Object|Duplicate Selected|Remove Selected|Rotate Left 15|Rotate Right 15|Raise 10|Lower 10|Forge|Close Menu"); return true;
    }
    if(input=="Phase Through Surfaces" || input=="Noclip" || input=="UFO Mode")
    {
        if(self common_scripts\ng_access::rank()<3) return true;
        if(input=="Phase Through Surfaces" && !self.forgeOn) { self iPrintln("Enable Forge Mode first."); return true; }
        if(isDefined(self.newufo)) self common_scripts\jellymod::jm_stopNoclip();
        else self thread phase(input=="Phase Through Surfaces");
        return true;
    }
    actions="Toggle Forge Mode|Select Allied Crate|Select Axis Crate|Select Marked Crate|Build 10 Crate Stairs|Select Aimed Object|Duplicate Selected|Remove Selected|Rotate Left 15|Rotate Right 15|Raise 10|Lower 10|Toggle Script Barriers|Remove My Props";
    if(!common_scripts\ng_access::contains(actions,input)) return false;
    if(self common_scripts\ng_access::rank()<3) return true;
    if(input!="Toggle Forge Mode" && !self.forgeOn) { self iPrintln("Enable Forge Mode first."); return true; }
    switch(input)
    {
        case "Toggle Forge Mode":
            if(self.forgeOn) self stop();
            else self start();
            self common_scripts\jellymod::closeModMenu(); break;
        case "Select Allied Crate": self.ng_propModel="mp_supplydrop_ally"; self iPrintln("Allied crate selected. Fire the Forge Python to place it."); break;
        case "Select Axis Crate": self.ng_propModel="mp_supplydrop_axis"; self iPrintln("Axis crate selected. Fire the Forge Python to place it."); break;
        case "Select Marked Crate": self.ng_propModel="mp_supplydrop_boobytrapped"; self iPrintln("Marked crate selected. Fire the Forge Python to place it."); break;
        case "Build 10 Crate Stairs": self thread stairs(); break;
        case "Select Aimed Object": self.ng_selected=self aimedObject(); if(isDefined(self.ng_selected)) self iPrintln("Object selected"); else self iPrintln("Aim at a player, map prop, or Forge crate."); break;
        case "Toggle Script Barriers": self barriers(); break;
        case "Remove My Props":
            for(i=0;i<level.ng_props.size;i++) if(isDefined(level.ng_props[i]) && isDefined(level.ng_props[i].ng_owner) && level.ng_props[i].ng_owner==self) level.ng_props[i] delete();
            self release(); self.ng_selected=undefined; break;
        default: self edit(input); break;
    }
    return true;
}

phase(requireForge,unrestricted)
{
    if(!isDefined(unrestricted)) unrestricted=false;
    requiredRank=3; if(unrestricted) requiredRank=2;
    self endon("death"); self endon("disconnect");
    if(requireForge) self endon("ng_forge_stop");
    if(!isAlive(self) || self IsRemoteControlling() || isDefined(self.heli) || isDefined(self.rtd_anchor)) return;
    self common_scripts\jellymod::closeModMenu();
    self release();
    while(self useButtonPressed() || self meleeButtonPressed()) wait 0.05;
    if((requireForge && !self.forgeOn) || self common_scripts\ng_access::rank()<requiredRank) return;
    if(isDefined(self.newufo)) return;
    self.ng_phaseRequiresForge=requireForge;
    self.ng_unrestricted=unrestricted;
    self.noclipOn=true;
    self phaseMove(requireForge,unrestricted);
}

compact()
{
    kept=[];
    for(i=0;i<level.ng_props.size;i++) if(isDefined(level.ng_props[i])) kept[kept.size]=level.ng_props[i];
    level.ng_props=kept;
}

make(model,origin,angles)
{
    compact();
    if(level.ng_props.size>=100) { self iPrintln("Forge limit: 100 props. Remove some first."); return undefined; }
    // Stock BO1 supply crates use the collision-enabled script_model spawn flag.
    p=spawn("script_model",origin,1);
    p.ng_model=model;
    p setModel(model); p.angles=(0,0,0); p solid();
    p captureBounds(); p.angles=angles;
    p.ng_forge=true; p.ng_owner=self; p.ng_model=model;
    level.ng_props[level.ng_props.size]=p;
    return p;
}

place(model)
{
    start=self getTagOrigin("j_head");
    tr=bulletTrace(start,start+anglesToForward(self getPlayerAngles())*1000,true,self);
    org=tr["position"]+(0,0,18);
    if(distance(start,org)<80) { self iPrintln("Aim farther away to place a prop."); return; }
    a=self getPlayerAngles();
    self.ng_selected=self make(model,org,(0,a[1],0));
    self iPrintln("Prop placed. ADS grabs it; USE turns; FIRE tilts.");
}

stairs()
{
    self endon("disconnect");
    a=self getPlayerAngles(); f=anglesToForward((0,a[1],0));
    start=self.origin+f*100;
    for(i=0;i<10;i++)
    {
        if(self common_scripts\ng_access::rank()<3) return;
        p=self make("mp_supplydrop_ally",start+f*(i*35)+(0,0,i*15),(0,a[1],0));
        if(!isDefined(p)) return;
        self.ng_selected=p; wait 0.05;
    }
    self iPrintln("10 solid crates placed as stairs.");
}

aimedObject()
{
    start=self getTagOrigin("j_head"); forward=anglesToForward(self getPlayerAngles());
    finish=start+forward*1500;
    tr=bulletTrace(start,finish,true,self);
    if(isDefined(tr["entity"]) && self movable(tr["entity"])) return tr["entity"];
    // The Wii trace alone cannot hit PC props with missing collision meshes.
    // Intersect registered prop envelopes, then use a small crosshair tolerance.
    best=undefined; bestScore=999999;
    candidates=[];
    for(i=0;i<level.ng_props.size;i++) if(isDefined(level.ng_props[i])) candidates[candidates.size]=level.ng_props[i];
    for(i=0;i<level.ng_mapProps.size;i++) if(isDefined(level.ng_mapProps[i])) candidates[candidates.size]=level.ng_mapProps[i];
    for(i=0;i<level.players.size;i++) candidates[candidates.size]=level.players[i];
    for(i=0;i<candidates.size;i++)
    {
        p=candidates[i]; if(!self movable(p)) continue;
        point=p.origin+(0,0,24);
        if(isPlayer(p)) point=p.origin+(0,0,38);
        along=vectorDot(point-start,forward);
        if(along<30 || along>1500) continue;
        miss=distance(point,start+forward*along);
        radius=38+along*0.025;
        if(radius>75) radius=75;
        hit=false;
        if(!isPlayer(p)) hit=p segmentHit(start,finish,false)>=0;
        if(!hit && miss>radius) continue;
        score=miss*8+along*0.1;
        if(hit) score=along*0.1;
        if(score<bestScore) { best=p; bestScore=score; }
    }
    return best;
}

movable(p)
{
    if(!isDefined(p) || p==self) return false;
    if(isDefined(p.ng_locked) && p.ng_locked) return false;
    if(isDefined(p.ng_holder) && p.ng_holder!=self) return false;
    if(isPlayer(p))
    {
        if(!isAlive(p) || p isHost() || isDefined(p.newufo) || isDefined(p.rtd_anchor) || isDefined(p.heli)) return false;
        return true;
    }
    if(isDefined(p.ng_forge)) return true;
    return isDefined(p.classname) && p.classname=="script_model" && !isDefined(p.owner) && !isDefined(p.team) && !isDefined(p.script_noteworthy) && isDefined(p.model) && p.model!="tag_origin";
}

cacheMapProps()
{
    wait 2;
    props=getEntArray("script_model","classname");
    for(i=0;i<props.size;i++)
    {
        p=props[i];
        if(!isDefined(p.ng_forge) && !isDefined(p.owner) && !isDefined(p.team) && !isDefined(p.script_noteworthy) && isDefined(p.model) && p.model!="tag_origin")
            level.ng_mapProps[level.ng_mapProps.size]=p;
    }
}


edit(input)
{
    if(!isDefined(self.ng_selected)) { self iPrintln("Select an object first."); return; }
    p=self.ng_selected;
    if(isPlayer(p)) { self iPrintln("Hold AIM to move players. Object edits apply to props."); return; }
    if(isDefined(p.ng_holder) && p.ng_holder!=self) { self iPrintln("Another builder is holding this object."); return; }
    switch(input)
    {
        case "Duplicate Selected":
            if(!isDefined(p.ng_forge)) { self iPrintln("Duplicate is available for Forge props."); return; }
            self.ng_selected=self make(p.ng_model,p.origin+(0,0,35),p.angles); break;
        case "Remove Selected":
            if(!isDefined(p.ng_forge)) { self iPrintln("Remove is available for Forge props; map objects can be moved."); return; }
            p delete(); self.ng_selected=undefined; break;
        case "Rotate Left 15": p.angles+=(0,-15,0); break;
        case "Rotate Right 15": p.angles+=(0,15,0); break;
        case "Raise 10": p setOrigin(p.origin+(0,0,10)); break;
        case "Lower 10": p setOrigin(p.origin-(0,0,10)); break;
    }
}

release()
{
    if(isDefined(self.ng_held) && isDefined(self.ng_held.ng_holder) && self.ng_held.ng_holder==self)
    {
        p=self.ng_held;
        if(isPlayer(p))
        {
            p.ng_grabTick=undefined;
            p freeze_player_controls(false);
            p notify("ng_released");
        }
        else
        {
            // Cancel any unfinished interpolation at the drop position before restoring collision.
            p moveTo(p.origin,0.05);
            p.ng_nextMove=undefined;
            p solid();
        }
        p.ng_holder=undefined;
    }
    self.ng_held=undefined;
}


grabLoop()
{
    self endon("death"); self endon("disconnect");
    self thread releaseOnEnd();
    nextSearch=0; nextHint=0;
    while(true)
    {
        if(!self.forgeOn || self common_scripts\ng_access::rank()<3) { self release(); wait 0.2; continue; }
        aiming=self adsButtonPressed() || self playerADS()>0.05;
        if(!self.menuOpen && aiming)
        {
            if(!isDefined(self.ng_held) && getTime()>=nextSearch)
            {
                nextSearch=getTime()+150;
                p=self aimedObject();
                if(isDefined(p))
                {
                    self.ng_held=p; p.ng_holder=self; self.ng_selected=p;
                    if(isPlayer(p))
                    {
                        p.ng_grabTick=getTime();
                        p freeze_player_controls(true);
                        p thread grabWatchdog();
                        p thread heldPlayerCleanup();
                    }
                    else { p notsolid(); p.ng_nextMove=0; }
                    self iPrintln("Grabbed! Hold AIM to move; release AIM to drop.");
                }
                else if(getTime()>=nextHint) { self iPrintln("Aim at a prop or player and hold AIM to grab."); nextHint=getTime()+2500; }
            }
            if(isDefined(self.ng_held))
            {
                p=self.ng_held;
                pressed=self useButtonPressed();
                if(pressed && !self.ng_rotateDown && !isPlayer(p)) p.angles+=(0,15,0);
                self.ng_rotateDown=pressed;
                // Wii behavior: hold the target 200 units ahead of the player's view.
                dest=self getTagOrigin("j_head")+anglesToForward(self getPlayerAngles())*200;
                if(isPlayer(p))
                {
                    if(!isAlive(p)) self release();
                    else { p setOrigin(safeStep(p.origin,dest-(0,0,36))); p setVelocity((0,0,0)); p.ng_grabTick=getTime(); }
                }
                else
                {
                    // Script models need their mover trajectory updated. Do not overlap moves.
                    if(getTime()>=p.ng_nextMove)
                    {
                        offset=dest-p.origin; step=length(offset);
                        if(step>30) offset=offset*(30/step);
                        p moveTo(p.origin+offset,0.1);
                        p.ng_nextMove=getTime()+150;
                    }
                }
            }
        }
        else { self release(); self.ng_rotateDown=false; }
        wait 0.05;
    }
    self release();
}

heldPlayerCleanup()
{
    self waittill_any("death","disconnect","ng_released");
    if(isDefined(self.ng_holder)) self.ng_holder release();
}


releaseOnEnd()
{
    self waittill_any("death","disconnect");
    self release();
    self.forgeOn=false;
}

start()
{
    if(self common_scripts\ng_access::rank()<3 || !isAlive(self)) return;
    self.ng_oldGun=self getCurrentWeapon();
    self saveLoadout();
    if(!isDefined(self.ng_propModel)) self.ng_propModel="mp_supplydrop_ally";
    self.forgeOn=true; self.ng_rotateDown=false;
    self takeAllWeapons();
    self giveWeapon("python_mp"); self giveMaxAmmo("python_mp"); self switchToWeapon("python_mp");
    self setBlockWeaponPickup("python_mp",true);
    self DisableOffhandWeapons();
    self.ng_forgeOffhandLock=true;
    // Controllers are started by the player spawn listener, outside menu threads.
    self iPrintln("Forge ON: Python fires props. ADS grabs; USE turns; FIRE tilts.");
}

stop()
{
    active=self.forgeOn;
    if(active || (isDefined(self.ng_phaseRequiresForge) && self.ng_phaseRequiresForge)) self common_scripts\jellymod::jm_stopNoclip();
    self release(); self.forgeOn=false;
    if(active && isAlive(self))
    {
        self restoreLoadout();
        self iPrintln("Forge OFF");
    }
    self notify("ng_forge_stop");
}

saveLoadout()
{
    self.ng_savedGuns=self getWeaponsList();
    self.ng_savedClip=[]; self.ng_savedStock=[];
    for(i=0;i<self.ng_savedGuns.size;i++)
    {
        w=self.ng_savedGuns[i];
        self.ng_savedClip[i]=self getWeaponAmmoClip(w);
        self.ng_savedStock[i]=self getWeaponAmmoStock(w);
    }
}

restoreLoadout()
{
    if(self hasWeapon("python_mp")) self setBlockWeaponPickup("python_mp",false);
    self takeAllWeapons();
    if(isDefined(self.ng_savedGuns))
    {
        for(i=0;i<self.ng_savedGuns.size;i++)
        {
            w=self.ng_savedGuns[i]; self giveWeapon(w);
            self setWeaponAmmoClip(w,self.ng_savedClip[i]);
            self setWeaponAmmoStock(w,self.ng_savedStock[i]);
        }
    }
    self EnableOffhandWeapons();
    self.ng_forgeOffhandLock=undefined;
    if(isDefined(self.ng_oldGun) && self hasWeapon(self.ng_oldGun)) self switchToWeapon(self.ng_oldGun);
    self.ng_savedGuns=undefined; self.ng_savedClip=undefined; self.ng_savedStock=undefined;
}

lockLoadout()
{
    self endon("death"); self endon("disconnect");
    while(true)
    {
        if(!self.forgeOn) { wait 0.2; continue; }
        guns=self getWeaponsList();
        for(i=0;i<guns.size;i++) if(guns[i]!="python_mp") self takeWeapon(guns[i]);
        if(!self hasWeapon("python_mp")) self giveWeapon("python_mp");
        self setBlockWeaponPickup("python_mp",true);
        if(!self.menuOpen && self getCurrentWeapon()!="python_mp") self switchToWeapon("python_mp");
        wait 0.1;
    }
}

propShots()
{
    self endon("death"); self endon("disconnect");
    for(;;)
    {
        self waittill("weapon_fired");
        if(!self.forgeOn) continue;
        if(self common_scripts\ng_access::rank()<3) { self stop(); continue; }
        if(self.menuOpen || self getCurrentWeapon()!="python_mp") continue;
        self setWeaponAmmoClip("python_mp",6);
        if(isDefined(self.ng_held)) { if(!isPlayer(self.ng_held)) self.ng_held.angles+=(15,0,0); }
        else if(!self adsButtonPressed()) self place(self.ng_propModel);
    }
}

barriers()
{
    if(level.ng_barriersOff)
    {
        for(i=0;i<level.ng_barriers.size;i++) if(isDefined(level.ng_barriers[i])) level.ng_barriers[i] solid();
        level.ng_barriers=[]; level.ng_barriersOff=false; self iPrintln("Script barriers restored."); return;
    }
    names=strTok("clip|playerclip|barrier|invisiblewall","|");
    for(n=0;n<names.size;n++)
    {
        a=getEntArray(names[n],"targetname");
        for(i=0;i<a.size;i++)
            if(a[i].classname=="script_brushmodel") { a[i] notsolid(); level.ng_barriers[level.ng_barriers.size]=a[i]; }
    }
    level.ng_barriersOff=true;
    self iPrintln("Disabled "+level.ng_barriers.size+" script barriers. Use Phase Through Surfaces for fixed map boundaries.");
}

captureBounds()
{
    // Stable model-space envelopes also work for models without traceable physics.
    self.ng_centerOffset=(0,0,24); self.ng_half=(45,25,24);
    if(isSubStr(self.ng_model,"rcbomb")) { self.ng_half=(22,16,12); self.ng_centerOffset=(0,0,12); }
    else if(isSubStr(self.ng_model,"turret")) { self.ng_half=(40,40,45); self.ng_centerOffset=(0,0,45); }
    else if(isSubStr(self.ng_model,"helo") || isSubStr(self.ng_model,"ch46")) { self.ng_half=(220,140,85); self.ng_centerOffset=(0,0,60); }
    else if(isSubStr(self.ng_model,"veh_")) { self.ng_half=(110,50,45); self.ng_centerOffset=(0,0,45); }
    self.ng_radius=length(self.ng_half)+length(self.ng_centerOffset)+64;
    self.ng_boundsAngles=undefined;
}


axes()
{
    if(isDefined(self.ng_boundsAngles) && self.ng_boundsAngles==self.angles) return;
    self.ng_axis=[];
    self.ng_axis[0]=anglesToForward(self.angles);
    self.ng_axis[1]=anglesToRight(self.angles)*-1;
    self.ng_axis[2]=anglesToUp(self.angles);
    self.ng_boundsAngles=self.angles;
}

// Return the first intersection fraction, or -1. Uses the entire movement segment.
segmentHit(start,finish,playerHull)
{
    if(!isDefined(self.ng_half)) return -1;
    travel=finish-start;
    broad=length(travel)*0.5+self.ng_radius;
    middle=(start+finish)*0.5;
    if(distanceSquared(middle,self.origin)>broad*broad) return -1;
    self axes();
    center=self.origin;
    for(k=0;k<3;k++) center+=self.ng_axis[k]*self.ng_centerOffset[k];
    delta=start-center;
    enter=0; leave=1; inside=true;
    for(k=0;k<3;k++)
    {
        axis=self.ng_axis[k]; bound=self.ng_half[k];
        if(playerHull) bound+=abs(axis[0])*14+abs(axis[1])*14+abs(axis[2])*35-0.5;
        else bound+=4;
        position=vectorDot(delta,axis); velocity=vectorDot(travel,axis);
        if(abs(position)>=bound) inside=false;
        if(abs(velocity)<0.0001)
        {
            if(abs(position)>=bound) return -1;
        }
        else
        {
            near=(0-bound-position)/velocity; far=(bound-position)/velocity;
            if(near>far) { swap=near; near=far; far=swap; }
            if(near>enter) enter=near;
            if(far<leave) leave=far;
            if(enter>leave) return -1;
        }
    }
    // If a builder moves a prop over someone, permit them to escape instead of trapping them.
    if(playerHull && inside) return -1;
    if(leave<0 || enter>1) return -1;
    return enter;
}

safeStep(from,to)
{
    fraction=1;
    // Treat player origin as feet; test a standing hull centered above it.
    start=from+(0,0,36); finish=to+(0,0,36);
    solids=[];
    for(i=0;i<level.ng_props.size;i++) solids[solids.size]=level.ng_props[i];
    for(i=0;i<level.ng_solidProps.size;i++) solids[solids.size]=level.ng_solidProps[i];
    for(i=0;i<solids.size;i++)
    {
        p=solids[i]; if(!isDefined(p) || isDefined(p.ng_holder)) continue;
        t=p segmentHit(start,finish,true);
        if(t>=0 && t<fraction) fraction=t;
    }
    if(fraction>=1) return to;
    fraction-=0.01;
    if(fraction<0) fraction=0;
    return from+(to-from)*fraction;
}

phaseMove(requireForge,unrestricted)
{
    requiredRank=3; if(unrestricted) requiredRank=2;
    self endon("death"); self endon("disconnect"); self endon("stop_noclip");
    if(requireForge) self endon("ng_forge_stop");
    // A networked script-model mover updates the linked player's position on PC.
    self.newufo=spawn("script_model",self.origin);
    self.newufo setModel("tag_origin"); self.newufo notsolid();
    self.newufo.owner=self;
    self linkTo(self.newufo);
    self iPrintln("Noclip: hold [{+activate}] to fly where you look; [{+melee}] exits.");
    nextMove=0;
    for(;;)
    {
        if((requireForge && !self.forgeOn) || self common_scripts\ng_access::rank()<requiredRank) break;
        if(self meleeButtonPressed()) break;
        if(self useButtonPressed() && !self.menuOpen && getTime()>=nextMove)
        {
            from=self.newufo.origin;
            to=from+anglesToForward(self getPlayerAngles())*45;
            if(!unrestricted) to=safeStep(from,to);
            self.newufo moveTo(to,0.1);
            nextMove=getTime()+150;
        }
        wait 0.05;
    }
    self common_scripts\jellymod::jm_stopNoclip();
}

// Fallback for models whose visual geometry has no usable native player collision.
guardProps()
{
    self endon("death"); self endon("disconnect");
    last=self.origin;
    for(;;)
    {
        wait 0.1;
        current=self.origin;
        if(isDefined(self.ng_holder)) { last=current; continue; }
        if(isDefined(self.newufo) && isDefined(self.ng_unrestricted) && self.ng_unrestricted) { last=current; continue; }
        travel=distanceSquared(last,current);
        // Preserve BO1's native grounded step-up over short crate stairs.
        if(level.ng_solidProps.size==0 && !isDefined(self.newufo) && !isDefined(self.rtd_anchor) && self isOnGround() && current[2]>last[2] && current[2]-last[2]<=18)
        { last=current; continue; }
        if(travel>0.01 && travel<262144 && (level.ng_props.size>0 || level.ng_solidProps.size>0))
        {
            safe=safeStep(last,current);
            if(distanceSquared(safe,current)>0.01)
            {
                if(isDefined(self.newufo)) self.newufo setOrigin(safe);
                else if(isDefined(self.rtd_anchor)) self.rtd_anchor setOrigin(safe);
                else self setOrigin(safe);
                self setVelocity((0,0,0));
                current=safe;
            }
        }
        last=current;
    }
}

grabWatchdog()
{
    self endon("death"); self endon("disconnect"); self endon("ng_released");
    for(;;)
    {
        wait 0.2;
        if(!isDefined(self.ng_grabTick)) return;
        if(!isDefined(self.ng_holder) || getTime()-self.ng_grabTick>600)
        {
            self freeze_player_controls(false);
            if(isDefined(self.ng_holder)) self.ng_holder.ng_held=undefined;
            self.ng_holder=undefined; self.ng_grabTick=undefined;
            self notify("ng_released");
            return;
        }
    }
}
