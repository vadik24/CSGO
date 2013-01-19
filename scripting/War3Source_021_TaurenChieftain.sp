 /**
* File: War3Source_TaurenChieftain.sp
* Description: The Orc Hero for War3Source.
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
new MyWeaponsOffset,Clip1Offset,AmmoOffset;
new Handle:RespawnDelayCvar;

//skill 1
new Float:ShockWaveChance[9]={0.0,0.30,0.32,0.34,0.36,0.38,0.40,0.42,0.44};

//skill 2
new Float:WarStompMaxDamage[]={0.0,0.85,0.8,0.75,0.7,0.65,0.6,0.55,0.5}; 
new Float:WarStompRadius=500.0;
new WarStompLoopCountdown[66];
new bool:HitOnForwardTide[66][66]; //[VICTIM][ATTACKER]
new Float:WarStompOrigin[66][3];
new Float:AbilityCooldownTime=10.0;
//skill 3
new bool:bEndurance[66];
new Float:EnduranceArr[9]={1.0,1.09,1.12,1.15,1.18,1.21,1.24,1.27,1.3};

//skill 4
new bool:bReincarnation[66] = {false, ...};
new Float:ReincarnationChance[9]={0.0,0.25,0.3,0.35,0.40,0.45,0.50,0.55,0.60};
new String:StompSnd[]="npc/ichthyosaur/attack_growl3.mp3";
new String:StompSnd2[]="weapons/mortar/mortar_explode1.mp3";

new SKILL_SHOCKWAVE, SKILL_WARSTOMP, SKILL_ENDURANCE, ULT_REINCARNATION;
new BeamSprite,FlameSprite, HaloSprite; 

public Plugin:myinfo = 
{
	name = "War3Source Race - Tauren Chieftain",
	author = "[Oddity]TeacherCreature",
	description = "The Taruen Cheiftain Hero for War3Source.",
	version = "1.0.0.0",
	url = "warcraft-source.net"
};

public OnPluginStart()
{
	HookEvent("player_death",PlayerDeathEvent);
	HookEvent("round_start",Event_RoundStart);
	MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
	Clip1Offset=FindSendPropOffs("CBaseCombatWeapon","m_iClip1");
	AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
	RespawnDelayCvar=CreateConVar("war3_taurenc_respawn_delay","4","How long before spawning for reincarnation?");
	
	LoadTranslations("w3s.race.taurenc.phrases");
}
public Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i =1;i<=MaxClients;i++)
	{
		bReincarnation[i] = false;
	}
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID){
		bEndurance[client]=false;
		W3ResetAllBuffRace(client,thisRaceID);
		W3ResetPlayerColor(client,thisRaceID);
	}
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==20)
	{
		thisRaceID=War3_CreateNewRaceT("taurenc");
		SKILL_SHOCKWAVE=War3_AddRaceSkillT(thisRaceID,"ShockWave",false,8);
		SKILL_WARSTOMP=War3_AddRaceSkillT(thisRaceID,"WarStomp",false,8);
		SKILL_ENDURANCE=War3_AddRaceSkillT(thisRaceID,"Endurance",false,8);
		ULT_REINCARNATION=War3_AddRaceSkillT(thisRaceID,"Reincarnation",true,8); 
		War3_CreateRaceEnd(thisRaceID);
	}
}
/*
public OnGameFrame()
{
	for(new i=1;i<=MaxClients;i++){
		if(War3_ValidPlayer(i,true))
		{
			if(War3_GetRace(i)==thisRaceID && bFlying[i]){
				War3_SetBuff(client,bFlyMode,thisRaceID,true);
			}
			if(War3_GetRace(i)==thisRaceID && !bFlying[i]){
				SetEntityMoveType(i,MOVETYPE_WALK);
			}
		}
	}
}*/

public OnMapStart()
{
	FlameSprite=PrecacheModel("sprites/fireburst.vmt");
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	//War3_PrecacheSound(StompSnd);
	//War3_PrecacheSound(StompSnd2);
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_WARSTOMP);
		if(skill_level>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_WARSTOMP,true))
			{
				if(!Silenced(client))
				{
					//EmitSoundToAll(StompSnd,client);
					GetClientAbsOrigin(client,WarStompOrigin[client]);
					WarStompOrigin[client][2]+=15.0;
					WarStompLoopCountdown[client]=20;
					
					for(new i=1;i<=MaxClients;i++){
						HitOnForwardTide[i][client]=false;
					}
					
					TE_SetupBeamRingPoint(WarStompOrigin[client], 1.0, 500.0, BeamSprite, HaloSprite, 0, 5, 1.0, 50.0, 1.0, {84,84,84,250}, 60, 0);
					TE_SendToAll();
					
					CreateTimer(0.1,BurnLoop,client); //damage
					CreateTimer(1.0,StompSound,client);
					War3_CooldownMGR(client,AbilityCooldownTime,thisRaceID,SKILL_WARSTOMP,_,_);
					PrintHintText(client,"%T","War Stomp",client);
				}
				else
				{
					PrintHintText(client,"%T","Silenced: can not cast",client);
				}
			}
		}
	}
}

public Action:StompSound(Handle:timer,any:client)
{
	//EmitSoundToAll(StompSnd2,client);
}

public Action:BurnLoop(Handle:timer,any:attacker)
{

	if(ValidPlayer(attacker) && WarStompLoopCountdown[attacker]>0)
	{
		new team = GetClientTeam(attacker);
		//War3_DealDamage(victim,damage,attacker,DMG_BURN);
		CreateTimer(0.1,BurnLoop,attacker);
		
		new Float:damagingRadius=(1.0-FloatAbs(float(WarStompLoopCountdown[attacker])-10.0)/10.0)*WarStompRadius;
		
		//PrintToChatAll("distance to damage %f",damagingRadius);
		
		WarStompLoopCountdown[attacker]--;
		
		new Float:otherVec[3];
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Skills))
			{
		
				if(HitOnForwardTide[i][attacker]==true){
					continue;
				}
					
					
				GetClientAbsOrigin(i,otherVec);
				otherVec[2]+=30.0;
				new Float:victimdistance=GetVectorDistance(WarStompOrigin[attacker],otherVec);
				if(victimdistance<WarStompRadius&&FloatAbs(otherVec[2]-WarStompOrigin[attacker][2])<50)
				{
					if(FloatAbs(victimdistance-damagingRadius)<(WarStompRadius/10.0))
					{
						
						HitOnForwardTide[i][attacker]=true;
						War3_DealDamage(i,RoundFloat(WarStompMaxDamage[War3_GetSkillLevel(attacker,thisRaceID,SKILL_WARSTOMP)]*victimdistance/WarStompRadius/2.0),attacker,DMG_ENERGYBEAM,"WarStomp");
						War3_SetBuff(i,bBashed,thisRaceID,true);
						CreateTimer(2.0,unbash,i);
						//War3_SetBuff(i,fSlow,thisRaceID,WarStompArr[War3_GetSkillLevel(attacker,thisRaceID,SKILL_WARSTOMP)]);
						PrintHintText(i,"%T","You were hit by War Stomp!",i);
					}
				}
			}
		}
	}
}

public Action:unbash(Handle:timer,any:client)
{
	War3_SetBuff(client,bBashed,thisRaceID,false);
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
			new skill_level_shockwave=War3_GetSkillLevel(attacker,thisRaceID,SKILL_SHOCKWAVE);
			// Liquid Fire
			if(race_attacker==thisRaceID && skill_level_shockwave>0 && !Silenced(attacker))
			{
				if(GetRandomFloat(0.0,1.0)<=ShockWaveChance[skill_level_shockwave] && !W3HasImmunity(victim,Immunity_Skills))
				{
					new Float:spos[3];
					new Float:epos[3];
					GetClientAbsOrigin(victim,epos);
					GetClientAbsOrigin(attacker,spos);
					epos[2]+=35;
					TE_SetupBeamPoints(spos, epos, FlameSprite, FlameSprite, 1, 5, 2.0, 50.0, 50.0, 2, 4.0, {255,80,20,255}, 30);
					TE_SendToAll();
					War3_ShakeScreen(victim,2.0,50.0,40.0);
					PrintToConsole(attacker,"%T","Shockwave",attacker);
					W3FlashScreen(victim,RGBA_COLOR_RED);
				}
			}
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_REINCARNATION);
		if(ult_level>0)		
		{
			PrintHintText(client,"%T","This Ultimate is Passive!",client);
		}	
		else
		{
			PrintHintText(client,"%T","Level Your Ultimate First",client);
		}
	}
}


public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new index=GetClientOfUserId(userid);
	if(index>0)
	{
		new race=War3_GetRace(index);
		if(race==thisRaceID&&!bReincarnation[index]&&War3_GetGame()!=Game_TF)
		{
			new skill=War3_GetSkillLevel(index,race,ULT_REINCARNATION);
			if(skill>0&&!Silenced(index))
			{
				
				if(War3_Chance(ReincarnationChance[skill]))
				{
					for(new slot=0;slot<10;slot++)
					{
						new ent=War3_CachedWeapon(index,slot);
						if(ent)
						{
							if(IsValidEdict(ent))
							{
								decl String:wepName[64];
								War3_CachedDeadWeaponName(index,slot,wepName,64);
								if(StrEqual(wepName,"weapon_c4") || StrEqual(wepName,"weapon_knife"))
								{
									continue; // don't think we need to delete these
								}
								UTIL_Remove(ent);
							}
						}
					}
					new Float:delay_spawn=GetConVarFloat(RespawnDelayCvar);
					if(delay_spawn<0.25)
						delay_spawn=0.25;
					CreateTimer(delay_spawn,RespawnPlayer,userid);
					PrintHintText(index,"%T","REINCARNATION IN {amount} SECONDS!",index,delay_spawn);
					
				}
			}
		}
	}
}

public Action:RespawnPlayer(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(client>0&&!IsPlayerAlive(client))
	{
		War3_SpawnPlayer(client);
		new Float:pos[3];
		new Float:ang[3];
		War3_CachedAngle(client,ang);
		War3_CachedPosition(client,pos);
		TeleportEntity(client,pos,ang,NULL_VECTOR);
		// cool, now remove their weapons besides knife and c4 
		for(new slot=0;slot<10;slot++)
		{
			new ent=GetEntDataEnt2(client,MyWeaponsOffset+(slot*4));
			if(ent>0 && IsValidEdict(ent))
			{
				new String:ename[64];
				GetEdictClassname(ent,ename,64);
				if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
				{
					continue; // don't think we need to delete these
				}
				UTIL_Remove(ent);
			}
		}
		// restore iAmmo
		for(new ammotype=0;ammotype<32;ammotype++)
		{
			SetEntData(client,AmmoOffset+(ammotype*4),War3_CachedDeadAmmo(client,ammotype),4);
		}
		// give them their weapons
		for(new slot=0;slot<10;slot++)
		{
			new String:wep_check[64];
			War3_CachedDeadWeaponName(client,slot,wep_check,64);
			if(!StrEqual(wep_check,"") && !StrEqual(wep_check,"",false) && !StrEqual(wep_check,"weapon_c4") && !StrEqual(wep_check,"weapon_knife"))
			{
				new wep_ent=GivePlayerItem(client,wep_check);
				if(wep_ent>0) //too bad you get full clip
				{
					SetEntData(wep_ent,Clip1Offset,War3_CachedDeadClip1(client,slot),4);
				}
			}
		}
		bReincarnation[client]=true;
		War3_ChatMessage(client,"%T","Reincarnated",client);
	}
	else{
		//gone or respawned via some other race/item
		bReincarnation[client]=false;
	}
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		InitPassiveSkills(client);
		bEndurance[client]=false;
	}
}

public InitPassiveSkills(client){
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllev=War3_GetSkillLevel(client,thisRaceID,SKILL_ENDURANCE);
		if(skilllev)
		{
			new Float:speed=EnduranceArr[skilllev];
			War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
		}
	}
}