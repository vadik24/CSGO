 /**
* File: War3Source_Spy.sp
* Description: The ES version of Spy race for War3Source.
* Author(s): Schmarotzer
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
new Handle:ultCooldownCvar;
// new bool:bTeleported[MAXPLAYERS];
new Float:CoordsL[MAXPLAYERS][3];
new Float:CoordsA[MAXPLAYERS][3];
//new Float:CoordsL[3];
//new Float:CoordsA[3];
new g_offsCollisionGroup;

//new Float:Location[3];
//new Float:Angle[3];

//skill 1
new Float:DruggerChance[5]={0.0,0.05,0.1,0.15,0.2}; 
new bool:bDrugged[MAXPLAYERS];

//skill 2
new const PoisonInitialDamage=20;
new const PoisonTrailingDamage=5;
new Float:PoisonChanceArr[]={0.0,0.05,0.1,0.15,0.2};
new PoisonTimes[]={0,2,3,4,5};
new BeingPoisonedBy[66];
new PoisonRemaining[66];


//skill 3 
new Float:DisguiserChance[5]={0.0,0.35,0.50,0.65,0.80};












//skill 4.





















new SKILL_DRUGGER, SKILL_POISON, SKILL_DISGUISER, ULT_TRANSPORT;

public Plugin:myinfo = 
{
	name = "War3Source Race - Spy",
	author = "Schmarotzer",
	description = "The ES Spy race for War3Source.",
	version = "1.0.0.0",
	url = "http://css.bashtel.ru/"
};

public OnPluginStart()
{
	//HookEvent("round_start",RoundStartEvent);
	LoadTranslations("w3s.race.spy.phrases");
	ultCooldownCvar=CreateConVar("war3_spy_transport_cooldown","5.0","Cooldown between teleports");
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");	
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==2)
	{
		thisRaceID=War3_CreateNewRaceT("spy");
		SKILL_DRUGGER=War3_AddRaceSkillT(thisRaceID,"Drugger",false,4); // 
		SKILL_POISON=War3_AddRaceSkillT(thisRaceID,"PoisonBullet",false,4); // 
		SKILL_DISGUISER=War3_AddRaceSkillT(thisRaceID,"Disguiser",false,4); // 
		ULT_TRANSPORT=War3_AddRaceSkillT(thisRaceID,"Transport",true,1);  //
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		//bTeleported[client]=true;
		War3_WeaponRestrictTo(client,thisRaceID, "");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{	
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_glock,weapon_hkp2000");
		if(ValidPlayer(client,true))
		{
			if(GetClientTeam(client)==3)
			{
				GivePlayerItem(client,"weapon_hkp2000");
			}
			if(GetClientTeam(client)==2)
			{
				GivePlayerItem(client,"weapon_glock");
			}
		}
	}
}


public OnWar3EventSpawn(client){
	//PrintToChatAll("3");
	
	bDrugged[client] = false;
	
	CoordsL[client] = NULL_VECTOR;
	
	
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		// bTeleported[client]=true;
		if(GetClientTeam(client)==3)
		{
			GivePlayerItem(client,"weapon_hkp2000");
		}
		if(GetClientTeam(client)==2)
		{
			GivePlayerItem(client,"weapon_glock");
		}
		// ============ DISGUISER ============
		new skill_level_disguiser=War3_GetSkillLevel(client,race,SKILL_DISGUISER);
		if(skill_level_disguiser>0)
		{
			if(GetRandomFloat(0.0,1.0)<=DisguiserChance[skill_level_disguiser])
			{
				if(GetClientTeam(client)==3)
				{
					//SetEntityModel(client, "models/player/t_leet.mdl");
				}
				if(GetClientTeam(client)==2)
				{
					//SetEntityModel(client, "models/player/ct_urban.mdl");
				}
			}
		}
	}
}

public OnMapStart()
{
	
	//glowsprite=PrecacheModel("sprites/strider_blackball.spr");
	//glowsprite++;
	//glowsprite--;
	/*
	if(War3_GetGame()==Game_TF)
	{
		ExplosionModel=PrecacheModel("materials/particles/fluidexplosions/fluidexplosion.vmt",false);
		PrecacheSound("weapons/explode1.mp3",false);
	}
	else
	{
		ExplosionModel=PrecacheModel("materials/sprites/zerogxplode.vmt",false);
		PrecacheSound("weapons/explode5.mp3",false);
	}
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	////War3_PrecacheSound(explosionSound1);
	*/
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
			if(race_attacker==thisRaceID)
			{
				new skill_level_drugger=War3_GetSkillLevel(attacker,race_attacker,SKILL_DRUGGER);
				if(skill_level_drugger>0)
				{
					if( GetRandomFloat(0.0,1.0)<=DruggerChance[skill_level_drugger] && !bDrugged[victim])
					{
						ServerCommand("sm_drug #%d",GetClientUserId(victim));
						//ServerCommand("sm_drug #%d %d",GetClientUserId(victim),1);
						CreateTimer(5.0,DrugOff,victim);
						bDrugged[victim] = true;
					}
				}
				new skill_level_poison=War3_GetSkillLevel(attacker,race_attacker,SKILL_POISON);
				new Float:chance_mod=W3ChanceModifier(attacker);
				if(skill_level_poison>0 && PoisonRemaining[victim]==0 && GetRandomFloat(0.0,1.0)<=chance_mod*PoisonChanceArr[skill_level_poison]&&!Silenced(attacker))
				{
					if(W3HasImmunity(victim,Immunity_Skills))
					{
						//PrintHintText(victim,"%T","Immunity to Fangs",victim);
						//PrintHintText(attacker,"%T","Fangs Immunity",attacker);
					}
					else
					{
						//PrintHintText(victim,"%T","You got bitten by enemy with Fangs",victim);
						//PrintHintText(attacker,"%T","You bit your enemy with Fangs",attacker);
						BeingPoisonedBy[victim]=attacker;
						PoisonRemaining[victim]=PoisonTimes[skill_level_poison];
						War3_DealDamage(victim,PoisonInitialDamage,attacker,DMG_BULLET,"poison");
						W3FlashScreen(victim,RGBA_COLOR_RED);
						
						////EmitSoundToAll(Fangsstr,attacker);
						////EmitSoundToAll(Fangsstr,victim);
						CreateTimer(1.0,PoisonLoop,victim);
					}
				}
			}
		}
	}
}



public Action:PoisonLoop(Handle:timer,any:victim)
{
	if(PoisonRemaining[victim]>0 && ValidPlayer(BeingPoisonedBy[victim]) && ValidPlayer(victim,true))
	{
		War3_DealDamage(victim,PoisonTrailingDamage,BeingPoisonedBy[victim],_,"Poison Bullets",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_TRUEDMG);
		PoisonRemaining[victim]--;
		W3FlashScreen(victim,RGBA_COLOR_RED, 0.3, 0.4);
		CreateTimer(1.0,PoisonLoop,victim);
	}
}





public Action:DrugOff(Handle:h,any:victim)
{
	if(ValidPlayer(victim))
	{
		new VictimID = GetClientUserId(victim);
		ServerCommand("sm_drug #%d",VictimID);
		bDrugged[victim] = false;
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new race = War3_GetRace(client);
		new ult_level=War3_GetSkillLevel(client,race,ULT_TRANSPORT);
		if(ult_level>0)
		{
			//GetEntPropVector(client, Prop_Send, "m_vecLocation", Location);
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", CoordsL[client]);
			GetEntPropVector(client, Prop_Send, "m_angRotation", CoordsA[client]);
			//CoordsL[client][0] = Location[0];
			//CoordsL[client][1] = Location[1];
			//CoordsL[client][2] = Location[2];
			//CoordsA[client][0] = Angle[0];
			//CoordsA[client][1] = Angle[1];
			//CoordsA[client][2] = Angle[2];
		
			//GetClientEyeAngles(client,ang);
			//GetClientAbsLocation(client,pos);
			//PrintToChatAll("LOCATION IS SAVED");
			War3_ChatMessage(client,"%T","LocSaved",client);
		}
	}
}


public OnUltimateCommand(client,race,bool:pressed)
{
	if(pressed)
	{
		if(race==thisRaceID&&IsPlayerAlive(client)&&!Silenced(client))
		{
			new ult_level=War3_GetSkillLevel(client,race,ULT_TRANSPORT);
			if(ult_level>0)
			{
				// new Float:Location[3];
				// Location[0] = CoordsL[client][0];
				// Location[1] = CoordsL[client][1];
				// Location[2] = CoordsL[client][2];
				// Angle[0] = CoordsA[client][0];
				// Angle[1] = CoordsA[client][1];
				// Angle[2] = CoordsA[client][2];
				if(CoordsL[client][0]!=0 && CoordsL[client][1]!=0 && CoordsL[client][2]!=0 && War3_SkillNotInCooldown(client,thisRaceID,ULT_TRANSPORT,true))
				{
					TeleportEntity(client, CoordsL[client], CoordsA[client], NULL_VECTOR);
					SetEntData(client, g_offsCollisionGroup, 2, 4, true);
					CreateTimer(3.0,normal,client);
					War3_ChatMessage(client,"%T","Teleported",client);
					// bTeleported[client]=true;
					new Float:cooldown=GetConVarFloat(ultCooldownCvar);
					War3_CooldownMGR(client,cooldown,thisRaceID,ULT_TRANSPORT,_,_);
				}
				else
				{
					War3_ChatMessage(client,"%T","MustSave",client);
				}
			}
			else
			{
				W3MsgUltNotLeveled(client);
			}
		}
	}
}

/*
public OnCooldownExpired(client,raceID,skillNum,bool:expiredbytime)
{
	if(raceID==thisRaceID)
	{
		if(skillNum==ULT_TRANSPORT)
		{
			if(expiredbytime){
				//PrintHintText(client,"UltimateReady");
			}
		}
	}
}

public UltimateNotReadyMSG(client)
{
	PrintHintText(client,"%T","Ultimate not ready, {amount} seconds remaining",client,War3_CooldownRemaining(client,thisRaceID,ULT_TRANSPORT));
}
*/

public Action:normal(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		SetEntData(client, g_offsCollisionGroup, 5, 4, true);
	}
}




/*
public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	bTeleported[client]=true;
}


public OnWar3EventDeath(victim,attacker)
{
	if(victim==thisRaceID)
		{
			bTeleported[victim]=true;
		}
}
*/