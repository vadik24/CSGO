 /**
* File: War3Source_Arthas.sp
* Description: The Arthas race for War3Source.
* Author(s): Scyther
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>



new thisRaceID;

new SKILL_HEALING, SKILL_BBULL, SKILL_AURA, ULT_VOODOO;

//skill 1
new HealingperAmountArr[]={0,1,2,3,4};
new Float:HealingperDistanceArr[]={0.0,300.0,400.0,500.0,600.0};

//skill 2
new Float:AbilityCooldownTime=20.0;
new Float:BlessedTime[5]={0.0,2.0,4.0,6.0,8.0};
new bool:bBlessed[66];
//skill 3
new DevotionHealth[5]={0,10,20,30,40};
//ultimate
new Handle:ultCooldownCvar;

new Float:UltimateDuration[]={0.0,1.3,1.6,1.9,2.1}; ///big bad voodoo duration



new bool:bVoodoo[65];

new String:ultimateSound[]="war3source/divineshield.mp3";

new BeamSprite,HaloSprite; //wards

public Plugin:myinfo = 
{
	name = "War3Source Race - Arthas",
	author = "Scyther",
	description = "The Arthas race for War3Source.",
	version = "1.0.0.0",
	url = "http://Www.OwnageClan.Com"
};

public OnPluginStart()
{
	
	ultCooldownCvar=CreateConVar("war3_hunter_voodoo_cooldown","20","Cooldown between Big Bad Voodoo (ultimate)");
	CreateTimer(1.0,CalcHexHeales,_,TIMER_REPEAT);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==260)
	{
		
		
		thisRaceID=War3_CreateNewRace("Knight Arthas","arthas");
		SKILL_HEALING=War3_AddRaceSkill(thisRaceID,"Holy Light","Treat allies around you",false,4);
		SKILL_BBULL=War3_AddRaceSkill(thisRaceID,"Patron saint","(+ability) Get increased damage for 2-8 seconds",false,4);
		SKILL_AURA=War3_AddRaceSkill(thisRaceID,"The aura of the Gods","Spawn with a lot of HP",false,4);
		ULT_VOODOO=War3_AddRaceSkill(thisRaceID,"Pray to God","At some time you bless the gods themselves,\nremove the damage from bullets.",true,4); 
		War3_CreateRaceEnd(thisRaceID);
	}
	
}

public OnMapStart()
{
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	
	////War3_PrecacheSound(ultimateSound);
}

public OnWar3PlayerAuthed(client)
{
	bVoodoo[client]=false;
}

public OnRaceChanged(client, oldrace, newrace)
{
	if(newrace!=thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{
		ActivateSkills(client);
		
	}
}
public ActivateSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		
		new skill_devo=War3_GetSkillLevel(client,thisRaceID,SKILL_AURA);
		if(skill_devo)
		{
			// Devotion Aura
			new hpadd=DevotionHealth[skill_devo];
			new Float:vec[3];
			GetClientAbsOrigin(client,vec);
			vec[2]+=25.0;
			new ringColor[4]={0,0,0,0};
			new team=GetClientTeam(client);
			if(team==2)
			{
				ringColor={255,0,0,255};
			}
			else if(team==3)
			{
				ringColor={0,0,255,255};
			}
			TE_SetupBeamRingPoint(vec,40.0,10.0,BeamSprite,HaloSprite,0,15,1.0,8.0,0.0,ringColor,10,0);
			TE_SendToAll();
			

			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,hpadd);
			//War3_ChatMessage(client,"+%d HP",hpadd);
		}
	}
}


public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_VOODOO);
		if(ult_level>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_VOODOO,true))
			{
				bVoodoo[client]=true;
				W3SetPlayerColor(client,thisRaceID,120,0,0,_,GLOW_ULTIMATE);
				CreateTimer(UltimateDuration[ult_level],EndVoodoo,GetClientUserId(client));
				new Float:cooldown=	GetConVarFloat(ultCooldownCvar);
				War3_CooldownMGR(client,cooldown,thisRaceID,ULT_VOODOO,_,_);
				PrintHintText(client,"Activated Blessing!");
				//EmitSoundToAll(ultimateSound,client,_,SNDLEVEL_TRAIN);
				//EmitSoundToAll(ultimateSound,client,_,SNDLEVEL_TRAIN);
			}
			
		}
		else
		{
			PrintHintText(client,"First, elevate the level of ultimate");
		}
	}
}

public OnCooldownExpired(client,raceID,skillNum,bool:expiredbytime){
	if(raceID==thisRaceID){
		if(skillNum==ULT_VOODOO){
			
			if(expiredbytime){
				PrintHintText(client,"Ultra ready");
			}
		}
	}
}

public UltimateNotReadyMSG(client){
	PrintHintText(client,"Ulta is not ready, %d seconds left",War3_CooldownRemaining(client,thisRaceID,ULT_VOODOO));
}


public Action:EndVoodoo(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(client>0)
	{
		bVoodoo[client]=false;
		W3ResetPlayerColor(client,thisRaceID);
		PrintHintText(client,"Immortality is completed");
	}
}

public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0) //block self inflicted damage
	{
		if(bVoodoo[victim]&&attacker==victim){
			War3_DamageModPercent(0.0);
			return;
		}
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		
		
		if(vteam!=ateam)
		{
			if(bVoodoo[victim])
			{
				if(!W3HasImmunity(attacker,Immunity_Ultimates))
				{
					if(War3_GetGame()==Game_TF){
						decl Float:pos[3];
						GetClientEyePosition(victim, pos);
						pos[2] += 4.0;
						War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
					}
					War3_DamageModPercent(0.0);
				}
				else
				{
					PrintHintText(victim,"Enemies immune!");
					PrintToConsole(victim,"Enemy has immunity!");
				}
			}
		}
		new race_attacker=War3_GetRace(attacker);
		new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_BBULL);	
		if(race_attacker==thisRaceID && bBlessed[attacker] && skill_level>0)
		{
			// new vteam=GetClientTeam(victim);
			// new ateam=GetClientTeam(attacker);
			if(vteam!=ateam)
			{
				new race=War3_GetRace(attacker);
				if(race==thisRaceID)
				{
					//new Float:chance=0.60*chance_mod; //&&GetRandomFloat(0.0,1.0)<=chance&&
					if(skill_level>0&&!W3HasImmunity(victim,Immunity_Skills))
					{
						
						if(!W3HasImmunity(attacker,Immunity_Skills))
							War3_DamageModPercent(1.10);
						//PrintHintText(attacker,"10% extra damage");
						//PrintHintText(victim,"Hit with blessed bullets");
						new Float:victimoriginp[3];
						new Float:attackeroriginp[3];
						GetClientAbsOrigin(victim,victimoriginp);
						GetClientAbsOrigin(attacker,attackeroriginp);
						attackeroriginp[2]+=15.0;
						victimoriginp[2]+=15.0;
						TE_SetupBeamPoints(attackeroriginp,victimoriginp,BeamSprite,0,0,0,1.0,8.0,8.0,10,0.0,{255,246,143,255},20);
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
		}
	}
	return;
}



// Events
public OnWar3EventSpawn(client){
	bVoodoo[client]=false;
	bBlessed[client]=false;
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		ActivateSkills(client);
	}
}




public Healer(client)
{
	//assuming client exists and has this race
	new skill = War3_GetSkillLevel(client,thisRaceID,SKILL_HEALING);
	if(skill>0)
	{
		new Float:dist = HealingperDistanceArr[skill];
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
					War3_HealToMaxHP(i,HealingperAmountArr[skill]);
					//HealerPos[2]+=15.0;
					VecPos[2]+=15.0;
					TE_SetupBeamPoints(HealerPos,VecPos,BeamSprite,0,0,0,0.3,2.5,3.0,10,0.0,{0,225,0,255},20);
					//TE_SendToAll();
					new aa = 0;//, team = 2;
					decl sendarray[32];
					for (new x = 1; x <= MaxClients; x++)
					{
						if(IsClientInGame(x) && !IsFakeClient(x))
						{
							new ArthasTeam = GetClientTeam(x);
							if (ArthasTeam == HealerTeam)
							{
								sendarray[aa++] = x;
							}
						}
					}
					TE_Send(sendarray, aa);
				}
			}
		}
	}
}



public Action:CalcHexHeales(Handle:timer,any:userid)
{
	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true))
			{
				if(War3_GetRace(i)==thisRaceID)
				{
					Healer(i); //check leves later
				}
			}
		}
	}
}





public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_BBULL);
		if(skill_level>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_BBULL,true))
			{
				War3_CooldownMGR(client,AbilityCooldownTime,thisRaceID,SKILL_BBULL,_,_);
				PrintHintText(client,"Now your patrons lit and inflict more damage");
				CreateTimer(BlessedTime[skill_level],RemoveBless,client);
				bBlessed[client]=true;
			}
		}
	}
}




public Action:RemoveBless(Handle:t,any:client)
{
	if(bBlessed[client]==true)
	{
		bBlessed[client]=false;
		PrintHintText(client,"Patron saint ran out");
	}
}

