/**
* File: War3Source_UndeadScourge.sp
* Description: The Undead Scourge race for War3Source.
* Author(s): Anthony Iacono
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>

// War3Source stuff
new thisRaceID;


new Float:LevitationGravity[5]={1.0,0.92,0.733,0.5466,0.36};
new Float:EvadeChance[5]={0.0,0.05,0.10,0.15,0.20};
new Float:CritsChance[5]={0.0,0.04,0.12,0.16,0.22};
new UltimateDamageDuration[]={0,2,4,8,10};
new Float:UltimateMaxDistance=400.0;
new Handle:ultCooldownCvar;
new BeingBurnedBy[66];
new BurnsRemaining[66];
new BeamSprite;
// new HaloSprite;

new SKILL_LOWGRAV,SKILL_CRITS,SKILL_EVADE,ULT_FLAMESTRIKE;

public Plugin:myinfo =
{
	name = "War3Source Race - Death Mage",
	author = "OwnageClan",
	description = "The Death Mage race for War3Source.",
	version = "1.0.0.0",
	url = "http://war3source.com"
};

// War3Source Functions
public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("war3_deathmage_ult_cooldown","15","cooldown for copycat's ultimate");
}


public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==10)
	{
		thisRaceID=War3_CreateNewRace("DeathMage","deathmage");
		SKILL_LOWGRAV=War3_AddRaceSkill(thisRaceID,"Gravity","Reduce effect of gravity",false,4);
		SKILL_CRITS=War3_AddRaceSkill(thisRaceID,"Magic Bullets","Chance to inflict double damage",false,4);
		SKILL_EVADE=War3_AddRaceSkill(thisRaceID,"Evasion","Chance to avoid hits",false,4);
		ULT_FLAMESTRIKE=War3_AddRaceSkill(thisRaceID,"Fire Strike","Ignites nearby enemies",true,4);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnWar3EventSpawn(client)
{

	InitSkills(client);

}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{
		if(IsPlayerAlive(client)){
			InitSkills(client);
		}
	}
}
InitSkills(client){
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		new skilllevel_levi=War3_GetSkillLevel(client,thisRaceID,SKILL_LOWGRAV);
		if(skilllevel_levi)
		{
			new Float:gravity=LevitationGravity[skilllevel_levi];
			War3_SetBuff(client,fLowGravitySkill,thisRaceID,gravity);
		}
	}
}




public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race=War3_GetRace(attacker);
			if(race==thisRaceID)
			{
				new skill_level=War3_GetSkillLevel(attacker,race,SKILL_CRITS);
				//new Float:chance=0.60*chance_mod; //&&GetRandomFloat(0.0,1.0)<=chance&&
				if(skill_level>0&&!W3HasImmunity(victim,Immunity_Skills))
				{

					if(GetRandomFloat(0.0,1.0)<=CritsChance[skill_level] && !W3HasImmunity(attacker,Immunity_Skills)){
						War3_DamageModPercent(2.0);
						PrintHintText(attacker,"You have caused double damage");
						PrintHintText(victim,"Пreceived double the damage of Death Magic");
						new Float:victimoriginp[3];
						new Float:attackeroriginp[3];
						GetClientAbsOrigin(victim,victimoriginp);
						GetClientAbsOrigin(attacker,attackeroriginp);
						attackeroriginp[2]+=15.0;
						victimoriginp[2]+=15.0;
						TE_SetupBeamPoints(attackeroriginp,victimoriginp,BeamSprite,0,0,0,1.0,8.0,8.0,10,0.0,{0,128,0,255},20);
						TE_SendToAll();

						/*War3_DamageModPercent(percent);
						PrintToConsole(attacker,"%.1fX Critical ! ",percent+1.0);
						PrintHintText(attacker,"Critical !",percent+1.0);

						PrintToConsole(victim,"Received %.1fX Critical Dmg!",percent+1.0);
						PrintHintText(victim,"Received Critical Dmg!");
						*/

					}
				}
			}

			race=War3_GetRace(victim);
			if(race==thisRaceID)
			{
				new skill_level=War3_GetSkillLevel(victim,thisRaceID,SKILL_EVADE);//if they are not this race thats fine, later check for race


				if(GetRandomFloat(0.0,1.0)<=EvadeChance[skill_level] && !W3HasImmunity(attacker,Immunity_Skills)){
					War3_DamageModPercent(0.0);
					PrintHintText(attacker,"The enemy has evaded!");
					PrintHintText(victim,"You have turned aside!");
				}
			}
		}
	}
}



public OnUltimateCommand(client,race,bool:pressed)
{

	if(race==thisRaceID && pressed && ValidPlayer(client,true) )
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_FLAMESTRIKE);
		if(ult_level>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_FLAMESTRIKE,true))
			{
				/////Flame Strike
				new target = War3_GetTargetInViewCone(client,UltimateMaxDistance,false,23.0,IsBurningFilter);
				if(target>0)
				{

					BeingBurnedBy[target]=client;
					BurnsRemaining[target]=UltimateDamageDuration[ult_level];
					CreateTimer(1.0,BurnLoop,target);
					War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_FLAMESTRIKE);
					PrintHintText(client,"Fire Punch-Out!");
					PrintHintText(target,"You hit the Mage Fire Death Blow!");
					W3SetPlayerColor(target,thisRaceID,255,128,0,_,GLOW_ULTIMATE);
				}
				else
				{
					W3MsgNoTargetFound(client,UltimateMaxDistance);
					//PrintHintText(client,"No results found objectives within %.1f feet",UltimateMaxDistance/10.0);
				}
			}
		}
	}
}

public bool:IsBurningFilter(client)
{
	return (BurnsRemaining[client]<=0 && !W3HasImmunity(client,Immunity_Ultimates));
}
public Action:BurnLoop(Handle:timer,any:victim)
{
	new attacker=GetClientOfUserId(BeingBurnedBy[victim]);
	if(victim>0 && attacker>0 && BurnsRemaining[victim]>0 && IsClientInGame(victim) && IsClientInGame(attacker) && IsPlayerAlive(victim))
	{
		BurnsRemaining[victim]--;
		new damage = 5;
		War3_DealDamage(victim,damage,attacker,DMG_BURN,"flamestrike",_,W3DMGTYPE_MAGIC);
		CreateTimer(1.0,BurnLoop,victim);
		if(BurnsRemaining[victim]<=0)
		{
			W3ResetPlayerColor(victim,thisRaceID);
		}
	}
}



