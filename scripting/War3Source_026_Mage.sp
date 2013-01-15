 /**
* File: War3Source_Mage.sp
* Description: The ES version of Archmage race for War3Source.
* Author(s): [Oddity]TeacherCreature
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

new thisRaceID;

//skill 1 //20% shake 3 3 4 5 5 6
new Float:ShakeTimeArr[]={0.0, 3.0, 3.0, 4.0, 5.0, 5.0, 6.0};

//skill 2
new Float:SpeedArr[]={1.0,1.05,1.1,1.15,1.2,1.25,1.3};

//skill 3 
new Float:DeagleArr[]={0.0,0.3,0.4,0.5,0.6,0.7,0.8};
new Float:ColtArr[]={0.0,0.3,0.4,0.45,0.5,0.55,0.6};

//skill 4.
new HealthArr[]={0,5,6,7,8,9,10};
new Float:Cooldown[]={0.0, 4.0, 4.0, 3.0, 3.0, 2.0, 1.0};
new bool:bFlying[66];

new SKILL_EARTHQUAKE, SKILL_BROOM, SKILL_WEAPON, ULT_LIFTOFF;

public Plugin:myinfo = 
{
	name = "War3Source Race - Mage",
	author = "[Oddity]TeacherCreature",
	description = "The ES Archmage race for War3Source.",
	version = "1.0.6.0",
	url = "warcraft-source.net"
};

public OnPluginStart()
{
	LoadTranslations("w3s.race.archm.phrases");
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==2)
	{
		thisRaceID=War3_CreateNewRaceT("archm");
		SKILL_EARTHQUAKE=War3_AddRaceSkillT(thisRaceID,"Earthquake",false,6);
		SKILL_BROOM=War3_AddRaceSkillT(thisRaceID,"BroomOfVelocity",false,6);
		SKILL_WEAPON=War3_AddRaceSkillT(thisRaceID,"WeaponOfTheSorcerer",false,6);
		ULT_LIFTOFF=War3_AddRaceSkillT(thisRaceID,"LiftOff",true,6); 
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID){
		W3ResetAllBuffRace(client,thisRaceID);
	}
	if(newrace==thisRaceID){
		bFlying[client]=false;
		if(ValidPlayer(client,true))
		{
			InitPassiveSkills(client);
		}
	}
}

public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel = War3_GetSkillLevel(client,thisRaceID,SKILL_BROOM);
		if(skilllevel)
		{
			War3_SetBuff(client,fMaxSpeed,thisRaceID,SpeedArr[skilllevel]);
		}
	}
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && attacker!=victim)
	{
		new vteam = GetClientTeam(victim);
		new ateam = GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker = War3_GetRace(attacker);
			new skill_level_earthquake = War3_GetSkillLevel(attacker,thisRaceID,SKILL_EARTHQUAKE);
			// Earthquake
			if(race_attacker==thisRaceID && skill_level_earthquake>0)
			{
				if(W3Chance(0.25) && !IsSkillImmune(victim))
				{
					War3_ShakeScreen(victim,ShakeTimeArr[skill_level_earthquake],50.0,40.0);
					PrintToConsole(attacker,"%T","Earthquake",attacker);
					W3FlashScreen(victim,RGBA_COLOR_RED);
				}
			}
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_LIFTOFF);
		if(ult_level>0)		
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_LIFTOFF,false)) 
			{
				if(!Silenced(client))
				{
					if(!bFlying[client])
					{
						bFlying[client]=true;
						War3_SetBuff(client,bFlyMode,thisRaceID,true);
						PrintHintText(client,"%T","Lift off and fly!",client);
						War3_HealToBuffHP(client,HealthArr[ult_level]);
					}	
					else
					{
						bFlying[client]=false;
						War3_SetBuff(client,bFlyMode,thisRaceID,false);
						PrintHintText(client,"%T","You land!",client);
					}
					War3_CooldownMGR(client,Cooldown[ult_level],thisRaceID,ULT_LIFTOFF,_,_);
				}
				else
				{
					PrintHintText(client,"%T","Silenced: Can not cast",client);
				}
			}
			
		}
		else
		{
			PrintHintText(client,"%T","Level Your Ultimate First",client);
		}
	}
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		InitPassiveSkills(client);
		bFlying[client]=false;
		War3_SetBuff(client,bFlyMode,thisRaceID,false);
		new wep_level=War3_GetSkillLevel(client,race,SKILL_WEAPON);
		if(wep_level>0)		
		{
			if(GetRandomFloat(0.0,1.0)<=DeagleArr[wep_level])
			{
				GivePlayerItem(client,"weapon_deagle");
			}
			if(GetRandomFloat(0.0,1.0)<=ColtArr[wep_level])
			{
				GivePlayerItem(client,"weapon_m4a1");
			}
		}
	}
}