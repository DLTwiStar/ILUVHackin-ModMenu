#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

render(items)
{
    self endon("death"); self endon("disconnect"); self endon("exit_menu");
    count=items.size;
    columns=1; perColumn=count; scale=1.45; spacing=23;
    if(count>15) { columns=2; perColumn=int((count+1)/2); scale=1.25; spacing=21; }
    if(perColumn>16) { spacing=330/perColumn; scale=1.0; }
    rows=[]; previous=[];
    for(i=0;i<count;i++)
    {
        column=int(i/perColumn); row=i-column*perColumn;
        rows[i]=self createFontString("objective",scale);
        if(columns==1) rows[i] setPoint("TOPRIGHT","TOPRIGHT",-18,50+row*spacing);
        else rows[i] setPoint("TOPLEFT","TOPLEFT",18+column*310,50+row*spacing);
        rows[i].sort=20; rows[i].alpha=1;
        self thread common_scripts\jellymod::destroyEvent(rows[i],"death","exit_menu","disconnect");
        previous[i]="";
    }
    while(self.menuOpen)
    {
        for(i=0;i<count;i++)
        {
            label=self label(items[i],columns);
            if(self.ng_cursor==i) label="^3[ "+label+" ^3]";
            if(label!=previous[i]) { rows[i] setText(label); previous[i]=label; }
        }
        wait 0.15;
    }
}

label(input,columns)
{
    text=input;
    if(getSubStr(input,0,8)=="Player #")
    {
        tokens=strTok(input," "); n=int(getSubStr(tokens[1],1,tokens[1].size));
        if(!isDefined(self.ng_playerChoices) || n>=self.ng_playerChoices.size || !isDefined(self.ng_playerChoices[n])) return "^7> Player left";
        p=self.ng_playerChoices[n]; name=common_scripts\ng_access::safeName(p.name);
        if(columns==2 && name.size>15) name=getSubStr(name,0,15);
        roles=strTok("Scrub|The new guy|VIP|Cohost|Host","|");
        return "^7> "+name+" ^3["+roles[p common_scripts\ng_access::rank()]+"]";
    }
    if(input=="My Infinite Ammo") text="Infinite Ammo";
    if(input=="My Godmode") text="Godmode";
    state=self state(input);
    color="^7";
    if(isDefined(state)) { if(state) color="^2"; else color="^1"; }
    marker="* ";
    if(common_scripts\ng_access::contains("Play as a Car|Play as a Dog|Bounty Relay|Previous Screen|Change Map|Wager Modes|Miscellaneous|Stats|Toggle Prestige|Killstreaks|Special Guns|Admin Menu|Fun|Roll the Dice|Roll the Dice V2|Nuketown Zombies|Browse Rolls|Next Rolls|Previous Rolls|Game Status|End Game Options|Admin Misc|Player Menu|Back to Player Menu|Permissions|VIP Menu|Forge|Forge Props|Forge Object|Vehicle Props|Killstreak Props",input)) marker="> ";
    return color+marker+text;
}

state(input)
{
    p=self;
    if(input=="Infinite Ammo" || input=="Godmode")
    {
        if(!isDefined(self.ng_target)) return false;
        p=self.ng_target;
    }
    switch(input)
    {
        case "Moon Gravity": return isDefined(self.ng_vipMoon) && self.ng_vipMoon;
        case "Aimbot": return isDefined(self.ng_vipAim) && self.ng_vipAim;
        case "Super Speed": return isDefined(self.ng_vipSpeed) && self.ng_vipSpeed;
        case "No Fall Damage": return isDefined(self.ng_vipNoFall) && self.ng_vipNoFall;
        case "Vampire": return isDefined(self.ng_vipVampire) && self.ng_vipVampire;
        case "Infinite Advanced UAV": return isDefined(self.ng_vipRadar) && self.ng_vipRadar;
        case "Infinite Ammo": case "My Infinite Ammo": return isDefined(p.ng_adminAmmo) && p.ng_adminAmmo;
        case "Godmode": case "My Godmode": return isDefined(p.ng_adminGod) && p.ng_adminGod;
        case "Toggle Forge Mode": return isDefined(self.forgeOn) && self.forgeOn;
        case "Phase Through Surfaces": case "Noclip": case "UFO Mode": return isDefined(self.newufo);
        case "Toggle Script Barriers": return level.ng_barriersOff;
        case "Wii Graphics": return isDefined(self.ng_wii) && self.ng_wii;
        case "Spiral Bullet Tracers": return isDefined(self.ng_spiral) && self.ng_spiral;
        case "Shoot Care Packages": return isDefined(self.shootCarePackages) && self.shootCarePackages;
        case "Explosive Bullets": return isDefined(self.nukeBulletsTog) && self.nukeBulletsTog;
        case "Freeze All": return isDefined(self.ng_freeze) && self.ng_freeze;
        case "3rd Person": return isDefined(self.togThird) && self.togThird;
    }
    return undefined;
}

back()
{
    self.ng_pendingChange=undefined;
    if(!isDefined(self.ng_history) || self.ng_history.size==0)
    { self common_scripts\jellymod::closeModMenu(); return; }
    n=self.ng_history.size-1; page=self.ng_history[n];
    stack=[];
    for(i=0;i<n;i++) stack[i]=self.ng_history[i];
    self.ng_history=stack; self.ng_goingBack=true; self.ng_backCursor=page.cursor;
    self common_scripts\jellymod::changeMenu(page.id,page.title,page.options);
}
