/**
* File: War3Source_Priest.sp
* Description: The Priest race for War3Source.
* Author(s): TeacherCreature 
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
	name = "War3Source Race - Priest",
	author = "TeacherCreature",
	description = "Priest for War3Source.",
	version = "1.0.7",
	url = "http://warcraft-source.net/"
};
public OnPluginStart()
{
	CreateTimer(1.0,heals,_,TIMER_REPEAT);
}
//new GlowSprite;

public OnMapStart()
{
}

new SKILL_HEAL, SKILL_DISPEL, ULT_INNERFIRE, SKILL_TRAINING;

new DistCheck[7]={0,50,60,70,80,90,100};
new UltCheck[7]={0,50,60,70,80,90,100};
new regenarr[7]={0,1,2,3,4,5,6};
new bool:bRegen[66];
new bool:bInFire[66];
new bool:bDispel[66];
new Float:cool[7]={30.0, 20.0, 18.0, 16.0, 14.0, 12.0, 10.0};

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==179)
	{
		thisRaceID=War3_CreateNewRace("Priest","priest");
		SKILL_HEAL=War3_AddRaceSkill(thisRaceID,"Heal(autocast)","Heal nearby allies for 25 health",false,6);
		SKILL_DISPEL=War3_AddRaceSkill(thisRaceID,"Dispel(ability)","Remove all buffs and cause damage",false,6);
		SKILL_TRAINING=War3_AddRaceSkill(thisRaceID,"Master Training(passive)","More health, needed for innerfire",false,6);
		ULT_INNERFIRE=War3_AddRaceSkill(thisRaceID,"Inner Fire(autocast)","More damage and armor for nearby allies",true,6);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public Action:heals(Handle:timer,any:a)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID)
		{
			new skill3 = War3_GetSkillLevel(client, thisRaceID, SKILL_TRAINING);
			if(bRegen[client]&&skill3>0)
			{
				War3_HealToMaxHP(client,regenarr[skill3]);
			}
			new skill1 = War3_GetSkillLevel(client, thisRaceID, SKILL_HEAL);
			new skill4 = War3_GetSkillLevel(client, thisRaceID, ULT_INNERFIRE);
			for(new i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true)&&GetClientTeam(i)==GetClientTeam(client)&&i!=client)
				{
					new Float:vpos[3];
					GetClientAbsOrigin(i,vpos);
					new Float:apos[3];
					GetClientAbsOrigin(client,apos);
					new Float:distance=GetVectorDistance(apos,vpos);
					if(distance<DistCheck[skill1])
					{
						War3_HealToMaxHP(i,25);
					}
					if(distance<UltCheck[skill4]&&!bInFire[i])
					{
						bInFire[i]=true;
						CreateTimer(6.0,infire,i);
						PrintHintText(i,"Inner Fire: Priest Blessing!.");
					}
				}
			}
		}
	}
}
	
public OnWar3EventSpawn(client)
{
	War3_SetBuff(client,bBuffDenyAll,thisRaceID,false);
	new race = War3_GetRace(client);
	if (race == thisRaceID)
	{  
		bDispel[client]=false;
		bRegen[client]=false;
		//Training
		new skill3 = War3_GetSkillLevel(client, race, SKILL_TRAINING);
		if(skill3>0)
		{
			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,40);
			bRegen[client]=true;
		}
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
		War3_WeaponRestrictTo(client,thisRaceID,"");
		bDispel[client]=false;
	}
	if(newrace == thisRaceID)
	{
		if(ValidPlayer(client,true))
		{
			bRegen[client]=false;
			//Training
			new skill3 = War3_GetSkillLevel(client, thisRaceID, SKILL_TRAINING);
			if(skill3>0)
			{
				bRegen[client]=true;
			}
		}
	}
}

/*public Action:ReBuff(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		War3_SetBuff(client,bBuffDeny,race,false);
	}
}*/
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		new race_attacker=War3_GetRace(attacker);
		if(vteam!=ateam)
		{
			if(bInFire[attacker])
			{  
				War3_DamageModPercent(1.1);   
				W3FlashScreen(victim,RGBA_COLOR_RED);
			}
			if(bInFire[victim])
			{
				War3_DamageModPercent(0.95);
			}
			if(race_attacker==thisRaceID) 
			{
				if(bDispel[attacker])
				{
					PrintHintText(attacker,"Dispel Magic.");
					War3_DamageModPercent(1.2);
					War3_SetBuff(victim,bBuffDenyAll,thisRaceID,true);
					PrintHintText(victim,"Hit with Dispel Magic.");
					//CreateTimer(2.0,ReBuff,client);
					for(new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true)&&GetClientTeam(i)==GetClientTeam(victim)&&i!=victim)
						{
							new Float:vpos[3];
							GetClientAbsOrigin(i,vpos);
							new Float:apos[3];
							GetClientAbsOrigin(victim,apos);
							new Float:distance=GetVectorDistance(apos,vpos);
							if(distance<150)
							{
								War3_SetBuff(i,bBuffDenyAll,thisRaceID,true);
								//CreateTimer(2.0,ReBuff,i);
								PrintHintText(i,"Hit with Dispel Magic.");
							}
						}
					}
				}
			}
		}
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_DISPEL);
		if(skill_level>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_DISPEL,true))
			{
				if(!Silenced(client))
				{
					PrintHintText(client,"Dispel Magic on next shot.");
					War3_CooldownMGR(client,cool[skill_level],thisRaceID,SKILL_DISPEL);
					bDispel[client]=true;
				}
				else
				{
					PrintHintText(client,"Silenced: can not cast.");
				}
			}
		}
	}
}

public Action:infire(Handle:timer,any:client) 
{
	if(ValidPlayer(client))
	{
		bInFire[client]=false;
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_INNERFIRE);
		new check=War3_GetSkillLevel(client,race,SKILL_TRAINING);
		if(check>0)
		{
			if(ult_level>0)		
			{
				/*if(War3_SkillNotInCooldown(client,thisRaceID,ULT_INNERFIRE,false)) 
				{
					if(!Silenced(client))
					{
						War3_CooldownMGR(client,30.0,thisRaceID,ULT_INNERFIRE,_,_,_,"Inner Fire");
						PrintHintText(client,"INNER FIRE");
						for(new i=1;i<=MaxClients;i++)
						{
							if(ValidPlayer(i,true)&&GetClientTeam(i)==GetClientTeam(client)&&i!=client)
							{
								new Float:vpos[3];
								GetClientAbsOrigin(i,vpos);
								new Float:apos[3];
								GetClientAbsOrigin(client,apos);
								new Float:distance=GetVectorDistance(apos,vpos);
								if(distance<UltCheck[ult_level])
								{
									bInFire[i]=true;
									CreateTimer(10.0,infire,i);
									PrintHintText(i,"Inner Fire: You are blessed for 10 seconds");
								}
							}
						}
					}
					else
					{
						PrintHintText(client,"Silenced: Can not cast");
					}
				}*/
				PrintHintText(client,"This Ultimate is Passive");
				
			}
			else
			{
				PrintHintText(client,"Level Your Ultimate First");
			}
		}
		else
		{
			PrintHintText(client,"You need to train more.");
		}
	}
}