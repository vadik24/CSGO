#pragma semicolon 1	///WE RECOMMEND THE SEMICOLON

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - Rogue Knight",
	author = "Ted Theodore Logan",
	description = "The Rogue Knight race for War3Source.",
	version = "1.2",
};

/* Changelog
 * 1.2 - Fixed speed buff not being removed on race switch
 */

new thisRaceID;
new SKILL_BOLT, SKILL_CLEAVE, SKILL_WARCRY, ULT_STRENGTH;

// Tempents
new g_BeamSprite;
new g_HaloSprite;

// Storm Bolt 
new BoltDamage[5] = {0,5,15,25,30};
new Handle:StormCooldownTime; // cooldown
new Float:BoltRange = 450.0;
new const StormCol[4] = {0, 0, 255, 255}; // Color of the beacon
new bool:bIsStunned[MAXPLAYERS];

// Cleave Multiplayer
new Float:CleaveDistance[5] = {0.0,50.0,100.0,150.0,200.0};
new Float:CleaveMultiplier[5] = {0.0,0.05,0.1,0.15,0.2};

// Warcry Buffs
new Float:WarcrySpeed[5]={1.0,1.06,1.12,1.18,1.24};
new Float:WarcryArmor[5]={1.0,0.94,0.88,0.82,0.76};

// Gods Strength
new Float:GodsStrength[5]={1.0,0.7,0.80,0.9,1.0};
new bool:bStrengthActivated[MAXPLAYERS];
new Handle:StrengthCooldown; // cooldown

// Sounds
new String:skillsnd[]="war3source/sven/cast.mp3";
new String:ultsnd[]="war3source/sven/grunt.mp3";

public OnWar3PluginReady(){
	thisRaceID=War3_CreateNewRaceT("sven");
	SKILL_BOLT=War3_AddRaceSkillT(thisRaceID,"StormBolt",false,4);
	SKILL_CLEAVE=War3_AddRaceSkillT(thisRaceID,"GreatCleave",false,4);
	SKILL_WARCRY=War3_AddRaceSkillT(thisRaceID,"Warcry",false,4);
	ULT_STRENGTH=War3_AddRaceSkillT(thisRaceID,"GodsStrength",true,4); 
	War3_CreateRaceEnd(thisRaceID); ///DO NOT FORGET THE END!!!
}

public OnPluginStart()
{
	StormCooldownTime=CreateConVar("war3_sven_bolt_cooldown","15","Cooldown timer.");
	StrengthCooldown=CreateConVar("war3_sven_strength_cooldown","30","Cooldown timer.");
	LoadTranslations("w3s.race.sven.phrases");
}

public OnMapStart()
{
	// Precache the stuff for the beacon ring
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = War3_PrecacheHaloSprite();   
	//Sounds
	////War3_PrecacheSound(skillsnd);
	////War3_PrecacheSound(ultsnd);
}

public OnWar3EventSpawn(client)
{
	InitPassiveSkills(client);
	bIsStunned[client] = false;
	bStrengthActivated[client] = false;
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
		new skill = War3_GetSkillLevel(client,thisRaceID,SKILL_WARCRY);
		new Float:speed = WarcrySpeed[skill];
		War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		W3ResetAllBuffRace(client,thisRaceID);
	}
}


public OnW3TakeDmgBulletPre(victim,attacker,Float:damage){
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		if(War3_GetRace(victim)==thisRaceID)
		{
			// Apply armor to victims
			new skill = War3_GetSkillLevel(victim,thisRaceID,SKILL_WARCRY);
			War3_DamageModPercent(WarcryArmor[skill]);
		}
		if(War3_GetRace(attacker)==thisRaceID)
		{
			if(bStrengthActivated[attacker])
			{
				// GODS STRENGTH!
				new skill = War3_GetSkillLevel(attacker,thisRaceID,ULT_STRENGTH);
				War3_DamageModPercent(GodsStrength[skill]);
			}
		}
	}
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage){
	if(ValidPlayer(victim,true)&&ValidPlayer(attacker,false)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new skill;
			// Cleave
			if(bStrengthActivated[attacker])
			{
				skill = War3_GetSkillLevel(attacker,thisRaceID,ULT_STRENGTH);
				// For Cleave...
				damage = damage * GodsStrength[skill];
			}
			skill = War3_GetSkillLevel(attacker,thisRaceID,SKILL_CLEAVE);
			new splashdmg = RoundToFloor(damage * CleaveMultiplier[skill]);
			// AWP? AWP!
			if(splashdmg>20)
			{
				splashdmg = 20;
			}
			new Float:dist = CleaveDistance[skill];
			new AttackerTeam = GetClientTeam(attacker);
			new Float:OriginalVictimPos[3];
			GetClientAbsOrigin(victim,OriginalVictimPos);
			new Float:VictimPos[3];
			
			if(attacker>0)
			{
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true)&&(GetClientTeam(i)!=AttackerTeam)&&(victim!=i))
					{
						GetClientAbsOrigin(i,VictimPos);
						if(GetVectorDistance(OriginalVictimPos,VictimPos)<=dist)
						{
							War3_DealDamage(i,splashdmg,attacker,DMG_BURN,"greatcleave",W3DMGORIGIN_SKILL);
						}
					}
				}
			}
		}
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill = War3_GetSkillLevel(client,thisRaceID,SKILL_BOLT);
		if(skill > 0)
		{
			
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_BOLT,true))
			{
				new damage = BoltDamage[skill];
				new Float:AttackerPos[3];
				GetClientAbsOrigin(client,AttackerPos);
				new AttackerTeam = GetClientTeam(client);
				new Float:VictimPos[3];
				
				TE_SetupBeamRingPoint(AttackerPos, 10.0, BoltRange, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, StormCol, 10, 0);
				TE_SendToAll();
				
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true)){
						GetClientAbsOrigin(i,VictimPos);
						if(GetVectorDistance(AttackerPos,VictimPos)<BoltRange)
						{
							if(GetClientTeam(i)!=AttackerTeam)
							{
								War3_DealDamage(i,damage,client,DMG_BURN,"stormbolt",W3DMGORIGIN_SKILL);
								if(!bIsStunned[i])
								{
									bIsStunned[i]=true;
									// Nice color :3
									W3SetPlayerColor(i,thisRaceID, StormCol[0], StormCol[1], StormCol[2], StormCol[3]); 
									War3_SetBuff(i,bStunned,thisRaceID,true);

									W3FlashScreen(i,RGBA_COLOR_RED);
									CreateTimer(1.5,UnstunPlayer,i);
								
									PrintHintText(i,"You were stunned by Storm Bolt");
								}
							}
						}
					}
				}
				//EmitSoundToAll(skillsnd,client);
				War3_CooldownMGR(client,GetConVarFloat(StormCooldownTime),thisRaceID,SKILL_BOLT,false,true);
			}
		}
	}
}

public Action:UnstunPlayer(Handle:timer,any:client)
{
	
	PrintHintText(client,"No longer stunned");
	War3_SetBuff(client,bStunned,thisRaceID,false);
	bIsStunned[client]=false;
	W3ResetPlayerColor(client, thisRaceID);
	
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill = War3_GetSkillLevel(client,thisRaceID,ULT_STRENGTH);
		if(skill>0)
		{	
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_STRENGTH,true ))
			{
				PrintHintText(client, "The gods lend you their strength");
				bStrengthActivated[client] = true;
				CreateTimer(5.0,stopUltimate,client);
				
				//EmitSoundToAll(ultsnd,client);  
				War3_CooldownMGR(client,GetConVarFloat(StrengthCooldown),thisRaceID,ULT_STRENGTH,false,true);
			}
		}
	}
}


public Action:stopUltimate(Handle:t,any:client){
	bStrengthActivated[client] = false;
	if(ValidPlayer(client,true)){
		PrintHintText(client,"You feel less powerful");
	}
}