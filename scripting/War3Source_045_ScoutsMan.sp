/*
* File					: War3Source_ScoutsMan.sp
* Description			: The ES version of ScoutMan race for War3Source.
* Author(s)				: Schmarotzer & [Oddity]TeacherCreature
* Original Idea			: [H.F.M.]Rasmus{Chef}
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
new String:frndsnd[]="war3source/reincarnation.mp3";
new ClipOffset,AmmoOffset;

new bool:bAvenged[MAXPLAYERS];

//skill 1
new Float:TrainingPercent[5]={0.0,0.45,0.70,0.95,1.20};
new Float:TrainingChance[5]={0.0,0.20,0.30,0.40,0.50};

//skill 2
new Float:FriendsChance[5]={0.0,0.40,0.55,0.70,0.90};

//skill 3 
new Float:DisguiserAlphaCS[5]={1.0,0.85,0.7,0.55,0.4};
new Float:DisguiserAlphaTF[5]={1.0,0.85,0.7,0.55,0.4};

//skill 4.
new HealthArr[]={0,5,6,7,8,9,10};
new Float:Cooldown[]={0.0, 4.0, 3.0, 2.0, 1.0};
new bool:bFlying[66];

new SKILL_TRAINING, SKILL_FRIENDS, SKILL_DISGUISER, ULT_FLYSCOUT;

public Plugin:myinfo = 
{
	name = "War3Source Race - ScoutMan",
	author = "Schmarotzer",
	description = "The ES ScoutMan race for War3Source.",
	version = "1.0.0.0",
	url = "http://css.bashtel.ru/"
};

public OnPluginStart()
{
	LoadTranslations("w3s.race.scout.phrases");
	ClipOffset=FindSendPropOffs("CBaseCombatWeapon","m_iClip1");
	AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
}

public OnMapStart()
{
	////War3_PrecacheSound(frndsnd);
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==2)
	{
		thisRaceID=War3_CreateNewRaceT("scout");
		SKILL_TRAINING=War3_AddRaceSkillT(thisRaceID,"Training",false,4); // READY со скаута
		SKILL_FRIENDS=War3_AddRaceSkillT(thisRaceID,"Friends",false,4); // READY тока свои, но не я и один раз
		SKILL_DISGUISER=War3_AddRaceSkillT(thisRaceID,"Disguiser",false,4); // READY маскировка
		ULT_FLYSCOUT=War3_AddRaceSkillT(thisRaceID,"FlyScout",true,4);  // READY полеты
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID){
		W3ResetAllBuffRace(client,thisRaceID);
		War3_WeaponRestrictTo(client,thisRaceID, "");
	}
	if(newrace==thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_ssg08,weapon_glock,weapon_hkp2000,weapon_fiveseven,weapon_p250,weapon_deagle,weapon_m4a1,weapon_ak47,weapon_elite");
		bFlying[client]=false;
		if(ValidPlayer(client,true))
		{
			InitPassiveSkills(client);
			GivePlayerItem(client,"weapon_ssg08");
		}
	}
}

public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skill_level_disguiser=War3_GetSkillLevel(client,thisRaceID,SKILL_DISGUISER);
		new Float:alpha=(War3_GetGame()==Game_CS)?DisguiserAlphaCS[skill_level_disguiser]:DisguiserAlphaTF[skill_level_disguiser];
		//if(skill_invis>0)
			//War3_ChatMessage(client,"You fade %s into the backdrop.",(skill_invis==1)?"slightly":(skill_invis==2)?"well":(skill_invis==3)?"greatly":"dramatically");
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
	}
}


public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new x=1;x<=64;x++)
		bAvenged[x]=false;
}

// =================================================================================================
// ===================================== SCOUTSMAN TRAINING ========================================
// =================================================================================================
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			//new Float:chance_mod=W3ChanceModifier(attacker);
			if(race_attacker==thisRaceID)
			{
				new skill_level_training=War3_GetSkillLevel(attacker,race_attacker,SKILL_TRAINING);
				if(skill_level_training>0&&!Hexed(attacker,false))
				{
					//new Float:chance=0.15*chance_mod;
					if( GetRandomFloat(0.0,1.0)<=TrainingChance[skill_level_training] && !W3HasImmunity(victim,Immunity_Skills))
					{
						new Float:percent=TrainingPercent[skill_level_training]; //0.0 = zero effect -1.0 = no damage 1.0=double damage
						new health_take=RoundFloat(damage*percent);
						//new new_health=GetClientHealth(victim)-health_take;
						//if(new_health<0)
						//	new_health=0;
						//SetEntityZHealth(victim,new_health);
						
						new ent = W3GetCurrentWeaponEnt(attacker);
						if(ent>0 && IsValidEdict(ent))
						{
							decl String:wepName[64];
							GetEdictClassname(ent,wepName,64);
							if(StrEqual(wepName,"weapon_ssg08",true))
							{
								if(health_take>80) health_take=80;
								if(War3_DealDamage(victim,health_take,attacker,_,"scouttraining",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL,true))
								{	
									W3PrintSkillDmgHintConsole(victim,attacker,War3_GetWar3DamageDealt(),SKILL_TRAINING);
									W3FlashScreen(victim,RGBA_COLOR_RED);
								}
							}
						}
					}
				}
			}
		}
	}
}
// =================================================================================================
// =================================================================================================
// =================================================================================================







public OnWar3EventDeath(index,attacker)
{	
	if(ValidPlayer(index)){
		new race=W3GetVar(DeathRace); //get  immediate variable, which indicates the race of the player when he died
		if(race==thisRaceID && !bAvenged[index] && War3_GetGame()!=Game_TF)
		{
			new skill_level_friends=War3_GetSkillLevel(index,race,SKILL_FRIENDS);
			if(skill_level_friends>0) //let them revive even if hexed
			{
				new Float:percent=FriendsChance[skill_level_friends];
				if(GetRandomFloat(0.0,1.0)<=percent)
				{
					//PrintToChatAll("FriendsChance: %d",FriendsChance[skill_level_friends]);
					
					new team = GetClientTeam(index);
					new possibletargets[MAXPLAYERS];
					new possibletargetsfound;
					for(new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i) && !IsPlayerAlive(i) && GetClientTeam(i)==team && i!=index)
						{
							possibletargets[possibletargetsfound]=i;
							possibletargetsfound++;
							//PrintToChatAll("possibletargetsfound: %d",possibletargetsfound);
						}
					}
					new onetarget;
					if(possibletargetsfound>0)
					{
						//PrintToChatAll("possibletargetsfound: %d > 0",possibletargetsfound);
						onetarget=possibletargets[GetRandomInt(0, possibletargetsfound-1)]; //i hope random 0 0 works to zero
						//PrintToChatAll("Random Man : %d",onetarget);
						if(onetarget>0)
						{
							//PrintToChatAll("onetarget : %d > 0",possibletargetsfound);
							new Float:ang[3];
							new Float:pos[3];
							new String:otname[32];
							War3_SpawnPlayer(onetarget);
							//PrintToChatAll("SPAWN PLAYER");
							GetClientEyeAngles(index,ang);
							GetClientAbsOrigin(index,pos);
							TeleportEntity(onetarget,pos,ang,NULL_VECTOR);
							//EmitSoundToAll(frndsnd,onetarget);
							bAvenged[index]=true;
							//PrintToChatAll("PLAY SOUND");
							// War3_ChatMessage(client,"%T","You reincarnated by ",client);
							//GetClientName(onetarget,otname,32);
							War3_ChatMessage(onetarget,"%T","A teammate has been slayed",onetarget);
							//A teammate has been slayed, you have been summuned to avenge his death
							//You call apon #green server_var(wcs_name) #lightgreento Avenge your Death
							GetClientName(onetarget,otname,32);
							War3_ChatMessage(index,"%T","You call apon [name] to Avenge your Death",index,otname);
						}
						else
						{
							bAvenged[index]=false;
						}
					}
				}
			}
		}
	}
}













public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_FLYSCOUT);
		if(ult_level>0)		
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_FLYSCOUT,false)) 
			{
				if(!Silenced(client))
				{
					if(!bFlying[client])
					{
						bFlying[client]=true;
						War3_SetBuff(client,bFlyMode,thisRaceID,true);
						PrintHintText(client,"%T","Now you can fly",client);
						War3_HealToBuffHP(client,HealthArr[ult_level]);
					}	
					else
					{
						bFlying[client]=false;
						War3_SetBuff(client,bFlyMode,thisRaceID,false);
						PrintHintText(client,"%T","You land",client);
					}
					War3_CooldownMGR(client,Cooldown[ult_level],thisRaceID,ULT_FLYSCOUT,_,_);
				}
				else
				{
					PrintHintText(client,"%T","Silenced_Can_not_cast",client);
				}
			}
			
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		InitPassiveSkills(client);
		bFlying[client]=false;
		War3_SetBuff(client,bFlyMode,thisRaceID,false);
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_ssg08,weapon_glock,weapon_hkp2000,weapon_fiveseven,weapon_p250,weapon_deagle,weapon_m4a1,weapon_ak47,weapon_elite");
		if(ValidPlayer(client,true))
		{
			GivePlayerItem(client,"weapon_ssg08");
			SetEntData(client,ClipOffset,30,4);
			SetEntData(client,AmmoOffset,100,4);
			// повышение патронов надо еще
		}
	}
}