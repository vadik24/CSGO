/**
* File: War3Source_Brewmaster.sp
* Description: Pandaren Brewmaster race of warcraft.
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
new m_vecBaseVelocity;

//Pandaren Brewmaster
	//Drunken Brawler
new Float:BrawlDmg[]={1.0,2.0,2.4,2.8,3.2,3.6,4.0};
new Float:BrawlEvade[]={0.0,0.07,0.10,0.13,0.16,0.18,0.20};

	//Drunken Haze
new BarrelSprite;
new Float:HazeSpeed[]={1.0,0.85,0.78,0.71,0.64,0.57,0.50};
new Float:HazeMiss[]={0.0,0.40,0.48,0.56,0.64,0.72,0.80};
new Float:HazeDrunk[MAXPLAYERS];
new bool:bDrunk[MAXPLAYERS];
new bool:bHaze[MAXPLAYERS];
new String:haze_sound[]="war3source/brewmaster/haze.mp3";
new Float:HazeLocation[MAXPLAYERS][3];
new HazeCLIENT[MAXPLAYERS];

	//Breath of Fire
new BoFDmg[]={0,6,15,24,33,42,47};
new bool:bBoF[MAXPLAYERS];
new String:breath_sound[]="war3source/brewmaster/breath.mp3";
new bool:bBurned[MAXPLAYERS];

	//Storm, earth & Fire
new SEFForm[MAXPLAYERS]; //0 = brewmaster, 1 = Storm, 2 = Earth, 3 = Fire
new bool:bDied[MAXPLAYERS];
new String:ultimate_sound[]="war3source/brewmaster/ultimate.mp3";

//Storm
	//Dispell
	
	//Cyclone
	new bool:bCyclone[MAXPLAYERS];
	
	//Windwalk
	new bool:bInvis[MAXPLAYERS];
	
	//Ultimate Immunity
	
//Earth
	//Extra Damage
	
	//Taunt
	new bool:bTaunt[MAXPLAYERS];
	new Tauntby[MAXPLAYERS];
	//Skill Immunity
	
	//Ultimate Immunity

//Fire
	//Ultimate Immunity
	
	//Immolation

//Skills & Ultimate
new SKILL_BRAWL, SKILL_HAZE, SKILL_ABILITY, ULT_RESPAWN;

public Plugin:myinfo = 
{
	name = "War3Source Race - Pandaren Brewmaster",
	author = "Lucky",
	description = "Pandaren Brewmaster race of warcraft",
	version = "alpha",
	url = ""
}

public OnPluginStart()
{
	HookEvent("round_end",RoundOverEvent);
	HookEvent("weapon_fire", WeaponFire);
	CreateTimer(0.5,CalcHaze,_,TIMER_REPEAT);
	CreateTimer(1.0,BoF,_,TIMER_REPEAT);
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	CreateTimer(1.0,Immolation,_,TIMER_REPEAT);
}

public OnMapStart()
{
	////War3_PrecacheSound(haze_sound);
	////War3_PrecacheSound(breath_sound);
	////War3_PrecacheSound(ultimate_sound);
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	BarrelSprite=PrecacheModel("models/props_c17/woodbarrel001.mdl");
	LoadTranslations("w3s.race.brewmaster.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==010){
		thisRaceID=War3_CreateNewRaceT("brewmaster");
		SKILL_BRAWL=War3_AddRaceSkillT(thisRaceID,"1",false,6);
		SKILL_HAZE=War3_AddRaceSkillT(thisRaceID,"2",false,6);
		SKILL_ABILITY=War3_AddRaceSkillT(thisRaceID,"3",false,6);
		ULT_RESPAWN=War3_AddRaceSkillT(thisRaceID,"4",true,1);
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
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		if(ValidPlayer(client,true)){
			GivePlayerItem(client, "weapon_knife");
		}
	}
}

public Action:WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new client=GetClientOfUserId(userid);
	if(War3_GetRace(client)==thisRaceID){
		if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_HAZE,true)){
			if(SEFForm[client]==0){
				new skill_haze=War3_GetSkillLevel(client,thisRaceID,SKILL_HAZE);
				if(skill_haze>0){
					War3_CooldownMGR(client,12.0,thisRaceID,SKILL_HAZE,_,_);
					//EmitSoundToAll(haze_sound,client);
					HazeCLIENT[client]=client;
					War3_GetAimTraceMaxLen(client,HazeLocation[client],550.0);
					TE_SetupGlowSprite(HazeLocation[client],BarrelSprite,5.0,5.0,255);
					TE_SendToAll();
					bHaze[client]=true;
					CreateTimer(5.0, disableHaze,client);
				}
			}
		}
	}
}

public Action:disableHaze(Handle:timer,any:client)
{
	bHaze[client]=false;
}

public Action:CalcHaze(Handle:timer,any:userid)
{
	for(new x=1;x<=MaxClients;x++){
		if(ValidPlayer(x,true)){
			if(War3_GetRace(x)==thisRaceID){
				new client=HazeCLIENT[x];
				new Float:victimPos[3];
				if(HazeLocation[client][0]==0.0&&HazeLocation[client][1]==0.0&&HazeLocation[client][2]==0.0){
				}
				else 
				{
					if(bHaze[client]){
						new ownerteam=GetClientTeam(client);
						new skill_haze=War3_GetSkillLevel(client,thisRaceID,SKILL_HAZE);
						
						for (new i=1;i<=MaxClients;i++){
							if(ValidPlayer(i,true)&& GetClientTeam(i)!=ownerteam){
								GetClientAbsOrigin(i,victimPos);
								if(GetVectorDistance(HazeLocation[client],victimPos)<200.0){
									if(!W3HasImmunity(i,Immunity_Skills)){
										HazeDrunk[i]=HazeMiss[skill_haze];
										War3_SetBuff(i,fSlow,thisRaceID,HazeSpeed[skill_haze]);
										bDrunk[i]=true;
										CreateTimer(5.0,slow,i);
										
										//EmitSoundToAll(haze_sound,i);
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

public Action:slow(Handle:timer,any:victim)
{
	War3_SetBuff(victim,fSlow,thisRaceID,1.0);
	bDrunk[victim]=false;
	HazeDrunk[victim]=0.0;
}

public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i)&&War3_GetRace(i)==thisRaceID)
		{
			bDied[i]=false;
			SEFForm[i]=0;
		}
	}
}

public OnWar3EventSpawn(client)
{	
	War3_SetBuff(client,bBuffDenyAll,thisRaceID,false);
	if(War3_GetRace(client)==thisRaceID){
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.2);
		bHaze[client]=false;
		bBoF[client]=false;
		if(SEFForm[client]==1){
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,20);
		SetEntityHealth(client,120);
		}
		if(SEFForm[client]==2){
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,50);
		SetEntityHealth(client,170);
		}
		if(SEFForm[client]==3){
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,10);
		SetEntityHealth(client,110);
		}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	new race_victim=War3_GetRace(victim);
	
	if(race_victim==thisRaceID){
		new ult_respawn=War3_GetSkillLevel(victim,thisRaceID,ULT_RESPAWN);
		
		if(ult_respawn==1){
			if(!bDied[victim]){
				bDied[victim]=true;
				new Handle:menu = CreateMenu(SelectPower);
				SetMenuTitle(menu, "Which power do you want?");
				AddMenuItem(menu, "Storm", "Storm");
				AddMenuItem(menu, "Earth", "Earth");
				AddMenuItem(menu, "Fire", "Fire");
				SetMenuExitButton(menu, false);
				DisplayMenu(menu, victim, 20);	
			}
			if(SEFForm[victim]>0){
				SEFForm[victim]=0;
			}
		}
	}
}

public SelectPower(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if(StrEqual(info,"Storm"))
		{
			SEFForm[client]=1;
			War3_SpawnPlayer(client);
			//EmitSoundToAll(ultimate_sound,client);
			War3_SetBuff(client,bImmunityUltimates,thisRaceID,true);
		}
		else if(StrEqual(info,"Earth"))
		{
			SEFForm[client]=2;
			War3_SpawnPlayer(client);
			//EmitSoundToAll(ultimate_sound,client);
			War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
			War3_SetBuff(client,bImmunityUltimates,thisRaceID,true);
		}
		else if(StrEqual(info,"Fire"))
		{
			SEFForm[client]=3;
			War3_SpawnPlayer(client);
			//EmitSoundToAll(ultimate_sound,client);
			War3_SetBuff(client,bImmunityUltimates,thisRaceID,true);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		
		if(vteam!=ateam){
			new race_attacker=War3_GetRace(attacker);
			new race_victim=War3_GetRace(victim);
			
			if(race_attacker==thisRaceID){
				if(SEFForm[attacker]==0){
					new skill_brawl=War3_GetSkillLevel(attacker,thisRaceID,SKILL_BRAWL);
				
					if(skill_brawl){
						if(GetRandomFloat(0.0,1.0)<=0.1){
							War3_DamageModPercent(BrawlDmg[skill_brawl]);
							PrintHintText(attacker, "%T", "You deal extra damage", attacker);
						}
					}
				}
				if(SEFForm[attacker]==1){
					PrintHintText(victim, "%T", "You've been dispelled!", victim);
					War3_SetBuff(victim,bBuffDenyAll,thisRaceID,true);
					
					if(bInvis[attacker]){
						War3_DealDamage(victim,5,attacker,DMG_BULLET,"Windwalk");
						bInvis[attacker]=false;
						War3_SetBuff(attacker,fInvisibilitySkill,thisRaceID,1.0);
						War3_SetBuff(attacker,fMaxSpeed,thisRaceID,1.2);
					}
					
					if(!bCyclone[attacker]){
						bCyclone[attacker]=true;
						CreateTimer(5.0, cyclone, attacker);
						new Float:position[3];
					
						GetClientAbsOrigin(attacker, position);
						position[2]+=10;
						TE_SetupBeamRingPoint(position,0.0,200.0,BeamSprite,HaloSprite,0,15,0.3,20.0,3.0,{100,100,150,255},20,0);
						TE_SendToAll();
						GetClientAbsOrigin(attacker,position);
						TE_SetupBeamRingPoint(position, 20.0, 80.0,BeamSprite,BeamSprite, 0, 5, 2.6, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
						TE_SendToAll();
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 40.0, 100.0,BeamSprite,BeamSprite, 0, 5, 2.4, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
						TE_SendToAll();
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 60.0, 120.0,BeamSprite,BeamSprite, 0, 5, 2.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 80.0, 140.0,BeamSprite,BeamSprite, 0, 5, 2.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 100.0, 160.0,BeamSprite,BeamSprite, 0, 5, 1.8, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 120.0, 180.0,BeamSprite,BeamSprite, 0, 5, 1.6, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 140.0, 200.0,BeamSprite,BeamSprite, 0, 5, 1.4, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 160.0, 220.0,BeamSprite,BeamSprite, 0, 5, 1.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 180.0, 240.0,BeamSprite,BeamSprite, 0, 5, 1.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();
						for(new target=0;target<=MaxClients;target++){
							if(ValidPlayer(target,true)){
								new client_team=GetClientTeam(attacker);
								new target_team=GetClientTeam(target);
					
								if(target_team!=client_team){
									new Float:targetPos[3];
									new Float:clientPos[3];
								
									GetClientAbsOrigin(target, targetPos);
									GetClientAbsOrigin(attacker, clientPos);
									if(!W3HasImmunity(target,Immunity_Skills)){
										if(GetVectorDistance(targetPos,clientPos)<100.0){
											new Float:velocity[3];
									
											velocity[2]+=800.0;
											SetEntDataVector(target,m_vecBaseVelocity,velocity,true);									
											CreateTimer(0.1,Tornado1,target);
											CreateTimer(0.4,Tornado2,target);
										}	
									}	
								}	
							}			
						}
					}
				}
				if(SEFForm[attacker]==2){
					if(GetRandomFloat(0.0,1.0)<=0.2){
						PrintHintText(attacker, "%T", "You deal extra damage", attacker);
						War3_DealDamage(victim,4,attacker,DMG_BULLET,"Extra Damage");
					}
				}
			}
			if(race_victim==thisRaceID){
				if(SEFForm[victim]==0){
					new skill_brawl=War3_GetSkillLevel(victim,thisRaceID,SKILL_BRAWL);
				
					if(skill_brawl){
						if(GetRandomFloat(0.0,1.0)<=BrawlEvade[skill_brawl]){
							War3_DamageModPercent(0.0);
							PrintHintText(attacker, "%T", "evaded the attack", attacker);
							PrintToConsole(attacker, "Damage Reduced against Brewmaster - Brawler");
							PrintToConsole(victim, "Damage Reduced by Brewmaster - Brawler");
						}
					}
				}
				if(SEFForm[victim]==1){
					if(!bCyclone[victim]){
						bCyclone[victim]=true;
						CreateTimer(5.0, cyclone, victim);
						new Float:position[3];
					
						GetClientAbsOrigin(victim, position);
						position[2]+=10;
						TE_SetupBeamRingPoint(position,0.0,200.0,BeamSprite,HaloSprite,0,15,0.3,20.0,3.0,{100,100,150,255},20,0);
						TE_SendToAll();
						GetClientAbsOrigin(victim,position);
						TE_SetupBeamRingPoint(position, 20.0, 80.0,BeamSprite,BeamSprite, 0, 5, 2.6, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
						TE_SendToAll();
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 40.0, 100.0,BeamSprite,BeamSprite, 0, 5, 2.4, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
						TE_SendToAll();
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 60.0, 120.0,BeamSprite,BeamSprite, 0, 5, 2.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 80.0, 140.0,BeamSprite,BeamSprite, 0, 5, 2.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 100.0, 160.0,BeamSprite,BeamSprite, 0, 5, 1.8, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 120.0, 180.0,BeamSprite,BeamSprite, 0, 5, 1.6, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 140.0, 200.0,BeamSprite,BeamSprite, 0, 5, 1.4, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 160.0, 220.0,BeamSprite,BeamSprite, 0, 5, 1.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						position[2]+=20.0;
						TE_SetupBeamRingPoint(position, 180.0, 240.0,BeamSprite,BeamSprite, 0, 5, 1.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();
						for(new target=0;target<=MaxClients;target++){
							if(ValidPlayer(target,true)){
								new client_team=GetClientTeam(victim);
								new target_team=GetClientTeam(target);
					
								if(target_team!=client_team){
									new Float:targetPos[3];
									new Float:clientPos[3];
								
									GetClientAbsOrigin(target, targetPos);
									GetClientAbsOrigin(victim, clientPos);
									if(!W3HasImmunity(target,Immunity_Skills)){
										if(GetVectorDistance(targetPos,clientPos)<100.0){
											new Float:velocity[3];
									
											velocity[2]+=800.0;
											SetEntDataVector(target,m_vecBaseVelocity,velocity,true);									
											CreateTimer(0.1,Tornado1,target);
											CreateTimer(0.4,Tornado2,target);
										}	
									}	
								}	
							}			
						}
					}
				}
			}
			if(bDrunk[attacker])
			{
				if(GetRandomFloat(0.0,1.0)<=HazeDrunk[attacker])
				{
					PrintHintText(attacker,"%T","You are drunk and miss",attacker);
					War3_DamageModPercent(0.0);
					PrintToConsole(attacker, "Damage Reduced against Brewmaster - Drunk");
					PrintToConsole(victim, "Damage Reduced by Brewmaster - Drunk");
				}
			}
			if(bTaunt[victim]){
				War3_DamageModPercent(0.01);
				PrintToConsole(attacker, "Damage Reduced against Brewmaster - Taunt");
				PrintToConsole(victim, "Damage Reduced by Brewmaster - Taunt");
				War3_DealDamage(Tauntby[victim],20,attacker,DMG_BULLET,"Extra Damage");
			}
		}
	}
}

public Action:cyclone(Handle:timer,any:client)
{
	bCyclone[client]=false;
}

public Action:Tornado1(Handle:timer,any:client)
{
	new Float:velocity[3];
	
	velocity[2]+=4.0;
	velocity[0]-=600.0;
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}

public Action:Tornado2(Handle:timer,any:client)
{
	new Float:velocity[3];
	
	velocity[2]+=4.0;
	velocity[0]+=600.0;
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}

public Action:BoF(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++){
		if(ValidPlayer(client,true)){
			if(War3_GetRace(client)==thisRaceID){
				if(bBoF[client] && ValidPlayer(client,true)){
					new skill_ability=War3_GetSkillLevel(client,thisRaceID,SKILL_ABILITY);
					new target = War3_GetTargetInViewCone(client,500.0,false,20.0);
		
					if(target>0&&!W3HasImmunity(target,Immunity_Skills)&&!bBurned[target]){
						bBurned[target]=true;
						CreateTimer(5.0, disableBurned, target);
						War3_DealDamage(target,BoFDmg[skill_ability],client,DMG_ENERGYBEAM,"Breath of Fire");
						if(bDrunk[target]){
							IgniteEntity(target, 5.0);
						}						
					}
				}
			}
		}
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(!Silenced(client)){
		new skill_ability=War3_GetSkillLevel(client,thisRaceID,SKILL_ABILITY);
		
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_ABILITY,true)){
				if(skill_ability>0){
					if(SEFForm[client]==0){
						bBoF[client]=true;
						CreateTimer(5.0, disableBreath,client);
						//EmitSoundToAll(breath_sound,client);
						War3_CooldownMGR(client,10.0,thisRaceID,SKILL_ABILITY,_,_);
					}
					if(SEFForm[client]==1){
						PrintHintText(client, "%T", "You're now invisible", client);
						War3_CooldownMGR(client,15.0,thisRaceID,SKILL_ABILITY,_,_);
						CreateTimer(5.0, Visible, client);
						War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
						War3_SetBuff(client,fMaxSpeed,thisRaceID,1.4);
						bInvis[client]=true;
					}
					if(SEFForm[client]==2){
						for(new ally=1;ally<=MaxClients;ally++){
							if(ValidPlayer(ally)){
								new ally_team=GetClientTeam(ally);
								new client_team=GetClientTeam(client);
								if(IsPlayerAlive(ally) && ally_team==client_team && ally!=client){
									bTaunt[ally]=true;
									Tauntby[ally]=client;
									CreateTimer(2.0, Taunt, ally);
								}
							}
						}
					}
				}
				else
				{
					PrintHintText(client,"%T", "Level your BoF first",client);
				}
			}
		}
	}
}

public Action:Taunt(Handle:timer,any:client)
{
	bTaunt[client]=false;
}

public Action:Visible(Handle:timer,any:client)
{
	if (ValidPlayer(client)){
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.2);
		PrintHintText(client, "%T", "You're not invisible anymore!",client);
	}
}

public Action:disableBurned(Handle:timer,any:client)
{
	bBurned[client]=false;
}

public Action:disableBreath(Handle:timer,any:client)
{
	bBoF[client]=false;
}

public Action:Immolation(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++){
		if(ValidPlayer(client,true)){
			if(War3_GetRace(client)==thisRaceID){
				if(SEFForm[client]==3){
					new ownerteam=GetClientTeam(client);
					new Float:targetPos[3];
					new Float:clientPos[3];
					GetClientAbsOrigin(client,clientPos);							
					for (new target=1;target<=MaxClients;target++){
						if(ValidPlayer(target,true)&& GetClientTeam(target)!=ownerteam){
							GetClientAbsOrigin(target,targetPos);
							if(GetVectorDistance(clientPos,targetPos)<220.0){
								if(!W3HasImmunity(target,Immunity_Skills)){
									IgniteEntity(target, 1.0);
								}
							}
						}
					}
				}
			}
		}
	}
}