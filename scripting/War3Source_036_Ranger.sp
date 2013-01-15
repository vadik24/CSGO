/**
* File: War3Source_Ranger.sp
* Description: The Ranger race for War3Source.
* Author(s): VoGon
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>

// War3Source stuff
new thisRaceID;

//Trackless skill
new Float:TracklessAlphaTF[5]={1.0,0.84,0.68,0.56,0.40};
new Float:TracklessAlphaCS[5]={1.0,0.90,0.8,0.7,0.6};

//Poison Ivy aka shadowstrike
new String:shadowstrikestr[]={"music/war3source/shadowstrikebirth.mp3"};
new const ShadowStrikeInitialDamage=20;
new const ShadowStrikeTrailingDamage=5;
new Float:ShadowStrikeChanceArr[]={0.0,0.05,0.1,0.15,0.2};
new ShadowStrikeTimes[]={0,2,3,4,5};
new BeingStrikedBy[MAXPLAYERS];
new StrikesRemaining[MAXPLAYERS];

//Heal wounds aka healinge

new HealineAmountArr[]={0,1,2,3,4};
new Float:HealineDistanceArr[]={0.0,300.0,400.0,500.0,600.0};

//Wood skin
new Float:EvadeChance[5]={0.0,0.05,0.10,0.15,0.20};

//Skills definition

new SKILL_TRACKLESS,SKILL_WOODSKIN,SKILL_POISONIVY,SKILL_HEALWOUNDS;

public Plugin:myinfo = 
{
	name = "War3Source Race - Wood Ranger",
	author = "Vogon",
	description = "The Wood Ranger race for War3Source.",
	version = "1.0.0.0",
	url = "http://www.twkgaming.com"
};

// War3Source Functions
public OnPluginStart()
{
	CreateTimer(1.0,CalcHexHeaes,_,TIMER_REPEAT);
	
	LoadTranslations("w3s.race.ranger.phrases");
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==10)
	{
		thisRaceID=War3_CreateNewRaceT("ranger");
		SKILL_TRACKLESS=War3_AddRaceSkillT(thisRaceID,"Trackless",false,4);
		SKILL_WOODSKIN=War3_AddRaceSkillT(thisRaceID,"WoodSkin",false,4);
		SKILL_POISONIVY=War3_AddRaceSkillT(thisRaceID,"PoisonIvy",false,4);
		SKILL_HEALWOUNDS=War3_AddRaceSkillT(thisRaceID,"HealWounds",false,4);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnMapStart()
{
	////War3_PrecacheSound(shadowstrikestr);
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
		
	}
	else
	{
		if(IsPlayerAlive(client))
		{
			ActivateSkills(client);
		}
	}
}

public ActivateSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_TRACKLESS);
		new Float:alpha=(War3_GetGame()==Game_CS)?TracklessAlphaCS[skilllevel]:TracklessAlphaTF[skilllevel];
		if(SKILL_TRACKLESS==1){
			War3_ChatMessage(client,"%T","You fade slightly into the woods",client);
		}else if(SKILL_TRACKLESS==2){
			War3_ChatMessage(client,"%T","You fade well into the woods",client);
		}else if(SKILL_TRACKLESS==3){
			War3_ChatMessage(client,"%T","You fade greatly into the woods",client);
		}else{
			War3_ChatMessage(client,"%T","You fade dramatically into the woods",client);
		}
		//War3_ChatMessage(client,"You fade %s into the woods.",(SKILL_TRACKLESS==1)?"slightly":(SKILL_TRACKLESS==2)?"well":(SKILL_TRACKLESS==3)?"greatly":"dramatically");
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
	}
}

public Action:CalcHexHeaes(Handle:timer,any:userid)
{
	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true))
			{
				if(War3_GetRace(i)==thisRaceID)
				{
					Heae(i); //check leves later
				}
			}
		}
	}
}


public Heae(client)
{
	//assuming client exists and has this race
	new skill = War3_GetSkillLevel(client,thisRaceID,SKILL_HEALWOUNDS);
	if(skill>0)
	{
		new Float:dist = HealineDistanceArr[skill];
		new HealerTeam = GetClientTeam(client);
		new Float:HealerPos[3];
		GetClientAbsOrigin(client,HealerPos);
		new Float:VecPos[3];
		
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)==HealerTeam)
			{
				GetClientAbsOrigin(i,VecPos);
				if(GetVectorDistance(HealerPos,VecPos)<=dist)
				{
					War3_HealToMaxHP(i,HealineAmountArr[skill]);
				}
			}
		}
	}
}
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		if(IsPlayerAlive(attacker)&&IsPlayerAlive(victim)&&GetClientTeam(victim)!=GetClientTeam(attacker))
		{
			if(War3_GetRace(attacker)==thisRaceID)
			{
				//Poison Ivy poison
				new Float:chance_mod=W3ChanceModifier(attacker);
				/// CHANCE MOD BY VICTIM
				new skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_POISONIVY);
				if(skill_level>0 && StrikesRemaining[victim]==0 && GetRandomFloat(0.0,1.0)<=chance_mod*ShadowStrikeChanceArr[skill_level])
				{
					PrintHintText(victim,"%T","Attacked By Poison Ivy",victim);
					PrintHintText(attacker,"%T","Activated Poison Ivy",attacker);
					
					BeingStrikedBy[victim]=attacker;
					StrikesRemaining[victim]=ShadowStrikeTimes[skill_level];
					War3_DealDamage(victim,ShadowStrikeInitialDamage,attacker,DMG_BULLET,"poisonivy");
					W3FlashScreen(victim,RGBA_COLOR_GREEN);
					
					//EmitSoundToAll(shadowstrikestr,attacker);
					//EmitSoundToAll(shadowstrikestr,attacker);
					CreateTimer(1.0,ShadowStrikeLoop,GetClientUserId(victim));
				}
			}
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
			//new race_attacker=War3_GetRace(attacker);
			new race_victim=War3_GetRace(victim);
			
			new skill_level_evasion=War3_GetSkillLevel(victim,thisRaceID,SKILL_WOODSKIN);
			if(race_victim==thisRaceID && skill_level_evasion>0 ) 
			{
				if(GetRandomFloat(0.0,1.0)<=EvadeChance[skill_level_evasion] && !W3HasImmunity(attacker,Immunity_Skills))
				{
					W3FlashScreen(victim,RGBA_COLOR_BLUE);
					
					War3_DamageModPercent(0.0); //NO DAMAMGE
					
					W3MsgEvaded(victim,attacker);
					if(War3_GetGame()==Game_TF)
					{
						decl Float:pos[3];
						GetClientEyePosition(victim, pos);
						pos[2] += 4.0;
						War3_TF_ParticleToClient(0, "miss_text", pos);
					}
				}
			}
		}
	}
}

public Action:ShadowStrikeLoop(Handle:timer,any:userid)
{
	new victim = GetClientOfUserId(userid);
	if(StrikesRemaining[victim]>0 && ValidPlayer(BeingStrikedBy[victim]) && ValidPlayer(victim,true))
	{
		War3_DealDamage(victim,ShadowStrikeTrailingDamage,BeingStrikedBy[victim],DMG_BULLET,"poisonivy");
		StrikesRemaining[victim]--;
		W3FlashScreen(victim,RGBA_COLOR_GREEN);
		CreateTimer(1.0,ShadowStrikeLoop,userid);
	}
}
