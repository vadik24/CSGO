#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks> 


new thisRaceID;
new Float:SkillLongJump[7]={0.0,1.5,2.0,2.5,3.0,3.5,4.0};
new Float:Speed[7]={0.0,0.05,0.10,0.15,0.20,0.25,0.3};
new Float:Gravity[7]={1.0,0.95,0.90,0.85,0.80,0.75,0.70};
new Float:Health[7]={40.0,45.0,50.0,55.0,60.0,65.0,70.0};

new String:ChuckyModel[]="models/player/slow/chucky_v3/slow.mdl";

public Plugin:myinfo = 
{
	name = "War3Source Race - Chucky",
	author = "Chuck",
	description = "Tmu first race",
	version = "1.0.0.1",
	url = "http://tmuservers.net"
};


new SKILL_LONGJUMP,SKILL_SPEED,SKILL_GRAVITY,SKILL_HEALTH;

public OnWar3PluginReady()
{
		thisRaceID=War3_CreateNewRace("Tmu Chucky","chucky");
		SKILL_LONGJUMP=War3_AddRaceSkill(thisRaceID,"Long Jump","Increase the Jump",false,7);
		SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed","Run Faster",false,7);
		SKILL_GRAVITY=War3_AddRaceSkill(thisRaceID,"Gravity","Decrease the Gravity",false,7);
		SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Health","Less Health",false,7);
		War3_CreateRaceEnd(thisRaceID);
}

public OnMapStart()
{
	PrecacheModel(ChuckyModel,true);
}



// War3Source Functions
public OnPluginStart()
{
	HookEvent("player_jump",PlayerJumpEvent);
}
new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;
public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	new ClientRace = War3_GetRace(client);
	if(ClientRace==thisRaceID){
		new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_LONGJUMP);
		if(skilllevel>0){
			new Float:velocity[3]={0.0,0.0,0.0};
			velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
			velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
			velocity[0]*=SkillLongJump[skilllevel]*0.25;
			velocity[1]*=SkillLongJump[skilllevel]*0.25;
			SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
		}
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
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		
		if(ValidPlayer(client,true))
		{
			
			PassiveSkills(client);
		}
	}
}

public PassiveSkills(client)
{
	if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID)
	{
		SetEntityModel(client, ChuckyModel);
		new skill_healths=War3_GetSkillLevel(client,thisRaceID,SKILL_HEALTH);
		if (skill_healths)
		{
			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,Health[skill_healths]);
			
		}
		new skill_speeds = War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
		if(skill_speeds)
		{
		 War3_SetBuff(client,fMaxSpeed,thisRaceID,Speed[skill_speeds]);
		}
		new skill_gravitys = War3_GetSkillLevel(client,thisRaceID,SKILL_GRAVITY);
		if(skill_gravitys)
		{
		War3_SetBuff(client,fLowGravitySkill,thisRaceID,Gravity[skill_gravitys]);
		}
	}
}

public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		
		PassiveSkills(client);
	}
	
}
