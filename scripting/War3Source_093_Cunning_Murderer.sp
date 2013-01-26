#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - Cunning Murderer",
	author = "M.A.C.A.B.R.A",
	description = "The Cunning Murderer race for War3Source.",
	version = "1.0",
};

new thisRaceID;
new SKILL_ROTATE, SKILL_REGENERATE, SKILL_ACCELERATOR, ULT_AVENGER;

// Rotate
new Float:RotateRange[]={0.0,50.0,80.0,100.0,15.0,200.0};
new RotateDelayer[MAXPLAYERS];

// Regenerate
new bool:bDucking[MAXPLAYERS];
new RegenerateAmmount[]={0,1,2,3,4,5};
new Float:canregeneratetime[MAXPLAYERS+1];
new RegenerateDelayer[MAXPLAYERS];

//Accelerator
new Float:SpeedAmmount[]={1.0,1.2,1.4,1.6,1.8,2.0};
new Float:StandStillTime[MAXPLAYERS];
new bool:AcceleratorActivated[MAXPLAYERS];
new m_vecVelocity = -1;
new Float:canspeedtime[MAXPLAYERS+1];
new AcceleratorDelayer[MAXPLAYERS];

// Avenger
new VictimsTab[MAXPLAYERS];
new AvengerDmg[]={0,10,20,30,40,50};

// Model Index'es
new BeamSprite,HaloSprite;

/* *********************** OnWar3PluginReady *********************** */
public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "VIP Cunning Murderer", "cunning" );
	
	SKILL_ROTATE = War3_AddRaceSkill( thisRaceID, "Rotate", "Passively turns around your enemy", false, 5 );
	SKILL_REGENERATE = War3_AddRaceSkill( thisRaceID, "Regenerate", "HP recover if ducking.", false, 5 );
	SKILL_ACCELERATOR = War3_AddRaceSkill( thisRaceID, "Accelerator", "Charges your speed if not moving.", false, 5 );
	ULT_AVENGER = War3_AddRaceSkill( thisRaceID, "Avenger", "Your friend comes to avenge your death.", true, 5 );
	
	
	War3_CreateRaceEnd( thisRaceID );
}

/* *********************** OnMapStart *********************** */
public OnMapStart()
{
	BeamSprite = PrecacheModel("materials/sprites/plasma.vmt");
	HaloSprite = PrecacheModel("materials/sprites/plasmahalo.vmt");
}

/* *********************** OnPluginStart *********************** */
public OnPluginStart()
{
	CreateTimer(0.1,CalcSpeed,_,TIMER_REPEAT);
	m_vecVelocity = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
}

/* *********************** OnWar3EventSpawn *********************** */
public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		StandStillTime[client] = 0.0;
		AcceleratorActivated[client] = false;
		bDucking[client] = false;
		W3ResetAllBuffRace( client, thisRaceID );
		
		RegenerateDelayer[client] = GetRandomInt(0,10);
		AcceleratorDelayer[client] = RegenerateDelayer[client];
		RotateDelayer[client] = GetRandomInt(0,30);
	}
}

/* *********************** OnRaceChanged *********************** */
public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		W3ResetAllBuffRace( client, thisRaceID );
	}
}

/* *********************** OnWar3EventDeath *********************** */
public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
	
	if(War3_GetRace(victim) == thisRaceID)
	{
		new skill_lvl = War3_GetSkillLevel(victim,thisRaceID,ULT_AVENGER);
		War3_DealDamage(attacker,AvengerDmg[skill_lvl],victim,DMG_BURN,"Avenger",W3DMGORIGIN_SKILL);
	
		new avenger = GetRandomDeathPlayer( victim );
		if(avenger>0) {
			decl Handle:pack;
			CreateDataTimer(1.5, Timer_SpawnPlayer, pack);
			WritePackCell(pack, avenger);		
			WritePackCell(pack, victim);
			WritePackCell(pack, attacker);
			PrintToChat(avenger,"\x04[War3Source] \x01You will be summoned to the corpse of your friend in 1.5 seconds!");
			PrintHintText(avenger, "You have been chosen to avenge the death of your friend.");
		}
	}
}

public Action:Timer_SpawnPlayer(Handle:timer, Handle:pack)
{
	//Resolve order must be: client,max_distance,AoE,slowdown amount,damage,targetpos[3]
	ResetPack(pack);
	new avenger = ReadPackCell(pack);
	new victim = ReadPackCell(pack);
	new attacker = ReadPackCell(pack);
	if(avenger>0&&victim>0&&attacker>0) {
		new Float:VictimPos[3];
		GetClientAbsOrigin(victim,VictimPos);
		new Float:angs[3];
		GetClientEyeAngles(attacker, angs);
		angs[1] += 180;
		War3_SpawnPlayer(avenger);
		TeleportEntity(avenger, VictimPos, angs, NULL_VECTOR);
		TE_SetupBeamRingPoint(VictimPos,50.0,150.0,BeamSprite,HaloSprite,0,15,3.20,80.0,2.0,{255,120,120,255},30,0);
		TE_SendToAll();
	}
}

/* *************************************** CalcRegenerate *************************************** */
/* MOVED TO CALC SPEED
public Action:CalcRegenerate(Handle:timer,any:userid)
{
	for(new i = 1; i < MaxClients; i++)
	{
		if(ValidPlayer(i) && War3_GetRace(i) == thisRaceID)
		{
			new skill_regen = War3_GetSkillLevel(i,thisRaceID,SKILL_REGENERATE);
			if(canregeneratetime[i] < GetGameTime() && skill_regen > 0)
			{
				RegenerateDelayer[i]++;
				if(RegenerateDelayer[i] == 10)
				{
					War3_HealToBuffHP(i,RegenerateAmmount[skill_regen]);
					RegenerateDelayer[i] = 0;
				}
			}
			else
			{
			}
			if(skill_regen> 0 && !bDucking[i])
			{
				canregeneratetime[i] = GetGameTime() + 1.0;
			}
		}
	}
}*/

/* *************************************** OnPlayerRunCmd *************************************** */
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(ValidPlayer(client)&&War3_GetRace(client)==thisRaceID)
	{
		bDucking[client]=(buttons & IN_DUCK)?true:false;
	}
	return Plugin_Continue;
}



/* *************************************** CalcSpeed *************************************** */
public Action:CalcSpeed(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i,true) && War3_GetRace(i) == thisRaceID)
		{
			if(GetRandomInt(0,2)==2) Rotation( i );
			Heal( i );
			new skill_speed = War3_GetSkillLevel(i,thisRaceID,SKILL_ACCELERATOR);
			if(canspeedtime[i] < GetGameTime() && skill_speed > 0 )
			{
				if(AcceleratorActivated[i] == false)
				{
					AcceleratorDelayer[i]++;
					if(AcceleratorDelayer[i] == 10)
					{
						StandStillTime[i]++;
						PrintHintText(i, "Charging accelerate: %.0f",StandStillTime[i]);	
						AcceleratorDelayer[i] = 0;
					}
				}
			}
			else
			{
				if(AcceleratorActivated[i] == false)
				{
					if(StandStillTime[i] != 0.0)
					{
						PrintHintText(i, "You've been accelerated for %.0f seconds",StandStillTime[i]);
						AcceleratorDelayer[i] = 0;
						CreateTimer(StandStillTime[i], SlowDown, i);
						StandStillTime[i] = 0.0;
						War3_SetBuff(i,fMaxSpeed,thisRaceID,SpeedAmmount[skill_speed]);
						AcceleratorActivated[i] = true;
					}
				}
			}
			decl Float:velocity[3];
			GetEntDataVector(i,m_vecVelocity,velocity);
			if(skill_speed > 0 && GetVectorLength(velocity) > 0)
			{
				canspeedtime[i] = GetGameTime() + 1.0;
			}
		}
	}	
}

/* *************************************** SlowDown *************************************** */
public Action:SlowDown(Handle:timer,any:client)
{
	AcceleratorActivated[client] = false;
	if (ValidPlayer(client,true))
	{
		W3ResetAllBuffRace( client, thisRaceID );
		PrintHintText(client, "You slowed down.");
	}	
}



/* *************************************** CalcRotation *************************************** */
/* MOVED TO CalcSpeed
public Action:CalcRotation( Handle:timer, any:userid )
{
	if( thisRaceID > 0 )
	{
		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) )
			{
				if( War3_GetRace( i ) == thisRaceID )
				{
					Rotation( i );					
				}
			}
		}
	}
}*/

/* *************************************** Rotation *************************************** */
public Rotation( client )
{
	new skill_rotate = War3_GetSkillLevel( client, thisRaceID, SKILL_ROTATE );
	if( skill_rotate > 0 && !Hexed( client, false ) )
	{
		new Float:distance = RotateRange[skill_rotate];
		new AttackerTeam = GetClientTeam( client );
		new Float:AttackerPos[3];
		new Float:VictimPos[3];
		
		GetClientAbsOrigin( client, AttackerPos );
		
		AttackerPos[2] += 40.0;

		for( new i = 1; i <= MaxClients; i++ )
		{
			if( ValidPlayer( i, true ) && GetClientTeam( i ) != AttackerTeam && !W3HasImmunity( i, Immunity_Skills ) )
			{
				GetClientAbsOrigin( i, VictimPos );
				VictimPos[2] += 40.0;
				
				if( GetVectorDistance( AttackerPos, VictimPos ) <= distance )
				{
					RotateDelayer[i]++;
					if(RotateDelayer[i] == 50)
					{
						new Float:angs[3];
						GetClientEyeAngles(i, angs);
	
						angs[1] += 180;
	
						TeleportEntity(i, NULL_VECTOR, angs, NULL_VECTOR);
						
						RotateDelayer[i] = 0;
						VictimPos[2]+=20.0;
						TE_SetupBeamRingPoint(VictimPos,50.0,50.1,BeamSprite,HaloSprite,0,15,1.2,24.0,2.0,{255,80,80,255},10,0);
						TE_SendToClient(client);
					}
				}
			}
		}
	}
}

public Heal( i )
{
	new skill_regen = War3_GetSkillLevel(i,thisRaceID,SKILL_REGENERATE);
	if(canregeneratetime[i] < GetGameTime() && skill_regen > 0)
	{
		RegenerateDelayer[i]++;
		if(RegenerateDelayer[i] == 10)
		{
			War3_HealToBuffHP(i,RegenerateAmmount[skill_regen]);
			RegenerateDelayer[i] = 0;
		}
	}
	else
	{
	}
	if(skill_regen> 0 && !bDucking[i])
	{
		canregeneratetime[i] = GetGameTime() + 1.0;
	}
	W3FlashScreen(i,RGBA_COLOR_GREEN);
}

/* *************************************** GetRandomDeathPlayer *************************************** */
public GetRandomDeathPlayer( client )
{
	new victims = 0;
	new avengerTeam = GetClientTeam( client );
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( ValidPlayer( i, false ) && GetClientTeam( i ) == avengerTeam )
		{
			if(IsClientInGame(i) && !IsPlayerAlive(i))
			{
				VictimsTab[victims] = i;
				victims++;
			}
		}
	}
	
	if(victims == 0)
	{
		return 0;
	}
	else
	{
		new target = GetRandomInt(0,(victims-1));
		return VictimsTab[target];		
	}
}

