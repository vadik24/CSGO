/**
* File						: War3Source_Zombie.sp
* Description				: The Zombie race for War3Source.
* Author(s)					: Schmarotzer
* Original ES Idea			: [Oddity]TeacherCreature
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

new thisRaceID;
new String:ZombieT[]="models/zombie.mdl";
new String:ZombieCT[]="models/player/mapeadores/kaem/zh/zh1.mdl";
new String:BrainsSound0[]="music/war3source/zombiesch/brains1.mp3";
new String:BrainsSound1[]="music/war3source/zombiesch/brains2.mp3";
new String:ClawSound0[]="music/war3source/zombiesch/claw1.mp3";
new String:ClawSound1[]="music/war3source/zombiesch/claw2.mp3";
new String:ClawSound2[]="music/war3source/zombiesch/claw3.mp3";
new String:SpawnSound[]="music/war3source/zombiesch/spawn.mp3";

new Float:RageTime[5]={0.0,1.0,2.0,3.0,4.0};
new Float:StartZSpeed[5]={1.0,0.95,0.9,0.85,0.8};
new Float:ConvictionPercent[5]={1.0,0.9,0.8,0.7,0.6};
new Float:BrainsDivider[5]={0.0,4.0,3.0,2.0,1.0};
new Float:ClawPercent[5]={0.0,0.50,0.55,0.60,0.65};

new SKILL_RAGE,SKILL_CONVICTION,SKILL_BRAINS,SKILL_CLAW;

public Plugin:myinfo = 
{
	name = "War3Source Race - Zombie",
	author = "Schmarotzer",
	description = "The Zombie race for War3Source.",
	version = "1.0.3.4",
	url = "http://css.bashtel.ru"
};

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==10)
	{
		thisRaceID			=War3_CreateNewRaceT("zombiesch");
		SKILL_RAGE			=War3_AddRaceSkillT(thisRaceID,"ZombieRage",false,4);
		SKILL_CONVICTION	=War3_AddRaceSkillT(thisRaceID,"ZombieConviction",false,4);
		SKILL_BRAINS		=War3_AddRaceSkillT(thisRaceID,"EatBrains",false,4);
		SKILL_CLAW			=War3_AddRaceSkillT(thisRaceID,"ClawAndBite",false,4); 
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnPluginStart()
{
	LoadTranslations("w3s.race.zombiesch.phrases");
}

public OnMapStart()
{
	////War3_PrecacheSound(BrainsSound0);
	////War3_PrecacheSound(BrainsSound1);
	////War3_PrecacheSound(ClawSound0);
	////War3_PrecacheSound(ClawSound1);
	////War3_PrecacheSound(ClawSound2);
	////War3_PrecacheSound(SpawnSound);
	//PrecacheModel(ZombieT, true);
	//PrecacheModel(ZombieCT, true);
}

public NormalSpeed(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skill_level_rage=War3_GetSkillLevel(client,thisRaceID,SKILL_RAGE);
		if(skill_level_rage>0)
		{
			new Float:StartSpeed = StartZSpeed[skill_level_rage];
			W3ResetBuffRace(client,fSlow,thisRaceID);
			W3ResetBuffRace(client,fMaxSpeed,thisRaceID);
			War3_SetBuff(client,fSlow,thisRaceID,StartSpeed);
		}
	}
}

public OnWar3EventSpawn(client)
{

	//SetEntityMoveType(client,MOVETYPE_WALK);
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
		ActivateSkills(client);
		//EmitSoundToAll(SpawnSound,client);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
		War3_WeaponRestrictTo(client,thisRaceID,"");
	}
	if(newrace==thisRaceID)
	{
		ActivateSkills(client);
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		ActivateSkills(client);
	}
}

// *************************************************************************************************

public ActivateSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
		SetEntityHealth(client, 200); 
		//War3_SetBuff(client,fSlow,thisRaceID,0.8);
		NormalSpeed(client);
		
		/*if(ValidPlayer(client,true))
		{
			new ClientTeam = GetClientTeam(client);
			switch(ClientTeam)
			{
				case 3:
					SetEntityModel(client, ZombieCT);
				case 2:
					SetEntityModel(client, ZombieT);
			}
			
		}
		*/
	}
}

// *********************************************************************************

public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim,true) && ValidPlayer(attacker,true) && attacker!=victim)
	//if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new skill_level_rage=War3_GetSkillLevel(victim,thisRaceID,SKILL_RAGE);
			if(War3_GetRace(victim)==thisRaceID && skill_level_rage>0 ) 
			{
				if(GetRandomFloat(0.0,1.0)<=0.50 && !W3HasImmunity(attacker,Immunity_Skills))
				{
					new Float:rage_time=RageTime[skill_level_rage];
					W3ResetBuffRace(victim,fSlow,thisRaceID);
					War3_SetBuff(victim,fMaxSpeed,thisRaceID,1.5);
					PrintHintText(victim,"%T","Got a speed boost for {amount} seconds",victim,rage_time);
					//War3_ChatMessage(victim,"%T","Got a speed boost for [amount] seconds",victim,ragetime);
					CreateTimer(rage_time,ZombieSpeed,victim);
				}
			}
			
			new skill_level_brains=War3_GetSkillLevel(attacker,thisRaceID,SKILL_BRAINS);
			new skill_level_claw=War3_GetSkillLevel(attacker,race_attacker,SKILL_CLAW);
			if(race_attacker==thisRaceID) 
			{
				new Float:skillrandom = GetRandomFloat(0.0,1.0);
				if(skillrandom < 0.4)
				{
					if(skill_level_brains>0 && !W3HasImmunity(victim,Immunity_Skills))
					{
						//new zombierace=War3_GetRaceIDByShortname("zombiesch");
						if(War3_GetRace(victim)!=thisRaceID)
						{
							new hpreturn=RoundToFloor(damage/BrainsDivider[skill_level_brains]);
							War3_HealToMaxHP(attacker,hpreturn);
							//War3_HealToBuffHP(attacker,hpreturn);
							PrintHintText(victim,"%T","The Zombie is eating your brains",victim);
							PrintHintText(attacker,"%T","You are eating the enemys brains",attacker);
							
							new random = GetRandomInt(0,1);
							if(random==0){
								//EmitSoundToAll(BrainsSound0,attacker);
							}else{
								//EmitSoundToAll(BrainsSound1,attacker);
							}
						}
					}
				}
				else
				{
					if(skill_level_claw>0 && !W3HasImmunity(victim,Immunity_Skills))
					{
						new Float:percent=ClawPercent[skill_level_claw]; //0.0 = zero effect -1.0 = no damage 1.0=double damage
						new health_take=RoundFloat(damage*percent);
						if(War3_DealDamage(victim,health_take,attacker,_,"claw and bite",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL,true))
						{	
							W3PrintSkillDmgHintConsole(victim,attacker,War3_GetWar3DamageDealt(),SKILL_CLAW);
							W3FlashScreen(victim,RGBA_COLOR_RED);
							
							new random = GetRandomInt(0,2);
							if(random==0){
								//EmitSoundToAll(ClawSound0,attacker);
							}else if(random==1){
								//EmitSoundToAll(ClawSound1,attacker);
							}else{
								//EmitSoundToAll(ClawSound2,attacker);
							}
						}
					}
				}
			}
		}
	}
}

public Action:ZombieSpeed(Handle:timer,any:victim)
{
	if(War3_GetRace(victim)==thisRaceID)
	{
		W3ResetBuffRace(victim,fMaxSpeed,thisRaceID);
		NormalSpeed(victim);
	}
}

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
		if(War3_GetRace(victim)==thisRaceID)
		{
			if(hitgroup!=1)
			{
				//new zombierace=War3_GetRaceIDByShortname("zombiesch");
				if(War3_GetRace(attacker)==thisRaceID && GetClientTeam(victim)!=GetClientTeam(attacker))
				{
					//damage=100.0;
				}
				else
				{
					damage=0.0;
					PrintHintText(victim,"%T","They are shooting you",victim);
					PrintHintText(attacker,"%T","To kill a zombie aim for the head",attacker);
				}
			}
			else
			{
				new skill_level_conviction=War3_GetSkillLevel(victim,thisRaceID,SKILL_CONVICTION);
				if(skill_level_conviction>0 ) 
				{
					//War3_DamageModPercent(2.0);
					damage*=ConvictionPercent[skill_level_conviction];
				}
			}
		}
	}
	return Plugin_Changed;
}
