/**
* File: War3Source_Vagabond.sp
* Description: The Vagabond race for SourceCraft.
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
new thisRaceID, SKILL_SPEED, SKILL_SCOUT, SKILL_LOWGRAV, ULT_INVIS_TELE;

// Chance/Data Arrays
new col1[4], col2[4], col3[4], col4[4], col5[4], col6[4], col7[4], col8[4], col9[4];
new Float:VagabondGravity[5] = { 1.0, 0.85, 0.7, 0.55, 0.4 };
new Float:VagabondSpeed[5] = { 1.0, 1.10, 1.20, 1.30, 1.40 };
// new Float:DamageChanse[5] = { 0.0, 0.28, 0.44, 0.60, 0.75 };
new Float:DamageChanse[5] = { 0.0, 0.10, 0.20, 0.30, 0.40 };
new Float:PushForce[5] = { 0.0, 0.7, 1.1, 1.3, 1.7 };
new Float:UltDelay[5] = { 0.0, 15.0, 12.0, 11.0, 10.0 };
new bool:bIsInvisible[MAXPLAYERS];
new String:map[64];

// Sounds
new String:UltOutstr[] = "weapons/physcannon/physcannon_claws_close.mp3";
new String:UltInstr[] = "weapons/physcannon/physcannon_claws_open.mp3";
new String:spawnsound[] = "ambient/atmosphere/cave_hit2.mp3";

// Other
new HaloSprite, BeamSprite, SteamSprite;
new m_vecBaseVelocity;

public Plugin:myinfo = 
{
	name = "Vagabond",
	author = "xDr.HaaaaaaaXx",
	description = "The Vagabond race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
	col1[3] = 255;
	col2[3] = 255;
	col3[3] = 255;
	col4[3] = 255;
	col5[3] = 255;
	col6[3] = 255;
	col7[3] = 255;
	col8[3] = 255;
	col9[3] = 255;
	
	LoadTranslations("w3s.race.vagabond.phrases");
}

public OnMapStart()
{
	HaloSprite = War3_PrecacheHaloSprite();
	BeamSprite = PrecacheModel( "materials/sprites/laserbeam.vmt" );
	SteamSprite = PrecacheModel( "sprites/steam1.vmt" );
	////War3_PrecacheSound( UltInstr );
	////War3_PrecacheSound( UltOutstr );
	////War3_PrecacheSound( spawnsound );
	GetCurrentMap( map, 63 );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRaceT( "vagabond" );
	
	SKILL_SPEED = War3_AddRaceSkillT( thisRaceID, "Adrinaline", false );	
	SKILL_SCOUT = War3_AddRaceSkillT( thisRaceID, "Scout", false );	
	SKILL_LOWGRAV = War3_AddRaceSkillT( thisRaceID, "Levitation", false );
	ULT_INVIS_TELE = War3_AddRaceSkillT( thisRaceID, "CompleteInvisibility", true );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_INVIS_TELE, 5.0, _ );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		new skilllevel_speed = War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED );
		new Float:speed = VagabondSpeed[skilllevel_speed];
		War3_SetBuff( client, fMaxSpeed, thisRaceID, speed );
		
		new skilllevel_levi = War3_GetSkillLevel( client, thisRaceID, SKILL_LOWGRAV );
		new Float:gravity = VagabondGravity[skilllevel_levi];
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, gravity );
		War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
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
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife,weapon_ssg08" );
		if( IsPlayerAlive( client ) )
		{
			GivePlayerItem( client, "weapon_ssg08" );
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
	StopInvis( client );
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		GivePlayerItem( client, "weapon_ssg08" );
		InitPassiveSkills(client);
		//EmitSoundToAll( spawnsound, client );
	}
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_SCOUT );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= DamageChanse[skill_level] )
			{
				new String:wpnstr[32];
				GetClientWeapon( attacker, wpnstr, 32 );
				if( StrEqual( wpnstr, "weapon_ssg08" ) )
				{
					col1[0] = GetRandomInt( 0, 255 );
					col1[1] = GetRandomInt( 0, 255 );
					col1[2] = GetRandomInt( 0, 255 );
	
					col2[0] = GetRandomInt( 0, 255 );
					col2[1] = GetRandomInt( 0, 255 );
					col2[2] = GetRandomInt( 0, 255 );
	
					col3[0] = GetRandomInt( 0, 255 );
					col3[1] = GetRandomInt( 0, 255 );
					col3[2] = GetRandomInt( 0, 255 );
	
					col4[0] = GetRandomInt( 0, 255 );
					col4[1] = GetRandomInt( 0, 255 );
					col4[2] = GetRandomInt( 0, 255 );
	
					col5[0] = GetRandomInt( 0, 255 );
					col5[1] = GetRandomInt( 0, 255 );
					col5[2] = GetRandomInt( 0, 255 );
	
					col6[0] = GetRandomInt( 0, 255 );
					col6[1] = GetRandomInt( 0, 255 );
					col6[2] = GetRandomInt( 0, 255 );
	
					col7[0] = GetRandomInt( 0, 255 );
					col7[1] = GetRandomInt( 0, 255 );
					col7[2] = GetRandomInt( 0, 255 );
	
					col8[0] = GetRandomInt( 0, 255 );
					col8[1] = GetRandomInt( 0, 255 );
					col8[2] = GetRandomInt( 0, 255 );
	
					col9[0] = GetRandomInt( 0, 255 );
					col9[1] = GetRandomInt( 0, 255 );
					col9[2] = GetRandomInt( 0, 255 );
					
					new Float:start_pos[3];
					new Float:target_pos[3];
					
					GetClientAbsOrigin( attacker, start_pos );
					GetClientAbsOrigin( victim, target_pos );
					
					target_pos[2] += 40;
					
					// 1
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;
					
					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 30.0, 10.0, 10.0, 0, 0.0, col1, 40 );
					TE_SendToAll();
					
					// 2
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 30.0, 10.0, 10.0, 0, 0.0, col2, 40 );
					TE_SendToAll();
					
					// 3
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 30.0, 10.0, 10.0, 0, 0.0, col3, 40 );
					TE_SendToAll();
					
					// 4
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 30.0, 10.0, 10.0, 0, 0.0, col4, 40 );
					TE_SendToAll();
					
					// 5
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 30.0, 10.0, 10.0, 0, 0.0, col5, 40 );
					TE_SendToAll();
					
					// 6
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 30.0, 10.0, 10.0, 0, 0.0, col6, 40 );
					TE_SendToAll();
					
					// 7
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 30.0, 10.0, 10.0, 0, 0.0, col7, 40 );
					TE_SendToAll();
					
					// 8
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 30.0, 10.0, 10.0, 0, 0.0, col8, 40 );
					TE_SendToAll();
					
					// 9
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[2] += 40;
					target_pos[2] += 5;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 30.0, 10.0, 10.0, 0, 0.0, col9, 40 );
					TE_SendToAll();
					
					if( !W3HasImmunity( victim, Immunity_Skills ) && !bIsInvisible[attacker] )
					{
						War3_DealDamage( victim, damage, attacker, DMG_BULLET, "vagabond_crit" );
						W3FlashScreen( victim, RGBA_COLOR_RED );

						W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), DMG_BULLET );
					}
				}
			}
		}
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	new userid = GetClientUserId( client );
	if( race == thisRaceID && pressed && userid > 1 && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_INVIS_TELE );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_INVIS_TELE, true ) )
			{
				if( !bIsInvisible[client] )
				{
					ToggleInvisibility( client );
					TeleportPlayer( client );
					War3_CooldownMGR( client, 0.5, thisRaceID, ULT_INVIS_TELE, _, false );
				}
				else
				{
					ToggleInvisibility( client );
					War3_CooldownMGR( client, UltDelay[ult_level], thisRaceID, ULT_INVIS_TELE, _, false );
				}
				
				new Float:pos[3];
				
				GetClientAbsOrigin( client, pos );
				
				pos[2] += 50;
				
				TE_SetupGlowSprite( pos, SteamSprite, 1.0, 2.5, 130 );
				TE_SendToAll();
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

stock StopInvis( client )
{
	if( bIsInvisible[client] )
	{
		bIsInvisible[client] = false;
		War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
		//EmitSoundToAll( UltOutstr, client );
	}
}

stock StartInvis( client )
{
	if ( !bIsInvisible[client] )
	{
		bIsInvisible[client] = true;
		CreateTimer( 1.0, StartStop, client );
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.0 );
		//EmitSoundToAll( UltInstr, client );
	}
}

public Action:StartStop( Handle:timer, any:client )
{
	War3_SetBuff( client, bNoMoveMode, thisRaceID, true );
}

stock ToggleInvisibility( client )
{
	if( bIsInvisible[client] )
	{
		StopInvis( client );
	}
	else
	{
		StartInvis( client );
	}
}

Action:TeleportPlayer( client )
{
	if( client > 0 && IsPlayerAlive( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_INVIS_TELE );
		new Float:startpos[3];
		new Float:endpos[3];
		new Float:localvector[3];
		new Float:velocity[3];
		
		GetClientAbsOrigin( client, startpos );
		War3_GetAimEndPoint( client, endpos );
		
		localvector[0] = endpos[0] - startpos[0];
		localvector[1] = endpos[1] - startpos[1];
		localvector[2] = endpos[2] - startpos[2];
		
		velocity[0] = localvector[0] * PushForce[ult_level];
		velocity[1] = localvector[1] * PushForce[ult_level];
		velocity[2] = localvector[2] * PushForce[ult_level];
		
		SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
	}
}