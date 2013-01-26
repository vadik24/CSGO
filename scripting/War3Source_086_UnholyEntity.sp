/**
 * File: War3Source_Unholy_Entity.sp
 * Description: The Unholy Entity race for War3Source.
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
#include <haaaxfunctions>
new thisRaceID;

//skill 1
new Float:EntSpeed[6] = { 1.0, 1.16, 1.20, 1.24, 1.28, 1.32 };

//skill 2
new Float:BuryChance[6] = { 0.0, 0.13, 0.15, 0.17, 0.19, 0.22 };

//skill 3
new Float:AvangeChance[6] = { 0.0, 0.5, 0.55, 0.60, 0.65, 0.99 };

//ultimate
new Float:UltDelay[6] = { 0.0, 45.0, 40.0, 35.0, 30.0, 25.0 };

new SKILL_SPEED, SKILL_BURY, SKILL_AVENGE, ULT_TRADE;
new Float:Ult_ClientPos[64][3];
new Float:Ult_EnemyPos[64][3];
new Float:Client_Pos[64][3];
new Ult_BestTarget[64];
new BestTarget[64];

new String:Sound[] = { "ambient/atmosphere/cave_hit5.mp3" };
new BeamSprite, HaloSprite, Ult_BeamSprite1, Ult_BeamSprite2;

public Plugin:myinfo = 
{
	name = "War3Source Race - Unholy Entity",
	author = "xDr.HaaaaaaaXx",
	description = "The Unholy Entity race for War3Source.",
	version = "1.0.0.1",
	url = ""
};

public OnPluginStart()
{
	HookEvent( "player_death", PlayerDeathEvent );
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==204){

	thisRaceID = War3_CreateNewRace( "Unholy Entity", "unholyent" );
	
	SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Swift", "Run Fast", false, 4 );
	SKILL_BURY = War3_AddRaceSkill( thisRaceID, "Bury", "Bury your enemy Alive half way under ground", false, 4 );
	SKILL_AVENGE = War3_AddRaceSkill( thisRaceID, "Avenge", "Call apon a teammate to avenge your death", false, 4 );
	ULT_TRADE = War3_AddRaceSkill( thisRaceID,  "Possessor", "Trade places with a randome enemy", true, 4 );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_TRADE, 20.0, _);
	
	War3_CreateRaceEnd( thisRaceID );
	}
}

public OnMapStart()
{
	BeamSprite = PrecacheModel( "sprites/bluelight1.vmt" );
	HaloSprite = War3_PrecacheHaloSprite();
	Ult_BeamSprite1 = PrecacheModel( "materials/effects/ar2_altfire1.vmt" );
	Ult_BeamSprite2 = PrecacheModel( "models/alyx/pupil_r.vmt" );
	//War3_PrecacheSound( Sound );
}

public InitPassiveSkills( client )
{
	if( ValidPlayer( client, true ) )
	{
		if( War3_GetRace( client ) == thisRaceID )
		{
			War3_SetBuff( client, fMaxSpeed, thisRaceID, EntSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
		}
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if( ValidPlayer( client, true ) )
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
}

public OnSkillLevelChanged( client, race, skill, newskilllevel )
{
	if( ValidPlayer( client, true ) )
	{
		InitPassiveSkills( client );
	}
}

public OnWar3EventSpawn( client )
{
	if( ValidPlayer( client, true ) )
	{
		new race = War3_GetRace( client );
		if( race == thisRaceID )
		{
			InitPassiveSkills(client);
			EmitSoundToAll( Sound, client );
		}
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
			new skill_bury = War3_GetSkillLevel( attacker, thisRaceID, SKILL_BURY );
			if( !Hexed( attacker, false ) && skill_bury > 0 && GetRandomFloat( 0.0, 1.0 ) <= BuryChance[skill_bury] )
			{
				new Float:attacker_pos[3];
				new Float:victim_pos[3];

				GetClientAbsOrigin( attacker, attacker_pos );
				GetClientAbsOrigin( victim, victim_pos );
				
				victim_pos[2] -= 40;
				
				TeleportEntity( victim, victim_pos, NULL_VECTOR, NULL_VECTOR );

				victim_pos[2] += 40;

				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 165, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[1] += 70;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[1] += 70;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				GetClientAbsOrigin( attacker, attacker_pos );
				GetClientAbsOrigin( victim, victim_pos );
				
				attacker_pos[2] += 40;
				victim_pos[2] += 40;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[1] += 50;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[0] += 50;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				GetClientAbsOrigin( attacker, attacker_pos );
				GetClientAbsOrigin( victim, victim_pos );
				
				attacker_pos[2] += 140;
				victim_pos[2] += 40;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[1] += 170;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[0] += 170;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				GetClientAbsOrigin( attacker, attacker_pos );
				GetClientAbsOrigin( victim, victim_pos );
				
				attacker_pos[2] += 1140;
				victim_pos[2] += 40;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[1] += 5;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[0] += 3;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				GetClientAbsOrigin( attacker, attacker_pos );
				GetClientAbsOrigin( victim, victim_pos );
				
				attacker_pos[2] += 20;
				victim_pos[2] += 20;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[1] += 30;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
				
				attacker_pos[0] += 30;
				
				TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 5.0, 10.0, 10.0, 0, 0.0, { 215, 11, 167, 255 }, 0 );
				TE_SendToAll();
			}
		}
	}
}

public PlayerDeathEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	if( ValidPlayer( client, true ) )
	{
		if( War3_GetRace( client ) == thisRaceID )
		{
			new skill_avange = War3_GetSkillLevel( client, thisRaceID, SKILL_AVENGE );
			if( skill_avange > 0 && GetRandomFloat( 0.0, 1.0 ) <= AvangeChance[skill_avange] )
			{
				new Float:TeamMate_Pos[3];
				if( GetClientTeam( client ) == TEAM_T )
					BestTarget[client] = War3_GetRandomPlayer( "#ct", true, true );
				if( GetClientTeam( client ) == TEAM_CT )
					BestTarget[client] = War3_GetRandomPlayer( "#t", true, true );
				
				GetClientAbsOrigin( client, Client_Pos[client] );
				GetClientAbsOrigin( BestTarget[client], TeamMate_Pos );
				
				if( BestTarget[client] == 0 )
				{
					PrintHintText( client, "No Target Found" );
				}
				else
				{
					CreateTimer( 6.0, AvangeTeleport, client );
					
					new String:Name[64];
					GetClientName( BestTarget[client], Name, 64 );
					
					PrintToChat( client, "\x05: \x03You call apon \x04%s \x03to Avenge your Death!", Name );
					PrintToChat( BestTarget[client], "\x05: \x03A teammate has been slayed! You have been summuned to avenge his death!" );
					
					EmitSoundToAll( Sound, client );
					EmitSoundToAll( Sound, BestTarget[client] );
				}
			}
		}
	}
}

public Action:AvangeTeleport( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) && ValidPlayer( BestTarget[client], true ) )
	{
		TeleportEntity( BestTarget[client], Client_Pos[client], NULL_VECTOR, NULL_VECTOR );
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( ValidPlayer( client, true ) )
	{
		if( race == thisRaceID && pressed && IsPlayerAlive( client ) )
		{
			new ult_level = War3_GetSkillLevel( client, race, ULT_TRADE );
			if( ult_level > 0 )
			{
				if( War3_SkillNotInCooldown( client, thisRaceID, ULT_TRADE, true ) )
				{
					Trade( client );
					War3_CooldownMGR( client, UltDelay[ult_level], thisRaceID, ULT_TRADE, _, false );
				}
			}
			else
			{
				W3MsgUltNotLeveled( client );
			}
		}
	}
}

stock Trade( client )
{
	if( GetClientTeam( client ) == TEAM_T )
		Ult_BestTarget[client] = War3_GetRandomPlayer( "#ct", true, true );
	if( GetClientTeam( client ) == TEAM_CT )
		Ult_BestTarget[client] = War3_GetRandomPlayer( "#t", true, true );

	if( Ult_BestTarget[client] == 0 )
	{
		PrintHintText( client, "No Target Found" );
	}
	else
	{
		GetClientAbsOrigin( Ult_BestTarget[client], Ult_EnemyPos[client] );
		GetClientAbsOrigin( client, Ult_ClientPos[client] );
		
		new String:Name[64];
		GetClientName( Ult_BestTarget[client], Name, 64 );
	
		EmitSoundToAll( Sound, client );
		EmitSoundToAll( Sound, Ult_BestTarget[client] );
		
		PrintToChat( client, "\x05: \x03You will trade places with \x04%s \x03in three seconds!", Name );
		
		CreateTimer( 3.0, TradeDelay, client );
		
		new Float:BeamPos[3];
		BeamPos[0] = Ult_ClientPos[client][0];
		BeamPos[1] = Ult_ClientPos[client][1];
		BeamPos[2] = Ult_ClientPos[client][2] + 40.0;
		
		TE_SetupBeamRingPoint( BeamPos, 950.0, 190.0, Ult_BeamSprite1, HaloSprite, 0, 0, 3.0, 150.0, 0.0, { 115, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
		TE_SendToAll();

		TE_SetupBeamRingPoint( BeamPos, 950.0, 190.0, Ult_BeamSprite2, HaloSprite, 0, 0, 3.0, 150.0, 0.0, { 115, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
		TE_SendToAll();
	}
}

public Action:TradeDelay( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) && Ult_BestTarget[client] )
	{
		TeleportEntity( Ult_BestTarget[client], Ult_ClientPos[client], NULL_VECTOR, NULL_VECTOR );
		TeleportEntity( client, Ult_EnemyPos[client], NULL_VECTOR, NULL_VECTOR );
	}
}