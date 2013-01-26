 /**
* File: War3Source_Necromancer.sp
* Description: The Necromancer unit for War3Source.
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

//native War3_GetAimEndPoint(client,Float:returnvector[3]);

new thisRaceID;

//skill 1
new Float:CrippleChance[]={0.00,0.20,0.24,0.28,0.32,0.36,0.40,0.44,0.48};
//skill 2
new FrenzyCost[]={0,8,7,6,5,4,3,2,1};
new bool:bFrenzy[66];

//skill 3
new Mastery[9]={0,5,10,15,20,25,30,35,40};

//skill 4
new String:facsnd[]="vo/trainyard/ba_backup.mp3";
new Raiser[MAXPLAYERS+1];
new bool:Skeleton[MAXPLAYERS+1][MAXPLAYERS+1];
new Float:RaiseDeadChance[9]={0.0,0.40,0.40,0.45,0.50,0.55,0.60,0.65,0.70};
new g_offsCollisionGroup;
new Float:skeletsMaxDistance = 1000.0; // ~30 meters
new nSkelets;

new SKILL_CRIPPLE, SKILL_UNHOLYFRENZY, SKILL_MASTERY, ULT_RAISEDEAD;

public Plugin:myinfo = 
{
	name = "War3Source Race - Necromancer",
	author = "[Oddity]TeacherCreature + Namolem",
	description = "The Necromancer unit for War3Source.",
	version = "1.1.0.0",
	url = "warcraft-source.net"
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==320)
	{
		thisRaceID=War3_CreateNewRaceT("necro");
		SKILL_CRIPPLE=War3_AddRaceSkillT(thisRaceID,"cripple",false,8);
		SKILL_UNHOLYFRENZY=War3_AddRaceSkillT(thisRaceID,"frenzy",false,8);
		SKILL_MASTERY=War3_AddRaceSkillT(thisRaceID,"mastery",false,8);
		ULT_RAISEDEAD=War3_AddRaceSkillT(thisRaceID,"raise",true,8); 
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnMapStart()
{
	////War3_PrecacheSound(facsnd);
	//PrecacheModel("models/player/slow/bones/bones.mdl", true);
	
}
public OnPluginStart()
{
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	// HookEvent("round_end",RoundEndEvent);
	CreateTimer(0.2,CalcSkelets,_,TIMER_REPEAT);
	HookEvent("round_start",RoundStartEvent);
	LoadTranslations("w3s.race.necro.phrases");
}
public Action:RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	nSkelets = 0;
	for (new i=1;i<=MaxClients;i++)
	{
		Raiser[i] = 0;
		for (new j=1;j<= MaxClients;j++)
			Skeleton[i][j] = false;
	}
}
public Action:CalcSkelets(Handle:timer)
{
	if (nSkelets > 0)
	{
		for (new necromant=1; necromant <= MaxClients;necromant++)
		{
			if (!ValidPlayer(necromant,true)) continue;
			for (new skelet = 1; skelet < MaxClients;skelet++)
			{
				if (!ValidPlayer(skelet,true)) continue;
				if (Skeleton[necromant][skelet] == true)
				{
					decl Float:masterVec[3];
					decl Float:skeletVec[3];
					GetClientAbsOrigin(necromant,masterVec);
					GetClientAbsOrigin(skelet,skeletVec);
					new Float:distance = GetVectorDistance(masterVec,skeletVec);
					if (distance > skeletsMaxDistance)
					{
						War3_DealDamage(skelet,1,0,DMG_GENERIC,"necromants chain");
						new DamageScreen[4] = {10,10,10,50};
						W3FlashScreen(skelet,DamageScreen);
						PrintHintText(skelet,"%t","too far from master");
					}
				}
			}
		}
	}
	
}
public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim,true) && ValidPlayer(attacker) && attacker!=victim)
	{
		if(GetClientTeam(victim)!=GetClientTeam(attacker))
		{
			new race_attacker=War3_GetRace(attacker);
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_CRIPPLE);
			if(race_attacker==thisRaceID && skill_level>0 )
			{
				if(GetRandomFloat(0.0,1.0)<=CrippleChance[skill_level] && !W3HasImmunity(victim,Immunity_Skills))
				{
					War3_SetBuff(victim,fSlow,thisRaceID,0.6);
					War3_SetBuff(victim,fAttackSpeed,thisRaceID,0.5);
					W3FlashScreen(victim,RGBA_COLOR_RED);
					CreateTimer(2.0,RemoveCripple,victim);
					PrintHintText(victim,"%t","you were crippled");
					PrintHintText(attacker,"%t","you crippled enemy");
				}
			}
		}
	}
}
public Action:RemoveCripple(Handle:t,any:client){
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
}
public OnWar3EventDeath(victim,attacker)
{
	if (War3_GetRace(victim) == thisRaceID)
	{
		new Handle:pack;
		CreateDataTimer(0.5,KillSkelets,pack);
		WritePackCell(pack,victim);
		WritePackCell(pack,attacker);
		
	}
}

public Action:KillSkelets(Handle:timer,Handle:pack)
{
	ResetPack(pack);
	new victim = ReadPackCell(pack);
	new attacker = ReadPackCell(pack);
	for (new skelet = 1; skelet <= MaxClients; skelet++)
	{
		if (ValidPlayer(skelet,true) && Skeleton[victim][skelet])
		{
			War3_DealDamage(skelet,999,attacker,DMG_GENERIC,"necromant chain");
			PrintHintText(skelet,"%t","your master dead");
		}
	}
}
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_UNHOLYFRENZY);
		if(skill_level>0)
		{
			
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_UNHOLYFRENZY,true))
			{
				if(bFrenzy[client]==false)
				{
					bFrenzy[client]=true;
					CreateTimer(0.1,Frenzy,client);
					War3_CooldownMGR(client,3.0,thisRaceID,SKILL_UNHOLYFRENZY);
					PrintHintText(client,"%t","frenzy activated");
				}
				else
				{
					bFrenzy[client]=false;
					PrintHintText(client,"%t","frenzy deactivated");
				}
			}
		}
	}
}

public Action:Frenzy(Handle:t,any:client)
{
	new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_UNHOLYFRENZY);
	if(skill_level>0)
	{	
		if(bFrenzy[client]==true)
		{
			new hpsub=FrenzyCost[skill_level];
			if(hpsub<GetClientHealth(client))
			{
				SetEntityHealth(client,GetClientHealth(client)-hpsub);
			}
			else
			{
				War3_DealDamage(client,FrenzyCost[skill_level],client,DMG_BULLET,"Unholy Frenzy");
			}
			War3_SetBuff(client,fAttackSpeed,thisRaceID,1.4);
			CreateTimer(1.0,Frenzy,client);
		}
		else
		{
			War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
		}
	}
}


public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		bFrenzy[client]=false;
		W3ResetAllBuffRace(client,thisRaceID);
		W3SetPlayerColor(client,thisRaceID,255,255,255);
	}
}

public OnWar3EventSpawn(client)
{
	new race = War3_GetRace(client);
	if (race == thisRaceID)
	{ 
		bFrenzy[client]=false;
		if(GetClientTeam(client)==3)
		{
			W3SetPlayerColor(client,thisRaceID,255,255,255);
		}
		else
		{
			W3SetPlayerColor(client,thisRaceID,220,50,0);
		}
	}
	else
	{
		W3ResetPlayerColor(client,thisRaceID);
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new ult_level_raise=War3_GetSkillLevel(client,thisRaceID,ULT_RAISEDEAD);
		if(ult_level_raise>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_RAISEDEAD,true))
			{
				new skill_master=War3_GetSkillLevel(client,thisRaceID,SKILL_MASTERY);
				if(GetRandomFloat(0.0,1.0)<=RaiseDeadChance[ult_level_raise])
				{
					new possibletargets[MAXPLAYERS+1];
					new possibletargetsfound;
					for(new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i))
						{
							if(IsPlayerAlive(i)==false && GetClientTeam(i)==GetClientTeam(client))
								{
									possibletargets[possibletargetsfound]=i;
									possibletargetsfound++;
								}
						}
					}
					new onetarget;
					if(possibletargetsfound>0)
					{
						onetarget=possibletargets[GetRandomInt(0, possibletargetsfound-1)]; //i hope random 0 0 works to zero
						if(onetarget>0)
						{
							Skeleton[client][onetarget]=true;
							War3_CooldownMGR(client,15.0,thisRaceID,ULT_RAISEDEAD);
							decl Float:ang[3];
							decl Float:pos[3];
							War3_SpawnPlayer(onetarget);
							GetClientEyeAngles(client,ang);
							GetClientAbsOrigin(client,pos);
							TeleportEntity(onetarget,pos,ang,NULL_VECTOR);
							//EmitSoundToAll(facsnd,client);
							Raiser[onetarget]=client;
							nSkelets++;
							//SetEntityModel(onetarget, "models/player/slow/bones/bones.mdl");
							if(GetClientTeam(onetarget)==3)
							{
								W3SetPlayerColor(onetarget,thisRaceID,20,100,200); //fyi the new buff sytem includes setplayercolor, so ud have to change all these functions names
							}
							else
							{
								W3SetPlayerColor(onetarget,thisRaceID,200,100,20);
							}
							//War3_WeaponRestrictTo(onetarget,"weapon_knife");
							War3_SetBuff(onetarget,iAdditionalMaxHealth,thisRaceID,Mastery[skill_master]);
							War3_SetBuff(onetarget,fMaxSpeed,thisRaceID,0.9);
							PrintHintText(onetarget,"%t","you were risen");
							PrintHintText(client,"%t","you rose corpse");
							SetEntData(onetarget, g_offsCollisionGroup, 2, 4, true);
							CreateTimer(3.0,normal,onetarget);
							CreateTimer(3.0,normal,client);
						}
					}
					else
					{
						PrintHintText(client,"%t","need body");
					}
				}
				else
				{
					PrintHintText(client,"%t","rise failed");
					War3_CooldownMGR(client,3.0,thisRaceID,ULT_RAISEDEAD);
				}
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public Action:normal(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		new Float:end_dist=50.0;
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
					CreateTimer(1.0,normal,client);
					break;
				}
				else{
					SetEntData(client, g_offsCollisionGroup, 5, 4, true);
				}
			}
		}
	}
}