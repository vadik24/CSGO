#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

#include <sdkhooks>



new thisRaceID;
new Float:SkillLongJump[7]={0.0,2.0,2.5,3.0,4.5,5.0,5.5};
new Float:FastSpeed[7]=  {1.0,1.05,1.10,1.15,1.20,1.25,1.30};
new Float:Gravity[7]={1.0,0.95,0.90,0.85,0.80,0.75,0.70};
new BigHealth[7]={0,5,10,15,20,25,30};

//long jump variable
new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;
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

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num == 1)
    {
		thisRaceID=War3_CreateNewRace("Tmu Chucky","chucky");
		SKILL_LONGJUMP=War3_AddRaceSkill(thisRaceID,"Long Jump","Increase the Jump",false,6);
		SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed","Run Faster",false,6);
		SKILL_GRAVITY=War3_AddRaceSkill(thisRaceID,"Gravity","Decrease the Gravity",false,6);
		SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Health","Less Health",false,6);
		
		War3_CreateRaceEnd(thisRaceID);
		
		War3_AddSkillBuff(thisRaceID,SKILL_SPEED,fMaxSpeed,FastSpeed);
		War3_AddSkillBuff(thisRaceID,SKILL_HEALTH,iAdditionalMaxHealth,BigHealth);
		War3_AddSkillBuff(thisRaceID,SKILL_GRAVITY,fLowGravitySkill,Gravity);
	}
}	

public OnMapStart()
{
	PrecacheModel(ChuckyModel,true);
}



// War3Source Functions

public OnPluginStart()
{
	m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	HookEvent("player_jump",PlayerJumpEvent);
}

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

	}
	if(newrace == thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		if(War3_GetLevel(client, newrace) == 0)
		War3_SetLevel(client, newrace, 3);
		
		if(ValidPlayer(client,true))
		{
			
			SetEntityModel(client, ChuckyModel);
		}
	}
}


public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		
		SetEntityModel(client, ChuckyModel);
	}
	
}
