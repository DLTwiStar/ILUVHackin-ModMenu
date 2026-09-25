#include common_scripts\utility;
#include maps\mp\_utility;

switchMode(mode)
{
    mapName=getDvar("mapname"); gameType=getDvar("g_gametype");
    if(mode=="nuketown") { mapName="mp_nuked"; gameType="tdm"; }
    if(mode=="bounty") gameType="dm";
    self common_scripts\ng_admin::requestChange(mapName,gameType,mode);
}


book(page)
{
    rows=common_scripts\nitys_rtd::rollNames();
    if(page<0) page=9;
    if(page>9) page=0;
    self.ng_bookPage=page;
    text="";
    for(i=page*10;i<page*10+10;i++) text+="#"+(i+1)+" "+rows[i]+"|";
    text+="Previous Rolls|Next Rolls|Close Menu";
    self common_scripts\jellymod::changeMenu(18,"^3Rolls "+(page*10+1)+"-"+(page*10+10),text);
}

describe(input)
{
    tokens=strTok(input," ");
    number=int(getSubStr(tokens[0],1,tokens[0].size));
    if(number<1||number>100) return;
    names=common_scripts\nitys_rtd::rollNames();
    hints=common_scripts\nitys_rtd::rollHints();
    self iPrintlnBold("^3#"+number+" ^7"+names[number-1]);
    self iPrintln(hints[number-1]);
}

pilotAttackHelicopter()
{
    self endon("death"); self endon("disconnect");
    if(self.rtd_enabled) { self iPrintln("Leave RTD through Fun before starting helicopter control."); return; }
    if(isDefined(self.heli)||isDefined(self.newufo)||isDefined(self.rtd_anchor)) { self iPrintln("Exit your current vehicle or flight first."); return; }
    if(!isDefined(level.heli_primary_path)||level.heli_primary_path.size==0) { self iPrintln("This map has no helicopter flight path."); return; }
    self common_scripts\jellymod::closeModMenu();
    // Use the stock pilot implementation, not the automatic Huey gunner path.
    result=self maps\mp\_helicopter_player::useKillstreakHelicopterPlayer("helicopter_player_firstperson_mp");
    if(isDefined(result)&&result&&isDefined(self.heli))
    {
        if(isDefined(level.chopperRegular))
        {
            self.heli setModel(level.chopperRegular);
            self.heli setEnemyModel(level.chopperRegular);
        }
        self iPrintln("Attack helicopter: use the game's helicopter pilot controls.");
    }
    else self iPrintln("Helicopter unavailable: stand on open ground and wait for airspace.");
}

chopperGunner()
{
    self endon("death"); self endon("disconnect");
    if(self.rtd_enabled) { self iPrintln("Leave RTD through Fun before starting helicopter control."); return; }
    if(isDefined(self.heli)||isDefined(self.newufo)||isDefined(self.rtd_anchor)) return;
    self common_scripts\jellymod::closeModMenu();
    result=self maps\mp\_helicopter_player::useKillstreakHelicopterGunner("helicopter_gunner_mp");
    if(!isDefined(result)||!result) self iPrintln("Chopper Gunner unavailable: stand on open ground and wait for airspace.");
}
