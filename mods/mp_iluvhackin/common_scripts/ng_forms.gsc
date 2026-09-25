#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#using_animtree("ng_forms");

init()
{
    precacheModel("german_shepherd");
    precacheModel("german_shepherd_black");
    precacheModel("tag_origin");
    precacheVehicle("rc_car_medium_mp");
}

menu(dogs)
{
    self.ng_formChoices=[];
    if(dogs)
    {
        self addChoice("German Shepherd","german_shepherd","dog");
        self addChoice("Black Shepherd","german_shepherd_black","dog");
    }
    else
    {
        self addChoice("Allied RC-XD","t5_veh_rcbomb_allies","car");
        self addChoice("Axis RC-XD","t5_veh_rcbomb_axis","car");
        for(i=0;i<level.ng_carModels.size;i++)
            self addChoice(level.ng_carNames[i],level.ng_carModels[i],"car");
    }
    text="";
    for(i=0;i<self.ng_formChoices.size;i++) text+="Drive/Play #"+i+" "+self.ng_formChoices[i].name+"|";
    self common_scripts\jellymod::changeMenu(40,"^3Play As",text+"Exit Form|Close Menu");
}

addChoice(name,model,kind)
{
    entry=spawnStruct(); entry.name=name; entry.model=model; entry.kind=kind;
    self.ng_formChoices[self.ng_formChoices.size]=entry;
}

route(input)
{
    if(input=="Play as a Car") { self menu(false); return true; }
    if(input=="Play as a Dog") { self menu(true); return true; }
    if(input=="Exit Form") { self stop(false); return true; }
    if(getSubStr(input,0,12)!="Drive/Play #") return false;
    parts=strTok(input," "); number=int(getSubStr(parts[1],1,parts[1].size));
    if(!isDefined(self.ng_formChoices) || number<0 || number>=self.ng_formChoices.size) return true;
    if(self common_scripts\ng_access::rank()<2) return true;
    self thread start(self.ng_formChoices[number]);
    return true;
}

start(choice)
{
    if(isDefined(self.ng_formActive) && self.ng_formActive) return;
    if(!isAlive(self) || getDvarInt("jm_rtd")!=0 || common_scripts\ng_admin::isWagerMode())
    { self iPrintln("Play As is available while alive in the base menu mode."); return; }
    if(self IsRemoteControlling() || isDefined(self.rcbomb) || isDefined(self.heli) || isDefined(self.newufo) || isDefined(self.rtd_anchor) || (isDefined(self.forgeOn) && self.forgeOn))
    { self iPrintln("Exit Forge, flight or your current vehicle first."); return; }
    placement=undefined;
    if(choice.kind=="car")
    {
        if(!self isOnGround()) { self iPrintln("Stand on open ground first."); return; }
        placement=self maps\mp\_rcbomb::getRCBombPlacement();
        if(!isDefined(placement)) { self iPrintln("No room to drive here. Try open ground."); return; }
    }
    self common_scripts\jellymod::closeModMenu();
    self.ng_formActive=true; self.ng_formKind=choice.kind;
    self.ng_formRC=(choice.model=="t5_veh_rcbomb_allies" || choice.model=="t5_veh_rcbomb_axis");
    self.ng_formDetonating=false;
    self.ng_formSpeed=self getMoveSpeedScale();
    self.ng_formThird=0;
    if(isDefined(self.togThird) && self.togThird) self.ng_formThird=1;
    self.ng_formHud=self createFontString("objective",1.35);
    self.ng_formHud setPoint("BOTTOM","BOTTOM",0,-65);
    self.ng_formHud setText("^2"+choice.name+" ^7| Hold [{+activate}] to exit");
    self thread endWatcher("death");
    self thread endWatcher("disconnect");
    self thread endWatcher("joined_team");
    self thread endWatcher("joined_spectators");
    self thread endWatcher("spawned");
    self thread gameEndWatcher();
    self endon("ng_form_end");
    if(choice.kind=="car")
    {
        model="t5_veh_rcbomb_allies";
        if(choice.model=="t5_veh_rcbomb_axis") model=choice.model;
        self.ng_formCar=spawnVehicle(model,"ng_fun_car","rc_car_medium_mp",placement.origin,placement.angles);
        if(!isDefined(self.ng_formCar)) { self stop(false); return; }
        car=self.ng_formCar;
        car MakeVehicleUnusable(); car SetOwner(self); car SetVehicleTeam(self.team); car.team=self.team;
        if(choice.model!=model)
        {
            // Keep the native driving chassis network-visible beneath the vehicle body.
            self.ng_formShell=spawn("script_model",car.origin);
            self.ng_formShell setModel(choice.model); self.ng_formShell.angles=car.angles;
            self.ng_formShell.owner=self; self.ng_formShell notsolid(); self.ng_formShell linkTo(car);
        }
        car useVehicle(self,0);
        cameraHeight=100; cameraDistance=240;
        if(self.ng_formRC) { cameraHeight=40; cameraDistance=95; }
        self.ng_formCamera=spawn("script_model",car.origin+(0,0,cameraHeight)-anglesToForward(car.angles)*cameraDistance);
        self.ng_formCamera setModel("tag_origin"); self.ng_formCamera linkTo(car);
        self CameraSetPosition(self.ng_formCamera); self CameraSetLookAt(car); self CameraActivate(true);
        self thread endWatcher("exit_vehicle");
        car thread vehicleEndWatcher(self);
        if(self.ng_formRC)
        {
            self.ng_formHud setText("^2"+choice.name+" ^7| [{+attack}]: DETONATE | Hold [{+activate}]: exit");
            self iPrintln("RC-XD: FIRE detonates. Hold USE / INTERACT to exit without detonating.");
        }
        else self iPrintln("Use the RC vehicle movement controls. Hold USE / INTERACT to exit.");
    }
    else
    {
        self hide(); self disableWeapons(); self DisableOffhandWeapons();
        self setMoveSpeedScale(1.4); self setClientDvar("cg_thirdPerson",1);
        self.ng_formShell=spawn("script_model",self.origin);
        self.ng_formShell setModel(choice.model); self.ng_formShell.angles=(0,self.angles[1],0);
        self.ng_formShell.owner=self; self.ng_formShell notsolid(); self.ng_formShell linkTo(self);
        self.ng_formShell UseAnimTree(#animtree,true);
        self.ng_formShell SetAnim(%german_shepherd_idle,1,0,1);
        self.ng_formHud setText("^2"+choice.name+" ^7| FIRE: bite | AIM: bark | Hold [{+activate}]: exit");
    }
    // The menu's select key must be released before it can exit the new form.
    armed=false; fireArmed=false; heldSince=0; nextBite=0; nextBark=0; running=false; lastPos=self.origin;
    while(isAlive(self))
    {
        if(self common_scripts\ng_access::rank()<2) break;
        if(!self useButtonPressed()) { armed=true; heldSince=0; }
        else if(armed)
        {
            if(heldSince==0) heldSince=getTime();
            if(getTime()-heldSince>=400) break;
        }
        if(choice.kind=="car")
        {
            if(!isDefined(self.ng_formCar)) break;
            if(!self attackButtonPressed()) fireArmed=true;
            else if(self.ng_formRC && fireArmed)
            {
                self thread detonateCar();
                return;
            }
        }
        else
        {
            moving=distanceSquared(self.origin,lastPos)>1;
            if(moving!=running)
            {
                running=moving;
                if(running) { self.ng_formShell SetAnim(%german_shepherd_idle,0,0.15,1); self.ng_formShell SetAnim(%german_shepherd_run,1,0.15,1); }
                else { self.ng_formShell SetAnim(%german_shepherd_run,0,0.15,1); self.ng_formShell SetAnim(%german_shepherd_idle,1,0.15,1); }
            }
            lastPos=self.origin;
            if(self attackButtonPressed() && getTime()>=nextBite) { nextBite=getTime()+700; self bite(); }
            if(self adsButtonPressed() && getTime()>=nextBark) { nextBark=getTime()+1200; self playSound("aml_dog_bark_close"); }
        }
        wait 0.05;
    }
    self stop(false);
}

detonateCar()
{
    if(!isDefined(self.ng_formActive) || !self.ng_formActive || !self.ng_formRC || self.ng_formDetonating || !isDefined(self.ng_formCar)) return;
    self.ng_formDetonating=true;
    origin=self.ng_formCar.origin;
    // Detach and remove the driving entities before applying blast damage.
    // This worker does not end on the form cleanup notification.
    self stop(false);
    if(isDefined(level._effect["rcbombexplosion"])) playFX(level._effect["rcbombexplosion"],origin);
    playSoundAtPosition("mpl_sab_exp_suitcase_bomb_main",origin);
    self radiusDamage(origin+(0,0,10),256,350,25,self,"MOD_EXPLOSIVE","rcbomb_mp");
}

bite()
{
    start=self getEye(); direction=anglesToForward(self getPlayerAngles());
    trace=bulletTrace(start,start+direction*100,true,self);
    target=trace["entity"];
    if(!isDefined(target) || !isPlayer(target) || !isAlive(target) || target==self) return;
    if(level.teambased && target.team==self.team) return;
    target maps\mp\gametypes\_callbacksetup::CodeCallback_PlayerDamage(self,self,100,0,"MOD_MELEE","dog_bite_mp",trace["position"],direction,"none",0);
}

endWatcher(event)
{
    self endon("ng_form_end");
    self waittill(event);
    self stop(event=="disconnect");
}

gameEndWatcher()
{
    self endon("ng_form_end");
    level waittill("game_ended");
    self stop(false);
}

vehicleEndWatcher(player)
{
    player endon("ng_form_end");
    self waittill("death");
    player stop(false);
}

stop(disconnected)
{
    if(!isDefined(self.ng_formActive) || !self.ng_formActive) return;
    self.ng_formActive=false;
    // Cleanup runs in a separate thread so notification can cancel every owner worker.
    self thread cleanup(disconnected);
}

cleanup(disconnected)
{
    self notify("ng_form_end");
    if(!disconnected)
    {
        if(self.ng_formKind=="car") { self CameraActivate(false); self unlink(); }
        else
        {
            self show(); self enableWeapons(); self EnableOffhandWeapons();
            self setMoveSpeedScale(self.ng_formSpeed); self setClientDvar("cg_thirdPerson",self.ng_formThird);
        }
    }
    if(isDefined(self.ng_formCamera)) self.ng_formCamera delete();
    if(isDefined(self.ng_formShell)) self.ng_formShell delete();
    if(isDefined(self.ng_formCar)) self.ng_formCar delete();
    if(isDefined(self.ng_formHud)) self.ng_formHud destroy();
    self.ng_formCamera=undefined; self.ng_formShell=undefined; self.ng_formCar=undefined; self.ng_formHud=undefined;
    self.ng_formKind=undefined;
}
