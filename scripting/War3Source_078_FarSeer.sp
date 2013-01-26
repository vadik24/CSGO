/**
* File: War3Source_FarSeer.sp
* Description: The Far Seer race for War3Source.
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
new thisRaceID;
public Plugin:myinfo = 
{
	name = "War3Source Race - Far Seer",
	author = "Cereal Killer",
	description = "Far Seer for War3Source.",
	version = "1.0.6.3",
	url = "http://warcraft-source.net/"
};
new FARSKILL, CHAINSKILL, FERALSKILL, QUAKEULTI;
new BeamSprite,HaloSprite;
new Float:farlife[6]={0.0,0.4,0.6,1.2,1.6,2.0};
new Float:farwidth[6]={0.0,1.0,2.0,3.0,4.0,5.0};
new Float:farradius[6]={0.0,200.0,250.0,350.0,400.0,500.0};
new Float:ChainChance[6]={0.0,0.01,0.03,0.05,0.08,0.1};
new Float:FeralChance[6]={0.0,0.3,0.35,0.4,0.45,0.5};
new Float:earthquakecool[6]={0.0,40.0,30.0,25.0,20.0,15.0};
new Float:FeralDamage[6]={0.0,1.1,1.15,1.2,1.25,1.3};
new String:reviveSound[]="war3source/reincarnation.mp3";
public OnPluginStart(){
	CreateTimer(5.0,far_sight,_,TIMER_REPEAT);
}
public OnMapStart(){
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	////War3_PrecacheSound(reviveSound);
}

public OnWar3LoadRaceOrItemOrdered2(num){
	if(num==150)
	{
		thisRaceID=War3_CreateNewRace("VIP Far Seer","seer");
		FARSKILL=War3_AddRaceSkill(thisRaceID,"Far Sight","Guides you to Enemies even thru walls",false,5);
		CHAINSKILL=War3_AddRaceSkill(thisRaceID,"Chain Lightning","Damages enemies around your victim (passif)",false,5);
		FERALSKILL=War3_AddRaceSkill(thisRaceID,"Feral Spirit","Slow and Damage",false,5);
		QUAKEULTI=War3_AddRaceSkill(thisRaceID,"Earthquake (+ultimate)","Shake enemy near you",true,5);
		War3_CreateRaceEnd(thisRaceID);
	}
}
public OnWar3EventSpawn(client){
}

public OnUltimateCommand(client,race,bool:pressed){
	if(race==thisRaceID && IsPlayerAlive(client) && pressed){
		new skill_level=War3_GetSkillLevel(client,race,QUAKEULTI);
		if(skill_level>0){
			if(!Silenced(client)){
				if(War3_SkillNotInCooldown(client,thisRaceID,QUAKEULTI,false)){
					War3_CooldownMGR(client,earthquakecool[skill_level],thisRaceID,QUAKEULTI);
					for(new i=1;i<=MaxClients;i++){
						if(ValidPlayer(i,true)&&War3_GetRace(i)!=thisRaceID){	 
							new clientteam=GetClientTeam(client);
							new iteam=GetClientTeam(i);
							if(iteam!=clientteam){
								new Float:iPosition[3];
								new Float:clientPosition[3];
								GetClientAbsOrigin(i, iPosition);
								GetClientAbsOrigin(client, clientPosition);
								if(!W3HasImmunity(i,Immunity_Skills)){
									if(GetVectorDistance(iPosition,clientPosition)<500){
										// earthquake!!!!!
										War3_ShakeScreen(i,3.0,50.0,40.0);
										War3_ShakeScreen(client,3.0,50.0,40.0);
										War3_DealDamage(i,GetRandomInt(30,60),client,DMG_CRUSH,"earthquake",_,W3DMGTYPE_MAGIC);
										TE_SetupBeamRingPoint(clientPosition,250.0,250.0,BeamSprite,HaloSprite,0,15,2.0,20.0,3.0,{255,0,0,255},20,0);
										TE_SendToAll();
										CreateTimer(0.5,SlowUp2,i);
										War3_SetBuff(i,fMaxSpeed,thisRaceID,0.3);
										W3SetPlayerColor(i,thisRaceID,151,105,79,_,0);
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
public Action:SlowUp2(Handle:timer,any:client) {
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	W3SetPlayerColor(client,thisRaceID,255,255,255,_,0);	
}				
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage){
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam) 
		{
			new race_attacker=War3_GetRace(attacker);
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,CHAINSKILL);
			if(race_attacker==thisRaceID && skill_level>0 ) {
				if(GetRandomFloat(0.0,1.0)<=ChainChance[skill_level] && !W3HasImmunity(attacker,Immunity_Skills)){
					for(new client1=1;client1<=MaxClients;client1++){
						new Float:iPosition[3];
						new Float:clientPosition[3];
						GetClientAbsOrigin(victim, iPosition);
						GetClientAbsOrigin(attacker, clientPosition);
						iPosition[2]+=35;
						clientPosition[2]+=35;
						War3_DamageModPercent(1.2);
						CreateTimer(0.1,Chainlight,victim);
						TE_SetupBeamPoints(iPosition,clientPosition,BeamSprite,HaloSprite,0,1,1.0,10.0,5.0,0,1.0,{100,150,75,255},50);
						TE_SendToAll();
					}
				}
			}
			new skill_level2=War3_GetSkillLevel(attacker,thisRaceID,FERALSKILL);
			if(race_attacker==thisRaceID && skill_level>0 ) {
				if(GetRandomFloat(0.0,1.0)<=FeralChance[skill_level2] && !W3HasImmunity(attacker,Immunity_Skills)){
					new Float:iPosition[3];
					new Float:clientPosition[3];
					GetClientAbsOrigin(victim, iPosition);
					GetClientAbsOrigin(attacker, clientPosition);
					iPosition[2]+=35;
					clientPosition[2]+=35;
					War3_DamageModPercent(FeralDamage[skill_level2]);
					CreateTimer(0.5,SlowUp,victim);
					TE_SetupBeamPoints(iPosition,clientPosition,BeamSprite,HaloSprite,0,1,1.0,10.0,5.0,0,1.0,{120,250,0,155},1);
					TE_SendToAll();
					War3_SetBuff(victim,fMaxSpeed,thisRaceID,0.3);
				}
			}
		}
	}
}
public Action:SlowUp(Handle:timer,any:client) {
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
}
public Action:Chainlight(Handle:timer,any:client) {
	for(new client1=1;client1<=MaxClients;client1++){
		if(ValidPlayer(client1,true)&&War3_GetRace(client1)==thisRaceID){
			for(new i=1;i<=MaxClients;i++){
				if(ValidPlayer(i,true)&&War3_GetRace(i)!=thisRaceID){	
					new clientteam=GetClientTeam(client);
					new iteam=GetClientTeam(i);
					if(iteam==clientteam){
						new Float:iPosition[3];
						new Float:clientPosition[3];
						GetClientAbsOrigin(i, iPosition);
						GetClientAbsOrigin(client, clientPosition);
						if(!W3HasImmunity(i,Immunity_Skills)){
							if(GetVectorDistance(iPosition,clientPosition)<300){
								iPosition[2]+=35;
								clientPosition[2]+=35;
								TE_SetupBeamPoints(iPosition,clientPosition,BeamSprite,HaloSprite,0,1,1.0,10.0,5.0,0,1.0,{100,150,75,255},50);
								TE_SendToAll();
								War3_DealDamage(i,30,client1,DMG_CRUSH,"chain lightning",_,W3DMGTYPE_MAGIC);
							}
						}
					}
				}
			}
		}
	}
}
public Action:far_sight(Handle:timer,any:a) {
	for(new client=1;client<=MaxClients;client++){
		if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID){
			for(new target=1;target<=MaxClients;target++){
				if(ValidPlayer(target,true)){
					new clientteam=GetClientTeam(client);	
					new targetteam=GetClientTeam(target);	
					if(clientteam!=targetteam ){
						new skill_level=War3_GetSkillLevel(client,thisRaceID,FARSKILL);
						if(skill_level>0){
							new Float:pos[3]; 
							GetClientAbsOrigin(client,pos);
							pos[2]+=30;
							new Float:targpos[3];
							GetClientAbsOrigin(target,targpos);
							if (targetteam==2){
								TE_SetupBeamPoints(pos, targpos, BeamSprite, HaloSprite, 0, 8, farlife[skill_level], farwidth[skill_level], 10.0, 10, 10.0, {255,0,0,155}, 70); 
								TE_SendToClient(client);
								targpos[2]+=10;
								TE_SetupBeamRingPoint(targpos,0.0,farradius[skill_level],BeamSprite,HaloSprite,0,15,1.0,20.0,3.0,{255,0,0,255},20,0);
								TE_SendToAll();
							}
							if (targetteam==3){
								TE_SetupBeamPoints(pos, targpos, BeamSprite, HaloSprite, 0, 8, farlife[skill_level], farwidth[skill_level], 10.0, 10, 10.0, {0,0,255,155}, 70); 
								TE_SendToClient(client);
								targpos[2]+=10;
								TE_SetupBeamRingPoint(targpos,0.0,farradius[skill_level],BeamSprite,HaloSprite,0,15,1.0,20.0,3.0,{0,0,255,255},20,0);
								TE_SendToAll();
							}
						}
					}
				}
			}
		}
	}
}