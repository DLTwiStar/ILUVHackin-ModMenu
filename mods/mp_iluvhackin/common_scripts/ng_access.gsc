#include common_scripts\utility;
#include maps\mp\_utility;

rank()
{
    if(self isHost()) return 4;
    if(isDefined(self.pers["ng_role"])) return self.pers["ng_role"];
    return 0;
}

setup()
{
    self.pers["ng_role"]=0;
    self.ng_adminAmmo=false;
    self.ng_adminGod=false;
    self.ng_hostDefaultsSet=undefined;
    self hostDefaults();
    self updateStatus();
    self thread ammoShots();
    self common_scripts\ng_vip::setup();
    self thread common_scripts\ng_visuals::restoreOnDisconnect();
}

hostDefaults()
{
    if(!self isHost() || getDvarInt("jm_rtd")!=0 || isDefined(self.ng_hostDefaultsSet) || common_scripts\ng_admin::isWagerMode()) return;
    self.ng_hostDefaultsSet=true;
    self.ng_adminAmmo=true; self.ng_adminGod=true;
}

updateStatus()
{
    names=strTok("Scrub|The new guy|VIP|Cohost|Host","|");
    self.varStatus=names[self rank()];
    self notify("update_status");
}

contains(list,value)
{
    a=strTok(list,"|");
    for(i=0;i<a.size;i++) if(a[i]==value) return true;
    return false;
}

allowed(input)
{
    // Navigation is view-only for Scrubs. Every mutation is checked before dispatch.
    if(contains("Play as a Car|Play as a Dog|Close Menu|Bounty Relay|Change Map|Wager Modes|Miscellaneous|Stats|Toggle Prestige|Killstreaks|Special Guns|Admin Menu|Fun|Roll the Dice|Roll the Dice V2|Nuketown Zombies|Browse Rolls|Next Rolls|Previous Rolls|Game Status|End Game Options|Admin Misc|Player Menu|Back to Player Menu|Permissions|VIP Menu|Forge|Forge Props|Forge Object|Vehicle Props|Killstreak Props",input)) return true;
    if(getSubStr(input,0,1)=="#" || getSubStr(input,0,8)=="Player #") return true;
    r=self rank();
    if(input=="Exit Form") return true;
    if(r>=2 && getSubStr(input,0,12)=="Drive/Play #") return true;
    if(r>=3) return true;
    if(r>=1 && contains("radar|mortar|rcbomb|supplydrop|radardirection|m220_tow|dogs|Death Machine|Grim Reaper|Default Weapon|Golden Crossbow|Teleport Gun",input)) return true;
    if(r>=2 && contains("Moon Gravity|Aimbot|Super Speed|No Fall Damage|Vampire|Infinite Advanced UAV|Wii Graphics|My Infinite Ammo|My Godmode|Spiral Bullet Tracers|Teleport|Vision|3rd Person|Sexy Graphics|Suicide",input)) return true;
    self iPrintln("Your role can view this option but cannot use it.");
    return false;
}

players()
{
    self.ng_playerChoices=[];
    text="";
    for(i=0;i<level.players.size;i++)
    {
        p=level.players[i]; self.ng_playerChoices[i]=p;
        text+="Player #"+i+" "+safeName(p.name)+"|";
    }
    self common_scripts\jellymod::changeMenu(21,"^3Players",text+"Close Menu");
}

playerMenu()
{
    if(!isDefined(self.ng_target)) { self iPrintln("Select a player first."); return; }
    self common_scripts\jellymod::changeMenu(22,"^3"+safeName(self.ng_target.name),"Permissions|Infinite Ammo|Godmode|Respawn Player|Kick|Kill|Derank and Kick|Derank without Kick|Back to Player Menu|Close Menu");
}

route(input)
{
    if(self common_scripts\ng_vip::route(input)) return true;
    if(getSubStr(input,0,8)=="Player #")
    {
        t=strTok(input," "); n=int(getSubStr(t[1],1,t[1].size));
        if(!isDefined(self.ng_playerChoices) || n<0 || n>=self.ng_playerChoices.size) return true;
        self.ng_target=self.ng_playerChoices[n]; self playerMenu(); return true;
    }
    if(contains("Player Menu|Back to Player Menu",input)) { self players(); return true; }
    if(input=="Permissions")
    {
        self common_scripts\jellymod::changeMenu(23,"^3Permissions","Grant Scrub|Grant The new guy|Grant VIP|Grant Cohost|Back to Player Menu|Close Menu"); return true;
    }
    if(input=="VIP Menu")
    {
        self common_scripts\jellymod::changeMenu(24,"^3VIP Menu","My Infinite Ammo|My Godmode|Moon Gravity|Aimbot|Super Speed|No Fall Damage|Vampire|Infinite Advanced UAV|Teleport|Vision|3rd Person|Close Menu"); return true;
    }
    if(input=="My Infinite Ammo") { self toggleAmmo(); return true; }
    if(input=="My Godmode") { self toggleGod(); return true; }
    if(contains("Grant Scrub|Grant The new guy|Grant VIP|Grant Cohost|Infinite Ammo|Godmode|Respawn Player|Kick|Kill|Derank and Kick|Derank without Kick",input))
    { self playerAction(input); return true; }
    if(input=="Freeze All" || input=="Teleport All")
    {
        if(self rank()<3) return true;
        if(!isDefined(self.ng_freeze)) self.ng_freeze=false;
        if(input=="Freeze All") self.ng_freeze=!self.ng_freeze;
        for(i=0;i<level.players.size;i++)
        {
            p=level.players[i]; if(p isHost()) continue;
            if(input=="Freeze All") p freeze_player_controls(self.ng_freeze);
            else if(isAlive(p)) p setOrigin(self.origin+(0,0,40));
        }
        return true;
    }
    if(self common_scripts\ng_admin::route(input)) return true;
    return self common_scripts\ng_forge::route(input);
}

playerAction(input)
{
    if(self rank()<3) return;
    if(!isDefined(self.ng_target)) { self iPrintln("That player has left. Select a player again."); return; }
    p=self.ng_target;
    if(input=="Infinite Ammo") { if(isDefined(p.ng_adminAmmo) && p.ng_adminAmmo) input="Infinite Ammo OFF"; else input="Infinite Ammo ON"; }
    if(input=="Godmode") { if(isDefined(p.ng_adminGod) && p.ng_adminGod) input="Godmode OFF"; else input="Godmode ON"; }
    targetName=p.name;
    positive=contains("Infinite Ammo ON|Godmode ON",input);
    if(p isHost() && p!=self && !positive)
    { self iPrintln("The host is protected from player-management actions."); return; }
    if(p isHost() && !contains("Infinite Ammo ON|Infinite Ammo OFF|Godmode ON|Godmode OFF",input)) { self iPrintln("The host cannot be deranked or removed."); return; }
    if(getSubStr(input,0,6)=="Grant ")
    {
        roles=strTok("Grant Scrub|Grant The new guy|Grant VIP|Grant Cohost","|");
        for(i=0;i<roles.size;i++) if(input==roles[i]) p.pers["ng_role"]=i;
        p updateStatus();
        p common_scripts\jellymod::closeModMenu();
        p common_scripts\ng_forge::stop();
        p.ng_adminAmmo=false; p.ng_adminGod=false; p DisableInvulnerability();
        p notify("end_tele_gun");
        p common_scripts\jellymod::jm_stopNoclip();
        p iPrintln("Your role is now "+p.varStatus);
        self iPrintln(p.name+": "+p.varStatus); return;
    }
    switch(input)
    {
        case "Infinite Ammo ON": p.ng_adminAmmo=true; p refill(); break;
        case "Infinite Ammo OFF": p.ng_adminAmmo=false; break;
        case "Godmode ON": p.ng_adminGod=true; p EnableInvulnerability(); break;
        case "Godmode OFF": p.ng_adminGod=false; p DisableInvulnerability(); break;
        case "Respawn Player": p thread respawn(); break;
        case "Kill": p.ng_adminGod=false; p DisableInvulnerability(); p suicide(); break;
        case "Kick": kick(p getEntityNumber()); break;
        case "Derank and Kick": p common_scripts\jellymod::derankPlayer(); kick(p getEntityNumber()); break;
        case "Derank without Kick": p common_scripts\jellymod::derankPlayer(); break;
    }
    self iPrintln(input+" applied to "+targetName);
}

toggleAmmo()
{
    if(self rank()<2) return;
    if(!isDefined(self.ng_adminAmmo)) self.ng_adminAmmo=false;
    self.ng_adminAmmo=!self.ng_adminAmmo;
    if(self.ng_adminAmmo) { self refill(); self iPrintln("Infinite Ammo ON"); }
    else self iPrintln("Infinite Ammo OFF");
}

toggleGod()
{
    if(self rank()<2) return;
    if(!isDefined(self.ng_adminGod)) self.ng_adminGod=false;
    self.ng_adminGod=!self.ng_adminGod;
    if(self.ng_adminGod) { self EnableInvulnerability(); self iPrintln("Godmode ON"); }
    else { self DisableInvulnerability(); self iPrintln("Godmode OFF"); }
}

refill()
{
    if(!isAlive(self)) return;
    gun=self getCurrentWeapon();
    if(gun!="none" && gun!="knife_mp")
    {
        self giveMaxAmmo(gun);
        self setWeaponAmmoClip(gun,weaponClipSize(gun));
    }
    types=strTok("frag_grenade_mp|sticky_grenade_mp|hatchet_mp|flash_grenade_mp|concussion_grenade_mp|willy_pete_mp|tabun_gas_mp|c4_mp|claymore_mp","|");
    for(i=0;i<types.size;i++)
        if(self hasWeapon(types[i])) self giveMaxAmmo(types[i]);
}

ammoShots()
{
    self endon("disconnect");
    for(;;)
    {
        self waittill("weapon_fired");
        if(isDefined(self.ng_adminAmmo) && self.ng_adminAmmo) self refill();
    }
}

respawn()
{
    self endon("disconnect");
    if(self isHost()) return;
    if(isDefined(self.ng_respawning)) return;
    if(!isDefined(self.pers["team"]) || self.pers["team"]=="spectator") return;
    self.ng_respawning=true;
    // End existing life workers before stock spawn starts the new life.
    self common_scripts\ng_forge::stop();
    self notify("death");
    self common_scripts\jellymod::closeModMenu();
    self common_scripts\jellymod::jm_stopNoclip();
    self freeze_player_controls(false);
    wait 0.1;
    self [[level.spawnPlayer]]();
    self.ng_respawning=undefined;
}

safeName(name)
{
    out="";
    for(c=0;c<name.size && out.size<24;c++)
    {
        ch=getSubStr(name,c,c+1);
        if(ch=="^") { c++; continue; }
        if(ch=="|" || ch=="\n" || ch=="\r") ch=" ";
        out+=ch;
    }
    return out;
}
