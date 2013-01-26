/**
* File: War3Source_Aura_Master.sp
* Description: The Aura Master race for SourceCraft.
* Author(s): xDr.HaaaaaaaXx 
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>

#include "W3SIncs/War3Source_Interface"

// War3Source stuff
new thisRaceID;

// Chance/Data Arrays
new Float:AuraSpeed[5] = { 1.0, 1.24, 1.28, 1.32, 1.36 };
new Float:AuraGravity[5] = { 1.0, 0.6, 0.52, 0.44, 0.36 };
new Float:AuraPushChance[5] = { 0.0, 0.05, 0.10, 0.15, 0.20 };
new m_vecBaseVelocity;
new HaloSprite, BeamSprite;

new SKILL_SPEED, SKILL_LOWGRAV, SKILL_PUSH, SKILL_LEECH;

public Plugin:myinfo = 
{
	name = "Aura Master",
	author = "xDr.HaaaaaaaXx",
	description = "The Aura Master race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

public OnMapStart()
{
	BeamSprite = War3_PrecacheBeamSprite();
	HaloSprite = War3_PrecacheHaloSprite();
}

public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
	
	LoadTranslations("w3s.race.auramaster.phrases");
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRaceT( "auramaster" );
	
	SKILL_SPEED = War3_AddRaceSkillT( thisRaceID, "UnholyAura", false );	
	SKILL_LOWGRAV = War3_AddRaceSkillT( thisRaceID, "GravityAura", false );	
	SKILL_PUSH = War3_AddRaceSkillT( thisRaceID, "ExellenceAura", false );
	SKILL_LEECH = War3_AddRaceSkillT( thisRaceID, "AncientAura", false );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		new skilllevel_speed = War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED );
		new Float:speed = AuraSpeed[skilllevel_speed];
		War3_SetBuff( client, fMaxSpeed, thisRaceID, speed );
		
		new skilllevel_levi = War3_GetSkillLevel( client, thisRaceID, SKILL_LOWGRAV );
		new Float:gravity = AuraGravity[skilllevel_levi];
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, gravity );
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{	
		if( IsPlayerAlive( client ) )
		{
			InitPassiveSkills( client );
		}
	}
}

public OnSkillLevelChanged( client, race, skill, newskilllevel )
{
	InitPassiveSkills( client );
}

public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		InitPassiveSkills(client);
	}
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_push_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_PUSH );
			if(!Hexed(attacker, false) && W3Chance(AuraPushChance[skill_push_level]) && !IsSkillImmune(victim))
			{
				new Float:velocity[3];
				velocity[2] += 600.0;
				SetEntDataVector( victim, m_vecBaseVelocity, velocity, true );
				W3FlashScreen( victim, RGBA_COLOR_RED );
			}

			new skill_leech = War3_GetSkillLevel( attacker, thisRaceID, SKILL_LEECH );
			if(!Hexed(attacker, false) && W3Chance(0.45) && skill_leech > 0 && !IsSkillImmune(victim))
			{
				new Float:start_pos[3];
				new Float:target_pos[3];
				
				GetClientAbsOrigin( attacker, start_pos );
				GetClientAbsOrigin( victim, target_pos );
				
				TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 35, 1.0, 40.0, 40.0, 0, 40.0, { 255, 0, 0, 255 }, 40 );
				TE_SendToAll();
				
				War3_HealToBuffHP( attacker, damage / 2 );
				W3FlashScreen( victim, RGBA_COLOR_RED );
			}
		}
	}
}