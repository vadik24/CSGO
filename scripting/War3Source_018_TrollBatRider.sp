 /**
* File: War3Source_TrollBatRider.sp
* Description: The Troll Bat Rider race for War3Source.
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
new bool:bFlying[66];
new Handle:ultCooldownCvar;
//new String:TrollModel[]="models/player/techknow/demon/demon.mdl";

//skill 1
new RegenAmountArr[]={0,1,1,2,2,3,3,4,5};

//skill 2
new Float:ArcaniteDamagePercent[9]={0.0,0.26,0.28,0.30,0.32,0.34,0.36,0.38,0.40};
new Float:ArcaniteChance[9]={0.0,0.58,0.61,0.64,0.67,0.71,0.74,0.77,0.80};
//skill 3
new Float:LiquidFireArr[9]={1.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0};

//skill 4
new SKILL_REGEN, SKILL_ARCANITE, SKILL_LIQUIDFIRE, ULT_CONCOCTION;

public Plugin:myinfo = 
{
	name = "War3Source Race - Troll Bat Rider",
	author = "[Oddity]TeacherCreature",
	description = "The Troll Bat Rider race for War3Source.",
	version = "1.0.0.0",
	url = "warcraft-source.net"
};

public OnPluginStart()
{
	CreateTimer(1.0,CalcRegees,_,TIMER_REPEAT);
	HookEvent("hegrenade_detonate", GrenadeDetonate);
	ultCooldownCvar=CreateConVar("war3_tbr_flying_cooldown","0.5","Cooldown for Flying");
	
	LoadTranslations("w3s.race.tbr.phrases");
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID){
		W3ResetAllBuffRace(client,thisRaceID);
		W3ResetPlayerColor(client,thisRaceID);
		War3_WeaponRestrictTo(client,thisRaceID,"");
	}
	if(newrace==thisRaceID)
	{
		bFlying[client]=false;
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_hegrenade");
		if(ValidPlayer(client,true))
		{
			GivePlayerItem(client,"weapon_hegrenade");
		}
	}
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==6)
	{
		thisRaceID=War3_CreateNewRaceT("tbr");
		SKILL_REGEN=War3_AddRaceSkillT(thisRaceID,"Regenerate",false,8);
		SKILL_ARCANITE=War3_AddRaceSkillT(thisRaceID,"Arcanite",false,8);
		SKILL_LIQUIDFIRE=War3_AddRaceSkillT(thisRaceID,"LiquidFire",false,8);
		ULT_CONCOCTION=War3_AddRaceSkillT(thisRaceID,"BatRider",true,1); 
		War3_CreateRaceEnd(thisRaceID);
	}
}
public OnMapStart()
{
	//PrecacheModel(TrollModel,true);
}

public Action:CalcRegees(Handle:timer,any:userid)
{
	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true))
			{
				if(War3_GetRace(i)==thisRaceID)
				{
					Regen(i); //check leves later
				}
			}
		}
	}
}

public Regen(client)
{
	//assuming client exists and has this race
	new skill = War3_GetSkillLevel(client,thisRaceID,SKILL_REGEN);
	if(skill>0)
	{
		new Float:dist = 1.0;
		new RegenTeam = GetClientTeam(client);
		new Float:RegenPos[3];
		GetClientAbsOrigin(client,RegenPos);
		new Float:VecPos[3];

		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)==RegenTeam)
			{
				GetClientAbsOrigin(i,VecPos);
				if(GetVectorDistance(RegenPos,VecPos)<=dist)
				{
					War3_HealToMaxHP(i,RegenAmountArr[skill]);
				}
			}
		}
	}
}

public Action:GrenadeDispense(Handle:timer,any:index)
{
	if(ValidPlayer(index)&&IsPlayerAlive(index))
	{
		GivePlayerItem(index,"weapon_hegrenade");
	}
}
	
public Action:GrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new index=GetClientOfUserId(userid);
	if(index>0)
	{
		new race=War3_GetRace(index);
		if(race==thisRaceID&&War3_GetGame()!=Game_TF&&IsPlayerAlive(index))
		{
			GivePlayerItem(index,"weapon_hegrenade");
		}
	}
	return Plugin_Continue;
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
			new skill_level_liquidfire=War3_GetSkillLevel(attacker,thisRaceID,SKILL_LIQUIDFIRE);
			new skill_level_arcanite=War3_GetSkillLevel(attacker,thisRaceID,SKILL_ARCANITE);
			// Arcanite
			if(race_attacker==thisRaceID && skill_level_arcanite>0 )
			{
				if(GetRandomFloat(0.0,1.0)<=ArcaniteChance[skill_level_arcanite] && !W3HasImmunity(victim,Immunity_Skills))
				{
				War3_DamageModPercent(ArcaniteDamagePercent[skill_level_arcanite]+1.0);
				//PrintToConsole(attacker,"+%d ARCANITE DAMAGE (SDKhooks)",damage_i);
				W3FlashScreen(victim,RGBA_COLOR_RED);
				}
			}
			// Liquid Fire
			if(race_attacker==thisRaceID && skill_level_liquidfire>0)
			{
				if(GetRandomFloat(0.0,1.0)<=0.5 && !W3HasImmunity(victim,Immunity_Skills))
				{
				IgniteEntity(victim,LiquidFireArr[skill_level_liquidfire]);
				PrintToConsole(attacker,"%T","Liquid Fire burns your enemy",attacker);
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
		new ult_level=War3_GetSkillLevel(client,race,ULT_CONCOCTION);
		if(ult_level>0)		
		{
			new Float:cooldown=GetConVarFloat(ultCooldownCvar);
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_CONCOCTION,false)) 
			{
				if(!Silenced(client))
				{
					if(!bFlying[client])
					{
						bFlying[client]=true;
						War3_SetBuff(client,bFlyMode,thisRaceID,true);
						PrintHintText(client,"%T","Ride Bat and fly!",client);
					}	
					else
					{
						bFlying[client]=false;
						War3_SetBuff(client,bFlyMode,thisRaceID,false);
						PrintHintText(client,"%T","Get off of bat and stop flying!",client);
					}
					War3_CooldownMGR(client,cooldown,thisRaceID,ULT_CONCOCTION,_,_);
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

public OnWar3EventDeath(victim,attacker)
{
	
	/*new uid_victim=GetEventInt(event,"userid");
	if(uid_victim>0)
	{
		new deathFlags = GetEventInt(event, "death_flags");
		if (War3_GetGame()==Game_TF&&deathFlags & 32)
		{
		   //PrintToChat(client,"war3 debug: dead ringer kill");
		}
		else
		{
			new victim=GetClientOfUserId(uid_victim);*/
			
	ExtinguishEntity(victim);
		//}
	//}
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		//SetEntityModel(client, TrollModel);
		if(GetClientTeam(client)==3)
		{
			W3SetPlayerColor(client,thisRaceID,20,100,200,255,1);
		}
		else{
			W3ResetPlayerColor(client,thisRaceID);
		}
		
		bFlying[client]=false;
		War3_SetBuff(client,bFlyMode,thisRaceID,false);
		CreateTimer(0.7,GrenadeDispense,client);
	}
	
}
