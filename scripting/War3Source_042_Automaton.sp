/**
* File						: War3Source_Automaton.sp
* Description				: The Automaton race for War3Source.
* Author(s)					: Schmarotzer
* Original ES Idea			: HOLLIDAY
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

new thisRaceID;

// skill 1
new Float:DisintegrationChance[6] = {0.0, 0.7, 0.14, 0.21, 0.28, 0.35};

// skill 2
new Float:ConfiscationChance[6] = {0.0, 0.10, 0.15, 0.20, 0.25, 0.30};
new Float:ConfiscationDuration[6] = {0.0, 3.0, 5.0, 7.0, 9.0, 11.0};
new bool:bConfMode[MAXPLAYERS];

// skill3
new MedicHealth[6]={0,10,15,20,25,30};
new String:MedicSystemSnd[] = "hl1/fvox/power_restored.mp3";
new String:FlatlineSnd[] = "hl1/fvox/flatline.mp3";

// ultimate
new Float:AimDuration[6] = {0.0, 3.0, 4.0, 5.0, 6.0, 7.0};
new Float:AimDistance[6] = {0.0, 550.0, 700.0, 850.0, 1000.0, 1150.0};
new String:UltSnd[] = "npc/combine_gunship/attack_start2.mp3";
new bool:bAimMode[MAXPLAYERS];

new SKILL_DISINTEGRATION,SKILL_CONFISCATION,SKILL_MEDIC,ULT_TARGET;

public Plugin:myinfo = 
{
	name = "War3Source Race - Automaton",
	author = "Schmarotzer",
	description = "The Automaton race for War3Source.",
	version = "1.0.0.0",
	url = "http://css.bashtel.ru"
};

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==10)
	{
		thisRaceID				= War3_CreateNewRaceT("automaton");
		SKILL_DISINTEGRATION	= War3_AddRaceSkillT(thisRaceID,"Disintegration",false,5);
		SKILL_CONFISCATION		= War3_AddRaceSkillT(thisRaceID,"Confiscation",false,5);
		SKILL_MEDIC				= War3_AddRaceSkillT(thisRaceID,"MedicSystem",false,5);
		ULT_TARGET				= War3_AddRaceSkillT(thisRaceID,"TargetSystem",true,5); 
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnPluginStart()
{
	
	LoadTranslations("w3s.race.automaton.phrases");
}

public OnMapStart()
{
	////War3_PrecacheSound(MedicSystemSnd);
	////War3_PrecacheSound(FlatlineSnd);
	////War3_PrecacheSound(UltSnd);
}

public OnWar3EventSpawn(client)
{
	new ClientRace = War3_GetRace(client);
	if (ClientRace == thisRaceID)
	{
		bAimMode[client] = false;
		bConfMode[client] = false;
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_elite,weapon_knife");
		GivePlayerItem(client, "weapon_elite");
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
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_elite,weapon_knife");
		if(ValidPlayer(client))
		{
			GivePlayerItem(client, "weapon_elite");
		}
	}
}

// ▄█████████████████ █ ███████████████████████████████████████▄
// ██████████████████████ DISINTEGRATION █████████████████████
// ▀█████████████████████████████████████████████████████████▀
public OnWar3EventDeath(victim,attacker)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker))
	{
		new VRace = War3_GetRace(victim);
		// new ARace = War3_GetRace(attacker);
		if(VRace==thisRaceID)
		{
			new skill_level_dis=War3_GetSkillLevel(victim,thisRaceID,SKILL_DISINTEGRATION);
			if(skill_level_dis>0 && War3_Chance(DisintegrationChance[skill_level_dis]) && !IsUltImmune(attacker) && !Silenced(victim))
			{
				// Destroy all weapons of attacker
				if(IsPlayerAlive(attacker))
				{
					new iWeapon;
					iWeapon = GetPlayerWeaponSlot(attacker,CS_SLOT_PRIMARY);
					if (iWeapon != -1)
						RemovePlayerItem(attacker,iWeapon);
					iWeapon = GetPlayerWeaponSlot(attacker,CS_SLOT_SECONDARY);
					if (iWeapon != -1)
						RemovePlayerItem(attacker,iWeapon);
					do
					{
						iWeapon = GetPlayerWeaponSlot(attacker,CS_SLOT_GRENADE);
						if (iWeapon != -1)
							RemovePlayerItem(attacker,iWeapon);
					}
					while (iWeapon != -1);
					FakeClientCommand(attacker,"use weapon_knife");
					PrintHintText(attacker,"%T","[Disintegration] All your weapons disintegrated by Automaton!",attacker);
				}
			}
			//EmitSoundToAll(FlatlineSnd,attacker);
		}
	}
}


// ▄█████████████████████████████████████████████████████████▄
// ███████████████████████ CONFISCATION ██████████████████████
// ▀█████████████████████████████████████████████████████████▀
public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(attacker,true) && ValidPlayer(victim,true))
	{
		new VTeam = GetClientTeam(victim);
		new ATeam = GetClientTeam(attacker);
		new ARace = War3_GetRace(attacker);
		if(VTeam!=ATeam && ARace==thisRaceID && !bConfMode[attacker])
		{
			if(!bAimMode[attacker])
			{
				new skill_level_conf = War3_GetSkillLevel(attacker,thisRaceID,SKILL_CONFISCATION);
				if(skill_level_conf>0 && War3_Chance(ConfiscationChance[skill_level_conf]) && !IsSkillImmune(victim))
				{
					/* new VWeapon = War3_CachedWeapon(victim,CS_SLOT_PRIMARY);
					if(VWeapon!=-1)
					{
						new String:wep_check[64];
						War3_CachedDeadWeaponName(victim,CS_SLOT_PRIMARY,wep_check,sizeof[wep_check]);
						War3_WeaponRestrictTo(attacker,thisRaceID,"%s,weapon_elite,weapon_knife",wep_check);
						GivePlayerItem(attacker,wep_check);
						FakeClientCommand(attacker,"use %s",wep_check);
						CreateTimer(ConfiscationDuration[skill_level_conf],StandardMode,attacker);
					} */
					new VWeapon = W3GetCurrentWeaponEnt(victim);
					if(VWeapon>0 && IsValidEdict(VWeapon))
					{
						decl String:WeaponName[32];
						GetEdictClassname(VWeapon, WeaponName, sizeof(WeaponName));
						if(StrContains(WeaponName,"weapon_knife",false)<0 &&
							StrContains(WeaponName,"weapon_glock",false)<0 &&
							StrContains(WeaponName,"weapon_usp",false)<0 &&
							StrContains(WeaponName,"weapon_p228",false)<0 &&
							StrContains(WeaponName,"weapon_deagle",false)<0 &&
							StrContains(WeaponName,"weapon_fiveseven",false)<0 &&
							StrContains(WeaponName,"weapon_elite",false)<0 &&
							StrContains(WeaponName,"weapon_c4",false)<0)
						{
							PrintHintText(victim,"%T","[Confiscation] Automaton confiscated your primary weapon!",victim);
							PrintHintText(attacker,"%T","[Confiscation] You confiscated enemy's weapon!",attacker);
							bConfMode[attacker] = true;
							
							W3DropWeapon(victim,VWeapon);
							decl String:WeaponsList[64];
							Format(WeaponsList,sizeof(WeaponsList),"%s,weapon_elite,weapon_knife",WeaponName);
							War3_WeaponRestrictTo(attacker,thisRaceID,WeaponsList);
							GivePlayerItem(attacker,WeaponName);
							FakeClientCommand(attacker,"use %s",WeaponName);
							CreateTimer(ConfiscationDuration[skill_level_conf],StandardMode,attacker);
						}
					}
				}
			}
			else
			{
				War3_DamageModPercent(1.2);
			}
		}
	}
}

// ▄█████████████████████████████████████████████████████████▄
// ██████████████████████ STANDARD MODE ██████████████████████
// ▀█████████████████████████████████████████████████████████▀
public Action:StandardMode(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		bAimMode[client] = false;
		bConfMode[client] = false;
		new iWeapon;
		iWeapon = GetPlayerWeaponSlot(client,CS_SLOT_PRIMARY);
		if (iWeapon != -1)
			RemovePlayerItem(client,iWeapon);
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_elite,weapon_knife");
		FakeClientCommand(client,"use weapon_elite");
	}
}


// ▄█████████████████████████████████████████████████████████▄
// █████████████████ AUTOMATON MEDIC SYSTEM ██████████████████
// ▀█████████████████████████████████████████████████████████▀
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		if(ability==0 && pressed && IsPlayerAlive(client))
		{
			new skill_level_medic=War3_GetSkillLevel(client,thisRaceID,SKILL_MEDIC);
			if(skill_level_medic>0)
			{
				if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_MEDIC,true))
				{
					new AutomatonHealth = GetClientHealth(client);
					if(AutomatonHealth<160)
					{
						new AddHP = MedicHealth[skill_level_medic];
						SetEntityHealth(client,AutomatonHealth+AddHP);
						//EmitSoundToAll(MedicSystemSnd,client);
						War3_CooldownMGR(client,20.0,thisRaceID,SKILL_MEDIC,_,_);
						PrintHintText(client,"%T","[Medical System] You gained [amount] HP",client,AddHP);
					}
					else
					{
						PrintHintText(client,"%T","[Medical System] Medical assistance is not required",client);
					}
				}
			}
			else
			{
				W3MsgUltNotLeveled(client);
			}
		}
	}
}



// ▄█████████████████████████████████████████████████████████▄
// █████████████████ AUTOMATIC TARGET SYSTEM █████████████████
// ▀█████████████████████████████████████████████████████████▀
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && IsPlayerAlive(client) && pressed)
	{
		new ult_level_target = War3_GetSkillLevel(client,race,ULT_TARGET);
		if(ult_level_target>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TARGET,true))
			{
				new ClientTeam = GetClientTeam(client);
				new Float:posVec[3];
				GetClientAbsOrigin(client,posVec);
				new Float:otherVec[3];
				// new Float:bestTargetDistance = 3000.0;
				new Float:bestTargetDistance = AimDistance[ult_level_target];
				new bestTarget;
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true))
					{
						new ITeam = GetClientTeam(i);
						if(ITeam!=ClientTeam && !IsUltImmune(i))
						{
							GetClientAbsOrigin(i,otherVec);
							new Float:dist=GetVectorDistance(posVec,otherVec);
							// if(dist<bestTargetDistance && W3LOS(client,i))
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
					SetAim(client,bestTarget,63.0);
					PrintHintText(client,"%T","[Auto-Aim] Automatical Aiming Mode detected enemy! Kill him!",client);
				}
				bAimMode[client] = true;
				War3_WeaponRestrictTo(client,thisRaceID,"weapon_sg550,weapon_elite,weapon_knife");
				GivePlayerItem(client,"weapon_sg550");
				// War3_DamageModPercent(5.0);
				FakeClientCommand(client,"use weapon_sg550");
				CreateTimer(AimDuration[ult_level_target],StandardMode,client);
				War3_CooldownMGR(client,20.0,thisRaceID,ULT_TARGET,_,_);
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}








// ▄█████████████████████████████████████████████████████████▄
// ███████████████████████ S T O C K S ███████████████████████
// ▀█████████████████████████████████████████████████████████▀
/**
 * Make a player aim at another player.
 *
 * @param client		client
 * @param aim_at 		Client to aim
 * @param add 			Add to z
 * @return			  	No return
 */
stock SetAim( client, aim_at, Float:add )
{
	new Float:pos1[3];
	new Float:pos2[3];
	new Float:vecang[3];
	new Float:ang[3];
	
	GetClientAbsOrigin( client, pos1 );
	GetClientAbsOrigin( aim_at, pos2 );
	
	pos1[2] += add;
	pos2[2] += add;
	
	SubtractVectors( pos2, pos1, vecang );
	
	GetVectorAngles( vecang, ang );
	
	ang[2] = 0.0;
	
	TeleportEntity( client, NULL_VECTOR, ang, NULL_VECTOR );
}


