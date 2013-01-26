/**
 * File: War3Source_080_Rapscallion.sp
 * Description: The Rapscallion race for War3Source.
 * Author(s): VoidLess
 */

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
//#include <sdktools_functions>
//#include <sdktools_tempents>
//#include <sdktools_tempents_stocks> 

//#include <sdkhooks>

new thisRaceID;

new SKILL_SPEED,SKILL_BLADE,SKILL_LOWGRAV,SKILL_INVISIBLE;

new Float:UnholySpeed[5]={1.0,1.07,1.14,1.21,1.28};
new Float:BladeChance[5]={0.0,0.20,0.40,0.60,0.80};
new Float:LevitationGravity[5]={1.0,0.8,0.6,0.5,0.4};

new Float:UltDelay[5]={0.0,4.0,3.0,2.0,1.0};
//new Float:UltTime[5]={0.0,10.0,20.0,30.0,40.0};

new bool:bIsInvisible[MAXPLAYERS];

new String:Bladestr[]="npc/roller/mine/rmine_blades_out2.mp3";
new String:UltInstr[]="npc/scanner/scanner_nearmiss1.mp3";
new String:UltOutstr[]="npc/scanner/scanner_nearmiss2.mp3";

new bool:hurt_flag = true;

public Plugin:myinfo = 
{
	name = "War3Source Race - Rapscallion",
	author = "VoidLess",
	description = "Rapscallion race for War3Source.",
	version = "1.0.0",
	url = "http://twitter.com/voidless"
};

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==80)
	{
		thisRaceID=War3_CreateNewRaceT("raps");
		SKILL_SPEED=War3_AddRaceSkillT(thisRaceID,"1",false,4);
		SKILL_BLADE=War3_AddRaceSkillT(thisRaceID,"2",false,4);
		SKILL_LOWGRAV=War3_AddRaceSkillT(thisRaceID,"3",false,4);
		SKILL_INVISIBLE=War3_AddRaceSkillT(thisRaceID,"4",true,4);
		
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnPluginStart()
{
	LoadTranslations("w3s.race.raps.phrases");
	HookEvent("player_hurt",PlayerHurtEvent);
}

public OnMapStart()
{
	////War3_PrecacheSound(Bladestr);
	////War3_PrecacheSound(UltInstr);
	////War3_PrecacheSound(UltOutstr);
}

public OnWar3EventSpawn(client)
{
	StopInvis(client);
	
	new race = War3_GetRace(client);
	if (race == thisRaceID)
	{  
		InitPassiveSkills(client);
	}
}

public InitPassiveSkills(client){
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel_unholy=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
		new Float:speed=UnholySpeed[skilllevel_unholy];
		War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
		
		new skilllevel_levi=War3_GetSkillLevel(client,thisRaceID,SKILL_LOWGRAV);
		new Float:gravity=LevitationGravity[skilllevel_levi];
		War3_SetBuff(client,fLowGravitySkill,thisRaceID,gravity);
	}
}

public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
	InitPassiveSkills(client);
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	if(newrace == thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		if(IsPlayerAlive(client))
		{
			InitPassiveSkills(client);
		}
	}
}

public PlayerHurtEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (hurt_flag == false)
	{
		hurt_flag = true; //for skipping your own damage?
	} else {
		new victim = GetClientOfUserId(GetEventInt(event,"userid"));
		new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
		
		if (victim && attacker && victim!=attacker)
		{
			
			new race=War3_GetRace(attacker);
			if (race==thisRaceID)
			{
				new dmgamount = GetEventInt(event,"dmg_health");
				
				new skilllevel = War3_GetSkillLevel(attacker,race,SKILL_BLADE);
				
				if (skilllevel > 0 && dmgamount > 0 && !W3HasImmunity(victim,Immunity_Skills))
				{
					decl String: weapon[MAX_NAME_LENGTH+1];
					GetEventString(event,"weapon",weapon,sizeof(weapon));
					
					if (StrEqual(weapon,"knife") && GetRandomFloat(0.0,1.0)<=BladeChance[skilllevel])
					{
						War3_ChatMessage(attacker, "%T", "Blade", attacker);
						//W3EmitSoundToAll(Bladestr,attacker);
						//W3EmitSoundToAll(Bladestr,victim);
						W3FlashScreen(victim,RGBA_COLOR_RED);
						
						hurt_flag = false;
						War3_DealDamage(victim,dmgamount,attacker,_,"Blade",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL);
					}
				}
			}
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(pressed)
	{
		if(race==thisRaceID&&IsPlayerAlive(client)&&!Silenced(client))
		{
			new ult_level=War3_GetSkillLevel(client,race,SKILL_INVISIBLE);
			if (ult_level>0)
			{
				ToggleInvisibility(client, ult_level);
			}
			else
			{
				W3MsgUltNotLeveled(client);
			}
		}
	}
}
/*
public Action:TimerStopInvis(Handle:timer,any:client)
{
	StopInvis(client);
}
*/
stock StopInvis(client)
{
	if (bIsInvisible[client])
	{
		bIsInvisible[client]=false;
		War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		//W3EmitSoundToAll(UltOutstr,client);
	}
}

stock StartInvis(client)
{
	if (!bIsInvisible[client])
	{
		bIsInvisible[client]=true;
		War3_SetBuff(client,bNoMoveMode,thisRaceID,true);
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
		//W3EmitSoundToAll(UltInstr,client);
		
		//new lvl = War3_GetSkillLevel(client,race,SKILL_INVISIBLE);
		//CreateTimer(UltTime[lvl],TimerStopInvis,client);
	}
}

stock ToggleInvisibility(client, ult_level)
{
	if (War3_SkillNotInCooldown(client,thisRaceID,SKILL_INVISIBLE,true))
	{
		if (bIsInvisible[client])
			StopInvis(client);
		else
			StartInvis(client);
		
		War3_CooldownMGR(client,UltDelay[ult_level],thisRaceID,SKILL_INVISIBLE);
	} else {
		War3_PrintSkillIsNotReady(client,thisRaceID,SKILL_INVISIBLE);
	}
}
