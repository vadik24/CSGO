/**
* File						: War3Source_Athena.sp
* Description				: The Athena race for War3Source.
* Author(s)					: Schmarotzer
* Original ES Idea			: HOLLIDAY
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

new thisRaceID;

// skills
new SKILL_SPEAR, SKILL_NECK, SKILL_HELM, ULT_MEDUSA;

//skill 1
new Float:SpearPercent[6]={0.0, 0.1, 0.2, 0.3, 0.4, 0.55};
new Float:SpearChance[6]={0.0, 0.13, 0.20, 0.25, 0.30, 0.35};

//skill 2
new Float:NeckChance[6]={0.0, 0.55, 0.65, 0.75, 0.85, 0.95};

//skill 3 
new Float:HelmetChance[6]={0.0, 0.45, 0.55, 0.65, 0.75, 0.90};



//skill 4
new Float:MedusasDistance[6]={0.0, 450.0, 500.0, 525.0, 575.0, 600.0};
new Float:MedusasDuration[6]={0.0, 1.0, 1.25, 1.5, 1.75, 2.0};
new String:MedusaSound[]="war3source/entanglingrootsdecay1.mp3";
new bool:bIsPetrified[MAXPLAYERS];
new Handle:MedusaNoShootCvar;//cannot shoot?
new Handle:MedusaCooldownCvar; // cooldown

// Effects
new BeamSprite,HaloSprite;


public Plugin:myinfo = 
{
	name = "War3Source Race - Athena",
	author = "Schmarotzer",
	description = "The Athena race for War3Source.",
	version = "1.0.0.0",
	url = "http://css.bashtel.ru"
};

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==350)
	{
		thisRaceID			=	War3_CreateNewRaceT("athena");
		SKILL_SPEAR			=	War3_AddRaceSkillT(thisRaceID,"AthenasSpear",false,5);
		SKILL_NECK			=	War3_AddRaceSkillT(thisRaceID,"NecklaceOfImmunity",false,5);
		SKILL_HELM			=	War3_AddRaceSkillT(thisRaceID,"GoldenHelmet",false,5);
		ULT_MEDUSA			=	War3_AddRaceSkillT(thisRaceID,"GorgonsHead",true,5); 
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnPluginStart()
{
	MedusaCooldownCvar=CreateConVar("war3_athena_ult_cooldown","30.0","Cooldown timer");
	MedusaNoShootCvar=CreateConVar("war3_athena_ult_noshoot","0","Disable shooting when petrified?");
	LoadTranslations("w3s.race.athena.phrases");
}

public OnMapStart()
{
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();

	////War3_PrecacheSound(MedusaSound);
}




public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(bIsPetrified[client] && War3_GetGame()==Game_TF)
	{
		if(GetConVarInt(MedusaNoShootCvar)>0){
			if((buttons & IN_ATTACK) || (buttons & IN_ATTACK2))
				return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID){
		W3ResetAllBuffRace(client,thisRaceID);
	}
	if(newrace==thisRaceID){
		if(ValidPlayer(client,true))
		{
			InitPassiveSkills(client);
		}
	}
}

public InitPassiveSkills(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		new skill_level_necklace=War3_GetSkillLevel(client,race,SKILL_NECK);
		if(skill_level_necklace>0)
		{
			// new Float:chance=0.15*chance_mod;
			if( GetRandomFloat(0.0,1.0)<=NeckChance[skill_level_necklace])
			{
				War3_SetBuff(client,bImmunityUltimates,thisRaceID,true);
				War3_ChatMessage(client,"%T","You have put on Necklace of Immunity! (Skill activated)",client);
			}
			else
			{
				War3_ChatMessage(client,"%T","You forgot to put on Necklace of Immunity! (Skill failed)",client);
			}
		}
	}
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		InitPassiveSkills(client);
	}
	if(bIsPetrified[client])
	{
		bIsPetrified[client]=false;
		War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(race==thisRaceID&&skill==0&&newskilllevel>=0&&War3_GetRace(client)==thisRaceID)
	{
		if(newskilllevel>0 && IsPlayerAlive(client))
			War3_SetBuff(client,bImmunityUltimates,thisRaceID,true);
	}
}


// =================================================================================================
// ======================================= ATHENA'S SPEAR ==========================================
// =================================================================================================
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			//new Float:chance_mod=W3ChanceModifier(attacker);
			if(race_attacker==thisRaceID)
			{
				new skill_level_spear=War3_GetSkillLevel(attacker,race_attacker,SKILL_SPEAR);
				if(skill_level_spear>0&&!Hexed(attacker,false))
				{
					//new Float:chance=0.15*chance_mod;
					if( GetRandomFloat(0.0,1.0)<=SpearChance[skill_level_spear] && !W3HasImmunity(victim,Immunity_Skills))
					{
						new Float:percent=SpearPercent[skill_level_spear]; //0.0 = zero effect -1.0 = no damage 1.0=double damage
						new health_take=RoundFloat(damage*percent);
						if(health_take>80) health_take=80;
						if(War3_DealDamage(victim,health_take,attacker,_,"athenas_spear",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL,true))
						{	
							W3PrintSkillDmgHintConsole(victim,attacker,War3_GetWar3DamageDealt(),SKILL_SPEAR);
							W3FlashScreen(victim,RGBA_COLOR_RED);
						}
					}
				}
			}
		}
	}
}
// =================================================================================================
// =================================================================================================
// =================================================================================================


// =================================================================================================
// ======================================= GOLDEN HELMET ===========================================
// =================================================================================================

public OnClientPutInServer(client)
{
	SDKHook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack); 
}

public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(ValidPlayer(victim,true) && ValidPlayer(attacker,true) && attacker!=victim)
	{
		new skill_level_helmet=War3_GetSkillLevel(victim,thisRaceID,SKILL_HELM);
		new race=War3_GetRace(victim);
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(race==thisRaceID && skill_level_helmet>0  && vteam!=ateam)
		{
			if(hitgroup==1)
			{
				if(GetRandomFloat(0.0,1.0)<=HelmetChance[skill_level_helmet])
				{
					damage=0.0;
				}
			}
		}
	}
	return Plugin_Changed;
}

// =================================================================================================
// =================================================================================================
// =================================================================================================





// =================================================================================================
// ======================================= GORGON'S HEAD ===========================================
// =================================================================================================



public bool:ImmunityCheck(client)
{
	if(bIsPetrified[client]||W3HasImmunity(client,Immunity_Ultimates))
	{
		return false;
	}
	return true;
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && IsPlayerAlive(client) && pressed)
	{
		new ult_level_medusa=War3_GetSkillLevel(client,race,ULT_MEDUSA);
		if(ult_level_medusa>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_MEDUSA,true)){

				new Float:distance=MedusasDistance[ult_level_medusa];
				new target; // easy support for both

				new Float:our_pos[3];
				GetClientAbsOrigin(client,our_pos);

				target=War3_GetTargetInViewCone(client,distance,false,60.0,ImmunityCheck);
				if(ValidPlayer(target,true))
				{

					bIsPetrified[target]=true;

					War3_SetBuff(target,bNoMoveMode,thisRaceID,true);
					new Float:petrification_time=MedusasDuration[ult_level_medusa];
					CreateTimer(petrification_time,StopPetrification,target);
					new Float:effect_vec[3];
					GetClientAbsOrigin(target,effect_vec);
					effect_vec[2]+=15.0;
					TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,petrification_time,5.0,0.0,{0,255,0,255},10,0);
					TE_SendToAll();
					effect_vec[2]+=15.0;
					TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,petrification_time,5.0,0.0,{0,255,0,255},10,0);
					TE_SendToAll();
					effect_vec[2]+=15.0;
					TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,petrification_time,5.0,0.0,{0,255,0,255},10,0);
					TE_SendToAll();
					new String:name[64];
					GetClientName(target,name,64);

					//EmitSoundToAll(MedusaSound,target);
					//EmitSoundToAll(MedusaSound,target);

					War3_ChatMessage(target,"%T","You have been petrified by Medusa's Gaze!",target);

					new Float:CooldownTime = GetConVarFloat(MedusaCooldownCvar);
					War3_CooldownMGR(client,CooldownTime,thisRaceID,ULT_MEDUSA,_,_);
				}
				else
				{
					W3MsgNoTargetFound(client,distance);
				}
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public Action:StopPetrification(Handle:timer,any:client)
{

	bIsPetrified[client]=false;
	War3_SetBuff(client,bNoMoveMode,thisRaceID,false);

}

// =================================================================================================
// =================================================================================================
// =================================================================================================