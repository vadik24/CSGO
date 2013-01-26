/**
* File: War3Source_SpiritWalker.sp
* Description: Spirit Walker race of warcraft.
* Author: Lucky 
*/
 
#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>
#include <cstrike>

new thisRaceID;
new BeamSprite,HaloSprite;

new String:steal_sound[]="war3source/spellbreaker/spellsteal.mp3";
new String:fdback_sound[]="war3source/spellbreaker/feedback.mp3";

//Spell Steal
new Float:StealCD[]={0.0,30.0,28.0,26.0,24.0,22.0,20.0};

//Spell Immunity

//Feedback
new Float:FeedbackCD[]={0.0,8.0,7.0,6.0,5.0,4.0,3.0};

//Control Magic
new Float:ControlRange[]={0.0,250.0,300.0,350.0,400.0,450.0,500.0};
new ControlTime[MAXPLAYERS]; //Time till channeling is complete
new bool:bControlling[MAXPLAYERS][MAXPLAYERS]; //Client and Victim
new bool:bChanged[MAXPLAYERS]; //Person is now under control
new bool:bChannel[MAXPLAYERS]; //You are channeling

//Skills & Ultimate
new SKILL_STEAL, SKILL_IMMUNITY, SKILL_FEEDBACK, ULT_CONTROL;

public Plugin:myinfo = 
{
	name = "War3Source Race - Spirit Walker",
	author = "Lucky",
	description = "Spirit Walker race of warcraft",
	version = "1.0.8.9",
	url = ""
}

public OnPluginStart()
{
	CreateTimer(1.0,ControlLoop,_,TIMER_REPEAT);
	HookEvent("round_end",RoundOverEvent);
}

public OnMapStart()
{
	//War3_PrecacheSound(steal_sound);
	//War3_PrecacheSound(fdback_sound);
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==010){
		thisRaceID=War3_CreateNewRace("SpellBreaker", "spellbreaker");
		SKILL_STEAL=War3_AddRaceSkill(thisRaceID,"Spell Steal (Kill)", "Take buffs from the enemy and use them yourself",false,6);
		SKILL_IMMUNITY=War3_AddRaceSkill(thisRaceID,"Spell Immunity (passive)","Spell immunity",false,1);
		SKILL_FEEDBACK=War3_AddRaceSkill(thisRaceID,"Feedback (Auto-Cast)","Add extra damage",false,6);
		ULT_CONTROL=War3_AddRaceSkill(thisRaceID,"Control Magic (Ultimate)","Control your enemy with magic REQUIRES CHANNELING",true,6);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	
	if(newrace == thisRaceID){
		new skill_immunity=War3_GetSkillLevel(client,thisRaceID,SKILL_IMMUNITY);
		
		if(skill_immunity==1){
			War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
		}
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_tmp");
		if(ValidPlayer(client,true)){
			GivePlayerItem(client, "weapon_tmp");
		}
	}
}

public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i)&&bChanged[i])
		{
			new target_team=GetClientTeam(i);
			if(target_team==2){
				bChanged[i]=false;
				CS_SwitchTeam(i, 3);
			}
			if(target_team==3){
				bChanged[i]=false;
				CS_SwitchTeam(i, 2);
			}
		}
	}
}

public OnWar3EventSpawn(client)
{	
	bChanged[client]=false;
	
	if(War3_GetRace(client)==thisRaceID){
		new skill_immunity=War3_GetSkillLevel(client,thisRaceID,SKILL_IMMUNITY);

		if(skill_immunity==1){
			War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
		}
		GivePlayerItem(client, "weapon_tmp");
		bChannel[client]=false;
		ControlTime[client]=0;
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.15);
		War3_SetBuff(client,fLowGravitySkill,thisRaceID,1.0);
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
	}
	
}

public OnWar3EventDeath(victim,attacker)
{
	new race_victim=War3_GetRace(victim);
	new race_attacker=War3_GetRace(attacker);
	
	if(race_victim==thisRaceID){
		for(new controlled=1;controlled<=MaxClients;controlled++)
		{
			if(ValidPlayer(controlled)&&bChanged[controlled])
			{
				PrintHintText(controlled, "You are free again!");
				W3FlashScreen(controlled,{120,0,255,50});
				new target_team=GetClientTeam(controlled);
				if(target_team==2){
					bChanged[controlled]=false;
					CS_SwitchTeam(controlled, 3);
				}
				if(target_team==3){
					bChanged[controlled]=false;
					CS_SwitchTeam(controlled, 2);
				}
			}
			
		}
	}
	
	for(new client=1;client<=MaxClients;client++){
		if(bControlling[client][victim]){
			War3_SetBuff(client,bStunned,thisRaceID,false);
			War3_SetBuff(victim,bStunned,thisRaceID,false);
			bChannel[client]=false;
			bControlling[client][victim]=false;	
			War3_CooldownMGR(client,30.0,thisRaceID,ULT_CONTROL,_,_);
		}
	}
	
	if(race_attacker==thisRaceID){
		if(!Silenced(attacker)){
			new skill_steal=War3_GetSkillLevel(attacker,thisRaceID,SKILL_STEAL);
		
			if(War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_STEAL,true)){
				if(War3_GetRace(victim)!=War3_GetRaceIDByShortname("wisp")){
					if(skill_steal>0){
						CheckBuffs(attacker, victim);
						War3_CooldownMGR(attacker,StealCD[skill_steal],thisRaceID,SKILL_STEAL,_,_);
						EmitSoundToAll(steal_sound, attacker);
						EmitSoundToAll(steal_sound, victim);
					}
				}
			
			}
		}
		
	}
}

public CheckBuffs(any: attacker, any:victim)
{
	new Float:victim_gravity=W3GetBuffMinFloat(victim,fLowGravitySkill);
	new Float:victim_speed=W3GetBuffMaxFloat(victim,fMaxSpeed);
	new Float:victim_attack=W3GetBuffStackedFloat(victim,fAttackSpeed);
	new Float:victim_invisibility = W3GetBuffMinFloat(victim,fInvisibilitySkill);
	new Float:attacker_gravity=W3GetBuffMinFloat(attacker,fLowGravitySkill);
	new Float:attacker_speed=W3GetBuffMaxFloat(attacker,fMaxSpeed);
	new Float:attacker_attack=W3GetBuffStackedFloat(attacker,fAttackSpeed);
	new Float:attacker_invisibility = W3GetBuffMinFloat(attacker,fInvisibilitySkill);
	
	if(victim_gravity<attacker_gravity){
		War3_SetBuff(attacker,fLowGravitySkill,thisRaceID,victim_gravity);
	}
	if(victim_speed>attacker_speed){
		War3_SetBuff(attacker,fMaxSpeed,thisRaceID,victim_speed);
	}
	
	if(victim_attack>attacker_attack){
		War3_SetBuff(attacker,fAttackSpeed,thisRaceID,victim_attack);
	}
	
	if(victim_invisibility<attacker_invisibility){
		War3_SetBuff(attacker,fInvisibilitySkill,thisRaceID,victim_invisibility);
	}
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		
		if(vteam!=ateam){
			new race_attacker=War3_GetRace(attacker);
			
			if(race_attacker==thisRaceID){
				new skill_feedback=War3_GetSkillLevel(attacker,thisRaceID,SKILL_FEEDBACK);
				
				if(War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_FEEDBACK,true)&&!W3HasImmunity(victim,Immunity_Skills)){
					War3_CooldownMGR(attacker,FeedbackCD[skill_feedback],thisRaceID,SKILL_FEEDBACK,_,_);
					War3_DealDamage(victim,15,attacker,DMG_BULLET,"Feedback");
					EmitSoundToAll(fdback_sound, victim);
				}
			}
		}
	}
}

public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		
		if(vteam!=ateam){
			new race_victim=War3_GetRace(victim);
			
			if(race_victim==thisRaceID && bChannel[victim]){
				War3_SetBuff(victim,bStunned,thisRaceID,false);
				bChannel[victim]=false;
				War3_CooldownMGR(victim,30.0,thisRaceID,ULT_CONTROL,_,_);
				for(new target=1;target<=MaxClients;target++){
					if(ValidPlayer(target,true)&&bControlling[victim][target]){
						bControlling[victim][target]=false;
						War3_SetBuff(target,bStunned,thisRaceID,false);
					}
			
				}
				PrintHintText(victim, "You've been interupted");
			}
		}
		
	}
}
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true)){
		if(!Silenced(client)){
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_CONTROL,true)){
				new ult_control=War3_GetSkillLevel(client,thisRaceID,ULT_CONTROL);
				if(ult_control>0){
					new target = War3_GetTargetInViewCone(client,ControlRange[ult_control],false,8.0);
						
					if(target>0 && !bChanged[target] && !W3HasImmunity(target,Immunity_Ultimates)){
						new victimTeam=GetClientTeam(target);
						new playersAliveSameTeam;
						for(new i=1;i<=MaxClients;i++)
						{
							if(i!=target&&ValidPlayer(i,true)&&GetClientTeam(i)==victimTeam)
							{
								playersAliveSameTeam++;
							}
						}
						if(playersAliveSameTeam>0)
						{
							bChannel[client]=true;
							War3_SetBuff(client,bStunned,thisRaceID,true);
							War3_SetBuff(target,bStunned,thisRaceID,true);
							ControlTime[client]=0;
							new Float:pos[3];
							GetClientAbsOrigin(client,pos);
							pos[2]+=15;
							new Float:tarpos[3];
							GetClientAbsOrigin(target,tarpos);
							tarpos[2]+=15;
							TE_SetupBeamPoints(pos,tarpos,BeamSprite,HaloSprite,0,1,1.0,10.0,5.0,0,1.0,{120,84,120,255},50);
							TE_SendToAll();	
							TE_SetupBeamRingPoint(tarpos, 1.0, 250.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
							TE_SendToAll();
							tarpos[2]+=15;
							TE_SetupBeamRingPoint(tarpos, 250.0, 1.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
							TE_SendToAll();
							tarpos[2]+=15;
							TE_SetupBeamRingPoint(tarpos, 1.0, 125.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
							TE_SendToAll();
							tarpos[2]+=15;
							TE_SetupBeamRingPoint(tarpos, 125.0, 1.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
							TE_SendToAll();
							bControlling[client][target]=true;
							PrintHintText(client, "You start channeling");
							PrintHintText(target, "You are stunned");
						}
						else
						{
							PrintHintText(client, "Target is last person alive, cannot be controlled");
						}
					}
					else
					{
						PrintHintText(client, "no target nearby");
					}
					
				}
				else
				{
					PrintHintText(client, "Level your Control Magic first");
				}
			
			}
		}
		else
		{
			PrintHintText(client, "you are silenced");
		}
	}
}

public Action:ControlLoop(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++){
		if(ValidPlayer(client,true)){
			if(War3_GetRace(client)==thisRaceID){
				for(new target=1;target<=MaxClients;target++){
					if(ValidPlayer(target,true)&&bControlling[client][target]){
						if(ControlTime[client]<4){
							new Float:pos[3];
							GetClientAbsOrigin(client,pos);
							pos[2]+=15;
							new Float:tarpos[3];
							GetClientAbsOrigin(target,tarpos);
							tarpos[2]+=15;
							TE_SetupBeamPoints(pos,tarpos,BeamSprite,HaloSprite,0,1,1.0,10.0,5.0,0,1.0,{120,84,120,255},50);
							TE_SendToAll();	
							TE_SetupBeamRingPoint(tarpos, 1.0, 250.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
							TE_SendToAll();
							tarpos[2]+=15;
							TE_SetupBeamRingPoint(tarpos, 250.0, 1.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
							TE_SendToAll();
							tarpos[2]+=15;
							TE_SetupBeamRingPoint(tarpos, 1.0, 125.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
							TE_SendToAll();
							tarpos[2]+=15;
							TE_SetupBeamRingPoint(tarpos, 125.0, 1.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
							TE_SendToAll();
							ControlTime[client]++;
						}
						else
						{
							War3_CooldownMGR(client,60.0,thisRaceID,ULT_CONTROL,_,_);
							War3_SetBuff(client,bStunned,thisRaceID,false);
							War3_SetBuff(target,bStunned,thisRaceID,false);
							bControlling[client][target]=false;
							bChannel[client]=false;
							new target_team=GetClientTeam(target);
							PrintHintText(client, "Channeling complete");
							PrintHintText(target, "You've been switched");
							W3FlashScreen(target,{120,0,255,50});
							if(target_team==2){
								bChanged[target]=true;
								CS_SwitchTeam(target, 3);
							}
							if(target_team==3){
								bChanged[target]=true;
								CS_SwitchTeam(target, 2);
							}
						}
					}
				}
			}
		}
	}
}