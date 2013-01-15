/**
* File: War3Source_Jamshut.sp
* Description: Jamshut race builder of Comedy Club.
* Author: [I]Loki 
*/
 
#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Jamshut",
	author = "[I]Loki",
	description = "Jamshut race builder of Comedy Club",
	version = "1.0",
	url = "Arsenall.net"
}

new thisRaceID;

//CBULLETS
new Float:JamshutStrikePercent[5]={0.0,0.33,0.66,1.01,1.33}; 
new Handle:EntangleCooldownCvar; // cooldown

//CKICK
new KickSprite;
new m_vecBaseVelocity; //offsets
new Float:KickVec[9]={0.0,380.0,390.0,400.0,410.0,420.0,430.0,440.0,450.0};
new String:CKick[]="physics/cardboard/cardboard_box_impact_hard4.mp3";

//Worker
new Float:JamshutSpeed[5]={1.0,1.1,1.2,1.3,1.4};
new Float:JamshutGravity[5]={1.0,0.9,0.8,0.7,0.6};


//Wall
new Float:Cooldown[]={5.0, 4.0, 2.0, 1.0, 0.0};

//Skills & Ultimate
new SKILL_CBULLETS, SKILL_CKICK, SKILL_WORKER, ULT_WALL;

public OnPluginStart()
{
	LoadTranslations("w3s.race.jamshut.phrases");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	EntangleCooldownCvar=CreateConVar("war3_jamshut_entangle_cooldown","20","Cooldown timer.");
}

public OnMapStart()
{
	////War3_PrecacheSound(CKick);
	//ShieldSprite=PrecacheModel("sprites/strider_blackball.vmt");
	KickSprite=PrecacheModel("sprites/lgtning.vmt");
	PrecacheModel("models/props/de_nuke/cinderblock_stack.mdl");
	
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==100){
	
		thisRaceID=War3_CreateNewRaceT("jamshut");
		SKILL_CBULLETS=War3_AddRaceSkillT(thisRaceID,"CBullets", false,4);
		SKILL_CKICK=War3_AddRaceSkillT(thisRaceID,"CKick",false,4);
		SKILL_WORKER=War3_AddRaceSkillT(thisRaceID,"Worker",false,4);
		ULT_WALL=War3_AddRaceSkillT(thisRaceID,"Wall",true,4);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnRaceChanged(client, oldrace, newrace)
{
	if(newrace!=thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
		
	}
	
	if(newrace==thisRaceID){
		InitPassiveSkills(client);
	}
}

public OnWar3EventSpawn(client)
{
	//PrintToChatAll("SPAWN %d",client);
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public InitPassiveSkills(client)
{
	new skilllevel_worker=War3_GetSkillLevel(client,thisRaceID,SKILL_WORKER);
	War3_SetBuff(client,fMaxSpeed,thisRaceID,JamshutSpeed[skilllevel_worker]);
	War3_SetBuff(client,fLowGravitySkill,thisRaceID,JamshutGravity[skilllevel_worker]);
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
			new Float:chance_mod=W3ChanceModifier(attacker);
			if(race_attacker==thisRaceID)
			{
				new skilllevel_attacker=War3_GetSkillLevel(attacker,race_attacker,SKILL_CBULLETS);
				if(skilllevel_attacker>0&&!Hexed(attacker,false))
				{
					new Float:chance=0.15*chance_mod;
					if( GetRandomFloat(0.0,1.0)<=chance && !W3HasImmunity(victim,Immunity_Skills))
					{
						new Float:percent=JamshutStrikePercent[skilllevel_attacker]; //0.0 = zero effect -1.0 = no damage 1.0=double damage
						new health_take=RoundFloat(damage*percent);
						if(War3_DealDamage(victim,health_take,attacker,_,"jamshutstrike",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL,true))
						{	
							W3PrintSkillDmgHintConsole(victim,attacker,War3_GetWar3DamageDealt(),SKILL_CBULLETS);
							W3FlashScreen(victim,RGBA_COLOR_RED);
						}
					}
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
			//new race_victim=War3_GetRace(victim);
			new skilllevel_ckick=War3_GetSkillLevel(attacker,thisRaceID,SKILL_CKICK);
			// CKick
			if(race_attacker==thisRaceID && skilllevel_ckick>0)
			{
				if(GetRandomFloat(0.0,1.0)<=0.3 && !W3HasImmunity(victim,Immunity_Skills)&&!Silenced(attacker))
				{
					new Float:targpos[3];
					GetClientAbsOrigin(victim,targpos);
					TE_SetupBeamRingPoint(targpos, 20.0, 80.0,KickSprite,KickSprite, 0, 5, 2.6, 20.0, 0.0, {154,66,120,100}, 10,FBEAM_HALOBEAM);
					TE_SendToAll();
					targpos[2]+=20.0;
					TE_SetupBeamRingPoint(targpos, 40.0, 100.0,KickSprite,KickSprite, 0, 5, 2.4, 20.0, 0.0, {154,66,120,100}, 10,FBEAM_HALOBEAM);
					TE_SendToAll();
					targpos[2]+=20.0;
					//TE_SetupGlowSprite(targpos, ShieldSprite, 1.0, 1.0, 130);
					//TE_SendToAll(); 
					TE_SetupBeamRingPoint(targpos, 60.0, 120.0,KickSprite,KickSprite, 0, 5, 2.2, 20.0, 0.0, {154,66,120,100}, 10, FBEAM_HALOBEAM);
					TE_SendToAll();
					targpos[2]+=20.0;
					TE_SetupBeamRingPoint(targpos, 80.0, 140.0,KickSprite,KickSprite, 0, 5, 2.0, 20.0, 0.0, {154,66,120,100}, 10, FBEAM_HALOBEAM);
					TE_SendToAll();	
					targpos[2]+=20.0;
					TE_SetupBeamRingPoint(targpos, 100.0, 160.0,KickSprite,KickSprite, 0, 5, 1.8, 20.0, 0.0, {154,66,120,100}, 10, FBEAM_HALOBEAM);
					TE_SendToAll();	
					targpos[2]+=20.0;
					TE_SetupBeamRingPoint(targpos, 120.0, 180.0,KickSprite,KickSprite, 0, 5, 1.6, 20.0, 0.0, {154,66,120,100}, 10, FBEAM_HALOBEAM);
					TE_SendToAll();	
					targpos[2]+=20.0;
					TE_SetupBeamRingPoint(targpos, 140.0, 200.0,KickSprite,KickSprite, 0, 5, 1.4, 20.0, 0.0, {154,66,120,100}, 10, FBEAM_HALOBEAM);
					TE_SendToAll();	
					targpos[2]+=20.0;
					TE_SetupBeamRingPoint(targpos, 160.0, 220.0,KickSprite,KickSprite, 0, 5, 1.2, 20.0, 0.0, {154,66,120,100}, 10, FBEAM_HALOBEAM);
					TE_SendToAll();	
					targpos[2]+=20.0;
					TE_SetupBeamRingPoint(targpos, 180.0, 240.0,KickSprite,KickSprite, 0, 5, 1.0, 20.0, 0.0, {154,66,120,100}, 10, FBEAM_HALOBEAM);
					TE_SendToAll();
					
					//EmitSoundToAll(CKick,attacker);

					new Float:velocity[3];
					velocity[2]=KickVec[skilllevel_ckick];
					SetEntDataVector(victim,m_vecBaseVelocity,velocity,true);
					PrintToConsole(attacker,"Cement Kick");
					PrintToConsole(victim,"Cement Kick");
					W3FlashScreen(victim,RGBA_COLOR_WHITE,1.0,1.0);
					//War3_SetBuff(victim,bBashed,thisRaceID,true);
					//CreateTimer(1.0,unbash,victim);
				}
			}
		}
	}
}

public Action:Destroy(Handle:timer,any:entity)
{
	UTIL_Remove(entity);
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true)){
		if(!Silenced(client)){
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_WALL,true)){
				new ultlevel_wall=War3_GetSkillLevel(client,thisRaceID,ULT_WALL);
				if(ultlevel_wall>0){
					new Float:tempendpos[3];
					War3_GetAimEndPoint(client,tempendpos);
					if (!isSomeBodyNear(tempendpos))
					{
						//new Float:playerpos[3];
						//GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerpos);
						new entindex = CreateEntityByName("prop_physics_override");
						//new entindex = CreateEntityByName("smokegrenade_projectile");
						
						DispatchKeyValue(entindex, "physdamagescale", "10.0");
						DispatchKeyValue(entindex, "health", "10.0");
						//SetEntityHealth(entindex, 10);
						//SetVariantInt(10);
						//AcceptEntityInput(entindex,"SetHealth",client);
						if (entindex != -1)
						{
							//DispatchKeyValue(entindex, "targetname", "loltest");
							if(GetClientTeam(client)==2){
								DispatchKeyValue(entindex, "model", "models/props_c17/chair_stool01a.mdl");
							}
							if(GetClientTeam(client)==3){
								DispatchKeyValue(entindex, "model", "models/props_c17/chair_stool01a.mdl");
							}
						}
						else
						{
							PrintToChatAll("Error creating block");
						}
						DispatchSpawn(entindex);
						
						
						
						TeleportEntity(entindex, tempendpos, NULL_VECTOR, NULL_VECTOR);
						//SetEntityMoveType(entindex, MOVETYPE_VPHYSICS);	
						ActivateEntity(entindex);
						SetEntityMoveType(entindex, MOVETYPE_NONE);	
						War3_CooldownMGR(client,GetConVarFloat(EntangleCooldownCvar),thisRaceID,ULT_WALL,_,_);
						CreateTimer(15.0,Destroy,entindex);
					}
					else
					{
						PrintToChat(client,"Somebody is possibly there.");
					}
				}
				else
				{
					W3MsgUltNotLeveled(client);
				}	
			}
		}
		else
		{
			PrintHintText(client,"%T","Silenced_Can_not_cast",client);
		}
	}
}

public bool:isSomeBodyNear(Float:point[3])
{
	decl Float:clientPos[3];
	for (new i = 1; i <= MaxClients;i++)
	{
		if (ValidPlayer(i,true))
		{
			GetClientAbsOrigin(i,clientPos);
			new Float:distance = GetVectorDistance(clientPos,point);
			if (distance <= 64) return true;
		}
	}
	return false;
}


