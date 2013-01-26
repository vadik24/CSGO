/**
* File: War3Source_Sniper_Class.sp
* Description: The Sniper Class race for SourceCraft.
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
new Float:UltTime[5] = { 0.0, 4.25, 4.85, 5.35, 6.0 };
new Float:DamageDivider[5] = { 0.0, 6.75, 6.25, 5.75, 5.25 };
new Float:SniperInvis[5] = { 1.0, 0.55, 0.50, 0.45, 0.40 };
new m_vecBaseVelocity, m_vecVelocity_0, m_vecVelocity_1;
new HaloSprite, BeamSprite;
new Transformed;

new SKILL_SNIPER, SKILL_INVIS, SKILL_LEECH, ULT_TRANSFORM;

public Plugin:myinfo = 
{
	name = "Sniper Class",
	author = "xDr.HaaaaaaaXx",
	description = "The Sniper Class race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

public OnMapStart()
{
	HaloSprite = War3_PrecacheHaloSprite();
	BeamSprite = War3_PrecacheBeamSprite();
}

public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
	m_vecVelocity_0 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[0]" );
	m_vecVelocity_1 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[1]" );
	HookEvent( "player_jump", PlayerJumpEvent );
	
	LoadTranslations("w3s.race.snipclass.phrases");
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRaceT( "snipclass" );
	
	SKILL_SNIPER = War3_AddRaceSkillT( thisRaceID, "Sniper", false );
	SKILL_INVIS = War3_AddRaceSkillT( thisRaceID, "Camouflage", false );
	SKILL_LEECH = War3_AddRaceSkillT( thisRaceID, "RandomMedkit", false );
	ULT_TRANSFORM = War3_AddRaceSkillT( thisRaceID, "Stamania", true );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_TRANSFORM, 5.0, _ );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{			
		// War3_SetMaxHP( client, 500 );
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
		
		new skill_invis = War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS );
		new Float:invis = SniperInvis[skill_invis];
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
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife,weapon_awp,weapon_ssg08,weapon_sg550,weapon_g3sg1,weapon_deagle,weapon_glock,weapon_usp" );
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
		if( War3_GetSkillLevel( client, thisRaceID, SKILL_SNIPER ) == 1 )
			GivePlayerItem( client, "weapon_ssg08" );
		if( War3_GetSkillLevel( client, thisRaceID, SKILL_SNIPER ) == 2 )
			GivePlayerItem( client, "weapon_sg550" );
		if( War3_GetSkillLevel( client, thisRaceID, SKILL_SNIPER ) == 3 )
			GivePlayerItem( client, "weapon_g3sg1" );
		if( War3_GetSkillLevel( client, thisRaceID, SKILL_SNIPER ) == 4 )
			GivePlayerItem( client, "weapon_awp" );
		Transformed = false;
	}
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_leech = War3_GetSkillLevel( attacker, thisRaceID, SKILL_LEECH );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.80 && skill_leech > 0 )
			{
				new Float:start_pos[3];
				new Float:target_pos[3];
				
				GetClientAbsOrigin( attacker, start_pos );
				GetClientAbsOrigin( victim, target_pos );
				
				start_pos[2] += 40;
				target_pos[2] += 40;
				
				TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 35, 1.0, 40.0, 40.0, 0, 40.0, { 50, 50, 255, 255 }, 40 );
				TE_SendToAll();
				
				War3_HealToBuffHP( attacker, RoundToFloor( damage / DamageDivider[skill_leech] ) );
				W3FlashScreen( victim, RGBA_COLOR_RED );
			}
		}
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_TRANSFORM );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_TRANSFORM, true ) )
			{
				StartTransform( client );
				War3_CooldownMGR( client, 11.0, thisRaceID, ULT_TRANSFORM, _, false );
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

Action:StartTransform( client )
{
	new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_TRANSFORM );
	CreateTimer( UltTime[ult_level], EndTransform, client );
	War3_SetBuff( client, fLowGravitySkill, thisRaceID, 0.30 );
	War3_SetBuff( client, fMaxSpeed, thisRaceID, 2.0 );
	Transformed = true;
}

public Action:EndTransform( Handle:timer, any:client )
{
	War3_SetBuff( client, fLowGravitySkill, thisRaceID, 1.0 );
	War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
	Transformed = false;
}

public PlayerJumpEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		new ult = War3_GetSkillLevel( client, race, ULT_TRANSFORM );
		if( ult > 0 && Transformed )
		{
			new Float:velocity[3] = { 0.0, 0.0, 0.0 };
			velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
			velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
			velocity[0] *= 1.6;
			velocity[1] *= 1.6;
			SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
		}
	}
}