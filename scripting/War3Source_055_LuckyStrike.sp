/**
* File: War3Source_LuckyStrike.sp
* Description: The Lucky*Strike race for SourceCraft.
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
new Float:FreezeChance[5] = { 0.0, 0.27, 0.30, 0.33, 0.36 };
new Float:DamageMultiplier[5] = { 0.0, 0.3, 0.4, 0.5, 0.6 };
new Float:EvadeChance[5] = { 0.0, 0.05, 0.10, 0.15, 0.20 };
new Float:AntiultChanse[5] = { 0.0, 0.55, 0.65, 0.65, 0.80 };
new StealMoney[5] = { 0, 300, 600, 900, 1200 };
new m_iAccount;

new SKILL_DMG, SKILL_EVADE, SKILL_STEAL, SKILL_ANTIULT, SKILL_FREEZE;

public Plugin:myinfo = 
{
	name = "Lucky*Strike",
	author = "xDr.HaaaaaaaXx",
	description = "The Lucky*Strike race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

public OnPluginStart()
{
	m_iAccount = FindSendPropInfo( "CCSPlayer", "m_iAccount" );
	
	LoadTranslations("w3s.race.luckstruck.phrases");
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRaceT( "luckstruck" );
	
	SKILL_DMG = War3_AddRaceSkillT( thisRaceID, "LuckyStrike", false );	
	SKILL_EVADE = War3_AddRaceSkillT( thisRaceID, "WildCard", false );	
	SKILL_STEAL = War3_AddRaceSkillT( thisRaceID, "StrikeLucky", false );
	SKILL_ANTIULT = War3_AddRaceSkillT( thisRaceID, "Joker", false );
	SKILL_FREEZE = War3_AddRaceSkillT( thisRaceID, "Freeze", false );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_ANTIULT );
	if( War3_GetRace( client ) == thisRaceID && GetRandomFloat( 0.0, 1.0 ) <= AntiultChanse[skill_level] )
	{
		War3_SetBuff( client, bImmunityUltimates, thisRaceID, true );
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
	}
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.25 && skill_dmg > 0 )
			{
				War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_dmg] ), attacker, DMG_BULLET, "lucky_crit" );
				
				W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG );
				W3FlashScreen( victim, RGBA_COLOR_RED );
			}
			
			new skill_freeze = War3_GetSkillLevel( attacker, thisRaceID, SKILL_FREEZE );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= FreezeChance[skill_freeze] && skill_freeze > 0 )
			{
				War3_SetBuff( victim, bNoMoveMode, thisRaceID, true );
				CreateTimer( 1.0, StopFreeze, victim );
				W3FlashScreen( victim, RGBA_COLOR_BLUE );
				PrintHintText( attacker, "%T", "Your enemy freezed!", attacker );
			}
		}
	}
}

public Action:StopFreeze( Handle:timer, any:client )
{
	War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
}

public OnW3TakeDmgBulletPre( victim, attacker, Float:damage )
{
	if( ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && victim != attacker )
	{
		new vteam = GetClientTeam( victim );
		new ateam = GetClientTeam( attacker );

		new race_victim = War3_GetRace( victim );
		new race_attack = War3_GetRace( attacker );

		if( vteam != ateam )
		{
			new skill_steal = War3_GetSkillLevel( attacker, thisRaceID, SKILL_STEAL );
			if( race_attack == thisRaceID && skill_steal > 0 && !Hexed( attacker, false ) && !W3HasImmunity( victim, Immunity_Skills ) )
			{
				if( GetRandomFloat( 0.0, 1.0 ) <= 0.30 )
				{
					new stolen = StealMoney[skill_steal];

					new dec_money = GetMoney( victim ) - stolen;
					new inc_money = GetMoney( attacker ) + stolen;

					if( dec_money < 0 ) dec_money = 0;
					if( inc_money > 16000 ) inc_money = 16000;

					SetMoney( victim, dec_money );
					SetMoney( attacker, inc_money );

					W3MsgStoleMoney( victim, attacker, StealMoney[skill_steal] );
					W3FlashScreen( attacker, RGBA_COLOR_BLUE );
				}
			}
			
			new skill_evade = War3_GetSkillLevel( victim, thisRaceID, SKILL_EVADE );
			if( race_victim == thisRaceID && skill_evade > 0 && !Hexed( victim, false ) && !W3HasImmunity( victim, Immunity_Skills ) ) 
			{
				if( GetRandomFloat( 0.0, 1.0 ) <= EvadeChance[skill_evade] )
				{
					W3FlashScreen( victim, RGBA_COLOR_BLUE );
					War3_DamageModPercent( 0.0 );
					W3MsgEvaded( victim, attacker );
				}
			}
		}
	}
}

stock GetMoney( player )
{
	return GetEntData( player, m_iAccount );
}

stock SetMoney( player, money )
{
	SetEntData( player, m_iAccount, money );
}