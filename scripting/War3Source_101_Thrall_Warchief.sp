/**
* File: War3Source_Thrall_Warchief.sp
* Description: The Thrall Warchief race for SourceCraft. Race from Warcraft III Collection(http://www.fpsbanana.com/scripts/5804)
* Author(s): xDr.HaaaaaaaXx 
*/

#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>

#include "W3SIncs/War3Source_Interface"

// War3Source stuff
new thisRaceID, SKILL_SPAWN, SKILL_VICTIM, SKILL_DEATH, SKILL_ULT;

// Chance/Data Arrays
// skill 1
new Float:FenixChance[5] = { 0.0, 0.15, 0.30, 0.45, 0.50 };
new String:reviveSound[] = "war3source/reincarnation.mp3";
new Float:fLastRevive[MAXPLAYERS];
new bool:bRevived[MAXPLAYERS];
new RevivedBy[MAXPLAYERS];
new PupilSprite;

// skill 2
new Float:MoneyChance[5] = { 0.0, 0.8, 0.12, 0.16, 0.18 };

// skill 3
new DMGMin[5] = { 0, 5, 5, 7, 10 };
new DMGMax[5] = { 0, 9, 11, 15, 20 };

// skill 4
new Float:Duration[5] = { 0.0, 3.0, 5.0, 8.0, 10.0 };
new HudSprite;

// other
new MoneyOffsetCS, MyWeaponsOffset, AmmoOffset;

public Plugin:myinfo = 
{
	name = "War3Source Race - Thrall Warchief",
	author = "xDr.HaaaaaaaXx",
	description = "The Thrall Warchief race for War3Source. Race from Warcraft III Collection(http://www.fpsbanana.com/scripts/5804)",
	version = "1.0.0.1",
	url = ""
};

public OnPluginStart()
{
	HookEvent( "player_death", PlayerDeathEvent );
	MoneyOffsetCS = FindSendPropInfo( "CCSPlayer", "m_iAccount" );
	MyWeaponsOffset = FindSendPropOffs( "CBaseCombatCharacter", "m_hMyWeapons" );
	AmmoOffset = FindSendPropOffs( "CBasePlayer", "m_iAmmo" );
}

public OnMapStart()
{
	//War3_PrecacheSound( reviveSound );
	PupilSprite = PrecacheModel( "models/alyx/pupil_r.vmt" );
	HudSprite = PrecacheModel( "sprites/640hud9.vmt" );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Vip Thrall Warchief", "thrall" );
	
	SKILL_SPAWN = War3_AddRaceSkill( thisRaceID, "Leader of the Horde", "Rescue fallen Horde", false, 4 );
	SKILL_VICTIM = War3_AddRaceSkill( thisRaceID, "Clan of Frostwolves", "Get pay from damage you take", false, 4 );
	SKILL_DEATH = War3_AddRaceSkill( thisRaceID, "Orc Blood", "Get revenge to your death", false, 4 );
	SKILL_ULT = War3_AddRaceSkill( thisRaceID, "Alliance", "Change your side", true, 4 );
	
	W3SkillCooldownOnSpawn( thisRaceID, SKILL_ULT, 15.0 );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID && War3_GetSkillLevel( client, thisRaceID, SKILL_SPAWN ) > 0 )
	{
		new Float:pos[3];
		
		GetClientAbsOrigin( client, pos );
		
		pos[2] += 15;
		
		TE_SetupGlowSprite( pos, PupilSprite, 3.0, 3.0, 255 );
		TE_SendToAll();
	}
}

public OnRacechanged( client,oldrace, newrace )
{
	if( newrace != thisRaceID )
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

bool:CooldownRevive( client )
{
	if( GetGameTime() >= ( fLastRevive[client] + 15.0 ) )
		return true;
	return false;
}

public PlayerDeathEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new userid = GetEventInt( event, "userid" );
	new victim = GetClientOfUserId( userid );
	new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	if( victim > 0 )
	{
		W3ResetPlayerColor( victim, thisRaceID );
		new victimTeam = GetClientTeam( victim );
		new skillevel;
		
		if( CooldownRevive( victim ) )
		{
			for( new i = 1; i <= MaxClients; i++ )
			{
				if( i != victim && ValidPlayer( i, true ) && GetClientTeam( i ) == victimTeam && War3_GetRace( i ) == thisRaceID )
				{
					skillevel = War3_GetSkillLevel( i, thisRaceID, SKILL_SPAWN );
					if( skillevel > 0 && !Hexed( i, false ) )
					{
						if( GetRandomFloat( 0.0, 1.0 ) <= FenixChance[skillevel] )
						{
							RevivedBy[victim] = i;
							bRevived[victim] = true;
							CreateTimer( 2.0, DoRevival, victim );
							break;
						}
					}
				}
			}
		}
	}
	if( War3_GetRace( victim ) == thisRaceID && victim != 0 )
	{
		new skill_death = War3_GetSkillLevel( victim, thisRaceID, SKILL_DEATH );
		if( skill_death > 0 && GetRandomFloat( 0.0, 1.0 ) <= 0.20 )
		{
			new DMG = GetRandomInt( DMGMin[skill_death], DMGMax[skill_death] );
			War3_DealDamage( attacker, DMG, victim, DMG_BULLET, "thrall_blood" );
			W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(),SKILL_DEATH  );
		}
	}
}

public Action:DoRevival( Handle:timer, any:client )
{
	if( client > 0 )
	{
		new savior = RevivedBy[client];
		if( ValidPlayer( savior, true ) && ValidPlayer( client ) )
		{
			if( GetClientTeam( savior ) == GetClientTeam( client ) && !IsPlayerAlive( client ) )
			{
				War3_SpawnPlayer( client );
				EmitSoundToAll( reviveSound, client );
				
				W3MsgRevivedBM( client, savior );
				
				new Float:VecPos[3];
				new Float:Angles[3];
				War3_CachedAngle( client, Angles );
				War3_CachedPosition( client, VecPos );
				
				TeleportEntity( client, VecPos, Angles, NULL_VECTOR );
				if( War3_GetGame() == Game_CS )
				{
					for( new s = 0; s < 10; s++ )
					{
						new ent = GetEntDataEnt2( client, MyWeaponsOffset + ( s * 4 ) );
						if( ent > 0 && IsValidEdict( ent ) )
						{
							new String:ename[64];
							GetEdictClassname( ent, ename, 64 );
							if( StrEqual( ename, "weapon_c4" ) || StrEqual( ename, "weapon_knife" ) )
							{
								continue;
							}
							UTIL_Remove( ent );
						}
					}
					for( new s = 0; s < 32; s++ )
					{
						SetEntData( client, AmmoOffset + ( s * 4 ), War3_CachedDeadAmmo( client, s ), 4 );
					}
					SetEntProp( client, Prop_Send, "m_ArmorValue", 100 );
				}
				testhull( client );
				fLastRevive[client] = GetGameTime();
			}
			else
			{
				RevivedBy[client] = 0;
				bRevived[client] = false; 
			}
		}
		else
		{
			RevivedBy[client] = 0;
			bRevived[client] = false; 
		}
	
	}
}

new absincarray[] = { 0, 4, -4, 8, -8, 12, -12, 18, -18, 22, -22, 25, -25, 27, -27, 30, -30 };//,33,-33,40,-40};

public bool:testhull( client )
{	
	new Float:mins[3];
	new Float:maxs[3];
	GetClientMins( client, mins );
	GetClientMaxs( client, maxs );
	
	new absincarraysize = sizeof( absincarray );
	new Float:originalpos[3];
	GetClientAbsOrigin( client, originalpos );
	
	new limit = 5000;
	for( new x = 0; x < absincarraysize; x++ )
	{
		if( limit > 0 )
		{
			for( new y = 0; y <= x; y++ )
			{
				if( limit > 0 )
				{
					for( new z = 0; z <= y; z++ )
					{
						new Float:pos[3] = { 0.0, 0.0, 0.0 };
						AddVectors( pos, originalpos, pos );
						pos[0] += float( absincarray[x] );
						pos[1] += float( absincarray[y] );
						pos[2] += float( absincarray[z] );
						
						TR_TraceHullFilter( pos, pos, mins, maxs, CONTENTS_SOLID|CONTENTS_MOVEABLE, CanHitThis, client );
						if( TR_DidHit( _ ) )
						{
						}
						else
						{
							TeleportEntity( client, pos, NULL_VECTOR, NULL_VECTOR );
							limit = -1;
							break;
						}
						if( limit --< 0 )
						{
							break;
						}
					}
					if( limit --< 0 )
					{
						break;
					}
				}
			}
			if( limit --< 0 )
			{
				break;
			}
		}
	}
}

public bool:CanHitThis( entityhit, mask, any:data )
{
	if( entityhit == data )
	{
		return false;
	}
	if( ValidPlayer( entityhit ) && ValidPlayer( data ) && War3_GetGame() == Game_TF && GetClientTeam( entityhit ) == GetClientTeam( data ) )
	{
		return false;
	}
	return true;
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( victim ) == thisRaceID )
		{
			new skill_level = War3_GetSkillLevel( victim, thisRaceID, SKILL_VICTIM );
			if( !Hexed( victim, false ) && GetRandomFloat( 0.0, 1.0 ) <= MoneyChance[skill_level] )
			{
				new stolen = 1000;
				new new_money = GetMoney( victim ) + stolen;
				if( new_money > 16000 ) new_money = 16000;
				SetMoney( victim, new_money );
				new_money = GetMoney( attacker ) - stolen;
				if( new_money < 0 ) new_money = 0; 
				SetMoney( attacker, new_money );
				if( stolen > 0 )
				{
					W3FlashScreen( victim, { 0, 0, 128, 80 } );
					W3MsgStoleMoney( attacker, victim, stolen );
				}
			}
		}
	}
}


public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, SKILL_ULT );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_ULT, true ) )
			{
				if( GetClientTeam( client ) == TEAM_T )
				{
					//SetEntityModel( client, "models/player/ct_urban.mdl" );
					PrintToChat( client, "\x03You have become a \x04Counter Terrorist \x03for %f seconds", Duration[ult_level] );
					CreateTimer( Duration[ult_level], ChangeTeam, client );
					CS_SwitchTeam( client, TEAM_CT );
				}
				else if( GetClientTeam( client ) == TEAM_CT )
				{
					//SetEntityModel( client, "models/player/t_leet.mdl" );
					PrintToChat( client, "\x03You have become a \x04Terrorist \x03for %f seconds", Duration[ult_level] );
					CreateTimer( Duration[ult_level], ChangeTeam, client );
					CS_SwitchTeam( client, TEAM_T );
				}
				War3_CooldownMGR( client, 20.0, thisRaceID, SKILL_ULT,false);
				new Float:pos[3];
				GetClientAbsOrigin( client, pos );
				pos[2] += 40;
				TE_SetupBeamRingPoint( pos, 450.0, 190.0, HudSprite, HudSprite, 0, 0, 0.2, 150.0, 0.0, { 155, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
				TE_SendToAll();
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

public Action:ChangeTeam( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		if( GetClientTeam( client ) == TEAM_CT )
		{
			//SetEntityModel( client, "models/player/t_leet.mdl" );
			PrintToChat( client, "\x03You are no longer a Terrorist" );
			CS_SwitchTeam( client, TEAM_T );
		}
		else if( GetClientTeam( client ) == TEAM_T )
		{
			//SetEntityModel( client, "models/player/ct_urban.mdl" );
			PrintToChat( client, "\x03You are no longer a Counter Terrorist" );
			CS_SwitchTeam( client, TEAM_CT );
		}
	}
}

stock GetMoney( player )
{
	return GetEntData( player, MoneyOffsetCS );
}

stock SetMoney( player, money )
{
	SetEntData( player, MoneyOffsetCS, money );
}