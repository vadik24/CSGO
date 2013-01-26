/**
* File: War3Source_DemonHunter.sp
* Description: The Demon Hunter race for War3Source.
* Author(s): Cereal Killer + Anthony Iacono 
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
	name = "War3Source Race - Demon Hunter",
	author = "Cereal Killer",
	description = "Demon Hunter for War3Source.",
	version = "1.0.6.3",
	url = "http://warcraft-source.net/"
};
new SKILL_MANABURN, SKILL_IMMOLATION, SKILL_EVADE, ULT_META;
new Float:EvadeChance[6]={0.0,0.05,0.10,0.15,0.20,0.25};
new ManaMoney[6]={0,400,800,1200,1600,2000};
new Isimmolation[66];
new Ismeta[66];
new firedamage[6]={0,1,1,2,3,4};
new Float:ManaBurnChance[6]={0.0,0.10,0.20,0.30,0.40,0.50};
new BurnSprite, g_iExplosionModel;
new metamaxhp[6]={0,10,20,30,40,50};
new oldhealth[66];


public OnPluginStart()
{
	LoadTranslations("w3s.race.dhunter.phrases");
	
	CreateTimer(1.0,selfburnloop,_,TIMER_REPEAT);
	CreateTimer(0.1,heataoe,_,TIMER_REPEAT);
}
public OnMapStart()
{
	BurnSprite = PrecacheModel("materials/sprites/fire1.vmt");
	g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
}
public OnWar3EventSpawn(client)
{
	Isimmolation[client]=0;
	Ismeta[client]=0;
	W3ResetAllBuffRace(client,thisRaceID);
	W3ResetPlayerColor(client,thisRaceID);
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==310)
	{
		thisRaceID=War3_CreateNewRaceT("dhunter");
		SKILL_MANABURN=War3_AddRaceSkillT(thisRaceID,"ManaBurn",false,5);
		SKILL_IMMOLATION=War3_AddRaceSkillT(thisRaceID,"Immolation",false,5);
		SKILL_EVADE=War3_AddRaceSkillT(thisRaceID,"Evasion",false,5);
		ULT_META=War3_AddRaceSkillT(thisRaceID,"Metamorphosis",true,5);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
	W3ResetAllBuffRace(client,thisRaceID);
	}
	
}
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new race_victim=War3_GetRace(victim);
			new skill_level_evasion=War3_GetSkillLevel(victim,thisRaceID,SKILL_EVADE);
			if(race_victim==thisRaceID && skill_level_evasion>0 ) 
			{
				if(GetRandomFloat(0.0,1.0)<=EvadeChance[skill_level_evasion] && !W3HasImmunity(attacker,Immunity_Skills))
				{
					War3_DamageModPercent(0.0);
				}
			}
			new skill_level_mana=War3_GetSkillLevel(attacker,thisRaceID,SKILL_MANABURN);
			if(race_attacker==thisRaceID && skill_level_mana>0 ) 
			{
				if(!W3HasImmunity(victim,Immunity_Skills) && !Silenced(attacker) && GetRandomFloat(0.0,1.0)<=ManaBurnChance[skill_level_mana])
				{
					new Float:position[3];
					new Float:positionclient[3];
					GetClientAbsOrigin(victim,position);
					GetClientAbsOrigin(attacker,positionclient);
					position[2]+=35;
					positionclient[2]+=35;
					TE_SetupBeamPoints(position, positionclient,BurnSprite, 0 , 0, 8, 0.5, 10.0, 10.0, 10, 20.0, {255,0,255,255}, 70); 
					TE_SendToAll();
					if(GetCSMoney(victim)>0)
					{
						if(GetCSMoney(victim)>ManaMoney[skill_level_mana])
						{
							SetCSMoney(victim, GetCSMoney(victim)-ManaMoney[skill_level_mana]);
							War3_DamageModPercent(1.1);
						}
						else 
						{
							SetCSMoney(victim,0);
						}
					}
					if (GetCSMoney(victim)==0)
					{
						War3_DamageModPercent(3.0);
					}
					/*else
					{
						SetCSMoney(victim,0);
					}*/
				}
			}
		}
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	//if (ability==0){
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
			new skill_level_immolation=War3_GetSkillLevel(client,thisRaceID,SKILL_IMMOLATION);
			if(skill_level_immolation>0){
				if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_IMMOLATION,false)){
					War3_CooldownMGR(client,1.0,thisRaceID,SKILL_IMMOLATION);
					if(Isimmolation[client]==0){
						Isimmolation[client]=1;
						PrintHintText(client, "%T", "Immolation: ON", client);
					}
					else {
						Isimmolation[client]=0;
						PrintHintText(client, "%T", "Immolation: OFF", client);
					}
				}
			}
		}
	//}
}
public Action:selfburnloop(Handle:timer,any:a)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true) &&War3_GetRace(i)==thisRaceID)
		{
			new skill_level_immolation=War3_GetSkillLevel(i,thisRaceID,SKILL_IMMOLATION);
			if(skill_level_immolation>0)
			{
				if(Isimmolation[i]==1)
				{
					IgniteEntity(i,1.5);
					SetCSMoney(i, GetCSMoney(i)+200);
				}
			}
		}
	}
}
public Action:heataoe(Handle:timer,any:a)
{
	for(new i=1;i<=MaxClients;i++)
	{
		new irace=War3_GetRace(i);
		if(ValidPlayer(i,true))
		{
			if(irace==thisRaceID)
			{
				new skill_level_immolation=War3_GetSkillLevel(i,thisRaceID,SKILL_IMMOLATION);
				if(skill_level_immolation>0)
				{
					for(new x=1;x<=MaxClients;x++)
					{
						if(ValidPlayer(x,true)&&x!=i)
						{
							new iteam=GetClientTeam(i);
							new xteam=GetClientTeam(x);
							if(iteam!=xteam){
								new Float:positioni[3];
								War3_CachedPosition(i,positioni);
								new Float:positionx[3];
								War3_CachedPosition(x,positionx);
								if(Isimmolation[i]==1)
								{
									positioni[2]+=5;
									TE_SetupBeamRingPoint(positioni, 150.0, 200.0, BurnSprite, g_iExplosionModel,0,15,0.2,5.0,3.0,{255,200,200,255},10,0);
									TE_SendToAll();
									if(!W3HasImmunity(i,Immunity_Skills))
									{
										if(GetVectorDistance(positioni,positionx)<160)
										{
											IgniteEntity(x,2.0);
											War3_DealDamage(x,firedamage[skill_level_immolation],i,DMG_BURN,"fire",_,W3DMGTYPE_MAGIC);
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
}

public Action:shield(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		if(GetCSMoney(client)>200)
		{
			if(Ismeta[client]==1)
			{
				SetCSMoney(client, GetCSMoney(client)-100);
				CreateTimer(0.1,shield,client);
				if(GetCSMoney(client)<250)
				{
					if(Ismeta[client]==1)
					{
						CreateTimer(0.1,shield1,client);
					}
				}
			}
		}
	}
}
public Action:shield1(Handle:timer,any:client)
{
	Ismeta[client]=0;
	War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
	SetEntityHealth(client, oldhealth[client]);
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);	
	PrintHintText(client, "%T", "Metamorphosis is over", client);
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && IsPlayerAlive(client) && pressed){
		new ult_level_meta=War3_GetSkillLevel(client,race,ULT_META);
		if(ult_level_meta>0){
			if(!Silenced(client)){
				if(War3_SkillNotInCooldown(client,thisRaceID,ULT_META,false)){	
					War3_CooldownMGR(client,20.0,thisRaceID,ULT_META);
					if(GetCSMoney(client)>2000){
						if(Ismeta[client]==0){
							oldhealth[client]=GetClientHealth(client);
							Ismeta[client]=1;
							War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,metamaxhp[ult_level_meta]);
							SetEntityHealth(client, War3_GetMaxHP(client));
							War3_SetBuff(client,fMaxSpeed,thisRaceID,2.0);
							CreateTimer(0.1,shield,client);
							PrintHintText(client, "%T", "Metamorphosis: ACTIVATED", client);
						}
						else {
							PrintHintText(client, "%T", "Wait until Metamorphosis is over", client);
						}
					}
					else {
						PrintHintText(client, "%T", "Not enough Mana", client);
					}
				}
			}
		}
	}
}




