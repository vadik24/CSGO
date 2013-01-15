/**
* File: War3Source_StealthAssassin.sp
* Description: a race for War3Source.
* Author(s): [Oddity]TeacherCreature
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools_functions>	
#include <sdktools>
#include <sdkhooks>

new thisRaceID;

new smokesprite;
new bool:bSmoking[66];
new Float:SavePos[66][3];

new bool:bDucking[66];
new Float:caninvistime[66];
new Float:InvisTimer[]={5.0, 2.5, 2.3, 2.1, 1.9, 1.7, 1.5};

new Float:StabChance[]={0.0, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45 };
new Damage[]={0, 15,20,25,30,35,40};
//&&bDucking[attacker]
new Float:pOsition[3];
new Handle:ultCooldownCvar;
new Handle:ultRangeCvar;
new g_offsCollisionGroup;

new Float:ASSASSINATION_cooldown[7]={0.0,35.0,30.0,25.0,20.0,15.0,10.0};
new String:UltimateSound[]="war3source/stealth/ability_02_1.mp3";
new String:Spawn1Sound[]="war3source/stealth/attack_1.mp3";
new String:Spawn2Sound[]="war3source/stealth/attack_2.mp3";
new String:Spawn3Sound[]="war3source/stealth/attack_3.mp3";
new String:AlertSound[]="war3source/stealth/taunt_prior.mp3";
new String:TauntSound[]="war3source/stealth/taunt_after.mp3";
new String:SmokeSound[]="war3source/stealth/ability_01.mp3";


new SKILL_SMOKE, SKILL_INVIS, SKILL_STAB, ULT_ASSASSINATION;

public Plugin:myinfo = 
{
	name = "War3Source Race - Stealth Assassin",
	author = "TeacherCreature",
	description = "The stealth assassin race for War3Source.",
	version = "1.0.7.6",
	url = "http://war3source.com"
};

public OnPluginStart()
{
	HookEvent("weapon_fire", WeaponFire);
	ultCooldownCvar=CreateConVar("war3_assassination_cooldown","30","Cooldown between ultimate usage");
	ultRangeCvar=CreateConVar("war3_assassination_range","1000","Range of assination ultimate");
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	CreateTimer(0.1,CalcVis,_,TIMER_REPEAT);
	CreateTimer(0.1,Smoker,_,TIMER_REPEAT);
}

public Action:Smoker(Handle:timer,any:userid)
{
	for(new x=0;x<MaxClients;x++)
	{
		if(ValidPlayer(x)&&War3_GetRace(x)==thisRaceID)
		{
			new smoke_level = War3_GetSkillLevel(x,thisRaceID,SKILL_SMOKE);
			if(smoke_level>0 && bSmoking[x])
			{
				TE_SetupSmoke(SavePos[x], smokesprite, 1000.0, 1);
				TE_SendToAll();
				SavePos[x][0]+=100;
				TE_SetupSmoke(SavePos[x], smokesprite, 1000.0, 1);
				TE_SendToAll();
				SavePos[x][0]-=100;
				SavePos[x][1]+=100;
				TE_SetupSmoke(SavePos[x], smokesprite, 1000.0, 1);
				TE_SendToAll();
				for(new y=0;y<MaxClients;y++)
				{
					if(ValidPlayer(y,true) && GetClientTeam(y)!=GetClientTeam(x))
					{
						new Float:targpos[3];
						GetClientAbsOrigin(y,targpos);
						if(GetVectorDistance(SavePos[x],targpos)<250.0)
						{
							War3_SetBuff(y,fSlow,thisRaceID,0.8);
							War3_SetBuff(y,fAttackSpeed,thisRaceID,0.8);
							War3_SetBuff(y,bSilenced,thisRaceID,true);
							CreateTimer(1.0,norm,y);
						}
					}
				}
			}
		}
	}
}

public Action:norm(Handle:timer,any:client)
{
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
	War3_SetBuff(client,bSilenced,thisRaceID,false);
}
public Action:CalcVis(Handle:timer,any:userid)
{
	for(new i=0;i<MaxClients;i++)
	{
		if(ValidPlayer(i)&&War3_GetRace(i)==thisRaceID)
		{
			new invis_level = War3_GetSkillLevel(i,thisRaceID,SKILL_INVIS);
			if(caninvistime[i]<GetGameTime() && invis_level>0)
			{
				War3_SetBuff(i,fInvisibilitySkill,thisRaceID,0.0);
			}
			else
			{
				War3_SetBuff(i,fInvisibilitySkill,thisRaceID,1.0);
			}
			if(invis_level>0&&!bDucking[i])
			{
				caninvistime[i]=GetGameTime() + InvisTimer[invis_level];
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(ValidPlayer(client)&&War3_GetRace(client)==thisRaceID)
	{
		bDucking[client]=(buttons & IN_DUCK)?true:false;
	}
	return Plugin_Continue;
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==49)
	{
		thisRaceID=War3_CreateNewRaceT("stealth");
		SKILL_SMOKE=War3_AddRaceSkillT(thisRaceID,"SmokeScreen",false,6);
		SKILL_STAB=War3_AddRaceSkillT(thisRaceID,"BackStab",false,6);
		SKILL_INVIS=War3_AddRaceSkillT(thisRaceID,"PermaInvis",false,6);
		ULT_ASSASSINATION=War3_AddRaceSkillT(thisRaceID,"BlinkStrike",true,6);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnMapStart()
{
	//War3_PrecacheSound(UltimateSound);
	//War3_PrecacheSound(Spawn1Sound);
	//War3_PrecacheSound(Spawn2Sound);
	//War3_PrecacheSound(Spawn3Sound);
	//War3_PrecacheSound(TauntSound);
	//War3_PrecacheSound(AlertSound);
	//War3_PrecacheSound(SmokeSound);
	smokesprite=PrecacheModel("sprites/smoke.vmt");
}

public Action:WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new index=GetClientOfUserId(userid);
	if(index>0)
	{
		if(War3_GetRace(index)==thisRaceID)
		{
			new invis_level = War3_GetSkillLevel(index,thisRaceID,SKILL_INVIS);
			if(invis_level>0)
			{
				caninvistime[index]=GetGameTime() + InvisTimer[invis_level];
			}
		}
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(!Silenced(client))
	{
		if (ability==0)
		{
			if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
			{
				new smoke_level=War3_GetSkillLevel(client,thisRaceID,SKILL_SMOKE);
				if(smoke_level>0)
				{
					if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_SMOKE,false))
					{
						War3_CooldownMGR(client,10.0,thisRaceID,SKILL_SMOKE);
						
						GetClientAbsOrigin(client, SavePos[client]);
						bSmoking[client]=true;
						//EmitSoundToAll(SmokeSound,client);
						CreateTimer(5.0,nosmoke,client);
					}
				}
			}
		}
	}
	else
	{
		PrintHintText(client,"Silenced");
	}
}

public Action:nosmoke(Handle:timer,any:client)
{
	bSmoking[client]=false;
}

public OnWar3EventDeath(victim,attacker){
	if(ValidPlayer(victim)&&ValidPlayer(attacker)&&War3_GetRace(attacker)==thisRaceID&&bDucking[attacker]){
		//EmitSoundToAll(TauntSound,attacker);
	}
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_STAB);
			if(race_attacker==thisRaceID && skill_level>0 )
			{
				if(GetRandomFloat(0.0,1.0)<=StabChance[skill_level] && !W3HasImmunity(victim,Immunity_Skills))
				{
					War3_DealDamage(victim,Damage[skill_level],attacker,_,"BackStab",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL);
				}
			}
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(!Silenced(client))
	{
		new userid=GetClientUserId(client);
		if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
		{
			new ult_level=War3_GetSkillLevel(client,race,ULT_ASSASSINATION);
			if(ult_level>0)
			{
				
				if(War3_SkillNotInCooldown(client,thisRaceID,ULT_ASSASSINATION,true))
				{
					new Float:posVec[3];
					GetClientAbsOrigin(client,posVec);
					new Float:otherVec[3];
					new Float:bestTargetDistance=1000.0; 
					new team = GetClientTeam(client);
					new bestTarget=0;
					
					new Float:ultmaxdistance=GetConVarFloat(ultRangeCvar);
					for(new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Ultimates))
						{
							GetClientAbsOrigin(i,otherVec);
							new Float:dist=GetVectorDistance(posVec,otherVec);
							if(dist<bestTargetDistance&&dist<ultmaxdistance)
							{
								bestTarget=i;
								bestTargetDistance=GetVectorDistance(posVec,otherVec);
								
							}
						}
					}
					if(bestTarget==0)
					{
						W3MsgNoTargetFound(client,bestTargetDistance);
					}
					else
					{
						new damage=RoundFloat(float(War3_GetMaxHP(bestTarget))/2.0);
						if(damage>0)
						{
							War3_CachedPosition(bestTarget,Float:pOsition);
							TeleportEntity(client,pOsition,NULL_VECTOR,NULL_VECTOR);
							SetEntData(bestTarget, g_offsCollisionGroup, 2, 4, true);
							
							SetEntData(client, g_offsCollisionGroup, 2, 4, true);
							CreateTimer(2.0,normal,client);
							SetEntData(bestTarget, g_offsCollisionGroup, 2, 4, true);
							CreateTimer(2.0,normal,bestTarget);
							//EmitSoundToAll(AlertSound,bestTarget);
							//EmitSoundToAll(UltimateSound,client);
							CooldownUltimate(client);
							
							
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
	/*
	else
	{
		PrintHintText(client,"SILENCED");
	}
	*/
}

public Action:normal(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		new Float:end_dist=40.0;
		new Float:end_pos[3];
		GetClientAbsOrigin(client,end_pos);
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&i!=client)
			{
				new Float:pos[3];
				GetClientAbsOrigin(i,pos);
				new Float:dist=GetVectorDistance(end_pos,pos);
				if(dist<=end_dist)
				{
					CreateTimer(0.5,normal,client);
					break;
				}
				else{
					SetEntData(client, g_offsCollisionGroup, 5, 4, true);
				}
			}
		}
	}
}

public CooldownUltimate(client)
{
	new skilllevel_assassination = War3_GetSkillLevel(client,thisRaceID,ULT_ASSASSINATION);
	War3_CooldownMGR(client,ASSASSINATION_cooldown[skilllevel_assassination],thisRaceID,ULT_ASSASSINATION);
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	if(newrace==thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		War3_SetBuff(client,bDoNotInvisWeapon,thisRaceID,true);
		new DICE = (GetRandomInt(1,3));
		if(DICE == 1)
		{
			//EmitSoundToAll(Spawn1Sound,client);
		}
		if(DICE == 2)
		{
			//EmitSoundToAll(Spawn2Sound,client);
		}
		if(DICE == 3)
		{
			//EmitSoundToAll(Spawn3Sound,client);
		}		
	}
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		new DICE = (GetRandomInt(1,3));
		if(DICE == 1)
		{
			//EmitSoundToAll(Spawn1Sound,client);
		}
		if(DICE == 2)
		{
			//EmitSoundToAll(Spawn2Sound,client);
		}
		if(DICE == 3)
		{
			//EmitSoundToAll(Spawn3Sound,client);
		}
	}
}