/**
* File: War3Source_[Cereal] NINJA.sp
* Description: a race for War3Source.
* Author(s): Cereal Killer + Ownz
*/

// War3Source stuff
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>

new thisRaceID;
new Float:InvisibilityAlpha[7]={1.0,0.85,0.70,0.65,0.55,0.45,0.4};
new Float:SkillLongJump[7]={0.0,2.0,2.5,3.0,4.5,5.0,5.5};
new Float:DodgeChance[7]={0.0,0.05,0.10,0.15,0.20,0.25,0.3};
new Float:VanishChance[7]={0.0,0.04,0.7,0.11,0.14,0.17,0.2};
// new Handle:ultRangeCvar;
new g_offsCollisionGroup;
new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;
new Float:ASSASSINATION_cooldown[7]={40.0,35.0,30.0,25.0,20.0,15.0,10.0};
new String:ultimateSound[]="ambient/office/coinslot1.mp3";

new String:NinjaMdl[]="models/player/techknow/tmnt/ninja.mdl";

new SKILL_INVIS, SKILL_LONGJUMP, SKILL_DODGE, SKILL_VANISH, ULT_ASSASSINATION;

public Plugin:myinfo = 
{
	name = "War3Source Race - Ninja",
	author = "Cereal Killer + Ownz ",
	description = "The Ninja race for War3Source.",
	version = "1.0.0.0",
	url = "http://war3source.com"
};

// War3Source Functions
public OnPluginStart()
{
	// ultRangeCvar=CreateConVar("war3_ninja_ult_range","99999","Range of ninja assination ultimate");
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	HookEvent("player_jump",PlayerJumpEvent);
	
	LoadTranslations("w3s.race.ninja.phrases");
}


public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public Action:OnWeaponCanUse(client, weapon)
{
	new ClientRace = War3_GetRace(client);
	if(ClientRace==thisRaceID)
	{
		decl String:name[64];
		GetEdictClassname(weapon, name, sizeof(name));
		
		if(!StrEqual(name, "weapon_knife", false)){
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==180)
	{
		thisRaceID=War3_CreateNewRaceT("ninja");
		SKILL_INVIS=War3_AddRaceSkillT(thisRaceID,"Camo",false,6);
		SKILL_LONGJUMP=War3_AddRaceSkillT(thisRaceID,"LongJump",false,6);
		SKILL_DODGE=War3_AddRaceSkillT(thisRaceID,"DodgeBullets",false,6);
		SKILL_VANISH=War3_AddRaceSkillT(thisRaceID,"Vanish",false,6);
		ULT_ASSASSINATION=War3_AddRaceSkillT(thisRaceID,"Assassination",true,6);
		W3SkillCooldownOnSpawn(thisRaceID,ULT_ASSASSINATION,10.0,_);
		
		War3_CreateRaceEnd(thisRaceID);
	}
}


// *************************************************************


public OnMapStart()
{
	////War3_PrecacheSound(ultimateSound);
	//PrecacheModel(NinjaMdl, true);

}
new Float:pOsition[3];
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_ASSASSINATION);
		if(ult_level>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_ASSASSINATION,_,_,_))
			{
				new Float:posVec[3];
				GetClientAbsOrigin(client,posVec);
				new Float:otherVec[3];
				new Float:bestTargetDistance=3000.0; 
				new ClientTeam = GetClientTeam(client);
				new bestTarget=0;
				
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true))
					{
						new ITeam = GetClientTeam(i);
						if(ITeam!=ClientTeam && !IsUltImmune(i))
						{
							GetClientAbsOrigin(i,otherVec);
							new Float:dist=GetVectorDistance(posVec,otherVec);
							if(dist<bestTargetDistance)
							{
								bestTarget=i;
								bestTargetDistance=GetVectorDistance(posVec,otherVec);
							}
						}
					}
				}
				
				if(bestTarget==0)
				{
					W3MsgNoTargetFound(client,bestTargetDistance);
				}
				else
				{
					new BestTargetMaxHP = War3_GetMaxHP(bestTarget);
					new damage=RoundFloat(float(BestTargetMaxHP)/2.0);
					if(damage>0)
					{
						War3_CachedPosition(bestTarget,Float:pOsition);
						TeleportEntity(client,pOsition,NULL_VECTOR,NULL_VECTOR);
						SetEntData(bestTarget, g_offsCollisionGroup, 2, 4, true);
												
						//EmitSoundToAll(ultimateSound,client);
						War3_CooldownMGR(client,ASSASSINATION_cooldown[ult_level],thisRaceID,ULT_ASSASSINATION,true,true);
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



// public CooldownUltimate(client)
// {
	// new skilllevel_assassination=War3_GetSkillLevel(client,thisRaceID,ULT_ASSASSINATION);
	// War3_CooldownMGR(client,ASSASSINATION_cooldown[skilllevel_assassination],thisRaceID,ULT_ASSASSINATION,true,true);
// }

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID, "");
		W3ResetAllBuffRace(client,thisRaceID);
		W3ResetPlayerColor(client,thisRaceID);
	}
	else
	{
		ActivateSkills(client);
		//SetEntityModel(client, NinjaMdl);
		War3_WeaponRestrictTo(client,thisRaceID, "weapon_knife");
		new ClientTeam = GetClientTeam(client);
		if(ClientTeam==3)
		{
			W3SetPlayerColor(client,thisRaceID,20,100,200,255,1);
		}
		else if(ClientTeam==2)
		{
			W3SetPlayerColor(client,thisRaceID,220,50,0,255,1);
		}
		else
		{
			W3ResetPlayerColor(client,thisRaceID);
		}
	}
}


// *************************************************************************************************


public ActivateSkills(client)
{
	new ClientRace = War3_GetRace(client);
	if(ClientRace==thisRaceID)
	{
		
		new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_INVIS);
		new Float:alpha=InvisibilityAlpha[skilllevel];
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
		
		
		SetEntData(client, g_offsCollisionGroup, 2, 4, true);
	}
}



public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	new ClientRace = War3_GetRace(client);
	if(ClientRace==thisRaceID)
	{
		ActivateSkills(client);
	}
}




public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim,true) && ValidPlayer(attacker))
	{
		new ATeam = GetClientTeam(attacker);
		new VTeam = GetClientTeam(victim);
		new VRace = War3_GetRace(victim);
		if(VRace==thisRaceID && ATeam!=VTeam) 
		{
			new skill_level_dodge=War3_GetSkillLevel(victim,thisRaceID,SKILL_DODGE);
			if(skill_level_dodge>0)
			{
				if(War3_Chance(DodgeChance[skill_level_dodge]) && !IsSkillImmune(attacker))
				{
					W3FlashScreen(victim,RGBA_COLOR_BLUE);
					War3_DamageModPercent(0.0); //NO DAMAMGE
					// PrintToConsole( victim, "DODGE OF NINJA WORK GOOD ! ! !" );
				}
			}
		}
	}
}

public OnWar3EventPostHurt(victim,attacker,dmg){
	if(ValidPlayer(victim,true)&&War3_GetRace(victim)==thisRaceID)
	{ 
		new skilllevel=War3_GetSkillLevel(victim,thisRaceID,SKILL_VANISH);
		if(skilllevel>0&&War3_Chance(VanishChance[skilllevel]))
		{
			PrintHintText(victim,"%T","You disapear in the shadows",victim);
			War3_SetBuff(victim,fInvisibilitySkill,thisRaceID,0);
			CreateTimer(1.5,Invis1,victim);
		}
	}
}

public Action:Invis1(Handle:timer,any:victim)
{
	new VictimRace = War3_GetRace(victim);
	if(VictimRace==thisRaceID)
	{
		new skilllevel=War3_GetSkillLevel(victim,thisRaceID,SKILL_INVIS);
		War3_SetBuff(victim,fInvisibilitySkill,thisRaceID,InvisibilityAlpha[skilllevel]);
	}
	else
	{
		War3_SetBuff(victim,fInvisibilitySkill,thisRaceID,1.0);
	}
}



public OnWar3EventSpawn(client)
{
	new ClientRace = War3_GetRace(client);
	if(ClientRace==thisRaceID)
	{
		new ClientMaxHP = War3_GetMaxHP(client);
		new NewMaxHP = ClientMaxHP-60;
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,NewMaxHP);
		ActivateSkills(client);
		//SetEntityModel(client, NinjaMdl);
		new ClientTeam = GetClientTeam(client);
		if(ClientTeam==3)
		{
			W3SetPlayerColor(client,thisRaceID,20,100,200,255,1);
		}
		else if(ClientTeam==2)
		{
			W3SetPlayerColor(client,thisRaceID,220,50,0,255,1);
		}
		else
		{
			W3ResetPlayerColor(client,thisRaceID);
		}
	}
}
   

   
public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	new ClientRace = War3_GetRace(client);
	if(ClientRace==thisRaceID){
		new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_LONGJUMP);
		if(skilllevel>0){
			new Float:velocity[3]={0.0,0.0,0.0};
			velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
			velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
			velocity[0]*=SkillLongJump[skilllevel]*0.25;
			velocity[1]*=SkillLongJump[skilllevel]*0.25;
			SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
		}
	}
}
