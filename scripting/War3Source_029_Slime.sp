/**
 * File: War3Source_Slime.sp
 * Description: The Slime Unit for War3Source.
 * Author(s): [Oddity]TeacherCreature
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

new thisRaceID;

new SKILL_EVASION,SKILL_ORB,SKILL_POISON,ULT_EXPLOSION;

//skill 1
new Float:EvadeChance[5]={0.0,0.54,0.56,0.58,0.6}; 

//skill 2
new OrbAmount[5]={0,2,3,4,5};

//skill 3
new Float:PoisonChance[5]={0.0,0.45,0.5,0.55,0.6};
new const PoisonInitialDamage=10;
new const PoisonTrailingDamage=5;
new BeingPoisonedBy[MAXPLAYERS];
new PoisonRemaining[MAXPLAYERS];

//ultimate
new Float:UltRadius[5]={0.0,290.0,310.0,330.0,350.0};
new ExplosionModel;
new Float:ExplosionLocation[MAXPLAYERS][3];
new BeamSprite;
new HaloSprite;


public Plugin:myinfo = 
{
	name = "War3Source Race - Slime",
	author = "[Oddity]TeacherCreature",
	description = "The Slime Unit for War3Source.",
	version = "1.0.6.0",
	url = "warcraft-source.net"
}

public OnPluginStart()
{
	LoadTranslations("w3s.race.slime.phrases");
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==9)
	{
		thisRaceID=War3_CreateNewRaceT("slime");
		SKILL_EVASION=War3_AddRaceSkillT(thisRaceID,"SlimeEvasion",false,4);
		SKILL_ORB=War3_AddRaceSkillT(thisRaceID,"SlimeOrb",false,4);
		SKILL_POISON=War3_AddRaceSkillT(thisRaceID,"SlimePoison",false,4);
		ULT_EXPLOSION=War3_AddRaceSkillT(thisRaceID,"SlimeExplosion",true,4);
		War3_CreateRaceEnd(thisRaceID);	
	}

}

public OnMapStart()
{
	
	ExplosionModel=PrecacheModel("materials/sprites/zerogxplode.vmt",false);
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();	
}

public OnRaceChanged(client, oldrace, newrace)
{
	if (newrace == thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
		if(ValidPlayer(client,true)){
			
			GivePlayerItem(client, "weapon_knife");
			new ClientTeam = GetClientTeam(client);
			switch(ClientTeam)
			{
				case 3:
					W3SetPlayerColor(client,thisRaceID,0,50,255);
				case 2:
					W3SetPlayerColor(client,thisRaceID,255,255,255);
			}
		}
	}
	else if (oldrace == thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
		W3SetPlayerColor(client,thisRaceID,255,255,255);
	}
}

public OnWar3EventDeath(victim,attacker)
{
	new race=War3_GetRace(victim);
	new skill=War3_GetSkillLevel(victim,thisRaceID,ULT_EXPLOSION);
	if(race==thisRaceID && skill>0 && !Silenced(victim))
	{
		GetClientAbsOrigin(victim,ExplosionLocation[victim]);
		CreateTimer(0.15,DelayedBomber,victim);
	}
}
public Action:DelayedBomber(Handle:h,any:client){
	if(ValidPlayer(client)&&!IsPlayerAlive(client))
	{
		SlimeBomber(client,War3_GetSkillLevel(client,thisRaceID,ULT_EXPLOSION));
	}
}

public SlimeBomber(client,level)
{
	new ult_skill=War3_GetSkillLevel(client,thisRaceID,ULT_EXPLOSION);
	new Float:radius=UltRadius[ult_skill];
	if(level<=0)
		return; // just a safety check
	new Float:client_location[3];
	new our_team=GetClientTeam(client);
	for(new i=0;i<3;i++){
		client_location[i]=ExplosionLocation[client][i];
	}
	TE_SetupExplosion(client_location,ExplosionModel,10.0,1,0,RoundToFloor(radius),160);
	TE_SendToAll();
	client_location[2]-=40.0;
	TE_SetupBeamRingPoint(client_location, 10.0, radius, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, {255,255,255,33}, 120, 0);
	TE_SendToAll();
	
	new beamcolor[]={0,255,0,255}; 
	TE_SetupBeamRingPoint(client_location, 20.0, radius+10.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, beamcolor, 120, 0);
	TE_SendToAll();
	client_location[2]+=40.0;
	
	new Float:location_check[3];
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x,true)&&client!=x)
		{
			new team=GetClientTeam(x);
			if(team==our_team)
				continue;
			GetClientAbsOrigin(x,location_check);
			new Float:distance=GetVectorDistance(client_location,location_check);
			if(distance>radius)
				continue;
			
			if(!IsUltImmune(x))
			{
				W3FlashScreen(x,RGBA_COLOR_GREEN);
				PoisonRemaining[x]=10;
				BeingPoisonedBy[x]=client;
				War3_DealDamage(x,PoisonInitialDamage,client,DMG_BULLET,"slimeexplosion");
				CreateTimer(1.0,PoisonLoop,GetClientUserId(x));
				W3MsgAttackedBy(x,"Slime Explosion");
				W3MsgActivated(client,"Slime Explosion");
			}
			else
			{
				PrintToConsole(client,"%T","[W3S] Could not damage player {1} due to immunity",client,x);
			}
			
		}
	}
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	PoisonRemaining[client] = 0;
	if(race==thisRaceID)
	{
		//SetEntityModel(client, "models/player/slow/slimer/slow.mdl");
		GivePlayerItem(client, "weapon_knife");
		new ClientTeam = GetClientTeam(client);
		switch(ClientTeam)
		{
			case 3:
				W3SetPlayerColor(client,thisRaceID,0,50,255);
			case 2:
				W3SetPlayerColor(client,thisRaceID,255,255,255);
		}
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new race_victim=War3_GetRace(victim);
			
			//evade
			new skill_level_evasion=War3_GetSkillLevel(victim,thisRaceID,SKILL_EVASION);
			if(race_victim==thisRaceID && skill_level_evasion>0 &&!Hexed(victim,false)) 
			{
				if(W3Chance(EvadeChance[skill_level_evasion]) && !IsSkillImmune(attacker))
				{
					W3FlashScreen(victim,RGBA_COLOR_GREEN);
					War3_DamageModPercent(0.0); //NO DAMAMGE
					W3MsgEvaded(victim,attacker);
				}
			}
			
			//orb
			new skill_level_orb=War3_GetSkillLevel(victim,thisRaceID,SKILL_ORB);
			if(race_victim==thisRaceID && skill_level_orb>0 &&!Hexed(victim,false)) 
			{
				if(skill_level_orb>0 && !IsSkillImmune(attacker))
				{
					W3FlashScreen(victim,RGBA_COLOR_GREEN);
					War3_HealToMaxHP(victim,OrbAmount[skill_level_orb]);
				}
			}
			
			//Poison
			new skill_level_poison=War3_GetSkillLevel(victim,thisRaceID,SKILL_POISON);
			if(race_attacker==thisRaceID  && skill_level_poison>0 &&!Hexed(attacker,false)) 
			{
				if(PoisonRemaining[victim]==0 && W3Chance(PoisonChance[skill_level_poison]))
				{
					if(IsSkillImmune(victim))
					{
						W3MsgSkillBlocked(victim,attacker,"Slime Poison");
					}
					else
					{
						W3MsgAttackedBy(victim,"Slime Poison");
						W3MsgActivated(attacker,"Slime Poison");
						PoisonRemaining[victim]=10;
						BeingPoisonedBy[victim]=attacker;
						War3_DealDamage(victim,PoisonInitialDamage,attacker,DMG_BULLET,"slimepoison");
						W3FlashScreen(victim,RGBA_COLOR_RED);
						CreateTimer(1.0,PoisonLoop,GetClientUserId(victim));
					}
				}
			}
		}
	}
}

public Action:PoisonLoop(Handle:timer,any:userid)
{
	new victim = GetClientOfUserId(userid);
	if(PoisonRemaining[victim]>0 && ValidPlayer(BeingPoisonedBy[victim]) && ValidPlayer(victim,true))
	{
		War3_DealDamage(victim,PoisonTrailingDamage,BeingPoisonedBy[victim],DMG_BULLET,"slimepoison");
		PoisonRemaining[victim]--;
		W3FlashScreen(victim,RGBA_COLOR_RED);
		CreateTimer(1.0,PoisonLoop,userid);
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);			
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
	{
		// PrintHintText(client,"%T","Slime Explosion is Passive",client);
		W3MsgUltimateNotActivatable(client);
	}
}

