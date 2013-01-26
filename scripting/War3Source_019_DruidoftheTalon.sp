/**
* File: War3Source_DruidoftheTalon.sp
* Description: The Druid race for War3Source.
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


/*
* GetPlayerWeaponSlot(client, slot); Entity index on success
* native bool:RemovePlayerItem(client, item);  Entity index 
* native GivePlayerItem(client, const String:item[], iSubType=0);  classname
* */


new thisRaceID;
new bool:bFlying[66];
new Handle:ultCooldownCvar;

//skill 1
new Float:this_pos[3];
new GlowSprite,GlowSprite2;
new bool:bFaerie[66];
new Float:AbilityCooldownTime=10.0;
new Float:FaerieMaxDistance[]={0.0,650.0,700.0,750.0,800.0,850.0,900.0,950.0,1000.0}; //max distance u can target your ultimate

//skill 2
new ShieldSprite,TornadoSprite;
new String:Tornado[]="HL1/ambience/des_wind2.mp3";
new m_vecBaseVelocity; //offsets
new Float:CycloneVec[9]={0.0,380.0,390.0,400.0,410.0,420.0,430.0,440.0,450.0};
new FaeriedBy[66];

//skill 3



new SKILL_FAERIE, SKILL_CYCLONE, ULT_CROW;

public Plugin:myinfo = 
{
	name = "War3Source Race - Druid of the Talon",
	author = "[Oddity]TeacherCreature",
	description = "The Druid race for War3Source.",
	version = "1.0.0.0",
	url = "warcraft-source.net"
};

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("war3_druidt_flying_cooldown","1.5","Cooldown for Flying");
	HookEvent("round_start",RoundStartEvent);
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	
	LoadTranslations("w3s.race.druidt.phrases");
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID){
		W3ResetAllBuffRace(client,thisRaceID);
		War3_WeaponRestrictTo(client,thisRaceID,"");
	}
	else
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		if(IsPlayerAlive(client)){
			bFlying[client]=false;
			GivePlayerItem(client, "weapon_knife");
		}
	}
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==8)
	{
		thisRaceID=War3_CreateNewRaceT("druidt");
		SKILL_FAERIE=War3_AddRaceSkillT(thisRaceID,"FaerieFire",false,8);
		SKILL_CYCLONE=War3_AddRaceSkillT(thisRaceID,"Cyclone",false,8);
		ULT_CROW=War3_AddRaceSkillT(thisRaceID,"CrowForm",false,1); 
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnGameFrame()
{
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true))
		{
			new tteam=GetClientTeam(i);
			if(bFaerie[i]==true)
			{
				GetClientAbsOrigin(i,this_pos);
				this_pos[2]+=20;//offset for effect
				if(tteam==2)
				{
					TE_SetupGlowSprite(this_pos,GlowSprite,0.1,0.6,80);
					TE_SendToAll();
					//TE_SendToClient(client, Float:delay=0.0) 
				}
				else
				{
					//this_pos[2]+=20;
					//TE_SetupGlowSprite(this_pos,GlowSprite2,0.1,0.1,150);
					//TE_SendToAll();	
				}
			}
		}
	}
}

public OnMapStart()
{
	ShieldSprite=PrecacheModel("sprites/rico1.vmt");
	TornadoSprite=PrecacheModel("sprites/richo1.vmt");
	PrecacheModel("models/player/ctm_gsg9.mdl");
		PrecacheModel("models/player/tm_leet_variantb.mdl");
	//PrecacheModel("models/chicken/chicken.mdl", true);
	GlowSprite=PrecacheModel("effects/redflare.vmt");
	////War3_PrecacheSound(Tornado);
//	GlowSprite2=PrecacheModel("VGUI/gfx/VGUI/gign.vmt");
//sprites/blueglow1.vmt
	GlowSprite2=PrecacheModel("materials/effects/fluttercore.vmt");
	
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_FAERIE);
		if(skill_level>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_FAERIE,true))
			{
				if(!Silenced(client))
				{
					new target = War3_GetTargetInViewCone(client,FaerieMaxDistance[skill_level],false,23.0);
					if(target>0)
					{
						PrintHintText(client,"%T","Faerie Fire: Marked Target",client);
						bFaerie[target]=true;
						FaeriedBy[target]=client;
						War3_CooldownMGR(client,AbilityCooldownTime,thisRaceID,SKILL_FAERIE,_,_);
						CreateTimer(10.0,faerieoff,target);
					}
					else
					{
						PrintHintText(client,"%T","NO VALID TARGETS WITHIN {amount} FEET",client,FaerieMaxDistance[skill_level]/10.0);
					}
				}
				else
				{
					PrintHintText(client,"%T","Silenced: You can not cast!",client); 
				}
			}
			
		}
		else
		{
			PrintHintText(client,"%T","Level Your Ability First",client);
		}
	}
}

public Action:faerieoff(Handle:h, any:client)
{
	if(IS_PLAYER(client))
	{
		bFaerie[client]=false;
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
			new race_victim=War3_GetRace(victim);
			new skill_level_cyclone=War3_GetSkillLevel(attacker,thisRaceID,SKILL_CYCLONE);

			// Cyclone
			if(race_attacker==thisRaceID && skill_level_cyclone>0)
			{
				if(GetRandomFloat(0.0,1.0)<=0.5 && !W3HasImmunity(victim,Immunity_Skills)&&!Silenced(attacker))
				{
					new Float:targpos[3];
					GetClientAbsOrigin(victim,targpos);
					TE_SetupBeamRingPoint(targpos, 20.0, 80.0,TornadoSprite,TornadoSprite, 0, 5, 2.6, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
					TE_SendToAll();
					targpos[2]+=20.0;
					TE_SetupBeamRingPoint(targpos, 40.0, 100.0,TornadoSprite,TornadoSprite, 0, 5, 2.4, 20.0, 0.0, {54,66,120,100}, 10,FBEAM_HALOBEAM);
					TE_SendToAll();
					targpos[2]+=20.0;
					TE_SetupGlowSprite(targpos, ShieldSprite, 1.0, 1.0, 130);
					TE_SendToAll(); 
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
					//EmitSoundToAll(Tornado,attacker);

					new Float:velocity[3];
					velocity[2]=CycloneVec[skill_level_cyclone];
					SetEntDataVector(victim,m_vecBaseVelocity,velocity,true);
					PrintToConsole(attacker,"%T","Cyclone",attacker);
					PrintToConsole(victim,"%T","Cyclone",victim);
					W3FlashScreen(victim,RGBA_COLOR_WHITE,1.0,1.0);
					War3_SetBuff(victim,bBashed,thisRaceID,true);
					CreateTimer(1.0,unbash,victim);
				}
			}
		}
	}
}

public Action:unbash(Handle:h, any:client)
{
	War3_SetBuff(client,bBashed,thisRaceID,false);
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_CROW);
		if(ult_level>0)		
		{
			new Float:cooldown=GetConVarFloat(ultCooldownCvar);
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_CROW,true)) 
			{
				if(!Silenced(client))
				{
					if(!bFlying[client])
					{
						bFlying[client]=true;
						War3_SetBuff(client,bFlyMode,thisRaceID,true);
						//PrintHintText(client,"%T","Chicken Form!",client);
						//SetEntityModel(client, "models/chicken/chicken.mdl");
						
						//War3_WeaponRestrictTo(client,thisRaceID,"Crow_Form");
					}
					else
					{
						CreateTimer(0.1,returnform,client);
					}
					War3_CooldownMGR(client,cooldown,thisRaceID,ULT_CROW,_,false);
				}
				else
				{
					PrintHintText(client,"%T","Silenced: You can not cast!",client);
				}
			}
		}
		else
		{
			PrintHintText(client,"%T","Level Your Ultimate First",client);
		}
	}
}

public Action:returnform(Handle:h, any:client)
{
	if(ValidPlayer(client,true))
	{
		bFlying[client]=false;
		War3_SetBuff(client,bFlyMode,thisRaceID,false);
		PrintHintText(client,"%T","Elf Form!",client);
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		GivePlayerItem(client, "weapon_knife");
		if(GetClientTeam(client)==3)
		{
			SetEntityModel(client, "models/player/ctm_gsg9.mdl");
		}
		if(GetClientTeam(client)==2)
		{
			SetEntityModel(client, "models/player/tm_leet_variantb.mdl");
		}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if(bFaerie[victim]==true)
	{
		new old_XP = War3_GetXP(FaeriedBy[victim],thisRaceID);
		new xp;
		xp = 20;
		War3_SetXP(FaeriedBy[victim],thisRaceID,old_XP+xp);
		new old_Gold = War3_GetGold(FaeriedBy[victim]);
		new gold;
		gold = 1;
		War3_SetGold(FaeriedBy[victim],old_Gold+gold);
		bFaerie[victim]=false;
		PrintHintText(FaeriedBy[victim],"%T","Target Died - 20 XP and 1 Gold",FaeriedBy[victim]);
	}
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		bFaerie[i]=false;
	}
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		bFlying[client]=false;
		War3_SetBuff(client,bFlyMode,thisRaceID,false);
		GivePlayerItem(client, "weapon_knife");
	}
	else{
		//bFlying[client]=true; //kludge, not to allow some other race switch to this race and explode on death (ultimate)
	}
}
