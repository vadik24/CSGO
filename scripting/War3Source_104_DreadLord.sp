/**
* File: War3Source_DreadLord.sp
* Description: The Dread Lord race for War3Source.
* Author(s): Cereal Killer 
*/
#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>
 
public Plugin:myinfo = 
{
        name = "War3Source Race - Dread Lord",
        author = "Cereal Killer",
        description = "Dread Lord for War3Source.",
        version = "1.0.6.3",
        url = "http://warcraft-source.net/"
}
 
new thisRaceID;
new MyWeaponsOffset,ClipOffset, Clip2Offset,AmmoOffset;
new m_vecBaseVelocity;
 
//Carrion Swarm
new Float:BatChance[6]={0.0,0.25,0.3,0.35,0.38,0.3};
new Float:batdmg[6]={1.0,1.10,1.20,1.30,1.35,1.4};
 
//Sleep
new Float:sleepcool[6]={0.0,40.0,35.0,30.0,25.0,20.0};
new bool:bIsSleeping[MAXPLAYERS];
new Float:sleeptime[6]={0.0,0.5,0.7,0.9,1.2,1.5};
 
//Vampiric Aura
new aurahealz[6]={0,12,10,8,7,6};
new auraammo[6]={0,4,5,6,8,10};
 
//Inferno
new Float:infernocool[6]={0.0,40.0,35.0,30.0,25.0,20.0};
new quakedamage[6]={0,10,15,20,25,30};
new explosiondamage[6]={0,30,35,40,45,50};
new Float:FireTime[]={0.0,2.0,2.5,3.0,3.5,4.0};
new FireDmg[]={0,12,15,18,21,24};
 
new BeamSprite,HaloSprite;
new g_iExplosionModel,g_iSmokeModel;
 
//SKILLS and ULTIMATE
new BATSWARM, SLEEPSKILL, AURASKILL, INFERNOUTIL;
 
public OnPluginStart(){
        MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
        ClipOffset=FindSendPropOffs("CBaseCombatWeapon","m_iClip1");
        Clip2Offset=FindSendPropOffs("CBaseCombatWeapon","m_iClip2");
        AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
        m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
}
 
stock SetWeaponAmmo(client, slot, ammo)
{
    return SetEntData(client, AmmoOffset+(slot*4), ammo);
}
 
public OnMapStart(){ 
        BeamSprite=War3_PrecacheBeamSprite();
        HaloSprite=War3_PrecacheHaloSprite();
        g_iExplosionModel=PrecacheModel("materials/effects/fire_cloud1.vmt");
        g_iSmokeModel=PrecacheModel("materials/effects/fire_cloud2.vmt");  
}
 
public OnWar3LoadRaceOrItemOrdered(num){
        if(num==000)
        {
                thisRaceID=War3_CreateNewRace("Dread Lord","dread");
                BATSWARM=War3_AddRaceSkill(thisRaceID,"Carrion Swarm (Passive)","extra damage",false,5);
                SLEEPSKILL=War3_AddRaceSkill(thisRaceID,"Sleep (Ability)","Puts target to sleep",false,5);
                AURASKILL=War3_AddRaceSkill(thisRaceID,"Vampiric Aura (Passive)","Gain hp from others suffering",false,5);
                INFERNOUTIL=War3_AddRaceSkill(thisRaceID,"Inferno (Ultimate)","Put target in an inferno (FIRE STORM, EARTHQUAKE, TORNADO or EXPLOSION)",true,5);
                War3_CreateRaceEnd(thisRaceID);
        }
}
 
public OnRaceChanged(client, oldrace, newrace)
{
        if(newrace != thisRaceID)
        {
                War3_WeaponRestrictTo(client,thisRaceID,"");
				W3ResetAllBuffRace(client,thisRaceID);
        }
        
        if(newrace == thisRaceID)
        {
                War3_WeaponRestrictTo(client,thisRaceID,"weapon_m3");
                if(ValidPlayer(client,true))
                {
                        GivePlayerItem(client,"weapon_m3");
                        CreateTimer(5.0, Getammo, client);
                }
        }
}
 
public OnWar3EventDeath(victim,attacker)
{
        new race_victim=War3_GetRace(victim);
        
        if(race_victim==thisRaceID) {
                for(new s=0;s<10;s++){
                        new ent=GetEntDataEnt2(attacker,MyWeaponsOffset+(s*4));
                        
                        if(ent>0 && IsValidEdict(ent)){
                                new String:ename[64];
                                GetEdictClassname(ent,ename,64);
                                if(StrEqual(ename,"weapon_m3") ){
                                        SetEntData(ent,ClipOffset,8,4);
                                        SetWeaponAmmo(victim, 7, 0);
                                        SetEntData(victim,AmmoOffset+(s*4),32,4);
                                }
                        }
                }
        }
}       
 
public Action:Getammo(Handle:timer,any:attacker)
{
        if(ValidPlayer(attacker,true)){
                for(new s=0;s<10;s++){
                        new ent=GetEntDataEnt2(attacker,MyWeaponsOffset+(s*4));
                        
                        if(ent>0 && IsValidEdict(ent)){
                                new String:ename[64];
                                
                                GetEdictClassname(ent,ename,64);
                                if(StrEqual(ename,"weapon_m3") ){
                                        SetEntData(ent,ClipOffset,30,4);
                                        SetEntData(ent,Clip2Offset,0,4);
                                        SetWeaponAmmo(attacker, 7, 0);
                                        SetEntData(attacker,AmmoOffset+(s*4),0,4);
                                }
                        }
                }
        }
}
 
public OnWar3EventSpawn(client)
{
        bIsSleeping[client]=false;
        if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true)){
                War3_WeaponRestrictTo(client,thisRaceID,"weapon_m3");
                new wep_ent=GivePlayerItem(client,"weapon_m3");
                if(wep_ent>0){
                        CreateTimer(5.0, Getammo, client);
                        for(new s=7;s<8;s++)
                        {
                                SetEntData(client,AmmoOffset+(s*4),0,4);
                        }
                }
        }
}
 
public OnAbilityCommand(client,ability,bool:pressed)
{       
        if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
                if(!Silenced(client)){
                        new skill_level=War3_GetSkillLevel(client,thisRaceID,SLEEPSKILL);
                        
                        if(skill_level>0){
                                if(War3_SkillNotInCooldown(client,thisRaceID,SLEEPSKILL,true)){
                                        new target = War3_GetTargetInViewCone(client,1000.0,false,15.0);
                                        
                                        if(target>0){
                                                War3_SetBuff(target,bStunned,thisRaceID,true);
                                                CreateTimer(sleeptime[skill_level], unSleep, target);
                                                bIsSleeping[target]=true;
                                                new Float:iPosition[3];
                                                new Float:clientPosition[3];
                                                GetClientAbsOrigin(client, clientPosition);
                                                GetClientAbsOrigin(target, iPosition);
                                                iPosition[2]+=35;
                                                clientPosition[2]+=35;
                                                TE_SetupBeamPoints(iPosition,clientPosition,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,{75,150,0,205},20);
                                                TE_SendToAll();
                                                War3_CooldownMGR(client,sleepcool[skill_level],thisRaceID,SLEEPSKILL,_,_);
                                                W3FlashScreen(target,{255,255,255,255},0.1,2.0,FFADE_OUT);
                                        }
                                        else
                                        {
                                                PrintHintText(client,"NO VALID TARGETS");
                                        }
                                }
                        }
                        else
                        {
                                PrintHintText(client, "Level sleep first");
                        }
                }
                else
                {
                        PrintHintText(client, "Silenced!");
                }
        } 
}
 
public Action:unSleep(Handle:timer,any:victim)
{
        War3_SetBuff(victim,bStunned,thisRaceID,false);
        bIsSleeping[victim]=false;
}
 
public Action:SlowUp2(Handle:timer,any:client)
{
        War3_SetBuff(client,fSlow,thisRaceID,1.0);
}
 
public Action:Tornado1(Handle:timer,any:client)
{
        new Float:velocity[3];
        
        velocity[2]+=4.0;
        velocity[0]-=600.0;
        SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}
 
public Action:Tornado2(Handle:timer,any:client)
{
        new Float:velocity[3];
        
        velocity[2]+=4.0;
        velocity[0]+=600.0;
        SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}
 
public OnUltimateCommand(client,race,bool:pressed){
    if(race==thisRaceID && IsPlayerAlive(client) && pressed){
        if(!Silenced(client)){
                        new skill_level=War3_GetSkillLevel(client,race,INFERNOUTIL);
                        
                        if(skill_level>0){
                                if(War3_SkillNotInCooldown(client,thisRaceID,INFERNOUTIL,true)){
                                        new target = War3_GetTargetInViewCone(client,1000.0,false,15.0);
                                
                                        if(target>0 && !W3HasImmunity(target,Immunity_Ultimates)){
                                                new randnumber=GetRandomInt(0,3);
                                                
                                                if(randnumber==0){
                                                        PrintHintText(client,"FIRE STORM");
                                                        PrintHintText(target,"FIRE STORM");
                                                        IgniteEntity(target, FireTime[skill_level]);
                                                        War3_DealDamage(target,FireDmg[skill_level],client,DMG_BURN,"fire storm",_,W3DMGTYPE_MAGIC);
                                                }
                                                if(randnumber==1) {
                                                        PrintHintText(client,"EARTHQUAKE");
                                                        PrintHintText(target,"EARTHQUAKE");
                                                        War3_ShakeScreen(target,3.0,50.0,40.0);
                                                        War3_DealDamage(target,quakedamage[skill_level],client,DMG_CRUSH,"earthquake",_,W3DMGTYPE_MAGIC);
                                                        CreateTimer(1.0,SlowUp2,target);
                                                        War3_SetBuff(target,fSlow,thisRaceID,0.5);
                                                }
                                                if(randnumber==2){
                                                        PrintHintText(client,"EXPLOSION");
                                                        PrintHintText(target,"EXPLOSION");
                                                        War3_DealDamage(target,explosiondamage[skill_level],client,DMG_BURN,"Explosion",_,W3DMGTYPE_MAGIC);
                                                        new Float:targetpos[3];
                                                        GetClientAbsOrigin(target,targetpos);
                                                        TE_SetupExplosion(targetpos,g_iExplosionModel,10.0,10,TE_EXPLFLAG_NONE,200,255);
                                                        TE_SendToAll();
                                                        TE_SetupSmoke(targetpos,g_iExplosionModel,50.0,2);
                                                        TE_SendToAll();
                                                        TE_SetupSmoke(targetpos,g_iSmokeModel,50.0,2);
                                                        TE_SendToAll();
                                                }
                                                if(randnumber==3){
                                                        PrintHintText(client,"TORNADO");
                                                        PrintHintText(target,"TORNADO");
                                                        new Float:position[3];
                                                        new Float:velocity[3];
                                                        velocity[2]+=1000.0;
                                                        SetEntDataVector(target,m_vecBaseVelocity,velocity,true);
                                                        CreateTimer(0.1,Tornado1,target);
                                                        CreateTimer(0.4,Tornado2,target);
                                                        GetClientAbsOrigin(client,position);
                                                        TE_SetupBeamRingPoint(position, 20.0, 80.0,BeamSprite,BeamSprite, 0, 5, 2.6, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
                                                        TE_SendToAll();
                                                        position[2]+=20.0;
                                                        TE_SetupBeamRingPoint(position, 40.0, 100.0,BeamSprite,BeamSprite, 0, 5, 2.4, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
                                                        TE_SendToAll();
                                                        position[2]+=20.0;
                                                        TE_SetupBeamRingPoint(position, 60.0, 120.0,BeamSprite,BeamSprite, 0, 5, 2.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
                                                        TE_SendToAll();
                                                        position[2]+=20.0;
                                                        TE_SetupBeamRingPoint(position, 80.0, 140.0,BeamSprite,BeamSprite, 0, 5, 2.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
                                                        TE_SendToAll(); 
                                                        position[2]+=20.0;
                                                        TE_SetupBeamRingPoint(position, 100.0, 160.0,BeamSprite,BeamSprite, 0, 5, 1.8, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
                                                        TE_SendToAll(); 
                                                        position[2]+=20.0;
                                                        TE_SetupBeamRingPoint(position, 120.0, 180.0,BeamSprite,BeamSprite, 0, 5, 1.6, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
                                                        TE_SendToAll(); 
                                                        position[2]+=20.0;
                                                        TE_SetupBeamRingPoint(position, 140.0, 200.0,BeamSprite,BeamSprite, 0, 5, 1.4, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
                                                        TE_SendToAll(); 
                                                        position[2]+=20.0;
                                                        TE_SetupBeamRingPoint(position, 160.0, 220.0,BeamSprite,BeamSprite, 0, 5, 1.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
                                                        TE_SendToAll(); 
                                                        position[2]+=20.0;
                                                        TE_SetupBeamRingPoint(position, 180.0, 240.0,BeamSprite,BeamSprite, 0, 5, 1.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
                                                        TE_SendToAll();
                                                }
                                                War3_CooldownMGR(client,infernocool[skill_level],thisRaceID,INFERNOUTIL,_,_);
                                        }
                                        else
                                        {
                                                PrintHintText(client, "No target");
                                        }
                }
                        }
                        else
                        {
                                PrintHintText(client, "Level inferno first");
                        }
                }
                else
                {
                        PrintHintText(client, "Silenced!");
                }
        }
}
 
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
        if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
                new vteam=GetClientTeam(victim);
                new ateam=GetClientTeam(attacker);
                
                if(vteam!=ateam){
                        new race_attacker=War3_GetRace(attacker);
                        new skill_level1=War3_GetSkillLevel(attacker,thisRaceID,BATSWARM);
                        new skill_level2=War3_GetSkillLevel(attacker,thisRaceID,AURASKILL);
                        
                        if(bIsSleeping[victim]==true){
                                War3_SetBuff(victim,bStunned,thisRaceID,false);
                                bIsSleeping[victim]=false;      
                        }
                        
                        if(race_attacker==thisRaceID){
                                if(GetRandomFloat(0.0,1.0)<=BatChance[skill_level1]&& skill_level1>0 ){
                                        War3_DamageModPercent(batdmg[skill_level1]);
                                        new Float:attpos[3];
                                        new Float:vicpos[3];
                                        GetClientAbsOrigin(attacker,attpos);
                                        GetClientAbsOrigin(victim,vicpos);
                                        vicpos[2]+=30;
                                        attpos[2]+=30;
                                        TE_SetupBeamPoints(attpos,vicpos,BeamSprite,HaloSprite,0,8,1.8,8.0,0.6,10,0.0,{55,55,55,55},70);
                                        TE_SendToAll();         
                                }
                                for(new s=0;s<10;s++){
                                        new ent=GetEntDataEnt2(attacker,MyWeaponsOffset+(s*4));
                                        if(ent>0 && IsValidEdict(ent)){
                                                new String:ename[64];
                                                GetEdictClassname(ent,ename,64);
                                                if(StrEqual(ename,"weapon_m3") ){
                                                        if(GetRandomFloat(0.0,1.0)<=0.25){
                                                                new clipold = FindDataMapOffs(ent,"m_iClip1");
                                                                SetEntData(ent,ClipOffset,clipold+auraammo[skill_level2],4);
                                                        }
                                                        if(GetClientHealth(attacker)<250){
                                                                new healback=RoundFloat((damage/aurahealz[skill_level2]));
                                                                SetEntityHealth(attacker,(GetClientHealth(attacker)+healback));
                                                        }
                                                }
                                        }
                                }
                        }
                }
        }
}