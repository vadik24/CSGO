/** 
* File: War3Source_Footman.sp
* Description: The Footman for War3Source.
* Author(s): TeacherCreature
*/

#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
new String:TrollModel[]="models/player/slow/fallout_3/power_armor/slow.mdl";
new String:TrollModel2[]="models/player/slow/fallout_3/power_armor_outcast/slow.mdl";
public Plugin:myinfo = 
{
	name = "War3Source Race - Footman",
	author = "[Oddity]TeacherCreature",
	description = "Footman for War3Source.",
	version = "1.0.8.9",
	url = "http://warcraft-source.net/"
}

new thisRaceID;

//Defend
new bool:bDefend[MAXPLAYERS];
new Float:DefArr[]={0.0,0.21,0.23,0.25,0.27,0.29,0.31,0.33,0.35};

//Mithril Forged Sword
new Float:DmgArr[]={1.0,1.02,1.04,1.06,1.08,1.1,1.12,1.14,1.16};

//Mithril Plating
new Float:DmgRed[]={0.0,0.02,0.04,0.06,0.08,0.1,0.12,0.14,0.16};

//SKILLS and ULTIMATE
new DEFEND, SWORD, PLATING;

public OnMapStart()
{
	PrecacheModel(TrollModel, true);
	PrecacheModel(TrollModel2, true);
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==177){
		thisRaceID=War3_CreateNewRace("Footman","footman");
		DEFEND=War3_AddRaceSkill(thisRaceID,"Defend (Ability)","Defensive Stance - less dmg and movement",false,8);
		SWORD=War3_AddRaceSkill(thisRaceID,"Mithril Forged Sword (Passive)","Extra Damage",false,8);
		PLATING=War3_AddRaceSkill(thisRaceID,"Mithril Plating (Passive)","Reduced Damage",false,8);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"");
		bDefend[client]=false;
		W3ResetAllBuffRace(client,thisRaceID);
	}
	if(newrace==thisRaceID)
	{
		if(ValidPlayer(client,true))
		{
			if(GetClientTeam(client)==3)
			{
			SetEntityModel(client, TrollModel);
			}
			if(GetClientTeam(client)==2)
			{
			SetEntityModel(client, "models/player/slow/fallout_3/power_armor_outcast/slow.mdl");
			}
		}
	}
}

public OnWar3EventSpawn(client)
{
	if (War3_GetRace(client) == thisRaceID&&ValidPlayer(client,true)){
		bDefend[client]=false;
		War3_SetBuff(client,fSlow,thisRaceID,1.0);
			if(GetClientTeam(client)==3)
			{
			SetEntityModel(client, "models/player/slow/fallout_3/power_armor/slow.mdl");
			}
			if(GetClientTeam(client)==2)
			{
			SetEntityModel(client, "models/player/slow/fallout_3/power_armor_outcast/slow.mdl");
			}
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
		if(!Silenced(client)){
			new dlevel=War3_GetSkillLevel(client,thisRaceID,DEFEND);
			if(dlevel>0){
				if(bDefend[client]){
					bDefend[client]=false;
					War3_SetBuff(client,fSlow,thisRaceID,1.0);
					W3FlashScreen(client,{55,200,55,200},0.1,1.0,FFADE_OUT);
					PrintHintText(client,"You leave your defensive stance");
				}
				else 
				{
					bDefend[client]=true;
					War3_SetBuff(client,fSlow,thisRaceID,0.8);
					W3FlashScreen(client,{55,55,200,200},0.1,0.5,FFADE_OUT);
					PrintHintText(client,"Defend!");
				}
			}
			else
			{
				PrintHintText(client, "Level Defend first");
			}
		}
		else
		{
			PrintHintText(client, "Silenced!");
		}
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam){
			new race_attacker=War3_GetRace(attacker);
			new race_victim=War3_GetRace(victim);
			new dlevel=War3_GetSkillLevel(victim,thisRaceID,DEFEND);
			new slevel=War3_GetSkillLevel(attacker,thisRaceID,SWORD);
			new plevel=War3_GetSkillLevel(victim,thisRaceID,PLATING);
			if(race_attacker==thisRaceID){
				if(!Hexed(attacker)){
					if(GetRandomFloat(0.0,1.0)<0.4 && slevel>0){
						War3_DamageModPercent(DmgArr[slevel]);
					}
				}
			}
			if(race_victim==thisRaceID){
				new Float:red;
				red=1.0;
				if(GetRandomFloat(0.0,1.0)<0.4 && plevel>0){
					red=red-DmgRed[plevel];
					PrintToConsole(attacker, "Damage Reduced by plating");
					PrintToConsole(victim, "Damage Reduced by plating");
				}
				if(bDefend[victim]){
					red=red-DefArr[dlevel];
					PrintToConsole(attacker, "Damage Reduced by defensive stance");
					PrintToConsole(victim, "Damage Reduced in defend stance");
				}
				War3_DamageModPercent(red);
			}
		}
	}
}