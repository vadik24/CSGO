/**
* File: War3Source_Raiden.sp
* Description: The Raiden race for SourceCraft.
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
// skill 1
new Float:DMG1Multiplier[6] = { 0.0, 0.75, 0.99, 1.1, 1.2, 1.4 };

// skill 2
new Float:DMG2Multiplier[6] = { 0.0, 0.50, 0.70, 0.85, 1.0, 1.2 };

// skill 3
new Float:DMG3Multiplier[6] = { 0.0, 0.70, 0.80, 0.90, 1.1, 1.2 };

// skill 4
new Float:ShakeTime[6] = { 0.0, 2.0, 3.0, 4.0, 5.0, 6.0 };

// skill 5
#define MAXWARDS 64*4
#define WARDRADIUS 95
#define WARDDAMAGE 10
#define WARDBELOW -2.0
#define WARDABOVE 140.0

new WardStartingArr[] = { 0, 1, 2, 3, 4, 5 };
new Float:WardLocation[MAXWARDS][3];
new CurrentWardCount[MAXPLAYERS];
new Float:LastWardRing[MAXWARDS];
new Float:LastWardClap[MAXWARDS];
new WardOwner[MAXWARDS];

new LightningSprite, HaloSprite, GlowSprite, PurpleGlowSprite;
new SKILL_DMG1, SKILL_DMG2, SKILL_DMG3, SKILL_SHAKE, SKILL_WARD;

public Plugin:myinfo = 
{
	name = "War3Source Race - Raiden",
	author = "xDr.HaaaaaaaXx",
	description = "Raiden race for War3Source.",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	HookEvent( "player_hurt", PlayerHurtEvent );
	CreateTimer( 0.14, CalcWards, _, TIMER_REPEAT );
}

public OnMapStart()
{
	//PrecacheSound( "weapons/mortar/mortar_explode1.mp3", false );
	//PrecacheSound( "weapons/mortar/mortar_explode2.mp3", false );
	//PrecacheSound( "weapons/mortar/mortar_explode3.mp3", false );
	//PrecacheSound( "weapons/explode3.mp3", false );
	//PrecacheSound( "weapons/explode4.mp3", false );
	//PrecacheSound( "weapons/explode5.mp3", false );
	LightningSprite = War3_PrecacheBeamSprite();
	HaloSprite =       War3_PrecacheHaloSprite();
	GlowSprite = PrecacheModel( "sprites/glow.vmt" );
	PurpleGlowSprite = PrecacheModel( "sprites/purpleglow1.vmt" );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace("Raiden", "raiden");

	SKILL_DMG1 = War3_AddRaceSkill( thisRaceID, "Thunder", "More damage from grenades", false, 5 );	
	SKILL_DMG2 = War3_AddRaceSkill( thisRaceID, "Lighting", "Emits lightning on an enemy", false, 5 );	
	SKILL_DMG3 = War3_AddRaceSkill( thisRaceID, "Staff", "Weapons do more damage", false, 5 );
	SKILL_SHAKE = War3_AddRaceSkill( thisRaceID, "God of Thunder", "Shaking screen enemy", false, 5 );
	SKILL_WARD = War3_AddRaceSkill( thisRaceID, "The kingdom Raiden", "Kills anyone who enters в\nThe kingdom Raiden", false, 5 );

	War3_CreateRaceEnd( thisRaceID );
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		RemoveWards( client );
		W3ResetAllBuffRace( client, thisRaceID );
	}
}

public OnWar3EventSpawn( client )
{
	War3_SetBuff( client, fSlow, thisRaceID, 1.0 );
	RemoveWards( client );
}

public OnWar3EventDeath( client )
{
	W3ResetAllBuffRace( client, thisRaceID );
	War3_SetBuff( client, fSlow, thisRaceID, 1.0 );
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_dmg2 = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG2 );
			if( !Hexed( attacker, false ) && skill_dmg2 > 0 && GetRandomFloat( 0.0, 1.0 ) <= 0.15 )
			{
				War3_DealDamage( victim, RoundToFloor( damage * DMG2Multiplier[skill_dmg2] ), attacker, DMG_BULLET, "raiden_thundrbolt" );

				W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG2 );

				new Float:attacker_pos[3];
				new Float:victim_pos[3];

				GetClientAbsOrigin( attacker, attacker_pos );
				GetClientAbsOrigin( victim, victim_pos );

				TE_SetupBeamPoints( attacker_pos, victim_pos, LightningSprite, LightningSprite, 0, 0, 2.0, 13.0, 16.0, 0, 0.0, { 100, 155, 255, 255 }, 0 );
				TE_SendToAll();
			}
			new skill_dmg3 = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG3 );
			if( !Hexed( attacker, false ) && skill_dmg3 > 0 && GetRandomFloat( 0.0, 1.0 ) <= 0.30 )
			{
				War3_DealDamage( victim, RoundToFloor( damage * DMG3Multiplier[skill_dmg3] ), attacker, DMG_BULLET, "raiden_staff" );

				W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG3 );

				new Float:attacker_pos[3];
				new Float:victim_pos[3];

				GetClientAbsOrigin( attacker, attacker_pos );
				GetClientAbsOrigin( victim, victim_pos );

				TE_SetupBeamPoints( attacker_pos, victim_pos, HaloSprite, HaloSprite, 0, 0, 2.0, 5.0, 5.0, 0, 0.0, { 50, 20, 255, 255 }, 0 );
				TE_SendToAll();
			}
			new skill_shake = War3_GetSkillLevel( attacker, thisRaceID, SKILL_SHAKE );
			if( !Hexed( attacker, false ) && skill_shake > 0 && GetRandomFloat( 0.0, 1.0 ) <= 0.25 )
			{
				War3_ShakeScreen( victim, ShakeTime[skill_shake], 20.0, 100.0 );

				PrintToChat( victim, "\x05: God of Thunder" );
				PrintToChat( attacker, "\x05: God of Thunder" );

				new Float:attacker_pos[3];
				new Float:victim_pos[3];

				GetClientAbsOrigin( attacker, attacker_pos );
				GetClientAbsOrigin( victim, victim_pos );

				TE_SetupBeamPoints( attacker_pos, victim_pos, GlowSprite, GlowSprite, 0, 0, 0.5, 20.0, 20.0, 0, 0.0, { 0, 0, 255, 255 }, 0 );
				TE_SendToAll();
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

	if( victim > 0 && attacker > 0 && attacker != victim && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_dmg1 = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG1 );
			if( ValidPlayer( victim, true ) && skill_dmg1 > 0 )
			{
				if( StrEqual( weapon, "hegrenade" ) )
				{
					new magnitude = RoundToFloor( damage * 3.0 * DMG1Multiplier[skill_dmg1] );

					CreateExplode( attacker, victim, magnitude, 50 );

					PrintToChat( victim, "\x04: Thunderer!" );
					PrintToChat( attacker, "\x04: Thunderer!" );

					new Float:pos[3];

					GetClientAbsOrigin( victim, pos );

					TE_SetupBeamRingPoint( pos, 20.0, 5000.0, LightningSprite, LightningSprite, 0, 0, 2.0, 100.0, 1.8, { 175, 175, 255, 255 }, 1, FBEAM_ISACTIVE );
					TE_SendToAll();
				}
			}
		}
	}
}

public OnAbilityCommand( client, ability, bool:pressed )
{
	if( War3_GetRace( client ) == thisRaceID && ability == 0 && pressed && IsPlayerAlive( client ) )
	{
		new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_WARD );
		if( skill_level > 0 )
		{
			if( !Silenced( client ) && CurrentWardCount[client] < WardStartingArr[skill_level] )
			{
				CreateWard( client );
				CurrentWardCount[client]++;
				W3MsgCreatedWard( client, CurrentWardCount[client], WardStartingArr[skill_level] );
			}
			else
			{
				W3MsgNoWardsLeft( client );
			}
		}
	}
}

public CreateWard( client )
{
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( WardOwner[i] == 0 )
		{
			WardOwner[i] = client;
			GetClientAbsOrigin( client, WardLocation[i] );
			break;
		}
	}
}

public RemoveWards( client )
{
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( WardOwner[i] == client )
		{
			WardOwner[i] = 0;
			LastWardRing[i] = 0.0;
			LastWardClap[i] = 0.0;
		}
	}
	CurrentWardCount[client] = 0;
}

public Action:CalcWards( Handle:timer, any:userid )
{
	new client;
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( WardOwner[i] != 0 )
		{
			client = WardOwner[i];
			if( !ValidPlayer( client, true ) )
			{
				WardOwner[i] = 0;
				--CurrentWardCount[client];
			}
			else
			{
				WardEffectAndDamage( client, i );
			}
		}
	}
}

public WardEffectAndDamage( owner, wardindex )
{
	new ownerteam = GetClientTeam( owner );
	new beamcolor[] = { 0, 0, 200, 255 };
	if( ownerteam == 2 )
	{
		beamcolor[0] = 255;
		beamcolor[1] = 0;
		beamcolor[2] = 0;
		beamcolor[3] = 255;
	}

	new Float:start_pos[3];
	new Float:end_pos[3];
	new Float:tempVec1[] = { 0.0, 0.0, WARDBELOW };
	new Float:tempVec2[] = { 0.0, 0.0, WARDABOVE };

	AddVectors( WardLocation[wardindex], tempVec1, start_pos );
	AddVectors( WardLocation[wardindex], tempVec2, end_pos );

	TE_SetupBeamPoints( start_pos, end_pos, LightningSprite, LightningSprite, 0, GetRandomInt( 30, 100 ), 0.17, 20.0, 20.0, 0, 0.0, beamcolor, 0 );
	TE_SendToAll();

	if( LastWardRing[wardindex] < GetGameTime() - 0.25 )
	{
		LastWardRing[wardindex] = GetGameTime();
		TE_SetupBeamRingPoint( start_pos, 20.0, float( WARDRADIUS * 2 ), LightningSprite, LightningSprite, 0, 15, 1.0, 20.0, 1.0, { 255, 150, 70, 100 }, 10, FBEAM_ISACTIVE );
		TE_SendToAll();
	}

	TE_SetupGlowSprite( end_pos, PurpleGlowSprite, 1.0, 1.25, 50 );
	TE_SendToAll();

	new Float:BeamXY[3];
	for( new x = 0; x < 3; x++ ) BeamXY[x] = start_pos[x];
	new Float:BeamZ = BeamXY[2];
	BeamXY[2] = 0.0;

	new Float:VictimPos[3];
	new Float:tempZ;
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( ValidPlayer( i, true ) && GetClientTeam(i) != ownerteam )
		{
			GetClientAbsOrigin( i, VictimPos );
			tempZ = VictimPos[2];
			VictimPos[2] = 0.0;

			if( GetVectorDistance( BeamXY, VictimPos ) < WARDRADIUS )
			{
				if( tempZ > BeamZ + WARDBELOW && tempZ < BeamZ + WARDABOVE )
				{
					if(W3HasImmunity(i,Immunity_Wards))
					{
						W3MsgSkillBlocked(i,_,"Wards");
					}
					else
					{
						if( LastWardClap[wardindex] < GetGameTime() - 1 )
						{
							new DamageScreen[4];
							new Float:pos[3];

							GetClientAbsOrigin( i, pos );

							DamageScreen[0] = beamcolor[0];
							DamageScreen[1] = beamcolor[1];
							DamageScreen[2] = beamcolor[2];
							DamageScreen[3] = 50;

							W3FlashScreen( i, DamageScreen );

							War3_DealDamage( i, WARDDAMAGE, owner, DMG_ENERGYBEAM, "wards", _, W3DMGTYPE_MAGIC );

							War3_SetBuff( i, fSlow, thisRaceID, 0.7 );

							CreateTimer( 2.0, StopSlow, i );

							pos[2] += 40;

							TE_SetupBeamPoints( start_pos, pos, LightningSprite, LightningSprite, 0, 0, 1.0, 10.0, 20.0, 0, 0.0, { 255, 150, 70, 255 }, 0 );
							TE_SendToAll();

							PrintToChat( i, "\x03You've come to the Kingdom of Raiden" );

							LastWardClap[i] = GetGameTime();
						}
					}
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

stock CreateExplode( client, target, magnitude, radius )
{
	new String:expsound[128];
	new randsound = GetRandomInt( 1, 6 );
	if( randsound == 1 )
	{
		//expsound = "weapons/explode3.mp3";
	}
	else if( randsound == 2 )
	{
		//expsound = "weapons/explode4.mp3";
	}
	else if( randsound == 3 )
	{
		//expsound = "weapons/explode5.mp3";
	}
	else if( randsound == 4 )
	{
		//expsound = "weapons/mortar/mortar_explode1.mp3";
	}
	else if( randsound == 5 )
	{
		//expsound = "weapons/mortar/mortar_explode2.mp3";
	}
	else if( randsound == 6 )
	{
		//expsound = "weapons/mortar/mortar_explode3.mp3";
	}
	if( client > 0 && client <= MaxClients && IsClientConnected( client ) && IsClientInGame( client ) )
	{
		if( target > 0 && target <= MaxClients && IsClientConnected( target ) && IsClientInGame( target ) )
		{
			if( GetClientTeam( client ) != GetClientTeam( target ) )
			{
				if( magnitude < 10 )
					magnitude = 10;

				if( radius < 10 )
					radius = 10;

				new dmg = ( magnitude * radius / 150 );

				War3_DealDamage( target, dmg, client, DMG_GENERIC, "explode" );

				//EmitSoundToAll( expsound, target );	
			}
		}
	}
}
