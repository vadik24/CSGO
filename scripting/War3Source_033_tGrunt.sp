/**
* File: War3Source_Grunt.sp
* Description: The Grunt race for War3Source.
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
	name = "War3Source Race - Grunt",
	author = "Cereal Killer",
	description = "Grunt for War3Source.",
	version = "1.0.7.3",
	url = "http://warcraft-source.net/"
};
new PILLAGE, BHP, BST, ARCENH;
new BerserkerHP[6]={0,20,30,40,50,60};
new BerserkerARMOR[6]={0,50,60,80,90,100};
new Float:bstdamage[6]={0.0,1.05,1.1,1.15,1.2,1.25};
new Float:Pillagechance[6]={0.0,0.6,0.7,0.8,0.9,1.0};
new Float:arcenhdistance[6]={0.0,200.0,250.0,300.0,350.0,400.0};
new Float:arcenhdamage[6]={0.0,1.05,1.1,1.15,1.20,1.25};
public OnPluginStart()
{
	LoadTranslations("w3s.race.grunt.phrases");
}
public OnMapStart()
{
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==192)
	{
		thisRaceID=War3_CreateNewRaceT("grunt");
		PILLAGE=War3_AddRaceSkillT(thisRaceID,"Pillage",false,5);
		BHP=War3_AddRaceSkillT(thisRaceID,"BerserkerHealth",false,5);
		BST=War3_AddRaceSkillT(thisRaceID,"BerserkerStrength",false,5);
		ARCENH=War3_AddRaceSkillT(thisRaceID,"ArcaniteEnhancement",true,5);
		War3_CreateRaceEnd(thisRaceID);
	}
}
public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true))
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_fiveseven");
		GivePlayerItem(client,"weapon_fiveseven");
		HPbonus(client);
	}
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	if(newrace==thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_fiveseven");
		if(ValidPlayer(client,true))
		{
			GivePlayerItem(client,"weapon_fiveseven");
			HPbonus(client);
		}
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
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,BST);
			//new level=War3_GetSkillLevel(attacker,thisRaceID,PILLAGE);
			if(race_attacker==thisRaceID && skill_level>0 ) 
			{
				if(!W3HasImmunity(victim,Immunity_Skills))
				{
					War3_DamageModPercent(bstdamage[skill_level]);
				}
			}
			/*
			if(race_attacker==thisRaceID && level>0 ) 
			{
				if(!W3HasImmunity(victim,Immunity_Skills))
				{
					if(GetRandomFloat(0.0,1.0)<=Pillagechance[level])
					{
						new gold=War3_GetGold(victim);
						if(gold>0)
						{
							War3_SetGold(victim,War3_GetGold(victim)-1);
							War3_SetGold(attacker,War3_GetGold(attacker)+1);
							PrintHintText(victim,"%T","Grunt stole some gold",victim);
							PrintHintText(attacker,"%T","Steal Gold",attacker);
						}
						else
						{
							PrintHintText(attacker,"%T","They have no gold",attacker);
						}
					}
				}
			}
			*/
			for(new i=0;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true)&&War3_GetRace(i)==thisRaceID)
				{
					new iteam=GetClientTeam(i);
					if(iteam==ateam)
					{
						if(i!=attacker)
						{
							new skilllevel=War3_GetSkillLevel(i,thisRaceID,ARCENH);
							if(skilllevel>0 )
							{
								if(!W3HasImmunity(victim,Immunity_Skills))
								{
									new Float:ipos[3];
									new Float:attpos[3];
									GetClientAbsOrigin(i,ipos);
									GetClientAbsOrigin(attacker, attpos);
									if(GetVectorDistance(ipos,attpos)<arcenhdistance[skilllevel])
									{
										War3_DamageModPercent(arcenhdamage[skilllevel]);
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


public OnWar3EventDeath(victim,attacker)
{
	if(ValidPlayer(victim)&&ValidPlayer(attacker,true) && attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new level=War3_GetSkillLevel(attacker,thisRaceID,PILLAGE);
			if(race_attacker==thisRaceID && level>0 ) 
			{
				if(!W3HasImmunity(victim,Immunity_Skills))
				{
					if(GetRandomFloat(0.0,1.0)<=Pillagechance[level])
					{
						new gold=War3_GetGold(victim);
						if(gold>0)
						{
							War3_SetGold(victim,War3_GetGold(victim)-1);
							War3_SetGold(attacker,War3_GetGold(attacker)+1);
							PrintHintText(victim,"%T","Grunt stole some gold",victim);
							PrintHintText(attacker,"%T","Steal Gold",attacker);
						}
						else
						{
							PrintHintText(attacker,"%T","They have no gold",attacker);
						}
					}
				}
			}
		}
	}
}


public HPbonus(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,BHP);
		if(skill_level>0)
		{
			new hpadd=BerserkerHP[skill_level];
			//SetEntityHealth(client,GetClientHealth(client)+hpadd);
			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,hpadd);
			new armoradd=BerserkerARMOR[skill_level];
			War3_SetCSArmor(client,armoradd);
		}
	}
}