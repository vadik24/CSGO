 /**
* File: War3Source_Dwarven Rifleman.sp
* Description: The Dwarven Rifleman unti for War3Source.
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
#include "W3SIncs/AmmoControl" 

new thisRaceID;
//new MyWeaponsOffset,ClipOffset,AmmoOffset;
new Handle:ultCooldownCvar;
//skill 1
new LongRifleClip[9]={10,12,14,16,18,20,22,24,26};
new LongRifleAmmo[9]={30,40,50,60,70,80,90,100,110};

//skill 2
new Float:GunPowderPercent[9]={0.0,0.2,0.22,0.24,0.26,0.28,0.30,0.32,0.35};
new Float:GunPowderChance[9]={0.0,0.3,0.35,0.4,0.45,0.5,0.55,0.6,0.65};

//skill 3
new Float:DragonHideSpeedArr[9]={1.0,0.96,0.94,0.92,0.9,0.88,0.86,0.84,0.82};
new DragonHideHealthArr[9]={0,15,20,25,30,35,40,45,50};

//skill 4
new bool:bTakeAim[66];
new String:takeaimSound1[]="music/war3source/particle_suck1.mp3";
new String:takeaimSound2[]="music/weapons/explode5.mp3";

new SKILL_LONGRIFLE, SKILL_GUNPOWDER, SKILL_DRAGONHIDE, ULT_TAKEAIM;

public Plugin:myinfo = 
{
	name = "War3Source Race - Dwarven Rifleman",
	author = "[Oddity]TeacherCreature",
	description = "The Dwarven Rifleman race for War3Source.",
	version = "1.0.0.0",
	url = "warcraft-source.net"
}

public OnPluginStart()
{
	HookEvent("weapon_fire", WeaponFire);
	//MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
	//ClipOffset=FindSendPropOffs("CBaseCombatWeapon","m_iClip1");
	//AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
	ultCooldownCvar=CreateConVar("war3_dr_takeaim_cooldown","15.0","Cooldown for Take Aim");
	
	LoadTranslations("w3s.race.dr.phrases");
}

public OnMapStart()
{
	/*PrecacheSound("weapons/explode5.mp3",false);
	if(!////War3_PrecacheSound(takeaimSound1)){
		SetFailState("[War3Source DWARVEN RIFLEMAN] FATAL ERROR! FAILURE TO PRECACHE SOUND %s!!! CHECK TO SEE IF U HAVE THE SOUND FILES",takeaimSound1);
	}
	*/
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==4)
	{
		thisRaceID=War3_CreateNewRaceT("dr");
		SKILL_LONGRIFLE=War3_AddRaceSkillT(thisRaceID,"LongRifle",false,8);
		SKILL_GUNPOWDER=War3_AddRaceSkillT(thisRaceID,"GunPowder",false,8);
		SKILL_DRAGONHIDE=War3_AddRaceSkillT(thisRaceID,"DragonHide",false,8);
		ULT_TAKEAIM=War3_AddRaceSkillT(thisRaceID,"TakeAim",true,1); 
		War3_CreateRaceEnd(thisRaceID);
	}
	
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
		//========new=========
		War3_SetAmmoControl(client, "");
		//========new=========
	}
	if(newrace==thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_awp,weapon_smokegrenade");
		if(ValidPlayer(client,true))
		{
			//GivePlayerItem(client,"weapon_awp");
			//CreateTimer(0.1,setawpclip,client);
			new skill_long=War3_GetSkillLevel(client,thisRaceID,SKILL_LONGRIFLE);
			new newclip = LongRifleClip[skill_long];
			new newammo = LongRifleAmmo[skill_long];
			War3_SetAmmoControl(client, "weapon_awp", newammo, newclip, true);
			CreateTimer(2.0,smoke,client);
			GivePlayerItem(client,"weapon_awp");
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
			new Float:chance_mod=W3ChanceModifier(attacker);
			// Take Aim
			new skill_level_takeaim=War3_GetSkillLevel(attacker,thisRaceID,ULT_TAKEAIM);
			if(race_attacker==thisRaceID && bTakeAim[attacker] && skill_level_takeaim>0 && !W3HasImmunity(victim,Immunity_Ultimates)&&!Silenced(attacker))
			{
				War3_DamageModPercent(2.0);
				W3FlashScreen(victim,RGBA_COLOR_RED);
				bTakeAim[attacker]=false;
				PrintHintText(attacker,"%T","DOUBLE DAMAGE",attacker);
			}
			// Gun Powder
			new skill_level_gunpowder=War3_GetSkillLevel(attacker,thisRaceID,SKILL_GUNPOWDER);
			if(race_attacker==thisRaceID && skill_level_gunpowder>0 && !Silenced(attacker))
			{
				if(GetRandomFloat(0.0,1.0)<=GunPowderChance[skill_level_gunpowder]*chance_mod && !W3HasImmunity(victim,Immunity_Skills))
				{
					//EmitSoundToAll(takeaimSound2,attacker);
					War3_DamageModPercent(GunPowderPercent[skill_level_gunpowder]+1.0);
					//PrintToConsole(attacker,"+%d GUNPOWDER DAMAGE (SDKhooks)");
					W3FlashScreen(victim,RGBA_COLOR_RED);
				}
			}
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client))
	{
		new ultLevel=War3_GetSkillLevel(client,thisRaceID,ULT_TAKEAIM);
		if(ultLevel>0)
		{
			if(!Silenced(client))
			{
				new Float:cooldown=GetConVarFloat(ultCooldownCvar);
				if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TAKEAIM,true ) && !bTakeAim[client])
				{	
					//EmitSoundToAll(takeaimSound1,client);
					bTakeAim[client]=true;
					SetEntityMoveType(client,MOVETYPE_NONE);
					PrintHintText(client,"%T","Take Aim",client);
					////EmitSoundToAll(takeaimSound1,client);
					War3_CooldownMGR(client,cooldown,thisRaceID,ULT_TAKEAIM,_,_);
				}
			}
			else
			{
				PrintHintText(client,"%T","Silenced: Can Not Cast",client); 
			}
		}
		else
		{
			PrintHintText(client,"%T","Level Your Ultimate First",client);
		}	
	}
}

public Action:WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new index=GetClientOfUserId(userid);
	if(index>0)
	{
		new race=War3_GetRace(index);
		if(race==thisRaceID&&War3_GetGame()!=Game_TF&&bTakeAim[index])
		{
			CreateTimer(0.7,removeaim,index);
			SetEntityMoveType(index,MOVETYPE_WALK);
		}
	}
}	

public Action:removeaim(Handle:h,any:index){
	bTakeAim[index]=false;
}
public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		bTakeAim[client]=false;
		new skill_drag=War3_GetSkillLevel(client,thisRaceID,SKILL_DRAGONHIDE);
		if(skill_drag)
		{
			// Dragon Hide
			new hpadd=DragonHideHealthArr[skill_drag];
			SetEntityHealth(client,hpadd);
			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,hpadd);

			//War3_ChatMessage(client,"+%d HP",hpadd);
			new Float:speed=DragonHideSpeedArr[skill_drag];
			War3_SetBuff(client,fSlow,thisRaceID,speed);
		}
		
		GivePlayerItem(client,"weapon_awp");
		//CreateTimer(0.1,setawpclip,client);
		new skill_long=War3_GetSkillLevel(client,thisRaceID,SKILL_LONGRIFLE);
		new newclip = LongRifleClip[skill_long];
		new newammo = LongRifleAmmo[skill_long];
		War3_SetAmmoControl(client, "weapon_awp", newammo, newclip, true);
		/*if(skill_long)
		{
			for(new s=5;s<6;s++)
			{
				SetEntData(client,AmmoOffset+(s*4),999,4);
			}
				for(new s=0;s<10;s++){
					new ent=GetEntDataEnt2(client,MyWeaponsOffset+(s*4));
					if(ent>0 && IsValidEdict(ent))
					{
						new String:ename[64];
						GetEdictClassname(ent,ename,64);
						PrintToChatAll("ename %s",ename);
						if(StrEqual(ename,"weapon_awp") )
						{
							PrintToChatAll("[SM] %s offset: %d",ename, s);
							new offset = FindDataMapOffs(client,"m_iAmmo");
							new ammo = GetEntData(client, offset);
							PrintToChatAll("[SM] weapon ammo: %d", ammo);
							
							
							SetEntData(wep_ent,ClipOffset,LongRifleAmmo[skill_long],4);
							PrintToChatAll("%d",LongRifleAmmo[skill_long]);
							PrintToChatAll("%d",GetEntData(wep_ent,ClipOffset,4));
							//PrintToChatAll("%d",GetEntData(wep_ent,ClipOffset,4));
							break;
						}
					}
					
				}
		}
		*/
		CreateTimer(2.0,smoke,client);
	}
}
/*
public Action:setawpclip(Handle:h,any:client){
	new skill_long=War3_GetSkillLevel(client,thisRaceID,SKILL_LONGRIFLE);
	for(new s=0;s<10;s++){
		new ent=GetEntDataEnt2(client,MyWeaponsOffset+(s*4));
		if(ent>0 && IsValidEdict(ent))
		{
			new String:ename[64];
			GetEdictClassname(ent,ename,64);
			if(StrEqual(ename,"weapon_awp") )
			{
				//new offset = FindDataMapOffs(client,"m_iAmmo");
				//new ammo = GetEntData(client, offset);
				SetEntData(ent,ClipOffset,LongRifleAmmo[skill_long],4);
				break;
			}
		}
	}
}
*/

/*
* AMMO TYPE , offset is i_mAmmo * (number below*4)
*  weapon_ak47 Offset: 2 - Count: 90
Weapon: weapon_aug Offset: 2 - Count: 90
Weapon: weapon_awp Offset: 5 - Count: 30
Weapon: weapon_deagle Offset: 1 - Count: 35
Weapon: weapon_elite Offset: 6 - Count: 120
Weapon: weapon_famas Offset: 3 - Count: 90
Weapon: weapon_fiveseven Offset: 10 - Count: 100
Weapon: weapon_flashbang Offset: 12 - Count: 1
Weapon: weapon_g3sg1 Offset: 2 - Count: 90
Weapon: weapon_galil Offset: 3 - Count: 90
Weapon: weapon_glock Offset: 6 - Count: 120
Weapon: weapon_hegrenade Offset: 11 - Count: 1
Weapon: weapon_m249 Offset: 4 - Count: 200
Weapon: weapon_m3 Offset: 7 - Count: 32
Weapon: weapon_m4a1 Offset: 3 - Count: 90
Weapon: weapon_mac10 Offset: 8 - Count: 100
Weapon: weapon_mp5navy Offset: 6 - Count: 120
Weapon: weapon_p228 Offset: 9 - Count: 52
Weapon: weapon_p90 Offset: 10 - Count: 100
Weapon: weapon_ssg08 Offset: 2 - Count: 90
Weapon: weapon_sg550 Offset: 3 - Count: 90
Weapon: weapon_sg552 Offset: 3 - Count: 90
Weapon: weapon_smokegrenade Offset: 13 - Count: 1
Weapon: weapon_tmp Offset: 6 - Count: 120
Weapon: weapon_ump45 Offset: 8 - Count: 100
Weapon: weapon_usp Offset: 8 - Count: 100
Weapon: weapon_xm1014 Offset: 7 - Count: 32*/

public Action:smoke(Handle:t,any:client)
{
	if (War3_GetRace(client)== thisRaceID && ValidPlayer(client))
	{
		GivePlayerItem(client,"weapon_smokegrenade");
	}	
}
