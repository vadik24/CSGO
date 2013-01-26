/**
* File: 					War3Source_SpiderMan.sp
* Description: 				The ES version of SpiderMan race for War3Source.
* Author(s): 				Necavi, Schmarotzer, Frenzzy
* Original idea: 			HOLLIDAY
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>

#define DMG_FALL   (1 << 5)

new thisRaceID;
new String:NinjaMdl[]="models/player/techknow/spiderman3/spiderman3.mdl";
//skill1
new Float:SSenseChance[6] = {0.0,0.17,0.21,0.25,0.27,0.30};

//skill2
new Float:LongJump[6] = {1.09,1.10,1.12,1.14,1.18,1.20};
new Float:NewSpeed[6] = {1.0,1.06,1.05,1.10,1.15,1.20};

//skill3
new Float:WebTime[6] = {0.0,0.5,0.6,0.7,0.8,0.9};
new Float:WebChance[6] = {0.0,0.04,0.08,0.12,0.16,0.20};
new bool:bIsCatched[MAXPLAYERS];
new Float:LastDamageTime[MAXPLAYERS];

//skill4
new Force[6] = {0,600,650,700,750,850};
new Float:Cooldown[6] = {0.0,6.0,5.5,5.0,4.5,4.0};
new String:UltimateSound[]="weapons/357/357_spin1.mp3";

// ====================================================
new SenseSprite, WebSprite1, WebSprite2;
// ====================================================
new BeamSprite,HaloSprite;

new SKILL_EVADE,SKILL_SPEED,SKILL_STUN,ULT_WEB;

public Plugin:myinfo = 
{
	name = "War3Source Race - Spiderman",
	author = "Necavi, Schmarotzer, Frenzzy",
	description = "The ES SpiderMan race for War3Source.",
	version = "1.0.3.2",
	url = "http://war3source.com"
};

public OnPluginStart()
{
	HookEvent("player_jump",PlayerJumpEvent);
	LoadTranslations("w3s.race.spiderman.phrases");
}

public OnMapStart()
{
	
	////War3_PrecacheSound(UltimateSound);
	
	// ==================================================
	SenseSprite = PrecacheModel( "materials/sprites/yellowflare.vmt" );
	WebSprite1 = PrecacheModel( "materials/effects/combineshield/comshieldwall.vmt" );
	WebSprite2 = PrecacheModel( "materials/effects/combineshield/comshieldwall2.vmt" );
	// ==================================================
	PrecacheModel(NinjaMdl, true);
	BeamSprite = War3_PrecacheBeamSprite();
	HaloSprite = War3_PrecacheHaloSprite();
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==180)
	{
		thisRaceID=War3_CreateNewRaceT("spiderman");
		SKILL_EVADE=War3_AddRaceSkillT(thisRaceID,"SpiderSense",false,5);
		SKILL_SPEED=War3_AddRaceSkillT(thisRaceID,"Agility",false,5);
		SKILL_STUN=War3_AddRaceSkillT(thisRaceID,"WebShooters",false,5);
		ULT_WEB=War3_AddRaceSkillT(thisRaceID,"Weblines",true,5);
		W3SkillCooldownOnSpawn(thisRaceID,ULT_WEB,6.0,_);
		
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_victim=War3_GetRace(victim);
			//evade
			new skill_level_evasion=War3_GetSkillLevel(victim,thisRaceID,SKILL_EVADE);//if they are not this race thats fine, later check for race
			if(race_victim==thisRaceID && skill_level_evasion>0 &&!Silenced(victim,false)) 
			{
				
				if(GetRandomFloat(0.0,1.0)<=SSenseChance[skill_level_evasion] && !W3HasImmunity(attacker,Immunity_Skills))
				{
					
					War3_DamageModPercent(0.0);
					
					// ==================================================
					new Float:startpos[3];
					new Float:endpos[3];
					
					GetClientAbsOrigin( attacker, startpos );
					GetClientAbsOrigin( victim, endpos );
					
					TE_SetupBeamPoints( startpos, endpos, SenseSprite, SenseSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 255, 255, 255, 255 }, 0 );
					TE_SendToAll();
					// ==================================================
					
					W3FlashScreen(victim,RGBA_COLOR_BLUE);
										
					W3MsgEvaded(victim,attacker);
					
					if(War3_GetGame()==Game_TF)
					{
						decl Float:pos[3];
						GetClientEyePosition(victim, pos);
						pos[2] += 4.0;
						War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
					}
				}
			}
		}
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{
		ActivateSkills(client);
		new ClientTeam = GetClientTeam(client);
		SetEntityModel(client, NinjaMdl);
		if(ClientTeam==3)
		{
			W3SetPlayerColor(client,thisRaceID,20,100,200,255,1);
		}
		else if(ClientTeam==2)
		{
			W3SetPlayerColor(client,thisRaceID,220,50,0,255,1);
		}
		else
		{
			W3ResetPlayerColor(client,thisRaceID);
		}
	}
}

public OnWar3EventSpawn(client)
{
	new ClientRace = War3_GetRace(client);
	if(ClientRace==thisRaceID)
	{
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,-30);
		ActivateSkills(client);
		SetEntityModel(client, NinjaMdl);
		new ClientTeam = GetClientTeam(client);
		if(ClientTeam==3)
		{
			W3SetPlayerColor(client,thisRaceID,20,100,200,255,1);
		}
		else if(ClientTeam==2)
		{
			W3SetPlayerColor(client,thisRaceID,220,50,0,255,1);
		}
		else
		{
			W3ResetPlayerColor(client,thisRaceID);
		}
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		ActivateSkills(client);
	}
}

public ActivateSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skill_speed=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,NewSpeed[skill_speed]);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}


public OnWar3EventPostHurt(victim,attacker,damage){
	LastDamageTime[victim]=GetGameTime();
	if(W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ))
	{
		
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race=War3_GetRace(attacker);
			if(race==thisRaceID)
			{
				new skill_level_web=War3_GetSkillLevel(attacker,race,SKILL_STUN);
				if(skill_level_web && !Hexed(attacker) && !W3HasImmunity(victim,Immunity_Skills))
				{
					// Bash
					new Float:chance_mod=W3ChanceModifier(attacker);
					new Float:percent=WebChance[skill_level_web];
					new Float:time=WebTime[skill_level_web];
					if(GetRandomFloat(0.0,1.0)<=percent*chance_mod && !bIsCatched[victim] && IsPlayerAlive(attacker))
					{
						bIsCatched[victim]=true;
						War3_SetBuff(victim,bBashed,thisRaceID,true);
						
						W3FlashScreen(victim,RGBA_COLOR_RED);
						CreateTimer(time,UnfreezePlayer,victim);
						
						//  ====== ÂÇßÒÎ ÈÇ ÄÐÓÃÎÃÎ ÏÀÓÊÀ ======
						new Float:startpos[3];
						new Float:endpos[3];
				
						GetClientAbsOrigin( attacker, startpos );
						GetClientAbsOrigin( victim, endpos );
				
						TE_SetupBeamPoints( startpos, endpos, WebSprite1, WebSprite1, 0, 0, 2.0, time, 1.0, 0, 0.0, { 255, 0, 0, 255 }, 0 );
						TE_SendToAll();
				
						TE_SetupBeamRingPoint( endpos, 40.0, 50.0, WebSprite2, WebSprite2, 0, 0, time, 40.0, 0.0, { 10, 10, 10, 255 }, 0, FBEAM_ISACTIVE );
						TE_SendToAll();
						// ======================================
						
						/*
						new Float:effect_vec[3];
						GetClientAbsOrigin(victim,effect_vec);
						effect_vec[2]+=15.0;
						TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,time,5.0,0.0,{255,255,255,255},10,0);
						TE_SendToAll();
						effect_vec[2]+=15.0;
						TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,time,5.0,0.0,{255,255,255,255},10,0);
						TE_SendToAll();
						effect_vec[2]+=15.0;
						TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,time,5.0,0.0,{255,255,255,255},10,0);
						TE_SendToAll();
						*/						
						PrintHintText(victim,"%T","You are caught in the web",victim);
						PrintHintText(attacker,"%T","You caught the enemy in the web",attacker);
					}
				}
			}
		}
	}
}

public Action:UnfreezePlayer(Handle:timer,any:client)
{
	War3_SetBuff(client,bBashed,thisRaceID,false);
	bIsCatched[client]=false;
}

public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if(War3_GetRace(client)==thisRaceID){
		new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
		if(skilllevel>0){
			
			new v_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
			new v_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
			new v_b = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
			new Float:finalvec[3];
			finalvec[0] = GetEntDataFloat(client, v_0) * LongJump[skilllevel] * 0.25;
			finalvec[1] = GetEntDataFloat(client, v_1) * LongJump[skilllevel] * 0.25;
			finalvec[2] = LongJump[skilllevel] * 25.0;
			SetEntDataVector(client,v_b,finalvec,true);
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) ){
		new skilllevel=War3_GetSkillLevel(client,thisRaceID,ULT_WEB);
		if(skilllevel>0){
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_WEB,true))
			{
				decl Float:pushVector[3], Float:angle[3];
				GetClientEyeAngles(client, angle);
				if(angle[0]>60){
					angle[0] -= 25.0;
				}else if(angle[0]>30){
					angle[0] -= 20.0;
				}else if(angle[0]>0){
					angle[0] -= 15.0;
				}else if(angle[0]>-30.0){
					angle[0] -= 10.0;
				}else if(angle[0]>-60.0){
					angle[0] -= 5.0;
				}
				GetAngleVectors(angle, pushVector, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(pushVector, pushVector);
				pushVector[0] *= Force[skilllevel];
				pushVector[1] *= Force[skilllevel];
				pushVector[2] *= Force[skilllevel];
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, pushVector);
				War3_CooldownMGR(client,Cooldown[skilllevel],thisRaceID,ULT_WEB,_,_);
				//EmitSoundToAll(UltimateSound,client);
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (damagetype & DMG_FALL)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
