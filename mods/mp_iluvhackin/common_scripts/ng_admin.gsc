#include common_scripts\utility;
#include maps\mp\_utility;

init()
{
    // Only maps verified in this installation are offered.
    level.ng_mapIds=strTok("mp_array|mp_cracked|mp_crisis|mp_firingrange|mp_hanoi|mp_cairo|mp_havoc|mp_nuked|mp_radiation|mp_mountain|mp_villa|mp_russianbase|mp_duga|mp_cosmodrome|mp_berlinwall2|mp_discovery|mp_kowloon|mp_stadium","|");
    level.ng_mapNames=strTok("Array|Cracked|Crisis|Firing Range|Hanoi|Havana|Jungle|Nuketown|Radiation|Summit|Villa|WMD|Grid|Launch|Berlin Wall|Discovery|Kowloon|Stadium","|");
    level thread restoreBots();
    level thread transitionController();
}

route(input)
{
    if(input=="Change Map")
    {
        text="";
        for(i=0;i<level.ng_mapNames.size;i++) text+="Map: "+level.ng_mapNames[i]+"|";
        self common_scripts\jellymod::changeMenu(30,"^3Change Map",text+"Admin Menu|Close Menu"); return true;
    }
    if(input=="Wager Modes")
    {
        self common_scripts\jellymod::changeMenu(31,"^3Wager Modes","Gun Game|One in the Chamber|Sticks and Stones|Sharpshooter|Team Deathmatch|Free For All|Add 1 Bot|Fill to 7 Bots|Admin Menu|Close Menu"); return true;
    }
    if(getSubStr(input,0,5)=="Map: ")
    {
        if(self common_scripts\ng_access::rank()<3) return true;
        for(i=0;i<level.ng_mapNames.size;i++)
            if(input=="Map: "+level.ng_mapNames[i]) { self thread change(level.ng_mapIds[i],getDvar("g_gametype"),true); return true; }
        return true;
    }
    if(!common_scripts\ng_access::contains("Gun Game|One in the Chamber|Sticks and Stones|Sharpshooter|Team Deathmatch|Free For All|Add 1 Bot|Fill to 7 Bots",input)) return false;
    if(self common_scripts\ng_access::rank()<3) return true;
    if(input=="Add 1 Bot") { self thread addBots(1); return true; }
    if(input=="Fill to 7 Bots") { self thread addBots(7-botCount()); return true; }
    names=strTok("Gun Game|One in the Chamber|Sticks and Stones|Sharpshooter|Team Deathmatch|Free For All","|");
    modes=strTok("gun|oic|hlnd|shrp|tdm|dm","|");
    for(i=0;i<names.size;i++) if(input==names[i]) self thread change(getDvar("mapname"),modes[i],false);
    return true;
}

change(mapName,mode,keepRtd)
{
    next="normal";
    if(keepRtd && getDvarInt("jm_rtd")==1) next="rtd";
    if(keepRtd && getDvarInt("jm_rtd")==2) next="rtd2";
    self requestChange(mapName,mode,next);
}

requestChange(mapName,mode,extension)
{
    if(self common_scripts\ng_access::rank()<3) { self iPrintln("Host or Cohost permission is required."); return; }
    request=spawnStruct(); request.map=mapName; request.mode=mode; request.extension=extension;
    self.ng_pendingChange=request;
    label=mapName+" / "+mode;
    if(extension=="nuketown") label="Nuketown Zombies";
    if(extension=="rtd") label="Roll the Dice";
    if(extension=="rtd2") label="Roll the Dice V2";
    if(extension=="bounty") label="Bounty Relay";
    self common_scripts\jellymod::changeMenu(32,"^3Restart: "+label+"?","No - Go Back|Yes - Restart Now");
}

confirmChange()
{
    if(self common_scripts\ng_access::rank()<3) { self iPrintln("Host or Cohost permission is required."); return; }
    if(!isDefined(self.ng_pendingChange)) { self iPrintln("Choose a map or mode first."); return; }
    if(isDefined(level.ng_transition)) { self iPrintln("A change is already queued."); return; }
    request=self.ng_pendingChange; self.ng_pendingChange=undefined;
    // The level-owned worker survives closing the menu and player death.
    level.ng_transition=request;
    self common_scripts\jellymod::closeModMenu();
    self iPrintlnBold("Confirmed. Restarting the match...");
}

transitionController()
{
    for(;;)
    {
        if(isDefined(level.ng_transition))
        {
            request=level.ng_transition;
            oldType=level.gametype;
            for(formPlayer=0;formPlayer<level.players.size;formPlayer++) level.players[formPlayer] common_scripts\ng_forms::stop(false);
            for(vipPlayer=0;vipPlayer<level.players.size;vipPlayer++) level.players[vipPlayer] common_scripts\ng_vip::reset(false);
            common_scripts\ng_visuals::restoreAll();
            setDvar("ng_bot_restore",botCount());
            common_scripts\ng_bounty::restoreDvars();
            common_scripts\ng_nuketown::restoreDvars();
            setDvar("ng_rtd_nextmode",request.extension);
            setDvar("jm_rtd_force",""); setDvar("ng_rtd_v2_force","");
            setDvar("g_gametype",request.mode);
            setDvar("xblive_wagermatch",0);
            iPrintlnBold("Restarting: "+request.map+" / "+request.mode);
            wait 0.5;
            if(request.map==getDvar("mapname") && request.mode==oldType) map_restart(false);
            else
            {
                setDvar("sv_mapRotationCurrent","gametype "+request.mode+" map "+request.map);
                map(request.map);
                // Fallback through BO1's level-exit rotation if a local map call returns.
                wait 2;
                exitLevel(false);
            }
            wait 4;
            // Never leave a permanent lock after an engine-rejected transition.
            level.ng_transition=undefined;
            setDvar("ng_rtd_nextmode","");
            iPrintlnBold("The engine did not change the match. You can retry the selection.");
        }
        wait 0.1;
    }
}


isWagerMode()
{
    return common_scripts\ng_access::contains("gun|oic|hlnd|shrp",getDvar("g_gametype"));
}

botCount()
{
    count=0;
    for(i=0;i<level.players.size;i++) if(level.players[i] isTestClient()) count++;
    return count;
}

restoreBots()
{
    wanted=getDvarInt("ng_bot_restore"); setDvar("ng_bot_restore",0);
    if(wanted<=0) return;
    // Stock Combat Training gets the first opportunity to repopulate the lobby.
    wait 10;
    host=GetHostPlayer(); if(!isDefined(host)) return;
    host addBots(wanted-botCount());
}

addBots(count)
{
    if(self common_scripts\ng_access::rank()<3 || isDefined(level.ng_addingBots)) return;
    level.ng_addingBots=true;
    if(count>17) count=17;
    difficulty=getDvar("bot_difficulty"); if(difficulty=="") difficulty="normal";
    maps\mp\gametypes\_bot::bot_set_difficulty(difficulty);
    for(i=0;i<count;i++)
    {
        if(level.players.size>=getDvarInt("sv_maxclients")) break;
        bot=AddTestClient(); if(!isDefined(bot)) break;
        bot.pers["isBot"]=true; bot.equipment_enabled=true;
        team="axis";
        if(isDefined(self.pers["team"]) && self.pers["team"]=="axis") team="allies";
        bot thread maps\mp\gametypes\_bot::bot_spawn_think(team);
        wait 0.5;
    }
    level.ng_addingBots=undefined;
    self iPrintln("Bots in lobby: "+botCount());
}
