/*** File: War3Source_MontainKing.sp
 * * Description: The Montain King race for War3Source.
 * * Author(s): Cereal Killer + Anthony Iacono 
 * */ #pragma semicolon 1
 
 #include <sourcemod>
 #include "W3SIncs/War3Source_Interface"
 #include <sdktools>
 #include <sdktools_functions>
 #include <sdktools_tempents>
 #include <sdktools_tempents_stocks>
 #include <sdkhooks>
 
 new thisRaceID;
 new Float:DmgChance[5]={0.0,0.1,0.15,0.2,0.25};
 new Float:BashChance[5]={0.0,0.5,0.1,0.12,0.15};
 new bool:bIsBashed[MAXPLAYERS];
 new Float:avatarcooldown[5]={0.0,30.0,28.0,26.0,24.0};
 new avatarhp[5]={100,120,140,160,180};
 new tclapdist[5]={0,250,275,300,325};
 new tclapdamage[5]={0,6,8,10,12};
 new stormdamage[5]={0,10,13,16,19};
 new Float:stormbashtime[5]={0.0,0.8,1.0,1.2,1.4};
 new BeamSprite,HaloSprite;
 //new StarSprite,TSprite,CTSprite,BurnSprite,g_iExplosionModel,g_iSmokeModel;
 
public Plugin:myinfo =
{	
 	name = "War3Source Race - Montain King",	
	author = "Cereal Killer",	
	description = "Montain King for War3Source.",	
	version = "1.0.6.3",	
	url = "http://warcraft-source.net/"
};

new SKILL_STORM, SKILL_TCLAP, SKILL_BASH, ULT_AVATAR;

public OnPluginStart()
{	
	CreateTimer(0.1,overheal,_,TIMER_REPEAT);
	
	LoadTranslations("w3s.race.mking.phrases");
}

public OnMapStart()
{
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	/*StarSprite=PrecacheModel("materials/effects/fluttercore.vmt");
	* TSprite=PrecacheModel("VGUI/gfx/VGUI/guerilla.vmt");
	* CTSprite=PrecacheModel("VGUI/gfx/VGUI/gign.vmt");
	* BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
	* g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
	* g_iSmokeModel     = PrecacheModel("materials/effects/fire_cloud2.vmt");
	* */
}

public OnRaceChanged(client, oldrace, newrace)
{
	if (newrace == thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		if(ValidPlayer(client,true))
		{
			GivePlayerItem(client, "weapon_knife");
		}
	}
	else if (oldrace == thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client, thisRaceID);
	}
}

public OnWar3EventSpawn(client)
{
	bIsBashed[client]=false;
	War3_SetBuff(client,bBashed,thisRaceID,false);
	War3_SetBuff(client,bImmunitySkills,thisRaceID,false);
	if (War3_GetRace(client) == thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		GivePlayerItem(client,"weapon_knife");
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.3);
	}
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==27)
	{
		thisRaceID=War3_CreateNewRaceT("mking");
		SKILL_STORM=War3_AddRaceSkillT(thisRaceID,"StormBolt",false,4);
		SKILL_TCLAP=War3_AddRaceSkillT(thisRaceID,"ThunderClap",false,4);
		SKILL_BASH=War3_AddRaceSkillT(thisRaceID,"Bash",false,4);
		ULT_AVATAR=War3_AddRaceSkillT(thisRaceID,"Avatar",true,4);
		War3_CreateRaceEnd(thisRaceID);
	}
}

// public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && attacker!=victim)
	{	
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_BASH);
			if(race_attacker==thisRaceID && skill_level>0 )
 			{
				if(W3Chance(DmgChance[skill_level]) && !IsSkillImmune(victim) && !Hexed(attacker,false))
				{
					War3_DamageModPercent(1.2);
				}
				if(W3Chance(BashChance[skill_level]) &&!bIsBashed[victim] && !IsSkillImmune(victim)&& !Hexed(attacker,false))
				{
					War3_SetBuff(victim,bBashed,thisRaceID,true);
					bIsBashed[victim]=true;
					CreateTimer(1.0, Unbash, victim);
				}
			}
		}
	}
}

public Action:Unbash(Handle:timer,any:victim)
{
	War3_SetBuff(victim,bBashed,thisRaceID,false);
	bIsBashed[victim]=false;
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && IsPlayerAlive(client) && pressed)
	{
		new skill_level=War3_GetSkillLevel(client,race,ULT_AVATAR);
		if(skill_level>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_AVATAR,true,true,true))
			{
				War3_CooldownMGR(client,avatarcooldown[skill_level],thisRaceID,ULT_AVATAR,_,_);
				SetEntityHealth(client, avatarhp[skill_level]);
				War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
			// PrintHintText(client,"%T","Level your ultimate first",client);
		}
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(!Silenced(client))
	{
		if (ability==0)
		{
			if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
			{
				new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_STORM);
				if(skill_level>0)
				{
					if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_STORM,true))
					{
						new Float:bestTargetDistance = 600.0;
						new target = War3_GetTargetInViewCone(client,bestTargetDistance,false,6.0);
						if(target>0)
						{
							PrintHintText(client,"%T","Storm Bolt!",client);
							War3_DealDamage(target,stormdamage[skill_level],client,DMG_CRUSH,"storm bolt",_,W3DMGTYPE_MAGIC);
							War3_SetBuff(target,bBashed,thisRaceID,true);
							CreateTimer(stormbashtime[skill_level], Unbash, target);
							new Float:iPosition[3];
							new Float:clientPosition[3];
							GetClientAbsOrigin(client, clientPosition);
							GetClientAbsOrigin(target, iPosition);
							iPosition[2]+=35;
							clientPosition[2]+=35;
							TE_SetupBeamPoints(iPosition,clientPosition,BeamSprite,HaloSprite,0,35,0.5,9.0,9.0,0,1.0,{155,000,255,255},20);
							TE_SendToAll();
							War3_CooldownMGR(client,9.0,thisRaceID,SKILL_STORM,_,_);
						}
						else
						{
							// PrintHintText(client,"%T","NO VALID TARGETS WITHIN 60 FEET",client);
							W3MsgNoTargetFound(client,bestTargetDistance);
							new Float:iPosition[3];
							new Float:clientPosition[3];
							GetClientAbsOrigin(client, clientPosition);
							War3_GetAimEndPoint(client,iPosition);
							clientPosition[2]+=35;	
							TE_SetupBeamPoints(iPosition,clientPosition,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,{255,000,000,255},20);
							TE_SendToAll();
						}
					}
				}
			}
		}
		if (ability==1)
		{
			if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client))
			{
				new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_TCLAP);
				if(skill_level>0)
				{
					if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_TCLAP,false))
					{
						War3_CooldownMGR(client,6.0,thisRaceID,SKILL_TCLAP,_,_);
						new Float:position111[3];
						GetClientAbsOrigin(client, position111);
						position111[2]+=10;
						TE_SetupBeamRingPoint(position111,0.0,tclapdist[skill_level]*2.0,BeamSprite,HaloSprite,0,15,0.3,20.0,3.0,{100,100,150,255},20,0);
						TE_SendToAll();
						for(new i=0;i<=MaxClients;i++)
						{
							if(ValidPlayer(i,true)&&i!=client)
							{
								new clientteam=GetClientTeam(client);
								new iteam=GetClientTeam(i);
								if(iteam!=clientteam)
								{
									new Float:iPosition[3];
									new Float:clientPosition[3];
									GetClientAbsOrigin(i, iPosition);
									GetClientAbsOrigin(client, clientPosition);
									if(!IsSkillImmune(i))
									{
										if(GetVectorDistance(iPosition,clientPosition)<tclapdist[skill_level])
										{
											War3_DealDamage(i,tclapdamage[skill_level],client,DMG_CRUSH,"thunder clap",_,W3DMGTYPE_MAGIC);
											War3_SetBuff(i,fMaxSpeed,thisRaceID,0.5);
											CreateTimer(3.0,tclapslow,i);
											War3_WeaponRestrictTo(i,thisRaceID,"weapon_knife",2);
											CreateTimer(1.0,regainweapons,i);
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
	// else
	// {
		// PrintHintText(client,"%T","Can not cast",client);
	// }
}

public Action:tclapslow(Handle:timer,any:i)
{
	War3_SetBuff(i,fMaxSpeed,thisRaceID,1.0);
}

public Action:regainweapons(Handle:timer,any:i)
{
	War3_WeaponRestrictTo(i,thisRaceID,"");
}

public Action:overheal(Handle:timer,any:a)
{
	for(new i=0;i<=MaxClients;i++)
	{
		new IRace = War3_GetRace(i);
		if(ValidPlayer(i,true) && IRace==thisRaceID)
		{
			new skill_level=War3_GetSkillLevel(i,thisRaceID,ULT_AVATAR);
			if(skill_level>0)
			{
				if(GetClientHealth(i)>100)
				{
					SetEntityHealth(i, GetClientHealth(i)-1);
				}
				else
				{
					War3_SetBuff(i,bImmunitySkills,thisRaceID,false);
				}
			}
		}
	}
}
