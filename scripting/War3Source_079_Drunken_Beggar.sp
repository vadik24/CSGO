/*
* War3Source Race - Drunken Beggar
* 
* File: War3Source_Drunken_Beggar.sp
* Description: The Drunken Beggar race for War3Source.
* Author: M.A.C.A.B.R.A 
*/
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - Drunken Beggar",
	author = "M.A.C.A.B.R.A",
	description = "The Drunken Beggar race for War3Source.",
	version = "1.0",
	url = "http://strefagier.com.pl/",
};

new thisRaceID;
new SKILL_SLALOM, SKILL_RESISTANCE, SKILL_DRUNK, SKILL_BEG, ULT_FURY;

// Slalom 
new SlalomMin = 1;
new SlalomMax[] = { 0, 70, 60, 50, 40 };


// Resistance Buffs
new Float:ResistanceSpeed[]={1.0,1.10,1.15,1.20,1.25};
new Float:ResistanceGravity[]={1.0,0.95,0.85,0.75,0.65};
new ResistanceArmor[]={0,25,50,75,100};
new ResistanceHP[]={100,105,110,115,120};

// Drunk
new DrunkDamage[] = {0,10,15,20,25};
new Float:DrunkTime[]={0.0,2.0,3.0,4.0,5.0}; 
new Handle:DrunkCooldownTime;
new Float:DrunkRange[]={0.0,100.0,200.0,300.0,400.0};
new bool:bIsDrunked[MAXPLAYERS];

new UserMsg:g_FadeUserMsgId;
new Handle:g_DrunkTimers[MAXPLAYERS+1];
new Float:g_DrunkAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

// Beg
new Float:Begchance[]={0.0,0.2,0.4,0.6,0.8};

// Drunken Fury
new Float:DrunkenFury[]={1.0,1.05,1.20,1.35,1.5};
new bool:bFuryActivated[MAXPLAYERS];
new Handle:FuryCooldown; 

// Sounds 
new String:skillsnd[]="war3source/beggar/laugh.mp3";
new String:ultsnd[]="war3source/beggar/fury.mp3";

public OnWar3PluginReady(){
	thisRaceID=War3_CreateNewRace("Drunken Beggar","drunken");
	
	SKILL_SLALOM=War3_AddRaceSkill(thisRaceID,"Slalom","You walk zig-zag between bullets.",false,4); // evade
	SKILL_RESISTANCE=War3_AddRaceSkill(thisRaceID,"Resistance","You can drink more and become stronger.",false,4); // hp,ap,speed
	SKILL_DRUNK=War3_AddRaceSkill(thisRaceID,"Treat (Ability)","You regale enemies and drunk them.",false,4); // upija (Drunk)
	SKILL_BEG=War3_AddRaceSkill(thisRaceID,"Beg (Attack)","Hello my boss. Gimmmie some gold.",false,4); // gold
	ULT_FURY=War3_AddRaceSkill(thisRaceID,"Drunken Fury (Ultimate)","You're really pissed off and far more powerful.",true,4); // sila
	War3_CreateRaceEnd(thisRaceID);
}

public OnPluginStart()
{
	DrunkCooldownTime=CreateConVar("war3_drunken_drunk_cooldown","15","Cooldown timer.");
	FuryCooldown=CreateConVar("war3_drunken_fury_cooldown","30","Cooldown timer.");
}

public OnMapStart()
{  
	//Sounds
	////War3_PrecacheSound(skillsnd);
	////War3_PrecacheSound(ultsnd);
}

public OnWar3EventSpawn(client)
{
	InitPassiveSkills(client);
	bIsDrunked[client] = false;
	bFuryActivated[client] = false;
	W3ResetPlayerColor(client, thisRaceID);
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	InitPassiveSkills(client);
}

public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skill_lvl = War3_GetSkillLevel(client,thisRaceID,SKILL_RESISTANCE);	
		if(skill_lvl > 0)
		{
			War3_SetBuff(client,fMaxSpeed,thisRaceID,ResistanceSpeed[skill_lvl]);
			War3_SetBuff(client,fLowGravitySkill,thisRaceID,ResistanceGravity[skill_lvl]);
			SetEntityHealth(client,ResistanceHP[skill_lvl]);
			War3_SetMaxHP_INTERNAL(client,ResistanceHP[skill_lvl]);
			War3_SetCSArmor(client,ResistanceArmor[skill_lvl]);
			War3_SetCSArmorHasHelmet(client,true);
		}
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
		War3_SetMaxHP_INTERNAL(client,100);
		War3_SetCSArmor(client,0);
		War3_SetCSArmorHasHelmet(client,false);
	}
}


public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim) && IS_PLAYER(attacker) && victim > 0 && attacker > 0 && attacker != victim)
	{
		new vteam = GetClientTeam(victim);
		new ateam = GetClientTeam(attacker);
		if(vteam != ateam)
		{
			new race_attacker = War3_GetRace(attacker);
			new level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_BEG);
			if(race_attacker == thisRaceID)
			{
				if(!Hexed(attacker))
				{
					if(level > 0)
					{
						if(!W3HasImmunity(victim,Immunity_Skills))
						{
							if(GetRandomFloat(0.0,1.0) <= Begchance[level])
							{
								new gold = War3_GetGold(victim);
								if(gold > 0)
								{
									War3_SetGold(victim,War3_GetGold(victim) - 1);
									War3_SetGold(attacker,War3_GetGold(attacker) + 1);
									PrintHintText(victim,"Beggar says THANKS !");
									PrintHintText(attacker,"Thanks my boss !");
								}
								else
								{
									PrintHintText(attacker,"He's a piker !");
								}
							}
						}
					}
				}
			}			
			
		}
		if(IsPlayerAlive(victim) && IsPlayerAlive(attacker))
		{
			new race_victim = War3_GetRace(victim);
			if( vteam != ateam )
			{
				new skill_slalom = War3_GetSkillLevel( victim, thisRaceID, SKILL_SLALOM );
				if( race_victim == thisRaceID && skill_slalom > 0 && !Hexed( victim, false ) && !W3HasImmunity( attacker, Immunity_Skills ))
				{
					if( GetRandomInt( SlalomMin, SlalomMax[skill_slalom] ) <= 10 )
					{
						W3FlashScreen( victim, RGBA_COLOR_BLUE );					
						War3_DamageModPercent( 0.0 );					
						W3MsgEvaded( victim, attacker );
					}
				}
			}
		}
	}
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			if(bFuryActivated[attacker])
			{
				new skill_ult = War3_GetSkillLevel(attacker,thisRaceID,ULT_FURY);
				War3_DamageModPercent(DrunkenFury[skill_ult]);
				damage *= DrunkenFury[skill_ult];
			}
			
		}
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill = War3_GetSkillLevel(client,thisRaceID,SKILL_DRUNK);
		if(skill > 0)
		{
			
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_DRUNK,true))
			{
				new damage = DrunkDamage[skill];
				new Float:AttackerPos[3];
				GetClientAbsOrigin(client,AttackerPos);
				new AttackerTeam = GetClientTeam(client);
				new Float:VictimPos[3];
				
				
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true)){
						GetClientAbsOrigin(i,VictimPos);
						if(GetVectorDistance(AttackerPos,VictimPos) < DrunkRange[skill])
						{
							if(GetClientTeam(i)!= AttackerTeam)
							{
								War3_DealDamage(i,damage,client,DMG_BURN,"drunk",W3DMGORIGIN_SKILL);
								if(!bIsDrunked[i])
								{
									bIsDrunked[i]=true;
									W3SetPlayerColor(i,thisRaceID, 0, 255, 0, 0); 
									PrintHintText(i,"You were drunked by Beggar");
									CreateDrunk(i);
									W3FlashScreen(i,RGBA_COLOR_RED);
									CreateTimer(DrunkTime[skill],SoberPlayer,i);									
								}
							}
						}
					}
				}
				//EmitSoundToAll(skillsnd,client);
				War3_CooldownMGR(client,GetConVarFloat(DrunkCooldownTime),thisRaceID,SKILL_DRUNK,false,true);
			}
		}
		else
		{
			PrintHintText(client, "Level your Treat first");
		}
	}
}

public Action:SoberPlayer(Handle:timer,any:client)
{
	KillDrunk(client);
	PrintHintText(client,"You sobered up!");
	bIsDrunked[client]=false;
	W3ResetPlayerColor(client, thisRaceID);
	
}

CreateDrunk(client)
{
	g_DrunkTimers[client] = CreateTimer(0.5, Timer_Drunk, client, TIMER_REPEAT);	
}

KillDrunk(client)
{
	KillDrunkTimer(client);
	
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	new Float:angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = 0.0;
	
	TeleportEntity(client, pos, angs, NULL_VECTOR);	
	
	new clients[2];
	clients[0] = client;	
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	BfWriteShort(message, (0x0001 | 0x0010));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	EndMessage();	
}

KillDrunkTimer(client)
{
	KillTimer(g_DrunkTimers[client]);
	g_DrunkTimers[client] = INVALID_HANDLE;	
}


public Action:Timer_Drunk(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		KillDrunkTimer(client);

		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		KillDrunk(client);
		
		return Plugin_Handled;
	}
	
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	new Float:angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = g_DrunkAngles[GetRandomInt(0,100) % 20];
	
	TeleportEntity(client, pos, angs, NULL_VECTOR);
	
	new clients[2];
	clients[0] = client;	
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(message, 255);
	BfWriteShort(message, 255);
	BfWriteShort(message, (0x0001|0x0010));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));

	EndMessage();	
		
	return Plugin_Handled;
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill = War3_GetSkillLevel(client,thisRaceID,ULT_FURY);
		if(skill>0)
		{	
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_FURY,true ))
			{
				PrintHintText(client, "Someone smashed ur bottle. ROAR !!!");
				bFuryActivated[client] = true;
				CreateTimer(10.0,stopUltimate,client);
				
				//EmitSoundToAll(ultsnd,client);  
				War3_CooldownMGR(client,GetConVarFloat(FuryCooldown),thisRaceID,ULT_FURY,false,true);
			}
		}
		else
		{
			PrintHintText(client, "Level your Fury first");
		}
	}
}


public Action:stopUltimate(Handle:t,any:client){
	bFuryActivated[client] = false;
	if(ValidPlayer(client,true)){
		PrintHintText(client,"They promised to redeem it.");
	}
}