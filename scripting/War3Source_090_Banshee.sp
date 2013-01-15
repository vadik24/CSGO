/**
* File: War3Source_Banshee.sp
* Description: The Banshee race for War3Source.
* Author(s): Cereal Killer, Lucky
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
	name = "War3Source Race - Banshee",
	author = "Cereal Killer and Lucky",
	description = "Banshee for War3Source.",
	version = "1.0.6.3",
	url = "http://warcraft-source.net/"
};
new CURSE, AMS, TRAINING, POSSESS;

//Training
new TRA_regen[6]={0,1,2,3,4,5};
new maxhp1[6]={0,28,31,34,37,40};
//Anti Magic Shell
new Float:AMScooldown[7]={0.0,10.0,9.0,8.0,7.0,6.0};
//Curse
new bool:bCursed[MAXPLAYERS];
new Float:CurseChance[6]={0.0,0.20,0.22,0.24,0.26,0.28};
new bool:bisCursed[MAXPLAYERS];
//Possession
new bool:bPossessed[MAXPLAYERS];
new bool:bPossess[MAXPLAYERS];
new PossessDamage[6]={0,5,6,7,8,10};
new bPossessDamage[MAXPLAYERS];
new bool:bPossession[MAXPLAYERS][MAXPLAYERS];
new PossessedBy[MAXPLAYERS];
new String:NewModel[MAXPLAYERS][256];
new Float:PossessRange[6]={0.0,250.0,300.0,350.0,400.0,450.0};
new PossessedTime[MAXPLAYERS];

new ShieldSprite;
new BeamSprite,HaloSprite;
new String:AMS_sound[]="war3source/banshee/ams.mp3";
new String:curse_sound[]="war3source/banshee/curse.mp3";
new String:possess_sound[]="war3source/banshee/possession.mp3";

public OnPluginStart()
{
		CreateTimer(3.0,CalcHexHeales,_,TIMER_REPEAT);
		CreateTimer(1.0,PossessLoop,_,TIMER_REPEAT);
		LoadTranslations("w3s.race.banshee.phrases");
}

public OnMapStart()
{
	ShieldSprite=PrecacheModel("sprites/strider_blackball.vmt");
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	//War3_PrecacheSound(AMS_sound);
	//War3_PrecacheSound(curse_sound);
	//War3_PrecacheSound(possess_sound);
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==150)
	{
		thisRaceID=War3_CreateNewRaceT("banshee");
		CURSE=War3_AddRaceSkillT(thisRaceID,"1",false,5);
		AMS=War3_AddRaceSkillT(thisRaceID,"2",false,5);
		TRAINING=War3_AddRaceSkillT(thisRaceID,"3",false,5);
		POSSESS=War3_AddRaceSkillT(thisRaceID,"4",true,5);
		War3_CreateRaceEnd(thisRaceID);
	}
}
public Action:CalcHexHeales(Handle:timer,any:userid)
{
	if(thisRaceID>0){
		for(new i=1;i<=MaxClients;i++){
			if(ValidPlayer(i,true)){
				if(War3_GetRace(i)==thisRaceID){
					Regen(i); //check leves later
				}
			}
		}
	}
}
public Regen(client)
{
	new skill = War3_GetSkillLevel(client,thisRaceID,TRAINING);
	if(skill>0){
		if(ValidPlayer(client,true)){
			War3_HealToMaxHP(client,TRA_regen[skill]);
		}
	}
}

public OnWar3EventSpawn(client)
{
	for(new x=1;x<=MaxClients;x++){
		bPossession[client][x]=false;
	}
	bPossessed[client]=false;
	bisCursed[client]=false;
	bCursed[client]=false;
	PossessedTime[client]=0;
	if(War3_GetRace(client)==thisRaceID){
		if(ValidPlayer(client,true))
		{
			bPossess[client]=false;
			setbuffs(client);
		}
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
	}
	
	if(newrace == thisRaceID)
	{
		if(ValidPlayer(client,true))
		{
			setbuffs(client);
		}
	}
}

public setbuffs(client)
{
	new skill=War3_GetSkillLevel(client,thisRaceID,TRAINING);
	if(ValidPlayer(client,true,true))
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,maxhp1[skill]); //War3_SetMaxHP(client,War3_GetMaxHP(client)+maxhp1[skill]);
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam){
			new race_attacker=War3_GetRace(attacker);
			new skill_c=War3_GetSkillLevel(attacker,thisRaceID,CURSE);
			if(race_attacker==thisRaceID && skill_c>0 && !Silenced(attacker))
			{
				if(GetRandomFloat(0.0,1.0)<=CurseChance[skill_c] && !W3HasImmunity(victim,Immunity_Skills) && !bisCursed[victim])
				{
					bisCursed[victim]=true;
					bCursed[victim]=true;
					War3_SetBuff(victim,bHexed,thisRaceID,true);
					PrintHintText(victim,"%T","You've been cursed",victim);
					PrintHintText(attacker,"%T","You curse your enemy",attacker);
					CreateTimer(6.0, Curse, victim);
					
					new Float:pos[3]; 
					GetClientAbsOrigin(attacker,pos);
					pos[2]+=30;
					new Float:targpos[3];
					GetClientAbsOrigin(victim,targpos);
					targpos[2]+=30;
					TE_SetupBeamPoints(pos, targpos, HaloSprite, HaloSprite, 0, 8, 0.8, 2.0, 10.0, 10, 10.0, {125,0,255,100}, 70); 
					TE_SendToAll();
					
					EmitSoundToAll(curse_sound,attacker);
					EmitSoundToAll(curse_sound,victim);
				}
			}
			if(bCursed[attacker])
			{
				if(GetRandomFloat(0.0,1.0)<=0.33)
				{
					PrintHintText(attacker,"%T","You are cursed and miss",attacker);
					War3_DamageModPercent(0.0);
				}
			}
		}
	}
}

public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam){
			new race_victim=War3_GetRace(victim);
			new skill=War3_GetSkillLevel(victim,thisRaceID,AMS);
			if(race_victim==thisRaceID && skill>0)
			{
				if(War3_SkillNotInCooldown(victim,thisRaceID,AMS))
				{
					War3_CooldownMGR(victim,AMScooldown[skill],thisRaceID,AMS);
					War3_DamageModPercent(0.0);
					PrintCenterText(victim,"%T","Anti Magic Shell",victim);
					PrintCenterText(attacker,"%T","Anti Magic Shell blocks your attack",attacker);
					new Float:pos[3];
					GetClientAbsOrigin(victim,pos);
					pos[2]+=35;
					TE_SetupGlowSprite(pos, ShieldSprite, 0.1, 1.0, 130);
					TE_SendToAll(); 
					EmitSoundToAll(AMS_sound,attacker);
					EmitSoundToAll(AMS_sound,victim);
				}
				
			}
			if(race_victim==thisRaceID && bPossess[victim])
			{
				War3_DamageModPercent(1.66);
				War3_SetBuff(victim,bStunned,thisRaceID,false);
				bPossess[victim]=false;
				for(new x=1;x<=MaxClients;x++){
					if(ValidPlayer(x,true)&&bPossession[victim][x])
					{
						bPossession[victim][x]=false;
						War3_SetBuff(x,bStunned,thisRaceID,false);
						War3_SetBuff(bPossession[victim][x],bStunned,thisRaceID,false);
						bPossessed[x]=false;
					}
			
				}
				PrintHintText(victim,"%T","Channeling interupted",victim);
			}
		}
		
	}
	
}
public Action:Curse(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		bisCursed[client]=false;
		bCursed[client]=false;
		War3_SetBuff(client,bHexed,thisRaceID,false);
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true)){
		new skill_training=War3_GetSkillLevel(client,thisRaceID,TRAINING);
		new ult_possess=War3_GetSkillLevel(client,thisRaceID,POSSESS);
		if(ult_possess>0)
		{
			if(skill_training>0)
			{
				if(!Silenced(client))
				{
					if(War3_SkillNotInCooldown(client,thisRaceID,POSSESS,true))
					{
						new target = War3_GetTargetInViewCone(client,PossessRange[ult_possess],false,8.0);
						if(target>0 && !W3HasImmunity(target,Immunity_Ultimates))
						{
							new victimTeam=GetClientTeam(target);
							new playersAliveSameTeam;
							for(new i=1;i<=MaxClients;i++)
							{
								if(i!=target&&ValidPlayer(i,true)&&GetClientTeam(i)==victimTeam)
								{
									playersAliveSameTeam++;
								}
							}
							if(playersAliveSameTeam>0)
							{
								War3_SetBuff(target,bStunned,thisRaceID,true);
								War3_SetBuff(client,bStunned,thisRaceID,true);
								bPossessed[target]=true;
								bPossess[client]=true;
								bPossession[client][target]=true;
								PossessedBy[target]=client;
								bPossessDamage[target]=PossessDamage[ult_possess];
								new Float:pos[3];
								GetClientAbsOrigin(client,pos);
								pos[2]+=15;
								new Float:tarpos[3];
								GetClientAbsOrigin(target,tarpos);
								tarpos[2]+=15;
								TE_SetupBeamRingPoint(pos, 1.0, 350.0, BeamSprite, HaloSprite, 0, 5, 1.0, 50.0, 1.0, {84,84,84,255}, 50, 0);
								TE_SendToAll();
								TE_SetupBeamRingPoint(tarpos, 1.0, 350.0, BeamSprite, HaloSprite, 0, 5, 1.0, 50.0, 1.0, {84,84,84,255}, 50, 0);
								TE_SendToAll();
								EmitSoundToAll(possess_sound,target);
								EmitSoundToAll(possess_sound,client);
							}
							else
							{
								PrintHintText(client,"%T","Target is last person alive, cannot be possessed",client);
							}
						}
						else
						{
							W3MsgNoTargetFound(client, PossessRange[ult_possess]);
						}
					}
					
				}
				else
				{
					PrintHintText(client,"%T","Silenced: Can Not Cast",client); 
				}
				
			}
			else
			{
				PrintHintText(client,"%T","You need more training",client);
			}
			
		}
		else
		{
			W3MsgUltNotLeveled(client); //PrintHintText(client,"%T","Level Your Ultimate First",client);
		}	
		
	}
	
}

public Action:PossessLoop(Handle:timer,any:userid)
{
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true)){
			if(War3_GetRace(i)==thisRaceID){
				for(new x=1;x<=MaxClients;x++){
					if(ValidPlayer(x,true)&&bPossession[i][x]){
						if(PossessedTime[x]<4){
							new Float:pos[3];
							GetClientAbsOrigin(i,pos);
							pos[2]+=15;
							new Float:tarpos[3];
							GetClientAbsOrigin(x,tarpos);
							tarpos[2]+=15;
							TE_SetupBeamRingPoint(pos, 1.0, 350.0, BeamSprite, HaloSprite, 0, 5, 1.0, 50.0, 1.0, {84,84,84,255}, 50, 0);
							TE_SendToAll();
							TE_SetupBeamRingPoint(tarpos, 1.0, 350.0, BeamSprite, HaloSprite, 0, 5, 1.0, 50.0, 1.0, {84,84,84,255}, 50, 0);
							TE_SendToAll();
							PossessedTime[x]++;
						}
						else
						{
							War3_DealDamage(x,900,i,DMG_BULLET,"Possession");
						}
						
					}
					
				}
				
			}
			
		}
		
	}
	
}

public OnWar3EventDeath(victim,attacker)
{
	new race_victim=War3_GetRace(victim);
	new race_attacker=War3_GetRace(attacker);
	
	if(race_victim==thisRaceID){
		War3_SetBuff(victim,bStunned,thisRaceID,false);
		bPossess[victim]=false;
		for(new x=1;x<=MaxClients;x++)
		{
			War3_SetBuff(bPossession[victim][x],bStunned,thisRaceID,false);
			if(ValidPlayer(x,true)&&bPossession[victim][x])
			{
				bPossession[victim][x]=false;
				War3_SetBuff(bPossession[victim][x],bStunned,thisRaceID,false);
				War3_SetBuff(x,bStunned,thisRaceID,false);
				bPossessed[x]=false;
			}
			
		}
		
	}
	
	if(bPossessed[victim]&&race_attacker==thisRaceID&&bPossession[attacker][victim]){
		GetClientModel(victim, NewModel[attacker], 256);
		SetEntityModel(attacker, NewModel[attacker]);
		War3_SetBuff(attacker,bStunned,thisRaceID,false);
		bPossess[attacker]=false;
		bPossession[attacker][victim]=false;
		War3_SetBuff(victim,bStunned,thisRaceID,false);
		bPossessed[victim]=false;
		War3_CooldownMGR(attacker,60.0,thisRaceID,POSSESS);
	}
	else
	{
		if(bPossessed[victim]){
			War3_SetBuff(PossessedBy[victim],bStunned,thisRaceID,false);
			bPossess[PossessedBy[victim]]=false;
			bPossession[PossessedBy[victim]][victim]=false;
			War3_SetBuff(victim,bStunned,thisRaceID,false);
			bPossessed[victim]=false;
			War3_CooldownMGR(PossessedBy[victim],60.0,thisRaceID,POSSESS);
		}
		
	}
	
}