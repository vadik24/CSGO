/**
* File: War3Source_Marine_Class.sp
* Description: The Marine Class race for SourceCraft.
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
new bool:Beaconed[MAXPLAYERS];

// Chance/Data Arrays
new Float:DamageMultiplier[5] = { 0.0, 0.10, 0.20, 0.30, 0.40 };
new Float:BeaconChance[5] = { 0.0, 0.10, 0.15, 0.20, 0.25 };
new Float:DamageChance[5] = { 0.0, 0.35, 0.40, 0.45, 0.50 };
new StrikeDamage[5] = { 0, 15, 20, 25, 30 };
new String:ult_sound[] = "weapons/stinger_fire1.mp3";
new HaloSprite, BeamSprite;

new SKILL_GUN, SKILL_TRAINING, SKILL_BEACON, ULT_ART;

public Plugin:myinfo = 
{
	name = "Marine Class",
	author = "xDr.HaaaaaaaXx",
	description = "The Marine Class race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

public OnPluginStart()
{
	LoadTranslations("w3s.race.marineclass.phrases");
}

public OnMapStart()
{
	HaloSprite = War3_PrecacheHaloSprite();
	BeamSprite = PrecacheModel( "materials/sprites/laserbeam.vmt" );
	////War3_PrecacheSound( ult_sound );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRaceT( "marineclass" );
	
	SKILL_GUN = War3_AddRaceSkillT( thisRaceID, "Gun", false );	
	SKILL_TRAINING = War3_AddRaceSkillT( thisRaceID, "AimTraining", false );	
	SKILL_BEACON = War3_AddRaceSkillT( thisRaceID, "HotSpot", false );
	ULT_ART = War3_AddRaceSkillT( thisRaceID, "Artillery", true );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_ART, 5.0, _ );
	
	War3_CreateRaceEnd( thisRaceID );
}


/*
public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,25);
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
*/

public OnWar3EventSpawn( client )
{
	Beaconed[client]=false;
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		//InitPassiveSkills( client );
				
		if( War3_GetSkillLevel( client, thisRaceID, SKILL_GUN ) == 1 )
			GivePlayerItem( client, "weapon_mp7" );
		if( War3_GetSkillLevel( client, thisRaceID, SKILL_GUN ) == 2 )
			GivePlayerItem( client, "weapon_famas" );
		if( War3_GetSkillLevel( client, thisRaceID, SKILL_GUN ) == 3 )
			GivePlayerItem( client, "weapon_m4a1" );
		if( War3_GetSkillLevel( client, thisRaceID, SKILL_GUN ) == 4 )
			GivePlayerItem( client, "weapon_m249" );
	}
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_training = War3_GetSkillLevel( attacker, thisRaceID, SKILL_TRAINING );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= DamageChance[skill_training] && skill_training > 0 )
			{
				new Float:start_pos[3];
				new Float:target_pos[3];
				
				GetClientAbsOrigin( attacker, start_pos );
				GetClientAbsOrigin( victim, target_pos );
				
				start_pos[2] += 40;
				target_pos[2] += 40;
				
				TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 1.0, 10.0, 10.0, 0, 0.0, { 133, 177, 155, 255 }, 40 );
				TE_SendToAll();
				
				War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_training] ), attacker, DMG_BULLET, "marine_crit" );
				
				W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_TRAINING );
				W3FlashScreen( victim, RGBA_COLOR_RED );
			}
			
			new skill_beacon = War3_GetSkillLevel( attacker, thisRaceID, SKILL_BEACON );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= BeaconChance[skill_beacon] && skill_beacon > 0 )
			{
				if(!Beaconed[victim])
				{
					ServerCommand( "sm_beacon #%d 1", GetClientUserId( victim ) );
					Beaconed[victim]=true;
				}
			}
		}
	}
}

/*
Action:BeaconVictim(client)
{
	if(!Beaconed[client])
	{
		ServerCommand( "sm_beacon #%d 1", GetClientUserId( client ) );
		Beaconed[client]=true;
	}
}
*/

public OnUltimateCommand( client, race, bool:pressed )
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_ART );
		if( ult_level > 0 )
		{
			if( !Silenced( client ) && War3_SkillNotInCooldown( client, thisRaceID, ULT_ART, true ) )
			{
				// Strike( client );
				
				new Float:bestTargetDistance = 2000.0;
				new Float:otherVec[3];
				new Float:posVec[3];
				new bestTarget = 0;
				new team = GetClientTeam( client );

				GetClientAbsOrigin( client, posVec );

				for( new i = 1; i <= MaxClients; i++ )
				{
					// if( ValidPlayer( i, true ) && GetClientTeam( i ) != team && !W3HasImmunity( i, Immunity_Ultimates ) )
					if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Ultimates))
					{
						GetClientAbsOrigin( i, otherVec );
						new Float:dist = GetVectorDistance( posVec, otherVec );
						if( dist < bestTargetDistance )
						{
							bestTarget = i;
							bestTargetDistance = GetVectorDistance( posVec, otherVec );
						}
					}
				}
				
				// new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_ART );
				if( bestTarget == 0 )
				{
					W3MsgNoTargetFound(client,bestTargetDistance);
				}
				else
				{
					new DamageOrHP=StrikeDamage[ult_level];
					War3_DealDamage( bestTarget, DamageOrHP, client, DMG_BULLET, "marine_artillery",_, W3DMGTYPE_PHYSICAL );
					// War3_HealToMaxHP( client, StrikeDamage[ult_level] );
					new MarineHP=GetClientHealth(client);
					SetEntityHealth(client,MarineHP+DamageOrHP);
			
					W3PrintSkillDmgHintConsole( bestTarget, client, War3_GetWar3DamageDealt(), ULT_ART );
					War3_ShakeScreen( bestTarget, 3.0, 250.0, 40.0 );
					W3FlashScreen( bestTarget, RGBA_COLOR_RED );
					
					//EmitSoundToAll( ult_sound, client );
				
					War3_CooldownMGR( client, 30.0, thisRaceID, ULT_ART, _, false );
				}
							
							
			}
		}
		else	
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

/*
Action:Strike( client )
{
	new Float:bestTargetDistance = 9999.0;
	new Float:otherVec[3];
	new Float:posVec[3];
	new bestTarget = 0;
	new team = GetClientTeam( client );

	GetClientAbsOrigin( client, posVec );

	for( new i = 1; i <= MaxClients; i++ )
	{
		if( ValidPlayer( i, true ) && GetClientTeam( i ) != team && !W3HasImmunity( i, Immunity_Ultimates ) )
		{
			GetClientAbsOrigin( i, otherVec );
			new Float:dist = GetVectorDistance( posVec, otherVec );
			if( dist < bestTargetDistance )
			{
				bestTarget = i;
				bestTargetDistance = GetVectorDistance( posVec, otherVec );
			}
		}
	}

	new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_ART );
	if( bestTarget == 0 )
	{
		W3MsgNoTargetFound(client,bestTargetDistance);
	}
	else
	{
		new DamageOrHP=StrikeDamage[ult_level];
		War3_DealDamage( bestTarget, DamageOrHP, client, DMG_BULLET, "marine_artillery",_, W3DMGTYPE_PHYSICAL );
		// War3_HealToMaxHP( client, StrikeDamage[ult_level] );
		new MarineHP=GetClientHealth(client);
		SetEntityHealth(client,MarineHP+DamageOrHP);

		W3PrintSkillDmgHintConsole( bestTarget, client, War3_GetWar3DamageDealt(), "Artillery" );
		War3_ShakeScreen( bestTarget, 3.0, 250.0, 40.0 );
		W3FlashScreen( bestTarget, RGBA_COLOR_RED );
		
		//EmitSoundToAll( ult_sound, client );

		War3_CooldownMGR( client, 30.0, thisRaceID, ULT_ART, _, false );
	}
}
*/