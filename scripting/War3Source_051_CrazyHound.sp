/**
* File: War3Source_Crazy_Hound.sp
* Description: The Crazy Hound race for SourceCraft.
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
new Float:HoundGravity[5] = { 1.0, 0.80, 0.75, 0.7, 0.6 };
new Float:HoundSpeed[5] = { 1.0, 1.2, 1.3, 1.4, 1.5 };
new Float:DamageMultiplier[5] = { 0.0, 0.30, 0.45, 0.60, 0.70 };
new Float:HoundInvis[5] = { 1.0, 0.54, 0.47, 0.39, 0.33 };
new MaxHP[5] = { -50, -25, 0, 25, 50 };

new SKILL_GRAV, SKILL_SPEED, SKILL_DMG, SKILL_HP, SKILL_INVIS;

public Plugin:myinfo = 
{
	name = "Crazy Hound",
	author = "xDr.HaaaaaaaXx",
	description = "The Crazy Hound race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

public OnPluginStart()
{
	LoadTranslations("w3s.race.crhound.phrases");
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRaceT( "crhound" );
	
	SKILL_GRAV = War3_AddRaceSkillT( thisRaceID, "StrongLegs", false );
	SKILL_SPEED = War3_AddRaceSkillT( thisRaceID, "FourLegs", false );
	SKILL_DMG = War3_AddRaceSkillT( thisRaceID, "ClawsOfTheHound", false );
	SKILL_HP = War3_AddRaceSkillT( thisRaceID, "AdditionalBlood", false );
	SKILL_INVIS = War3_AddRaceSkillT( thisRaceID, "SkillsOfTheChameleon", false );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		new skill_levi = War3_GetSkillLevel( client, thisRaceID, SKILL_GRAV );
		new Float:gravity = HoundGravity[skill_levi];
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, gravity );
		
		new skill_speed = War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED );
		new Float:speed = HoundSpeed[skill_speed];
		War3_SetBuff( client, fMaxSpeed, thisRaceID, speed );
		
		new skill_hp = War3_GetSkillLevel( client, thisRaceID, SKILL_HP );
		SetEntityHealth( client, 50 );
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,MaxHP[skill_hp]);
		if( War3_GetMaxHP( client ) > GetClientHealth( client ) )
		{
			War3_HealToMaxHP( client, ( War3_GetMaxHP( client ) - GetClientHealth( client ) ) );
		}
		
		new skill_invis = War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS );
		new Float:invis = HoundInvis[skill_invis];
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, invis );
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife" );
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
		InitPassiveSkills( client );
	}
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
			if( !Hexed( attacker, false ) && skill_level > 0 )
			{
				War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_level] ), attacker, DMG_BULLET, "crazy_hound_claws" );
				
				W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG );
				W3FlashScreen( victim, RGBA_COLOR_RED );
			}
		}
	}
}