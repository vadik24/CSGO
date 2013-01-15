/**
* File						: War3Source_Detective.sp
* Description				: The Detective race for War3Source.
* Author(s)					: Schmarotzer
* Original Es Idea			: Serenkiy Vol4onok
*/

#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
new thisRaceID;

// skill 1
new Float:SenseChance[6]={0.0,0.04,0.08,0.12,0.16,0.20}; 
// new Float:SenseChance[6]={0.0, 0.04, 0.08, 0,12, 0.16, 0.20};

// skill 2
new Float:TrickChance[6]={0.0,0.04,0.08,0.12,0.16,0.20}; 
new SmokeSprite;

// skill 3
new Float:BloodPercent[6]={0.0,0.05,0.1,0.15,0.2,0.25};

// skill 4
new Float:CatchChance[6]={0.0,0.04,0.08,0.12,0.16,0.20}; 
new bool:bCaught[MAXPLAYERS];

// ultimate
new Float:TrackingDamagePercent[6]={0.0,0.05,0.1,0.15,0.2,0.25};
new Float:TrackingTime[6]={0.0,7.0,6.0,5.0,4.0,3.0};
new Float:CooldownTime[6]={0.0,31.0,27.0,23.0,19.0,15.0};
new Float:DetectivesTargetPos[3];
new DetectivesTarget;

new SKILL_SENSE,SKILL_TRICK,SKILL_BLOOD,SKILL_CATCH,ULT_CHASE;

public Plugin:myinfo = 
{
	name = "War3Source Race - Detective",
	author = "Schmarotzer",
	description = "The Detective race for War3Source.",
	version = "1.0.0.0",
	url = "http://css.bashtel.ru"
};

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==400)
	{
		thisRaceID	= War3_CreateNewRaceT("detective");
		SKILL_SENSE	= War3_AddRaceSkillT(thisRaceID,"DetectiveSense",false,4);
		SKILL_TRICK	= War3_AddRaceSkillT(thisRaceID,"DirtyTrick",false,4);
		SKILL_BLOOD	= War3_AddRaceSkillT(thisRaceID,"ColdBlooded",false,4);
		SKILL_CATCH	= War3_AddRaceSkillT(thisRaceID,"Catch",false,4);
		ULT_CHASE	= War3_AddRaceSkillT(thisRaceID,"Tracking",true,4);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnPluginStart()
{
	
	LoadTranslations("w3s.race.detective.phrases");
}

public OnMapStart()
{
	SmokeSprite = PrecacheModel( "sprites/smoke.vmt" );
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{
		if( IsPlayerAlive(client) )
		{
			// InitPassiveSkills(client);
		}
	}
}

public OnWar3EventSpawn(client)
{
	bCaught[client] = false;
	new race = War3_GetRace(client);
	War3_SetBuff(client,bBuffDenyAll,thisRaceID,false);
	if(race == thisRaceID)
	{
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		// InitPassiveSkills(client);
	}
}

public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim,true) && ValidPlayer(attacker,true))
	{
		new ATeam = GetClientTeam(attacker);
		new VTeam = GetClientTeam(victim);
		new VRace = War3_GetRace(victim);
		new ARace = War3_GetRace(attacker);
		if(ATeam!=VTeam) 
		{
			if(ARace==thisRaceID)
			{
				new skill_level_sense=War3_GetSkillLevel(attacker,thisRaceID,SKILL_SENSE);
				if(skill_level_sense>0)
				{
					if(War3_Chance(SenseChance[skill_level_sense]) && !IsSkillImmune(victim))
					{
						W3FlashScreen(victim,RGBA_COLOR_BLUE);
						// War3_SetBuff(victim, bInvisibilityDenyAll, thisRaceID, true);
						
						PrintHintText(attacker,"%T","You normalized enemy",attacker);
						War3_SetBuff(victim,bBuffDenyAll,thisRaceID,true);
						PrintHintText(victim,"%T","You was normalized by Detective",victim);
					}
				}
			}
			if(VRace==thisRaceID) 
			{
				new skill_level_trick=War3_GetSkillLevel(attacker,thisRaceID,SKILL_TRICK);
				if(skill_level_trick>0)
				{
					if(War3_Chance(TrickChance[skill_level_trick]) && !IsSkillImmune(attacker))
					{
						W3FlashScreen(victim,RGBA_COLOR_BLUE);
						// War3_SetBuff(victim, bInvisibilityDenyAll, thisRaceID, true);
						
						// PrintHintText(attacker,"Dispel Magic.");
						War3_SetBuff(victim,fInvisibilitySkill,thisRaceID,0.0);
						HideInSmoke(victim);
						PrintHintText(victim,"%T","You hid in the shadows",victim);
						CreateTimer(2.5,UnSmoke,victim);
					}
				}
			}
		}
	}
}

public Action:UnSmoke(Handle:timer,any:client)
{
	if(ValidPlayer(client,true)) 
	{
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
	}
}

Action:HideInSmoke(client)
{
	new Float:ClientPos[3];
	GetClientAbsOrigin(client,ClientPos);
	ClientPos[2] += 15;
	TE_SetupSmoke(ClientPos,SmokeSprite,100.0,10);
	TE_SendToAll();
	TE_SetupSmoke(ClientPos,SmokeSprite,100.0,10);
	TE_SendToAll();
	TE_SetupSmoke(ClientPos,SmokeSprite,100.0,10);
	TE_SendToAll();
	TE_SetupSmoke(ClientPos,SmokeSprite,100.0,10);
	TE_SendToAll();
}

public OnWar3EventPostHurt(victim,attacker,damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker,true) && attacker!=victim)
	{
		new VTeam=GetClientTeam(victim);
		new ATeam=GetClientTeam(attacker);
		if(VTeam!=ATeam)
		{
			new ARace=War3_GetRace(attacker);
			new VRace=War3_GetRace(victim);
			if(ARace==thisRaceID)
			{
				new skill_level_blood=War3_GetSkillLevel(attacker,thisRaceID,SKILL_BLOOD);
				if(skill_level_blood>0 && !IsSkillImmune(victim) && !Hexed(attacker))
				{	
					new Float:percent_health=BloodPercent[skill_level_blood];
					new leechhealth=RoundToFloor(damage*percent_health);
					if(leechhealth>40) leechhealth=40;
				
					PrintToConsole(attacker,"%T","Leeched +{amount} HP",attacker,leechhealth);

					W3FlashScreen(attacker,RGBA_COLOR_GREEN);	
					War3_HealToBuffHP(attacker,leechhealth);
				}
			}
			if(VRace==thisRaceID)
			{
				new skill_level_catch=War3_GetSkillLevel(victim,thisRaceID,SKILL_CATCH);
				if(skill_level_catch>0 && !IsSkillImmune(attacker) && !Hexed(victim))
				{
					if(War3_Chance(CatchChance[skill_level_catch]) && !bCaught[attacker])
					{
						new AttackerID = GetClientUserId(attacker);
						ServerCommand("sm_beacon #%d",AttackerID);
						PrintHintText(attacker,"%T","Detective caught you!",attacker);
						PrintHintText(victim,"%T","You caught enemy!",victim);
						bCaught[attacker] = true;
					}
				}
			}
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{

	if(race==thisRaceID && pressed && ValidPlayer(client,true) )
	{
		new ult_level_chase=War3_GetSkillLevel(client,race,ULT_CHASE);
		if(ult_level_chase>0)
		{
			
			if(SkillAvailable(client,thisRaceID,ULT_CHASE,_,_,_))
			{
				new Float:posVec[3];
				GetClientAbsOrigin(client,posVec);
				new Float:otherVec[3];
				new Float:bestTargetDistance=3000.0; 
				new ClientTeam = GetClientTeam(client);
				new bestTarget=0;
				
				// new Float:ultmaxdistance=GetConVarFloat(ultRangeCvar);
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true))
					{	
						new ITeam = GetClientTeam(i);
						if(ITeam!=ClientTeam && !IsUltImmune(i))
						{

							GetClientAbsOrigin(i,otherVec);
							new Float:dist=GetVectorDistance(posVec,otherVec);
							// if(dist<bestTargetDistance&&dist<ultmaxdistance)
							if(dist<bestTargetDistance)
							{
								bestTarget=i;
								bestTargetDistance=GetVectorDistance(posVec,otherVec);
								
							}
							
						}

					}
				}
				if(bestTarget==0)
				{
					W3MsgNoTargetFound(client,bestTargetDistance);
				}
				else
				{
					new BestTargetMaxHP = War3_GetMaxHP(bestTarget);
					new damage=RoundFloat(float(BestTargetMaxHP)*TrackingDamagePercent[ult_level_chase]);
					if(damage>0)
					{
						GetClientAbsOrigin(bestTarget,DetectivesTargetPos);
						if(War3_DealDamage(bestTarget,damage,client,DMG_BULLET,"tracking"))
						{
							DetectivesTarget = bestTarget;
							// W3PrintSkillDmgHintConsole(bestTarget,client,War3_GetWar3DamageDealt(),"Locust");
							W3FlashScreen(bestTarget,RGBA_COLOR_RED);
							
							// Написать о том что Детектив идет по следу
							PrintHintText(client,"%T","You begin tracking your enemy down",client);
							new Float:UltTime = TrackingTime[ult_level_chase];
							CreateTimer(UltTime,Tracking,client);
							// //EmitSoundToAll(ultimateSound,client);
							new Float:CDTime = UltTime + CooldownTime[ult_level_chase];
							War3_CooldownMGR(client,CDTime,thisRaceID,ULT_CHASE,true,_);
						}
					}
				}
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public Action:Tracking(Handle:t,any:client)
{
	if(ValidPlayer(client,true))
	{
		if(ValidPlayer(DetectivesTarget,true))
		{
			TeleportEntity(client,DetectivesTargetPos,NULL_VECTOR,NULL_VECTOR);
			PrintHintText(client,"%T","You on track! Hurry, enemy was here a moment ago!",client);
			PrintHintText(DetectivesTarget,"%T","Beware! Someone maybe on your track!",DetectivesTarget);
		}
		else
		{
			PrintHintText(client,"%T","You lost track!",client);
		}
	}
}