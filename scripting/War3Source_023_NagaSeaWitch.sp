 /**
* File: War3Source_NagaSeaWitch.sp
* Description: The Naga Sea Witch unit for War3Source.
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

//new Handle:ultCooldownCvar;

//skill 1
new String:lightningSound[]="music/war3source/lightningbolt.mp3";
new bool:bForked[66];
new ForkedDamage[9]={0, 11, 13, 15, 17, 19, 21, 23, 25};

//skill 2
new Float:FrostArrow[9]={0.00,0.70,0.65,0.60,0.55,0.50,0.45,0.40,0.35};

//skill 3
new ShieldSprite;
new bool:bMShield[66];
new MoneyOffsetCS;
new String:Cast[]="music/war3source/manashield/cast.mp3";
new String:Imp1[]="music/war3source/manashield/impact_1.mp3";
new String:Imp2[]="music/war3source/manashield/impact_2.mp3";
new String:Imp3[]="music/war3source/manashield/impact_3.mp3";
new String:State[]="music/war3source/manashield/state.mp3";
new String:Exp[]="music/war3source/manashield/state_expire.mp3";
new MSmultiplier[9]={0,100,95,90,85,80,75,70,65};
new Float:MSreducer[9]={0.0,0.80, 0.70, 0.60, 0.50, 0.40, 0.30, 0.20, 0.10};

//skill 4
new m_vecBaseVelocity; //offsets
new TornadoSprite;
new String:Tornado[]="HL1/ambience/des_wind2.mp3";
new Float:Cooldown[9]={0.0, 30.0, 29.0, 28.0, 27.0, 26.0, 25.0, 24.0, 23.0};

new SKILL_FORKED, SKILL_FROSTARROW, SKILL_MANASHIELD, ULT_TORNADO;

public Plugin:myinfo = 
{
	name = "War3Source Race - Naga Sea Witch",
	author = "[Oddity]TeacherCreature",
	description = "The Naga Sea Witch race for War3Source.",
	version = "1.0.6.3",
	url = "warcraft-source.net"
}

public OnPluginStart()
{
	CreateTimer(1.0,mana,_,TIMER_REPEAT);
	HookEvent("round_start",RoundStartEvent);
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
	//ultCooldownCvar=CreateConVar("war3_naga_tornado_cooldown","30.0","Cooldown for Tornado");
	
	LoadTranslations("w3s.race.naga.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==38)
	{
		thisRaceID=War3_CreateNewRaceT("naga");
		SKILL_FORKED=War3_AddRaceSkillT(thisRaceID,"ForkedLightning",false,8);
		SKILL_FROSTARROW=War3_AddRaceSkillT(thisRaceID,"FrostArrows",false,8);
		SKILL_MANASHIELD=War3_AddRaceSkillT(thisRaceID,"ManaShield",false,8);
		ULT_TORNADO=War3_AddRaceSkillT(thisRaceID,"Tornado",true,8); 
		War3_CreateRaceEnd(thisRaceID);
	}
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
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_ssg08");
		if(ValidPlayer(client,true))
		{
			GivePlayerItem(client, "weapon_ssg08");
			GivePlayerItem(client, "weapon_smokegrenade");
		}
	}
}

public OnMapStart()
{
	ShieldSprite=PrecacheModel("vgui/gfx/vgui/shield.vmt");
	TornadoSprite==War3_PrecacheBeamSprite();
	////War3_PrecacheSound(Tornado);
	////War3_PrecacheSound(lightningSound);
	////War3_PrecacheSound(Cast);
	////War3_PrecacheSound(Imp1);
	////War3_PrecacheSound(Imp2);
	////War3_PrecacheSound(Imp3);
	////War3_PrecacheSound(State);
	////War3_PrecacheSound(Exp);
}

public OnWar3EventDeath(victim,attacker)
{
	new race=War3_GetRace(victim);
	if(race==thisRaceID)
	{
		SetMoney(victim,0);
	}
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		GivePlayerItem(client, "weapon_ssg08");
		GivePlayerItem(client, "weapon_smokegrenade");
	}
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i)&&War3_GetRace(i)==thisRaceID)
		{
			new skill=War3_GetSkillLevel(i,thisRaceID,SKILL_MANASHIELD);
			if(skill>0)
			{
				bMShield[i]=false;
			}
		}
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
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_FROSTARROW);
			// Frost Arrow
			if(race_attacker==thisRaceID && skill_level>0 && !Silenced(attacker))
			{
				if(!Silenced(attacker)&&War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_FROSTARROW) && !W3HasImmunity(victim,Immunity_Skills))
				{
					War3_CooldownMGR(attacker,5.0,thisRaceID,SKILL_FROSTARROW,_,_);
					War3_SetBuff(victim,fSlow,thisRaceID,FrostArrow[skill_level]);
					War3_SetBuff(victim,fAttackSpeed,thisRaceID,FrostArrow[skill_level]);
					W3FlashScreen(victim,RGBA_COLOR_RED);
					CreateTimer(1.5,unfrost,victim);
					PrintHintText(attacker,"%T","Frost Arrow!",attacker);
					PrintHintText(victim,"%T","You have been hit by a Frost Arrow",victim);
				}
			}
		}
	}
}

public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_victim=War3_GetRace(victim);
			if(race_victim==thisRaceID && bMShield[victim])
			{
				if(GetRandomInt(1,3)==1)
				{
					//W3EmitSoundToAll(Imp1,attacker);
					//W3EmitSoundToAll(Imp1,victim);
				}
				if(GetRandomInt(1,3)==2)
				{
					//W3EmitSoundToAll(Imp2,attacker);
					//W3EmitSoundToAll(Imp2,victim);
				}
				if(GetRandomInt(1,3)==3)
				{
					//W3EmitSoundToAll(.mp3,attacker);
					//W3EmitSoundToAll(.mp3,victim);
				}				
				new Float:pos[3];
				GetClientAbsOrigin(victim,pos);
				pos[2]+=35;
				TE_SetupGlowSprite(pos, ShieldSprite, 0.1, 1.0, 130);
				TE_SendToAll(); 
				new skill_mana=War3_GetSkillLevel(victim,thisRaceID,SKILL_MANASHIELD);
				new money=GetMoney(victim);
				new ddamage=RoundFloat(damage*MSmultiplier[skill_mana]);
				if(money>=ddamage)
				{
					War3_DamageModPercent(0.0);
					new new_money;
					new_money=money-ddamage;
					SetMoney(victim,new_money);
				}
				else
				{
					StopSound(victim, SNDCHAN_AUTO,State);
					//W3EmitSoundToAll(Exp,victim);
					War3_DamageModPercent(MSreducer[skill_mana]);
					bMShield[victim]=false;
					PrintHintText(victim,"%T","Mana Shield: Depleted!",victim);
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

public Action:unfrost(Handle:timer,any:client)
{
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
}

public bool:TargetCheck(client)
{
	if(bForked[client]||W3HasImmunity(client,Immunity_Skills))
	{
		return false;
	}
	return true;
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(!Silenced(client))
	{
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
		{
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_FORKED);
			if(skill_level>0)
			{
				if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_FORKED,true))
				{
					new targets;
					new targetlist[3];
					for(new i=0;i<3;i++){
						new target = War3_GetTargetInViewCone(client,800.0,false,23.0,TargetCheck);
						new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_FORKED);
						if(target>0&&!W3HasImmunity(target,Immunity_Skills))
						{
							bForked[target]=true;
							new Float:start_pos[3];
							GetClientAbsOrigin(client,start_pos);
							War3_DealDamage(target,ForkedDamage[skill],client,DMG_ENERGYBEAM,"chainlightning");
							PrintHintText(target,"%T","Hit by Forked Lightning -{amount} HP",target,War3_GetWar3DamageDealt());
							start_pos[2]+=30.0; // offset for effect
							new Float:target_pos[3];
							GetClientAbsOrigin(target,target_pos);
							target_pos[2]+=30.0;
							TE_SetupBeamPoints(start_pos,target_pos,TornadoSprite,TornadoSprite,0,35,1.0,40.0,40.0,0,40.0,{255,100,255,255},40);
							TE_SendToAll();
							//W3EmitSoundToAll( lightningSound , target,_,SNDLEVEL_TRAIN);
							War3_CooldownMGR(client,11.0,thisRaceID,SKILL_FORKED,_,_);
							targetlist[targets]=target;
							targets++;
						}
					}
					if(targets==0){
						PrintHintText(client,"%T","NO VALID TARGETS WITHIN {amount} FEET",client,80.0);
					}
					for(new i=0;i<3;i++){
						bForked[targetlist[i]]=false;
					}
				}
			}
			else
			{
				PrintHintText(client,"%T","Level Forked Lightning First",client);
			}
		}
		if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client))
		{	
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_MANASHIELD);
			if(skill_level>0)
			{
				if(bMShield[client]==true)
				{
					PrintHintText(client,"%T","Mana Shield: Deactivated",client);
					bMShield[client]=false;
					StopSound(client, SNDCHAN_AUTO,State);
					//W3EmitSoundToAll(Exp,client);
				}
				else
				{
					PrintHintText(client,"%T","Mana Shield: Activated",client);
					//W3EmitSoundToAll(Cast,client);
					CreateTimer(1.2,shieldsoundloop,client);
					bMShield[client]=true;
				}
			}
		}
	}
	else
	{
		PrintHintText(client,"%T","Silenced: Can not cast",client);
	}
}

public Action:shieldsoundloop(Handle:timer,any:client)
{
	//W3EmitSoundToAll(State,client,SNDCHAN_AUTO);
}

public Action:mana(Handle:timer,any:client)
{
	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true))
			{
				if(War3_GetRace(i)==thisRaceID)
				{
					if(!bMShield[i])
					{
						new money=GetMoney(i);
						if(money<16000)
						{
							SetMoney(i,money+200);
						}
					}
					if(bMShield[i])
					{
						new money=GetMoney(i);
						if(money>100)
						{
							SetMoney(i,money-100);
						}
						else
						{
							bMShield[i]=false;
							PrintHintText(i,"%T","Mana Shield: Out of mana",i);
							StopSound(i, SNDCHAN_AUTO,State);
							//W3EmitSoundToAll(Exp,i);
						}
					}
				}
			}
		}
	}}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_TORNADO);
		if(ult_level>0)		
		{
			new Float:pos[3];
			new Float:lookpos[3];
			War3_GetAimEndPoint(client,lookpos);
			GetClientAbsOrigin(client,pos);
			pos[1]+=60.0;
			pos[2]+=60.0;
			TE_SetupBeamPoints(pos, lookpos, TornadoSprite,TornadoSprite, 0, 5, 2.0,15.0,19.0, 2, 10.0, {54,66,120,100}, 60); 
			TE_SendToAll();
			pos[1]-=120.0;
			TE_SetupBeamPoints(pos, lookpos, TornadoSprite,TornadoSprite, 0, 5, 2.0,15.0,19.0, 2, 10.0, {54,66,120,100}, 60);
			TE_SendToAll();
			new target = War3_GetTargetInViewCone(client,300.0,false,20.0);
			if(target>0&&!W3HasImmunity(target,Immunity_Ultimates))
			{
				if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TORNADO,true)) 
				{
					if(!Silenced(client))
					{
						new Float:targpos[3];
						GetClientAbsOrigin(target,targpos);
						TE_SetupBeamRingPoint(targpos, 20.0, 80.0,TornadoSprite,TornadoSprite, 0, 5, 2.6, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
						TE_SendToAll();
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 40.0, 100.0,TornadoSprite,TornadoSprite, 0, 5, 2.4, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
						TE_SendToAll();
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 60.0, 120.0,TornadoSprite,TornadoSprite, 0, 5, 2.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 80.0, 140.0,TornadoSprite,TornadoSprite, 0, 5, 2.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 100.0, 160.0,TornadoSprite,TornadoSprite, 0, 5, 1.8, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 120.0, 180.0,TornadoSprite,TornadoSprite, 0, 5, 1.6, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 140.0, 200.0,TornadoSprite,TornadoSprite, 0, 5, 1.4, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 160.0, 220.0,TornadoSprite,TornadoSprite, 0, 5, 1.2, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();	
						targpos[2]+=20.0;
						TE_SetupBeamRingPoint(targpos, 180.0, 240.0,TornadoSprite,TornadoSprite, 0, 5, 1.0, 20.0, 0.0, {54,66,120,100}, 10, FBEAM_HALOBEAM);
						TE_SendToAll();
						//W3EmitSoundToAll(Tornado,client);
						//W3EmitSoundToAll(Tornado,target);
						new Float:velocity[3];
						velocity[2]+=800.0;
						SetEntDataVector(target,m_vecBaseVelocity,velocity,true);
						CreateTimer(0.1,nado1,target);
						CreateTimer(0.4,nado2,target);
						CreateTimer(0.9,nado3,target);
						CreateTimer(1.4,nado4,target);
						War3_DealDamage(target,50,client,DMG_GENERIC,"Tornado");
						//War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_TORNADO,_,_);
						War3_CooldownMGR(client,Cooldown[ult_level],thisRaceID,ULT_TORNADO,_,_);
					}
					else
					{
						PrintHintText(client,"%T","Silenced: Can not cast",client);
					}
				}
			}
			else
			{
				PrintHintText(client,"%T","NO VALID TARGETS WITHIN {amount} FEET",client,30.0);
			}
		}
		else
		{
			PrintHintText(client,"%T","Level Tornado First",client);
		}
	}
}

public Action:nado1(Handle:timer,any:client)
{
	new Float:velocity[3];
	velocity[2]+=4.0;
	velocity[0]-=600.0;
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}
public Action:nado2(Handle:timer,any:client)
{
	new Float:velocity[3];
	velocity[2]+=4.0;
	velocity[1]-=600.0;
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}

public Action:nado3(Handle:timer,any:client)
{
	new Float:velocity[3];
	velocity[2]+=4.0;
	velocity[0]+=600.0;
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}

public Action:nado4(Handle:timer,any:client)
{
	new Float:velocity[3];
	velocity[2]+=4.0;
	velocity[1]+=600.0;
	SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
}
