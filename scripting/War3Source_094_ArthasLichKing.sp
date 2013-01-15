#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisRaceID
new S_1, S_2, S_3, S_4, U_1;

new BeamSprite, Plague, BlueCore, Smoke;
new m_vecBaseVelocity;

// Necrotic Plague (S_1)
new NecroticPlagueAttacker[MAXPLAYERS+1];
new bool:NecroticPlagueOn[MAXPLAYERS+1];
new Float:NecroticPlagueDuration[5]={0.0, 6.0, 8.0, 9.0, 10.0};
new Float:NecroticPlagueChance[5]={0.0, 0.14, 0.18, 0.22, 0.26};

// Soul Reaper (S_2)
new bool:ReaperOn[MAXPLAYERS+1];
new Float:ReaperPercentDamage[5]={1.0, 1.14, 1.26, 1.36, 1.42};
new Float:ReaperSpeedChance[5]={0.0, 0.08, 0.12, 0.16, 0.2};

// Harvest Soul (S_3)
new String:reviveSound[]="war3source/reincarnation.mp3";
new Float:HarvestChance[5]={0.0, 0.1, 0.21, 0.26, 0.34};

// Remorseless Winter (S_4)
new String:freezeSound[]="ambient/misc/metal2.mp3";
new bool:WinterIceEffect[MAXPLAYERS+1];
new Float:WinterRange[5]={0.0, 250.0, 300.0, 350.0, 400.0};
new Float:WinterTime[5]={0.0, 3.0, 3.5, 4.0, 4.5};

// Fury of Frostmourne (U_1)
new String:furySound[]="weapons/hegrenade/explode4.mp3";
new bool:FuryOn[MAXPLAYERS+1];
new Float:FuryRange[5]={0.0, 350.0, 400.0, 450.0, 500.0};
new FuryDamage[5]={0, 35, 45, 50, 60};

public Plugin:myinfo = 
{
	name = "War3Source Race - Lich King",
	author = "Revan (edit DiviX)",
	description = "Arthas - The Lich king race for war3source.",
	version = "1.0",
	url = "www.wcs-lagerhaus.de"
}

public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
	CreateTimer(2.0, NecroticPlagueCheck, _, TIMER_REPEAT);
	
	LoadTranslations("w3s.race.lichking.phrases");
}

public OnMapStart()
{
	BeamSprite=War3_PrecacheBeamSprite();
	Plague=PrecacheModel("materials/sprites/vortring1.vmt");
	BlueCore=PrecacheModel("materials/sprites/physcannon_bluecore2b.vmt");
	Smoke=PrecacheModel("materials/sprites/smoke.vmt");
	PrecacheModel("materials/particle/fire.vmt");
	//War3_PrecacheSound(reviveSound);
	//War3_PrecacheSound(freezeSound);
	//War3_PrecacheSound(furySound);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==203)
	{
		thisRaceID = War3_CreateNewRaceT("lichking");
		S_1 = War3_AddRaceSkillT(thisRaceID, "1", false, 4);	
		S_2 = War3_AddRaceSkillT(thisRaceID, "2", false, 4);	
		S_3 = War3_AddRaceSkillT(thisRaceID, "3", false, 4);
		S_4 = War3_AddRaceSkillT(thisRaceID, "4", false, 4)
		U_1 = War3_AddRaceSkillT(thisRaceID, "5", true, 4);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnWar3EventSpawn(client)
{
	ArthasResetAllBuffs(client);
}

ArthasResetAllBuffs(client)
{
	if(ValidPlayer(client))
	{
		NecroticPlagueOn[client]=false;
		NecroticPlagueAttacker[client]=0;
		
		ReaperOn[client]=false;
		War3_SetBuff(client, fAttackSpeed, thisRaceID, 1.0);
		
		ClientCommand(client, "r_screenoverlay 0");
		WinterIceEffect[client]=false;
		
		FuryOn[client]=false;
	}
}

public Action:NecroticPlagueCheck(Handle:timer, any:uid)
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(ValidPlayer(i, true))
			if(NecroticPlagueOn[i])
			{
				new attacker=NecroticPlagueAttacker[i];
				if(ValidPlayer(attacker, false))
					War3_DealDamage(i, 4, attacker, DMG_POISON, "Necrotic Plague", W3DMGORIGIN_SKILL);
			}
	}
}

public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim, true) && ValidPlayer(attacker, true))
	{
		if(GetClientTeam(victim) != GetClientTeam(attacker) && !W3HasImmunity(victim, Immunity_Skills) && victim != attacker)
		{
			if(War3_GetRace(attacker)==thisRaceID && !Hexed(attacker) && !Silenced(attacker))
			{
				new level_S_1=War3_GetSkillLevel(attacker, thisRaceID, S_1);
				if(level_S_1>0 && GetRandomFloat(0.0,1.0) <= NecroticPlagueChance[level_S_1])
				{
					NecroticPlagueOn[victim]=true;
					NecroticPlagueAttacker[victim]=attacker;
					CreateTimer(NecroticPlagueDuration[level_S_1], Timer_ExecutePlagueBuff, victim);
					CreateTimer(NecroticPlagueDuration[level_S_1], Timer_PlagueBuffOff, victim);
					
					// Effect
					new Float:attacker_pos[3], Float:victim_pos[3];
					GetClientAbsOrigin(attacker, Float:attacker_pos); 
					GetClientAbsOrigin(victim, Float:victim_pos);
					attacker_pos[2]+=35.0, victim_pos[2]+=40.0;
					TE_SetupBeamPoints(attacker_pos, victim_pos, Plague, Plague, 0, 200, 1.5, 28.0, 16.0, 0, 0.5, {20,255,15,255}, 30);
					TE_SendToAll();
				}
			}
		}
	}
}


public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{

	
	if(ValidPlayer(victim, true) && ValidPlayer(attacker, true))
	{
		if(GetClientTeam(victim) != GetClientTeam(attacker) && !W3HasImmunity(victim, Immunity_Skills) && victim != attacker)
			if(War3_GetRace(attacker)==thisRaceID && !Hexed(attacker))
			{
				new level_S_2=War3_GetSkillLevel(attacker, thisRaceID, S_2);
				if(level_S_2>0)
				{
					War3_DamageModPercent(ReaperPercentDamage[level_S_2]);
					
					// Effect
					new Float:victim_pos[3], Float:attacker_pos[3];
					GetClientAbsOrigin(victim, victim_pos);
					GetClientAbsOrigin(attacker, attacker_pos);
					// Effect
					victim_pos[2]+=35;
					attacker_pos[2]+=50;
					TE_SetupBeamPoints(attacker_pos, victim_pos, BeamSprite, BeamSprite, 0, 35, 1.0, 10.0, 10.0, 0, 10.0, {210,210,255,255}, 30);
					TE_SendToAll();
					// Effect
					victim_pos[2]-=25;
					attacker_pos[2]-=10;
					TE_SetupBeamPoints(victim_pos, attacker_pos, BeamSprite, BeamSprite, 0, 35, 1.0, 10.0, 10.0, 0, 10.0, {210,210,255,255}, 30);
					TE_SendToAll();
					if(GetRandomFloat(0.0,1.0)<=ReaperSpeedChance[level_S_2])
					{
						// Effect
						attacker_pos[2]+=55;
						TE_SetupGlowSprite(attacker_pos, BeamSprite, 1.0, 3.5, 255);
						TE_SendToAll();
						
						ReaperOn[attacker]=true;
						War3_SetBuff(attacker, fAttackSpeed, thisRaceID, 1.45);
						PrintHintText(attacker, "%T", "Raised attack speed for 5 Seconds", attacker);
						CreateTimer(5.0, Timer_ReaperBuffOff, attacker);
					}
				}
			}
	}
	
	if(ValidPlayer(victim, true) && ValidPlayer(attacker, true))
	{
		if(WinterIceEffect[victim])
		{
			new weapon = W3GetCurrentWeaponEnt(attacker);
			if(IsValidEdict(weapon))
				if(weapon>0)
				{
					decl String:wpn_name[64];
					GetEdictClassname(weapon, wpn_name, sizeof(wpn_name));
					if(StrContains(wpn_name, "weapon_knife", false) < 0 && !W3IsDamageFromMelee(wpn_name))
					{
						War3_DamageModPercent(0.0);
						PrintCenterText(attacker, "%T", "You can only damage your enemy with melee weapons!", attacker);
						// Effect
						new Float:pos[3];
						GetClientAbsOrigin(victim, pos);
						pos[2] += 38;
						TE_SetupBeamRingPoint(pos, 10.0, 9999.0, BeamSprite, BeamSprite, 2, 6, 1.0, 18.0, 7.0, {120,255,120,255}, 40, 0);
						TE_SendToAll();
					}
				}
		}
	}
}

public Action:Timer_PlagueBuffOff(Handle:timer, any:client)
{
	if(ValidPlayer(client, false))
	{
		NecroticPlagueAttacker[client]=0;
		if(NecroticPlagueOn[client])
		{
			NecroticPlagueOn[client]=false;
			if(IsPlayerAlive(client))
				PrintHintText(client, "%T", "Necrotic Plague disappears!", client);
		}
	}
}

public Action:Timer_ExecutePlagueBuff(Handle:timer, any:client)
{
	if(ValidPlayer(client, false))
	{
		if(NecroticPlagueOn[client])
		{
			CreateTimer(0.0, Timer_PlagueBuffOff, client);
			for(new i=1; i<=MaxClients; i++)
			{
				new attacker=NecroticPlagueAttacker[client];
				if(ValidPlayer(i, true) && ValidPlayer(attacker, false))
				{
					new level=War3_GetSkillLevel(attacker, thisRaceID, S_1);
					if(i != client && GetClientTeam(i) != GetClientTeam(attacker) && level>0)
					{
						new Float:client_pos[3], Float:i_pos[3];
						GetClientAbsOrigin(i, i_pos);
						GetClientAbsOrigin(i, client_pos);
						i_pos[2] += 36.0;
						TE_SetupBeamRingPoint(i_pos, 10.0, 395.0, BeamSprite, BeamSprite, 2, 6, 1.295, 60.0, 7.0, {120,255,120,255}, 40, 0);
						TE_SendToAll();
						TE_SetupBeamRingPoint(i_pos, 10.0, 395.0, BeamSprite, BeamSprite, 2, 6, 0.20, 60.0, 7.0, {120,255,120,255}, 40, 0);
						TE_SendToAll(0.45);
						i_pos[2]-=36.0;
						new Float:distance=GetVectorDistance(client_pos, i_pos);
						if(distance < 380.0)
						{
							NecroticPlagueOn[i]=true;
							NecroticPlagueAttacker[i]=attacker;
							CreateTimer(NecroticPlagueDuration[level], Timer_PlagueBuffOff, i);
							
							// Effect
							i_pos[2]+=50;
							TE_SetupGlowSprite(i_pos, Plague, 1.28, 1.28, 255);
							TE_SendToAll();
							
							War3_ChatMessage(i, "%T", "You're infected with a Necrotic Plague!", i);
						}
					}
				}
			}
		}
	}
}

public Action:Timer_ReaperBuffOff(Handle:timer, any:client)
{
	if(ReaperOn[client])
	{
		ReaperOn[client]=false;
		// Effect
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);
		pos[2]+=38;
		TE_SetupBeamRingPoint(pos, 10.0, 20.0, Smoke, Smoke, 2, 6, 1.5, 10.0, 7.0, {120,120,255,255}, 40,0);
		TE_SendToAll();
		
		War3_SetBuff(client, fAttackSpeed, thisRaceID, 1.0);
	}
}

public OnWar3EventDeath(victim, attacker)
{
	ArthasResetAllBuffs(victim);
	
	if(ValidPlayer(attacker, false) && ValidPlayer(victim, false))
	{
		new level=War3_GetSkillLevel(attacker, thisRaceID, S_3);
		if(War3_GetRace(attacker)==thisRaceID)
		{
			if(level>0 && !Hexed(attacker, false))
				if(GetRandomFloat(0.0,1.0) <= HarvestChance[level])
					for(new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i, false))
							if(i != attacker && GetClientTeam(i) == GetClientTeam(attacker) && !IsPlayerAlive(i))
							{
								War3_SpawnPlayer(i);
								War3_ChatMessage(i, "%T", "Arthas revived you!", i);
								// Effect
								EmitSoundToAll(reviveSound,i);
								
								new Float:attacker_pos[3];
								GetClientAbsOrigin(attacker, attacker_pos);
								attacker_pos[2] += 40;
								TE_SetupBeamRingPoint(attacker_pos, 10.0, 200.0, BeamSprite, BeamSprite, 0, 120, 3.5, 12.0, 5.0, {255,255,255,120}, 60, 0);
								TE_SendToAll();
								
								attacker_pos[2]-=10;
								TE_SetupBeamRingPoint(attacker_pos, 10.0, 200.0, BeamSprite, BeamSprite, 0, 120, 3.5, 12.0, 5.0, {255,255,255,120}, 60, 0);
								TE_SendToAll(0.35);
								
								attacker_pos[2]-=10;
								TE_SetupBeamRingPoint(attacker_pos, 10.0, 200.0, BeamSprite, BeamSprite, 0, 120, 3.5, 12.0, 5.0, {255,255,255,120}, 60, 0);
								TE_SendToAll(0.65);
								
								attacker_pos[2]-=10;
								TE_SetupBeamRingPoint(attacker_pos, 10.0, 200.0, BeamSprite, BeamSprite, 0, 120, 3.5, 12.0, 5.0, {255,255,255,120}, 60, 0);
								TE_SendToAll(0.95);
								break;
							}
					}
		}
	}
}

public OnAbilityCommand(client, ability, bool:pressed)
{
	if(ValidPlayer(client, true))
		if(War3_GetRace(client) == thisRaceID && pressed)
			if(!Hexed(client) && !Silenced(client) && War3_SkillNotInCooldown(client, thisRaceID, S_4, true))
			{
				new level = War3_GetSkillLevel(client, thisRaceID, S_4);
				if(level>0)
				{
					RemorselessWinter(client, level);
					War3_ChatMessage(client, "%T", "Remorseless Winter (%f feets range)", client, WinterRange[level]/10);
					War3_CooldownMGR(client, 20.0, thisRaceID, S_4);
					new Float:client_pos[3];
					GetClientAbsOrigin(client, client_pos);
					for(new i=1; i<=MaxClients; i++)
					{
						if(ValidPlayer(i,true))
						{
							new Float:i_pos[3];
							GetClientAbsOrigin(i, i_pos);
							if(i != client && GetClientTeam(i) != GetClientTeam(client) && !W3HasImmunity(i, Immunity_Ultimates) && !W3HasImmunity(i, Immunity_Skills))
								if(GetVectorDistance(client_pos, i_pos) < WinterRange[level])
								{
									ClientCommand(i, "r_screenoverlay effects/rollerglow");
									i_pos[2] += 50;
									TE_SetupGlowSprite(i_pos, BlueCore, 1.0, 1.0, 255);
									TE_SendToAll();
									WinterIceEffect[i]=true;
									War3_SetBuff(i, bBashed, thisRaceID, true);
									W3SetPlayerColor(i, thisRaceID, 120, 120, 255, 180, 0);
									FakeClientCommand(i, "use weapon_knife");
									W3FlashScreen(i, RGBA_COLOR_BLUE, 0.34, 0.2, FFADE_IN);
									CreateTimer(0.35, Loop_IceEffects, i);
									CreateTimer(WinterTime[level], Timer_RemoveIceEffect, i);
								}
						}
					}
				}
			}
}

public Action:RemorselessWinter(client, level)
{
	new particle = CreateEntityByName("env_smokestack");
	if(IsValidEdict(particle))
	{
		decl String:Name[64], Float:fPos[3], Float:fAng[3] = {0.0, 0.0, 0.0};
		Format(Name, sizeof(Name), "Winter_%i", client);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
		fPos[2] += 30;

		//Set Key Values
		DispatchKeyValueVector(particle, "Origin", fPos);
		DispatchKeyValueVector(particle, "Angles", fAng);
		DispatchKeyValueFloat(particle, "BaseSpread", 450.0);
		DispatchKeyValueFloat(particle, "StartSize", 21.0);
		DispatchKeyValueFloat(particle, "EndSize", 11.0);
		DispatchKeyValueFloat(particle, "Twist", 80.0);
		
		DispatchKeyValue(particle, "Name", Name);
		DispatchKeyValue(particle, "SmokeMaterial", "particle/fire.vmt");
		DispatchKeyValue(particle, "RenderColor", "100 100 220");
		DispatchKeyValue(particle, "RenderAmt", "200");
		DispatchKeyValue(particle, "SpreadSpeed", "600");
		DispatchKeyValue(particle, "JetLength", "600");
		DispatchKeyValue(particle, "Speed", "200");
		DispatchKeyValue(particle, "Rate", "148");
		DispatchSpawn(particle);
		
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", client, particle, 0);
		AcceptEntityInput(particle, "TurnOn");
		
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);
		pos[2] += 40;
		TE_SetupBeamRingPoint(pos, 10.0, 10+WinterRange[level], BeamSprite, BeamSprite, 0, 120, 3.5, 12.0, 5.0, {100,100,255,120}, 60, 0);
		TE_SendToAll();
		EmitSoundToAll(freezeSound, client);
		CreateTimer(5.0, Timer_RSTargetEntinty, particle); //dynamic turn off, so it not look like shit
	}
	else
		LogError("[SM] Failed to create env_smokestack ent!");
}

public Action:Timer_RSTargetEntinty(Handle:timer, any:particle)
{
	AcceptEntityInput(particle, "TurnOff");
	AcceptEntityInput(particle, "Kill");
}

public Action:Timer_RemoveIceEffect(Handle:timer, any:client)
{
	ClientCommand(client, "r_screenoverlay 0"); 
	WinterIceEffect[client]=false;
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2] += 38;
	TE_SetupBeamRingPoint(pos, 10.0, 9999.0, BlueCore, BlueCore, 2, 6, 1.5, 100.0, 7.0, {120,120,255,255}, 40,0);
	TE_SendToAll();
	War3_SetBuff(client, bBashed, thisRaceID, false);
	W3ResetPlayerColor(client, thisRaceID);
}

public Action:Loop_IceEffects(Handle:timer, any:client)
{
	if(ValidPlayer(client, true))
		if(WinterIceEffect[client])
		{
			PrintCenterText(client, "%T", "You are turned into an Ice block!", client);
			FakeClientCommand(client, "use weapon_knife");
			new Float:pos[3];
			GetClientAbsOrigin(client, pos);
			pos[2]+=38;
			TE_SetupBeamRingPoint(pos, 10.0, 20.0, Smoke, Smoke, 2, 6, 0.42, 100.0, 7.0, {100,100,255,160}, 40,0);
			TE_SendToAll();
			W3FlashScreen(client, RGBA_COLOR_BLUE);
			CreateTimer(0.35, Loop_IceEffects, client);
		}
}

public OnUltimateCommand(client, race, bool:pressed)
{
	if(ValidPlayer(client, true))
		if(race==thisRaceID && pressed)
		{
			new level=War3_GetSkillLevel(client, race, U_1);
			if(level>0)
			{
				if(!Hexed(client) && !Silenced(client) && War3_SkillNotInCooldown(client, thisRaceID, U_1, true))
				{
					ClientCommand(client, "r_screenoverlay effects/tp_refract");
					War3_CooldownMGR(client, 20.0, thisRaceID, U_1);
					new Float:client_location[3];
					GetClientAbsOrigin(client, client_location);
					client_location[2] += 20;
					TE_SetupBeamRingPoint(client_location, 620.0, 10.0, BeamSprite, BeamSprite, 0, 15, 0.5, 10.0, 10.0, {255,255,255,255}, 120, 0);
					TE_SendToAll();
					TE_SetupBeamFollow(client, BeamSprite, 0, 0.65, 10.0, 20.0, 20, {200,200,255,255});
					TE_SendToAll();
					ForceClientJump(client);
					FuryOn[client]=true;
					CreateTimer(1.1, Timer_frostmourne, client);
				}
			}
			else
				W3MsgUltNotLeveled(client);
		}
}

ForceClientJump(client)
{
	new Float:startpos[3];
	new Float:endpos[3];
	new Float:localvector[3];
	new Float:velocity[3];
	
	GetClientAbsOrigin(client, startpos);
	GetClientAbsOrigin(client, endpos);
	endpos[2] += 180;
	localvector[2] = endpos[2] - startpos[2];
	
	velocity[0] = localvector[0];
	velocity[1] = localvector[1];
	velocity[2] = localvector[2] * 2.6;
	SetEntDataVector(client, m_vecBaseVelocity, velocity, true);
}

public Action:Timer_frostmourne(Handle:timer, any:client)
{
	if(ValidPlayer(client, true))
	{
		ClientCommand(client, "r_screenoverlay 0");
		if(FuryOn[client])
		{
			new Float:client_pos[3];
			GetClientAbsOrigin(client, client_pos);
			new level=War3_GetSkillLevel(client, War3_GetRace(client), U_1);
			for(new i=1; i<=MaxClients; i++)
			{
				if(ValidPlayer(i,true))
					if(!W3HasImmunity(i, Immunity_Ultimates))
					{
						new Float:i_pos[3];
						GetClientAbsOrigin(i, i_pos);
						if(GetVectorDistance(i_pos, client_pos) < FuryRange[level] && GetClientTeam(client) !=GetClientTeam(i) && !WinterIceEffect[i])
						{
							FuryOn[i]=false;
							i_pos[2]+=35;
							TE_SetupBeamRingPoint(client_pos, 10.0, 2000.0, Smoke, Smoke, 2, 6, 1.9, 5.0, 7.0, {120, 100, 255, 160}, 40,0);
							TE_SendToAll();
							TE_SetupBeamPoints(client_pos, i_pos, BlueCore, BlueCore, 0, 50, 1.0, 50.0, 16.0, 0, 1.5, {200, 200, 255, 255}, 30);
							TE_SendToAll();
							EmitSoundToAll(furySound, client);
							War3_DealDamage(i, GetRandomInt(1, 6)+FuryDamage[level], client, DMG_SLASH, "Frostmourne", W3DMGORIGIN_ULTIMATE, W3DMGTYPE_TRUEDMG);
							for(new sfx=1;sfx<=5;sfx++)
							{
								i_pos[2]+=10;
								TE_SetupBeamRingPoint(i_pos, 40.0, 100.0, BeamSprite, BeamSprite, 0, 15, 1.1, 10.0, 10.0, {200,200,255,255}, 120, 0);
								TE_SendToAll();
							}
						}
					}
			}
		}
	}	
}