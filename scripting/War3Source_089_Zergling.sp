/**
* File: War3Source_Zergling.sp
* Description: The Zergling race for SourceCraft.
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
new thisRaceID, SKILL_LONGJUMP, SKILL_REGEN, SKILL_SPEED, SKILL_DMG, ULT_BURROW;

// Chance/Data Arrays
// skill 1
new bool:bIsLongjumpActivated[MAXPLAYERS];
new Float:ChanceJump[5] = { 0.0, 0.4, 0.5, 0.6, 0.7 };
new m_vecBaseVelocity, m_vecVelocity_0, m_vecVelocity_1;

// skill 2
new HealthRegen[5] = { 0, 1, 2, 3, 4 };

// skill 3
new Float:ZerglingSpeed[5] = { 1.0, 1.1, 1.2, 1.3, 1.4 };
new Health[5] = { 50, 40, 30, 20, 10 };

// skill 4
new Float:g_DrugAngles[20] = { 0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0 };
new String:attack_sound[] = "npc/roller/mine/rmine_blades_out2.mp3";
new Float:DMGChance[5] = { 0.0, 0.4, 0.5, 0.6, 0.7 };
new UserMsg:g_FadeUserMsgId;

// skill 5
new String:UltOutstr[] = "npc/scanner/scanner_nearmiss2.mp3";
new String:UltInstr[] = "npc/scanner/scanner_nearmiss1.mp3";
new Float:UltCooldown[5] = { 0.0, 6.0, 5.0, 4.0, 3.0 };
new bool:bIsBurrowed[MAXPLAYERS];
new SmokeSprite;

public Plugin:myinfo = 
{
	name = "War3Source Race - Zergling",
	author = "xDr.HaaaaaaaXx",
	description = "The Zergling race for War3Source.",
	version = "1.0",
	url = ""
};

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==205){
	thisRaceID = War3_CreateNewRace( "Zergling", "zergling" );

	SKILL_LONGJUMP = War3_AddRaceSkill( thisRaceID, "Alien Lunge", "You can lunge forward for a quick attack", false );
	SKILL_REGEN = War3_AddRaceSkill( thisRaceID, "Alien regeneration", "Zerg slowly regenerate health", false );
	SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Metabolic Boost", "Increases the movement speed of Zerglings (To very fast but less hp)", false );
	SKILL_DMG = War3_AddRaceSkill( thisRaceID, "Adrenal Glands", "Increases the Damage of Zerglings (Left click only)", false );
	ULT_BURROW = War3_AddRaceSkill( thisRaceID, "Burrow", "Burrow underground", true );

	W3SkillCooldownOnSpawn( thisRaceID, ULT_BURROW, 5.0, _ );

	War3_CreateRaceEnd( thisRaceID );
	}
}

public OnMapStart()
{
	//War3_PrecacheSound( attack_sound );
	//War3_PrecacheSound( UltInstr );
	//War3_PrecacheSound( UltOutstr );
	SmokeSprite = PrecacheModel( "sprites/smoke.vmt" );
}

public OnPluginStart()
{
	CreateTimer( 2.5, CalcHexHeales, _, TIMER_REPEAT );
	m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
	m_vecVelocity_0 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[0]" );
	m_vecVelocity_1 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[1]" );
	HookEvent( "player_jump", PlayerJumpEvent );
	g_FadeUserMsgId = GetUserMessageId( "Fade" );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff( client, fMaxSpeed, thisRaceID, ZerglingSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
		
		SetEntityHealth( client, Health[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
		
		if( GetRandomFloat( 0.0, 1.0 ) <= ChanceJump[War3_GetSkillLevel( client, thisRaceID, SKILL_LONGJUMP )] )
		{
			bIsLongjumpActivated[client] = true;
			PrintToChat( client, "\x03Alien Lunge\x05: \x03You have the ability to Lunge this round." );
		}
		else
		{
			bIsLongjumpActivated[client] = false;
		}
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		W3ResetAllBuffRace(client,thisRaceID);
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
	StopBurrow( client );
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		InitPassiveSkills( client );
	}
}

public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
}

public PlayerJumpEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		new skill_long = War3_GetSkillLevel( client, race, SKILL_LONGJUMP );
		if( skill_long > 0 && bIsLongjumpActivated[client] )
		{
			new Float:velocity[3] = { 0.0, 0.0, 0.0 };
			velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
			velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
			velocity[0] *= 1.5 * 0.25;
			velocity[1] *= 1.5 * 0.25;
			SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
		}
	}
}

public OnW3TakeDmgBullet( victim, attacker, Float:damage )
{
	if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
	{
		new vteam = GetClientTeam( victim );
		new ateam = GetClientTeam( attacker );
		if( vteam != ateam )
		{
			new race_attacker = War3_GetRace( attacker );
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
			if( race_attacker == thisRaceID && skill_level > 0 )
			{
				if( GetRandomFloat( 0.0, 1.0 ) <= DMGChance[skill_level] && damage < 50 && !W3HasImmunity( victim, Immunity_Skills ) )
				{
					War3_DealDamage( victim, 30, attacker, _, "adrenal_glands", W3DMGORIGIN_SKILL, W3DMGTYPE_TRUEDMG );
					Drug( victim, 1 );
					CreateTimer( 1.0, Drug1, victim );
					CreateTimer( 2.0, Drug1, victim );
					CreateTimer( 3.0, Drug2, victim );
					EmitSoundToAll( attack_sound, victim );
				}
			}
		}
	}
}

public Action:Drug1( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		Drug( client, 1 );
	}
}

public Action:Drug2( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		Drug( client, 0 );
	}
}

stock Drug( client, mode )
{
	if( mode == 1 )
	{
		new Float:pos[3];
		GetClientAbsOrigin( client, pos );

		new Float:angs[3];
		GetClientEyeAngles( client, angs );

		angs[2] = g_DrugAngles[GetRandomInt( 0, 100 ) % 20];

		TeleportEntity( client, pos, angs, NULL_VECTOR );

		new clients[2];
		clients[0] = client;

		new Handle:message = StartMessageEx( g_FadeUserMsgId, clients, 1 );
		BfWriteShort( message, 255 );
		BfWriteShort( message, 255 );
		BfWriteShort( message, ( 0x0002 ) );
		BfWriteByte( message, GetRandomInt( 0, 255 ) );
		BfWriteByte( message, GetRandomInt( 0, 255 ) );
		BfWriteByte( message, GetRandomInt( 0, 255 ) );
		BfWriteByte( message, 128 );

		EndMessage();
	}
	
	if( mode == 0 )
	{
		new Float:pos[3];
		GetClientAbsOrigin( client, pos );

		new Float:angs[3];
		GetClientEyeAngles( client, angs );

		angs[2] = 0.0;

		TeleportEntity( client, pos, angs, NULL_VECTOR );	

		new clients[2];
		clients[0] = client;	

		new Handle:message = StartMessageEx( g_FadeUserMsgId, clients, 1 );
		BfWriteShort( message, 1536 );
		BfWriteShort( message, 1536 );
		BfWriteShort( message, ( 0x0001 | 0x0010 ) );
		BfWriteByte( message, 0 );
		BfWriteByte( message, 0 );
		BfWriteByte( message, 0 );
		BfWriteByte( message, 0 );

		EndMessage();
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && ValidPlayer( client, true ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_BURROW );
		if( ult_level > 0 )		
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_BURROW, true ) ) 
			{
				ToggleBurrow( client );
				AttachSmoke( client );
				War3_CooldownMGR( client, UltCooldown[ult_level], thisRaceID, ULT_BURROW, _, false );
			}
		}
		else
		{
			PrintHintText( client, "Level Your Ultimate First" );
		}
	}
}

stock StopBurrow( client )
{
	if( bIsBurrowed[client] )
	{
		bIsBurrowed[client] = false;
		
		War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
		
		EmitSoundToAll( UltOutstr, client );
		
		new Float:pos[3];
		
		GetClientAbsOrigin( client, pos );
		
		pos[2] += 70;
		
		TeleportEntity( client, pos, NULL_VECTOR, NULL_VECTOR );
	}
}

stock StartBurrow( client )
{
	if( !bIsBurrowed[client] )
	{
		bIsBurrowed[client] = true;
		
		War3_SetBuff( client, bNoMoveMode, thisRaceID, true );
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.0 );
		
		EmitSoundToAll( UltInstr, client );
		
		PrintToChat( client, "\x05: \x04You burrowed underground! Press \x03ultimate \x04again to unburrow!" );
		new Float:pos[3];
		
		GetClientAbsOrigin( client, pos );
		
		pos[2] -= 70;
		
		TeleportEntity( client, pos, NULL_VECTOR, NULL_VECTOR );
	}
}

stock ToggleBurrow( client )
{
	if( bIsBurrowed[client] )
	{
		StopBurrow( client );
	}
	else
	{
		StartBurrow( client );
	}
}

stock AttachSmoke( client )
{
	new Float:pos[3];
	GetClientAbsOrigin( client, pos );
	
	pos[2] += 15;
	
	TE_SetupSmoke( pos, SmokeSprite, 100.0, 10 );
	TE_SendToAll();
	
	TE_SetupSmoke( pos, SmokeSprite, 100.0, 10 );
	TE_SendToAll();
	
	TE_SetupSmoke( pos, SmokeSprite, 100.0, 10 );
	TE_SendToAll();
	
	TE_SetupSmoke( pos, SmokeSprite, 100.0, 10 );
	TE_SendToAll();
}

public Action:CalcHexHeales( Handle:timer, any:userid )
{
	if( thisRaceID > 0 )
	{
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) )
			{
				if( War3_GetRace( i ) == thisRaceID )
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
		if( bIsBurrowed[client] )
		{
			War3_HealToMaxHP( client, ( HealthRegen[skill] * 2 ) );
		}
		else
		{
			War3_HealToMaxHP( client, HealthRegen[skill] );
		}
	}
}