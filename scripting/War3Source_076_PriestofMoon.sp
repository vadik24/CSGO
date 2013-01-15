/**
* File: War3Source_PriestessOfTheMoon.sp
* Description: The Priestess Of The Moon race for War3Source.
* Author(s): Cereal Killer + Anthony Iacono 
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>
new thisRaceID;
new Float:TrueshotDamagePercent[5]={0.0,0.15,0.20,0.25,0.30};
new Float:HideAlpha[5]={1.0,0.8,0.7,0.6,0.5};
new Float:HideAlphaC[5]={1.0,0.5,0.40,0.30,0.20};
new MoneyOffsetCS;
new BurnChance[5]={11,9,8,7,6};
new Float:BurnTime[5]={0.0,2.0,3.0,4.0,5.0};
new BurnDamage[5]={0,1,2,3,4};
new Float:scoutcooldown[5]={50.0,10.0,9.0,8.0,7.0};
new playerisbeingburned[MAXPLAYERS];
new Float:starfallstar[MAXPLAYERS][3];
new Float:StarFallCoolDown[5]={100.0,25.0,20.0,15.0,10.0};
new starfallbool[MAXPLAYERS];
new BeamSprite,HaloSprite;
new StarSprite,TSprite,CTSprite,BurnSprite,g_iExplosionModel,g_iSmokeModel;
//new String:incoming[]="npc/env_headcrabcanister/incoming.mp3";
//new String:boom[]="npc/env_headcrabcanister/explosion.mp3";

public OnWar3EventSpawn(client){
	playerisbeingburned[client]=0;
	if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID){
		GivePlayerItem(client, "weapon_usp");
	}
}
public Plugin:myinfo = 
{
	name = "War3Source Race - Priestess Of The Moon",
	author = "Cereal Killer",
	description = "The Priestess Of The Moon for War3Source.",
	version = "1.0.6.3",
	url = "http://warcraft-source.net/"
};
new SKILL_HIDE, SKILL_SCOUT, SKILL_SEARING, SKILL_TRUESHOT, ULT_STARFALL;
public OnPluginStart()
{
	HookEvent("weapon_fire", WeaponFire);
	MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
	CreateTimer(0.01,loop11,_,TIMER_REPEAT);
}
public OnMapStart()
{
	////War3_PrecacheSound(incoming);
	////War3_PrecacheSound(boom);
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	StarSprite=PrecacheModel("materials/effects/fluttercore.vmt");
	TSprite=PrecacheModel("VGUI/gfx/VGUI/guerilla.vmt");
	CTSprite=PrecacheModel("VGUI/gfx/VGUI/gign.vmt");
	BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
	g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
	g_iSmokeModel     = PrecacheModel("materials/effects/fire_cloud2.vmt");
	
}
public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==150)
	{
		thisRaceID=War3_CreateNewRace("VIP Priestess of the Moon","moon");
		SKILL_HIDE=War3_AddRaceSkill(thisRaceID,"secrecy","Invisibility, greater invisibility, if you sit down",false,4);
		SKILL_SCOUT=War3_AddRaceSkill(thisRaceID,"scout","[+ability] Detects all enemies",false,4);
		SKILL_SEARING=War3_AddRaceSkill(thisRaceID,"Discounted Arrows","Your bullets can set fire to enemy",false,4);
		SKILL_TRUESHOT=War3_AddRaceSkill(thisRaceID,"Aura Marksmanship","Your attacks inflict more damage",false,4);
		ULT_STARFALL=War3_AddRaceSkill(thisRaceID,"Starfall","The sky is falling meteorite and causing damage to nearby enemies",true,4);
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
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_usp");
		if(ValidPlayer(client,true)){
			GivePlayerItem(client, "weapon_usp");
		}
	}
}
public Action:WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new index=GetClientOfUserId(userid);
	if(index>0)
	{
		if(War3_GetRace(index)==thisRaceID)
		{
			new skill=War3_GetSkillLevel(index,thisRaceID,SKILL_SEARING);
			if(skill>0)
			{
				new money=GetMoney(index);
				if(money>100)
				{
					SetMoney(index,money-100);
					new Float:pos[3];
					GetClientAbsOrigin(index,pos);
					pos[2]+=30;
					new target = War3_GetTargetInViewCone(index,9999.0,false,5.0);
					if(target>0)
					{
						new Float:targpos[3];
						GetClientAbsOrigin(target,targpos);
						TE_SetupBeamPoints(pos, targpos, BurnSprite, BurnSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {255,255,255,255}, 70); 
						TE_SendToAll();
						IgniteEntity(target,BurnTime[skill]);
						targpos[2]+=50;
						TE_SetupGlowSprite(targpos,BurnSprite,1.0,1.9,255);
						TE_SendToAll();
						PrintHintText(target,"You set fire flaming arrows!");
						//sprites/640_logo.vmt server_var(wcs_x1) server_var(wcs_y1) server_var(wcs_z1) server_var(wcs_x2) server_var(wcs_y2) server_var(wcs_z2) 1 2 2 255 225 255 255
					}
					else
					{
						new Float:targpos[3];
						War3_GetAimEndPoint(index,targpos);
						TE_SetupBeamPoints(pos, targpos, BurnSprite, BurnSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {255,255,255,255}, 70); 
						TE_SendToAll();
						targpos[2]+=50;
						TE_SetupGlowSprite(targpos,BurnSprite,1.0,1.9,255);
						TE_SendToAll();
					}
				}
			}
		}
	}
}
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new skill_level_trueshot=War3_GetSkillLevel(attacker,thisRaceID,SKILL_TRUESHOT);
			if(race_attacker==thisRaceID && skill_level_trueshot>0 && IsPlayerAlive(attacker))
			{
				if(GetRandomFloat(0.0,1.0)<0.3&&!W3HasImmunity(victim,Immunity_Skills))
				{  
					War3_DamageModPercent(TrueshotDamagePercent[skill_level_trueshot]+1.0);   
					W3FlashScreen(victim,RGBA_COLOR_RED);
					PrintHintText(attacker,"accuracy!");
					PrintHintText(victim,"As you hit best shot!");
				}
			}
			new skill_level_searing=War3_GetSkillLevel(attacker,thisRaceID,SKILL_SEARING);
			if(race_attacker==thisRaceID && skill_level_searing>0 && IsPlayerAlive(attacker))
			{
				if(RoundFloat(GetRandomFloat(0.0,1.0)*10)>BurnChance[skill_level_searing]){
					if(!W3HasImmunity(victim,Immunity_Skills))
					{  
						new Float:position[3];
						War3_CachedPosition(victim,position);
						position[2]+=35;
						TE_SetupGlowSprite(position,BurnSprite,1.5,0.6,200);
						TE_SendToAll();
						War3_SetBuff(victim,fMaxSpeed,thisRaceID,0.0);
						CreateTimer(2.0,BurnLoop,GetClientUserId(victim));
						CreateTimer(4.0,BurnLoop,GetClientUserId(victim));
						CreateTimer(6.0,BurnLoop,GetClientUserId(victim));
						CreateTimer(8.0,BurnLoop,GetClientUserId(victim));
						CreateTimer(10.0,BurnLoop,GetClientUserId(victim));
						CreateTimer(12.0,BurnLoop,GetClientUserId(victim));
						CreateTimer(14.0,BurnLoop,GetClientUserId(victim));
						playerisbeingburned[victim]=1;
					}
				}
			}
		}
	}
}
stock GetMoney(player)
{
	return GetEntData(player,MoneyOffsetCS);
}

stock SetMoney(player,money)
{
	SetEntData(player,MoneyOffsetCS,money);
}
public Action:BurnLoop(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++){
		if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID){
			new victim=GetClientOfUserId(userid);
			new attacker=client;
			new skill_level_searing=War3_GetSkillLevel(attacker,thisRaceID,SKILL_SEARING);
			if(ValidPlayer(victim)&&IsPlayerAlive(victim)){
				if(playerisbeingburned[victim]==1){
					new Float:position[3];
					War3_CachedPosition(victim,position);
					position[2]+=35;
					TE_SetupGlowSprite(position,BurnSprite,1.5,0.6,200);
					TE_SendToAll();
					War3_DealDamage(victim,BurnDamage[skill_level_searing],attacker,DMG_BURN,"searingArrows",_,W3DMGTYPE_MAGIC);
				}
			}
		}
	}
}
public OnUltimateCommand(client,race,bool:pressed){
	if(race==thisRaceID && IsPlayerAlive(client) && pressed){
		new skill_level=War3_GetSkillLevel(client,race,ULT_STARFALL);
		if(skill_level>0){
			if(!Silenced(client)){
				if(War3_SkillNotInCooldown(client,thisRaceID,ULT_STARFALL,false)){
					War3_CooldownMGR(client,StarFallCoolDown[skill_level],thisRaceID,ULT_STARFALL,_,_);
					new Float:position[3];
					War3_GetAimEndPoint(client,position);
					position[0]+=50;
					position[1]+=50;
					position[2]+=400;
					starfallstar[client][0]=position[0];
					starfallstar[client][1]=position[1];
					starfallstar[client][2]=position[2];
					starfallbool[client]=1;
					CreateTimer(0.6, StarExplode);
					//CreateTimer(1.0, StarExplode);
					//CreateTimer(1.5, StarExplode);
					CreateTimer(0.8, BoomSound,client);
					PrintHintText(client,"Starfall!");
				}
			}
		}
	}
}
public Action:loop11(Handle:timer,any:a){
	for(new client=1;client<=MaxClients;client++){
		if(ValidPlayer(client,true) &&War3_GetRace(client)==thisRaceID){
			new skill_level_hide=War3_GetSkillLevel(client,thisRaceID,SKILL_HIDE);
			new Float:alpha=HideAlpha[skill_level_hide];
			new Float:alphaC=HideAlphaC[skill_level_hide];
			if(skill_level_hide>0&&IsPlayerAlive(client)){
				if(War3_CachedDucking(client)==false){
					War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
				}
				if(War3_CachedDucking(client)==true){
					War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alphaC);
				}
			}
			if(starfallbool[client]==1){
				TE_SetupGlowSprite(starfallstar[client],StarSprite,0.25,1.2,100);
				TE_SendToAll();
				starfallstar[client][0]-=8;
				starfallstar[client][1]-=8;
				starfallstar[client][2]-=64;
			}
		}
	}
}
public Action:BoomSound(Handle:timer,any:client){
	//EmitSoundToAll(boom,client);
}
public Action:StarExplode(Handle:timer,any:a){
	for(new client=1;client<=MaxClients;client++){
		if(ValidPlayer(client,true) &&War3_GetRace(client)==thisRaceID){
			TE_SetupExplosion(starfallstar[client], g_iExplosionModel, 10.0, 10, TE_EXPLFLAG_NONE, 200, 255);
			TE_SendToAll();
			TE_SetupSmoke(starfallstar[client],     g_iExplosionModel, 50.0, 2);
			TE_SendToAll();
			TE_SetupSmoke(starfallstar[client],     g_iSmokeModel,     50.0, 2);
			TE_SendToAll();
			TE_SetupBeamRingPoint(starfallstar[client],0.0,400.0,BeamSprite,HaloSprite,0,15,0.8,10.0,6.0,{255,10,0,255},10,0);
			TE_SendToAll(); 
			starfallbool[client]=0;
			//EmitSoundToAll(incoming,client);
			for (new i=1;i<=MaxClients;i++){
				new ownerteam=GetClientTeam(client);	
				if(ValidPlayer(i,true)&& GetClientTeam(i)!=ownerteam ){
					new Float:VictimPos[3];
					GetClientAbsOrigin(i,VictimPos);
					if(GetVectorDistance(starfallstar[client],VictimPos)<250){
						//EmitSoundToAll(incoming,i);
						if(!W3HasImmunity(i,Immunity_Skills)){
							War3_DealDamage(i,50,client,DMG_CRUSH,"Falling Star",_,W3DMGTYPE_MAGIC);
							PrintHintText(i,"Starfall: 50 damage!");
						}
					}
				}
			}
		}
	}
}


public OnAbilityCommand(client,ability,bool:pressed){
	if (ability==0){
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_SCOUT);
			if(skill_level>0){
				if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_SCOUT,false)){
					War3_CooldownMGR(client,scoutcooldown[skill_level],thisRaceID,SKILL_SCOUT,_,_);
					for (new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true)&&IsPlayerAlive(i)){
							new Float:position[3];
							War3_CachedPosition(i,position);
							position[2]+=60;
							if(GetClientTeam(client)==2)
							{							
								if(GetClientTeam(i)==3){
									TE_SetupGlowSprite(position,CTSprite,2.0,0.3,200);
									TE_SendToClient(client,0.0);
								}
							}
							if(GetClientTeam(client)==3)
							{
								if(GetClientTeam(i)==2){
									TE_SetupGlowSprite(position,TSprite,2.0,0.3,200);
									TE_SendToClient(client,0.0);
								}
							}
						}
					}
				}
			}
		}
	}
}