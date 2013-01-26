/**
* File: War3Source_Molecule.sp
* Description: The Molecule race for SourceCraft.
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
new Float:DamageMultiplier[6] = {0.0, 0.13, 0.16, 0.19, 0.21, 0.24};
new Float:EvadeChance[6] = {0.0, 0.15, 0.20, 0.25, 0.30, 0.35};
new Float:MoleculeSpeed[6] = {1.0, 1.1, 1.2, 1.3, 1.4, 1.5};
new Float:DmgChance[6] = {0.0, 0.15, 0.20, 0.25, 0.30, 0.35};
new Float:UltDuration[6] = {0.0, 1.0, 2.0, 3.0, 5.0, 7.0};
new String:spawn[] = "weapons/explode3.mp3";
new ShieldSprite, AttackSprite, EvadeSprite;
// new Float:RandMin = 0.01;
new bool:GOD[63];

new SKILL_SPEED, SKILL_DMG, SKILL_EVADE, ULT_FIELD;

public Plugin:myinfo = 
{
	name = "Molecule",
	author = "xDr.HaaaaaaaXx",
	description = "Molecule race for War3Source.",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	LoadTranslations("w3s.race.molecule.phrases");
}

public OnMapStart()
{
	////War3_PrecacheSound(spawn);
	ShieldSprite = PrecacheModel("sprites/strider_blackball.vmt");
	AttackSprite = PrecacheModel("sprites/physring1.vmt");
	EvadeSprite = PrecacheModel("sprites/blueshaft1.vmt");
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRaceT("molecule");
	
	SKILL_SPEED = War3_AddRaceSkillT(thisRaceID, "Speed", false, 5);	
	SKILL_DMG = War3_AddRaceSkillT(thisRaceID, "ElectricShock", false, 5);	
	SKILL_EVADE = War3_AddRaceSkillT(thisRaceID, "Evade", false, 5);
	ULT_FIELD = War3_AddRaceSkillT(thisRaceID, "ForceField", true, 5);
	
	W3SkillCooldownOnSpawn(thisRaceID, ULT_FIELD, 5.0, _);
	
	War3_CreateRaceEnd(thisRaceID);
}

public InitPassiveSkills(client)
{
	new ClientRace = War3_GetRace(client);
	if(ClientRace == thisRaceID)
	{
		new skill_speed = War3_GetSkillLevel(client, thisRaceID, SKILL_SPEED);
		new Float:speed = MoleculeSpeed[skill_speed];
		War3_SetBuff(client, fMaxSpeed, thisRaceID, speed);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		if(IsPlayerAlive(client))
		{
			InitPassiveSkills(client);
		}
	}
	else
	{
		W3ResetAllBuffRace(client,thisRaceID);
	}
}

public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
	InitPassiveSkills(client);
}

public OnWar3EventSpawn(client)
{
	new race = War3_GetRace(client);
	if(race == thisRaceID)
	{
		InitPassiveSkills(client);
		//EmitSoundToAll(spawn, client);
	}
}

public OnWar3EventPostHurt(victim, attacker, damage)
{
	if(W3GetDamageIsBullet() && ValidPlayer(victim, true) && ValidPlayer(attacker, true))
	{
		new ATeam = GetClientTeam(attacker);
		new VTeam = GetClientTeam(victim);
		new ARace = War3_GetRace(attacker);
		if(ARace == thisRaceID && VTeam != ATeam)
		{
			new skill_dmg = War3_GetSkillLevel(attacker, thisRaceID, SKILL_DMG);
			if(!Hexed(attacker, false) && skill_dmg > 0 && W3Chance(DmgChance[skill_dmg]))
			{
				new String:wpnstr[32];
				GetClientWeapon(attacker, wpnstr, 32);
				if(!StrEqual(wpnstr, "weapon_knife"))
				{
					War3_DealDamage(victim, RoundToFloor(damage * DamageMultiplier[skill_dmg]), attacker, DMG_BULLET, "electric_crit");
				
					W3PrintSkillDmgHintConsole(victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG);
					
					W3FlashScreen(victim, RGBA_COLOR_RED);
					
					new Float:pos[3];
					
					GetClientAbsOrigin(victim, pos);
					
					pos[2] += 15;
					
					TE_SetupGlowSprite(pos, AttackSprite, 3.0, 0.25, 255);
					TE_SendToAll();
				}
			}
		}
	}
}

public OnW3TakeDmgBulletPre(victim, attacker, Float:damage)
{
	if(ValidPlayer(victim, true) && ValidPlayer(attacker, true) && attacker != victim)
	{
		new vteam = GetClientTeam(victim);
		new ateam = GetClientTeam(attacker);
		if(vteam != ateam)
		{
			new VRace = War3_GetRace(victim);
			new skill_level = War3_GetSkillLevel(victim, thisRaceID, SKILL_EVADE);
			if(VRace == thisRaceID && skill_level > 0 && W3Chance(EvadeChance[skill_level]) && !GOD[victim])
			{
				if(!IsSkillImmune(attacker))
				{
					War3_DamageModPercent(0.0);
					W3MsgEvaded(victim, attacker);
					
					new Float:startpos[3];
					new Float:endpos[3];
					
					GetClientAbsOrigin(attacker, startpos);
					GetClientAbsOrigin(victim, endpos);
					
					TE_SetupBeamPoints(startpos, endpos, EvadeSprite, EvadeSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, {255, 255, 255, 255}, 0);
					TE_SendToAll();
				}
				else
				{
					W3MsgEnemyHasImmunity(victim, true);
				}
			}
		}
	}
}

public OnW3TakeDmgAllPre(victim, attacker, Float:damage)
{
	if(ValidPlayer(victim, true) && ValidPlayer(attacker, true) && attacker != victim)
	{
		new vteam = GetClientTeam(victim);
		new ateam = GetClientTeam(attacker);
		if(vteam != ateam)
		{
			new VRace = War3_GetRace(victim);
			new ult_level = War3_GetSkillLevel(victim, thisRaceID, ULT_FIELD);
			if(VRace == thisRaceID && ult_level > 0 && GOD[victim])
			{
				if(!IsUltImmune(attacker))
				{
					War3_DamageModPercent(0.0);
					
					new Float:startpos[3];
					new Float:endpos[3];
					
					GetClientAbsOrigin(attacker, startpos);
					GetClientAbsOrigin(victim, endpos);
					
					TE_SetupBeamPoints(startpos, endpos, EvadeSprite, EvadeSprite, 0, 0, 1.0, 1.0, 1.0, 0, 0.0, {255, 255, 255, 255}, 0);
					TE_SendToAll();
				}
				else
				{
					W3MsgEnemyHasImmunity(victim, true);
				}
			}
		}
	}
}

public OnUltimateCommand(client, race, bool:pressed)
{
	if(race == thisRaceID && pressed && IsPlayerAlive(client) && !Silenced(client))
	{
		new ult_level = War3_GetSkillLevel(client, race, ULT_FIELD);
		if(ult_level > 0)
		{
			if(War3_SkillNotInCooldown(client, thisRaceID, ULT_FIELD, true))
			{
				War3_SetBuff(client, bNoMoveMode, thisRaceID, true);
				
				GOD[client] = true;
				
				CreateTimer(UltDuration[ult_level], StopGod, client);
				
				War3_CooldownMGR(client, UltDuration[ult_level] + 15.0, thisRaceID, ULT_FIELD, _, false);
				
				new Float:pos[3];
				
				GetClientAbsOrigin(client, pos);
				
				pos[2] += 15;
				
				TE_SetupGlowSprite(pos, ShieldSprite, UltDuration[ult_level], 1.5, 255);
				TE_SendToAll();
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public Action:StopGod(Handle:timer, any:client)
{
	War3_SetBuff(client, bNoMoveMode, thisRaceID, false);
	
	GOD[client] = false;
}