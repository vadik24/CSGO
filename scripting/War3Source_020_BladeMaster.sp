/**
 * File: War3Source_BladeMaster.sp
 * Description: The Blademaster race for War3Source.
 * Author(s): [Oddity]TeacherCreature
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

new thisRaceID;

new SKILL_WINDWALK,SKILL_MIRRORIMAGE, SKILL_CRITICAL,ULT_BLADESTORM;

//skill 1
new Float:WindWalkTime[9]={0.0,2.0,2.4,2.8,3.2,3.6,4.0,4.4,4.8};
new Float:AbilityCooldownTime=15.0;
new bool:bWinded[66];
new String:ww_on[]="npc/scanner/scanner_nearmiss1.mp3";
new String:ww_off[]="npc/scanner/scanner_nearmiss2.mp3";

//skill 2
//new String:mImage[256];
new Float:MirrorImageChance[9]={0.0,0.3,0.35,0.40,0.45,0.50,0.55,0.60,0.65};
new GlowSprite, GlowSprite2;

//skill 3
new Float:CriticalPercent[9]={0.0,0.6,0.8,1.0,1.2,1.4,1.6,1.8,2.0};

//ultimate
new Handle:ultCooldownCvar;
new OverloadDuration=15; //HIT TIMES, DURATION DEPENDS ON TIMER
new OverloadRadius=100;
new OverloadDamagePerHit[9]={0,13,14,15,16,17,18,19,20};
new Float:OverloadDamageIncrease[9]={1.0,1.015,1.018,1.021,1.024,1.027,1.030,1.033,1.035};
////
new UltimateZapsRemaining[66];
new Float:PlayerDamageIncrease[66];
new WindSprite; 
new String:ultsnd[]="music/war3source/bmaster/swiftbladespin.mp3";

public Plugin:myinfo = 
{
	name = "War3Source Race - Blademaster",
	author = "[Oddity]TeacherCreature",
	description = "The Blademaster race for War3Source.",
	version = "1.0.0.0",
	url = "warcraft-source.net"
}

public OnPluginStart()
{
	//HookEvent("round_start",RoundStartEvent);
	ultCooldownCvar=CreateConVar("war3_bmaster_ult_cooldown","30","Cooldown time for BMaster ult Bladestorm.");
	
	LoadTranslations("w3s.race.bmaster.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==19)
	{
		thisRaceID=War3_CreateNewRaceT("bmaster");
		SKILL_WINDWALK=War3_AddRaceSkillT(thisRaceID,"WindWalk",false,8);
		SKILL_MIRRORIMAGE=War3_AddRaceSkillT(thisRaceID,"MirrorImage",false,8);
		SKILL_CRITICAL=War3_AddRaceSkillT(thisRaceID,"CriticalStrike",false,8);
		ULT_BLADESTORM=War3_AddRaceSkillT(thisRaceID,"Bladestorm",true,8); 
		War3_CreateRaceEnd(thisRaceID);	
	}

}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		bWinded[client]=false;
		W3ResetAllBuffRace(client,thisRaceID);
	}
	if(newrace==thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	}
}

public OnMapStart()
{
	WindSprite=PrecacheModel("sprites/crosshairs.vmt");
	//GlowSprite=PrecacheModel("models/player/t_leet.mdl");
	//GlowSprite2=PrecacheModel("models/player/ct_urban.mdl");
	////War3_PrecacheSound(ultsnd);
	////War3_PrecacheSound(ww_on);
	////War3_PrecacheSound(ww_off);
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{ 
		UltimateZapsRemaining[client]=0;
		bWinded[client]=false;
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		/*new mteam=GetClientTeam(client);
		if(mteam==2)
		{
			SetEntityModel(client, "models/player/t_leet.mdl");
		}
		else
		{
			
			SetEntityModel(client, "models/player/ct_urban.mdl");
		}
		*/
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_WINDWALK);
		if(skill_level>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_WINDWALK,true))
			{
				if(!Silenced(client))
				{
					War3_SetBuff(client,fMaxSpeed,thisRaceID,1.3);
					new Float:this_pos[3];
					GetClientAbsOrigin(client,this_pos);
					TE_SetupBeamRingPoint(this_pos, 40.0, 90.0, WindSprite, WindSprite, 0, 5, 0.5, 50.0, 0.0, {155,115,100,200}, 1, 0) ;
					TE_SendToAll();
					War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
					CreateTimer(WindWalkTime[skill_level],RemoveInvis,client);
					War3_CooldownMGR(client,AbilityCooldownTime,thisRaceID,SKILL_WINDWALK,_,_);
					PrintHintText(client,"%T","Wind Walk: Invisibilty",client);
					bWinded[client]=true;
					//EmitSoundToAll(ww_on,client);
					War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
				}
				else
				{
					PrintHintText(client,"%T","Silenced: Can not cast!",client);
				}
			}
		}
	}
}

public Action:RemoveInvis(Handle:t,any:client)
{
	if(ValidPlayer(client,true) && bWinded[client]==true)
	{
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		War3_SetBuff(client,bImmunitySkills,thisRaceID,false);
		bWinded[client]=false;
		PrintHintText(client,"%T","Wind Walk: Ended",client);
		//EmitSoundToAll(ww_off,client);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	}
}

public CooldownUltimate(client)
{
	War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_BLADESTORM,_,_);
}

public Action:RemoveSpeed(Handle:t,any:client)
{
	if(ValidPlayer(client))
	{
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	}
}

public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new race_victim=War3_GetRace(victim);
			// mirror image
			new skill_mimage=War3_GetSkillLevel(victim,race_victim,SKILL_MIRRORIMAGE);
			if(race_victim==thisRaceID)
			{
				if(GetRandomFloat(0.0,1.0)<=MirrorImageChance[skill_mimage] && !Silenced(victim))
				{
					if(bWinded[victim]==false)
					{
						new tteam=GetClientTeam(victim);
						new Float:this_pos[3];
						{
							GetClientAbsOrigin(victim,this_pos);
							if(tteam==2)
							{
								//TE_SetupGlowSprite(this_pos,GlowSprite,2.0,1.0,250);
								//TE_SendToAll();
							}
							else
							{
								//TE_SetupGlowSprite(this_pos,GlowSprite2,2.0,1.0,250);
								//TE_SendToAll();
							}
						}
						War3_SetBuff(victim,fMaxSpeed,thisRaceID,1.6);
						PrintHintText(victim,"%T","Mirror Image",victim);
						bWinded[victim]=true;
						CreateTimer(2.0,RemoveSpeed,victim);
					}
					else
					{
						War3_DamageModPercent(0.0);
					}
				}
			}
			if(race_attacker==thisRaceID)
			{
				//windwalk turn off
				if(bWinded[attacker]==true&&!Silenced(attacker))
				{
					War3_DamageModPercent(1.5);
					War3_SetBuff(attacker,fInvisibilitySkill,thisRaceID,1.0);
					War3_SetBuff(attacker,fMaxSpeed,thisRaceID,1.0);
					bWinded[attacker]=false;
					PrintHintText(attacker,"%T","Wind Walk: 50% extra damage",attacker);
					//EmitSoundToAll(ww_off,attacker);
				}
				
			}
		}
	}
}

public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new race_victim=War3_GetRace(victim);
			// mirror image
			new skill_mimage=War3_GetSkillLevel(victim,race_victim,SKILL_MIRRORIMAGE);
			if(race_victim==thisRaceID)
			{
				if(GetRandomFloat(0.0,1.0)<=MirrorImageChance[skill_mimage] && !Silenced(victim))
				{
					if(bWinded[victim]==false)
					{
						new tteam=GetClientTeam(victim);
						new Float:this_pos[3];
						{
							GetClientAbsOrigin(victim,this_pos);
							if(tteam==2)
							{
								//TE_SetupGlowSprite(this_pos,GlowSprite,2.0,1.0,250);
								//TE_SendToAll();
							}
							else
							{
								//TE_SetupGlowSprite(this_pos,GlowSprite2,2.0,1.0,250);
								//TE_SendToAll();
							}
						}
						War3_SetBuff(victim,fMaxSpeed,thisRaceID,1.6);
						PrintHintText(victim,"%T","Mirror Image",victim);
						bWinded[victim]=true;
						CreateTimer(2.0,RemoveSpeed,victim);
					}
				}
			}
			if(race_attacker==thisRaceID)
			{
				//critical
				new skill_cs_attacker=War3_GetSkillLevel(attacker,race_attacker,SKILL_CRITICAL);
				if(skill_cs_attacker>0)
				{
					new Float:chance=0.15;
					if(GetRandomFloat(0.0,1.0)<=chance && !W3HasImmunity(victim,Immunity_Skills))
					{
						new Float:percent=CriticalPercent[skill_cs_attacker];
						new health_take=RoundFloat(damage*percent);
						if(War3_DealDamage(victim,health_take,attacker,_,"bmastercrit",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL,true))
						{	
							PrintHintText(attacker,"%T","Critical! +{amount} Dmg",attacker,health_take);
							PrintHintText(victim,"%T","Received Critical -{amount} Dmg",victim,health_take);
							
							/*War3_DamageModPercent(percent);
							PrintToConsole(attacker,"%.1fX Critical ! ",percent+1.0);
							PrintHintText(attacker,"Critical !",percent+1.0);
							PrintToConsole(victim,"Received %.1fX Critical Dmg!",percent+1.0);
							PrintHintText(victim,"Received Critical Dmg!");*/
							
							W3FlashScreen(victim,RGBA_COLOR_RED);
						}
					}
				}
			}
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		//if(
		
		new skill=War3_GetSkillLevel(client,race,ULT_BLADESTORM);
		if(skill>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_BLADESTORM,true))
			{
				if(!Silenced(client))
				{
					if(bWinded[client]==true)
					{
						CreateTimer(0.1,RemoveInvis,client);
					}
					UltimateZapsRemaining[client]=OverloadDuration;
					if(War3_GetGame()==Game_CS){
						UltimateZapsRemaining[client]=OverloadDuration*2;
					}
					//EmitSoundToAll(ultsnd,client);
					PlayerDamageIncrease[client]=1.0;
					War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_BLADESTORM,_,_);
					PrintHintText(client,"%T","Bladestorm",client);
					CreateTimer(War3_GetGame()==Game_CS?0.25:0.5,UltimateLoop,GetClientUserId(client)); //damage
				}
				else
				{
					PrintHintText(client,"%T","Silenced: you can not case!",client);
				}
			}
		}
		else
		{
			PrintHintText(client,"%T","Level Your Ultimate First",client);
		}
	}
}
public Action:UltimateLoop(Handle:timer,any:userid)
{
	new attacker=GetClientOfUserId(userid);
	if(ValidPlayer(attacker) && UltimateZapsRemaining[attacker]>0&&IsPlayerAlive(attacker))
	{
		UltimateZapsRemaining[attacker]--;
		new Float:pos[3];
		new Float:otherpos[3];
		GetClientEyePosition(attacker,pos);
		new team = GetClientTeam(attacker);
		new lowesthp=99999;
		new besttarget=0;
		new Float:this_posu[3];
		this_posu[2]+=30.0;
		GetClientAbsOrigin(attacker,this_posu);
		TE_SetupBeamRingPoint(this_posu, 40.0, 90.0, WindSprite, WindSprite, 0, 5, 0.5, 50.0, 0.0, {155,115,100,200}, 1, 0) ;
		TE_SendToAll();
		for(new i=1;i<=MaxClients;i++){
			if(ValidPlayer(i,true)){
				
				if(GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Ultimates)){
					GetClientEyePosition(i,otherpos);
					if(War3_GetGame()==Game_CS){
						otherpos[2]-=20;
					}
					//PrintToChatAll("%d distance %f",i,GetVectorDistance(pos,otherpos));
					if(GetVectorDistance(pos,otherpos)<OverloadRadius){
						
						//TE_SetupBeamPoints(pos,otherpos,BeamSprite,HaloSprite,0,35,0.15,6.0,5.0,0,1.0,{255,255,255,100},20);
						//TE_SendToAll();
						
						new Float:distanceVec[3];
						SubtractVectors(otherpos,pos,distanceVec);
						new Float:angles[3];
						GetVectorAngles(distanceVec,angles);
						
						TR_TraceRayFilter(pos, angles, MASK_PLAYERSOLID, RayType_Infinite, CanHitThis,attacker);
						new ent;
						if(TR_DidHit(_))
						{
							ent=TR_GetEntityIndex(_);
							//PrintToChatAll("trace hit: %d      wanted to hit player: %d",ent,i);
						}
						
						if(ent==i&&GetClientHealth(i)<lowesthp){
							besttarget=i;
							lowesthp=GetClientHealth(i);
						}
					}
				}
			}
		}
		if(besttarget>0){
			pos[2]-=20.0;
			
			GetClientEyePosition(besttarget,otherpos);
			otherpos[2]-=20.0;
			//TE_SetupBeamPoints(pos,otherpos,BeamSprite,HaloSprite,0,35,0.15,6.0,5.0,0,1.0,{255,000,255,255},20);
			//TE_SendToAll();
			War3_DealDamage(besttarget,OverloadDamagePerHit[War3_GetSkillLevel(attacker,thisRaceID,ULT_BLADESTORM)],attacker,_,"bladestorm");
			PlayerDamageIncrease[attacker]*=OverloadDamageIncrease[War3_GetSkillLevel(attacker,thisRaceID,ULT_BLADESTORM)];
			PrintHintText(besttarget,"%T","Hit by Bladestorm",besttarget);
		}
		CreateTimer(War3_GetGame()==Game_CS?0.25:0.5,UltimateLoop,GetClientUserId(attacker)); //damage
	}
	else
	{
		UltimateZapsRemaining[attacker]=0;
	}
}

public bool:CanHitThis(entity, mask, any:data)
{
	if(entity == data)
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit
	}
	return true; // It didn't hit itself
}
