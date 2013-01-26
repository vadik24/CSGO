/**
* File: War3Source_Risen.sp
* Description: The Risen race for SourceCraft.
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
new thisRaceID, SKILL_HP, SKILL_INFECT, SKILL_SPAWN, ULT_SPEED;

// Chance/Data Arrays
new Float:InfectChance[7] = { 0.0, 0.30, 0.40, 0.45, 0.50, 0.55, 0.60 };
new Float:SpawnChance[7] = { 0.0, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40 };
new Float:UltDelay[7] = { 0.0, 20.0, 18.0, 16.0, 14.0, 12.0, 10.0 };
new Float:UltSpeed[7] = { 0.7, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4 };
new HealthADD[7] = { 0, 50, 100, 150, 200, 250, 300 };
new bool:Infected[64];
new InfectedBy[64];

// Sounds
new String:spawn[] = "npc/zombie_poison/pz_call1.mp3";
new String:attack[] = "npc/zombie/claw_strike2.mp3";
new String:ultsnd[] = "npc/zombie/zombie_alert1.mp3";

public Plugin:myinfo = 
{
	name = "War3Source Race - Risen",
	author = "xDr.HaaaaaaaXx",
	description = "The Risen race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

public OnPluginStart()
{
	HookEvent( "player_death", PlayerDeathEvent );
	CreateTimer( 1.0, CalcInfect, _, TIMER_REPEAT );
}

public OnMapStart()
{
	//War3_PrecacheSound( spawn );
	//War3_PrecacheSound( attack );
	//War3_PrecacheSound( ultsnd );
	PrecacheModel( "models/Zombie/Classic.mdl", true );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "The Risen", "therisen" );
	
	SKILL_HP = War3_AddRaceSkill( thisRaceID, "Infected Flesh", "Do more Damage and Disentegrate the enemie", false, 6 );	
	SKILL_INFECT = War3_AddRaceSkill( thisRaceID, "Infectious Bite", "Go a little faster", false, 6 );	
	SKILL_SPAWN = War3_AddRaceSkill( thisRaceID, "Rise from the Grave", "Go back to the exact moment before death", false, 6 );
	ULT_SPEED = War3_AddRaceSkill( thisRaceID, "Ferocious Dash", "Pull the enemy player torward you", true, 6 );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_SPEED, 5.0 );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff( client, fSlow, thisRaceID, 0.7 );
		new hp_level = War3_GetSkillLevel( client, thisRaceID, SKILL_HP );
		if( hp_level > 0 )
		{
			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,HealthADD[hp_level] );
		}
		if( War3_GetMaxHP( client ) > GetClientHealth( client ) )
		{
			War3_HealToMaxHP( client, ( War3_GetMaxHP( client ) - GetClientHealth( client ) ) );
		}
		SetEntityModel( client, "models/Zombie/Classic.mdl" );
	}
}

public OnRaceChanged( client, oldrace,newrace )
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		W3ResetAllBuffRace( client, thisRaceID );
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
		EmitSoundToAll( spawn, client );
	}
	Infected[client] = false;
	InfectedBy[client] = 0;
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
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_INFECT );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= InfectChance[skill_level] && !W3HasImmunity( victim, Immunity_Skills ) )
			{
				new String:NameAttacker[64];
				GetClientName( attacker, NameAttacker, 64 );
				
				new String:NameVictim[64];
				GetClientName( victim, NameVictim, 64 );
				
				if( !Infected[victim] )
				{
					PrintToChat( attacker, "\x05: \x03You have infected \x04%s!!", NameVictim );
					PrintToChat( victim, "\x05: \x03You have been \x05INFECTED \x03by \x04%s's \x03Infectious Bite!", NameAttacker );
				}
				
				Blood( victim );
				
				War3_DealDamage( victim, 5, attacker, DMG_BULLET, "infect" );
				
				EmitSoundToAll( attack, victim );
				EmitSoundToAll( attack, attacker );
				
				Infected[victim] = true;
				InfectedBy[victim] = attacker;
			}
		}
	}
}

public Action:CalcInfect( Handle:timer, any:userid )
{
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( ValidPlayer( i, true ) )
		{
			if( Infected[i] == true )
			{
				if( IsPlayerAlive( i ) && !W3HasImmunity( i, Immunity_Skills ) && ValidPlayer( InfectedBy[i], false ) )
				{
					War3_DealDamage( i, 5, InfectedBy[i], DMG_BULLET, "infect" );
				}
			}
		}
	}
}

public OnW3TakeDmgAll( victim, attacker, Float:damage )
{
	new race = War3_GetRace( victim );
	if( race == thisRaceID )
	{
		CreateTimer( 0.1, PrintHealth, victim );
	}
}

public Action:PrintHealth( Handle:timer, any:client )
{
	PrintHintText( client, "Health: %d", GetClientHealth( client ) );
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_SPEED );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_SPEED, true ) )
			{
				War3_SetBuff( client, fSlow, thisRaceID, 1.0 );
				War3_SetBuff( client, fMaxSpeed, thisRaceID, UltSpeed[ult_level] );
				PrintToChat( client, "\x05: \x03You have activated ferocious dash for 5 seconds." );
				CreateTimer( 5.0, StopSpeed, client );
				EmitSoundToAll( ultsnd, client );
				War3_CooldownMGR( client, UltDelay[ult_level], thisRaceID, ULT_SPEED, false);
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

public Action:StopSpeed( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
		War3_SetBuff( client, fSlow, thisRaceID, 0.7 );
		PrintToChat( client, "\x05: \x03Your ferocious dash has worn off." );
	}
}

public PlayerDeathEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	if( War3_GetRace( client ) == thisRaceID && client != 0 )
	{
		new skill_spawn = War3_GetSkillLevel( client, thisRaceID, SKILL_SPAWN );
		if( skill_spawn > 0 && GetRandomFloat( 0.0, 1.0 ) <= SpawnChance[skill_spawn] )
		{
			CreateTimer( 0.2, Spawn, client );
		}
	}
	Infected[client] = false;
	InfectedBy[client] = 0;
}

public Action:Spawn( Handle:timer, any:client )
{
	if( ValidPlayer( client, false ) )
	{
		War3_SpawnPlayer( client );
		PrintToChat( client, "\x05: \x03You have risen from the grave!" );
	}
}

stock Blood( client )
{
	new Float:Pos[3];
	GetClientAbsOrigin( client, Pos );
	new blood = CreateEntityByName( "env_blood" );
	if( blood )
	{
		DispatchKeyValue( blood, "color", "0" );
		DispatchKeyValue( blood, "amount", "50" );
		DispatchKeyValue( blood, "spawnflags", "109" );
		DispatchSpawn( blood );
		TeleportEntity( blood, Pos, NULL_VECTOR, NULL_VECTOR );
		AcceptEntityInput( blood, "emitblood" );
	}
}