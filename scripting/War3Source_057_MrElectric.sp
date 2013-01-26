/**
* File: War3Source_Mr_Electric.sp
* Description: The Spider Man race for SourceCraft.
* Author(s): xDr.HaaaaaaaXx
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>
//#include <haaaxfunctions>

#include "W3SIncs/War3Source_Interface"

// War3Source stuff
new thisRaceID;

// Chance/Data Arrays
new Float:ElectricGravity[5] = { 1.0, 0.92, 0.84, 0.76, 0.68 };
new Float:ShockChance[5] = { 0.0, 0.21, 0.25, 0.29, 0.33 };
new Float:BounceChance[5] = { 0.0, 0.15, 0.22, 0.38, 0.47 };
new Float:BounceDuration[5] = { 0.0, 1.5, 2.0, 2.5, 3.0 };
new Float:JumpMultiplier[5] = { 1.0, 3.1, 3.2, 3.3, 3.4 };
new StrikeDamage[5] = { 0, 10, 15, 20, 25 };
new m_vecBaseVelocity, m_vecVelocity_0, m_vecVelocity_1;
new HaloSprite, BeamSprite, AttackSprite1, AttackSprite2, VictimSprite;

new SKILL_ATTACK, SKILL_LONGJUMP, SKILL_BOUNCY, ULT_STRIKE;

public Plugin:myinfo = 
{
	name = "War3Source Race - Mr Electric",
	author = "xDr.HaaaaaaaXx",
	description = "The Mr Electric race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

public OnMapStart()
{
	HaloSprite = War3_PrecacheHaloSprite();
	BeamSprite = War3_PrecacheBeamSprite();
	//AttackSprite1 = PrecacheModel( "materials/effects/strider_pinch_dudv_dx60.vmt" );
	//AttackSprite2 = PrecacheModel( "models/props_lab/airlock_laser.vmt" );
	VictimSprite = PrecacheModel( "materials/sprites/crosshairs.vmt" );
}

public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
	m_vecVelocity_0 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[0]" );
	m_vecVelocity_1 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[1]" );
	HookEvent( "player_jump", PlayerJumpEvent );
	LoadTranslations("w3s.race.electric.phrases");
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRaceT( "electric" );
	
	SKILL_ATTACK = War3_AddRaceSkillT( thisRaceID, "1", false );	
	SKILL_LONGJUMP = War3_AddRaceSkillT( thisRaceID, "2", false );	
	SKILL_BOUNCY = War3_AddRaceSkillT( thisRaceID, "3", false );
	ULT_STRIKE = War3_AddRaceSkillT( thisRaceID, "4", true );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_STRIKE, 60.0,_ );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, ElectricGravity[War3_GetSkillLevel( client, thisRaceID, SKILL_LONGJUMP )] );
		
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
		//War3_SetMaxHP( client, War3_GetMaxHP( client ) + 100 );
		SetEntityRenderFx( client, RENDERFX_FLICKER_FAST );
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		W3ResetAllBuffRace( client, thisRaceID );
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
		InitPassiveSkills( client );
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
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_ATTACK );
			if( skill_level > 0 && !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= ShockChance[skill_level] && !W3HasImmunity( victim, Immunity_Skills ) )
			{
				new Float:velocity[3];
				
				velocity[0] += 0;
				velocity[1] += 0;
				velocity[2] += 300.0;
				
				SetEntDataVector( victim, m_vecBaseVelocity, velocity, true );
				
				War3_ShakeScreen( victim, 3.0, 50.0, 40.0 );
				
				W3FlashScreen( victim, RGBA_COLOR_RED );
				
				new Float:start_pos[3];
				new Float:target_pos[3];
				
				GetClientAbsOrigin( attacker, start_pos );
				GetClientAbsOrigin( victim, target_pos );
				
				start_pos[2] += 20;
				target_pos[2] += 20;
				
				//TE_SetupBeamPoints( start_pos, target_pos, AttackSprite1, HaloSprite, 0, 0, 1.0, 10.0, 5.0, 0, 0.0, { 255, 255, 255, 255 }, 0 );
				//TE_SendToAll();
				
				//TE_SetupBeamPoints( start_pos, target_pos, AttackSprite2, HaloSprite, 0, 0, 1.0, 15.0, 25.0, 0, 0.0, { 255, 255, 255, 255 }, 0 );
				//TE_SendToAll( 2.0 );
			}
		}
	}
}

public PlayerJumpEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		new skill_long = War3_GetSkillLevel( client, race, SKILL_LONGJUMP );
		if( skill_long > 0 )
		{
			new Float:velocity[3] = { 0.0, 0.0, 0.0 };
			velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
			velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
			velocity[0] *= JumpMultiplier[skill_long] * 0.25;
			velocity[1] *= JumpMultiplier[skill_long] * 0.25;
			SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
		}
	}
}

public OnW3TakeDmgBullet( victim, attacker, Float:damage )
{
	if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
	{
		new vteam = GetClientTeam( victim );
		new ateam = GetClientTeam( attacker );
		if( vteam != ateam )
		{
			new race_victim = War3_GetRace( victim );
			new skill_bouncy = War3_GetSkillLevel( victim, thisRaceID, SKILL_BOUNCY );
			if( race_victim == thisRaceID && skill_bouncy > 0 && !Hexed( victim, false ) ) 
			{
				if( GetRandomFloat( 0.0, 1.0 ) <= BounceChance[skill_bouncy] && !W3HasImmunity( attacker, Immunity_Skills ) )
				{
					new Float:pos1[3];
					new Float:pos2[3];
					new Float:localvector[3];
					new Float:velocity1[3];
					new Float:velocity2[3];
					
					GetClientAbsOrigin( attacker, pos1 );
					GetClientAbsOrigin( victim, pos2 );
					
					localvector[0] = pos1[0] - pos2[0];
					localvector[1] = pos1[1] - pos2[1];
					localvector[2] = pos1[2] - pos2[2];
					
					velocity1[0] += 0;
					velocity1[1] += 0;
					velocity1[2] += 300;
					
					velocity2[0] = localvector[0] * ( 100 * 5 );
					velocity2[1] = localvector[1] * ( 100 * 5 );
					
					SetEntDataVector( victim, m_vecBaseVelocity, velocity1, true );
					SetEntDataVector( victim, m_vecBaseVelocity, velocity2, true );
					
					War3_SetBuff( victim, fInvisibilitySkill, thisRaceID, 0.0 );

					CreateTimer( BounceDuration[skill_bouncy], InvisStop, victim );
					
					new Float:pos[3];
				
					GetClientAbsOrigin( victim, pos );
				
					pos[2] += 40;
				
					TE_SetupBeamRingPoint( pos, 40.0, 90.0, VictimSprite, HaloSprite, 0, 0, 0.5, 50.0, 0.0, { 155, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
					TE_SendToAll();
				}
			}
		}
	}
}

public Action:InvisStop( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_STRIKE );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_STRIKE, true ) )
			{
				Strike( client );
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

stock Strike( client )
{
	new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_STRIKE );
	new bestTarget;
	
	if( GetClientTeam( client ) == TEAM_T )
		bestTarget = War3_GetRandomPlayer( "#ct", true, true );
	if( GetClientTeam( client ) == TEAM_CT )
		bestTarget = War3_GetRandomPlayer( "#t", true, true );

	if( bestTarget == 0 )
	{
		W3MsgNoTargetFound(client);
	}
	else
	{
		War3_DealDamage( bestTarget, StrikeDamage[ult_level], client, DMG_BULLET, "electric_strike" );
		War3_HealToMaxHP( client, StrikeDamage[ult_level] );
		
		W3PrintSkillDmgHintConsole( bestTarget, client, War3_GetWar3DamageDealt(), ULT_STRIKE );
		W3FlashScreen( bestTarget, RGBA_COLOR_RED );
		
		War3_CooldownMGR( client, 20.0, thisRaceID, ULT_STRIKE);
		
		new Float:pos[3];
		
		GetClientAbsOrigin( client, pos );
		
		pos[2] += 40;
		
		TE_SetupBeamRingPoint( pos, 20.0, 50.0, BeamSprite, HaloSprite, 0, 0, 3.0, 60.0, 0.0, { 155, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
		TE_SendToAll();
	}
}


/**
 * Get random player. (haaaxfunctions.inc)
 *
 * @param type	      		Team id. CT - #ct, T - #t, All - #a
 * @param check_alive 		Check for alive or not
 * @param check_immunity	Check for ultimate immunity or not
 * @return			  		client
 */
stock War3_GetRandomPlayer( const String:type[] = "#a", bool:check_alive = false, bool:check_immunity = false )
{
	new targettable[MaxClients];
	new target = 0;
	new bool:all;
	new x = 0;
	new team;
	if( StrEqual( type, "#t" ) )
	{
		team = TEAM_T;
		all = false;
	}
	else if( StrEqual( type, "#ct" ) )
	{
		team = TEAM_CT;
		all = false;
	}
	else if( StrEqual( type, "#a" ) )
	{
		team = 0;
		all = true;
	}
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( i > 0 && i <= MaxClients && IsClientConnected( i ) && IsClientInGame( i ) )
		{
			if( check_alive && !IsPlayerAlive( i ) )
				continue;
			if( check_immunity && W3HasImmunity( i, Immunity_Ultimates ) )
				continue;
			if( !all && GetClientTeam( i ) != team )
				continue;
			targettable[x] = i;
			x++;
		}
	}
	for( new y = 0; y <= x; y++ )
	{
		if( target == 0 )
		{
			target = targettable[GetRandomInt( 0, x - 1 )];
		}
		else if( target != 0 && target > 0 )
		{
			return target;
		}
	}
	return 0;
}