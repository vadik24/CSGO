/**
* File: War3Source_Light_Bender.sp
* Description: The Light Bender race for SourceCraft.
* Author(s): xDr.HaaaaaaaXx
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_stocks>
#include <sdktools_functions>

#include "W3SIncs/War3Source_Interface"

// War3Source stuff
new thisRaceID, SKILL_RED, SKILL_GREEN, SKILL_BLUE, SKILL_SPEED, ULT_DISCO;

new Float:LightGravity[6] = { 1.0, 0.68, 0.60, 0.52, 0.44, 0.36 };
new Float:LightSpeed[6] = { 1.0, 1.24, 1.28, 1.32, 1.36, 1.4 };
new Float:RGBChance[6] = { 0.00, 0.04, 0.08, 0.12, 1.16, 0.20 };
new Float:ClientPos[64][3];
new ClientTarget[64];

new String:UltSnd[] = "ambient/office/zap1.mp3";

new HaloSprite, BeamSprite;

public Plugin:myinfo = 
{
	name = "Light Bender",
	author = "xDr.HaaaaaaaXx",
	description = "The Light Bender race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

public OnPluginStart()
{
	LoadTranslations("w3s.race.lightbender.phrases");
}

public OnMapStart()
{
	HaloSprite = War3_PrecacheHaloSprite();
	BeamSprite = PrecacheModel( "materials/sprites/laserbeam.vmt" );
	
	////War3_PrecacheSound(UltSnd);
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRaceT( "lightbender" );
	
	SKILL_RED = War3_AddRaceSkillT( thisRaceID, "RedLaser", false, 5 );	
	SKILL_GREEN = War3_AddRaceSkillT( thisRaceID, "GreenLaser", false, 5 );	
	SKILL_BLUE = War3_AddRaceSkillT( thisRaceID, "BlueLaser", false, 5 );
	SKILL_SPEED = War3_AddRaceSkillT( thisRaceID, "PhaseShift", false, 5 );
	ULT_DISCO = War3_AddRaceSkillT( thisRaceID, "DiscoBall", true, 1 );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_DISCO, 80.0, _ );

	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff( client, fMaxSpeed, thisRaceID, LightSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, LightGravity[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
		if( War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED ) > 0 )
			War3_ChatMessage( client, "%T", "You are currently in a Phase Shift", client );
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
		InitPassiveSkills( client );
	}
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID && !IsSkillImmune(victim) )
		{
			new bool:red_shot = false;
			new bool:green_shot = false;
			new bool:blue_shot = false;
			new RGB = GetRandomInt(0,2);
			switch (RGB)
			{
				case 0:
					red_shot = true;
				case 1:
					green_shot = true;
				case 2:
					blue_shot = true;
			}
			new skill_red = War3_GetSkillLevel( attacker, thisRaceID, SKILL_RED );
			if( red_shot ){
			if( !Hexed( attacker, false ) && skill_red > 0 && GetRandomFloat( 0.0, 1.0 ) <= RGBChance[skill_red] )
			{
				IgniteEntity( victim, 5.0 );
				
				War3_ChatMessage( victim, "%T", "Red Laser Burn", victim );
				
				new Float:StartPos[3];
				new Float:EndPos[3];
				
				GetClientAbsOrigin( victim, StartPos );
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );

				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 255, 11, 15, 255 }, 1 );
				TE_SendToAll();
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
				
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 255, 11, 15, 255 }, 1 );
				TE_SendToAll();
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
				
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 255, 11, 15, 255 }, 1 );
				TE_SendToAll();
			}
			}
			
			new skill_green = War3_GetSkillLevel( attacker, thisRaceID, SKILL_GREEN );
			if( green_shot ){
			if( !Hexed( attacker, false ) && skill_green > 0 && GetRandomFloat( 0.0, 1.0 ) <= RGBChance[skill_green] )
			{
				War3_ShakeScreen( victim );
				
				War3_ChatMessage( victim, "%T", "Green Laser Shake", victim );
				
				new Float:StartPos[3];
				new Float:EndPos[3];
				
				GetClientAbsOrigin( victim, StartPos );
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );

				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 11, 255, 15, 255 }, 1 );
				TE_SendToAll();
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
				
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 11, 255, 15, 255 }, 1 );
				TE_SendToAll();
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
				
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 11, 255, 15, 255 }, 1 );
				TE_SendToAll();
			}
			}
			
			new skill_blue = War3_GetSkillLevel( attacker, thisRaceID, SKILL_BLUE );
			if( blue_shot ){
			if( !Hexed( attacker, false ) && skill_blue > 0 && GetRandomFloat( 0.0, 1.0 ) <= RGBChance[skill_blue] )
			{
				War3_SetBuff( victim, bStunned, thisRaceID, true );
				CreateTimer( 1.0, StopFreeze, victim );
				
				War3_ChatMessage( victim, "%T", "Blue Laser Freeze", victim );
				
				new Float:StartPos[3];
				new Float:EndPos[3];
				
				GetClientAbsOrigin( victim, StartPos );
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );

				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 15, 11, 255, 255 }, 1 );
				TE_SendToAll();
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
				
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 15, 11, 255, 255 }, 1 );
				TE_SendToAll();
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
				
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 15, 11, 255, 255 }, 1 );
				TE_SendToAll();
			}
			}
		}
	}
}

public Action:StopFreeze( Handle:timer, any:client )
{
	War3_SetBuff( client, bStunned, thisRaceID, false );
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && ValidPlayer( client, true ) )
	{
		new skill_level_red = War3_GetSkillLevel( client, race, SKILL_RED );
		new skill_level_green = War3_GetSkillLevel( client, race, SKILL_GREEN );
		new skill_level_blue = War3_GetSkillLevel( client, race, SKILL_BLUE );
		new skill_level_speed = War3_GetSkillLevel( client, race, SKILL_SPEED );
		new ult_level = War3_GetSkillLevel( client, race, ULT_DISCO );
		if( skill_level_red >= 4 && skill_level_green >= 4 && skill_level_blue >= 4 && skill_level_speed >= 4 )
		{
			if( ult_level > 0 )
			{
				if( War3_SkillNotInCooldown( client, thisRaceID, ULT_DISCO, true ) )
				{
					Disco( client );
				}
			}
			else
			{
				W3MsgUltNotLeveled(client);
			}
		}
		else
		{
			PrintHintText(client,"%T","You must level your skills first!",client);
		}
	}
}

Action:Disco( client )
{
	new Float:besttargetDistance = 2000.0; 
	new Float:posVec[3];
	new Float:otherVec[3];
	ClientTarget[client] = 0;
	new team = GetClientTeam( client );
	
	GetClientAbsOrigin( client, posVec );
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( ValidPlayer( i, true ) && GetClientTeam( i ) != team && IsPlayerAlive( i ) && !W3HasImmunity( i, Immunity_Ultimates ) )
		{
			GetClientAbsOrigin( i, otherVec );
			new Float:dist = GetVectorDistance( posVec, otherVec );
			if( dist < besttargetDistance )
			{
				ClientTarget[client] = i;
				besttargetDistance = GetVectorDistance( posVec, otherVec );
				break;
			}
		}
	}
	
	if( ClientTarget[client] == 0 )
	{
		W3MsgNoTargetFound(client,besttargetDistance);
	}
	else
	{
		new String:NameAttacker[64];
		GetClientName( client, NameAttacker, 64 );
		
		new String:NameVictim[64];
		GetClientName( ClientTarget[client], NameVictim, 64 );
		
		PrintCenterText( client, "%T", "{player} will teleport to you and become a Disco Ball in 3 seconds", client, NameVictim );
		PrintCenterText( ClientTarget[client], "%T", "You will teleport to {player} and become a Disco Ball in 3 seconds", ClientTarget[client], NameAttacker );
		
		//EmitSoundToAll( UltSnd, ClientTarget[client] );
		//EmitSoundToAll( UltSnd, client );
		
		GetClientAbsOrigin( client, ClientPos[client] );
		CreateTimer( 3.0, Teleport, client );
		CreateTimer( 3.1, Freeze, client );
		CreateTimer( 4.1, UnFreeze, client );
		
		
		
		
		
		//War3_ChatMessage( client, "%T", "{player} will teleport to you and become a Disco Ball in 3 seconds", client, NameVictim );
		//War3_ChatMessage( ClientTarget[client], "%T", "You will teleport to {player} and become a Disco Ball in 3 seconds", ClientTarget[client], NameAttacker );
		
		War3_CooldownMGR( client, 30.0, thisRaceID, ULT_DISCO, _, false );
	}
}

public Action:Teleport( Handle:timer, any:client )
{
	ClientPos[client][2] += 64;
	TeleportEntity( ClientTarget[client], ClientPos[client], NULL_VECTOR, NULL_VECTOR );
}

public Action:Freeze( Handle:timer, any:client )
{
	War3_SetBuff( ClientTarget[client], bStunned, thisRaceID, true );
}

public Action:UnFreeze( Handle:timer, any:client )
{
	War3_SetBuff( ClientTarget[client], bStunned, thisRaceID, false );
}
