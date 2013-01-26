/**
* File: War3Source_Panorama.sp
* Description: The Panorama race for SourceCraft.
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
new thisRaceID, SKILL_WALL, SKILL_DRUG, SKILL_REMATCH, ULT_ZOOM;

// Chance/Data Arrays
new Float:Step[5] = { 12.0, 45.0, 55.0, 100.0, 200.0 };
new Float:RematchChance[5] = { 0.0, 0.25, 0.27, 0.28, 0.46 };
new Float:DrugChance[5] = { 0.0, 0.18, 0.23, 0.27, 0.33 };
new Float:RematchDelay[5] = { 0.0, 3.0, 5.0, 7.0, 8.0 };
new Zoom[5] = { 0, 44, 33, 22, 11 };
new Float:AttackerPos[64][3];
new Float:ClientPos[64][3];
new bool:Zoomed[64];
new bRematched[MAXPLAYERS];

// Sounds
new String:spawn[] = "weapons/physcannon/superphys_launch2.mp3";
new String:death[] = "weapons/physcannon/physcannon_drop.mp3";
new String:spawn1[] = "ambient/atmosphere/cave_hit1.mp3";
new String:zoom[] = "weapons/zoom.mp3";
new String:on[] = "items/nvg_on.mp3";
new String:off[] = "items/nvg_off.mp3";
new String:attack[] = "ambient/wind/wind_snippet2.mp3";

// Other
new GlowSprite;
new FOV;

public Plugin:myinfo = 
{
	name = "War3Source Race - Panorama",
	author = "xDr.HaaaaaaaXx -ZERO <ibis>",
	description = "Panorama race for War3Source.",
	version = "1.0.0.1",
	url = ""
};

public OnPluginStart()
{
	FOV = FindSendPropInfo( "CBasePlayer", "m_iFOV" );
	HookEvent( "player_death", PlayerDeathEvent );
	HookEvent( "round_start", RoundStartEvent );
}

public OnMapStart()
{
	////War3_PrecacheSound( spawn );
	////War3_PrecacheSound( death );
	////War3_PrecacheSound( spawn1 );
	////War3_PrecacheSound( zoom );
	////War3_PrecacheSound( on );
	////War3_PrecacheSound( off );
	////War3_PrecacheSound( attack );
	GlowSprite = PrecacheModel( "models/effects/portalfunnel.mdl" );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Panorama", "panorama" );
	
	SKILL_WALL = War3_AddRaceSkill( thisRaceID, "Climb", "Climb Tall Walls in a single Step", false, 4 );	
	SKILL_DRUG = War3_AddRaceSkill( thisRaceID, "Turn", "Turn the screen to the enemy", false, 4 );	
	SKILL_REMATCH = War3_AddRaceSkill( thisRaceID, "Rematch", "Go back and fight the enemy again", false, 4 );
	ULT_ZOOM = War3_AddRaceSkill( thisRaceID, "Zoom", "Ability to use the zoom on any weapon", true, 4 );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		new skill_wall = War3_GetSkillLevel( client, thisRaceID, SKILL_WALL );
		SetEntPropFloat( client, Prop_Send, "m_flStepSize", Step[skill_wall] );
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		if(ValidPlayer(client))
		{
			SetEntPropFloat( client, Prop_Send, "m_flStepSize", 18.0 ); 
			W3ResetAllBuffRace( client, thisRaceID );
		}
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


public RoundStartEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	for(new i=1;i<=MaxClients;i++)
	{
		bRematched[i] = false;
	}
}


public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		InitPassiveSkills( client );
		//EmitSoundToAll( spawn1, client );
	}
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DRUG );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= DrugChance[skill_level] )
			{
				new Float:pos[3];
				
				GetClientAbsOrigin( victim, pos );
				
				TE_SetupGlowSprite( pos, GlowSprite, 3.0, 0.5, 255 );
				TE_SendToAll();
				
				Drug( victim, 1.0 );
				
				//EmitSoundToAll( attack, attacker );
				//EmitSoundToAll( attack, victim );
			}
		}
	}
}

Action:Drug( client, Float:duration )
{
	if( IsPlayerAlive( client ) )
	{
		new Float:pos[3];
		new Float:angs[3];
		
		GetClientAbsOrigin( client, pos );
		GetClientEyeAngles( client, angs );
		
		angs[2] = 180.0;
		
		TeleportEntity( client, pos, angs, NULL_VECTOR );
		
		CreateTimer( duration, StopDrug, client );
	}
}

public Action:StopDrug( Handle:timer, any:client )
{
	if(ValidPlayer(client))
	{
		new Float:pos[3];
		new Float:angs[3];
		
		GetClientAbsOrigin( client, pos );
		GetClientEyeAngles( client, angs );
	
		angs[2] = 0.0;
	
		TeleportEntity( client, pos, angs, NULL_VECTOR );
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_ZOOM );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_ZOOM, true ) )
			{
				ToggleZoom( client );
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

stock ToggleZoom( client )
{
	if( Zoomed[client] )
	{
		StopZoom( client );
	}
	else
	{
		StartZoom( client );
	}
	//EmitSoundToAll( zoom, client );
}

stock StopZoom( client )
{
	if( Zoomed[client] )
	{
		SetEntData( client, FOV, 0 );
		//EmitSoundToAll( off, client );
		Zoomed[client] = false;
	}
}

stock StartZoom( client )
{
	if ( !Zoomed[client] )
	{
		new zoom_level = War3_GetSkillLevel( client, thisRaceID, ULT_ZOOM );
		SetEntData( client, FOV, Zoom[zoom_level] );
		//EmitSoundToAll( on, client );
		Zoomed[client] = true;
	}
}

public PlayerDeathEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	if( War3_GetRace( client ) == thisRaceID && attacker != client && attacker != 0 )
	{
		new skill_rematch = War3_GetSkillLevel( client, thisRaceID, SKILL_REMATCH );
		if( skill_rematch > 0 && GetRandomFloat( 0.0, 1.0 ) <= RematchChance[skill_rematch] && !bRematched[client])
		{
			GetClientAbsOrigin( client, ClientPos[client] );
			GetClientAbsOrigin( attacker, AttackerPos[attacker] );
			
			bRematched[client] = true;
			
			CreateTimer( RematchDelay[skill_rematch], SpawnClient, client );
			CreateTimer( RematchDelay[skill_rematch], SpawnAttacker, attacker );
			
			PrintToChat( client, "In %.f seconds you respawn same location where you died", RematchDelay[skill_rematch] );
			PrintToChat( attacker, "In %.f seconds Try to beat your last fight", RematchDelay[skill_rematch] );
			
			//EmitSoundToAll( death, client );
			//EmitSoundToAll( death, attacker );
		}
	}
}

public Action:SpawnClient( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		if( War3_GetMaxHP( client ) > GetClientHealth( client ) )
		{
			War3_HealToMaxHP( client, ( War3_GetMaxHP( client ) - GetClientHealth( client ) ) );
		}
		TeleportEntity( client, ClientPos[client], NULL_VECTOR, NULL_VECTOR );
		//EmitSoundToAll( spawn, client );
	}
	else
	{
		War3_SpawnPlayer( client );
		CreateTimer( 0.2, TeleportClient, client );
	}
}

public Action:TeleportClient( Handle:timer, any:client )
{
	TeleportEntity( client, ClientPos[client], NULL_VECTOR, NULL_VECTOR );
	//EmitSoundToAll( spawn, client );
}

public Action:SpawnAttacker( Handle:timer, any:attacker )
{
	if( IsPlayerAlive( attacker ) )
	{
		if( War3_GetMaxHP( attacker ) > GetClientHealth( attacker ) )
		{
			War3_HealToMaxHP( attacker, ( War3_GetMaxHP( attacker ) - GetClientHealth( attacker ) ) );
		}
		TeleportEntity( attacker, AttackerPos[attacker], NULL_VECTOR, NULL_VECTOR );
		//EmitSoundToAll( spawn, attacker );
	}
	else
	{
		War3_SpawnPlayer( attacker );
		CreateTimer( 0.2, TeleportAttacker, attacker );
	}
}

public Action:TeleportAttacker( Handle:timer, any:attacker )
{
	TeleportEntity( attacker, AttackerPos[attacker], NULL_VECTOR, NULL_VECTOR );
	//EmitSoundToAll( spawn, attacker );
}