/**
* File				: War3Source_TeurenShaman.sp
* Description		: The Tauren Shaman for War3Source.
* Author(s)			: Schmarotzer & K@R@ND@SH
* Original Idea		: [UG] Sek. NovaKiller DK Surfer
*/

#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Tauren Shaman",
	author = "Schmarotzer & K@R@ND@SH",
	description = "Tauren Shaman for War3Source.",
	version = "1.0.0.0",
	url = "http://css.bashtel.ru/"
}

new thisRaceID;

//skill 1
new StrenghtHealth[6]={0,2,4,6,8,10};

//skill 2
new Float:MasterChance[6]={0.0,0.20,0.30,0.40,0.50};
new MasterXP[6]={0,5,6,7,8,10};
new MasterMoney[6]={0,100,200,300,400,500};

//skill 3
new HealerCost[6]={0,80,70,50,40,30};
new bool:bHealer[MAXPLAYERS];

//ultimate
new Float:PowerDuration[6]={1.0, 3.0, 3.5, 4.0, 4.5, 5.0};

//SKILLS and ULTIMATE
new SKILL_STRENGHT, SKILL_MASTER, SKILL_HEALER, ULT_POWER;

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==178){
		thisRaceID=War3_CreateNewRaceT("taushaman");
		SKILL_STRENGHT=War3_AddRaceSkillT(thisRaceID,"skill1",false,5);	
		SKILL_MASTER=War3_AddRaceSkillT(thisRaceID,"skill2",false,5);
		SKILL_HEALER=War3_AddRaceSkillT(thisRaceID,"skill3",false,5);
		ULT_POWER=War3_AddRaceSkillT(thisRaceID,"skill4",true,5);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnPluginStart()
{
	HookEvent("round_start",RoundStartEvent);
	LoadTranslations("w3s.race.taushaman.phrases");
}


public OnMapStart()
{
	CreateTimer(0.2,Healer,_,TIMER_REPEAT);
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
		War3_WeaponRestrictTo(client,thisRaceID, "");
	}
	if(newrace==thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_ssg08,weapon_glock,weapon_usp,weapon_fiveseven,weapon_p228,weapon_deagle,weapon_elite,weapon_knife");
		if(ValidPlayer(client,true))
		{
			bHealer[client]=false;
			GivePlayerItem(client,"weapon_ssg08");
		}
	}
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		bHealer[client]=false;
		// InitPassiveSkills(client);
		// bFlying[client]=false;
		// War3_SetBuff(client,bFlyMode,thisRaceID,false);
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_ssg08,weapon_glock,weapon_usp,weapon_fiveseven,weapon_p228,weapon_deagle,weapon_elite,weapon_knife");
		if(ValidPlayer(client,true))
		{
			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,50);
			War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
			GivePlayerItem(client,"weapon_ssg08");
		}
	}
}




// =================================================================================================
// ======================================= AURA OF STRENGHT ========================================
// =================================================================================================

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x,true)&&War3_GetRace(x)==thisRaceID)
		{
			new skill_level_strenght=War3_GetSkillLevel(x,thisRaceID,SKILL_STRENGHT);
			if(skill_level_strenght>0)
			{
				War3_ChatMessage(x,"%T","String_01",x);
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true))
					{
						new ITeam = GetClientTeam(i);
						new teamX = GetClientTeam(x);
						if(ITeam==teamX && i!=x)
						{
							new hpadd;
							new TeammateMaxHP = War3_GetMaxHP(i);
							new TeammateHP = GetClientHealth(i);
							if (TeammateMaxHP > 25 && TeammateMaxHP < 155)
							{
								hpadd = StrenghtHealth[skill_level_strenght];
							}
							else
							{
								hpadd = 1;
							}
							War3_SetBuff(i,iAdditionalMaxHealth,thisRaceID,hpadd);
							SetEntityHealth(i,TeammateHP + hpadd);
							War3_ChatMessage(i,"%T","String_02",i,hpadd);
							// War3_ChatMessage(i,"%T","You gained [amount] HP",hpadd);
						}
					}
				}
			}
		}
	}
}
// =================================================================================================
// =================================================================================================
// =================================================================================================





// =================================================================================================
// ======================================= WEAPON'S MASTER =========================================
// =================================================================================================
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker,true) && attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			if(race_attacker==thisRaceID)
			{
				new skill_level_master=War3_GetSkillLevel(attacker,race_attacker,SKILL_MASTER);
				if(skill_level_master>0&&!Hexed(attacker,false))
				{
					if( GetRandomFloat(0.0,1.0)<=MasterChance[skill_level_master] && !W3HasImmunity(victim,Immunity_Skills))
					{
						new ent = W3GetCurrentWeaponEnt(attacker);
						if(ent>0 && IsValidEdict(ent))
						{
							decl String:wepName[64];
							GetEdictClassname(ent,wepName,64);
							if(StrEqual(wepName,"weapon_ssg08",true))
							{
								new old_XP = War3_GetXP(attacker,thisRaceID);
								new new_XP = old_XP+MasterXP[skill_level_master];
								War3_SetXP(attacker,thisRaceID,new_XP);
								
								new old_money = GetCSMoney(attacker);
								new new_money = old_money + MasterMoney[skill_level_master];
								if (new_money>=16000)
									new_money=16000;
								SetCSMoney(attacker,new_money);
							}
						}
					}
				}
			}
		}
	}
}
// =================================================================================================
// =================================================================================================
// =================================================================================================



// =================================================================================================
// ========================================= WOUNDS HEALER =========================================
// =================================================================================================


public Action:Healer(Handle:timer,any:client)
{
	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true))
			{
				new skill_level_healer=War3_GetSkillLevel(i,thisRaceID,SKILL_HEALER);
				new Race_Healer = War3_GetRace(i);
				if(Race_Healer==thisRaceID && skill_level_healer>0 && bHealer[i])
				{
					new old_money=GetCSMoney(i);
					if(old_money>HealerCost[skill_level_healer])
					{
						new new_money = old_money - HealerCost[skill_level_healer];
						SetCSMoney(i, new_money);
						// new old_HP = GetClientHealth(i);
						// SetEntityHealth(i, old_HP+1);
						War3_HealToMaxHP(i,1);
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
		new skill_level_healer=War3_GetSkillLevel(client,thisRaceID,SKILL_HEALER);
		if(skill_level_healer>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_HEALER,true))
			{
				if(!Silenced(client))
				{
					if(!bHealer[client])
					{
						bHealer[client]=true;
						War3_CooldownMGR(client,1.0,thisRaceID,SKILL_HEALER,_,_);
					}
					else
					{
						bHealer[client]=false;
						War3_CooldownMGR(client,5.0,thisRaceID,SKILL_HEALER,_,_);
					}
				}		
			}
		}
	}
}
// =================================================================================================
// =================================================================================================
// =================================================================================================




// =================================================================================================
// ========================================= HATURE POWER ==========================================
// =================================================================================================

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client)){
		if(!Silenced(client)){
			new ult_level_power=War3_GetSkillLevel(client,thisRaceID,ULT_POWER);
			if(ult_level_power>0)
			{
				new Float:time = PowerDuration[ult_level_power];
				if(War3_SkillNotInCooldown(client,thisRaceID,ULT_POWER,true)){
					if( GetRandomFloat(0.0,1.0)<=0.5 )
					{
						War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
						War3_CooldownMGR(client,30.0,thisRaceID,ULT_POWER,_,_);
						
						CreateTimer(time,unhide,client);
						PrintHintText(client,"%T","String_03",client,time);
					}
					else
					{
						new ClientTeam = GetClientTeam(client);
						/*if(ClientTeam==2)
						{
							SetEntityModel(client, "models/player/ct_urban.mdl");
						}
						if(ClientTeam==3)
						{
							SetEntityModel(client, "models/player/t_leet.mdl");
						}
						*/
						CreateTimer(time,unmask,client);
						PrintHintText(client,"%T","String_04",client,time);
						
						decl String:szPlayerName[255];
						GetClientName(client, szPlayerName, sizeof(szPlayerName));
						for (new i = 1; i <= MaxClients; i++)
						{
							if (IsClientInGame(i) && !IsFakeClient(i))
							{
								new ITeam = GetClientTeam(i);
								if(ITeam==ClientTeam && i != client)
								{
									new String:szMessage[150];
									
									Format(szPlayerName, sizeof(szPlayerName), "\x03%s\x01", szPlayerName);
									
									Format(szMessage, sizeof(szMessage), "\x04[W3S] %s :  %T", szPlayerName, "String_05", i);
									SayText2(i, i, szMessage);
								}
							}
						}
					}
				}
			}
			else
			{
				W3MsgUltNotLeveled(client);
			}
		}
		// else
		// {
			// PrintHintText(client,"Безмолвие!");
		// }
	}
}

public SayText2(client, author, const String:szMessage[])
{
	new Handle:hBuffer = StartMessageOne("SayText2", client);
	
	if (hBuffer != INVALID_HANDLE)
	{
		BfWriteByte(hBuffer, author);
		BfWriteByte(hBuffer, true);
		BfWriteString(hBuffer, szMessage);
		EndMessage();
	}
}

public Action:unhide(Handle:timer,any:client)
{
	if(ValidPlayer(client,true)){
		// W3ResetBuffRace(client,fInvisibilitySkill,thisRaceID);
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		PrintHintText(client,"%T","String_06",client);
	}
}

public Action:unmask(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		/*
		new ClientTeam = GetClientTeam(client);
		if(ClientTeam==3)
		{
			SetEntityModel(client, "models/player/ct_urban.mdl");
		}
		if(ClientTeam==2)
		{
			SetEntityModel(client, "models/player/t_leet.mdl");
		}
		*/
	}
}
// =================================================================================================
// =================================================================================================
// =================================================================================================