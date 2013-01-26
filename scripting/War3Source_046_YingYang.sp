/**
* File: 					War3Source_YingYang.sp
* Description: 				The ES version of YingYang race for War3Source.
* Author(s): 				Schmarotzer
* Original idea: 			Damakex
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
new MoneyOffsetCS;
// new String:ultsnd[]="war3source/blinkarrival.mp3";
new String:ultsnd[]="items/smallmedkit1.mp3";
new String:darksnd1[]="weapons/explode3.mp3";
new String:darksnd2[]="weapons/explode4.mp3";
new String:darksnd3[]="weapons/explode5.mp3";


//skill1
new Float:DarkChance[6]={0.00,0.03,0.06,0.09,0.12,0.15};
//skill2
new LightHealth[6]={0,10,15,20,25,30};
//skill3
new BalanceHealth[6]={0,10,15,20,25,30};




new SKILL_DARK,SKILL_LIGHT,ULT_BALANCE;

public Plugin:myinfo = 
{
	name = "War3Source Race - YingYang",
	author = "Schmarotzer",
	description = "The ES YingYang race for War3Source.",
	version = "1.0.3.2",
	url = "http://war3source.com"
};

public OnPluginStart()
{
	HookEvent("round_start",RoundStartEvent);
	LoadTranslations("w3s.race.yingyang.phrases");
	MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
}

public OnMapStart()
{
	////War3_PrecacheSound(ultsnd);
	////War3_PrecacheSound(darksnd1);
	////War3_PrecacheSound(darksnd2);
	////War3_PrecacheSound(darksnd3);
}

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==180)
	{
		thisRaceID=War3_CreateNewRaceT("yingyang");
		SKILL_DARK=War3_AddRaceSkillT(thisRaceID,"Dark",false,5);
		SKILL_LIGHT=War3_AddRaceSkillT(thisRaceID,"Light",false,5);
		ULT_BALANCE=War3_AddRaceSkillT(thisRaceID,"Balance",true,5);
		War3_CreateRaceEnd(thisRaceID);
	}
}


/*
public OnRaceChanged(client,oldrace,newrace)
{
	if(race=thisRaceID)
	{
		ActivateSkills(client);
	}
	else
	{
	W3ResetAllBuffRace(client,thisRaceID);
	}
}
*/

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x,true)&&War3_GetRace(x)==thisRaceID)
		{
			new skill_level_light=War3_GetSkillLevel(x,thisRaceID,SKILL_LIGHT);
			if(skill_level_light>0)
			{
				War3_ChatMessage(x,"%T","[Balance of Light] Your teammates gained HP",x);
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true) && GetClientTeam(i)==GetClientTeam(x) && i!=x)
					{
						new hpadd;
						new TeammateMaxHP = War3_GetMaxHP(i);
						new TeammateHP = GetClientHealth(i);
						if (TeammateMaxHP > 25 && TeammateMaxHP < 155)
						{
							hpadd = LightHealth[skill_level_light];
						}
						else
						{
							hpadd = 5;
						}
						War3_SetBuff(i,iAdditionalMaxHealth,TeammateMaxHP,hpadd);
						SetEntityHealth(i,TeammateHP + hpadd);
						War3_ChatMessage(i,"%T","You gained [amount] HP",i,hpadd);
						// War3_ChatMessage(i,"%T","You gained [amount] HP",hpadd);
					}
				}
			}
		}
	}
}

/*
public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		ActivateSkills(client);
	}
}

public ActivateSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skill_level_light=War3_GetSkillLevel(client,thisRaceID,SKILL_LIGHT);
		if(skill_level_light>0)
		{
			new hpadd=LightHealth[skill_level_light];
			War3_ChatMessage(client,"%T","[Balance of Light] Your teammates gained HP",client);
			for(new i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true) && GetClientTeam(i)==GetClientTeam(client) && i!=client)
				{
					new TeammateMaxHP=War3_GetMaxHP(i);
					new TeammateHP=GetClientHealth(i);
					War3_SetBuff(i,iAdditionalMaxHealth,thisRaceID,TeammateMaxHP+hpadd);
					SetEntityHealth(i,TeammateHP+hpadd);
					// War3_ChatMessage(i,"%T","You gained [amount] HP, because Ying-Yang in your team",i,hpadd);
					War3_ChatMessage(i,"%T","You gained [amount] HP, because Ying-Yang in your team",hpadd);
				}
			}
		}
	}
}
*/

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim,true) && ValidPlayer(attacker,true) && attacker!=victim)
	{
		if(GetClientTeam(attacker)!=GetClientTeam(victim))
		{
			if(War3_GetRace(attacker)==thisRaceID)
			{
				new skill_level_dark=War3_GetSkillLevel(attacker,thisRaceID,SKILL_DARK);
				if(skill_level_dark>0)
				{
					if(!Hexed(attacker,false) && GetRandomFloat(0.0,1.0)<=DarkChance[skill_level_dark])
					{
						if(W3HasImmunity(victim,Immunity_Skills))
						{
							W3MsgSkillBlocked(victim,attacker,"Balance of Dark");
						}
						else 
						{
							//EmitSoundToAll(darksnd,victim);
							W3FlashScreen(victim,{0,0,0,255},0.5,_,FFADE_STAYOUT);
							//new random = GetRandomInt(0,2);
							//switch (random)
							//{
							//	case 0:
							//		//EmitSoundToAll(darksnd1,victim);
							//	case 1:
							//		//EmitSoundToAll(darksnd2,victim);
							//	case 2:
							//		//EmitSoundToAll(darksnd3,victim);
							//}
							CreateTimer(0.5,Unblind,GetClientUserId(victim));
						}
					}
				}
			}
		}
	}
}


public Action:Unblind(Handle:timer,any:userid)
{
	// never EVER use client in a timer. userid is safe
	new client=GetClientOfUserId(userid);
	if(client>0)
	{
		W3FlashScreen(client,{0,0,0,0},0.1,_,(FFADE_IN|FFADE_PURGE));
	}
}

stock GetMoney(player)
{
	return GetEntData(player,MoneyOffsetCS);
}

stock SetMoney(player,money)
{
	SetEntData(player,MoneyOffsetCS,money);
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new ult_level_balance=War3_GetSkillLevel(client,race,ULT_BALANCE);
		if(ult_level_balance>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_BALANCE,true))
			{
				if(!Silenced(client))
				{
					new YYMoney = GetMoney(client);
					// new new_money;
					new hpultadd=BalanceHealth[ult_level_balance];
					if(YYMoney>500)
					{
						new new_money = YYMoney-500;
						SetMoney(client,new_money);
						SetEntityHealth(client,GetClientHealth(client)+hpultadd);
						//EmitSoundToAll(ultsnd,client);
						War3_CooldownMGR(client,25.0,thisRaceID,ULT_BALANCE,_,_);
						PrintHintText(client,"%T","Balance: You gained [amount] HP",client,hpultadd);
					}
					else
					{
						// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
						// PrintHintText(client,"%T","Õ≈ ’¬¿“¿≈“ ¡¿¡À¿",client);
						// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
					}
				}
				else
				{
					PrintHintText(client,"%T","Silenced: you can not case!",client);
				}
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}