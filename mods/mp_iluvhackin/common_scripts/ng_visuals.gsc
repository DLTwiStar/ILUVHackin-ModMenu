#include common_scripts\utility;
#include maps\mp\_utility;

init()
{
    // These are real BO1 renderer dvars, including the native helical tracer controls.
    level.ng_tracerNames=strTok("cg_tracerchance|cg_firstPersonTracerChance|cg_tracerlength|cg_tracerSpeed|cg_tracerwidth|cg_tracerScrewDist|cg_tracerScrewRadius|cg_tracerScale","|");
    level.ng_wiiNames=strTok("r_fullbright|r_lodScaleRigid|r_lodScaleSkinned|r_texFilterMipBias|r_normalMap|r_specularColorScale|r_dof_enable","|");
    level thread restoreAtEnd();
}

toggle()
{
    if(self common_scripts\ng_access::rank()<2) return;
    if(isDefined(self.ng_spiral) && self.ng_spiral)
    { self restoreTracers(); self iPrintln("Spiral tracers OFF"); return; }
    self.ng_tracerSaved=[];
    values=strTok("1|1|700|650|4|80|7|1","|");
    for(i=0;i<level.ng_tracerNames.size;i++)
    {
        name=level.ng_tracerNames[i]; self.ng_tracerSaved[i]=getDvar(name);
        self setClientDvar(name,values[i]);
    }
    self.ng_spiral=true;
    self iPrintln("Native spiral tracers ON. Fire a bullet weapon with the menu closed.");
}

restoreTracers()
{
    if(isDefined(self.ng_tracerSaved))
        for(i=0;i<level.ng_tracerNames.size;i++) self setClientDvar(level.ng_tracerNames[i],self.ng_tracerSaved[i]);
    self.ng_tracerSaved=undefined; self.ng_spiral=false;
}

wii()
{
    // Host owns the local renderer, allowing its actual original settings to be captured.
    if(!self isHost()) { self iPrintln("Wii Graphics is a local-host graphics toggle."); return; }
    if(isDefined(self.ng_wii) && self.ng_wii)
    { self restoreWii(); self iPrintln("Wii Graphics OFF - previous settings restored."); return; }
    self.ng_wiiSaved=[];
    values=strTok("1|4|4|3|1|0|0","|");
    for(i=0;i<level.ng_wiiNames.size;i++)
    {
        name=level.ng_wiiNames[i]; self.ng_wiiSaved[i]=getDvar(name);
        self setClientDvar(name,values[i]);
    }
    self.ng_wii=true;
    self iPrintln("Wii Graphics ON: flat lighting, blurry textures, low-detail models.");
}

restoreWii()
{
    if(isDefined(self.ng_wiiSaved))
        for(i=0;i<level.ng_wiiNames.size;i++) self setClientDvar(level.ng_wiiNames[i],self.ng_wiiSaved[i]);
    self.ng_wiiSaved=undefined; self.ng_wii=false;
}

restoreAll()
{
    for(i=0;i<level.players.size;i++)
    {
        level.players[i] restoreTracers();
        level.players[i] restoreWii();
    }
}

restoreAtEnd()
{
    level waittill("game_ended");
    restoreAll();
}

restoreOnDisconnect()
{
    self waittill("disconnect");
    self restoreTracers(); self restoreWii();
}
