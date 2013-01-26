
/**
 * 
 * Description:   FlyingMachine from WoW
 * Author(s): [Oddity]TeacherCreature
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>


//#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

new thisRaceID;

new SKILL_MITHRIL, SKILL_BOMBS, SKILL_FLAK, ULT_TURBO;

new mith[]={0,120,140,160,180,200,220,240,260,280,300};

new flak[]={0,5,6,7,8,9,10,11,12,13,14};

new String:missilesnd[]="weapons/mortar/mortar_explode2.mp3";
new BeamSprite2;
new Float:MissileMaxDistance[]={0.00,1000.0,2000.0,3000.0,4000.0,5000.0,6000.0,7000.0,8000.0,9000.0,10000.0};
new bool:bIsBashed[66];

new m_vecVelocity_0, m_vecVelocity_1,m_vecVelocity_2, m_vecBaseVelocity; //offsets

new String:StartSound[]="vehicles/v8/v8_start_loop1.mp3";
new String:LoopSound[]="music/npc/attack_helicopter/aheli_rotor_loop1.mp3";
new String:SpinSound[]="ambient/machines/spindown.mp3";
new String:DeadSound[]="ambient/materials/cartrap_explode_impact1.mp3";

new Float:cooldown[]={0.0,10.0,9.0,8.0,7.0,6.0,5.0,4.0,3.0,2.0,1.0};
// Effects
new BeamSprite,HaloSprite,BurnSprite; 

public Plugin:myinfo = 
{
	name = "War3Source Race - Flying Machine",
	author = "[Oddity]TeacherCreature",
	description = "The Flying Machine race for War3Source.",
	version = "1.6",
	url = "warcraft-source.net"
};

public OnPluginStart()
{
	m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecVelocity_2 = FindSendPropOffs("CBasePlayer","m_vecVelocity[2]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	HookEvent("weapon_fire", WeaponFire);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==390)
	{
		thisRaceID=War3_CreateNewRace("Flying Machine","flymac");
		SKILL_MITHRIL=War3_AddRaceSkill(thisRaceID,"Kevlar"," Armor Kevlar reduces the damage done",false,10);
		SKILL_BOMBS=War3_AddRaceSkill(thisRaceID,"Rockets","You can fire 2 rockets (+ ability)",false,10);
		SKILL_FLAK=War3_AddRaceSkill(thisRaceID,"Cannon","The gun does more damage",false,10);
		ULT_TURBO=War3_AddRaceSkill(thisRaceID,"Jet thrust"," Increases the speed of movement in any direction",true,10); 
		War3_CreateRaceEnd(thisRaceID);
	}
}


public OnMapStart()
{
	BeamSprite2=PrecacheModel("sprites/physbeam.vmt");
	////War3_PrecacheSound(missilesnd);
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	BurnSprite=PrecacheModel("materials/effects/fire_could1.vmt");
	//PrecacheModel("models/player/techknow/apache/apache-ct.mdl", true);
	//PrecacheModel("models/player/techknow/apache/apache-t.mdl", true);
	////War3_PrecacheSound(StartSound);
	////War3_PrecacheSound(LoopSound);
	////War3_PrecacheSound(SpinSound);
	////War3_PrecacheSound(DeadSound);
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID){
		W3ResetAllBuffRace(client,thisRaceID);
		War3_WeaponRestrictTo(client,thisRaceID,"");
	}
	if(newrace==thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_m249");
		if(ValidPlayer(client,true))
		{
			/*new ClientTeam = GetClientTeam(client);
			switch(ClientTeam)
			{
				case 3:
					SetEntityModel(client, "models/player/techknow/apache/apache-ct.mdl");
				case 2:
					SetEntityModel(client, "models/player/techknow/apache/apache-t.mdl");
			}
			*/
			War3_SetBuff(client,bFlyMode,thisRaceID,true);
			GivePlayerItem(client,"weapon_m249");
			//EmitSoundToAll(StartSound,client,SNDCHAN_AUTO);
			CreateTimer(2.0,StartEnd,client);
		}
	}
}

public Action:UnfreezePlayer(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(client>0)
	{
		//PrintHintText(client,"NO LONGER BASHED");
		War3_SetBuff(client,bBashed,thisRaceID,false);
		SetEntityMoveType(client,MOVETYPE_WALK);
		bIsBashed[client]=false;
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(!Silenced(client))
	{
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
		{
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_BOMBS);
			if(skill_level>0)
			{
				
				if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_BOMBS,true))
				{
					new Float:origin[3];
					new Float:targetpos[3];
					War3_GetAimEndPoint(client,targetpos);
					GetClientAbsOrigin(client,origin);
					origin[2]+=30;
					origin[1]+=20;
					TE_SetupBeamPoints(origin, targetpos, BeamSprite2, BeamSprite2, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {255,128,35,255}, 70);  
					TE_SendToAll();
					origin[1]-=40;
					TE_SetupBeamPoints(origin, targetpos, BeamSprite2, BeamSprite2, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {255,128,35,255}, 70);  
					TE_SendToAll();
					//EmitSoundToAll(missilesnd,client);
					War3_CooldownMGR(client,3.0,thisRaceID,SKILL_BOMBS,_,_);
					new target = War3_GetTargetInViewCone(client,MissileMaxDistance[skill_level],false,5.0);
					if(target>0 && !W3HasImmunity(target,Immunity_Skills))
					{
						War3_DealDamage(target,20,client,_,"Bombs",W3DMGORIGIN_SKILL,W3DMGTYPE_TRUEDMG);
						IgniteEntity(target,3.0);
						War3_SetBuff(target,bBashed,thisRaceID,true);
						W3FlashScreen(target,RGBA_COLOR_RED, 0.3, 0.4, FFADE_OUT);
						CreateTimer(1.5,UnfreezePlayer,GetClientUserId(target));
						bIsBashed[target]=true;
						
					}
				}
			}
		}
	}
}
		
public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		War3_SetBuff(client,bFlyMode,thisRaceID,true);
		GivePlayerItem(client,"weapon_m249");
		//EmitSoundToAll(StartSound,client,SNDCHAN_AUTO);
		CreateTimer(2.0,StartEnd,client);
		/*
		new ClientTeam = GetClientTeam(client);
		switch(ClientTeam)
		{
			case 3:
				SetEntityModel(client, "models/player/techknow/apache/apache-ct.mdl");
			case 2:
				SetEntityModel(client, "models/player/techknow/apache/apache-t.mdl");
		}
		*/
		new mith_level=War3_GetSkillLevel(client,thisRaceID,SKILL_MITHRIL);
		if(mith_level>0)
		{
			SetEntProp(client,Prop_Send,"m_ArmorValue",mith[mith_level]); //give full armor
		}
	}
}

public Action:StartEnd(Handle:timer,any:client)
{
	StopSound(client, SNDCHAN_AUTO,StartSound);
	CreateTimer(0.5,LoopStart,client);
}

public Action:LoopStart(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		//EmitSoundToAll(LoopSound,client,SNDCHAN_AUTO);
	}
}

public Action:LoopEnd(Handle:timer,any:client)
{
	StopSound(client, SNDCHAN_AUTO,LoopSound);
}

public Action:SoundCheck(Handle:timer,any:client)
{
	//EmitSoundToAll(SpinSound,client);
	if(ValidPlayer(client,true))
	{
		CreateTimer(0.5,LoopStart,client);
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
			new race_victim=War3_GetRace(victim);
			if(race_victim==thisRaceID&&IsPlayerAlive(victim))
			{
				War3_ShakeScreen(victim,0.5,30.0,20.0);
				CreateTimer(0.1,LoopEnd,victim);
				//EmitSoundToAll(SpinSound,victim);
				CreateTimer(0.8, SoundCheck, victim);
			}
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
			new Float:pos[3];
			GetClientAbsOrigin(index,pos);
			pos[2]+=30;
			new target = War3_GetTargetInViewCone(index,9999.0,false,5.0);
			if(target>0)
			{
				new Float:targpos[3];
				GetClientAbsOrigin(target,targpos);
				targpos[1]-=40;
				TE_SetupBeamPoints(pos, targpos, BeamSprite, HaloSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {50,50,50,255}, 70); 
				TE_SendToAll();
				targpos[1]+=80;
				TE_SetupBeamPoints(pos, targpos, BeamSprite, HaloSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {50,50,50,255}, 70); 
				TE_SendToAll();
				new flak_level=War3_GetSkillLevel(target,thisRaceID,SKILL_FLAK);
				War3_DealDamage(target,flak[flak_level],index,_,"Bombs",W3DMGORIGIN_SKILL,W3DMGTYPE_TRUEDMG);
				targpos[1]-=40;
				targpos[2]+=50;
				TE_SetupGlowSprite(targpos,BurnSprite,0.5,0.2,255);
				TE_SendToAll();
				//PrintHintText(target,"Burned by a searing arrow!");
				//sprites/640_logo.vmt server_var(wcs_x1) server_var(wcs_y1) server_var(wcs_z1) server_var(wcs_x2) server_var(wcs_y2) server_var(wcs_z2) 1 2 2 255 225 255 255
			}
			else
			{
				new Float:targpos[3];
				War3_GetAimEndPoint(index,targpos);
				targpos[1]+=40;
				TE_SetupBeamPoints(pos, targpos, BeamSprite, HaloSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {50,50,50,255}, 70); 
				TE_SendToAll();
				targpos[2]+=50;
				TE_SetupGlowSprite(targpos,BurnSprite,0.5,0.2,255);
				TE_SendToAll();
				targpos[2]-=50;
				targpos[1]-=80;
				TE_SetupBeamPoints(pos, targpos, BeamSprite, HaloSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {50,50,50,255}, 70); 
				TE_SendToAll();
				targpos[2]+=50;
				TE_SetupGlowSprite(targpos,BurnSprite,0.5,0.2,255);
				TE_SendToAll();
			}
		}
	}
}


public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true)&&pressed && race==thisRaceID)
	{
		new skill=War3_GetSkillLevel(client,race,ULT_TURBO);
		if (skill>0)
		{
			if (War3_SkillNotInCooldown(client,thisRaceID,ULT_TURBO,true))
			{
				new Float:velocity[3]={0.0,0.0,0.0};
				velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
				velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
				velocity[2]= GetEntDataFloat(client,m_vecVelocity_2);
				velocity[0]*=float(skill)*0.25;
				velocity[1]*=float(skill)*0.25;
				velocity[2]*=float(skill)*0.25;				
				//new Float:len=GetVectorLength(velocity,false);
				//if(len>100.0){
				//	velocity[0]*=100.0/len;
				//	velocity[1]*=100.0/len;
				//}
				//PrintToChatAll("speed vector length %f cd %d",len,War3_SkillNotInCooldown(client,thisRaceID,SKILL_ASSAULT)?0:1);
				/*len=GetVectorLength(velocity,false);
				PrintToChatAll("speed vector length %f",len);
				*/
				
				SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
				War3_CooldownMGR(client,cooldown[skill],thisRaceID,ULT_TURBO,_,false);
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}
