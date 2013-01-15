/**
 * vim: set ai et ts=4 sw=4 :
 * File: War3Source_Headcrab.sp
 * Description: The HeadCrab race for War3Source.
 * Author(s): Vladislav Dolgov
 */

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks> 

#include <sdkhooks>

new thisRaceID;

new SKILL_LONGJUMP,SKILL_FANGS,SKILL_FOURLEGS,SKILL_LATCH;

//skill 3
new const FangsInitialDamage=20;
new const FangsTrailingDamage=5;
new Float:FangsChanceArr[]={0.0,0.05,0.1,0.15,0.2};
new FangsTimes[]={0,2,3,4,5};
new BeingFangedBy[66];
new FangsRemaining[66];

//latch
new bool:bRound[66];
new BeingLatchedBy[66];
// Target getting killed
new LatchKilled[66];
new Float:LatchChanceArr[]={0.0,0.14,0.16,0.18,0.20};
new Float:LatchonDamageMin[]={0.0,3.0,4.0,5.0,6.0};
new Float:LatchonDamageMax[]={0.0,7.0,8.0,9.0,10.0};

new String:Fangsstr[]="npc/roller/mine/rmine_blades_out2.mp3"; // Не проверенно {}

public Plugin:myinfo = 
{
	name = "War3Source Race - Headcrab",
	author = "[Oddity]TeacerCreature",
	description = "Headcrab race for War3Source.",
	version = "1.0.0",
	url = "http://warcraft-source.net/"
};

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==70)
	{
		thisRaceID=War3_CreateNewRaceT("headcrab");
		SKILL_LONGJUMP=War3_AddRaceSkillT(thisRaceID,"1",false,4);
		SKILL_FOURLEGS=War3_AddRaceSkillT(thisRaceID,"2",false,4);
		SKILL_FANGS=War3_AddRaceSkillT(thisRaceID,"3",false,4);
		SKILL_LATCH=War3_AddRaceSkillT(thisRaceID,"4",false,4);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnPluginStart()
{
	HookEvent("player_jump", Event_PlayerJump);
	HookEvent("round_start",RoundStartEvent);
	HookEvent("player_footstep", Event_FootStep, EventHookMode_Pre);
	LoadTranslations("w3s.race.headcrab.phrases");
}

public Action:Event_FootStep(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( War3_GetRace( client ) == thisRaceID )
	{
		SetEntProp(client, Prop_Data, "m_fFlags", 4);
	}
}



public OnMapStart()
{
	
	////War3_PrecacheSound(Fangsstr);
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i))
		{
			bRound[i]=false;
		}
	}
}

public OnWar3EventSpawn(client)
{
	new race = War3_GetRace(client);
	if (race == thisRaceID)
	{
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,-60);
		InitPassiveSkills(client);
	}
}

public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
    if (client > 0)
    {
        if (race == thisRaceID && skill == 1)
        {
            new Float:gravity = 1.00;
            switch (newskilllevel)
            {
                case 0:
                    gravity = 1.00;
                case 1:
                    gravity = 0.90;
                case 2:
                    gravity = 0.80;
                case 3:
                    gravity = 0.70;
                case 4:
                    gravity = 0.60;
            }
            War3_SetBuff(client,fLowGravitySkill,thisRaceID,gravity);	
        }
    }

}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		//War3_WeaponRestrictTo(client,thisRaceID,"");
		//War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
		W3ResetAllBuffRace(client,thisRaceID);
	}
	if(newrace==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    if (client > 0)
    {
        new race = War3_GetRace(client);
        if (race == thisRaceID)
        {
            new skill2_longjump = War3_GetSkillLevel(client, race, SKILL_LONGJUMP);
            new Float:long_push = 1.00;
            switch (skill2_longjump)
            {
                case 0:
                    long_push = 1.10;
                case 1:
                    long_push = 1.15;
                case 2:
                    long_push = 1.20;
                case 3:
                    long_push = 1.25;
                case 4:
                    long_push = 1.30;
            }

            if (skill2_longjump > 0)
            {
                new v_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
                new v_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
                new v_b = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
                new Float:finalvec[3];
                finalvec[0] = GetEntDataFloat(client, v_0) * long_push / 2.0;
                finalvec[1] = GetEntDataFloat(client, v_1) * long_push / 2.0;
                finalvec[2] = long_push * 50.0;
                SetEntDataVector(client, v_b, finalvec, true);
            }
        }
    }
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(attacker,true)&&ValidPlayer(victim,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{

		//ATTACKER IS headcrab
		if(War3_GetRace(attacker)==thisRaceID)
		{
			//fangs poison
			new Float:chance_mod=W3ChanceModifier(attacker);
			/// CHANCE MOD BY VICTIM
			new skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_FANGS);
			if(skill_level>0 && FangsRemaining[victim]==0 && GetRandomFloat(0.0,1.0)<=chance_mod*FangsChanceArr[skill_level]&&!Silenced(attacker))
			{
				if(W3HasImmunity(victim,Immunity_Skills))
				{
					PrintHintText(victim,"%t","Immunity to Fangs");
					PrintHintText(attacker,"%t","Fangs Immunity");
				}
				else
				{
					PrintHintText(victim,"%t","You got bitten by enemy with Fangs");
					PrintHintText(attacker,"%t","You bit your enemy with Fangs");
					BeingFangedBy[victim]=attacker;
					FangsRemaining[victim]=FangsTimes[skill_level];
					War3_DealDamage(victim,FangsInitialDamage,attacker,DMG_BULLET,"fangs");
					W3FlashScreen(victim,RGBA_COLOR_RED);
					
					//W3EmitSoundToAll(Fangsstr,attacker);
					//W3EmitSoundToAll(Fangsstr,victim);
					CreateTimer(1.0,FangsLoop,victim);
				}
			}
		}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if(ValidPlayer(victim)&&ValidPlayer(attacker))
	{
		new race = War3_GetRace(victim);
		decl skilllevel;
		if(race==thisRaceID)
		{
			skilllevel=War3_GetSkillLevel(victim,thisRaceID,SKILL_LATCH);
			if(skilllevel>0&&GetRandomFloat(0.0,1.0)<=LatchChanceArr[skilllevel]&&!W3HasImmunity(attacker,Immunity_Ultimates)&&!Silenced(victim))
			{
				BeingLatchedBy[attacker]=victim;
				PrintHintText(attacker,"%t","You are being latched on by headcrab");
				PrintHintText(victim,"%t","Latched on to your killer");
				//W3EmitSoundToAll(Fangsstr,attacker);
				//W3EmitSoundToAll(Fangsstr,victim);
				CreateTimer(2.0,LatchDamageLoop,attacker);
				bRound[attacker]=true;
			}
		}
		new headcrabperson=BeingLatchedBy[victim];
		if(ValidPlayer( headcrabperson ))
		{
			if(War3_GetRace(headcrabperson)==thisRaceID && !IsPlayerAlive(headcrabperson))
			{
				War3_ChatMessage( headcrabperson , "%T", "Your killer died, you get to respawn", headcrabperson);
				LatchKilled[headcrabperson]=victim;
				CreateTimer(0.2,RespawnPlayer,headcrabperson);
			}
			BeingLatchedBy[victim]=0;
		}
	}
}


public Action:LatchDamageLoop(Handle:timer,any:client)
{
	if(ValidPlayer(client,true)&&ValidPlayer(BeingLatchedBy[client])&&bRound[client])
	{
		
		decl skill;
		skill=War3_GetSkillLevel(BeingLatchedBy[client],thisRaceID,SKILL_LATCH);
		War3_DealDamage(client,RoundFloat(GetRandomFloat(LatchonDamageMin[skill],LatchonDamageMax[skill])),BeingLatchedBy[client],_,"LatchOn",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_TRUEDMG);
		W3FlashScreen(client,RGBA_COLOR_RED, 0.5,0.5);
		PrintToConsole(client,"Recieved -%d Latchon dmg",War3_GetWar3DamageDealt());
		PrintToConsole(BeingLatchedBy[client],"Dealt -%d Latchon dmg",War3_GetWar3DamageDealt());
		CreateTimer(1.0,LatchDamageLoop,client);
	}
}

public Action:FangsLoop(Handle:timer,any:victim)
{
	if(FangsRemaining[victim]>0 && ValidPlayer(BeingFangedBy[victim]) && ValidPlayer(victim,true))
	{
		War3_DealDamage(victim,FangsTrailingDamage,BeingFangedBy[victim],_,"Fangs",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_TRUEDMG);
		//War3_DealDamage(victim,FangsTrailingDamage,BeingFangedBy[victim],DMG_BULLET,"fangs");
		FangsRemaining[victim]--;
		W3FlashScreen(victim,RGBA_COLOR_RED, 0.3, 0.4);
		CreateTimer(1.0,FangsLoop,victim);
	}
}

public Action:RespawnPlayer(Handle:timer,any:client)
{
	if(client>0&&!IsPlayerAlive(client)&&ValidPlayer(LatchKilled[client]))
	{
		War3_SpawnPlayer(client);
		new Float:pos[3];
		new Float:ang[3];
		War3_CachedAngle(LatchKilled[client],ang);
		War3_CachedPosition(LatchKilled[client],pos);
		TeleportEntity(client,pos,ang,NULL_VECTOR);
	}
}

public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		if(ValidPlayer(client,true))
		{
			War3_SetBuff(client,bInvisWeaponOverride,thisRaceID,true);
			War3_SetBuff(client,iInvisWeaponOverrideAmount,thisRaceID,0);
			//War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
			
			new skill3_fourlegs = War3_GetSkillLevel(client, thisRaceID, SKILL_FOURLEGS);
			new Float:gravity = 1.00;
			switch (skill3_fourlegs)
			{
				case 0:
					gravity = 1.00;
				case 1:
					gravity = 0.90;
				case 2:
					gravity = 0.80;
				case 3:
					gravity = 0.70;
				case 4:
					gravity = 0.60;
			}
			War3_SetBuff(client,fLowGravitySkill,thisRaceID,gravity);
		}
	}
}