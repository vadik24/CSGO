/**
* File: War3Source_Element.sp
* Description: The Element race for SourceCraft.
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
new thisRaceID, SKILL_ATTACK, SKILL_SPEED, SKILL_TIME, ULT_PUSH;

// Chance/Data Arrays
new Float:ImpulseChance[6] = { 0.0, 0.10, 0.12, 0.14, 0.15, 0.18 };
new Float:TimeChance[6] = { 0.0, 0.20, 0.25, 0.27, 0.28, 0.30 };
new Float:ElementSpeed[6] = { 0.0, 1.15, 1.20, 1.23, 1.24, 1.28 };
new Float:TimeDelay[6] = { 0.0, 2.0, 3.0, 5.0, 7.0, 8.0 };
new ImpulseDamage[6] = { 0, 1, 2, 3, 4, 7 };
new GravForce[6] = { 0, 1, 1, 1, 1, 2 };
new Float:AttackerPos[64][3];
new Float:FlyDuration = 1.8;
new Float:ClientPos[64][3];

// Sounds
new String:citadelsound[] = "ambient/levels/citadel/weapon_disintegrate3.mp3";
new String:sound1[] = "weapons/physcannon/physcannon_pickup.mp3";
new String:spawn[] = "weapons/physcannon/superphys_launch2.mp3";
new String:sound2[] = "weapons/physcannon/energy_bounce1.mp3";
new String:death[] = "weapons/physcannon/physcannon_drop.mp3";
new String:spawn1[] = "ambient/machines/machine1_hit1.mp3";
new String:spawn2[] = "weapons/irifle/irifle_fire2.mp3";

// Other
new HaloSprite, AttackSprite1, AttackSprite2;
new m_vecBaseVelocity;
new bool:bTimed[MAXPLAYERS];

public Plugin:myinfo = 
{
	name = "War3Source Race - Element++",
	author = "xDr.HaaaaaaaXx & Revan",
	description = "The Element race for War3Source.",
	version = "1.0.0.0",
	url = "www.wcs-lagerhaus.de"
};

public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
	HookEvent( "player_death", PlayerDeathEvent );
	HookEvent("round_start",RoundStartEvent);
}

public OnMapStart()
{
	////War3_PrecacheSound( citadelsound );
	////War3_PrecacheSound( sound1 );
	////War3_PrecacheSound( spawn );
	////War3_PrecacheSound( sound2 );
	////War3_PrecacheSound( death );
	////War3_PrecacheSound( spawn1 );
	////War3_PrecacheSound( spawn2 );
	HaloSprite = War3_PrecacheHaloSprite();
	AttackSprite1 = PrecacheModel( "materials/sprites/purplelaser1.vmt" );
	AttackSprite2 = PrecacheModel( "materials/sprites/glow.vmt" );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Element", "element" );
	
	SKILL_ATTACK = War3_AddRaceSkill( thisRaceID, "ImpulseRifle", "Do more Damage and Disentegrate the enemie", false, 5 );	
	SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Transport", "Go a little faster", false, 5 );	
	SKILL_TIME = War3_AddRaceSkill( thisRaceID, "Times Element", "Go back to the exact moment before death", false, 5 );
	ULT_PUSH = War3_AddRaceSkill( thisRaceID, "Gravity Gun", "Pull the enemy player torward you", true, 5 );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_PUSH, 5.0, true );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		new skill_speed = War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED );
		new Float:speed = ElementSpeed[skill_speed];
		War3_SetBuff( client, fMaxSpeed, thisRaceID, speed );
	}
}

public OnRaceChanged( client, oldrace, newrace )
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
		//EmitSoundToAll( spawn1, client );
		//EmitSoundToAll( spawn2, client );
		W3SetPlayerColor( client, thisRaceID, 120, 120, 120, _, GLOW_DEFAULT );
		new Float:iVec[ 3 ];
		GetClientAbsOrigin( client, Float:iVec );
		TE_SetupBeamRingPoint(iVec, 500.0, 20.0, AttackSprite2, AttackSprite2, 0, 15, 3.0, 5.0, 3.0, {0,0,255,255}, 10, 0);
		TE_SendToAll();
		iVec[2]+20.0;
		TE_SetupBeamRingPoint(iVec, 500.0, 20.0, AttackSprite2, AttackSprite2, 0, 15, 3.0, 5.0, 3.0, {0,0,255,255}, 10, 0);
		TE_SendToAll(0.235);
		iVec[2]+20;
		TE_SetupBeamRingPoint(iVec, 500.0, 20.0, AttackSprite2, AttackSprite2, 0, 15, 3.0, 5.0, 3.0, {0,0,255,255}, 10, 0);
		TE_SendToAll(0.435);
	}
	else
	{
		W3ResetPlayerColor( client, thisRaceID );
	}
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_ATTACK );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= ImpulseChance[skill_level] )
			{
				new impulsedamage = ImpulseDamage[skill_level];
				if(impulsedamage == 7)
				impulsedamage = GetRandomInt(5,6);

				War3_DealDamage( victim, impulsedamage, attacker, DMG_BULLET, "impulse_rifle" );
				W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_ATTACK);
				
				new Float:StartPos[3];
				new Float:EndPos[3];
				
				GetClientAbsOrigin( attacker, StartPos );
				GetClientAbsOrigin( victim, EndPos );
				
				StartPos[2] += 40;
				EndPos[2] += 40;
				
				TE_SetupBeamPoints( StartPos, EndPos, AttackSprite1, HaloSprite, 0, 1, 0.5, 0.5, 0.5, 0, 0.0, { 254, 254, 254, 255 }, 1 );
				TE_SendToAll();
				
				TE_SetupBeamPoints( StartPos, EndPos, AttackSprite1, HaloSprite, 0, 1, 0.5, 0.5, 0.5, 0, 0.0, { 254, 254, 254, 255 }, 1 );
				TE_SendToAll();
				
				TE_SetupBeamPoints( StartPos, EndPos, AttackSprite2, HaloSprite, 0, 1, 0.5, 2.5, 2.5, 0, 0.0, { 254, 254, 254, 255 }, 1 );
				TE_SendToAll();

				TE_SetupBeamPoints( StartPos, EndPos, AttackSprite2, HaloSprite, 0, 1, 0.5, 2.5, 2.5, 0, 0.0, { 254, 254, 254, 254 }, 1 );
				TE_SendToAll();

				TE_SetupBeamPoints( StartPos, EndPos, HaloSprite, HaloSprite, 0, 1, 0.5, 1.5, 1.5, 0, 0.0, { 254, 254, 254, 254 }, 1 );
				TE_SendToAll();
				
				TE_SetupBeamRingPoint(EndPos, 20.0, 22.0, HaloSprite, HaloSprite, 0, 15, 3.0, 45.0, 1.0, {255,255,255,255}, 10, 0);
				TE_SendToAll();
				
				TE_SetupBeamRingPoint(EndPos, 22.0, 200.0, HaloSprite, HaloSprite, 0, 15, 2.0, 10.0, 1.0, {255,255,255,255}, 10, 0);
				TE_SendToAll(0.6);
				StartPos[2]+=5;
				for( new Float:fx_timer = 0.0 ; fx_timer <= 3.6; fx_timer+= 0.21)
				{
					TE_SetupBeamPoints( StartPos, EndPos, AttackSprite1, HaloSprite, 0, GetRandomInt(5,20), 0.2, 0.5, 0.5, 0, 0.25, { 254, 254, 254, 255 }, 1 );
					TE_SendToAll(fx_timer);
					
					TE_SetupBeamPoints( StartPos, EndPos, AttackSprite2, HaloSprite, 0, GetRandomInt(5,20), 0.2, 2.5, 2.5, 0, 0.25, { 254, 254, 254, 255 }, 1 );
					TE_SendToAll(fx_timer);
					StartPos[2]+=5;
				}
				
				//EmitSoundToAll( citadelsound, victim );
				//EmitSoundToAll( citadelsound, attacker );
				new SmokeEnt = CreateEntityByName("env_entity_dissolver");
				if(SmokeEnt)
				{
					new String:SName[128];
					Format(SName, sizeof(SName), "dissolve_%i", victim);
					DispatchKeyValue(SmokeEnt,"target", "cs_ragdoll");
					DispatchKeyValue(SmokeEnt,"magnitude", "4500");
					DispatchKeyValue(SmokeEnt,"dissolvetype", "3");
					DispatchSpawn(SmokeEnt);
					AcceptEntityInput(SmokeEnt, "Dissolve");
					new Float:delay = 8.0;
					new Handle:pack;
					CreateDataTimer(delay, Timer_StopSmoke, pack);
					WritePackCell(pack, SmokeEnt);
				}
			}
		}
	}
}

public Action:Timer_StopSmoke(Handle:timer, Handle:pack)
{      
	ResetPack(pack);
	new SmokeEnt = ReadPackCell(pack);
	if (IsValidEntity(SmokeEnt))
	{
		RemoveSmokeEnt(SmokeEnt);
	}
}

RemoveSmokeEnt(target)
{
	if (IsValidEntity(target))
	{
		AcceptEntityInput(target, "Kill");
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_PUSH );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_PUSH, true ) )
			{
				Push( client );
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

Action:Push( client )
{
	new Float:besttargetDistance = 850.0; 
	new Float:posVec[3];
	new Float:otherVec[3];
	new team = GetClientTeam( client );
	new besttarget;
	new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_PUSH );
	
	GetClientAbsOrigin( client, posVec );
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( ValidPlayer( i, true ) && GetClientTeam( i ) != team && !W3HasImmunity( i, Immunity_Ultimates ) )
		{
			GetClientAbsOrigin( i, otherVec );
			new Float:dist = GetVectorDistance( posVec, otherVec );
			if( dist < besttargetDistance )
			{
				besttarget = i;
				besttargetDistance = GetVectorDistance( posVec, otherVec );
			}
		}
	}
	
	if( besttarget == 0 )
	{
		PrintHintText( client, "No Target Found within %.1f feet", besttargetDistance / 10 );
	}
	else
	{
		new Float:pos1[3];
		new Float:pos2[3];
		
		GetClientAbsOrigin( client, pos1 );
		GetClientAbsOrigin( besttarget, pos2 );
		
		new Float:localvector[3];
		
		localvector[0] = pos1[0] - pos2[0];
		localvector[1] = pos1[1] - pos2[1];
		localvector[2] = pos1[2] - pos2[2];

		new Float:velocity1[3];
		new Float:velocity2[3];
		
		velocity1[0] += 0;
		velocity1[1] += 0;
		velocity1[2] += 300;
		
		velocity2[0] = localvector[0] * ( 100 * GravForce[ult_level] );
		velocity2[1] = localvector[1] * ( 100 * GravForce[ult_level] );
		velocity2[2] = localvector[2] * ( 100 * GravForce[ult_level] );
		
		SetEntDataVector( besttarget, m_vecBaseVelocity, velocity1, true );
		SetEntDataVector( besttarget, m_vecBaseVelocity, velocity2, true );
		
		//EmitSoundToAll( sound1, client );
		//EmitSoundToAll( sound1, besttarget );
		
		//EmitSoundToAll( sound2, client );
		//EmitSoundToAll( sound2, besttarget );
		
		War3_SetBuff( besttarget, bFlyMode, thisRaceID, true );
		War3_DealDamage( besttarget, 1, client, DMG_BULLET, "element_crit" );
		CreateTimer( FlyDuration, StopFly, besttarget );
		
		new String:NameAttacker[64];
		GetClientName( client, NameAttacker, 64 );
		
		new String:NameVictim[64];
		GetClientName( besttarget, NameVictim, 64 );
		
		PrintToChat( client, ": You have pulled %s closer to you", NameVictim );
		PrintToChat( besttarget, ": You have been pulled torward %s", NameAttacker );
		
		new Float:startpos[3];
		new Float:endpos[3];
		GetClientAbsOrigin( client, startpos );
		GetClientAbsOrigin( besttarget, endpos );
		startpos[2]+=45;
		endpos[2]+=45;
		TE_SetupBeamPoints( startpos, endpos, AttackSprite1, HaloSprite, 0, 20, 1.5, 1.0, 20.0, 0, 8.5, { 200, 200, 200, 255 }, 0 );
		TE_SendToAll();

		War3_CooldownMGR( client, 20.0, thisRaceID, ULT_PUSH, _, true);
	}
}

public Action:StopFly( Handle:timer, any:client )
{
	new Float:iVec[ 3 ];
	GetClientAbsOrigin( client, Float:iVec );
	for( new sfx = 1; sfx <= 10; sfx++ )
	{
		iVec[2]+=25.0;
		TE_SetupBeamRingPoint(iVec, 10.0, 200.0, HaloSprite, HaloSprite, 0, 15, 1.0, 5.0, 0.0, {120,120,255,255}, 10, 0);
		TE_SendToAll();
	}
	War3_SetBuff( client, bFlyMode, thisRaceID, false );
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
for(new x=1;x<=64;x++)
if( ValidPlayer( x, false ) )
		bTimed[x]=false;

		public PlayerDeathEvent( Handle:event, const String:name[], bool:dontBroadcast )
		{
			new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
			new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
			if( War3_GetRace( client ) == thisRaceID && attacker != client && attacker != 0 )
	{
		new skill_time = War3_GetSkillLevel( client, thisRaceID, SKILL_TIME );
		if( skill_time > 0 && GetRandomFloat( 0.0, 1.0 ) <= TimeChance[skill_time] )
		{
			bTimed[client]=true;
			GetClientAbsOrigin( client, ClientPos[client] );
			GetClientAbsOrigin( attacker, AttackerPos[attacker] );
			
			CreateTimer( TimeDelay[skill_time], SpawnClient, client );
			CreateTimer( TimeDelay[skill_time], SpawnAttacker, attacker );
			
			PrintToChat( client, ": In %f seconds Time's Element will peice together your last Moment", TimeDelay[skill_time] );
			PrintToChat( attacker, ": In %f seconds you go back in time to this verry moment", TimeDelay[skill_time] );
			PrintToConsole( client, "[WAR3] Skill activated : Times Element" );
			//EmitSoundToAll( death, client );
			//EmitSoundToAll( death, attacker );

			new Float:iVec[ 3 ];
			GetClientAbsOrigin( attacker, Float:iVec );
			TE_SetupBeamRingPoint(iVec, 10.0, 20.0, HaloSprite, HaloSprite, 0, 15, TimeDelay[skill_time]+3.0, 5.0, 0.0, {120,120,255,255}, 10, 0);
			TE_SendToAll();
		}
	}
}

public Action:SpawnClient( Handle:timer, any:client )
{
	War3_SpawnPlayer( client );
	CreateTimer( 0.2, TeleportClient, client );
}

public Action:TeleportClient( Handle:timer, any:client )
{
	TeleportEntity( client, ClientPos[client], NULL_VECTOR, NULL_VECTOR );
	//EmitSoundToAll( spawn, client );
}

public Action:SpawnAttacker( Handle:timer, any:attacker )
{
	War3_SpawnPlayer( attacker );
	CreateTimer( 0.2, TeleportAttacker, attacker );
}

public Action:TeleportAttacker( Handle:timer, any:attacker )
{
	TeleportEntity( attacker, AttackerPos[attacker], NULL_VECTOR, NULL_VECTOR );
	//EmitSoundToAll( spawn, attacker );
}