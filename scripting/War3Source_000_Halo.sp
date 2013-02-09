#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
new Handle:ultCooldownCvar;

new thisRaceID;

new Float:FastSpeed[7]=  {1.0,2.05,2.10,2.15,2.20,2.25,2.30};
new Float:Gravity[7]={1.0,0.90,0.80,0.70,0.65,0.60,0.55};
new BigHealth[7]={0,5,10,15,20,25,30};
new asdasd[7] = { 0,1,2,3,4,5,6};
new String:BlueHaloModel[]="models/player/mapeadores/morell/masterchief/mc_blue.mdl";
new String:RedHaloModel[] = "models/player/mapeadores/morell/masterchief/mc_red.mdl";
public Plugin:myinfo = 
{
	name = "War3Source Race - Halo",
	author = "Chuck, ideas from SoundStream",
	description = "Tmu first race",
	version = "1.0.0.1",
	url = "http://tmuservers.net"
};


new SKILL_ULTIMATE,SKILL_SPEED,SKILL_GRAVITY,SKILL_HEALTH;

public OnWar3LoadRaceOrItemOrdered(num)
{
    if(num == 1)
    {
		thisRaceID=War3_CreateNewRace("Tmu Halo","halo");
		SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed","Run Faster",false,6);
		SKILL_GRAVITY=War3_AddRaceSkill(thisRaceID,"Gravity","Decrease the Gravity",false,6);
		SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Health","More Health",false,6);
		SKILL_ULTIMATE=War3_AddRaceSkill(thisRaceID,"Sword Power","Use knife and run fast for few seconds",true,6);
		War3_CreateRaceEnd(thisRaceID);
		
		War3_AddSkillBuff(thisRaceID,SKILL_HEALTH,iAdditionalMaxHealth,BigHealth);
		War3_AddSkillBuff(thisRaceID,SKILL_GRAVITY,fLowGravitySkill,Gravity);
	}
}	

public OnMapStart()
{
	//PrecacheModel(BlueHaloModel,true);
	//PrecacheModel(RedHaloModel,true);
}



// War3Source Functions

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("war3_halo_cooldown","20.0","Cooldown between Sword");
    
}



public OnRaceChanged(client, oldrace, newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		

	}
	if(newrace == thisRaceID)
	{
		
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_p90");
		GivePlayerItem(client,"weapon_p90");
		//SetEntityModel(client, RedHaloModel);
		//SetEntityModel(client, BlueHaloModel);
		
	}
}


public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		
		//SetEntityModel(client, RedHaloModel);
		//SetEntityModel(client, BlueHaloModel);
	}
	
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_level = War3_GetSkillLevel(client,race,SKILL_ULTIMATE);
		if(ult_level>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_ULTIMATE,true))
			{	
				CreateTimer(asdasd[ult_level],ABCD,client);
				new Float:cooldown=GetConVarFloat(ultCooldownCvar);
				War3_CooldownMGR(client,cooldown,thisRaceID,SKILL_ULTIMATE,_,_);
				
				
			}
			else
			{
				War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
				War3_WeaponRestrictTo(client,thisRaceID,"weapon_p90");
				GivePlayerItem(client,"weapon_p90");
			}
		}
	}
}			
	
public Action:ABCD(Handle:timer,any:victim)
{
	new VictimRace = War3_GetRace(victim);
	if(VictimRace==thisRaceID)
	{
		new skilllevel=War3_GetSkillLevel(victim,thisRaceID,SKILL_SPEED);
		War3_SetBuff(victim,fMaxSpeed,thisRaceID,FastSpeed[skilllevel]);
		War3_WeaponRestrictTo(victim,thisRaceID,"weapon_knife");
		GivePlayerItem(victim,"weapon_knife");
	}
	
}