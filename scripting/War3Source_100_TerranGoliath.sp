/**
* File: War3Source_Terran_Goliath.sp
* Description: The Terran Goliath race for SourceCraft.
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
new Float:AbilityRadius[6] = { 0.0, 200.0, 230.0, 260.0, 290.0, 325.0 };
new Float:DamageMultiplier[6] = { 0.0, 0.2, 0.4, 0.6, 0.8, 1.0 };
new Float:GoliathSpeed[6] = { 1.0, 1.20, 1.25, 1.30, 1.35, 1.40 };
new Float:UltDelay[6] = { 0.0, 35.0, 33.0, 31.0, 27.0, 25.0 };
new Float:UltDuration[6] = { 0.0, 0.5, 1.0, 1.5, 2.0, 2.5 };
new String:ultimateSound[] = "war3source/divineshield.mp3";
new AbilityHealth[6] = { 0, 1, 2, 3, 4, 5 };
new HaloSprite, BeamSprite, HealSprite;
new bool:bRegenActived[64];
new bool:bGodActived[64];

new SKILL_DMG, SKILL_SPEED, SKILL_REGEN, ULT_GOD;

public Plugin:myinfo = 
{
	name = "War3Source Race - Terran Goliath",
	author = "xDr.HaaaaaaaXx",
	description = "Terran Goliath race for War3Source.",
	version = "1.0",
	url = ""
};

public OnMapStart()
{
	HaloSprite = War3_PrecacheHaloSprite();
	BeamSprite = War3_PrecacheBeamSprite();
	HealSprite = PrecacheModel( "materials/sprites/hydraspinalcord.vmt" );
	//War3_PrecacheSound( ultimateSound );
}

public OnPluginStart()
{
	CreateTimer( 1.0, CalcHexHeales, _, TIMER_REPEAT );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Terran Goliath", "terrgoliath" );
	
	SKILL_DMG = War3_AddRaceSkill( thisRaceID, "Charon Boosters", "You can do more dmg whit some boosters.", false, 5 );	
	SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Walker Speed", "This will upgrade your speed.", false, 5 );	
	SKILL_REGEN = War3_AddRaceSkill( thisRaceID, "Repair/Medic", "You can repair your self and heal near by teammates.", false, 5 );
	ULT_GOD = War3_AddRaceSkill( thisRaceID, "Walker Plating", "You can active Walker Plating that make you Immortal for a bit time.", true, 5 );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_GOD, 5.0, true);
	W3SkillCooldownOnSpawn( thisRaceID, SKILL_REGEN, 5.0, false);
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff( client, fMaxSpeed, thisRaceID, GoliathSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
		
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,50);
	}
}

public OnRaceChanged( client, oldrace, newrace )
{
	if( newrace == thisRaceID )
	{
		if( IsPlayerAlive( client ) )
		{
			InitPassiveSkills( client );
		}
	}
	else
	{
		W3ResetAllBuffRace( client, thisRaceID );
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
	bGodActived[victim] = false;
	bRegenActived[victim] = false;
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
			if( !Hexed( attacker, false ) && skill_dmg > 0 && GetRandomFloat( 0.0, 1.0 ) <= 0.30 && !W3HasImmunity( victim, Immunity_Skills  ) )
			{
				new String:wpnstr[32];
				GetClientWeapon( attacker, wpnstr, 32 );
				if( !StrEqual( wpnstr, "weapon_knife" ) )
				{
					new Float:start_pos[3];
					new Float:target_pos[3];
				
					GetClientAbsOrigin( attacker, start_pos );
					GetClientAbsOrigin( victim, target_pos );
				
					start_pos[2] += 40;
					target_pos[2] += 40;
				
					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 1.0, 3.0, 6.0, 0, 0.0, { 100, 255, 55, 255 }, 0 );
					TE_SendToAll();
					
					War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_dmg] ), attacker, DMG_BULLET, "goliath_crit" );
				
					W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG);
					W3FlashScreen( victim, RGBA_COLOR_RED );
				}
			}
		}
	}
}

public OnW3TakeDmgAllPre( victim, attacker, Float:damage )
{
	if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
	{
		new vteam = GetClientTeam( victim );
		new ateam = GetClientTeam( attacker );
		if( vteam != ateam )
		{
			new race_victim = War3_GetRace( victim );
			new ult_level = War3_GetSkillLevel( victim, thisRaceID, ULT_GOD );
			if( race_victim == thisRaceID && ult_level > 0 && bGodActived[victim] )
			{
				if( !W3HasImmunity( attacker, Immunity_Ultimates ) )
				{
					War3_DamageModPercent( 0.0 );
				}
				else
				{
					W3MsgEnemyHasImmunity( victim, true );
				}
			}
		}
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_GOD );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_GOD, true ) )
			{
				bGodActived[client] = true;
				
				CreateTimer( UltDuration[ult_level], StopGod, client );
				
				War3_CooldownMGR( client, UltDuration[ult_level] + UltDelay[ult_level], thisRaceID, ULT_GOD,false);
				
				W3SetPlayerColor( client, thisRaceID, 255, 200, 0, _, GLOW_ULTIMATE );
				
				TE_SetupBeamFollow( client, BeamSprite, HaloSprite, 1.0, 10.0, 10.0, 10, { 255, 0, 25, 255 } );
				TE_SendToAll();
				
				W3FlashScreen( client, { 255, 200, 0, 3 } );
				
				PrintHintText( client, "Activated Walker Plating!" );
				
				EmitSoundToAll( ultimateSound, client );
				EmitSoundToAll( ultimateSound, client );
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

public Action:StopGod( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		bGodActived[client] = false;
		
		W3ResetPlayerColor( client, thisRaceID );
	
		PrintHintText( client, "Walker Plating has ended" );
	}
}

public OnAbilityCommand( client, ability, bool:pressed )
{
	if( War3_GetRace( client ) == thisRaceID && ability == 0 && pressed && IsPlayerAlive( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, thisRaceID, SKILL_REGEN );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_REGEN, true ) && !bRegenActived[client] )
			{
				bRegenActived[client] = true;
				
				CreateTimer( 15.0, StopRegen, client );
				
				War3_CooldownMGR( client, 25.0, thisRaceID, SKILL_REGEN,false);
				
				W3SetPlayerColor( client, thisRaceID, 100, 255, 100, _, GLOW_SKILL );
			}
		}
	}
}

public Action:StopRegen( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		bRegenActived[client] = false;
		
		W3ResetPlayerColor( client, thisRaceID );
	}
}

public Action:CalcHexHeales( Handle:timer, any:userid )
{
	if( thisRaceID > 0 )
	{
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) )
			{
				if( War3_GetRace( i ) == thisRaceID && bRegenActived[i] )
				{
					Healer( i );
				}
			}
		}
	}
}

public Healer( client )
{
	new skill = War3_GetSkillLevel( client, thisRaceID, SKILL_REGEN );
	if( skill > 0 && !Hexed( client, false ) )
	{
		new Float:dist = AbilityRadius[skill];
		new HealerTeam = GetClientTeam( client );
		new Float:HealerPos[3];
		new Float:VecPos[3];
		
		GetClientAbsOrigin( client, HealerPos );
		
		HealerPos[2] += 40.0;

		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) && GetClientTeam( i ) == HealerTeam )
			{
				GetClientAbsOrigin( i, VecPos );
				VecPos[2] += 40.0;
				
				if( GetVectorDistance( HealerPos, VecPos ) <= dist && GetClientHealth( i ) != War3_GetMaxHP( i ) )
				{
					War3_HealToMaxHP( i, AbilityHealth[skill] );
					
					TE_SetupBeamPoints( HealerPos, VecPos, HealSprite, HaloSprite, 0, 0, 0.5, 3.0, 6.0, 0, 0.0, { 100, 255, 55, 255 }, 0 );
					TE_SendToAll();
					
					W3FlashScreen( i, RGBA_COLOR_GREEN );
				}
			}
		}
	}
}