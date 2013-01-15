/**
* File: War3Source_AVATAR.sp
* Description: The Last Airbender.
* Author(s): xDr.HaaaaaaaXx
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_stocks>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>

#include "W3SIncs/War3Source_Interface"

// War3Source stuff
new thisRaceID, SKILL_FIRE, SKILL_WATER, SKILL_EARTH, ULT_WIND;

// Chance/Data Arrays
// skill 1
new Float:FireChance[5] = { 0.0, 0.1, 0.15, 0.2, 0.3 };

// skill 2
new Float:SlowChance[5] = { 0.0, 0.1, 0.15, 0.2, 0.3 };
new Float:SlowSpeed[5] = { 1.0, 0.75, 0.65, 0.60, 0.55 };
new Float:SlowDuration[5] = { 0.0, 0.5, 1.0, 1.5, 2.0 };

// skill 3
new Float:QuakeChance[5] = { 0.0, 0.1, 0.15, 0.2, 0.3 };

// skill 4
new Float:Duration[5] = { 0.0, 4.0, 6.0, 8.0, 10.0 };

// Sounds
new String:UltSound[] = "ambient/explosions/explode_7.mp3";

// Other
new TPBeamSprite, SplodeCardSprite, YellowFlareSprite;

public Plugin:myinfo = 
{
	name = "War3Source Race - AVATAR",
	author = "xDr.HaaaaaaaXx",
	description = "The Last Airbender.",
	version = "1.0.0.0",
	url = ""
};

public OnMapStart()
{	
	TPBeamSprite = PrecacheModel( "sprites/tp_beam001.vmt" );
	SplodeCardSprite = PrecacheModel( "models/effects/splodecard2_sheet.vmt" );
	YellowFlareSprite = PrecacheModel( "sprites/yellowflare.vmt" );
	//War3_PrecacheSound( UltSound );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "AVATAR", "avatar" );
	
	SKILL_FIRE = War3_AddRaceSkill( thisRaceID, "Fire", "Fire", false );
	SKILL_WATER = War3_AddRaceSkill( thisRaceID, "Water", "Water", false );
	SKILL_EARTH = War3_AddRaceSkill( thisRaceID, "Earth", "Earth", false );
	ULT_WIND = War3_AddRaceSkill( thisRaceID, "Wind", "Wind", true );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_WIND, 15.0);
	
	War3_CreateRaceEnd( thisRaceID );
}

public OnRaceChanged( client, oldrace,newrace )
{
	if( newrace != thisRaceID )
	{
		W3ResetAllBuffRace( client, thisRaceID );
	}
	else
	{
	}
}

public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_fire = War3_GetSkillLevel( attacker, thisRaceID, SKILL_FIRE );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= FireChance[skill_fire] )
			{
				if( !W3HasImmunity( victim, Immunity_Skills ) )
				{
					IgniteEntity( victim, 2.0 );
					
					new Float:attacker_pos[3];
					new Float:victim_pos[3];
					
					GetClientAbsOrigin( attacker, attacker_pos );
					GetClientAbsOrigin( victim, victim_pos );
					
					attacker_pos[2] += 40;
					victim_pos[2] += 40;
					
					TE_SetupBeamPoints( attacker_pos, victim_pos, YellowFlareSprite, YellowFlareSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 255, 0, 0, 255 }, 0 );
					TE_SendToAll();
				}
			}
		}
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_earth = War3_GetSkillLevel( attacker, thisRaceID, SKILL_EARTH );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= QuakeChance[skill_earth] )
			{
				if( !W3HasImmunity( victim, Immunity_Skills ) )
				{
					War3_ShakeScreen( victim );
					
					new Float:attacker_pos[3];
					new Float:victim_pos[3];
					
					GetClientAbsOrigin( attacker, attacker_pos );
					GetClientAbsOrigin( victim, victim_pos );
					
					attacker_pos[2] += 40;
					victim_pos[2] += 40;
					
					TE_SetupBeamPoints( attacker_pos, victim_pos, YellowFlareSprite, YellowFlareSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 0, 255, 0, 255 }, 0 );
					TE_SendToAll();
				}
			}
		}
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_water = War3_GetSkillLevel( attacker, thisRaceID, SKILL_WATER );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= SlowChance[skill_water] )
			{
				if( !W3HasImmunity( victim, Immunity_Skills ) )
				{
					War3_SetBuff( victim, fSlow, thisRaceID, SlowSpeed[skill_water] );
					
					CreateTimer( SlowDuration[skill_water], StopSlow, victim );
					
					new Float:attacker_pos[3];
					new Float:victim_pos[3];
					
					GetClientAbsOrigin( attacker, attacker_pos );
					GetClientAbsOrigin( victim, victim_pos );
					
					attacker_pos[2] += 40;
					victim_pos[2] += 40;
					
					TE_SetupBeamPoints( attacker_pos, victim_pos, YellowFlareSprite, YellowFlareSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 0, 0, 255, 255 }, 0 );
					TE_SendToAll();
				}
			}
		}
	}
}

public Action:StopSlow( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fSlow, thisRaceID, 1.0 );
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_WIND );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_WIND, true ) )
			{
				EmitSoundToAll( UltSound, client );
				
				PrintToChat( client, "\x03 : Got a \x04speed boost \x03for \x04%f seconds.", Duration[ult_level] );
				
				War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.4 );
				War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.0 );
				
				new Float:pos[3];
				
				GetClientAbsOrigin( client, pos );
				
				pos[2] += 340;
				
				TE_SetupBeamFollow( client, TPBeamSprite, TPBeamSprite, 3.0, 3.0, 3.0, 50, { 255, 0, 25, 255 } );
				TE_SendToAll();
				
				TE_SetupBeamRingPoint( pos, 550.0, 100.0, SplodeCardSprite, SplodeCardSprite, 0, 0, 5.0, 750.0, 0.0, { 155, 115, 100, 200 }, 30, FBEAM_ISACTIVE );
				TE_SendToAll();
				
				CreateTimer( 0.5, InvisStop1, client );
				CreateTimer( 1.0, InvisStop2, client );
				CreateTimer( 1.5, InvisStop3, client );
				CreateTimer( 2.0, InvisStop4, client );
				CreateTimer( 2.5, InvisStop5, client );
				CreateTimer( 3.0, InvisStop6, client );
				CreateTimer( 3.5, InvisStop7, client );
				CreateTimer( 4.0, InvisStop8, client );
				CreateTimer( 4.5, InvisStop9, client );
				CreateTimer( 5.0, InvisStop10, client );
				CreateTimer( 5.5, InvisStop11, client );
				CreateTimer( 6.0, InvisStop12, client );
				CreateTimer( Duration[ult_level], SpeedStop, client );
				CreateTimer( ( Duration[ult_level] - 1.0 ), SpeedStopWarning, client );
				
				War3_CooldownMGR( client, ( Duration[ult_level] + 10.0 ), thisRaceID, ULT_WIND, false);
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

public Action:SpeedStop( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
	}
}

public Action:SpeedStopWarning( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		PrintToChat( client, "\x03 : Becoming \x04slow \x03again ..." );
	}
}

public Action:InvisStop1( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.04 );
	}
}

public Action:InvisStop2( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.1 );
	}
}

public Action:InvisStop3( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.13 );
	}
}

public Action:InvisStop4( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.23 );
	}
}

public Action:InvisStop5( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.31 );
	}
}

public Action:InvisStop6( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.45 );
	}
}

public Action:InvisStop7( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.53 );
	}
}

public Action:InvisStop8( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.64 );
	}
}

public Action:InvisStop9( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.72 );
	}
}

public Action:InvisStop10( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.78 );
	}
}

public Action:InvisStop11( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.86 );
	}
}

public Action:InvisStop12( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
	}
}