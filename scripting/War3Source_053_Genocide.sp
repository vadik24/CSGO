/**
* File: War3Source_Genocide.sp
* Description: The Genocide race for SourceCraft.
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
new thisRaceID, SKILL_REGEN, SKILL_INVIS, SKILL_DMG, SKILL_GRENADE, ULT_DEJAVU;

// Chance/Data Arrays
new Float:GenocideDMGChance[5] = { 0.0, 0.18, 0.23, 0.27, 0.33 };
new Float:GenocideUltDuration[5] = { 0.0, 3.0, 4.0, 5.0, 6.0 };
new Float:HealthMultiplier[5] = { 0.0, 0.16, 0.19, 0.22, 0.25 };
new Float:GenocideInvis[5] = { 1.0, 0.50, 0.45, 0.40, 0.35 };
new Float:DamageMultiplier[5] = { 0.0, 1.9, 2.1, 2.4, 4.4 };
new Float:ClientPos[64][3];
new Float:ClientAng[64][3];
new bool:used[64];
new Health[64];

// Sounds
new String:grenade[] = "weapons/hegrenade/explode3.mp3";

// Other
new HaloSprite, BeamSprite, RingBeam, FlameSprite;

public Plugin:myinfo = 
{
	name = "Genocide",
	author = "xDr.HaaaaaaaXx",
	description = "The Vagabond race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

public OnPluginStart()
{
	HookEvent( "player_hurt", PlayerHurtEvent );
	
	LoadTranslations("w3s.race.genocide.phrases");
}

public OnMapStart()
{
	HaloSprite = War3_PrecacheHaloSprite();
	BeamSprite = War3_PrecacheBeamSprite();
	RingBeam = PrecacheModel( "materials/sprites/smoke.vmt" );
	//FlameSprite = PrecacheModel( "materials/sprites/flatflame.vmt" );
	////War3_PrecacheSound( grenade );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRaceT( "genocide" );
	
	SKILL_REGEN = War3_AddRaceSkillT( thisRaceID, "Regeneration", false );	
	SKILL_INVIS = War3_AddRaceSkillT( thisRaceID, "Invisibility", false );	
	SKILL_DMG = War3_AddRaceSkillT( thisRaceID, "Genocide", false );
	SKILL_GRENADE = War3_AddRaceSkillT( thisRaceID, "Grenades", false );
	ULT_DEJAVU = War3_AddRaceSkillT( thisRaceID, "DejaVu", true );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_DEJAVU, 5.0, _ );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, GenocideInvis[War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS )] );
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		if( IsPlayerAlive( client ) )
		{
			InitPassiveSkills( client );
		}
	}
	else
	{
		W3ResetAllBuffRace(client,thisRaceID);
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
		used[client] = false;
	}
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_REGEN );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.33 )
			{
				new Float:start_pos[3];
				new Float:target_pos[3];
				
				GetClientAbsOrigin( attacker, start_pos );
				GetClientAbsOrigin( victim, target_pos );
				
				start_pos[2] += 20;
				target_pos[2] += 20;
				
				TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 2.0, 40.0, 40.0, 0, 0.0, { 255, 0, 0, 255 }, 0 );
				TE_SendToAll();
				
				TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 2.0, 20.0, 20.0, 0, 0.0, { 255, 255, 255, 255 }, 0 );
				TE_SendToAll();
				
				War3_HealToBuffHP( attacker, RoundToFloor( damage * HealthMultiplier[skill_level] ) );
				W3FlashScreen( victim, RGBA_COLOR_RED );
			}
			
			new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= GenocideDMGChance[skill_dmg] && skill_dmg > 0 )
			{
				new String:wpnstr[32];
				GetClientWeapon( attacker, wpnstr, 32 );
				if( !StrEqual( wpnstr, "hegrenade" ) && !StrEqual( wpnstr, "weapon_knife" ) )
				{
					War3_DealDamage( victim, 10, attacker, DMG_BULLET, "genocide_crit" );
					
					W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG );
					W3FlashScreen( victim, RGBA_COLOR_RED );
					
					new Float:pos[3];
					
					GetClientAbsOrigin( victim, pos );
					
					TE_SetupBeamRingPoint( pos, 20.0, 60.0, RingBeam, RingBeam, 0, 0, 1.0, 4.0, 0.0, { 255, 100, 0, 255 }, 0, FBEAM_ISACTIVE );
					TE_SendToAll();
				}
			}
		}
	}
}


public PlayerHurtEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	new String:weapon[64];
	GetEventString( event, "weapon", weapon, 64 );
	new damage = GetEventInt( event, "dmg_health" );
	
	if( victim > 0 && attacker > 0 && attacker != victim )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_GRENADE );
			if( ValidPlayer( victim, true ) && skill_dmg > 0 )
			{
				if( StrEqual( weapon, "hegrenade" ) )
				{
					War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_dmg] ), attacker, DMG_BULLET, "genocide_grenade" );
					PrintHintText( victim, "%T", "Critical Grenade", victim );
					PrintHintText( attacker, "%T", "Critical Grenade", attacker );
					
					//new Float:pos[3];
					//GetClientAbsOrigin( victim, pos );
					//TE_SetupBeamRingPoint( pos, 20.0, 500.0, FlameSprite, FlameSprite, 0, 0, 2.0, 60.0, 0.8, { 255, 0, 0, 255 }, 1, FBEAM_ISACTIVE );
					//TE_SendToAll();
					//EmitSoundToAll( grenade, victim );
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
		new ult_level = War3_GetSkillLevel( client, race, ULT_DEJAVU );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_DEJAVU, true ) && !used[client] )
			{
				GetClientAbsOrigin( client, ClientPos[client] );
				GetClientEyeAngles( client, ClientAng[client] );
				Health[client] = GetClientHealth( client );
				
				CreateTimer( GenocideUltDuration[ult_level], TeleportClient, client );
				War3_CooldownMGR( client, GenocideUltDuration[ult_level] + 15.0, thisRaceID, ULT_DEJAVU, _, false );
				PrintHintText( client, "%T", "Deja Vu Activated!", client );
				used[client] = true;
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

public Action:TeleportClient( Handle:timer, any:client )
{
	if( used[client] )
	{
		if( IsPlayerAlive( client ) )
		{
			SetEntityHealth( client, Health[client] );
			TeleportEntity( client, ClientPos[client], ClientAng[client], NULL_VECTOR );
		}
		else
		{
			War3_SpawnPlayer( client );
			SetEntityHealth( client, Health[client] );
			TeleportEntity( client, ClientPos[client], ClientAng[client], NULL_VECTOR );
		}
		PrintHintText( client, "%T", "Deja Vu", client );
		used[client] = false;
	}
}